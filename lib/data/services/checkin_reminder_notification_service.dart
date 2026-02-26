import 'package:el_race/core/utils/shared_pref.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

/// خدمة إشعارات تذكير Check In/Out
///
/// التذكيرات:
/// • إذا عمل check in وما عمل check out:
///   - من الساعة 4 مساءً - 5 مساءً: إشعار كل 15 دقيقة
/// • إذا ما عمل check in:
///   - من الساعة 8 صباحاً - 9 صباحاً: إشعار كل 15 دقيقة
///
/// التوقيت: الإمارات (GMT+4)
class CheckInReminderNotificationService {
  static final CheckInReminderNotificationService _instance =
      CheckInReminderNotificationService._internal();
  factory CheckInReminderNotificationService() => _instance;
  CheckInReminderNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Notification IDs
  static const int _checkOutReminderId = 1000;
  static const int _checkInReminderId = 2000;

  Future<void> initialize() async {
    if (_initialized) return;

    // تهيئة منطقة التوقيت
    tz.initializeTimeZones();

    // تعيين توقيت الإمارات (GMT+4)
    tz.setLocalLocation(tz.getLocation('Asia/Dubai'));

    // طلب صلاحية الإشعارات
    await _requestNotificationPermissions();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);

    // إنشاء قنوات الإشعارات لـ Android
    await _createNotificationChannels();

    _initialized = true;
    print('🔔 Check-in/out reminder notification service initialized');
  }

  /// طلب صلاحيات الإشعارات والإشعارات الدقيقة
  Future<void> _requestNotificationPermissions() async {
    try {
      // طلب صلاحية الإشعارات العادية (Android 13+)
      final notificationStatus = await Permission.notification.request();
      print('📱 Notification permission: ${notificationStatus.isGranted}');

      // طلب صلاحية الإشعارات الدقيقة (Exact Alarms)
      // على Android 12 (API 31) وما فوق
      if (await Permission.scheduleExactAlarm.isDenied) {
        print('⚠️ Requesting exact alarm permission...');
        // في Android 14+ المستخدم يحتاج الموافقة يدوياً من الإعدادات
        await Permission.scheduleExactAlarm.request();
      }

      final alarmStatus = await Permission.scheduleExactAlarm.status;
      print('⏰ Exact alarm permission: ${alarmStatus.isGranted}');

      if (!alarmStatus.isGranted) {
        print('❌ Exact alarm permission NOT granted!');
        print('💡 User needs to enable "Alarms & reminders" in app settings');
      }
    } catch (e) {
      print('⚠️ Error requesting permissions: $e');
    }
  }

  /// إنشاء قنوات الإشعارات لـ Android
  Future<void> _createNotificationChannels() async {
    // قناة تذكيرات Check In
    const AndroidNotificationChannel checkInChannel = AndroidNotificationChannel(
      'check_in_reminder_channel',
      'Check In Reminders',
      description: 'Check-in reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // قناة تذكيرات Check Out
    const AndroidNotificationChannel checkOutChannel = AndroidNotificationChannel(
      'check_out_reminder_channel',
      'Check Out Reminders',
      description: 'Check-out reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // إنشاء القنوات
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(checkInChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(checkOutChannel);

    print('✅ Check-in/out notification channels created');
  }

  /// جدولة إشعارات التذكير بـ check out (من 4 مساءً - 5 مساءً)
  Future<void> scheduleCheckOutReminders() async {
    await initialize();
    await cancelCheckOutReminders(); // إلغاء أي إشعارات سابقة

    final now = tz.TZDateTime.now(tz.local);
    print('⏰ Current time: ${now.toString()}');

    // جدول إشعارات كل 15 دقيقة من الساعة 4 مساءً حتى 5 مساءً
    final reminderTimes = [
      // 4:00 PM
      tz.TZDateTime(tz.local, now.year, now.month, now.day, 16, 0),
      // 4:15 PM
      tz.TZDateTime(tz.local, now.year, now.month, now.day, 16, 15),
      // 4:30 PM
      tz.TZDateTime(tz.local, now.year, now.month, now.day, 16, 30),
      // 4:45 PM
      tz.TZDateTime(tz.local, now.year, now.month, now.day, 16, 45),
      // 5:00 PM (آخر تذكير)
      tz.TZDateTime(tz.local, now.year, now.month, now.day, 17, 0),
    ];

    int idCounter = _checkOutReminderId;
    int scheduledCount = 0;
    for (var scheduledTime in reminderTimes) {
      // إذا كان الوقت قد مضى اليوم، جدول لليوم التالي
      var targetTime = scheduledTime;
      if (targetTime.isBefore(now)) {
        targetTime = targetTime.add(const Duration(days: 1));
      }

      try {
        await _notificationsPlugin.zonedSchedule(
          idCounter,
          '⏰ Check Out Reminder',
          'Don\'t forget to Check Out',
          targetTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'check_out_reminder_channel',
              'Check Out Reminders',
              channelDescription: 'Check-out reminders',
              importance: Importance.max,
              priority: Priority.max,
              category: AndroidNotificationCategory.alarm,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
              fullScreenIntent: false,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time, // يتكرر يومياً
        );
        scheduledCount++;
        print(
            '✅ Scheduled check-out reminder #${idCounter - _checkOutReminderId + 1} at ${targetTime.toString()}');
      } catch (e) {
        print('❌ Error scheduling check-out reminder #${idCounter}: $e');
      }

      idCounter++;
    }

    print(
        '✅ Successfully scheduled $scheduledCount/${reminderTimes.length} check-out reminders (4 PM - 5 PM)');
  }

  /// جدولة إشعارات التذكير بـ check in (من 8 صباحاً - 9 صباحاً)
  Future<void> scheduleCheckInReminders() async {
    await initialize();
    await cancelCheckInReminders(); // إلغاء أي إشعارات سابقة

    final now = tz.TZDateTime.now(tz.local);
    print('⏰ Current time: ${now.toString()}');

    // جدول إشعارات كل 15 دقيقة من الساعة 8 صباحاً حتى 9 صباحاً
    final reminderTimes = [
      // 8:00 AM
      tz.TZDateTime(tz.local, now.year, now.month, now.day, 8, 0),
      // 8:15 AM
      tz.TZDateTime(tz.local, now.year, now.month, now.day, 8, 15),
      // 8:30 AM
      tz.TZDateTime(tz.local, now.year, now.month, now.day, 8, 30),
      // 8:45 AM
      tz.TZDateTime(tz.local, now.year, now.month, now.day, 8, 45),
      // 9:00 AM (آخر تذكير)
      tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0),
    ];

    int idCounter = _checkInReminderId;
    int scheduledCount = 0;
    for (var scheduledTime in reminderTimes) {
      // إذا كان الوقت قد مضى اليوم، جدول لليوم التالي
      var targetTime = scheduledTime;
      if (targetTime.isBefore(now)) {
        targetTime = targetTime.add(const Duration(days: 1));
      }

      try {
        await _notificationsPlugin.zonedSchedule(
          idCounter,
          '⏰ Check In Reminder',
          'Don\'t forget to Check In',
          targetTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'check_in_reminder_channel',
              'Check In Reminders',
              channelDescription: 'Check-in reminders',
              importance: Importance.max,
              priority: Priority.max,
              category: AndroidNotificationCategory.alarm,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
              fullScreenIntent: false,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time, // يتكرر يومياً
        );
        scheduledCount++;
        print(
            '✅ Scheduled check-in reminder #${idCounter - _checkInReminderId + 1} at ${targetTime.toString()}');
      } catch (e) {
        print('❌ Error scheduling check-in reminder #${idCounter}: $e');
      }

      idCounter++;
    }

    print(
        '✅ Successfully scheduled $scheduledCount/${reminderTimes.length} check-in reminders (8 AM - 9 AM)');
  }

  /// إلغاء تذكيرات check out
  Future<void> cancelCheckOutReminders() async {
    await initialize();
    // إلغاء 5 إشعارات (4:00, 4:15, 4:30, 4:45, 5:00)
    for (int i = 0; i < 5; i++) {
      await _notificationsPlugin.cancel(_checkOutReminderId + i);
    }
    print('🔕 Cancelled check-out reminders');
  }

  /// إلغاء تذكيرات check in
  Future<void> cancelCheckInReminders() async {
    await initialize();
    // إلغاء 5 إشعارات (8:00, 8:15, 8:30, 8:45, 9:00)
    for (int i = 0; i < 5; i++) {
      await _notificationsPlugin.cancel(_checkInReminderId + i);
    }
    print('🔕 Cancelled check-in reminders');
  }

  /// تحديث الإشعارات حسب حالة check in/out
  Future<void> updateReminders() async {
    final isCheckedIn = SharedPref().getPreferenceBoolean('isCheckedIn');

    if (isCheckedIn) {
      // المستخدم عامل check in - جدول تذكيرات check out وألغي تذكيرات check in
      await cancelCheckInReminders();
      await scheduleCheckOutReminders();
      print('📱 Updated: Scheduled check-out reminders (user is checked in)');
    } else {
      // المستخدم ما عامل check in - جدول تذكيرات check in وألغي تذكيرات check out
      await cancelCheckOutReminders();
      await scheduleCheckInReminders();
      print(
          '📱 Updated: Scheduled check-in reminders (user is NOT checked in)');
    }
  }

  /// إلغاء جميع التذكيرات
  Future<void> cancelAllReminders() async {
    await cancelCheckInReminders();
    await cancelCheckOutReminders();
    print('🔕 Cancelled all check-in/out reminders');
  }

  /// [للاختبار] إرسال إشعار تجريبي فوري
  Future<void> sendTestNotification({bool isCheckIn = true}) async {
    await initialize();
    try {
      await _notificationsPlugin.show(
        99999, // رقم مؤقت للاختبار
        isCheckIn
            ? '🧪 Test: Check In Reminder'
            : '🧪 Test: Check Out Reminder',
        isCheckIn
            ? 'This is a test notification - Don\'t forget to Check In'
            : 'This is a test notification - Don\'t forget to Check Out',
        NotificationDetails(
          android: AndroidNotificationDetails(
            isCheckIn
                ? 'check_in_reminder_channel'
                : 'check_out_reminder_channel',
            isCheckIn ? 'Check In Reminders' : 'Check Out Reminders',
            channelDescription: isCheckIn
                ? 'Check-in reminders'
                : 'Check-out reminders',
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.alarm,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            fullScreenIntent: false,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      print(
          '✅ Test notification sent successfully (${isCheckIn ? "Check In" : "Check Out"})');
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }
}
