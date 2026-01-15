import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';

/// States for Face Recognition feature
abstract class FaceRecognitionState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Initial state
class FaceRecognitionInitial extends FaceRecognitionState {}

/// Loading/Processing states
class FaceRecognitionLoading extends FaceRecognitionState {
  final String message;

  FaceRecognitionLoading({this.message = 'Processing...'});

  @override
  List<Object?> get props => [message];
}

/// Camera ready for capture
class FaceRecognitionCameraReady extends FaceRecognitionState {
  final CameraController cameraController;

  FaceRecognitionCameraReady(this.cameraController);

  @override
  List<Object?> get props => [cameraController];
}

/// Face detected and being analyzed
class FaceDetected extends FaceRecognitionState {
  final bool hasLiveness;
  final double quality;

  FaceDetected({
    required this.hasLiveness,
    required this.quality,
  });

  @override
  List<Object?> get props => [hasLiveness, quality];
}

/// Registration successful
class FaceRegistrationSuccess extends FaceRecognitionState {
  final String message;

  FaceRegistrationSuccess({this.message = 'Face registered successfully!'});

  @override
  List<Object?> get props => [message];
}

/// Verification result
class FaceVerificationResult extends FaceRecognitionState {
  final bool isVerified;
  final double confidence;
  final String message;
  final bool hasLiveness;

  FaceVerificationResult({
    required this.isVerified,
    required this.confidence,
    required this.message,
    required this.hasLiveness,
  });

  @override
  List<Object?> get props => [isVerified, confidence, message, hasLiveness];
}

/// Error states
class FaceRecognitionError extends FaceRecognitionState {
  final String message;
  final FaceRecognitionErrorType errorType;

  FaceRecognitionError({
    required this.message,
    required this.errorType,
  });

  @override
  List<Object?> get props => [message, errorType];
}

/// Liveness challenge in progress
class LivenessChallengeInProgress extends FaceRecognitionState {
  final String challengeText;
  final int currentChallengeIndex;
  final int totalChallenges;
  final List<String> completedChallenges;

  LivenessChallengeInProgress({
    required this.challengeText,
    required this.currentChallengeIndex,
    required this.totalChallenges,
    this.completedChallenges = const [],
  });

  @override
  List<Object?> get props => [
        challengeText,
        currentChallengeIndex,
        totalChallenges,
        completedChallenges
      ];
}

/// Liveness check completed
class LivenessCheckComplete extends FaceRecognitionState {
  final bool passed;
  final String message;

  LivenessCheckComplete({
    required this.passed,
    required this.message,
  });

  @override
  List<Object?> get props => [passed, message];
}

/// Error types for better UI handling
enum FaceRecognitionErrorType {
  noFaceDetected,
  multipleFacesDetected,
  livenessCheckFailed,
  modelNotLoaded,
  cameraError,
  storageError,
  verificationFailed,
  unknown,
}
