import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:el_race/data/services/hive_service.dart';
import 'package:equatable/equatable.dart';
import 'package:el_race/ui/presentation/Attendace_list/repository/attendance_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
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
    on<ChangeCurrentIndex>((event,emit){
      changeCurrentIndex(event, emit);
    });
    on<ChangeVisiablityIcon>((event,emit){
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
    monthName = DateFormat('MMMM').format(now);
  }
  bool isNotOpen=false;
  bool isEdit=false;
  int currentIndex = 1;
  changeCurrentIndex(ChangeCurrentIndex event,emit){
    emit(ChangeIndexLoading());
    currentIndex = event.index;
    emit(ChangeIndexSuccess());
  }

  bool enableBottomNav = true;
  changeBottomNavVisiblity(ChangeVisiablityIcon event,emit){
    emit(ChangeIndexLoading());
    enableBottomNav = !enableBottomNav;
    emit(ChangeIndexSuccess());
  }

  FutureOr<void> checkedInMethod(CheckInStatusChangedEvent event, Emitter<HomeState> emit) {
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

  @override
  Future<void> close() {
    _prayerTicker?.cancel();
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
      // 1) Try last known position for instant UI
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        _setPrayerTimesFor(Coordinates(last.latitude, last.longitude));
        if (_prayerTimes != null) {
          emit(PrayerTimesLoaded(
            prayerTimes: _prayerTimes,
            nextPrayer: _nextPrayer,
            nextTime: _nextPrayerTime,
            isSoundMuted: _isSoundMuted,
          ));
        }
      }

      // 2) Ensure services + permissions
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are disabled.');
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('Location permission denied.');
      }

      // 3) Fresh position with a timeout
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      _setPrayerTimesFor(Coordinates(pos.latitude, pos.longitude));
      emit(PrayerTimesLoaded(
        prayerTimes: _prayerTimes,
        nextPrayer: _nextPrayer,
        nextTime: _nextPrayerTime,
        isSoundMuted: _isSoundMuted,
      ));

      _startPrayerTicker();
    } catch (e) {
      // Fallback to Cairo if no prayer times set
      if (_prayerTimes == null) {
        _setPrayerTimesFor(Coordinates(30.0444, 31.2357));
      }
      
      emit(PrayerTimesError(
        error: e.toString(),
        prayerTimes: _prayerTimes,
        isSoundMuted: _isSoundMuted,
      ));
      
      _startPrayerTicker();
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
      final firstDayOfLastMonth = DateTime(now.year, now.month , 1);
      final lastDayOfLastMonth = DateTime(now.year, now.month+1, 0);

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
