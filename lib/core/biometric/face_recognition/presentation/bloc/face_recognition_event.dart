import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';

/// Events for Face Recognition Cubit
abstract class FaceRecognitionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Initialize the face recognition system
class InitializeFaceRecognition extends FaceRecognitionEvent {}

/// Initialize camera for capture
class InitializeCamera extends FaceRecognitionEvent {
  final CameraDescription camera;

  InitializeCamera(this.camera);

  @override
  List<Object?> get props => [camera];
}

/// Start face registration process
class StartFaceRegistration extends FaceRecognitionEvent {
  final CameraImage image;
  final String userId;
  final String? label;

  StartFaceRegistration({
    required this.image,
    required this.userId,
    this.label,
  });

  @override
  List<Object?> get props => [image, userId, label];
}

/// Start face verification process
class StartFaceVerification extends FaceRecognitionEvent {
  final CameraImage image;
  final String userId;

  StartFaceVerification({
    required this.image,
    required this.userId,
  });

  @override
  List<Object?> get props => [image, userId];
}

/// Check liveness of detected face
class CheckFaceLiveness extends FaceRecognitionEvent {
  final CameraImage image;

  CheckFaceLiveness(this.image);

  @override
  List<Object?> get props => [image];
}

/// Delete stored embeddings
class DeleteStoredEmbeddings extends FaceRecognitionEvent {
  final String userId;

  DeleteStoredEmbeddings(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Reset to initial state
class ResetFaceRecognition extends FaceRecognitionEvent {}
