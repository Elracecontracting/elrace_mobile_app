import 'package:dartz/dartz.dart';
import '../repositories/face_recognition_repository.dart';

/// Use Case: Initialize the Face Recognition System
class InitializeFaceRecognitionUseCase {
  final FaceRecognitionRepository repository;

  InitializeFaceRecognitionUseCase(this.repository);

  Future<Either<FaceRecognitionFailure, void>> call() async {
    return await repository.initialize();
  }
}
