import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Request permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Local Notifications Setup (for foreground)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap when app is in foreground
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // 3. Listen for Foreground Messages
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // 4. Handle Notification Tap (Background/Terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('App opened via notification: ${message.notification?.title}');
    });

    // 5. Update Token if already logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await updateToken(user.uid);
    }
  }

  static Future<void> updateToken(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM Token updated for $uid');
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  static Future<void> subscribeToRole(String role) async {
    // Unsubscribe from others first to avoid cross-role notifications
    await unsubscribeAll();
    
    final topic = switch (role.toLowerCase()) {
      'student' => 'students',
      'warden' => 'wardens',
      'admin' => 'admins',
      _ => null,
    };

    if (topic != null) {
      await _fcm.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    }
  }

  static Future<void> unsubscribeAll() async {
    await _fcm.unsubscribeFromTopic('students');
    await _fcm.unsubscribeFromTopic('wardens');
    await _fcm.unsubscribeFromTopic('admins');
    debugPrint('Unsubscribed from all roles');
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    const iosDetails = DarwinNotificationDetails();
    const platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: message.data.toString(),
    );
  }
}
