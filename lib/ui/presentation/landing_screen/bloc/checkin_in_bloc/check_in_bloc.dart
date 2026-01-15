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
        emit(const FaceVerificationFailedST('Error: Image file not found'));
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
        emit(const FaceVerificationFailedST('No face detected in the image'));
        return;
      }

      if (faces.length > 1) {
        print('❌ Multiple faces detected');
        emit(const FaceVerificationFailedST('Multiple faces detected'));
        return;
      }

      final face = faces.first;

      // Step 2: Anti-Spoofing check using multiple images
      if (event.additionalImagePaths != null &&
          event.additionalImagePaths!.length >= 3) {
        print(
            '🛡️ Performing anti-spoofing check with ${event.additionalImagePaths!.length} images...');

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

          print('   📊 Head Yaw variation: $yawVariation°');
          print('   📊 Head Pitch variation: $pitchVariation°');

          // If face is perfectly static (< 0.3° movement), it's likely a photo
          if (yawVariation < 0.3 && pitchVariation < 0.3) {
            print('❌ Anti-spoof FAILED: Face is too static (possible photo)');
            emit(const FaceVerificationFailedST(
                'Verification failed. Please try again'));
            return;
          }

          print('✅ Anti-spoofing check passed');
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

      // Log detailed info
      print('   👁️ Left eye: ${face.leftEyeOpenProbability}');
      print('   👁️ Right eye: ${face.rightEyeOpenProbability}');
      print('   🔄 Head Y: ${face.headEulerAngleY}');
      print('   🔄 Head Z: ${face.headEulerAngleZ}');

      if (!hasLiveness) {
        print('❌ Liveness check failed');
        emit(const FaceVerificationFailedST(
            'Please look directly at the camera with eyes open'));
        return;
      }

      // Step 4: Check face quality
      final quality = _faceDetectorService.getFaceQuality(face);
      if (quality < 0.3) {
        print('❌ Face quality too low: $quality');
        emit(const FaceVerificationFailedST(
            'Image quality is low. Please ensure good lighting'));
        return;
      }

      print('✅ Face quality: $quality');
      print('✅ Liveness check passed');

      // Step 4: Extract embedding from captured image and compare with stored
      try {
        // Get stored embeddings
        final storedEmbeddings = await _storageService.getEmbeddings(userId);
        if (storedEmbeddings.isEmpty) {
          print('❌ No stored embeddings found');
          emit(const FaceNotEnrolledST());
          return;
        }

        // Extract embedding from current image using FaceNet
        final currentEmbedding = await _faceNetService.getEmbeddingFromFile(
          imageFile,
          face.boundingBox,
        );

        if (currentEmbedding == null) {
          print('❌ Failed to extract face embedding');
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

        print('📊 Best match distance: $bestDistance');

        // Verification threshold:
        // < 0.5 = Very strict (may reject valid users)
        // 0.5-0.6 = Strict but fair (recommended)
        // 0.6-0.7 = Balanced
        // > 0.7 = Too lenient (security risk)
        const verificationThreshold =
            0.65; // Balanced: secure but not frustrating

        if (bestDistance > verificationThreshold) {
          print(
              '❌ Face does not match. Distance: $bestDistance (threshold: $verificationThreshold)');
          emit(const FaceVerificationFailedST(
              'Face verification failed. Please try again'));
          return;
        }

        print('✅ Face verified successfully! Distance: $bestDistance');
        emit(const FaceVerificationSuccessST());
      } catch (embeddingError) {
        print('❌ Embedding comparison failed: $embeddingError');
        // DO NOT allow fallback - this is a security risk
        emit(const FaceVerificationFailedST(
            'Face verification error. Please try again'));
        return;
      }
    } catch (e) {
      print('❌ Error during face verification: $e');
      emit(FaceVerificationFailedST('Verification error: $e'));
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
