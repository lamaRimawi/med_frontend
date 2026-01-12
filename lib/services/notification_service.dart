import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../main.dart'; // Import to use navigatorKey
import 'api_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');

  // If message has notification payload, system handles it.
  // If it's a data-only message, we might need to show a local notification.
  if (message.notification == null && message.data.isNotEmpty) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // Create the channel in the background isolate as well
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    String? title = message.data['title'];
    String? body = message.data['body'] ?? message.data['message'];
    final type = message.data['type'];

    // Handle Connection Request specifically if title is missing
    if (title == null && type == 'connection_request') {
      title = 'New Connection Request';
      body = 'Someone wants to connect with you.';
    }

    if (title != null) {
      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: type,
      );
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Stream for real-time notification updates
  final StreamController<RemoteMessage> _messageStreamController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessage => _messageStreamController.stream;

  Future<void> initialize(BuildContext context) async {
    // 0. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
        AndroidInitializationSettings('@mipmap/launcher_icon');
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
          // Convert payload string back to Map or handle simpler ID
          _handlePayloadNavigation(details.payload!);
        }
      },
    );

    // Create High Importance Channel for Android
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      ),
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
      debugPrint('Foreground Message: ${message.notification?.title} | Data: ${message.data}');
      _messageStreamController.add(message);
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
    // Robust title/body extraction: check notification payload first, then data payload
    String? title = message.notification?.title;
    String? body = message.notification?.body;

    if (title == null && message.data.isNotEmpty) {
      title = message.data['title'];
      body = message.data['body'] ?? message.data['message'];
    }

    // If still empty, don't show specific notification or show defaults?
    // Usually best to skip if no content, but for "Connection Request" let's check type
    final type = message.data['type'];
    if (title == null && type == 'connection_request') {
      title = 'New Connection Request';
      body = 'Someone wants to connect with you.';
    }

    if (title == null) return;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      enableVibration: true,
      styleInformation: BigTextStyleInformation(body ?? ''), // Expandable text
    );
    final NotificationDetails details = NotificationDetails(
      android: androidDetails, 
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      details,
      payload: message.data['type'], // Storing type as payload for simple handling
    );
  }

  void _handlePayloadNavigation(String type) {
    if (type == 'connection_request') {
       navigatorKey.currentState?.pushNamed('/family', arguments: {'initialTab': 1});
    } else if (type == 'profile_share') {
       navigatorKey.currentState?.pushNamed('/family');
    }
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    final String? type = data['type'];
    final String? profileIdArg = data['profile_id']?.toString();
    final String? reportIdArg = data['report_id']?.toString();

    debugPrint('Handling Navigation Data: Type=$type');

    if (type == 'connection_request') {
      navigatorKey.currentState?.pushNamed('/family', arguments: {'initialTab': 1}); // Pass argument
    } else if (type == 'profile_share') {
      debugPrint('Navigating to profile share: $profileIdArg');
      navigatorKey.currentState?.pushNamed('/family'); 
    } else if (type == 'report_upload') {
      debugPrint('Navigating to reports: $reportIdArg');
      navigatorKey.currentState?.pushNamed('/reports', arguments: {
        'profile_id': profileIdArg,
        'report_id': reportIdArg,
      });
    }
  }
}
