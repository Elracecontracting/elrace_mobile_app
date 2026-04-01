import 'dart:convert';

import 'package:el_race/chat/models/models.dart';
import 'package:el_race/core/services/attendance_status_sync_service.dart';
import 'package:el_race/core/services/notification_storage_service.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/main.dart';
import 'package:el_race/ui/chat/chat_screen.dart';
import 'package:el_race/ui/presentation/Email%20Approval/screens/hr_details_screen.dart';
import 'package:el_race/ui/presentation/Email%20Approval/screens/invoice_details_screen.dart';
import 'package:el_race/ui/presentation/Email%20Approval/screens/pettycash_details_screen.dart';
import 'package:el_race/ui/presentation/Email%20Approval/screens/rfq_details_screen.dart';
import 'package:el_race/ui/presentation/Notification/notification_screen.dart';
import 'package:el_race/ui/presentation/circular_announcement/screens/circular_announcement_screen.dart';
import 'package:el_race/ui/presentation/home_screen/screens/main_screens.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/string_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  static String? _pendingTapPayload;
  static bool _isHandlingTap = false;

  static Future<void> initialize() async {
    await _firebaseMessaging.setAutoInitEnabled(true);

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

    // Ensure iOS presents incoming FCM notifications while app is in foreground.
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('📬 [FOREGROUND] Received message!');
      print('   - Title: ${message.notification?.title}');
      print('   - Body: ${message.notification?.body}');
      print('   - Data: ${message.data}');

      _showNotification(message);
      // Save notification to storage
      _saveNotificationToStorage(message);

      await _refreshAttendanceFromPushIfNeeded(
        message,
        source: 'foreground',
      );
    });

    // Handle background-tap messages (when app is resumed from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
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
      await _refreshAttendanceFromPushIfNeeded(
        message,
        source: 'background_tap',
      );
      _handleNotificationTap(message.data.toString());
    });

    // Check for initial message (when app is opened from terminated state)
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) async {
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
        await _refreshAttendanceFromPushIfNeeded(
          message,
          source: 'terminated_tap',
        );
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

        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken != null && apnsToken.isNotEmpty) {
          print('🍎 APNS token: $apnsToken');
        } else {
          print('⚠️ APNS token unavailable during initialize');
        }
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
    final data = message.data;

    final title = (notification?.title ??
            data['title']?.toString() ??
            data['notification_title']?.toString() ??
            data['sender_name']?.toString() ??
            data['chat_title']?.toString() ??
            'Notification')
        .trim();

    final body = (notification?.body ??
            data['body']?.toString() ??
            data['message']?.toString() ??
            data['text']?.toString() ??
            '')
        .trim();

    if (title.isEmpty && body.isEmpty) {
      print('⚠️ Skipping local notification: empty title/body payload');
      return;
    }

    String category = 'notification';
    if (message.data.containsKey('category')) {
      category = message.data['category'].toString();
    } else if (message.data.containsKey('type')) {
      category = message.data['type'].toString();
    }

    final isMuted = await NotificationStorageService.shouldMuteNotification(
      category: category,
      data: message.data,
    );
    if (isMuted) {
      print(
          '🔇 Foreground notification suppressed by mute settings: category=$category');
      return;
    }

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
      interruptionLevel: InterruptionLevel.active,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = message.messageId?.hashCode ??
        '${title}_${body}_${DateTime.now().millisecondsSinceEpoch}'.hashCode;

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body.isEmpty ? null : body,
      platformDetails,
      payload: message.data.toString(), // Add payload for tap handling
    );
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

  static Future<void> _refreshAttendanceFromPushIfNeeded(
    RemoteMessage message, {
    required String source,
  }) async {
    if (!_isAttendancePush(message)) {
      return;
    }

    print(
      '🕒 Attendance push trigger detected from $source. Refreshing /api/attendance/today_status',
    );

    await AttendanceStatusSyncService.refreshFromServer(
      reason: 'push_$source',
    );
  }

  static bool _isAttendancePush(RemoteMessage message) {
    final data = message.data;

    final searchSpace = <String>[
      data['category']?.toString() ?? '',
      data['type']?.toString() ?? '',
      data['model']?.toString() ?? '',
      data['model_name']?.toString() ?? '',
      data['event']?.toString() ?? '',
      data['action']?.toString() ?? '',
      data['topic']?.toString() ?? '',
      message.notification?.title ?? '',
      message.notification?.body ?? '',
    ].join(' ').toLowerCase();

    final hasAttendanceKeyword = searchSpace.contains('hr.attendance') ||
        searchSpace.contains('attendance') ||
        searchSpace.contains('biotime') ||
        searchSpace.contains('check_in') ||
        searchSpace.contains('check_out') ||
        searchSpace.contains('check in') ||
        searchSpace.contains('check out') ||
        searchSpace.contains('checkout');

    if (hasAttendanceKeyword) {
      return true;
    }

    final refreshFlag = data['refresh_attendance'] ??
        data['attendance_refresh'] ??
        data['refresh_today_status'];

    if (refreshFlag == null) {
      return false;
    }

    final normalizedFlag = refreshFlag.toString().trim().toLowerCase();
    return normalizedFlag == '1' ||
        normalizedFlag == 'true' ||
        normalizedFlag == 'yes' ||
        normalizedFlag == 'y';
  }

  static void _handleNotificationTap(String? payload) {
    if (_isHandlingTap) {
      _pendingTapPayload = payload;
      return;
    }

    final navigator = navKey.currentState;
    if (navigator == null || navKey.currentContext == null) {
      _pendingTapPayload = payload;
      print('⚠️ Navigation is not ready yet. Tap payload queued.');
      return;
    }

    _isHandlingTap = true;
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
    try {
      // Chat message notification — navigate directly to ChatScreen
      if (category == 'chat_message' || category == 'chat') {
        final chatId = payloadData?['chat_id']?.toString();
        final chatTitle = payloadData?['chat_title']?.toString() ?? '';
        final chatTypeStr = payloadData?['chat_type']?.toString() ?? 'dm';
        print('   - ✅ Chat notification! Navigating to ChatScreen...');
        print('   - chatId=$chatId, title=$chatTitle, type=$chatTypeStr');

        if (chatId != null && chatId.isNotEmpty) {
          // Lazy-import-safe: use dynamic import approach
          _navigateToChatScreen(navigator, chatId, chatTitle, chatTypeStr);
          return;
        }
      }

      // Attendance update notification — go to app home to see refreshed widget.
      if (_isAttendancePayloadData(payloadData)) {
        print('   - ✅ Attendance notification! Navigating to Main/Home...');
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
            settings: const RouteSettings(name: '/main_home_from_attendance'),
          ),
          (_) => false,
        );
        return;
      }

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
          (_) => false,
        );
        print('   - ✅ Navigation to Circular/Announcement completed!');
        return;
      }

      final recordType = _resolveRecordTypeFromPayload(payloadData);
      final recordId = _extractRecordIdFromPayload(payloadData);
      if (_navigateToLinkedRecordDetail(navigator, recordType, recordId)) {
        print('   - ✅ Navigated to detailed notification target');
        return;
      }

      // Default: Navigate to notification screen
      print('   - ✅ Navigating to notification screen...');
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const NotificationScreen(),
          settings: const RouteSettings(name: '/notification'),
        ),
        (_) => false,
      );
      print('   - ✅ Navigation completed!');
    } finally {
      _isHandlingTap = false;

      // If another tap arrived while handling this one, process the latest.
      if (_pendingTapPayload != null && _pendingTapPayload != payload) {
        final nextPayload = _pendingTapPayload;
        _pendingTapPayload = null;
        processPendingNotificationTap(forcePayload: nextPayload);
      }
    }
  }

  static void processPendingNotificationTap({String? forcePayload}) {
    final payload = forcePayload ?? _pendingTapPayload;
    if (payload == null || payload.isEmpty) return;

    _pendingTapPayload = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationTap(payload);
    });
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  static int? _extractRecordIdFromPayload(Map<String, dynamic>? data) {
    if (data == null) return null;

    final candidates = <dynamic>[
      data['record_id'],
      data['recordId'],
      data['res_id'],
      data['resId'],
      data['request_id'],
      data['hr_request_id'],
      data['rfq_id'],
      data['invoice_id'],
      data['petty_cash_id'],
      data['expense_id'],
      data['po_id'],
      data['lpo_id'],
      data['id'],
    ];

    for (final candidate in candidates) {
      final id = _toInt(candidate);
      if (id != null) return id;
    }
    return null;
  }

  static String _normalizeType(dynamic value) {
    return (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static String _resolveRecordTypeFromPayload(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return '';

    final candidates = <dynamic>[
      data['record_type'],
      data['target_type'],
      data['model_name'],
      data['model'],
      data['module'],
      data['entity'],
      data['resource_type'],
      data['type'],
      data['screen'],
      data['category'],
    ];

    for (final candidate in candidates) {
      final normalized = _normalizeType(candidate);
      if (normalized.isEmpty ||
          normalized == 'notification' ||
          normalized == 'announcement' ||
          normalized == 'circular') {
        continue;
      }

      if (normalized.contains('rfq') || normalized == 'purchasequotation') {
        return 'rfq';
      }
      if (normalized.contains('invoice') ||
          normalized.contains('accountmove')) {
        return 'invoice';
      }
      if (normalized.contains('pettycash') ||
          normalized.contains('hrexpensesheet') ||
          normalized == 'expense' ||
          normalized.contains('expense')) {
        return 'pettycash';
      }
      if (normalized == 'hr' ||
          normalized.contains('hrrequest') ||
          normalized.contains('leaverequest') ||
          normalized.contains('employeerequest')) {
        return 'hr';
      }
      if (normalized.contains('lpo') ||
          normalized == 'po' ||
          normalized.contains('purchaseorder')) {
        return 'lpo';
      }
    }

    return '';
  }

  static bool _navigateToLinkedRecordDetail(
    NavigatorState navigator,
    String recordType,
    int? recordId,
  ) {
    if (recordType.isEmpty || recordId == null) return false;

    switch (recordType) {
      case 'hr':
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => HrDetailsScreen(
              requestId: '$recordId',
              type: 'HR',
            ),
            settings: const RouteSettings(name: '/notification_hr_details'),
          ),
          (_) => false,
        );
        return true;
      case 'rfq':
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => RfqDetailsScreen(
              requestId: '$recordId',
              type: 'RFQ',
            ),
            settings: const RouteSettings(name: '/notification_rfq_details'),
          ),
          (_) => false,
        );
        return true;
      case 'invoice':
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => InvoiceDetailsScreen(
              requestId: '$recordId',
              type: 'INVOICE',
            ),
            settings:
                const RouteSettings(name: '/notification_invoice_details'),
          ),
          (_) => false,
        );
        return true;
      case 'pettycash':
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => PettyCashDetailsScreen(
              requestId: '$recordId',
              type: 'PETTYCASH',
            ),
            settings:
                const RouteSettings(name: '/notification_pettycash_details'),
          ),
          (_) => false,
        );
        return true;
      case 'lpo':
        Util.openLpoPdfReport(navKey.currentContext!, recordId);
        return true;
      default:
        return false;
    }
  }

  static bool _isAttendancePayloadData(Map<String, dynamic>? payloadData) {
    if (payloadData == null || payloadData.isEmpty) return false;

    final searchSpace = <String>[
      payloadData['category']?.toString() ?? '',
      payloadData['type']?.toString() ?? '',
      payloadData['model']?.toString() ?? '',
      payloadData['model_name']?.toString() ?? '',
      payloadData['event']?.toString() ?? '',
      payloadData['action']?.toString() ?? '',
      payloadData['topic']?.toString() ?? '',
      payloadData['refresh_attendance']?.toString() ?? '',
      payloadData['attendance_refresh']?.toString() ?? '',
      payloadData['refresh_today_status']?.toString() ?? '',
    ].join(' ').toLowerCase();

    return searchSpace.contains('hr.attendance') ||
        searchSpace.contains('attendance') ||
        searchSpace.contains('biotime') ||
        searchSpace.contains('check_in') ||
        searchSpace.contains('check_out') ||
        searchSpace.contains('check in') ||
        searchSpace.contains('check out') ||
        searchSpace.contains('checkout');
  }

  /// Navigate to ChatScreen from a push notification tap
  static void _navigateToChatScreen(
    NavigatorState navigator,
    String chatId,
    String chatTitle,
    String chatTypeStr,
  ) {
    // Import dynamically to avoid circular deps
    try {
      final chatType = chatTypeStr == 'support'
          ? ChatType.support
          : chatTypeStr == 'role'
              ? ChatType.role
              : ChatType.dm;

      // Determine peerUid for DM chats
      String? peerUid;
      if (chatType == ChatType.dm) {
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUid != null) {
          final allParts = chatId.substring(3); // remove 'dm_'
          if (allParts.startsWith('${currentUid}_')) {
            peerUid = allParts.substring(currentUid.length + 1);
          } else if (allParts.endsWith('_$currentUid')) {
            peerUid =
                allParts.substring(0, allParts.length - currentUid.length - 1);
          }
        }
      }

      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            title: chatTitle,
            chatType: chatType,
            peerUid: peerUid,
          ),
        ),
      );
      print('   - ✅ Chat navigation completed!');
    } catch (e) {
      print('   - ❌ Chat navigation failed: $e');
    }
  }
}
