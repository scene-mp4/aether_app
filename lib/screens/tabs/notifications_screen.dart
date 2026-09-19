import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Notification Data Model
class NotificationItem {
  final String   id;
  final String   title;
  final String   message;
  final String   type;        // 'co_alert' | 'pm25_alert' | 'aqi_alert'
  final String   trackerId;
  final String   trackerName;
  final int      iaqi;
  final DateTime timestamp;
  bool           isRead;

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

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _db  = FirebaseFirestore.instance;
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  // Stream query — newest first, last 50
  Stream<List<NotificationItem>> get _notificationsStream {
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

  Future<void> _markAllAsRead() async {
    if (_uid == null) return;
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

  Future<void> _markOneAsRead(String id) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .doc(id)
        .update({'is_read': true});
  }

  Future<void> _removeNotification(String id) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .doc(id)
        .delete();
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'co_alert':   return Icons.warning_amber_rounded;
      case 'pm25_alert': return Icons.grain;
      default:           return Icons.air;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'co_alert':   return const Color(0xFFEF4444);
      case 'pm25_alert': return const Color(0xFFD97706);
      default:           return const Color(0xFF0052FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: SafeArea(
          child: StreamBuilder<List<NotificationItem>>(
            stream: _notificationsStream,
            builder: (context, snap) {
              final notifications = snap.data ?? [];
              final hasUnread = notifications.any((n) => !n.isRead);

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
                    const Text('Notifications',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const Spacer(),
                    if (hasUnread)
                      IconButton(
                        icon: const Icon(Icons.done_all,
                            color: Colors.white, size: 20),
                        tooltip: 'Mark all as read',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _markAllAsRead,
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

                // ── Loading state ─────────────────────────────────────────
                if (snap.connectionState == ConnectionState.waiting &&
                    notifications.isEmpty)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )

                // ── Empty state ───────────────────────────────────────────
                else if (notifications.isEmpty)
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

                // ── Notification list ─────────────────────────────────────
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 1),
                      itemBuilder: (context, index) {
                        final item   = notifications[index];
                        final color  = _colorForType(item.type);
                        final icon   = _iconForType(item.type);

                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _removeNotification(item.id),
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
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: color.withOpacity(
                                    item.isRead ? 0.08 : 0.15),
                                child: Icon(icon,
                                    color: color.withOpacity(
                                        item.isRead ? 0.5 : 1.0),
                                    size: 18),
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
                                  if (item.trackerName.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      const Icon(Icons.sensors,
                                          size: 11,
                                          color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 3),
                                      Text(item.trackerName,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF94A3B8))),
                                    ]),
                                  ],
                                ],
                              ),
                              onTap: () => _markOneAsRead(item.id),
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

