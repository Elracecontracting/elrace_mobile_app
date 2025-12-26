import 'package:equatable/equatable.dart';
import 'package:el_race/core/services/biometric_auth_service.dart';

/// Biometric authentication states for state-driven UI
abstract class BiometricAuthState extends Equatable {
  const BiometricAuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class BiometricAuthIdle extends BiometricAuthState {
  const BiometricAuthIdle();
}

/// Checking if biometrics are available
class BiometricAuthCheckingAvailability extends BiometricAuthState {
  const BiometricAuthCheckingAvailability();
}

/// Biometrics are available and ready
class BiometricAuthAvailable extends BiometricAuthState {
  final String biometricTypeName;
  final bool hasFaceId;
  final bool hasFingerprint;

  const BiometricAuthAvailable({
    required this.biometricTypeName,
    required this.hasFaceId,
    required this.hasFingerprint,
  });

  @override
  List<Object?> get props => [biometricTypeName, hasFaceId, hasFingerprint];
}

/// Biometrics not available on device
class BiometricAuthNotAvailable extends BiometricAuthState {
  final String reason;

  const BiometricAuthNotAvailable({required this.reason});

  @override
  List<Object?> get props => [reason];
}

/// Authentication in progress
class BiometricAuthAuthenticating extends BiometricAuthState {
  final String biometricTypeName;

  const BiometricAuthAuthenticating({required this.biometricTypeName});

  @override
  List<Object?> get props => [biometricTypeName];
}

/// Authentication succeeded
class BiometricAuthSuccess extends BiometricAuthState {
  const BiometricAuthSuccess();
}

/// Authentication failed
class BiometricAuthFailure extends BiometricAuthState {
  final String errorMessage;
  final BiometricAuthErrorType errorType;
  final bool canRetry;

  const BiometricAuthFailure({
    required this.errorMessage,
    required this.errorType,
    required this.canRetry,
  });

  @override
  List<Object?> get props => [errorMessage, errorType, canRetry];
}

/// User cancelled authentication
class BiometricAuthCancelled extends BiometricAuthState {
  const BiometricAuthCancelled();
}

/// Too many failed attempts - locked out
class BiometricAuthLockedOut extends BiometricAuthState {
  final String message;
  final bool isPermanent;

  const BiometricAuthLockedOut({
    required this.message,
    required this.isPermanent,
  });

  @override
  List<Object?> get props => [message, isPermanent];
}
