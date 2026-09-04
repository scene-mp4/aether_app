
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// Top-level handler for background messages — must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // App is in background or closed — system notification is shown automatically
  // by FCM. No additional action needed here unless you want custom handling.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class NotificationService {
  static final _messaging    = FirebaseMessaging.instance;
  static final _localNotifs  = FlutterLocalNotificationsPlugin();

  // Call once in main() before runApp()
  static Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);

    // Request permission (iOS requires this, Android 13+ requires this)
    await _messaging.requestPermission(
      alert:         true,
      badge:         true,
      sound:         true,
      criticalAlert: true, // iOS only — bypasses Do Not Disturb for emergencies
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      'aether_alerts',
      'AETHER Air Quality Alerts',
      description: 'Critical air quality alerts from AETHER trackers',
      importance:  Importance.max,
      playSound:   true,
      enableVibration: true,
    );
    await _localNotifs.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initialise local notifications (for foreground display)
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS:     DarwinInitializationSettings(),
    );
    await _localNotifs.initialize(initSettings);

    // Show notification when app is in foreground
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
            importance:  Importance.max,
            priority:    Priority.high,
            playSound:   true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    });
  }

  // Get this device's FCM token — save to Firestore so Cloud Function
  // can send targeted notifications to specific devices
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Subscribe to a topic — useful for "all nurses in facility X"
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }
}