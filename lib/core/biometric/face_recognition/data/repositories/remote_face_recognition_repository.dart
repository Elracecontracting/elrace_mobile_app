import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../domain/entities/face_embedding.dart';
import '../../domain/entities/face_verification_result.dart';
import '../../domain/repositories/face_recognition_repository.dart';

/// FUTURE: Bank-grade remote implementation.
///
/// This stub intentionally returns failures until a server-side / SDK-based
/// integration is added. It keeps the interface stable for migration.
class RemoteFaceRecognitionRepository implements FaceRecognitionRepository {
  @override
  Future<Either<FaceRecognitionFailure, void>> initialize() async {
    return const Left(ModelNotLoadedFailure());
  }

  @override
  Future<Either<FaceRecognitionFailure, FaceEmbedding>> registerFace({
    required CameraImage image,
    required String userId,
    String? label,
    List<CameraImage>? additionalImages,
  }) async {
    return const Left(VerificationFailure(
      'Remote biometric enrollment not implemented. Wire this to the bank-grade SDK.',
    ));
  }

  @override
  Future<Either<FaceRecognitionFailure, FaceVerificationResult>> verifyFace({
    required CameraImage image,
    required String userId,
    CameraLensDirection? lensDirection,
    int? sensorOrientation,
    List<CameraImage>? allFrames,
  }) async {
    return const Left(VerificationFailure(
      'Remote biometric verification not implemented. Wire this to the bank-grade SDK.',
    ));
  }

  @override
  Future<Either<FaceRecognitionFailure, List<FaceEmbedding>>>
      getStoredEmbeddings(String userId) async {
    return const Left(VerificationFailure(
      'Remote biometric storage not implemented. Use server-side templates.',
    ));
  }

  @override
  Future<Either<FaceRecognitionFailure, void>> deleteEmbeddings(
      String userId) async {
    return const Left(VerificationFailure(
      'Remote biometric deletion not implemented. Add server call.',
    ));
  }

  @override
  Future<Either<FaceRecognitionFailure, bool>> checkLiveness(
    CameraImage image, {
    CameraLensDirection? lensDirection,
    int? sensorOrientation,
  }) async {
    return const Left(LivenessCheckFailure());
  }

  @override
  Future<List<Face>> detectFaces(CameraImage image) async {
    return const [];
  }
}
