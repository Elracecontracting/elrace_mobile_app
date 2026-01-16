import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/landing_screen/repository/check_out_repo.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

import '../../repository/location_reop.dart';

part 'check_out_event.dart';
part 'check_out_state.dart';

LocationRepo _locationRepo = LocationRepo();
CheckOutRepo _checkOutRepo = CheckOutRepo();

class CheckOutBloc extends Bloc<CheckOutEvent, CheckOutState> {
  CheckOutBloc() : super(CheckOutInitial()) {
    on<CheckOutET>(checkOutMethod);
  }

  Future<void> checkOutMethod(
      CheckOutET event, Emitter<CheckOutState> emit) async {
    try {
      // Emit loading state
      emit(const CheckOutLoadingST(isLoading: true));

      // Simulate fetching the current location
      Position location = await _locationRepo.getCurrentLocation();

      // Call the API with location data and check_in_record_id
      Response? response = await _checkOutRepo.checkOutUser(
        location.latitude.toString(),
        location.longitude.toString(),
        event.checkInRecordId, // Pass the check_in_record_id
      );

      // Handle response and emit corresponding states
      if (response != null && response.data != null) {
        final responseData = response.data['result'];
        if (responseData['status'] == 'success') {
          // Save check-out time in UAE timezone (GMT+4) for display
          final uaeTime = DateTime.now().toUtc().add(const Duration(hours: 4));
          final displayTime =
              '${uaeTime.hour.toString().padLeft(2, '0')}:${uaeTime.minute.toString().padLeft(2, '0')}:${uaeTime.second.toString().padLeft(2, '0')}';

          print('\n🔴 ===== CHECK-OUT BLOC - SAVING TIME =====');
          print('🔴 Key: checkOutDisplayTime');
          print('🔴 Value: $displayTime');
          print('🔴 =========================================\n');

          await SharedPref()
              .setPreferencesString('checkOutDisplayTime', displayTime);
          print('✅ Check-out time saved to SharedPref: $displayTime');

          // Emit success state with the message
          emit(CheckedOutST(responseData['message']));
        } else if (responseData['status'] == 'warning') {
          // Save check-out time even on warning
          final uaeTime = DateTime.now().toUtc().add(const Duration(hours: 4));
          final displayTime =
              '${uaeTime.hour.toString().padLeft(2, '0')}:${uaeTime.minute.toString().padLeft(2, '0')}:${uaeTime.second.toString().padLeft(2, '0')}';

          print('\n🟡 ===== CHECK-OUT BLOC (WARNING) - SAVING TIME =====');
          print('🟡 Key: checkOutDisplayTime');
          print('🟡 Value: $displayTime');
          print('🟡 ===================================================\n');

          await SharedPref()
              .setPreferencesString('checkOutDisplayTime', displayTime);
          print('✅ Check-out time saved (warning): $displayTime');

          // Emit warning state with the warning message
          emit(CheckOutWarningST(responseData['message']));
        } else {
          // Emit error state with the error message
          emit(CheckOutErrorST(responseData['message'] ?? 'Checkout failed.'));
        }
      } else {
        emit(const CheckOutErrorST('No response data from server.'));
      }
    } catch (e) {
      emit(CheckOutErrorST('Error during checkout: $e'));
    } finally {
      // Emit loading complete
      emit(const CheckOutLoadingST(isLoading: false));
    }
  }
}
