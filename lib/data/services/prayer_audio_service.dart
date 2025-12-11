import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/data/services/hive_service.dart';
import 'package:el_race/data/services/prayer_notification_service.dart';
import 'package:flutter/material.dart';

class PrayerAudioService {
  static final PrayerAudioService _instance = PrayerAudioService._internal();
  factory PrayerAudioService() => _instance;
  PrayerAudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final PrayerNotificationService _notificationService =
      PrayerNotificationService();
  Timer? _checkTimer;
  PrayerTimes? _currentPrayerTimes;
  DateTime? _lastPlayedTime;

  // تهيئة الخدمة
  Future<void> initialize(PrayerTimes prayerTimes) async {
    debugPrint('🕌 PrayerAudioService: Initializing...');
    _currentPrayerTimes = prayerTimes;
    await _notificationService.initialize();
    await _startChecking();
    debugPrint('🕌 PrayerAudioService: Initialized successfully');
  }

  // بدء التحقق الدوري من أوقات الصلاة
  Future<void> _startChecking() async {
    // إلغاء أي timer سابق
    _checkTimer?.cancel();
    debugPrint('⏰ Starting prayer check timer (every 30 seconds)');

    // التحقق كل 30 ثانية
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      debugPrint('⏰ Timer tick - checking prayer times...');
      await _checkAndPlayAdhan();
    });

    // تحقق فوري عند البداية
    debugPrint('⏰ Initial check at startup');
    await _checkAndPlayAdhan();
  }

  // التحقق وتشغيل الأذان إذا حان الوقت
  Future<void> _checkAndPlayAdhan() async {
    if (_currentPrayerTimes == null) {
      debugPrint('❌ Prayer times not initialized');
      return;
    }

    try {
      // التحقق من تسجيل الدخول
      final isLoggedIn = SharedPref.isUserAuthenticated();
      debugPrint('🔑 User logged in: $isLoggedIn');
      if (!isLoggedIn) {
        debugPrint('🚫 User not logged in, skipping adhan');
        return;
      }

      // التحقق من حالة كتم الصوت
      final isMuted = await HiveService.isPrayerSoundMuted();
      debugPrint('🔊 Sound muted: $isMuted');
      if (isMuted) {
        debugPrint('🔇 Prayer sound is muted, skipping adhan');
        return;
      }

      final now = DateTime.now();
      debugPrint('🕐 Current time: ${now.hour}:${now.minute}:${now.second}');

      final prayers = [
        {'prayer': Prayer.fajr, 'time': _currentPrayerTimes!.fajr},
        {'prayer': Prayer.dhuhr, 'time': _currentPrayerTimes!.dhuhr},
        {'prayer': Prayer.asr, 'time': _currentPrayerTimes!.asr},
        {'prayer': Prayer.maghrib, 'time': _currentPrayerTimes!.maghrib},
        {'prayer': Prayer.isha, 'time': _currentPrayerTimes!.isha},
      ];

      for (var prayerData in prayers) {
        final prayerTime = prayerData['time'] as DateTime;
        final prayer = prayerData['prayer'] as Prayer;
        final prayerName = _getPrayerName(prayer);

        // التحقق إذا كان الوقت الحالي بين وقت الصلاة و 5 دقائق بعدها
        final timeDiff = now.difference(prayerTime);

        debugPrint(
            '📋 Checking $prayerName: time=${prayerTime.hour}:${prayerTime.minute}, diff=${timeDiff.inSeconds}s');

        if (timeDiff.inSeconds >= 0 && timeDiff.inMinutes < 5) {
          // التحقق من أننا لم نشغل الأذان لهذه الصلاة مسبقاً
          if (_lastPlayedTime == null ||
              _lastPlayedTime!.difference(prayerTime).abs().inMinutes > 10) {
            debugPrint('✅ Time for $prayerName prayer! Playing adhan...');
            await _notificationService.showAdhanNotification(prayerName);
            await _playAdhan();
            _lastPlayedTime = prayerTime;
            break;
          } else {
            debugPrint('⏭️ Already played for this prayer time');
          }
        }
      }
      debugPrint('✓ Check completed');
    } catch (e) {
      debugPrint('❌ Error checking prayer times: $e');
    }
  }

  // تشغيل صوت الأذان
  Future<void> _playAdhan() async {
    try {
      debugPrint('🎵 Starting adhan playback...');
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(1.0);
      debugPrint('🔊 Volume set to 100%');

      // تشغيل ملف الصوت من assets
      await _audioPlayer.play(AssetSource('mp3/pray-call.mp3'));

      debugPrint('✅ Adhan started playing successfully!');
    } catch (e) {
      debugPrint('❌ Error playing adhan: $e');
    }
  }

  // إيقاف صوت الأذان
  Future<void> stopAdhan() async {
    try {
      await _audioPlayer.stop();
      debugPrint('Adhan stopped');
    } catch (e) {
      debugPrint('Error stopping adhan: $e');
    }
  }

  // تحديث أوقات الصلاة
  void updatePrayerTimes(PrayerTimes prayerTimes) {
    _currentPrayerTimes = prayerTimes;
    _lastPlayedTime = null; // إعادة تعيين آخر وقت تشغيل
  }

  // الحصول على اسم الصلاة
  String _getPrayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.dhuhr:
        return 'Dhuhr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
      default:
        return 'Unknown';
    }
  }

  // تنظيف الموارد
  void dispose() {
    _checkTimer?.cancel();
    _audioPlayer.dispose();
  }
}
