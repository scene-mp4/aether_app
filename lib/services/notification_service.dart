// lib/services/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const channel = AndroidNotificationChannel(
      'aether_alerts',
      'AETHER Air Quality Alerts',
      description: 'Critical air quality alerts from AETHER trackers',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifs
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
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
            priority: Priority.high,
          ),
        ),
      );
    });

    FirebaseMessaging.instance.onTokenRefresh.listen(_registerRefreshedToken);
  }

  static Future<bool> enableForUser(String uid) async {
    if (kIsWeb) return false;

    final permission = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (permission.authorizationStatus != AuthorizationStatus.authorized &&
        permission.authorizationStatus != AuthorizationStatus.provisional) {
      return false;
    }

    final token = await getToken();
    if (token == null) return false;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'push_notifications': true,
      'fcm_tokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
    return true;
  }

  static Future<void> disableForUser(String uid) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    await userRef.set({'push_notifications': false}, SetOptions(merge: true));

    final token = await getToken();
    if (token != null) {
      await userRef.set({
        'fcm_tokens': FieldValue.arrayRemove([token]),
      }, SetOptions(merge: true));
    }
  }

  static Future<void> syncEnabledUser(String uid) async {
    if (kIsWeb) return;

    final permission = await FirebaseMessaging.instance
        .getNotificationSettings();
    if (permission.authorizationStatus != AuthorizationStatus.authorized &&
        permission.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }

    final token = await getToken();
    if (token == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcm_tokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  static Future<void> _registerRefreshedToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final userDoc = await userRef.get();
    if (userDoc.data()?['push_notifications'] != true) return;

    await userRef.set({
      'fcm_tokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  static Future<String?> getToken() async {
    if (kIsWeb) return null;
    return await FirebaseMessaging.instance.getToken();
  }
}
