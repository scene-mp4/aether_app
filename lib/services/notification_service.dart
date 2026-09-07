// lib/services/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class NotificationService {
  static final _localNotifs = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Skip FCM setup on web — web uses a service worker instead
    // and is not the primary target platform for notifications
    if (kIsWeb) {
      debugPrint('[NotificationService] Skipping FCM setup on web');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission(
      alert:         true,
      badge:         true,
      sound:         true,
    );

    const channel = AndroidNotificationChannel(
      'aether_alerts',
      'AETHER Air Quality Alerts',
      description: 'Critical air quality alerts from AETHER trackers',
      importance:  Importance.max,
      playSound:   true,
    );

    await _localNotifs.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS:     DarwinInitializationSettings(),
    );
    await _localNotifs.initialize(initSettings);

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifs.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'aether_alerts',
            'AETHER Air Quality Alerts',
            importance: Importance.max,
            priority:   Priority.high,
          ),
        ),
      );
    });
  }

  static Future<String?> getToken() async {
    if (kIsWeb) return null;
    return await FirebaseMessaging.instance.getToken();
  }
}