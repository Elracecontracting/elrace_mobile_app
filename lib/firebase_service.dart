import 'dart:convert';

import 'package:el_race/core/services/notification_storage_service.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/main.dart';
import 'package:el_race/ui/presentation/Notification/notification_screen.dart';
import 'package:el_race/ui/presentation/circular_announcement/screens/circular_announcement_screen.dart';
import 'package:el_race/utils/string_utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Track processed notification message IDs to avoid duplicate handling
  static final Set<String> _processedMessageIds = {};

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
        print("🔔 [LOCAL NOTIFICATION TAP] Notification tapped!");
        print("   - Payload: $payload");
        print("   - Action ID: ${response.actionId}");
        print("   - Notification ID: ${response.id}");
        // Handle notification tap - navigate to notification screen if needed
        _handleNotificationTap(payload);
      },
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 [FOREGROUND] Received message!');
      print('   - Title: ${message.notification?.title}');
      print('   - Body: ${message.notification?.body}');
      print('   - Data: ${message.data}');
      _showNotification(message);
      // Save notification to storage
      _saveNotificationToStorage(message);
    });

    // Handle background-tap messages (when app is resumed from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final messageId = message.messageId ?? message.data.toString();
      print('📲 [BACKGROUND TAP] App opened from notification!');
      print('   - Message ID: $messageId');
      print('   - Title: ${message.notification?.title}');
      print('   - Data: ${message.data}');

      // Check if already processed
      if (_processedMessageIds.contains(messageId)) {
        print('   - ⚠️ Message already processed, ignoring');
        return;
      }

      _processedMessageIds.add(messageId);
      print(
          '   - ✅ Processing message (${_processedMessageIds.length} total processed)');

      // Save notification to storage if not already saved
      _saveNotificationToStorage(message);
      _handleNotificationTap(message.data.toString());
    });

    // Check for initial message (when app is opened from terminated state)
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        final messageId = message.messageId ?? message.data.toString();
        print('📲 [TERMINATED TAP] App opened from notification!');
        print('   - Message ID: $messageId');
        print('   - Title: ${message.notification?.title}');
        print('   - Data: ${message.data}');

        // Check if already processed
        if (_processedMessageIds.contains(messageId)) {
          print('   - ⚠️ Message already processed, ignoring');
          return;
        }

        _processedMessageIds.add(messageId);
        print(
            '   - ✅ Processing message (${_processedMessageIds.length} total processed)');

        _saveNotificationToStorage(message);
        _handleNotificationTap(message.data.toString());
      } else {
        print('ℹ️ [TERMINATED] No initial message found');
      }
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
        print('📱 FCM Token obtained: $token'); // full token for debugging
      } else {
        print('❌ FCM Token is null - this may indicate APNS token issue');
      }
    } catch (e) {
      print('❌ Error getting FCM token during initialization: $e');
    }

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      SharedPref().setPreferencesString(fcm_token, newToken.toString());
      print('🔁 FCM Token refreshed: $newToken'); // full token for debugging
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
        channelShowBadge: true,
        enableVibration: true,
        playSound: true,
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
        payload: message.data.toString(), // Add payload for tap handling
      );
    }
  }

  static Future<void> _saveNotificationToStorage(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification != null) {
        // Determine category from message data
        String category = 'notification'; // default
        if (message.data.containsKey('category')) {
          category = message.data['category'].toString();
        } else if (message.data.containsKey('type')) {
          category = message.data['type'].toString();
        }

        await NotificationStorageService.saveNotification(
          title: notification.title ?? 'Notification',
          body: notification.body ?? '',
          imageUrl:
              notification.android?.imageUrl ?? notification.apple?.imageUrl,
          data: message.data,
          category: category,
        );
      }
    } catch (e) {
      print('❌ Error saving notification to storage: $e');
    }
  }

  static void _handleNotificationTap(String? payload) {
    print('\n🔔 [HANDLE TAP] Starting to handle notification tap');
    print('   - Payload: $payload');
    print('   - Context available: ${navKey.currentContext != null}');

    // Parse payload to check for circular/announcement type
    Map<String, dynamic>? payloadData;
    try {
      if (payload != null && payload.isNotEmpty) {
        // Try to parse as JSON if it looks like JSON
        if (payload.startsWith('{')) {
          payloadData = jsonDecode(payload);
        } else {
          // Handle the toString() format: {key: value, key2: value2}
          final cleanPayload = payload.replaceAll('{', '').replaceAll('}', '');
          final pairs = cleanPayload.split(',');
          payloadData = {};
          for (final pair in pairs) {
            final keyValue = pair.split(':');
            if (keyValue.length >= 2) {
              final key = keyValue[0].trim();
              final value = keyValue.sublist(1).join(':').trim();
              payloadData[key] = value;
            }
          }
        }
        print('   - Parsed payload: $payloadData');
      }
    } catch (e) {
      print('   - Failed to parse payload: $e');
    }

    // Check if this is a circular or announcement notification
    final category = payloadData?['category']?.toString().toLowerCase() ??
        payloadData?['type']?.toString().toLowerCase() ??
        '';
    final itemId = int.tryParse(payloadData?['id']?.toString() ?? '');

    print('   - Category: $category');
    print('   - Item ID: $itemId');

    // Navigate based on notification type
    if (navKey.currentContext != null) {
      final navigator = Navigator.of(navKey.currentContext!);

      if (category == 'circular' || category == 'announcement') {
        // Navigate to CircularAnnouncementScreen
        print('   - ✅ Navigating to Circular/Announcement screen...');

        final initialTabIndex = category == 'announcement' ? 1 : 0;

        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => CircularAnnouncementScreen(
              initialTabIndex: initialTabIndex,
              autoOpenItemId: itemId,
              autoOpenCategory: category,
            ),
            settings: const RouteSettings(name: '/circular_announcement'),
          ),
          (route) => route.isFirst,
        );
        print('   - ✅ Navigation to Circular/Announcement completed!');
        return;
      }

      // Default: Navigate to notification screen
      final currentRoute = ModalRoute.of(navKey.currentContext!);
      print('   - Current route name: ${currentRoute?.settings.name}');

      final isOnNotificationScreen =
          currentRoute?.settings.name == '/notification' ||
              currentRoute?.settings.arguments is NotificationScreen;

      print('   - Is on notification screen: $isOnNotificationScreen');

      if (!isOnNotificationScreen) {
        print('   - ✅ Navigating to notification screen...');

        // Remove any existing notification screens from stack and push new one
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const NotificationScreen(),
            settings: const RouteSettings(name: '/notification'),
          ),
          (route) => route.isFirst, // Keep only the first route (home)
        );
        print('   - ✅ Navigation completed!');
      } else {
        print('   - ⏭️ Already on notification screen, ignoring tap');
      }
    } else {
      print('⚠️ Navigation context is null, waiting for app to initialize...');
      // Retry after a delay if context is not available yet
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(payload);
      });
    }
  }
}
