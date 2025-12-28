import 'package:dartz/dartz.dart';
import 'package:camera/camera.dart';
import '../entities/face_embedding.dart';
import '../entities/face_verification_result.dart';

/// Repository interface for Face Recognition operations
/// Following Clean Architecture - Domain Layer defines the contract
abstract class FaceRecognitionRepository {
  /// Initialize the face recognition system (load models, etc.)
  Future<Either<FaceRecognitionFailure, void>> initialize();

  /// Register a new face embedding for the user
  /// Takes camera image and returns the stored embedding
  Future<Either<FaceRecognitionFailure, FaceEmbedding>> registerFace({
    required CameraImage image,
    required String userId,
    String? label,
  });

  /// Verify a face against stored embedding(s)
  /// Returns verification result with confidence score
  Future<Either<FaceRecognitionFailure, FaceVerificationResult>> verifyFace({
    required CameraImage image,
    required String userId,
  });

  /// Get all stored embeddings for a user
  Future<Either<FaceRecognitionFailure, List<FaceEmbedding>>>
      getStoredEmbeddings(String userId);

  /// Delete all stored embeddings for a user
  Future<Either<FaceRecognitionFailure, void>> deleteEmbeddings(String userId);

  /// Check if the detected face has liveness (real person, not photo)
  Future<Either<FaceRecognitionFailure, bool>> checkLiveness(CameraImage image);
}

/// Base class for all face recognition failures
abstract class FaceRecognitionFailure {
  final String message;
  const FaceRecognitionFailure(this.message);
}

class NoFaceDetectedFailure extends FaceRecognitionFailure {
  const NoFaceDetectedFailure()
      : super(
            'No face detected in the image. Please ensure your face is visible.');
}

class MultipleFacesDetectedFailure extends FaceRecognitionFailure {
  const MultipleFacesDetectedFailure()
      : super(
            'Multiple faces detected. Please ensure only one person is in frame.');
}

class ModelNotLoadedFailure extends FaceRecognitionFailure {
  const ModelNotLoadedFailure()
      : super('Face recognition model not loaded. Please initialize first.');
}

class EmbeddingGenerationFailure extends FaceRecognitionFailure {
  const EmbeddingGenerationFailure(String message) : super(message);
}

class StorageFailure extends FaceRecognitionFailure {
  const StorageFailure(String message) : super(message);
}

class LivenessCheckFailure extends FaceRecognitionFailure {
  const LivenessCheckFailure()
      : super('Liveness check failed. Please ensure you are a real person.');
}

class VerificationFailure extends FaceRecognitionFailure {
  const VerificationFailure(String message) : super(message);
}
