import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class PrayerNotificationService {
  static final PrayerNotificationService _instance =
      PrayerNotificationService._internal();
  factory PrayerNotificationService() => _instance;
  PrayerNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // تهيئة منطقة التوقيت لـ zonedSchedule
    tz.initializeTimeZones();

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
    _initialized = true;
    // debugPrint('🔔 Prayer notification service initialized');
  }

  Future<void> showAdhanNotification(String prayerName) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'prayer_adhan_channel',
      'Prayer Adhan',
      channelDescription: 'Notifications for prayer adhan times',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: false, // الصوت بيشتغل من AudioPlayer
      enableVibration: true,
      visibility: NotificationVisibility.public,
      autoCancel: true, // تختفي تلقائياً عند الضغط عليها
      ongoing: false,
      fullScreenIntent: false,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false, // الصوت بيشتغل من AudioPlayer
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      0, // notification ID - استخدام 0 لاستبدال الإشعار السابق
      '🕌 Prayer Time',
      '🔔 It\'s time for $prayerName prayer',
      details,
    );

    // debugPrint('🔔 Adhan notification shown for $prayerName');
  }

  Future<void> scheduleAdhanNotification(
    String prayerName,
    DateTime scheduledTime,
  ) async {
    await initialize();

    // استخدم وقت محلي مباشر مع exactAllowWhileIdle لضمان العمل حتى في وضع Doze
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      _buildId(prayerName, scheduledTime),
      '🕌 Prayer Time',
      '🔔 It\'s time for $prayerName prayer',
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_adhan_channel',
          'Prayer Adhan',
          channelDescription: 'Notifications for prayer adhan times',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: false,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          autoCancel: true,
          ongoing: false,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'prayer:$prayerName:${scheduledTime.millisecondsSinceEpoch}',
    );
  }

  Future<void> cancelScheduledAdhan(String prayerName, int ms) async {
    await initialize();
    final id = _buildId(prayerName, DateTime.fromMillisecondsSinceEpoch(ms));
    await _notificationsPlugin.cancel(id);
  }

  int _buildId(String prayerName, DateTime time) {
    // توليد معرف ثابت لكل صلاة/وقت لتجنب تكرار غير ضروري
    final base = prayerName.hashCode & 0x7fffffff;
    final t = time.millisecondsSinceEpoch ~/ 1000;
    return (base ^ t) & 0x7fffffff;
  }
}
