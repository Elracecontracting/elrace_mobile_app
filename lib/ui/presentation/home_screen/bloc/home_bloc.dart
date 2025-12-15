import 'dart:async';
import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:el_race/data/services/hive_service.dart';
import 'package:el_race/data/services/prayer_audio_service.dart';
import 'package:el_race/data/services/prayer_background_service.dart';
import 'package:equatable/equatable.dart';
import 'package:el_race/ui/presentation/Attendace_list/repository/attendance_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  static HomeBloc get(BuildContext context) => BlocProvider.of(context);
  DateTime now = DateTime.now();
  String monthName = '';
  HomeBloc() : super(HomeInitial()) {
    on<CheckInStatusChangedEvent>(checkedInMethod);
    on<FetchLastMonthAttendanceSummary>(_fetchLastMonthAttendanceSummary);
    on<ChangeCurrentIndex>((event, emit) {
      changeCurrentIndex(event, emit);
    });
    on<ChangeVisiablityIcon>((event, emit) {
      changeBottomNavVisiblity(event, emit);
    });
    on<UpdateFaceRecognitionStatus>((event, emit) {
      faceRecognitionStatus = event.status;
      emit(FaceRecognitionStatusChanged(event.status));
    });
    on<InitPrayerTimesEvent>(_initPrayerTimes);
    on<LoadPrayerMuteStateEvent>(_loadPrayerMuteState);
    on<TogglePrayerMuteStateEvent>(_togglePrayerMuteState);
    on<UpdatePrayerTickEvent>(_updatePrayerTick);
    on<ToggleReorderModeEvent>(_toggleReorderMode);
    monthName = DateFormat('MMMM').format(now);
  }
  bool isNotOpen = false;
  bool isEdit = false;
  bool isReorderMode = false;
  int currentIndex = 1;
  changeCurrentIndex(ChangeCurrentIndex event, emit) {
    emit(ChangeIndexLoading());
    currentIndex = event.index;
    emit(ChangeIndexSuccess());
  }

  bool enableBottomNav = true;
  changeBottomNavVisiblity(ChangeVisiablityIcon event, emit) {
    emit(ChangeIndexLoading());
    enableBottomNav = !enableBottomNav;
    emit(ChangeIndexSuccess());
  }

  void _toggleReorderMode(
      ToggleReorderModeEvent event, Emitter<HomeState> emit) {
    isReorderMode = !isReorderMode;
    emit(ReorderModeChanged(isReorderMode));
  }

  FutureOr<void> checkedInMethod(
      CheckInStatusChangedEvent event, Emitter<HomeState> emit) {
    emit(CheckedInSTHome());
  }

  int attendedDays = 0;
  FaceRecognitionStatus faceRecognitionStatus = FaceRecognitionStatus.idle;

  // Prayer times variables
  PrayerTimes? _prayerTimes;
  Prayer? _nextPrayer;
  DateTime? _nextPrayerTime;
  bool _isSoundMuted = false;
  Timer? _prayerTicker;
  final PrayerAudioService _audioService = PrayerAudioService();

  @override
  Future<void> close() {
    _prayerTicker?.cancel();
    _audioService.dispose();
    return super.close();
  }

  Future<void> _loadPrayerMuteState(
    LoadPrayerMuteStateEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final isMuted = await HiveService.isPrayerSoundMuted();
      _isSoundMuted = isMuted;
      emit(PrayerMuteStateChanged(isMuted));
    } catch (e) {
      debugPrint('Error loading mute state: $e');
    }
  }

  Future<void> _togglePrayerMuteState(
    TogglePrayerMuteStateEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final newState = !_isSoundMuted;
      await HiveService.setPrayerSoundMuted(newState);
      _isSoundMuted = newState;
      debugPrint(newState.toString());

      if (_prayerTimes != null) {
        emit(PrayerTimesLoaded(
          prayerTimes: _prayerTimes,
          nextPrayer: _nextPrayer,
          nextTime: _nextPrayerTime,
          isSoundMuted: _isSoundMuted,
        ));
      } else {
        emit(PrayerMuteStateChanged(newState));
      }
    } catch (e) {
      debugPrint('Error toggling mute state: $e');
    }
  }

  Future<void> _initPrayerTimes(
    InitPrayerTimesEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(const PrayerTimesLoading());

    try {
      // جلب أوقات الصلاة من API
      final response = await http.post(
        Uri.parse('https://test.elrace.com/api/prayer_times'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "params": {"country_code": "AE"}
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['result']?['status'] == 'success') {
          _setPrayerTimesFromAPI(data['result']['data']);

          emit(PrayerTimesLoaded(
            prayerTimes: _prayerTimes,
            nextPrayer: _nextPrayer,
            nextTime: _nextPrayerTime,
            isSoundMuted: _isSoundMuted,
          ));

          _startPrayerTicker();

          // تهيئة خدمة الصوت
          if (_prayerTimes != null) {
            await _audioService.initialize(_prayerTimes!);
            // إعادة جدولة المهام الخلفية مع أوقات الصلاة الجديدة
            await PrayerBackgroundService.reschedule();
          }

          return;
        }
      }

      throw Exception('Failed to fetch prayer times from API');
    } catch (e) {
      // Fallback: استخدام الحساب المحلي
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          _setPrayerTimesFor(Coordinates(last.latitude, last.longitude));
        } else {
          _setPrayerTimesFor(Coordinates(25.2048, 55.2708)); // Dubai
        }
      } catch (_) {
        _setPrayerTimesFor(Coordinates(25.2048, 55.2708));
      }

      emit(PrayerTimesError(
        error: 'Using local calculation',
        prayerTimes: _prayerTimes,
        isSoundMuted: _isSoundMuted,
      ));

      _startPrayerTicker();

      // تهيئة خدمة الصوت
      if (_prayerTimes != null) {
        await _audioService.initialize(_prayerTimes!);
        // إعادة جدولة المهام الخلفية
        await PrayerBackgroundService.reschedule();
      }
    }
  }

  void _setPrayerTimesFromAPI(Map<String, dynamic> apiData) {
    // final prayers = apiData['prayers'] as List;
    final nextPrayerData = apiData['next_prayer'];

    // إنشاء PrayerTimes object باستخدام positional parameters
    final coords = Coordinates(25.2048, 55.2708); // Dubai
    final params = CalculationMethod.egyptian.getParameters();
    final dateComponents = DateComponents.from(DateTime.now());

    // استخدام constructor مع positional parameters
    _prayerTimes = PrayerTimes(
      coords,
      dateComponents,
      params,
    );

    // تحديد الصلاة القادمة من API
    final nextPrayerTitle = nextPrayerData['title'] as String;
    _nextPrayer = _getPrayerFromTitle(nextPrayerTitle);

    // حساب الوقت المتبقي من remaining_time
    final remainingTime =
        nextPrayerData['remaining_time'] as String; // "05:36:29"
    final parts = remainingTime.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = int.parse(parts[2]);

    _nextPrayerTime = DateTime.now().add(
      Duration(hours: hours, minutes: minutes, seconds: seconds),
    );
  }

  // DateTime _parseTime(String timeStr) {
  //   final parts = timeStr.split(':');
  //   final hour = int.parse(parts[0]);
  //   final minute = int.parse(parts[1]);
  //   final now = DateTime.now();
  //   return DateTime(now.year, now.month, now.day, hour, minute);
  // }

  Prayer _getPrayerFromTitle(String title) {
    switch (title.toLowerCase()) {
      case 'fajr':
        return Prayer.fajr;
      case 'dhuhr':
        return Prayer.dhuhr;
      case 'asr':
        return Prayer.asr;
      case 'maghrib':
        return Prayer.maghrib;
      case 'isha':
        return Prayer.isha;
      default:
        return Prayer.fajr;
    }
  }

  void _setPrayerTimesFor(Coordinates coords) {
    final params = CalculationMethod.egyptian.getParameters()
      ..madhab = Madhab.hanafi;

    final pt = PrayerTimes.today(coords, params);
    final n = pt.nextPrayer();
    final nt = pt.timeForPrayer(n);

    _prayerTimes = pt;
    _nextPrayer = n;
    _nextPrayerTime = nt;
  }

  void _startPrayerTicker() {
    _prayerTicker?.cancel();
    if (_prayerTimes == null) return;

    _prayerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) {
        add(const UpdatePrayerTickEvent());
      }
    });
  }

  Future<void> _updatePrayerTick(
    UpdatePrayerTickEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (_prayerTimes == null) return;

    final n = _prayerTimes!.nextPrayer();
    final nt = _prayerTimes!.timeForPrayer(n);

    if (n != _nextPrayer || nt != _nextPrayerTime) {
      _nextPrayer = n;
      _nextPrayerTime = nt;

      // تحديث خدمة الصوت بأوقات الصلاة الجديدة
      _audioService.updatePrayerTimes(_prayerTimes!);
    }

    emit(PrayerTimesLoaded(
      prayerTimes: _prayerTimes,
      nextPrayer: _nextPrayer,
      nextTime: _nextPrayerTime,
      isSoundMuted: _isSoundMuted,
    ));
  }

  Future<void> _fetchLastMonthAttendanceSummary(
    FetchLastMonthAttendanceSummary event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(const LastMonthAttendanceSummaryLoading());
      final now = DateTime.now();
      final firstDayOfLastMonth = DateTime(now.year, now.month, 1);
      final lastDayOfLastMonth = DateTime(now.year, now.month + 1, 0);

      final summary = await AttendanceRepo().getAttendanceSummary(
        startDate: DateFormat('yyyy-MM-dd').format(firstDayOfLastMonth),
        endDate: DateFormat('yyyy-MM-dd').format(lastDayOfLastMonth),
      );
      attendedDays = summary['working_days'] ?? 0;
      emit(const LastMonthAttendanceSummaryLoaded());
      // No emit here, just set the variable
    } catch (e) {
      emit(LastMonthAttendanceSummaryError(e.toString()));
    }
  }

  int get getAttendedDays => attendedDays;
}
