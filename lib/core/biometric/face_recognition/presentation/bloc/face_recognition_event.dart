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
/// Now supports multiple images for anti-spoofing detection
class StartFaceRegistration extends FaceRecognitionEvent {
  final CameraImage image;
  final String userId;
  final String? label;
  final List<CameraImage>? additionalImages; // For anti-spoof check

  StartFaceRegistration({
    required this.image,
    required this.userId,
    this.label,
    this.additionalImages,
  });

  @override
  List<Object?> get props => [image, userId, label, additionalImages];
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

/// Start active liveness challenge check
class StartLivenessChallenge extends FaceRecognitionEvent {
  final Stream<CameraImage> frameStream;

  StartLivenessChallenge({required this.frameStream});

  @override
  List<Object?> get props => [];
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

/// Check device binding status (NEW - Security Enhancement)
class CheckDeviceBindingEvent extends FaceRecognitionEvent {
  final String userId;

  CheckDeviceBindingEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Request device transfer (NEW - Security Enhancement)
class RequestDeviceTransferEvent extends FaceRecognitionEvent {
  final String userId;
  final String reason;

  RequestDeviceTransferEvent({
    required this.userId,
    required this.reason,
  });

  @override
  List<Object?> get props => [userId, reason];
}

/// Sync local data with Firebase (NEW - Security Enhancement)
class SyncWithFirebaseEvent extends FaceRecognitionEvent {
  final String userId;

  SyncWithFirebaseEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}
