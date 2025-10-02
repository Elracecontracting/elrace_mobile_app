
import 'dart:async';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:get/get.dart';

class TimerController extends GetxController {
  final Rx<Duration> timeLeft = const Duration(hours: 8).obs;

  Timer? _timer;
  DateTime? _checkInTime;
  Duration _initialRemaining = const Duration(hours: 8);

  @override
  void onInit() {
    super.onInit();
    _loadState();
  }

  Future<void> _loadState() async {
    final isCheckedIn = SharedPref().getPreferenceBoolean('isCheckedIn');
    final checkInMillis = SharedPref().getPreferenceInt('checkInTime');
    final savedTimeLeftMillis = SharedPref().getPreferenceInt('timeLeft');

    _initialRemaining = Duration(milliseconds: savedTimeLeftMillis);
  
    timeLeft.value = _initialRemaining;

    if (isCheckedIn) {
      _checkInTime = DateTime.fromMillisecondsSinceEpoch(checkInMillis);
      _startCountdown();
    }
  }

  Future<void> startTimer() async {
    
    _checkInTime = DateTime.now();
    _initialRemaining = const Duration(hours: 8);

    await SharedPref().setPreferenceInt('checkInTime', _checkInTime!.millisecondsSinceEpoch);
    await SharedPref().setPreferencesBoolean('isCheckedIn', true);
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    final startTime = _checkInTime!;
    final initial = _initialRemaining;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final elapsed = DateTime.now().difference(startTime);
      final remaining = initial - elapsed;

      if (remaining.inSeconds <= 0) {
        timeLeft.value = Duration.zero;
        _timer?.cancel(); // Make sure the timer is stopped immediately
        _timer = null;
      } else {
        timeLeft.value = remaining;
      }
    });
  }


  Future<void> stopTimer() async {
    _timer?.cancel();
    _timer = null;
    
    if(_checkInTime == null) {
      SharedPref().removePreference('checkInTime');
      SharedPref().removePreference('isCheckedIn');
      SharedPref().removePreference('timeLeft');
      return;
    }

    final elapsed = DateTime.now().difference(_checkInTime!);
    final updatedRemaining = _initialRemaining - elapsed;

    await SharedPref().setPreferencesBoolean('isCheckedIn', false);
    await SharedPref().removePreference('checkInTime');
    await SharedPref().setPreferenceInt('timeLeft', updatedRemaining.inMilliseconds);

    _initialRemaining = updatedRemaining;
    timeLeft.value = updatedRemaining;
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

