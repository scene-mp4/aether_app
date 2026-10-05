import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '/stores/app_data_store.dart';
import '/models/tracker_reading.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Notification Data Model
// ═══════════════════════════════════════════════════════════════════════════════

class NotificationItem {
  final String   id;
  final String   title;
  final String   message;
  final String   type;
  final String   trackerId;
  final String   trackerName;
  final int      iaqi;
  final DateTime timestamp;
  bool           isRead;
  // For admin-generated in-app items that don't live in Firestore
  final bool     isLocal;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.type        = 'aqi_alert',
    this.trackerId   = '',
    this.trackerName = '',
    this.iaqi        = 0,
    this.isRead      = false,
    this.isLocal     = false,
  });

  factory NotificationItem.fromFirestore(
      String id, Map<String, dynamic> data) {
    return NotificationItem(
      id:          id,
      title:       data['title']        as String? ?? 'Alert',
      message:     data['message']      as String? ?? '',
      type:        data['type']         as String? ?? 'aqi_alert',
      trackerId:   data['tracker_id']   as String? ?? '',
      trackerName: data['tracker_name'] as String? ?? '',
      iaqi:        (data['iaqi']        as num?)?.toInt() ?? 0,
      isRead:      data['is_read']      as bool?  ?? false,
      timestamp:   data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// NotificationsScreen
// ═══════════════════════════════════════════════════════════════════════════════

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _db  = FirebaseFirestore.instance;
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  // Tracks which local admin notification IDs have been dismissed this session
  final Set<String> _dismissedLocal = {};

  // ── Firestore stream — user's own notifications ────────────────────────────
  Stream<List<NotificationItem>> get _firestoreStream {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => NotificationItem.fromFirestore(
                d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  // ── Admin: stream ALL users' notifications ─────────────────────────────────
  // Fetches the notifications subcollection from every user document.
  // Uses collectionGroup so Firestore returns all 'notifications' collections
  // regardless of which user they belong to.
  Stream<List<NotificationItem>> get _adminFirestoreStream {
    return _db
        .collectionGroup('notifications')
        .orderBy('created_at', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => NotificationItem.fromFirestore(
                d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  // ── Admin: generate live in-app notices from AppDataStore readings ─────────
  // These are NOT stored in Firestore — they are computed on the fly from
  // the current live readings and shown as informational items.
  List<NotificationItem> _buildLiveAdminNotices(AppDataStore store) {
    final items = <NotificationItem>[];
    final trackers = store.allTrackers;
    if (trackers.isEmpty) return items;

    // Collect readings for all trackers
    final readings = trackers
        .map((t) => store.allReadingFor(t.id))
        .where((r) => r != null)
        .map((r) => r!)
        .toList();

    if (readings.isEmpty) return items;

    // 1. Facility-wide average IAQI
    final avgIaqi = readings
            .map((r) => r.iaqi as int)
            .reduce((a, b) => a + b) /
        readings.length;

    if (avgIaqi > 150) {
      final id = 'admin_avg_iaqi';
      if (!_dismissedLocal.contains(id)) {
        items.add(NotificationItem(
          id:        id,
          title:     'High Average AQI Across Facility',
          message:   'The average IAQI across all ${trackers.length} '
              'trackers is ${avgIaqi.toStringAsFixed(0)} — '
              '${_iaqiLabel(avgIaqi.toInt())}. '
              'Review individual trackers for sources.',
          type:      'admin_aqi',
          iaqi:      avgIaqi.toInt(),
          timestamp: DateTime.now(),
          isRead:    false,
          isLocal:   true,
        ));
      }
    }

    // 2. Per-tracker alerts — CO, PM2.5, high IAQI
    for (int i = 0; i < trackers.length; i++) {
      final t = trackers[i];
      final r = store.allReadingFor(t.id);
      if (r == null) continue;

      if (r.coAlert) {
        final id = 'admin_co_${t.id}';
        if (!_dismissedLocal.contains(id)) {
          items.add(NotificationItem(
            id:          id,
            title:       '🚨 CO Alert — ${t.deviceName}',
            message:     'CO is ${r.coPpm.toStringAsFixed(1)} ppm at '
                '${t.location.isNotEmpty ? t.location : t.id}. '
                'Immediate ventilation recommended.',
            type:        'co_alert',
            trackerId:   t.id,
            trackerName: t.deviceName,
            iaqi:        r.iaqi,
            timestamp:   r.timestamp,
            isRead:      false,
            isLocal:     true,
          ));
        }
      }

      if (r.pm25Alert) {
        final id = 'admin_pm25_${t.id}';
        if (!_dismissedLocal.contains(id)) {
          items.add(NotificationItem(
            id:          id,
            title:       '⚠️ PM2.5 Elevated — ${t.deviceName}',
            message:     'PM2.5 is ${r.pm25Ugm3.toStringAsFixed(1)} µg/m³ '
                '(AQI ${r.pm25Aqi}) at '
                '${t.location.isNotEmpty ? t.location : t.id}.',
            type:        'pm25_alert',
            trackerId:   t.id,
            trackerName: t.deviceName,
            iaqi:        r.iaqi,
            timestamp:   r.timestamp,
            isRead:      false,
            isLocal:     true,
          ));
        }
      }

      if (!r.coAlert && !r.pm25Alert && r.iaqi > 150) {
        final id = 'admin_iaqi_${t.id}';
        if (!_dismissedLocal.contains(id)) {
          items.add(NotificationItem(
            id:          id,
            title:       'Unhealthy AQI — ${t.deviceName}',
            message:     'IAQI ${r.iaqi} (${_iaqiLabel(r.iaqi)}) at '
                '${t.location.isNotEmpty ? t.location : t.id}. '
                'Check ventilation.',
            type:        'aqi_alert',
            trackerId:   t.id,
            trackerName: t.deviceName,
            iaqi:        r.iaqi,
            timestamp:   r.timestamp,
            isRead:      false,
            isLocal:     true,
          ));
        }
      }
    }

    // 3. Count of trackers with no recent reading (offline check)
    final staleTrackers = trackers.where((t) {
      final r = store.allReadingFor(t.id);
      if (r == null) return true;
      return DateTime.now().difference(r.timestamp).inMinutes > 15;
    }).toList();

    if (staleTrackers.isNotEmpty) {
      final id = 'admin_stale';
      if (!_dismissedLocal.contains(id)) {
        items.add(NotificationItem(
          id:        id,
          title:     '${staleTrackers.length} Tracker${staleTrackers.length == 1 ? '' : 's'} Not Reporting',
          message:   staleTrackers.map((t) => t.deviceName).join(', ') +
              (staleTrackers.length == 1
                  ? ' has not sent a reading in over 15 minutes.'
                  : ' have not sent readings in over 15 minutes.'),
          type:      'admin_offline',
          timestamp: DateTime.now(),
          isRead:    false,
          isLocal:   true,
        ));
      }
    }

    return items;
  }

  String _iaqiLabel(int iaqi) {
    if (iaqi <= 50)  return 'Good';
    if (iaqi <= 100) return 'Moderate';
    if (iaqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (iaqi <= 200) return 'Unhealthy';
    if (iaqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  // ── Firestore operations ───────────────────────────────────────────────────

  Future<void> _markAllAsRead(bool isAdmin) async {
    if (_uid == null) return;
    if (isAdmin) {
      // Mark all notifications across all users
      final snap = await _db
          .collectionGroup('notifications')
          .where('is_read', isEqualTo: false)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();
    } else {
      final snap = await _db
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .where('is_read', isEqualTo: false)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();
    }
  }

  Future<void> _markOneAsRead(NotificationItem item, bool isAdmin) async {
    if (item.isLocal) {
      // Local items have no Firestore doc — just mark in memory
      setState(() => item.isRead = true);
      return;
    }
    if (_uid == null) return;
    if (isAdmin) {
      // Find the doc by collectionGroup — it could be under any user
      final snap = await _db
          .collectionGroup('notifications')
          .where(FieldPath.documentId, isEqualTo: item.id)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.update({'is_read': true});
      }
    } else {
      await _db
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .doc(item.id)
          .update({'is_read': true});
    }
  }

  Future<void> _removeNotification(NotificationItem item, bool isAdmin) async {
    if (item.isLocal) {
      setState(() => _dismissedLocal.add(item.id));
      return;
    }
    if (_uid == null) return;
    if (isAdmin) {
      final snap = await _db
          .collectionGroup('notifications')
          .where(FieldPath.documentId, isEqualTo: item.id)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.delete();
      }
    } else {
      await _db
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .doc(item.id)
          .delete();
    }
  }

  // ── Display helpers ────────────────────────────────────────────────────────

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'co_alert':     return Icons.warning_amber_rounded;
      case 'pm25_alert':   return Icons.grain;
      case 'admin_aqi':    return Icons.analytics_outlined;
      case 'admin_offline':return Icons.sensors_off_outlined;
      default:             return Icons.air;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'co_alert':     return const Color(0xFFEF4444);
      case 'pm25_alert':   return const Color(0xFFD97706);
      case 'admin_aqi':    return const Color(0xFF9333EA);
      case 'admin_offline':return const Color(0xFF64748B);
      default:             return const Color(0xFF0052FF);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final store   = context.watch<AppDataStore>();
    final isAdmin = store.isAdmin; // bool getter on AppDataStore

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: StreamBuilder<List<NotificationItem>>(
            stream: isAdmin ? _adminFirestoreStream : _firestoreStream,
            builder: (context, snap) {
              final firestoreItems = snap.data ?? [];

              // Merge live admin notices (in-app) with Firestore items
              final liveNotices = isAdmin
                  ? _buildLiveAdminNotices(store)
                  : <NotificationItem>[];

              // Combine: live notices first (most urgent), then Firestore
              final all = [...liveNotices, ...firestoreItems];
              final hasUnread = all.any((n) => !n.isRead);

              return Column(children: [
                // ── Header ────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  color: const Color(0xFF0052FF),
                  child: Row(children: [
                    const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notifications',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        if (isAdmin)
                          const Text('All trackers · Admin view',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFC7D2FE))),
                      ],
                    ),
                    const Spacer(),
                    if (hasUnread)
                      IconButton(
                        icon: const Icon(Icons.done_all,
                            color: Colors.white, size: 20),
                        tooltip: 'Mark all as read',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _markAllAsRead(isAdmin),
                      ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ]),
                ),

                // ── Loading ───────────────────────────────────────────────
                if (snap.connectionState == ConnectionState.waiting &&
                    all.isEmpty)
                  const Expanded(
                      child: Center(child: CircularProgressIndicator()))

                // ── Empty ─────────────────────────────────────────────────
                else if (all.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined,
                              size: 48, color: Color(0xFF94A3B8)),
                          SizedBox(height: 12),
                          Text('No notifications yet',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500)),
                          SizedBox(height: 4),
                          Text('Air quality alerts will appear here.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  )

                // ── List ──────────────────────────────────────────────────
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: all.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 1),
                      itemBuilder: (context, index) {
                        final item  = all[index];
                        final color = _colorForType(item.type);
                        final icon  = _iconForType(item.type);

                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) =>
                              _removeNotification(item, isAdmin),
                          background: Container(
                            color: const Color(0xFFEF4444),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.white, size: 20),
                          ),
                          child: Container(
                            color: item.isRead
                                ? Colors.white
                                : const Color(0xFFEFF6FF),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              leading: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: color.withOpacity(
                                        item.isRead ? 0.08 : 0.15),
                                    child: Icon(icon,
                                        color: color.withOpacity(
                                            item.isRead ? 0.5 : 1.0),
                                        size: 18),
                                  ),
                                  // Live indicator dot for local notices
                                  if (item.isLocal)
                                    Positioned(
                                      right: -2, top: -2,
                                      child: Container(
                                        width: 8, height: 8,
                                        decoration: const BoxDecoration(
                                            color: Color(0xFFEF4444),
                                            shape: BoxShape.circle),
                                      ),
                                    ),
                                ],
                              ),
                              title: Row(children: [
                                Expanded(
                                  child: Text(item.title,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: item.isRead
                                              ? FontWeight.w600
                                              : FontWeight.bold,
                                          color: const Color(0xFF0F172A))),
                                ),
                                Text(_formatTimestamp(item.timestamp),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF94A3B8))),
                              ]),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(item.message,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF475569))),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    if (item.trackerName.isNotEmpty) ...[
                                      const Icon(Icons.sensors,
                                          size: 11,
                                          color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 3),
                                      Text(item.trackerName,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF94A3B8))),
                                      const SizedBox(width: 8),
                                    ],
                                    if (item.isLocal)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text('Live',
                                            style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2563EB))),
                                      ),
                                  ]),
                                ],
                              ),
                              onTap: () => _markOneAsRead(item, isAdmin),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ]);
            },
          ),
        ),
      ),
    );
  }
}