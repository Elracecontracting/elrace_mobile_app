import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:el_race/core/constants/hive_constants.dart';
import 'package:el_race/data/services/hive_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

// اسم المهمة
const String prayerCheckTaskName = 'prayerCheckTask';
const String rescheduleTaskName = 'reschedulePrayerTasks';

// Background callback - يجب أن يكون top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Background task started: $task');
    
    // إذا كانت المهمة هي إعادة الجدولة
    if (task == rescheduleTaskName) {
      try {
        await PrayerBackgroundService.reschedule();
        return Future.value(true);
      } catch (e) {
        debugPrint('Error rescheduling: $e');
        return Future.value(false);
      }
    }
    
    try {
      // تهيئة Hive إذا لم يكن مهيأ
      if (!Hive.isBoxOpen(HiveConstants.preferencesBox)) {
        await Hive.initFlutter();
      }
      
      // التحقق من حالة كتم الصوت
      final isMuted = await HiveService.isPrayerSoundMuted();
      if (isMuted) {
        debugPrint('Prayer sound is muted, skipping adhan');
        return Future.value(true);
      }

      // تشغيل صوت الأذان
      debugPrint('Playing adhan at prayer time!');
      await _playAdhanInBackground();

      return Future.value(true);
    } catch (e) {
      debugPrint('Error in background task: $e');
      return Future.value(false);
    }
  });
}

Future<void> _playAdhanInBackground() async {
  try {
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setVolume(1.0);
    await player.play(AssetSource('mp3/pray-call.mp3'));
    
    debugPrint('Background adhan started playing');
    
    // الانتظار حتى ينتهي الصوت (أو وقت محدد)
    await Future.delayed(const Duration(minutes: 3));
    await player.stop();
    await player.dispose();
  } catch (e) {
    debugPrint('Error playing adhan in background: $e');
  }
}

class PrayerBackgroundService {
  static Future<void> initialize() async {
    // تهيئة Workmanager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // غيرها لـ false في Production
    );

    // جدولة المهام على أوقات الصلاة
    await _schedulePrayerTasks();

    debugPrint('Prayer background service initialized');
  }

  static Future<void> _schedulePrayerTasks() async {
    try {
      // إلغاء كل المهام القديمة
      await Workmanager().cancelAll();

      // حساب أوقات الصلاة
      final coords = Coordinates(25.2048, 55.2708); // Dubai
      final params = CalculationMethod.egyptian.getParameters()
        ..madhab = Madhab.hanafi;
      final prayerTimes = PrayerTimes.today(coords, params);

      final now = DateTime.now();
      final prayers = [
        {'name': 'fajr', 'time': prayerTimes.fajr},
        {'name': 'dhuhr', 'time': prayerTimes.dhuhr},
        {'name': 'asr', 'time': prayerTimes.asr},
        {'name': 'maghrib', 'time': prayerTimes.maghrib},
        {'name': 'isha', 'time': prayerTimes.isha},
      ];

      int taskId = 0;
      for (var prayerData in prayers) {
        final prayerTime = prayerData['time'] as DateTime;
        final prayerName = prayerData['name'] as String;

        // جدول المهمة فقط إذا كان الوقت لم يمر بعد
        if (prayerTime.isAfter(now)) {
          final delay = prayerTime.difference(now);
          
          await Workmanager().registerOneOffTask(
            'prayer-$prayerName-${prayerTime.day}',
            prayerCheckTaskName,
            initialDelay: delay,
            constraints: Constraints(
              networkType: NetworkType.notRequired,
              requiresBatteryNotLow: false,
              requiresCharging: false,
              requiresDeviceIdle: false,
              requiresStorageNotLow: false,
            ),
          );
          
          debugPrint('Scheduled $prayerName prayer task in ${delay.inMinutes} minutes');
          taskId++;
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

      debugPrint('Scheduled $taskId prayer tasks for today');
    } catch (e) {
      debugPrint('Error scheduling prayer tasks: $e');
    }
  }

  static Future<void> reschedule() async {
    await _schedulePrayerTasks();
  }

  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    debugPrint('Prayer background service cancelled');
  }
}
