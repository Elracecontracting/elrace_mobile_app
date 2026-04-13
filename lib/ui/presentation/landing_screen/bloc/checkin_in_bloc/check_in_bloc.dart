import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/core/services/attendance_status_sync_service.dart';
import 'package:el_race/ui/presentation/landing_screen/repository/check_in_repo.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import '../../repository/location_reop.dart';
part 'check_in_event.dart';
part 'check_in_state.dart';

LocationRepo _locationRepo = LocationRepo();
CheckInREpo _checkInRepo = CheckInREpo();

class CheckInBloc extends Bloc<CheckInEvent, CheckInState> {
  CheckInBloc() : super(CheckInInitial()) {
    on<CheckInET>(checkInMethod);
  }

  /// Get Dubai time
  DateTime _getDubaiTime() {
    return DateTime.now().toUtc().add(const Duration(hours: 4));
  }

  /// Get check-in cutoff time for today (11:59 AM Dubai time)
  DateTime _getCutoffTime() {
    final dubaiTime = _getDubaiTime();
    return DateTime(dubaiTime.year, dubaiTime.month, dubaiTime.day, 11, 59);
  }

  Future<void> checkInMethod(
      CheckInET event, Emitter<CheckInState> emit) async {
    try {
      // Emit loading state
      emit(const CheckInLoadingST(isLoading: true));

      // Check if check-in is allowed based on time restriction
      // Check-in is only allowed before 11:59 AM Dubai time
      // ⚠️ تم تعطيل شرط الوقت مؤقتاً
      // final dubaiTime = _getDubaiTime();
      // final cutoffTime = _getCutoffTime();
      //
      // // After 11:59 AM (hour >= 12) and before 5:00 AM next day, check-in is blocked
      // if (dubaiTime.hour >= 12 || dubaiTime.hour < 5) {
      //   emit(CheckInBlockedST(
      //     message:
      //         'Check-in is not allowed after 11:59 AM. Please try again tomorrow after 5:00 AM.',
      //     currentDubaiTime: dubaiTime,
      //     cutoffTime: cutoffTime,
      //   ));
      //   return;
      // }

      // Simulate API call or perform your actual API logic here
      Position location = await _locationRepo.getCurrentLocation();

      Response? response = await _checkInRepo.checkInUser(
        location.latitude.toString(),
        location.longitude.toString(),
      );

      // Handle response and emit corresponding states
      if (response != null && response.data != null) {
        final responseData = response.data['result'];
        print('---- ${responseData.toString()}');
        if (responseData['status'] == 'success') {
          final checkInRecordId = responseData['check_in_record_id'];
          await SharedPref()
              .setPreferenceInt('checkInRecordId', checkInRecordId);

          // Save check-in time in UAE timezone (GMT+4) for display
          final uaeTime = DateTime.now().toUtc().add(const Duration(hours: 4));
          final displayTime =
              '${uaeTime.hour.toString().padLeft(2, '0')}:${uaeTime.minute.toString().padLeft(2, '0')}:${uaeTime.second.toString().padLeft(2, '0')}';

          print('\n🟢 ===== CHECK-IN BLOC =====');
          print('🟢 checkInDisplayTime = $displayTime');
          print('🟢 checkInRecordId = $checkInRecordId');
          print('🟢 isCheckedIn = true');

          await SharedPref()
              .setPreferencesString('checkInDisplayTime', displayTime);

          // Save check-in timestamp for 16-hour reset logic
          final checkInMs = DateTime.now().millisecondsSinceEpoch;
          await SharedPref().setPreferenceInt('checkInTime', checkInMs);

          // Reset check-out time
          await SharedPref()
              .setPreferencesString('checkOutDisplayTime', '00:00:00');

          // Log final SharedPref state
          print('🟢 --- SharedPref state after check-in ---');
          print('🟢 isCheckedIn = ${SharedPref().getPreferenceBoolean('isCheckedIn')}');
          print('🟢 checkInDisplayTime = ${SharedPref().getPreferenceString('checkInDisplayTime')}');
          print('🟢 checkOutDisplayTime = ${SharedPref().getPreferenceString('checkOutDisplayTime')}');
          print('🟢 checkInTime (ms) = $checkInMs');
          print('🟢 lastLocalCheckOutTime = ${SharedPref().getPreferenceInt('lastLocalCheckOutTime')}');
          print('🟢 ===== END CHECK-IN BLOC =====\n');

          // Guard local state from being overwritten by stale server sync
          AttendanceStatusSyncService.markLocalAction();

          emit(CheckedInST(responseData['message'], checkInRecordId));
        } else if (responseData['status'] == 'warning') {
          final checkInRecordId = responseData['check_in_record_id'];
          await SharedPref()
              .setPreferenceInt('checkInRecordId', checkInRecordId);

          // Save check-in time in UAE timezone (GMT+4) for display
          final uaeTime = DateTime.now().toUtc().add(const Duration(hours: 4));
          final displayTime =
              '${uaeTime.hour.toString().padLeft(2, '0')}:${uaeTime.minute.toString().padLeft(2, '0')}:${uaeTime.second.toString().padLeft(2, '0')}';
          await SharedPref()
              .setPreferencesString('checkInDisplayTime', displayTime);
          print('🟢 Check-in time saved (warning): $displayTime');

          // Save check-in timestamp for 16-hour reset logic
          final checkInMs2 = DateTime.now().millisecondsSinceEpoch;
          await SharedPref().setPreferenceInt('checkInTime', checkInMs2);

          // Reset check-out time
          await SharedPref()
              .setPreferencesString('checkOutDisplayTime', '00:00:00');

          // Log final SharedPref state
          print('🟢 --- SharedPref state after check-in (warning) ---');
          print('🟢 isCheckedIn = ${SharedPref().getPreferenceBoolean('isCheckedIn')}');
          print('🟢 checkInDisplayTime = ${SharedPref().getPreferenceString('checkInDisplayTime')}');
          print('🟢 checkOutDisplayTime = ${SharedPref().getPreferenceString('checkOutDisplayTime')}');
          print('🟢 checkInTime (ms) = $checkInMs2');
          print('🟢 lastLocalCheckOutTime = ${SharedPref().getPreferenceInt('lastLocalCheckOutTime')}');

          // Guard local state from being overwritten by stale server sync
          AttendanceStatusSyncService.markLocalAction();

          emit(CheckInWarningST(responseData['message'], checkInRecordId));
        } else {
          emit(CheckInErrorST(responseData['message'] ?? 'Check-in failed.'));
        }
      } else {
        emit(const CheckInErrorST('No response data from server.'));
      }
    } catch (e) {
      emit(CheckInErrorST('Error during check-in: $e'));
    } finally {
      // Emit loading complete
      emit(const CheckInLoadingST(isLoading: false));
    }
  }
}
