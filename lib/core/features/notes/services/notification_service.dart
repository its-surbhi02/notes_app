import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

// 1. BACKGROUND HANDLER
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  // NEW: Plugin to show notifications locally
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // NEW: Android Channel (Required for Android 8+)
  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  Future<void> initNotifications() async {
    // A. Request Permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('User declined permission');
      return;
    }

    // B. Initialize Local Notifications (For Foreground Pop-up)
    // '@mipmap/ic_launcher' is the default app icon in Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(initializationSettings);

    // Create the channel on Android
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // C. Get Token
    final fcmToken = await _firebaseMessaging.getToken();
    debugPrint('=======================================');
    debugPrint('FCM TOKEN: $fcmToken');
    debugPrint('=======================================');

    // D. Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // E. Foreground Handler (UPDATED)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // If the message has a notification attached, show a local pop-up
      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: '@mipmap/ic_launcher', // Uses your app icon
              // Importance.high ensures the pop-up shows visually
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }
}