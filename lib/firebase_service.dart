import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/utils/string_utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request notification permission with more detailed settings
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('🔔 Notification permission status: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('⚠️ Provisional notification permission granted');
    } else {
      print(
          '❌ Notification permission declined: ${settings.authorizationStatus}');
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
    try {
      // For iOS, we need to wait for APNS token first
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        print('🍎 iOS detected - waiting for APNS token...');
        // Wait a bit for APNS token to be available
        await Future.delayed(const Duration(seconds: 2));
      }

      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        SharedPref().setPreferencesString(fcm_token, token);
        print('📱 FCM Token obtained: ${token.substring(0, 20)}...');
      } else {
        print('❌ FCM Token is null - this may indicate APNS token issue');
      }
    } catch (e) {
      print('❌ Error getting FCM token during initialization: $e');
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
      String existingToken = SharedPref().getPreferenceString(fcm_token);
      if (existingToken.isNotEmpty) {
        print(
            '📱 Using existing FCM Token: ${existingToken.substring(0, 20)}...');
        return existingToken;
      }

      // For iOS, check APNS token first
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        print('🍎 Checking APNS token availability...');
        try {
          String? apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken == null) {
            print('⚠️ APNS token not available yet, waiting...');
            print('💡 This usually means:');
            print('   1. Push Notifications capability not enabled in Xcode');
            print('   2. App not signed with proper provisioning profile');
            print('   3. Running on simulator (APNS not supported)');
            print('   4. Firebase APNS configuration missing');

            // Wait and retry a few times
            for (int i = 0; i < 5; i++) {
              await Future.delayed(const Duration(seconds: 1));
              apnsToken = await _firebaseMessaging.getAPNSToken();
              if (apnsToken != null) {
                print('✅ APNS token obtained after ${i + 1} attempts');
                break;
              }
            }
            if (apnsToken == null) {
              print('❌ APNS token still not available after 5 attempts');
              print('🔧 Please check the troubleshooting steps below');
              return null;
            }
          } else {
            print(
                '✅ APNS token is available: ${apnsToken.substring(0, 20)}...');
          }
        } catch (apnsError) {
          print('❌ Error checking APNS token: $apnsError');
        }
      }

      // Try to get a new FCM token
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

  /// Test method to manually check FCM token generation
  static Future<void> testFCMToken() async {
    print('🧪 Testing FCM Token generation...');
    try {
      String? token = await ensureFCMToken();
      if (token != null) {
        print('✅ FCM Token test successful: ${token.substring(0, 20)}...');
      } else {
        print('❌ FCM Token test failed - no token generated');
        print('🔄 Trying alternative method...');
        await testFCMTokenAlternative();
      }
    } catch (e) {
      print('❌ FCM Token test error: $e');
    }
  }

  /// Alternative method to get FCM token without APNS dependency
  static Future<String?> testFCMTokenAlternative() async {
    print('🔄 Trying alternative FCM token retrieval...');
    try {
      // Try to get token directly without APNS check
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('✅ Alternative method successful: ${token.substring(0, 20)}...');
        SharedPref().setPreferencesString(fcm_token, token);
        return token;
      } else {
        print('❌ Alternative method also failed');
        return null;
      }
    } catch (e) {
      print('❌ Alternative method error: $e');
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
