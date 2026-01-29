import 'package:dartz/dartz.dart';
import 'package:camera/camera.dart';
import '../entities/face_verification_result.dart';
import '../repositories/face_recognition_repository.dart';

/// Use Case: Verify a face against stored embeddings
/// Clean Architecture - Business Logic in Domain Layer
class VerifyFaceUseCase {
  final FaceRecognitionRepository repository;

  VerifyFaceUseCase(this.repository);

  Future<Either<FaceRecognitionFailure, FaceVerificationResult>> call({
    required CameraImage image,
    required String userId,
    List<CameraImage>? allFrames, // 🆕 For multi-frame analysis
  }) async {
    return await repository.verifyFace(
      image: image,
      userId: userId,
      allFrames: allFrames,
    );
  }
}
