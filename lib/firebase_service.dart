import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/utils/string_utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request notification permission
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');
    } else {
      print('❌ Notification permission declined');
    }

    // Initialize local notifications (for showing notifications in foreground)
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        print("🔔 Notification tapped with payload: $payload");
      },
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 Foreground message: ${message.notification?.title}');
      _showNotification(message);
    });

    // Handle background-tap messages (when app is resumed from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 App opened from notification');
    });

    // Get and print the FCM token (you can send this to your server)
    String? token = await _firebaseMessaging.getToken();
    SharedPref().setPreferencesString(fcm_token, token.toString());
    if (token != null) {
      print('📱 FCM Token: $token');
    }

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      SharedPref().setPreferencesString(fcm_token, newToken.toString());
      print('🔁 FCM Token refreshed: $newToken');
    });
  }

  static Future<String?> ensureFCMToken() async {
    try {
      // Check if we already have a token in SharedPreferences
      String? existingToken = SharedPref().getPreferenceString(fcm_token);
      if (existingToken != null && existingToken.isNotEmpty) {
        print(
            '📱 Using existing FCM Token: ${existingToken.substring(0, 20)}...');
        return existingToken;
      }

      // Try to get a new token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        SharedPref().setPreferencesString(fcm_token, token);
        print('📱 FCM Token obtained and stored: ${token.substring(0, 20)}...');
      } else {
        print('❌ Failed to get FCM token - Firebase may not be initialized');
      }
      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      print('❌ This may happen if Firebase is not properly initialized');
      return null;
    }
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title ?? 'No Title',
        notification.body ?? 'No Body',
        platformDetails,
      );
    }
  }
}
