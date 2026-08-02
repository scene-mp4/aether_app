// lib/stores/app_data_store.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/tracker_reading.dart';
import '../models/tracker_history.dart';
import '../models/tracker_info.dart';

// How many readings to fetch per page (288 = 24hrs at 5min intervals)
const int _pageSize = 288;

class AppDataStore extends ChangeNotifier {
  bool _initialized = false;
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── State ──────────────────────────────────────────────────────────────────

  List<TrackerInfo> _trackers = [];
  List<TrackerInfo> get trackers => List.unmodifiable(_trackers);

  List<TrackerInfo> _availableTrackers = [];
  List<TrackerInfo> get availableTrackers =>
    List.unmodifiable(_availableTrackers);

  // Latest reading per tracker (live, updated by Firestore stream)
  Map<String, TrackerReading> _latestReadings = {};
  Map<String, TrackerReading> get latestReadings =>
      Map.unmodifiable(_latestReadings);

  // History cache per tracker (fetched on demand)
  final Map<String, TrackerHistory> _historyCache = {};
  Map<String, TrackerHistory> get historyCache =>
      Map.unmodifiable(_historyCache);

  // Loading states
  bool _loading = false;
  bool get loading => _loading;

  // Per-tracker history loading state
  final Map<String, bool> _historyLoading = {};
  bool historyLoadingFor(String deviceId) =>
      _historyLoading[deviceId] ?? false;

  String? _error;
  String? get error => _error;

  // ── Internal listeners ─────────────────────────────────────────────────────
  StreamSubscription? _availableSub;
  StreamSubscription?                  _trackerListSub;
  final Map<String, StreamSubscription> _latestSubs    = {};
  final Map<String, StreamSubscription> _newReadingSubs = {};

  // Admin Fields
  StreamSubscription?       _allDevicesSub;
  List<TrackerInfo>         _allTrackers     = [];
  Map<String, TrackerReading> _allLatestReadings = {};
  final Map<String, StreamSubscription> _allLatestSubs = {};

  // ── Initialize ─────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    if (_initialized) clear(); // clear stale state from previous session
    _initialized = true;

    _loading = true;
    notifyListeners();

    _trackerListSub = _db
        .collection('devices')
        .where('owner_id', isEqualTo: uid)
        .snapshots()
        .listen(
      (snap) {
        _trackers = snap.docs.map((d) =>
            TrackerInfo.fromFirestore(
                d.id, d.data() as Map<String, dynamic>))
            .toList();

        final currentIds = _trackers.map((t) => t.id).toSet();

        // Open streams for new trackers
        for (final tracker in _trackers) {
          if (!_latestSubs.containsKey(tracker.id)) {
            _openLatestStream(tracker.id);
            _openNewReadingStream(tracker.id);
          }
        }

        // Close streams for removed trackers
        _latestSubs.keys
            .where((id) => !currentIds.contains(id))
            .toList()
            .forEach(_closeTrackerStreams);

        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        _error   = e.toString();
        _loading = false;
        notifyListeners();
      },
    );

        _availableSub = _db
        .collection('devices')
        .where('owner_id', isEqualTo: '')
        .snapshots()
        .listen((snap) {
      _availableTrackers = snap.docs
          .map((d) => TrackerInfo.fromFirestore(
              d.id, d.data() as Map<String, dynamic>))
          .toList();
      notifyListeners();
    });
  }

  // ── Live stream for the latest reading ────────────────────────────────────
  // Reads from devices/{deviceId}.latest — updated by Cloud Function
  void _openLatestStream(String deviceId) {
    final sub = _db
        .collection('devices')
        .doc(deviceId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;

      final data   = snap.data() as Map<String, dynamic>;
      final latest = data['latest'] as Map<String, dynamic>?;
      if (latest == null) return;

      // Use the raw_reading_id stored in latest as the reading ID
      final readingId = latest['raw_reading_id'] as String? ?? '';

      _latestReadings[deviceId] =
          TrackerReading.fromLatest(deviceId, readingId, latest);
      notifyListeners();
    });

    _latestSubs[deviceId] = sub;
  }

  // ── Live stream for new readings_computed documents ───────────────────────
  // Listens for documents created after now so new readings are
  // automatically appended to the history cache without re-fetching.
  void _openNewReadingStream(String deviceId) {
    final listenFrom = Timestamp.now();

    final sub = _db
        .collection('devices')
        .doc(deviceId)
        .collection('readings_computed')
        .where('timestamp', isGreaterThan: listenFrom)
        .orderBy('timestamp')
        .snapshots()
        .listen((snap) {
      if (snap.docs.isEmpty) return;

      // Only append if we have an existing history cache for this tracker.
      // If history hasn't been loaded yet, the new reading will be included
      // automatically when history is first fetched.
      if (!_historyCache.containsKey(deviceId)) return;

      final existing = _historyCache[deviceId]!;
      final existingIds = existing.readings.map((r) => r.readingId).toSet();

      final newReadings = snap.docs
          .map((d) => TrackerReading.fromDocument(d))
          .where((r) => !existingIds.contains(r.readingId))
          .toList();

      if (newReadings.isEmpty) return;

      // Append new readings and keep list sorted oldest → newest
      final updated = [...existing.readings, ...newReadings]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      _historyCache[deviceId] = existing.copyWith(readings: updated);
      notifyListeners();
    });

    _newReadingSubs[deviceId] = sub;
  }

  // ── Close all streams for a tracker ───────────────────────────────────────
  void _closeTrackerStreams(String deviceId) {
    _latestSubs[deviceId]?.cancel();
    _latestSubs.remove(deviceId);
    _newReadingSubs[deviceId]?.cancel();
    _newReadingSubs.remove(deviceId);
    _latestReadings.remove(deviceId);
    _historyCache.remove(deviceId);
    notifyListeners();
  }

  // ── Link a tracker to the current user ────────────────────────────────────
Future<void> linkTracker(String deviceId) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return;
  try {
    await _db.collection('devices').doc(deviceId).update({
      'owner_id': uid,
    });
    // The tracker list stream will automatically pick up the new device
    // and open its reading stream — no manual action needed here.
  } catch (e) {
    _error = e.toString();
    notifyListeners();
    if (kDebugMode) print('[AppDataStore] linkTracker error: $e');
  }
}

// ── Unlink a tracker from the current user ────────────────────────────────
Future<void> unlinkTracker(String deviceId) async {
  try {
    await _db.collection('devices').doc(deviceId).update({
      'owner_id': '',
    });
    // The tracker list stream will detect the removal and
    // _closeTrackerStreams will be called automatically.
  } catch (e) {
    _error = e.toString();
    notifyListeners();
    if (kDebugMode) print('[AppDataStore] unlinkTracker error: $e');
  }
}

  // ── Fetch history for a tracker ───────────────────────────────────────────
  // Call this when a history screen opens for the first time.
  // Subsequent calls are no-ops if data is already cached.
  // [forceRefresh] re-fetches from scratch — use for pull-to-refresh.
 Future<void> fetchHistory(
  String deviceId, {
  int days          = 1,
  bool forceRefresh = false,
}) async {
  if (_historyCache.containsKey(deviceId) && !forceRefresh) return;

  _historyLoading[deviceId] = true;
  notifyListeners();

  try {
    final from = DateTime.now().subtract(Duration(days: days));

    // FIX: Remove the .where('timestamp') filter — Firestore cannot
    // compare a string field with a Timestamp value, which returns 0 results.
    // Instead fetch the most recent documents and filter by date in Dart.
    final snap = await _db
        .collection('devices')
        .doc(deviceId)
        .collection('readings_computed')
        .orderBy('timestamp', descending: true)  // newest first
        .limit(days * 300)  // generous upper bound (300 readings/day max)
        .get();

    // Filter in Dart — works with both string and Timestamp formats
    final readings = snap.docs
        .map((d) => TrackerReading.fromDocument(d))
        .where((r) => r.timestamp.isAfter(from))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp)); // oldest → newest

      if (kDebugMode) {
      print('[AppDataStore] Raw docs fetched: ${snap.docs.length}');
      if (snap.docs.isNotEmpty) {
        final first = snap.docs.first.data() as Map<String, dynamic>;
        print('[AppDataStore] First doc timestamp field: ${first['timestamp']}');
      }
}

    _historyCache[deviceId] = TrackerHistory(
      deviceId:     deviceId,
      readings:     readings,
      oldestCursor: snap.docs.isNotEmpty ? snap.docs.last : null,
      hasMore:      snap.docs.length == days * 300,
      from:         from,
      to:           DateTime.now(),
    );

    if (kDebugMode) {
      print('[AppDataStore] fetchHistory: fetched ${snap.docs.length} docs, '
            '${readings.length} within last $days day(s) for $deviceId');
    }
  } catch (e, st) {
    _error = e.toString();
    if (kDebugMode) print('[AppDataStore] fetchHistory error: $e\n$st');
  }

  _historyLoading[deviceId] = false;
  notifyListeners();
}

  // ── Load more history (older readings) ────────────────────────────────────
  // Call this when the user scrolls to the top of a history chart
  // and wants to see older data beyond the initial page.
 Future<void> fetchMoreHistory(String deviceId, {int days = 7}) async {
  final existing = _historyCache[deviceId];
  if (existing == null || !existing.hasMore) return;
  if (_historyLoading[deviceId] == true) return;

  _historyLoading[deviceId] = true;
  notifyListeners();

  try {
    final from = DateTime.now().subtract(Duration(days: days));

    // FIX: No .where() filter — order and limit only
    Query query = _db
        .collection('devices')
        .doc(deviceId)
        .collection('readings_computed')
        .orderBy('timestamp', descending: true)
        .limit(days * 300);

    if (existing.oldestCursor != null) {
      query = query.startAfterDocument(
          existing.oldestCursor as DocumentSnapshot);
    }

    final snap = await query.get();

    final newReadings = snap.docs
        .map((d) => TrackerReading.fromDocument(d))
        .where((r) => r.timestamp.isAfter(from))
        .toList();

    final merged = [...newReadings, ...existing.readings]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    _historyCache[deviceId] = existing.copyWith(
      readings:     merged,
      oldestCursor: snap.docs.isNotEmpty
          ? snap.docs.last
          : existing.oldestCursor,
      hasMore:      snap.docs.length == days * 300,
      from:         from,
    );
  } catch (e, st) {
    _error = e.toString();
    if (kDebugMode) print('[AppDataStore] fetchMoreHistory error: $e\n$st');
  }

  _historyLoading[deviceId] = false;
  notifyListeners();
}

  // ── Convenience getters ────────────────────────────────────────────────────

  TrackerReading? readingFor(String deviceId) =>
      _latestReadings[deviceId];

  TrackerInfo? infoFor(String deviceId) =>
      _trackers.where((t) => t.id == deviceId).firstOrNull;

  TrackerHistory? historyFor(String deviceId) =>
      _historyCache[deviceId];

  bool get hasAnyCOAlert =>
      _latestReadings.values.any((r) => r.coAlert);

  int get worstIAQI => _latestReadings.values.isEmpty
      ? 0
      : _latestReadings.values
          .map((r) => r.iaqi)
          .reduce((a, b) => a > b ? a : b);

// Admin Getters
  List<TrackerInfo> get allTrackers =>
    List.unmodifiable(_allTrackers);
  Map<String, TrackerReading> get allLatestReadings =>
      Map.unmodifiable(_allLatestReadings);
  TrackerReading? allReadingFor(String deviceId) =>
      _allLatestReadings[deviceId];

// Initialize Admin
Future<void> initializeAdmin() async {
  // Listen to ALL devices regardless of owner
  _allDevicesSub = _db
      .collection('devices')
      .snapshots()
      .listen((snap) {
    _allTrackers = snap.docs
        .map((d) => TrackerInfo.fromFirestore(
            d.id, d.data() as Map<String, dynamic>))
        .toList();

    final currentIds = _allTrackers.map((t) => t.id).toSet();

    // Open a latest-reading stream for each device
    for (final t in _allTrackers) {
      if (!_allLatestSubs.containsKey(t.id)) {
        _openAdminLatestStream(t.id);
      }
    }

    // Close streams for removed devices
    _allLatestSubs.keys
        .where((id) => !currentIds.contains(id))
        .toList()
        .forEach(_closeAdminStream);

    notifyListeners();
  });
}

void _openAdminLatestStream(String deviceId) {
  final sub = _db
      .collection('devices')
      .doc(deviceId)
      .snapshots()
      .listen((snap) {
    if (!snap.exists) return;
    final data   = snap.data() as Map<String, dynamic>;
    final latest = data['latest'] as Map<String, dynamic>?;
    if (latest == null) return;
    final readingId = latest['raw_reading_id'] as String? ?? '';
    _allLatestReadings[deviceId] =
        TrackerReading.fromLatest(deviceId, readingId, latest);
    notifyListeners();
  });
  _allLatestSubs[deviceId] = sub;
}

void _closeAdminStream(String deviceId) {
  _allLatestSubs[deviceId]?.cancel();
  _allLatestSubs.remove(deviceId);
  _allLatestReadings.remove(deviceId);
}

  // ── Clear on sign out ──────────────────────────────────────────────────────
    void clear() {
      _initialized = false;
      _trackerListSub?.cancel();
      _availableSub?.cancel();      // ← add this line
      for (final sub in _latestSubs.values)     sub.cancel();
      for (final sub in _newReadingSubs.values) sub.cancel();
      _latestSubs.clear();
      _newReadingSubs.clear();
      _latestReadings.clear();
      _historyCache.clear();
      _historyLoading.clear();
      _trackers.clear();
      _availableTrackers.clear();   // ← add this line
      _error   = null;
      _loading = false;
      notifyListeners();
      _allDevicesSub?.cancel();
      for (final sub in _allLatestSubs.values) sub.cancel();
      _allLatestSubs.clear();
      _allLatestReadings.clear();
      _allTrackers.clear();
    }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}