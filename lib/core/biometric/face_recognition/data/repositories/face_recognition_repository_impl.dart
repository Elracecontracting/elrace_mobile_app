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
  }) async {
    try {
      // Step 1: Detect face
      final detectResult = await _detectSingleFace(image);
      if (detectResult.isLeft()) {
        return detectResult.fold(
            (failure) => Left(failure), (_) => throw Exception());
      }

      final face = detectResult.getOrElse(() => throw Exception());

      // Step 2: Check face quality (optional but recommended)
      final quality = _faceDetectorService.getFaceQuality(face);
      if (quality < 0.3) {
        return const Left(
          EmbeddingGenerationFailure(
            'Face quality too low. Please ensure good lighting and face the camera directly.',
          ),
        );
      }

      // Step 3: Check liveness (if enabled)
      if (_enableLivenessCheck) {
        final hasLiveness = _faceDetectorService.checkLiveness(face);
        if (!hasLiveness) {
          return const Left(LivenessCheckFailure());
        }
      }

      // Step 4: Crop face from image
      final croppedFace = await ImagePreprocessingHelper.cropFace(image, face);

      // Step 5: Generate embedding
      final embedding = await _faceNetService.generateEmbedding(croppedFace);

      // Step 6: Create FaceEmbedding entity
      final faceEmbedding = FaceEmbedding(
        embedding: embedding,
        userId: userId,
        createdAt: DateTime.now(),
        label: label,
      );

      // Step 7: Store embedding securely
      await _storageService.saveEmbedding(faceEmbedding);

      return Right(faceEmbedding);
    } on NoFaceDetectedFailure catch (e) {
      return Left(e);
    } on MultipleFacesDetectedFailure catch (e) {
      return Left(e);
    } on LivenessCheckFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(EmbeddingGenerationFailure('Registration failed: $e'));
    }
  }

  @override
  Future<Either<FaceRecognitionFailure, FaceVerificationResult>> verifyFace({
    required CameraImage image,
    required String userId,
  }) async {
    try {
      // Step 1: Check if user has registered embeddings
      final storedEmbeddings = await _storageService.getEmbeddings(userId);
      if (storedEmbeddings.isEmpty) {
        return const Left(
          VerificationFailure('No registered face found for this user.'),
        );
      }

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
}
