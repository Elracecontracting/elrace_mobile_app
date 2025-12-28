import 'package:dartz/dartz.dart';
import 'package:camera/camera.dart';
import '../entities/face_embedding.dart';
import '../repositories/face_recognition_repository.dart';

/// Use Case: Register a new face for the user
/// Clean Architecture - Business Logic in Domain Layer
class RegisterFaceUseCase {
  final FaceRecognitionRepository repository;

  RegisterFaceUseCase(this.repository);

  Future<Either<FaceRecognitionFailure, FaceEmbedding>> call({
    required CameraImage image,
    required String userId,
    String? label,
  }) async {
    return await repository.registerFace(
      image: image,
      userId: userId,
      label: label,
    );
  }
}
