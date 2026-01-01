import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // Import to use navigatorKey
import 'api_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize(BuildContext context) async {
    // 1. Request permissions (especially for iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
    }

    // 2. Setup Local Notifications for Foreground
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap when app is in foreground
        if (details.payload != null) {
          // You could parse the payload here, but for now we follow the data structure
        }
      },
    );

    // 3. Handle Token
    await _setupToken();

    // 4. Listen to Messages
    _setupListeners();
  }

  Future<void> _setupToken() async {
    String? token = await _fcm.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      await _registerTokenWithBackend(token);
    }

    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token Refreshed: $newToken');
      _registerTokenWithBackend(newToken);
    });
  }

  Future<void> _registerTokenWithBackend(String token) async {
    final deviceType = Platform.isAndroid ? 'android' : 'ios';
    await ApiClient.instance.registerFcmToken(token, deviceType);
  }

  void _setupListeners() {
    // A. Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground Message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // B. Background (App opened via notification tap)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Background Notification Clicked');
      _handleNotificationData(message.data);
    });

    // C. Terminated (App started via notification tap)
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App started from Notification');
        _handleNotificationData(message.data);
      }
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    final NotificationDetails details = NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails());

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: message.data['profile_id']?.toString() ?? '',
    );
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    final String? type = data['type'];
    final String? profileIdArg = data['profile_id']?.toString();
    final String? reportIdArg = data['report_id']?.toString();

    if (type == 'profile_share') {
      debugPrint('Navigating to profile share: $profileIdArg');
      // Navigate to Home or specific screen
      navigatorKey.currentState?.pushNamed('/home');
    } else if (type == 'report_upload') {
      debugPrint('Navigating to report upload: $reportIdArg');
      // Navigate to Reports screen
      navigatorKey.currentState?.pushNamed('/reports');
    }
  }
}
