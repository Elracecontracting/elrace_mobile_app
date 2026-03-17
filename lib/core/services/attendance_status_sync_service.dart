import 'dart:async';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/data/services/checkin_reminder_notification_service.dart';
import 'package:el_race/ui/presentation/Attendace_list/repository/attendance_repository.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart';
import 'package:el_race/utils/di.dart';

class AttendanceStatusSnapshot {
  final bool checkedIn;
  final bool checkedOut;
  final bool isToday;
  final String checkInDisplayTime;
  final String checkOutDisplayTime;
  final DateTime refreshedAt;

  const AttendanceStatusSnapshot({
    required this.checkedIn,
    required this.checkedOut,
    required this.isToday,
    required this.checkInDisplayTime,
    required this.checkOutDisplayTime,
    required this.refreshedAt,
  });
}

class AttendanceStatusSyncService {
  static final StreamController<AttendanceStatusSnapshot> _updatesController =
      StreamController<AttendanceStatusSnapshot>.broadcast();

  static Stream<AttendanceStatusSnapshot> get updates =>
      _updatesController.stream;

  static Future<AttendanceStatusSnapshot?> refreshFromServer({
    String reason = 'manual',
  }) async {
    if (!SharedPref.isUserAuthenticated()) {
      print(
          'ℹ️ Attendance sync skipped (reason=$reason): user is not authenticated');
      return null;
    }

    try {
      final status = await AttendanceRepo().getTodayStatus();
      final snapshot = _toSnapshot(status);

      await _persistSnapshot(snapshot);
      _updatesController.add(snapshot);
      _refreshHomeAttendanceSummary();

      print(
        '✅ Attendance today_status synced (reason=$reason): '
        'checkedIn=${snapshot.checkedIn}, checkedOut=${snapshot.checkedOut}, '
        'checkIn=${snapshot.checkInDisplayTime}, '
        'checkOut=${snapshot.checkOutDisplayTime}',
      );

      return snapshot;
    } catch (e) {
      print('❌ Attendance sync failed (reason=$reason): $e');
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
      refreshedAt: DateTime.now(),
    );
  }

  static Future<void> _persistSnapshot(
      AttendanceStatusSnapshot snapshot) async {
    await SharedPref().setPreferencesBoolean('isCheckedIn', snapshot.checkedIn);
    await SharedPref().setPreferencesString(
        'checkInDisplayTime', snapshot.checkInDisplayTime);
    await SharedPref().setPreferencesString(
        'checkOutDisplayTime', snapshot.checkOutDisplayTime);

    if (snapshot.checkedIn && snapshot.checkInDisplayTime != '00:00:00') {
      final checkInDateTime = _parseTodayTime(snapshot.checkInDisplayTime);
      if (checkInDateTime != null) {
        await SharedPref().setPreferenceInt(
            'checkInTime', checkInDateTime.millisecondsSinceEpoch);
      }
    } else {
      await SharedPref().setPreferenceInt('checkInTime', 0);
    }

    if (!snapshot.checkedIn) {
      await SharedPref().setPreferenceInt('checkInRecordId', 0);
    }

    try {
      await CheckInReminderNotificationService().updateReminders();
    } catch (e) {
      print('⚠️ Failed to update attendance reminders after sync: $e');
    }
  }

  static void _refreshHomeAttendanceSummary() {
    try {
      if (!sl.isRegistered<HomeBloc>()) {
        return;
      }

      final homeBloc = sl<HomeBloc>();
      if (homeBloc.isClosed) {
        return;
      }

      homeBloc.add(const FetchLastMonthAttendanceSummary());
    } catch (e) {
      print('⚠️ Failed to trigger HomeBloc attendance refresh: $e');
    }
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
