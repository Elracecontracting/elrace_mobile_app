import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:el_race/data/services/hive_service.dart';
import 'package:flutter/material.dart';

class PrayerAudioService {
  static final PrayerAudioService _instance = PrayerAudioService._internal();
  factory PrayerAudioService() => _instance;
  PrayerAudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _checkTimer;
  PrayerTimes? _currentPrayerTimes;
  DateTime? _lastPlayedTime;

  // تهيئة الخدمة
  Future<void> initialize(PrayerTimes prayerTimes) async {
    _currentPrayerTimes = prayerTimes;
    await _startChecking();
  }

  // بدء التحقق الدوري من أوقات الصلاة
  Future<void> _startChecking() async {
    // إلغاء أي timer سابق
    _checkTimer?.cancel();

    // التحقق كل 30 ثانية
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _checkAndPlayAdhan();
    });

    // تحقق فوري عند البداية
    await _checkAndPlayAdhan();
  }

  // التحقق وتشغيل الأذان إذا حان الوقت
  Future<void> _checkAndPlayAdhan() async {
    if (_currentPrayerTimes == null) return;

    try {
      // التحقق من حالة كتم الصوت
      final isMuted = await HiveService.isPrayerSoundMuted();
      if (isMuted) {
        debugPrint('Prayer sound is muted, skipping adhan');
        return;
      }

      final now = DateTime.now();
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

        // التحقق إذا كان الوقت الحالي بين وقت الصلاة و 5 دقائق بعدها
        final timeDiff = now.difference(prayerTime);
        
        if (timeDiff.inSeconds >= 0 && timeDiff.inMinutes < 5) {
          // التحقق من أننا لم نشغل الأذان لهذه الصلاة مسبقاً
          if (_lastPlayedTime == null || 
              _lastPlayedTime!.difference(prayerTime).abs().inMinutes > 10) {
            debugPrint('Time for ${_getPrayerName(prayer)} prayer! Playing adhan...');
            await _playAdhan();
            _lastPlayedTime = prayerTime;
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking prayer times: $e');
    }
  }

  // تشغيل صوت الأذان
  Future<void> _playAdhan() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(1.0);
      
      // تشغيل ملف الصوت من assets
      await _audioPlayer.play(AssetSource('mp3/pray-call.mp3'));
      
      debugPrint('Adhan started playing');
    } catch (e) {
      debugPrint('Error playing adhan: $e');
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
