import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:el_race/core/constants/hive_constants.dart';
import 'package:el_race/data/services/hive_service.dart';
import 'package:el_race/data/services/prayer_notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

// اسم المهمة
const String prayerCheckTaskName = 'prayerCheckTask';
const String rescheduleTaskName = 'reschedulePrayerTasks';

// Background callback - يجب أن يكون top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Ensure binding available in background isolate
    WidgetsFlutterBinding.ensureInitialized();

    // debugPrint('Background task started: $task');

    // if this is a reschedule task (unique name like reschedule-prayers-<day>)
    if (task == rescheduleTaskName ||
        task.toString().startsWith('reschedule-prayers-')) {
      try {
        await PrayerBackgroundService.reschedule();
        return Future.value(true);
      } catch (e) {
        // debugPrint('Error rescheduling: $e');
        return Future.value(false);
      }
    }

    try {
      // تهيئة Hive إذا لم يكن مهيأ
      if (!Hive.isBoxOpen(HiveConstants.preferencesBox)) {
        await Hive.initFlutter();
      }

      // التحقق من تسجيل الدخول
      final isLoggedIn = await HiveService.isUserLoggedIn();
      if (!isLoggedIn) {
        // debugPrint('🚫 User not logged in, skipping adhan (background)');
        return Future.value(true);
      }

      // التحقق من حالة كتم الصوت
      final isMuted = await HiveService.isPrayerSoundMuted();
      if (isMuted) {
        // debugPrint('Prayer sound is muted, skipping adhan');
        return Future.value(true);
      }

      // If task corresponds to a scheduled prayer
      final prayerName = inputData?['prayer'] as String?;
      final rawMs = inputData?['ms'];
      final parsedMs = rawMs is int ? rawMs : int.tryParse('$rawMs');

      if (prayerName != null && parsedMs != null) {
        try {
          final ms = parsedMs;

          // Prevent duplicates by checking if already played
          final playedKey = 'played_${prayerName}_$ms';
          final alreadyPlayed = await HiveService.hasPlayedPrayer(playedKey);
          if (!alreadyPlayed) {
            // تحديد إشارة أن الأذان قيد التشغيل
            await HiveService.markPrayerPlayed(playedKey);
            // ألغِ الإشعار المجدول لتجنب التكرار ثم شغّل الأذان
            await PrayerNotificationService()
                .cancelScheduledAdhan(prayerName, ms);
            // debugPrint('Playing adhan at prayer time!');
            await _playAdhanInBackground(prayerName, ms);
          } else {
            // debugPrint(
            //     '🔁 Prayer $prayerName at ${scheduledTime.toIso8601String()} already handled');
          }
        } catch (e) {
          // debugPrint('Error handling prayer task: $e');
        }
      }

      return Future.value(true);
    } catch (e) {
      // debugPrint('Error in background task: $e');
      return Future.value(false);
    }
  });
}

Future<void> _showAdhanNotificationInBackground(
    String prayerName, int ms) async {
  try {
    final notificationsPlugin = await _ensureNotificationsInitialized();

    await notificationsPlugin.show(
      0,
      '🕌 حان وقت الصلاة',
      '🔔 حان الآن وقت صلاة $prayerName',
      _defaultNotificationDetails,
    );

    // debugPrint('🔔 Background notification shown');
  } catch (e) {
    // debugPrint('Error showing notification: $e');
  }
}

Future<FlutterLocalNotificationsPlugin>
    _ensureNotificationsInitialized() async {
  final plugin = FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await plugin.initialize(settings);
  return plugin;
}

const NotificationDetails _defaultNotificationDetails = NotificationDetails(
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
    autoCancel: false,
    ongoing: false,
  ),
  iOS: DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: false,
    interruptionLevel: InterruptionLevel.timeSensitive,
  ),
);

Future<void> _playAdhanInBackground(String prayerName, int ms) async {
  try {
    final player = AudioPlayer();

    // إعداد AudioPlayer
    await player.setReleaseMode(ReleaseMode.stop);
    await player
        .setPlayerMode(PlayerMode.mediaPlayer); // استخدام media player mode

    // start with low volume and fade in for clarity
    await player.setVolume(0.1);
    await player.play(AssetSource('mp3/azan.mp3'));

    // debugPrint('Background adhan started playing (fade-in)');

    // Gradually increase volume to full over 3 seconds
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        await player.setVolume(0.1 * i);
      } catch (_) {}
    }

    // Wait until a reasonable max length (keep 4 minutes to ensure full adhan)
    await Future.delayed(const Duration(minutes: 4));
    await player.stop();
    await player.dispose();
  } catch (e) {
    // debugPrint('Error playing adhan in background: $e');
  }
}

class PrayerBackgroundService {
  static Future<void> initialize() async {
    // تهيئة Workmanager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // جدولة المهام على أوقات الصلاة
    await _schedulePrayerTasks();

    // debugPrint('Prayer background service initialized');
  }

  static Future<void> _schedulePrayerTasks() async {
    try {
      // debugPrint('🔄 Scheduling prayer tasks...');
      // إلغاء كل المهام القديمة
      await Workmanager().cancelAll();
      // debugPrint('🗑️ Cancelled all old tasks');

      final notificationService = PrayerNotificationService();
      await notificationService.initialize();

      // حساب أوقات الصلاة
      // Try to use device last-known location for accurate local Adhan times
      Position? last;
      try {
        last = await Geolocator.getLastKnownPosition();
      } catch (_) {
        last = null;
      }

      final coords = last != null
          ? Coordinates(last.latitude, last.longitude)
          : Coordinates(25.2048, 55.2708); // fallback Dubai
      final params = CalculationMethod.egyptian.getParameters()
        ..madhab = Madhab.hanafi;
      final prayerTimes = PrayerTimes.today(coords, params);

      final now = DateTime.now();
      // debugPrint('🕐 Current time: ${now.hour}:${now.minute}:${now.second}');

      final prayers = [
        {'name': 'fajr', 'time': prayerTimes.fajr},
        {'name': 'dhuhr', 'time': prayerTimes.dhuhr},
        {'name': 'asr', 'time': prayerTimes.asr},
        {'name': 'maghrib', 'time': prayerTimes.maghrib},
        {'name': 'isha', 'time': prayerTimes.isha},
      ];

      for (var prayerData in prayers) {
        final prayerTime = prayerData['time'] as DateTime;
        final prayerName = prayerData['name'] as String;

        // جدول المهمة فقط إذا كان الوقت لم يمر بعد
        if (prayerTime.isAfter(now)) {
          final delay = prayerTime.difference(now);

          final ms = prayerTime.millisecondsSinceEpoch;

          // جدولة إشعار محلي يشتغل حتى لو التطبيق مغلق
          await notificationService.scheduleAdhanNotification(
            prayerName,
            prayerTime,
          );

          await Workmanager().registerOneOffTask(
            'prayer-$prayerName-$ms',
            prayerCheckTaskName,
            inputData: {'prayer': prayerName, 'ms': ms},
            initialDelay: delay,
            constraints: Constraints(
              networkType: NetworkType.notRequired,
              requiresBatteryNotLow: false,
              requiresCharging: false,
              requiresDeviceIdle: false,
              requiresStorageNotLow: false,
            ),
          );

          // debugPrint(
          //     '✅ Scheduled $prayerName at ${prayerTime.hour}:${prayerTime.minute} (in ${delay.inMinutes}m ${delay.inSeconds % 60}s)');
        } else {
          // debugPrint('⏭️ Skipped $prayerName (already passed)');
        }
      }

      // جدول مهمة لإعادة الجدولة في منتصف الليل (للصلوات القادمة)
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 5);
      final delayUntilTomorrow = tomorrow.difference(now);

      await Workmanager().registerOneOffTask(
        'reschedule-prayers-${now.day}',
        'reschedulePrayerTasks',
        initialDelay: delayUntilTomorrow,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
        ),
      );

      // debugPrint('Scheduled $taskId prayer tasks for today');
    } catch (e) {
      // debugPrint('Error scheduling prayer tasks: $e');
    }
  }

  static Future<void> reschedule() async {
    await _schedulePrayerTasks();
  }

  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    // debugPrint('Prayer background service cancelled');
  }
}
