import 'dart:async';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/data/services/checkin_reminder_notification_service.dart';
import 'package:el_race/ui/presentation/Attendace_list/repository/attendance_repository.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/timer_controller.dart';
import 'package:el_race/utils/di.dart';
import 'package:get/get.dart';

class AttendanceStatusSnapshot {
  final bool checkedIn;
  final bool checkedOut;
  final bool isToday;
  final String checkInDisplayTime;
  final String checkOutDisplayTime;
  final int? checkInRecordId;
  final DateTime refreshedAt;

  const AttendanceStatusSnapshot({
    required this.checkedIn,
    required this.checkedOut,
    required this.isToday,
    required this.checkInDisplayTime,
    required this.checkOutDisplayTime,
    this.checkInRecordId,
    required this.refreshedAt,
  });
}

class AttendanceStatusSyncService {
  static final StreamController<AttendanceStatusSnapshot> _updatesController =
      StreamController<AttendanceStatusSnapshot>.broadcast();

  static Stream<AttendanceStatusSnapshot> get updates =>
      _updatesController.stream;

  /// Timestamp of the last local check-in action (epoch ms).
  /// Persisted in SharedPref as 'checkInTime' by CheckInBloc.
  /// Used to detect stale server data.
  static int get _localCheckInMs =>
      SharedPref().getPreferenceInt('checkInTime');

  /// Timestamp of the last local check-out action (epoch ms).
  /// Set by CheckOutBloc after a successful check-out.
  static int get _localCheckOutMs =>
      SharedPref().getPreferenceInt('lastLocalCheckOutTime');

  /// Call after a local check-in to record the action timestamp.
  static void markLocalAction({Duration guard = const Duration(minutes: 2)}) {
    // checkInTime is already saved by CheckInBloc.
    // This method is kept for backward compatibility.
    print('🛡️ AttendanceSync: Local check-in marked at ${DateTime.now()}');
  }

  /// Call after a local check-out to record the action timestamp.
  static void markLocalCheckOut() {
    SharedPref().setPreferenceInt(
        'lastLocalCheckOutTime', DateTime.now().millisecondsSinceEpoch);
    print('🛡️ AttendanceSync: Local check-out marked at ${DateTime.now()}');
  }

  /// Clears local action timestamps (e.g., on logout).
  static void clearGuard() {
    SharedPref().setPreferenceInt('lastLocalCheckOutTime', 0);
  }

  static Future<AttendanceStatusSnapshot?> refreshFromServer({
    String reason = 'manual',
  }) async {
    if (!SharedPref.isUserAuthenticated()) {
      return null;
    }

    try {
      final status = await AttendanceRepo().getTodayStatus();
      final snapshot = _toSnapshot(status);

      // ── Smart comparison: detect & skip stale server responses ──
      final localCheckedIn = SharedPref().getPreferenceBoolean('isCheckedIn');
      final localCheckIn = _localCheckInMs;
      final localCheckOut = _localCheckOutMs;

      print('\n🔍 ===== AttendanceSync ($reason) =====');
      print('🔍 SERVER: checkedIn=${snapshot.checkedIn}, '
          'checkedOut=${snapshot.checkedOut}, '
          'checkIn=${snapshot.checkInDisplayTime}, '
          'checkOut=${snapshot.checkOutDisplayTime}');
      print('🔍 LOCAL: checkedIn=$localCheckedIn, '
          'checkInTime=${localCheckIn > 0 ? DateTime.fromMillisecondsSinceEpoch(localCheckIn) : "none"}, '
          'checkOutTime=${localCheckOut > 0 ? DateTime.fromMillisecondsSinceEpoch(localCheckOut) : "none"}');
      print('🔍 LOCAL display: checkIn=${SharedPref().getPreferenceString("checkInDisplayTime")}, '
          'checkOut=${SharedPref().getPreferenceString("checkOutDisplayTime")}');

      // CASE 1: We're locally checked-in but server says NOT checked-in
      // → Server is stale if our check-in was recent (< 16 hours)
      if (localCheckedIn && !snapshot.checkedIn && localCheckIn > 0) {
        final localCheckInDate =
            DateTime.fromMillisecondsSinceEpoch(localCheckIn);
        final timeSince = DateTime.now().difference(localCheckInDate);
        print('🔍 CASE 1 match: localCheckedIn=$localCheckedIn, serverCheckedIn=${snapshot.checkedIn}, timeSince=${timeSince.inMinutes}min');
        if (timeSince.inHours < 16) {
          print('🛡️ AttendanceSync: SKIP — server says NOT checked-in but '
              'local check-in was ${timeSince.inMinutes}min ago (< 16h). '
              'Server is stale.');
          return null;
        }
      }

      // CASE 2: We're locally checked-in, server says checked-out,
      // but the server's check-out time is OLDER than our local check-in
      // → Stale check-out from a previous session
      if (localCheckedIn && snapshot.checkedOut && localCheckIn > 0) {
        final serverCheckOutDt =
            _parseServerDateTime(status['check_out_time']?.toString());
        if (serverCheckOutDt != null) {
          final localCheckInDate =
              DateTime.fromMillisecondsSinceEpoch(localCheckIn);
          if (serverCheckOutDt.isBefore(localCheckInDate)) {
            print('🛡️ AttendanceSync: SKIP — server check-out '
                '($serverCheckOutDt) is BEFORE local check-in '
                '($localCheckInDate). Server is stale.');
            return null;
          }
        }
      }

      // CASE 5: Both local and server agree on checked-in (not checked-out),
      // but the server's check-in time is OLDER than our local check-in time.
      // → Server is returning data from an older check-in record (first record
      //   of the day instead of the latest). Protect local display times.
      if (localCheckedIn && snapshot.checkedIn && !snapshot.checkedOut && localCheckIn > 0) {
        final serverCheckInDt =
            _parseServerDateTime(status['check_in_time']?.toString());
        if (serverCheckInDt != null) {
          final localCheckInDate =
              DateTime.fromMillisecondsSinceEpoch(localCheckIn);
          // Allow 2-min tolerance for clock drift between device and server
          if (serverCheckInDt.isBefore(
              localCheckInDate.subtract(const Duration(minutes: 2)))) {
            print('🛡️ AttendanceSync: SKIP — both checked-in but server '
                'check-in ($serverCheckInDt) is older than local check-in '
                '($localCheckInDate). Server returning stale record.');
            return null;
          }
        }
      }

      // CASE 3: We locally checked-out, but server still says checked-in
      // (no check-out). Our check-out was recent (< 4 hours).
      // → Server hasn't reflected the check-out yet.
      // ملاحظة: إذا كان checkInTime=0 يعني الحالة انمسحت بسبب counter reset
      // وليس بسبب تشيك اوت حقيقي، فلازم نقبل بيانات السيرفر
      if (!localCheckedIn && snapshot.checkedIn && !snapshot.checkedOut && localCheckOut > 0 && localCheckIn > 0) {
        final localCheckOutDate =
            DateTime.fromMillisecondsSinceEpoch(localCheckOut);
        final timeSince = DateTime.now().difference(localCheckOutDate);
        if (timeSince.inHours < 4) {
          print('🛡️ AttendanceSync: SKIP — server still says checked-in but '
              'local check-out was ${timeSince.inMinutes}min ago (< 4h). '
              'Server is stale.');
          return null;
        }
      }

      // CASE 4: Both local and server say "not checked in" (both checked-out).
      // Our local check-out was recent (< 4h), but the server's checkout time
      // is BEFORE our local checkout → server is returning stale data from an
      // older check-in/out cycle (e.g., morning 08:10→12:51 when we just did
      // 16:24→16:43). Protect local display times from being overwritten.
      if (!localCheckedIn && !snapshot.checkedIn && localCheckOut > 0) {
        final localCheckOutDate =
            DateTime.fromMillisecondsSinceEpoch(localCheckOut);
        final timeSince = DateTime.now().difference(localCheckOutDate);
        print('🔍 CASE 4 eval: both not checked-in, localCheckOut=${localCheckOutDate}, timeSince=${timeSince.inMinutes}min');
        if (timeSince.inHours < 4) {
          // Compare server checkout wall-clock time with our local checkout
          final serverCheckOutDt =
              _parseTodayTime(snapshot.checkOutDisplayTime);
          if (serverCheckOutDt == null ||
              serverCheckOutDt.isBefore(localCheckOutDate)) {
            print('🛡️ AttendanceSync: SKIP — local check-out was '
                '${timeSince.inMinutes}min ago. Server checkout '
                '(${snapshot.checkOutDisplayTime}) is older than local '
                '($localCheckOutDate). Server data is from older shift.');
            return null;
          }
        }
      }

      // Server data looks valid → apply it
      print('✅ AttendanceSync: Accepting server data ($reason)');
      print('🔍 ===== END AttendanceSync =====\n');
      await _persistSnapshot(snapshot);
      _updatesController.add(snapshot);
      _refreshHomeAttendanceSummary();

      return snapshot;
    } catch (_) {
      return null;
    }
  }

  static AttendanceStatusSnapshot _toSnapshot(Map<String, dynamic> data) {
    final checkedInRaw = _asBool(data['checked_in']);
    final checkedOutRaw = _asBool(data['checked_out']);
    final isToday = _asBool(data['is_today']);

    final checkInTime = _parseServerDateTime(data['check_in_time']?.toString());
    final checkOutTime =
        _parseServerDateTime(data['check_out_time']?.toString());

    final shouldBeCheckedIn = isToday && checkedInRaw && !checkedOutRaw;

    // Extract check_in_record_id if available from the server
    final rawRecordId = data['check_in_record_id'];
    final checkInRecordId = (rawRecordId is int && rawRecordId > 0)
        ? rawRecordId
        : (rawRecordId is String ? int.tryParse(rawRecordId) : null);

    return AttendanceStatusSnapshot(
      checkedIn: shouldBeCheckedIn,
      checkedOut: isToday && checkedOutRaw,
      isToday: isToday,
      checkInDisplayTime: (isToday && checkInTime != null)
          ? _formatTime(checkInTime)
          : '00:00:00',
      checkOutDisplayTime: (isToday && checkOutTime != null)
          ? _formatTime(checkOutTime)
          : '00:00:00',
      checkInRecordId: checkInRecordId,
      refreshedAt: DateTime.now(),
    );
  }

  static Future<void> _persistSnapshot(
      AttendanceStatusSnapshot snapshot) async {
    // Read current local state BEFORE overwriting
    final wasCheckedIn = SharedPref().getPreferenceBoolean('isCheckedIn');
    final existingCheckInTime = SharedPref().getPreferenceInt('checkInTime');
    final oldCheckInDisplay = SharedPref().getPreferenceString('checkInDisplayTime');
    final oldCheckOutDisplay = SharedPref().getPreferenceString('checkOutDisplayTime');

    print('\n📝 _persistSnapshot: BEFORE');
    print('📝   isCheckedIn = $wasCheckedIn');
    print('📝   checkInDisplayTime = $oldCheckInDisplay');
    print('📝   checkOutDisplayTime = $oldCheckOutDisplay');
    print('📝   checkInTime (ms) = $existingCheckInTime');
    print('📝 _persistSnapshot: WRITING from server:');
    print('📝   isCheckedIn = ${snapshot.checkedIn}');
    print('📝   checkInDisplayTime = ${snapshot.checkInDisplayTime}');
    print('📝   checkOutDisplayTime = ${snapshot.checkOutDisplayTime}');

    await SharedPref().setPreferencesBoolean('isCheckedIn', snapshot.checkedIn);

    // حماية أوقات العرض: إذا كان المستخدم checked-in محلياً وعلى السيرفر،
    // لا نكتب فوق الأوقات المحلية إذا كانت أوقات السيرفر أقدم (سجل قديم).
    bool shouldUpdateDisplayTimes = true;
    if (wasCheckedIn && snapshot.checkedIn && existingCheckInTime > 0 &&
        snapshot.checkInDisplayTime != '00:00:00' &&
        oldCheckInDisplay.isNotEmpty && oldCheckInDisplay != '00:00:00') {
      final localCheckInDate =
          DateTime.fromMillisecondsSinceEpoch(existingCheckInTime);
      final serverCheckInWallClock =
          _parseTodayTime(snapshot.checkInDisplayTime);
      if (serverCheckInWallClock != null &&
          serverCheckInWallClock.isBefore(
              localCheckInDate.subtract(const Duration(minutes: 2)))) {
        shouldUpdateDisplayTimes = false;
        print('🛡️ _persistSnapshot: Server checkInDisplayTime '
            '(${snapshot.checkInDisplayTime}) is older than local check-in '
            '($localCheckInDate). Keeping local display times.');
      }
    }

    if (shouldUpdateDisplayTimes) {
      await SharedPref().setPreferencesString(
          'checkInDisplayTime', snapshot.checkInDisplayTime);
      await SharedPref().setPreferencesString(
          'checkOutDisplayTime', snapshot.checkOutDisplayTime);
    }

    // CRITICAL: Only update checkInTime if we are transitioning from
    // NOT checked-in to checked-in (i.e., an external check-in we need to
    // pick up). If the user was ALREADY checked-in locally, preserve the
    // local checkInTime — it's more accurate (set at the exact moment the
    // check-in API returned success, with no timezone/parsing issues).
    if (snapshot.checkedIn && snapshot.checkInDisplayTime != '00:00:00') {
      if (!wasCheckedIn || existingCheckInTime == 0) {
        // Transitioning to checked-in OR recovering from missing timestamp
        final checkInDateTime = _parseTodayTime(snapshot.checkInDisplayTime);
        if (checkInDateTime != null) {
          await SharedPref().setPreferenceInt(
              'checkInTime', checkInDateTime.millisecondsSinceEpoch);
          print('🕐 _persistSnapshot: Set checkInTime from server (new check-in or recovery)');
        }
      } else {
        print('🕐 _persistSnapshot: Keeping existing checkInTime=$existingCheckInTime (already checked-in locally)');
      }
    } else if (!snapshot.checkedIn) {
      // Only clear checkInTime if we are transitioning to NOT checked-in
      // and the local state also agrees (prevents stale server data from
      // clearing a valid local check-in time).
      if (!wasCheckedIn || existingCheckInTime == 0) {
        await SharedPref().setPreferenceInt('checkInTime', 0);
      } else {
        // This shouldn't happen (guard should have caught it), but be safe
        print('⚠️ _persistSnapshot: Server says NOT checked-in but local checkInTime exists. NOT clearing.');
      }
    }

    if (!snapshot.checkedIn) {
      await SharedPref().setPreferenceInt('checkInRecordId', 0);
    }

    // Save check_in_record_id from server if available and we're checked-in
    if (snapshot.checkedIn && snapshot.checkInRecordId != null && snapshot.checkInRecordId! > 0) {
      final existingRecordId = SharedPref().getPreferenceInt('checkInRecordId');
      if (existingRecordId == 0) {
        await SharedPref().setPreferenceInt('checkInRecordId', snapshot.checkInRecordId!);
        print('🆔 _persistSnapshot: Set checkInRecordId from server = ${snapshot.checkInRecordId}');
      }
    }

    // Final state dump
    print('📝 _persistSnapshot: AFTER');
    print('📝   isCheckedIn = ${SharedPref().getPreferenceBoolean('isCheckedIn')}');
    print('📝   checkInDisplayTime = ${SharedPref().getPreferenceString('checkInDisplayTime')}');
    print('📝   checkOutDisplayTime = ${SharedPref().getPreferenceString('checkOutDisplayTime')}');
    print('📝   checkInTime (ms) = ${SharedPref().getPreferenceInt('checkInTime')}');
    print('📝   checkInRecordId = ${SharedPref().getPreferenceInt('checkInRecordId')}');
    print('📝   lastLocalCheckOutTime = ${SharedPref().getPreferenceInt('lastLocalCheckOutTime')}');
    print('📝 ===== END _persistSnapshot =====\n');

    // Reload the timer controller so it reflects the server's check-in time.
    // This handles the case where the user checked in/out from outside the app.
    try {
      final timerController = Get.find<TimerController>();
      await timerController.reloadState();
    } catch (_) {
      // TimerController is not yet registered (e.g., app startup before HomeScreen).
      // It will read the correct SharedPref values when it initializes.
    }

    try {
      await CheckInReminderNotificationService().updateReminders();
    } catch (_) {}
  }

  static void _refreshHomeAttendanceSummary() {
    try {
      if (!sl.isRegistered<HomeBloc>()) return;
      final homeBloc = sl<HomeBloc>();
      if (homeBloc.isClosed) return;
      homeBloc.add(const FetchLastMonthAttendanceSummary());
    } catch (_) {}
  }

  static bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value == null) {
      return false;
    }

    final normalized = value.toString().trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'y';
  }

  static DateTime? _parseServerDateTime(String? raw) {
    if (raw == null) {
      return null;
    }

    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'false') {
      return null;
    }

    final normalized =
        trimmed.contains('T') ? trimmed : trimmed.replaceFirst(' ', 'T');

    return DateTime.tryParse(normalized);
  }

  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}'
        ':${dateTime.minute.toString().padLeft(2, '0')}'
        ':${dateTime.second.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseTodayTime(String displayTime) {
    final parts = displayTime.split(':');
    if (parts.length != 3) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final second = int.tryParse(parts[2]);

    if (hour == null || minute == null || second == null) {
      return null;
    }

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute, second);
  }
}
