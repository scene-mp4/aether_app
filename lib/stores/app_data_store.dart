// lib/stores/app_data_store.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/tracker_reading.dart';
import '../models/tracker_history.dart';
import '../models/tracker_info.dart';

const int _pageSize = 288;

class AppDataStore extends ChangeNotifier {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Guards ─────────────────────────────────────────────────────────────────
  // _clearing prevents initialize() from running while clear() is still
  // awaiting stream cancellations.  Without this guard the two operations
  // can interleave and leave the store in a corrupt state.
  bool _clearing     = false;
  bool _initializing = false;

  // ── User state ─────────────────────────────────────────────────────────────
  List<TrackerInfo>            _trackers          = [];
  List<TrackerInfo>            _availableTrackers  = [];
  Map<String, TrackerReading>  _latestReadings     = {};
  final Map<String, TrackerHistory> _historyCache  = {};
  final Map<String, bool>      _historyLoading     = {};
  bool    _loading = false;
  String? _error;

  // ── Admin state ────────────────────────────────────────────────────────────
  List<TrackerInfo>            _allTrackers        = [];
  Map<String, TrackerReading>  _allLatestReadings  = {};

  // ── Advice state ───────────────────────────────────────────────────────────
  // Shared across all users — admins manage, users read.
  List<Map<String, dynamic>> _adviceEntries = [];
  List<Map<String, dynamic>> get adviceEntries =>
      List.unmodifiable(_adviceEntries);

  // ── Internal subscriptions ─────────────────────────────────────────────────
  StreamSubscription?                    _trackerListSub;
  StreamSubscription?                    _availableSub;
  StreamSubscription?                    _allDevicesSub;
  StreamSubscription?                    _adviceSub;
  final Map<String, StreamSubscription>  _latestSubs     = {};
  final Map<String, StreamSubscription>  _newReadingSubs = {};
  final Map<String, StreamSubscription>  _allLatestSubs  = {};

  // ── Public getters ─────────────────────────────────────────────────────────
  List<TrackerInfo> get trackers          => List.unmodifiable(_trackers);
  List<TrackerInfo> get availableTrackers => List.unmodifiable(_availableTrackers);
  List<TrackerInfo> get allTrackers       => List.unmodifiable(_allTrackers);

  Map<String, TrackerReading> get latestReadings    => Map.unmodifiable(_latestReadings);
  Map<String, TrackerReading> get allLatestReadings => Map.unmodifiable(_allLatestReadings);
  Map<String, TrackerHistory> get historyCache      => Map.unmodifiable(_historyCache);

  bool    get loading => _loading;
  String? get error   => _error;

  TrackerReading? readingFor(String deviceId)    => _latestReadings[deviceId];
  TrackerReading? allReadingFor(String deviceId) => _allLatestReadings[deviceId];
  TrackerHistory? historyFor(String deviceId)    => _historyCache[deviceId];

  TrackerInfo? infoFor(String deviceId) =>
      _trackers.where((t) => t.id == deviceId).firstOrNull;

  bool get hasAnyCOAlert => _latestReadings.values.any((r) => r.coAlert);

  int get worstIAQI => _latestReadings.values.isEmpty
      ? 0
      : _latestReadings.values.map((r) => r.iaqi).reduce((a, b) => a > b ? a : b);

  bool historyLoadingFor(String deviceId) => _historyLoading[deviceId] ?? false;

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEAR
  //
  // FIX: clear() is now async and awaits every stream cancellation before
  // returning. Previously it called cancel() without await, so old stream
  // callbacks could fire AFTER clear() returned and corrupt the new session's
  // state. This was the root cause of the account-switch bug.
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> clear() async {
    // If already clearing, wait — don't run twice concurrently
    if (_clearing) return;
    _clearing = true;

    // Cancel top-level subscriptions and await them
    await Future.wait([
      if (_trackerListSub != null) _trackerListSub!.cancel(),
      if (_availableSub   != null) _availableSub!.cancel(),
      if (_allDevicesSub  != null) _allDevicesSub!.cancel(),
      if (_adviceSub      != null) _adviceSub!.cancel(),
    ]);
    _trackerListSub = null;
    _availableSub   = null;
    _allDevicesSub  = null;
    _adviceSub      = null;

    // Cancel all per-tracker subscriptions and await them all
    await Future.wait([
      ..._latestSubs.values.map((s)     => s.cancel()),
      ..._newReadingSubs.values.map((s)  => s.cancel()),
      ..._allLatestSubs.values.map((s)   => s.cancel()),
    ]);
    _latestSubs.clear();
    _newReadingSubs.clear();
    _allLatestSubs.clear();

    // Reset all state
    _trackers.clear();
    _availableTrackers.clear();
    _allTrackers.clear();
    _latestReadings.clear();
    _allLatestReadings.clear();
    _historyCache.clear();
    _historyLoading.clear();
    _adviceEntries.clear();

    _loading      = false;
    _initializing = false;
    _error        = null;
    _clearing     = false;

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZE (user)
  //
  // FIX: Added _initializing mutex so concurrent calls (e.g. from hot-reload
  // or multiple widget rebuilds) don't open duplicate streams.
  // clear() is NOT called here — it must be called by the caller (AuthGate /
  // _RoleRouter) BEFORE initialize() so we can await it properly.
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> initialize() async {
    if (_initializing) return;
    _initializing = true;

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _initializing = false;
      return;
    }

    _loading = true;
    notifyListeners();

    // Listen to trackers owned by this user
    _trackerListSub = _db
        .collection('devices')
        .where('owner_id', isEqualTo: uid)
        .snapshots()
        .listen(
      (snap) {
        _trackers = snap.docs
            .map((d) => TrackerInfo.fromFirestore(
                d.id, d.data() as Map<String, dynamic>))
            .toList();

        final currentIds = _trackers.map((t) => t.id).toSet();

        for (final tracker in _trackers) {
          if (!_latestSubs.containsKey(tracker.id)) {
            _openLatestStream(tracker.id);
            _openNewReadingStream(tracker.id);
          }
        }

        _latestSubs.keys
            .where((id) => !currentIds.contains(id))
            .toList()
            .forEach(_closeTrackerStreams);

        _loading      = false;
        _initializing = false;
        notifyListeners();

        if (kDebugMode) {
          print('[AppDataStore] initialize: ${_trackers.length} trackers for $uid');
        }
      },
      onError: (e) {
        _error        = e.toString();
        _loading      = false;
        _initializing = false;
        notifyListeners();
        if (kDebugMode) print('[AppDataStore] initialize error: $e');
      },
    );

    // Listen to unowned (available) trackers
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

    // Listen to active advice entries — shared across all users
    _openAdviceStream();
  }

  // ── Advice stream ──────────────────────────────────────────────────────────
  // Opens a live stream on the advice collection filtered to active entries.
  // Sorted by severity so critical advice appears first in the UI.
  void _openAdviceStream() {
    _adviceSub = _db
        .collection('advice')
        .where('active', isEqualTo: true)
        .snapshots()
        .listen((snap) {
      _adviceEntries = snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return {'id': d.id, ...data};
      }).toList();

      // Sort: critical first, then warning, then info
      const order = {'critical': 0, 'warning': 1, 'info': 2};
      _adviceEntries.sort((a, b) {
        final aOrder = order[a['severity'] ?? 'info'] ?? 2;
        final bOrder = order[b['severity'] ?? 'info'] ?? 2;
        return aOrder.compareTo(bOrder);
      });

      notifyListeners();
      if (kDebugMode) {
        print('[AppDataStore] advice: ${_adviceEntries.length} active entries loaded');
      }
    }, onError: (e) {
      if (kDebugMode) print('[AppDataStore] advice stream error: \$e');
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZE ADMIN
  //
  // Listens to ALL devices regardless of owner_id.
  // Called in addition to initialize() for admin users.
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> initializeAdmin() async {
    _allDevicesSub = _db
        .collection('devices')
        .snapshots()
        .listen((snap) {
      _allTrackers = snap.docs
          .map((d) => TrackerInfo.fromFirestore(
              d.id, d.data() as Map<String, dynamic>))
          .toList();

      final currentIds = _allTrackers.map((t) => t.id).toSet();

      for (final t in _allTrackers) {
        if (!_allLatestSubs.containsKey(t.id)) {
          _openAdminLatestStream(t.id);
        }
      }

      _allLatestSubs.keys
          .where((id) => !currentIds.contains(id))
          .toList()
          .forEach(_closeAdminStream);

      notifyListeners();
    });
  }

  // ── Per-tracker stream helpers ─────────────────────────────────────────────

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
      final readingId = latest['raw_reading_id'] as String? ?? '';
      _latestReadings[deviceId] =
          TrackerReading.fromLatest(deviceId, readingId, latest);
      notifyListeners();
    });
    _latestSubs[deviceId] = sub;
  }

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
      if (!_historyCache.containsKey(deviceId)) return;

      final existing    = _historyCache[deviceId]!;
      final existingIds = existing.readings.map((r) => r.readingId).toSet();

      final newReadings = snap.docs
          .map((d) => TrackerReading.fromDocument(d))
          .where((r) => !existingIds.contains(r.readingId))
          .toList();

      if (newReadings.isEmpty) return;

      final updated = [...existing.readings, ...newReadings]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      _historyCache[deviceId] = existing.copyWith(readings: updated);
      notifyListeners();
    });
    _newReadingSubs[deviceId] = sub;
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

  void _closeTrackerStreams(String deviceId) {
    _latestSubs[deviceId]?.cancel();
    _latestSubs.remove(deviceId);
    _newReadingSubs[deviceId]?.cancel();
    _newReadingSubs.remove(deviceId);
    _latestReadings.remove(deviceId);
    _historyCache.remove(deviceId);
    notifyListeners();
  }

  void _closeAdminStream(String deviceId) {
    _allLatestSubs[deviceId]?.cancel();
    _allLatestSubs.remove(deviceId);
    _allLatestReadings.remove(deviceId);
  }

  // ── Tracker management ─────────────────────────────────────────────────────

  Future<void> linkTracker(String deviceId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('devices').doc(deviceId).update({'owner_id': uid});
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      if (kDebugMode) print('[AppDataStore] linkTracker error: $e');
    }
  }

  Future<void> unlinkTracker(String deviceId) async {
    try {
      await _db.collection('devices').doc(deviceId).update({'owner_id': ''});
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      if (kDebugMode) print('[AppDataStore] unlinkTracker error: $e');
    }
  }

  // ── History ────────────────────────────────────────────────────────────────

  Future<void> fetchHistory(
    String deviceId, {
    int  days         = 1,
    bool forceRefresh = false,
  }) async {
    if (_historyCache.containsKey(deviceId) && !forceRefresh) return;

    _historyLoading[deviceId] = true;
    notifyListeners();

    try {
      final from = DateTime.now().subtract(Duration(days: days));

      final snap = await _db
          .collection('devices')
          .doc(deviceId)
          .collection('readings_computed')
          .orderBy('timestamp', descending: true)
          .limit(days * 300)
          .get();

      final readings = snap.docs
          .map((d) => TrackerReading.fromDocument(d))
          .where((r) => r.timestamp.isAfter(from))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      _historyCache[deviceId] = TrackerHistory(
        deviceId:     deviceId,
        readings:     readings,
        oldestCursor: snap.docs.isNotEmpty ? snap.docs.last : null,
        hasMore:      snap.docs.length == days * 300,
        from:         from,
        to:           DateTime.now(),
      );

      if (kDebugMode) {
        print('[_fetchHistory] fetched ${snap.docs.length} docs for '
              'tracker $deviceId (days=$days)');
        print('[_fetchHistory] processed ${readings.length} points');
      }
    } catch (e, st) {
      _error = e.toString();
      if (kDebugMode) print('[AppDataStore] fetchHistory error: $e\n$st');
    }

    _historyLoading[deviceId] = false;
    notifyListeners();
  }

  Future<void> fetchMoreHistory(String deviceId, {int days = 7}) async {
    final existing = _historyCache[deviceId];
    if (existing == null || !existing.hasMore) return;
    if (_historyLoading[deviceId] == true) return;

    _historyLoading[deviceId] = true;
    notifyListeners();

    try {
      final from = DateTime.now().subtract(Duration(days: days));

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
        hasMore: snap.docs.length == days * 300,
        from:    from,
      );
    } catch (e, st) {
      _error = e.toString();
      if (kDebugMode) print('[AppDataStore] fetchMoreHistory error: $e\n$st');
    }

    _historyLoading[deviceId] = false;
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}