import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../domain/entities/face_embedding.dart';
import '../../domain/entities/face_verification_result.dart';
import '../../domain/repositories/face_recognition_repository.dart';
import '../services/face_detector_service.dart';
import '../services/facenet_service.dart';
import '../services/face_embedding_storage_service.dart';
import '../helpers/image_preprocessing_helper.dart';
import '../helpers/embedding_comparison_helper.dart';

/// Implementation of Face Recognition Repository
///
/// This is the Data Layer implementation that orchestrates all services
/// to fulfill the domain layer contracts
///
/// Architecture:
/// Domain Layer (Interface) <- Data Layer (Implementation)
///
/// Clean Architecture Benefits:
/// - Domain logic is independent of implementation details
/// - Easy to test with mocks
/// - Can swap implementations without changing business logic
class FaceRecognitionRepositoryImpl implements FaceRecognitionRepository {
  final FaceDetectorService _faceDetectorService;
  final FaceNetService _faceNetService;
  final FaceEmbeddingStorageService _storageService;

  // Configuration
  final double _verificationThreshold;
  final bool _useCosineSimilarity;
  final bool _enableLivenessCheck;

  FaceRecognitionRepositoryImpl({
    required FaceDetectorService faceDetectorService,
    required FaceNetService faceNetService,
    required FaceEmbeddingStorageService storageService,
    double verificationThreshold = 0.8,
    bool useCosineSimilarity = false,
    bool enableLivenessCheck = true,
  })  : _faceDetectorService = faceDetectorService,
        _faceNetService = faceNetService,
        _storageService = storageService,
        _verificationThreshold = verificationThreshold,
        _useCosineSimilarity = useCosineSimilarity,
        _enableLivenessCheck = enableLivenessCheck;

  @override
  Future<Either<FaceRecognitionFailure, void>> initialize() async {
    try {
      // Initialize face detector
      await _faceDetectorService.initialize();

      // Initialize FaceNet model
      await _faceNetService.initialize();

      return const Right(null);
    } catch (e) {
      return const Left(ModelNotLoadedFailure());
    }
  }

  @override
  Future<Either<FaceRecognitionFailure, FaceEmbedding>> registerFace({
    required CameraImage image,
    required String userId,
    String? label,
    List<CameraImage>? additionalImages, // For anti-spoof check
  }) async {
    try {
      print('📷 Starting face registration for user: $userId');

      // Step 0: Anti-Spoofing check with multiple images
      if (additionalImages != null && additionalImages.length >= 3) {
        print(
            '🛡️ Step 0: Anti-spoofing check with ${additionalImages.length} images...');

        final List<Face> faceSequence = [];
        for (final img in additionalImages) {
          final faces = await _faceDetectorService.detectFaces(img);
          if (faces.isNotEmpty) {
            faceSequence.add(faces.first);
          }
        }

        if (faceSequence.length >= 3) {
          // Check for natural micro-movements
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
            return const Left(
              LivenessCheckFailure(
                'Registration failed. Please try again with a live face.',
              ),
            );
          }

          print('✅ Anti-spoofing check passed');
        }
      }

      // Step 1: Detect face
      print('🔍 Step 1: Detecting face...');
      final detectResult = await _detectSingleFace(image);
      if (detectResult.isLeft()) {
        print('❌ Face detection failed');
        return detectResult.fold((failure) {
          print('❌ Failure: ${failure.runtimeType} - ${failure.message}');
          return Left(failure);
        }, (_) => throw Exception());
      }

      final face = detectResult.getOrElse(() => throw Exception());
      print('✅ Face detected successfully');

      // Step 2: Check face quality (optional but recommended)
      print('📊 Step 2: Checking face quality...');
      final quality = _faceDetectorService.getFaceQuality(face);
      print('📊 Face quality: $quality');
      if (quality < 0.3) {
        print('❌ Face quality too low: $quality < 0.3');
        return const Left(
          EmbeddingGenerationFailure(
            'Face quality too low. Please ensure good lighting and face the camera directly.',
          ),
        );
      }
      print('✅ Face quality OK');

      // Step 3: Check liveness (if enabled) - relaxed for registration
      if (_enableLivenessCheck) {
        print('🔒 Step 3: Checking liveness...');
        // Use relaxed thresholds for registration (eyes can be partially open)
        final hasLiveness = _faceDetectorService.checkLiveness(
          face,
          eyeOpenThreshold: 0.1, // Lower threshold for registration
          maxHeadEulerAngleY: 30.0, // Allow more head rotation
          maxHeadEulerAngleZ: 30.0,
        );
        print('🔒 Liveness result: $hasLiveness');

        // Log detailed liveness info for debugging
        print('   👁️ Left eye: ${face.leftEyeOpenProbability}');
        print('   👁️ Right eye: ${face.rightEyeOpenProbability}');
        print('   🔄 Head Y angle: ${face.headEulerAngleY}');
        print('   🔄 Head Z angle: ${face.headEulerAngleZ}');

        if (!hasLiveness) {
          // For registration, warn but don't fail - only fail if eyes are completely null
          if (face.leftEyeOpenProbability == null ||
              face.rightEyeOpenProbability == null) {
            print(
                '⚠️ Liveness data not available, proceeding anyway for registration');
          } else {
            print('❌ Liveness check failed');
            return const Left(LivenessCheckFailure());
          }
        } else {
          print('✅ Liveness check passed');
        }
      } else {
        print('⏭️ Liveness check disabled');
      }

      // Step 4: Crop face from image
      print('✂️ Step 4: Cropping face...');
      final croppedFace = await ImagePreprocessingHelper.cropFace(image, face);
      print('✅ Face cropped');

      // Step 5: Generate embedding
      print('🧠 Step 5: Generating embedding...');
      final embedding = await _faceNetService.generateEmbedding(croppedFace);
      print('✅ Embedding generated (${embedding.length} dimensions)');

      // Step 6: Create FaceEmbedding entity
      final faceEmbedding = FaceEmbedding(
        embedding: embedding,
        userId: userId,
        createdAt: DateTime.now(),
        label: label,
      );

      // Step 7: Store embedding securely
      print('💾 Step 7: Storing embedding...');
      await _storageService.saveEmbedding(faceEmbedding);
      print('✅ Embedding stored successfully');

      print('🎉 Face registration completed successfully!');
      return Right(faceEmbedding);
    } on NoFaceDetectedFailure catch (e) {
      print('❌ NoFaceDetectedFailure: ${e.message}');
      return Left(e);
    } on MultipleFacesDetectedFailure catch (e) {
      print('❌ MultipleFacesDetectedFailure: ${e.message}');
      return Left(e);
    } on LivenessCheckFailure catch (e) {
      print('❌ LivenessCheckFailure: ${e.message}');
      return Left(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      return Left(EmbeddingGenerationFailure('Registration failed: $e'));
    }
  }

  @override
  Future<Either<FaceRecognitionFailure, FaceVerificationResult>> verifyFace({
    required CameraImage image,
    required String userId,
  }) async {
    try {
      print('\n🔐 ===== FACE VERIFICATION START =====');
      print('👤 User ID for verification: $userId');

      // Step 1: Check if user has registered embeddings
      print('🔍 Step 1: Checking for registered embeddings...');
      final storedEmbeddings = await _storageService.getEmbeddings(userId);
      print(
          '📦 Found ${storedEmbeddings.length} stored embeddings for user: $userId');

      if (storedEmbeddings.isEmpty) {
        print('❌ No registered embeddings found for user: $userId');
        print('   Available embeddings for debugging:');
        // Try to get all embeddings to debug
        print('   (Note: Check if userId is correct during registration)');
        return const Left(
          VerificationFailure('No registered face found for this user.'),
        );
      }

      print('✅ Found registered embeddings, proceeding with verification...');

      // Step 2: Detect face in current image
      final detectResult = await _detectSingleFace(image);
      if (detectResult.isLeft()) {
        return detectResult.fold(
          (failure) => Left(failure),
          (_) => throw Exception(),
        );
      }

      final face = detectResult.getOrElse(() => throw Exception());

      // Step 3: Check liveness (if enabled)
      bool hasLiveness = true;
      if (_enableLivenessCheck) {
        hasLiveness = _faceDetectorService.checkLiveness(face);
        if (!hasLiveness) {
          return const Right(
            FaceVerificationResult(
              isVerified: false,
              confidence: 0.0,
              message:
                  'Liveness check failed. Please ensure you are a real person.',
              hasLiveness: false,
            ),
          );
        }
      }

      // Step 4: Crop face
      final croppedFace = await ImagePreprocessingHelper.cropFace(image, face);

      // Step 5: Generate embedding for current face
      final currentEmbedding =
          await _faceNetService.generateEmbedding(croppedFace);

      // Step 6: Compare with stored embeddings
      final storedEmbeddingVectors =
          storedEmbeddings.map((e) => e.embedding).toList();

      final matchResult = EmbeddingComparisonHelper.findBestMatch(
        currentEmbedding,
        storedEmbeddingVectors,
        threshold: _verificationThreshold,
        useCosineSimilarity: _useCosineSimilarity,
      );

      // Step 7: Calculate confidence score
      final confidence = EmbeddingComparisonHelper.getConfidenceScore(
        currentEmbedding,
        storedEmbeddingVectors[matchResult['bestIndex']],
        useCosineSimilarity: _useCosineSimilarity,
      );

      // Step 8: Create verification result
      final isVerified = matchResult['isMatch'] as bool;
      final message = isVerified
          ? 'Face verified successfully!'
          : 'Face verification failed. Please try again.';

      return Right(
        FaceVerificationResult(
          isVerified: isVerified,
          confidence: confidence,
          message: message,
          hasLiveness: hasLiveness,
        ),
      );
    } on NoFaceDetectedFailure catch (e) {
      return Left(e);
    } on MultipleFacesDetectedFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(VerificationFailure('Verification failed: $e'));
    }
  }

  @override
  Future<Either<FaceRecognitionFailure, List<FaceEmbedding>>>
      getStoredEmbeddings(String userId) async {
    try {
      final embeddings = await _storageService.getEmbeddings(userId);
      return Right(embeddings);
    } catch (e) {
      return Left(StorageFailure('Failed to retrieve embeddings: $e'));
    }
  }

  @override
  Future<Either<FaceRecognitionFailure, void>> deleteEmbeddings(
      String userId) async {
    try {
      await _storageService.deleteEmbeddings(userId);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to delete embeddings: $e'));
    }
  }

  @override
  Future<Either<FaceRecognitionFailure, bool>> checkLiveness(
      CameraImage image) async {
    try {
      final faces = await _faceDetectorService.detectFaces(image);

      if (faces.isEmpty) {
        return const Left(NoFaceDetectedFailure());
      }

      if (faces.length > 1) {
        return const Left(MultipleFacesDetectedFailure());
      }

      final hasLiveness = _faceDetectorService.checkLiveness(faces.first);
      return Right(hasLiveness);
    } catch (e) {
      return const Left(LivenessCheckFailure());
    }
  }

  /// Helper: Detect exactly one face in the image
  ///
  /// Returns Left with failure if no face or multiple faces detected
  /// Returns Right with the detected face
  Future<Either<FaceRecognitionFailure, Face>> _detectSingleFace(
      CameraImage image) async {
    final faces = await _faceDetectorService.detectFaces(image);

    if (faces.isEmpty) {
      return const Left(NoFaceDetectedFailure());
    }

    if (faces.length > 1) {
      return const Left(MultipleFacesDetectedFailure());
    }

    return Right(faces.first);
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

  /// Delete all stored embeddings (for debugging/cleanup)
  Future<void> deleteAllEmbeddings() async {
    await _storageService.deleteAllEmbeddings();
  }
}
