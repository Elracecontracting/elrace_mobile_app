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
  final String challengeInstruction;
  final int currentChallengeIndex;
  final int totalChallenges;
  final List<String> completedChallenges;
  final int iconCodePoint; // لعرض الأيقونة

  LivenessChallengeInProgress({
    required this.challengeText,
    required this.challengeInstruction,
    required this.currentChallengeIndex,
    required this.totalChallenges,
    this.completedChallenges = const [],
    this.iconCodePoint = 0xe3fc, // visibility icon default
  });

  @override
  List<Object?> get props => [
        challengeText,
        challengeInstruction,
        currentChallengeIndex,
        totalChallenges,
        completedChallenges,
        iconCodePoint,
      ];
}

/// 🆕 حالة انتظار التحدي التالي
class WaitingForNextChallenge extends FaceRecognitionState {
  final String previousChallengeResult;
  final int nextChallengeIndex;
  final int totalChallenges;
  final List<String> completedChallenges;

  WaitingForNextChallenge({
    required this.previousChallengeResult,
    required this.nextChallengeIndex,
    required this.totalChallenges,
    required this.completedChallenges,
  });

  @override
  List<Object?> get props => [
        previousChallengeResult,
        nextChallengeIndex,
        totalChallenges,
        completedChallenges,
      ];
}

/// 🆕 حالة نجاح تحدي واحد
class SingleChallengeSuccess extends FaceRecognitionState {
  final String challengeName;
  final int challengeIndex;
  final int totalChallenges;
  final String message;

  SingleChallengeSuccess({
    required this.challengeName,
    required this.challengeIndex,
    required this.totalChallenges,
    required this.message,
  });

  @override
  List<Object?> get props => [challengeName, challengeIndex, totalChallenges, message];
}

/// 🆕 حالة فشل تحدي واحد
class SingleChallengeFailed extends FaceRecognitionState {
  final String challengeName;
  final int challengeIndex;
  final int totalChallenges;
  final String message;

  SingleChallengeFailed({
    required this.challengeName,
    required this.challengeIndex,
    required this.totalChallenges,
    required this.message,
  });

  @override
  List<Object?> get props => [challengeName, challengeIndex, totalChallenges, message];
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
  deviceMismatch,        // NEW: Device binding violation
  noFirebaseData,        // NEW: No data in Firebase
  crossDeviceBlocked,    // NEW: Registration blocked from different device
  unknown,
}

// ==================== NEW SECURITY STATES ====================

/// Device binding check result (NEW - Security Enhancement)
class DeviceBindingCheckResult extends FaceRecognitionState {
  final bool isSameDevice;
  final String? registeredDeviceId;
  final String? currentDeviceId;
  final String message;

  DeviceBindingCheckResult({
    required this.isSameDevice,
    this.registeredDeviceId,
    this.currentDeviceId,
    required this.message,
  });

  @override
  List<Object?> get props => [isSameDevice, registeredDeviceId, currentDeviceId, message];
}

/// Device transfer requested (NEW - Security Enhancement)
class DeviceTransferRequestedState extends FaceRecognitionState {
  final bool success;
  final String message;

  DeviceTransferRequestedState({
    required this.success,
    required this.message,
  });

  @override
  List<Object?> get props => [success, message];
}

/// Sync status (NEW - Security Enhancement)
class SyncWithFirebaseResult extends FaceRecognitionState {
  final bool success;
  final String message;

  SyncWithFirebaseResult({
    required this.success,
    required this.message,
  });

  @override
  List<Object?> get props => [success, message];
}

/// Registration status across both storage systems (NEW - Security Enhancement)
class RegistrationStatusResult extends FaceRecognitionState {
  final bool hasLocalData;
  final bool hasFirebaseData;
  final bool isComplete;
  final bool isSameDevice;
  final String message;

  RegistrationStatusResult({
    required this.hasLocalData,
    required this.hasFirebaseData,
    required this.isComplete,
    required this.isSameDevice,
    required this.message,
  });

  @override
  List<Object?> get props => [hasLocalData, hasFirebaseData, isComplete, isSameDevice, message];
}
