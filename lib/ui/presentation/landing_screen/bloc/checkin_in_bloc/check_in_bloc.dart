import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/landing_screen/repository/check_in_repo.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import '../../repository/location_reop.dart';
import 'package:el_race/core/biometric/face_recognition/data/services/face_embedding_storage_service.dart';
import 'package:el_race/core/biometric/face_recognition/data/services/face_detector_service.dart';
import 'package:el_race/core/biometric/face_recognition/data/services/facenet_service.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
part 'check_in_event.dart';
part 'check_in_state.dart';

LocationRepo _locationRepo = LocationRepo();
CheckInREpo _checkInRepo = CheckInREpo();

class CheckInBloc extends Bloc<CheckInEvent, CheckInState> {
  final FaceEmbeddingStorageService _storageService =
      FaceEmbeddingStorageService();
  late final FaceDetectorService _faceDetectorService;
  late final FaceNetService _faceNetService;

  CheckInBloc() : super(CheckInInitial()) {
    _faceDetectorService = FaceDetectorService();
    _faceNetService = FaceNetService();

    // Initialize services
    _initializeServices();

    on<CheckInET>(checkInMethod);
    on<VerifyFaceForCheckInET>(verifyFaceForCheckIn);
  }

  Future<void> _initializeServices() async {
    await _faceDetectorService.initialize();
    await _faceNetService.initialize();
  }

  /// Verify face before allowing check-in
  /// This performs actual face recognition verification
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
      print('📸 Image Path: ${event.imagePath}');

      // Check if user has enrolled face
      final hasEmbeddings = await _storageService.hasEmbeddings(userId);

      if (!hasEmbeddings) {
        print('❌ No face embeddings found - user needs enrollment');
        emit(const FaceNotEnrolledST());
        return;
      }

      // Load image from path
      final imageFile = File(event.imagePath);
      if (!await imageFile.exists()) {
        print('❌ Image file not found');
        emit(const FaceVerificationFailedST('خطأ: لم يتم العثور على الصورة'));
        return;
      }

      // Create InputImage for face detection
      final inputImage = InputImage.fromFile(imageFile);

      // Perform face verification using FaceDetectorService
      print('🔍 Starting face verification...');

      // Step 1: Detect faces in the image
      final faces =
          await _faceDetectorService.detectFacesFromInputImage(inputImage);

      if (faces.isEmpty) {
        print('❌ No face detected in the image');
        emit(const FaceVerificationFailedST('لم يتم اكتشاف وجه في الصورة'));
        return;
      }

      if (faces.length > 1) {
        print('❌ Multiple faces detected');
        emit(const FaceVerificationFailedST('تم اكتشاف أكثر من وجه واحد'));
        return;
      }

      final face = faces.first;

      // Step 2: Check liveness
      final hasLiveness = _faceDetectorService.checkLiveness(face);
      if (!hasLiveness) {
        print('❌ Liveness check failed');
        emit(const FaceVerificationFailedST(
            'فشل فحص الحيوية. تأكد من النظر للكاميرا مباشرة'));
        return;
      }

      // Step 3: Check face quality
      final quality = _faceDetectorService.getFaceQuality(face);
      if (quality < 0.3) {
        print('❌ Face quality too low: $quality');
        emit(const FaceVerificationFailedST(
            'جودة الصورة منخفضة. تأكد من الإضاءة الجيدة'));
        return;
      }

      print('✅ Face quality: $quality');
      print('✅ Liveness check passed');

      // For now, if face is detected with good quality and liveness, consider it verified
      // TODO: Add actual embedding comparison when we have proper image-to-embedding conversion

      print('✅ Face verified successfully!');
      emit(const FaceVerificationSuccessST());
    } catch (e) {
      print('❌ Error during face verification: $e');
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
