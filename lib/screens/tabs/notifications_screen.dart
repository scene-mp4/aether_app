import 'package:flutter/material.dart';

// Notification Data Model
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Sample notification data (replace with your dynamic state/stream)
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'High CO Levels Detected',
      message: 'Tracker "Living Room Sensor" reported elevated CO levels.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    NotificationItem(
      id: '2',
      title: 'Air Quality Alert',
      message: 'AQI index in "Bedroom" reached Unhealthy status (155).',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationItem(
      id: '3',
      title: 'Device Reconnected',
      message: 'Tracker "Office Sensor" is back online.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item.isRead = true;
      }
    });
  }

  void _removeNotification(String id) {
    setState(() {
      _notifications.removeWhere((item) => item.id == id);
    });
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => !n.isRead);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85, // Covers 85% of screen width
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: SafeArea(
          child: Column(
            children: [
              // ── Header Bar ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF0052FF),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (hasUnread)
                      IconButton(
                        icon: const Icon(Icons.done_all, color: Colors.white, size: 20),
                        tooltip: 'Mark all as read',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _markAllAsRead,
                      ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // ── Notification List ────────────────────────────────────────
              Expanded(
                child: _notifications.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 48,
                              color: Color(0xFF94A3B8),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No notifications',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 1),
                        itemBuilder: (context, index) {
                          final item = _notifications[index];

                          return Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => _removeNotification(item.id),
                            background: Container(
                              color: const Color(0xFFEF4444),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            child: Container(
                              color: item.isRead
                                  ? Colors.white
                                  : const Color(0xFFEFF6FF),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: item.isRead
                                      ? const Color(0xFFE2E8F0)
                                      : const Color(0xFFDBEAFE),
                                  child: Icon(
                                    item.isRead
                                        ? Icons.notifications_none
                                        : Icons.notifications_active_outlined,
                                    color: item.isRead
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF0052FF),
                                    size: 18,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: item.isRead
                                              ? FontWeight.w600
                                              : FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTimestamp(item.timestamp),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    item.message,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    item.isRead = true;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}