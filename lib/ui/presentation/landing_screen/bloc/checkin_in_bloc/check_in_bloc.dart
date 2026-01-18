import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
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
  /// This performs actual face recognition verification with embedding comparison
  /// Now includes anti-spoofing check using multiple images
  Future<void> verifyFaceForCheckIn(
      VerifyFaceForCheckInET event, Emitter<CheckInState> emit) async {
    try {
      emit(const CheckInLoadingST(isLoading: true));

      // Get user ID
      final loginData = SharedPref.getLoginData();
      final userId = loginData.result?.data?.emp_id ??
          loginData.result?.data?.uid?.toString() ??
          'unknown';

      // Check if user has enrolled face
      final hasEmbeddings = await _storageService.hasEmbeddings(userId);

      if (!hasEmbeddings) {
        emit(const FaceNotEnrolledST());
        return;
      }

      // Load image from path
      final imageFile = File(event.imagePath);
      if (!await imageFile.exists()) {
        emit(const FaceVerificationFailedST('Error: Image file not found'));
        return;
      }

      // Create InputImage for face detection
      final inputImage = InputImage.fromFile(imageFile);

      // Perform face verification using FaceDetectorService

      // Step 1: Detect faces in the image
      final faces =
          await _faceDetectorService.detectFacesFromInputImage(inputImage);

      if (faces.isEmpty) {
        emit(const FaceVerificationFailedST('No face detected in the image'));
        return;
      }

      if (faces.length > 1) {
        emit(const FaceVerificationFailedST('Multiple faces detected'));
        return;
      }

      final face = faces.first;

      // Step 2: Anti-Spoofing check using multiple images
      if (event.additionalImagePaths != null &&
          event.additionalImagePaths!.length >= 3) {
        final List<Face> faceSequence = [];
        for (final path in event.additionalImagePaths!) {
          final file = File(path);
          if (await file.exists()) {
            final input = InputImage.fromFile(file);
            final detectedFaces =
                await _faceDetectorService.detectFacesFromInputImage(input);
            if (detectedFaces.isNotEmpty) {
              faceSequence.add(detectedFaces.first);
            }
          }
        }

        if (faceSequence.length >= 3) {
          // Check for natural micro-movements (photos are 100% static)
          final yawValues =
              faceSequence.map((f) => f.headEulerAngleY ?? 0.0).toList();
          final pitchValues =
              faceSequence.map((f) => f.headEulerAngleX ?? 0.0).toList();

          final yawVariation = _calculateVariation(yawValues);
          final pitchVariation = _calculateVariation(pitchValues);

          // If face is perfectly static (< 0.3° movement), it's likely a photo
          if (yawVariation < 0.3 && pitchVariation < 0.3) {
            emit(const FaceVerificationFailedST(
                'Verification failed. Please try again'));
            return;
          }
        }
      }

      // Step 3: Check liveness with relaxed thresholds
      // This ensures it's a real person but not too strict
      final hasLiveness = _faceDetectorService.checkLiveness(
        face,
        eyeOpenThreshold: 0.15, // Relaxed: eyes can be partially open
        maxHeadEulerAngleY: 25.0, // Allow some head rotation
        maxHeadEulerAngleZ: 25.0,
      );

      if (!hasLiveness) {
        emit(const FaceVerificationFailedST(
            'Please look directly at the camera with eyes open'));
        return;
      }

      // Step 4: Check face quality
      final quality = _faceDetectorService.getFaceQuality(face);
      if (quality < 0.3) {
        emit(const FaceVerificationFailedST(
            'Image quality is low. Please ensure good lighting'));
        return;
      }

      // Step 4: Extract embedding from captured image and compare with stored
      try {
        // Get stored embeddings
        final storedEmbeddings = await _storageService.getEmbeddings(userId);
        if (storedEmbeddings.isEmpty) {
          emit(const FaceNotEnrolledST());
          return;
        }

        // Extract embedding from current image using FaceNet
        final currentEmbedding = await _faceNetService.getEmbeddingFromFile(
          imageFile,
          face.boundingBox,
        );

        if (currentEmbedding == null) {
          emit(const FaceVerificationFailedST(
              'Could not process face. Please try again'));
          return;
        }

        // Compare embeddings
        double bestDistance = double.infinity;
        for (final stored in storedEmbeddings) {
          final distance = _faceNetService.euclideanDistance(
            currentEmbedding,
            stored.embedding,
          );
          if (distance < bestDistance) {
            bestDistance = distance;
          }
        }

        // Verification threshold:
        // < 0.5 = Very strict (may reject valid users)
        // 0.5-0.6 = Strict but fair (recommended)
        // 0.6-0.7 = Balanced
        // > 0.7 = Too lenient (security risk)
        const verificationThreshold =
            0.65; // Balanced: secure but not frustrating

        if (bestDistance > verificationThreshold) {
          emit(const FaceVerificationFailedST(
              'Face verification failed. Please try again'));
          return;
        }

        emit(const FaceVerificationSuccessST());
      } catch (embeddingError) {
        // DO NOT allow fallback - this is a security risk
        emit(const FaceVerificationFailedST(
            'Face verification error. Please try again'));
        return;
      }
    } catch (e) {
      emit(FaceVerificationFailedST('Verification error: $e'));
    } finally {
      emit(const CheckInLoadingST(isLoading: false));
    }
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
      final dubaiTime = _getDubaiTime();
      final cutoffTime = _getCutoffTime();

      // After 11:59 AM (hour >= 12) and before 5:00 AM next day, check-in is blocked
      if (dubaiTime.hour >= 12 || dubaiTime.hour < 5) {
        emit(CheckInBlockedST(
          message:
              'Check-in is not allowed after 11:59 AM. Please try again tomorrow after 5:00 AM.',
          currentDubaiTime: dubaiTime,
          cutoffTime: cutoffTime,
        ));
        return;
      }

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
          await SharedPref()
              .setPreferenceInt('checkInRecordId', checkInRecordId);

          // Save check-in time in UAE timezone (GMT+4) for display
          final uaeTime = DateTime.now().toUtc().add(const Duration(hours: 4));
          final displayTime =
              '${uaeTime.hour.toString().padLeft(2, '0')}:${uaeTime.minute.toString().padLeft(2, '0')}:${uaeTime.second.toString().padLeft(2, '0')}';

          print('\n🟢 ===== CHECK-IN BLOC - SAVING TIME =====');
          print('🟢 Key: checkInDisplayTime');
          print('🟢 Value: $displayTime');
          print('🟢 ========================================\n');

          await SharedPref()
              .setPreferencesString('checkInDisplayTime', displayTime);
          print('✅ Check-in time saved to SharedPref: $displayTime');

          // Save check-in timestamp for 16-hour reset logic
          await SharedPref().setPreferenceInt(
              'checkInTime', DateTime.now().millisecondsSinceEpoch);

          // Reset check-out time
          print('🟢 Resetting checkOutDisplayTime to 00:00:00');
          await SharedPref()
              .setPreferencesString('checkOutDisplayTime', '00:00:00');

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
          print('✅ Check-in time saved (warning): $displayTime');

          // Save check-in timestamp for 16-hour reset logic
          await SharedPref().setPreferenceInt(
              'checkInTime', DateTime.now().millisecondsSinceEpoch);

          // Reset check-out time
          await SharedPref()
              .setPreferencesString('checkOutDisplayTime', '00:00:00');

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

  /// Calculate statistical variation (standard deviation) for anti-spoofing
  double _calculateVariation(List<double> values) {
    if (values.isEmpty) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    double sumSquaredDiff = 0.0;
    for (final v in values) {
      sumSquaredDiff += (v - mean) * (v - mean);
    }
    final variance = sumSquaredDiff / values.length;

    return math.sqrt(variance);
  }
}
