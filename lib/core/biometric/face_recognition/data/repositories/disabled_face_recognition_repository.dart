import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../domain/entities/face_embedding.dart';
import '../../domain/entities/face_verification_result.dart';
import '../../domain/repositories/face_recognition_repository.dart';

/// Disabled implementation used when local biometrics are turned off via flags.
/// All calls return failures to ensure the UI can respond gracefully.
class DisabledFaceRecognitionRepository implements FaceRecognitionRepository {
  const DisabledFaceRecognitionRepository();

  @override
  Future<Either<FaceRecognitionFailure, void>> initialize() async {
    return const Left(VerificationFailure(
      'Biometrics are disabled in this build. Enable ENABLE_LOCAL_BIOMETRICS to use the temporary local flow.',
    ));
  }

  @override
  Future<Either<FaceRecognitionFailure, FaceEmbedding>> registerFace({
    required CameraImage image,
    required String userId,
    String? label,
    List<CameraImage>? additionalImages,
  }) async {
    return const Left(VerificationFailure(
      'Local biometrics are disabled by feature flag.',
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
      'Local biometrics are disabled by feature flag.',
    ));
  }

  @override
  Future<Either<FaceRecognitionFailure, List<FaceEmbedding>>>
      getStoredEmbeddings(String userId) async {
    return const Left(VerificationFailure(
      'Local biometrics are disabled by feature flag.',
    ));
  }

  @override
  Future<Either<FaceRecognitionFailure, void>> deleteEmbeddings(
      String userId) async {
    return const Left(VerificationFailure(
      'Local biometrics are disabled by feature flag.',
    ));
  }

  @override
  Future<Either<FaceRecognitionFailure, bool>> checkLiveness(
    CameraImage image, {
    CameraLensDirection? lensDirection,
    int? sensorOrientation,
  }) async {
    return const Left(VerificationFailure(
      'Local biometrics are disabled by feature flag.',
    ));
  }

  @override
  Future<List<Face>> detectFaces(CameraImage image) async {
    return const [];
  }
}
