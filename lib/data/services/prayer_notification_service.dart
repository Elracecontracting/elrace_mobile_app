import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class PrayerNotificationService {
  static final PrayerNotificationService _instance =
      PrayerNotificationService._internal();
  factory PrayerNotificationService() => _instance;
  PrayerNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
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
    debugPrint('🔔 Prayer notification service initialized');
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
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false, // الصوت بيشتغل من AudioPlayer
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      0, // notification ID
      '🕌 حان وقت الصلاة',
      '🔔 حان الآن وقت صلاة $prayerName',
      details,
    );

    debugPrint('🔔 Adhan notification shown for $prayerName');
  }
}
