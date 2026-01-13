import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/landing_screen/repository/check_in_repo.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import '../../repository/location_reop.dart';
import 'package:el_race/core/biometric/face_recognition/data/services/face_embedding_storage_service.dart';
part 'check_in_event.dart';
part 'check_in_state.dart';

LocationRepo _locationRepo = LocationRepo();
CheckInREpo _checkInRepo = CheckInREpo();

class CheckInBloc extends Bloc<CheckInEvent, CheckInState> {
  final FaceEmbeddingStorageService _storageService =
      FaceEmbeddingStorageService();

  CheckInBloc() : super(CheckInInitial()) {
    on<CheckInET>(checkInMethod);
    on<VerifyFaceForCheckInET>(verifyFaceForCheckIn);
  }

  /// Verify face before allowing check-in
  /// This checks if embeddings exist and triggers Face Verification screen through widget
  Future<void> verifyFaceForCheckIn(
      VerifyFaceForCheckInET event, Emitter<CheckInState> emit) async {
    try {
      emit(const CheckInLoadingST(isLoading: true));

      // Get user ID
      final loginData = SharedPref.getLoginData();
      final userId = loginData.result?.data?.emp_id ??
          loginData.result?.data?.uid?.toString() ??
          'unknown';

      print('\n🔐 ===== FACE VERIFICATION CHECK FOR CHECK-IN =====');
      print('👤 User ID: $userId');

      // Check if user has enrolled face
      final hasEmbeddings = await _storageService.hasEmbeddings(userId);

      if (!hasEmbeddings) {
        print('❌ No face embeddings found - user needs enrollment');
        emit(const FaceNotEnrolledST());
        return;
      }

      print(
          '✅ Face embeddings found - user can proceed to verification screen');
      emit(const FaceVerificationSuccessST());
    } catch (e) {
      print('❌ Error checking face embeddings: $e');
      emit(FaceVerificationFailedST('خطأ في التحقق من الوجه: $e'));
    } finally {
      emit(const CheckInLoadingST(isLoading: false));
    }
  }

  Future<void> checkInMethod(
      CheckInET event, Emitter<CheckInState> emit) async {
    try {
      // Emit loading state
      emit(const CheckInLoadingST(isLoading: true));

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
          print('checkInRecordIdBloc: $checkInRecordId');
          SharedPref().setPreferenceInt('checkInRecordId', checkInRecordId);

          // Save check-in time in UAE timezone (GMT+4) for display
          final uaeTime = DateTime.now().toUtc().add(const Duration(hours: 4));
          final displayTime =
              '${uaeTime.hour.toString().padLeft(2, '0')}:${uaeTime.minute.toString().padLeft(2, '0')}';
          SharedPref().setPreferencesString('checkInDisplayTime', displayTime);

          // Save check-in timestamp for 16-hour reset logic
          SharedPref().setPreferenceInt(
              'checkInTime', DateTime.now().millisecondsSinceEpoch);

          // Reset check-out time
          SharedPref().setPreferencesString('checkOutDisplayTime', '00:00:00');

          emit(CheckedInST(responseData['message'], checkInRecordId));
        } else if (responseData['status'] == 'warning') {
          final checkInRecordId = responseData['check_in_record_id'];
          SharedPref().setPreferenceInt('checkInRecordId', checkInRecordId);

          // Save check-in time in UAE timezone (GMT+4) for display
          final uaeTime = DateTime.now().toUtc().add(const Duration(hours: 4));
          final displayTime =
              '${uaeTime.hour.toString().padLeft(2, '0')}:${uaeTime.minute.toString().padLeft(2, '0')}';
          SharedPref().setPreferencesString('checkInDisplayTime', displayTime);

          // Save check-in timestamp for 16-hour reset logic
          SharedPref().setPreferenceInt(
              'checkInTime', DateTime.now().millisecondsSinceEpoch);

          // Reset check-out time
          SharedPref().setPreferencesString('checkOutDisplayTime', '00:00:00');

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
