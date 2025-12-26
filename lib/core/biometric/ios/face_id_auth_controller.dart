import 'package:get/get.dart';
import 'package:el_race/core/services/biometric_auth_service.dart';
import 'package:local_auth/local_auth.dart';

/// iOS-specific Face ID authentication states
enum FaceIdState {
  idle,
  authenticating,
  success,
  failed,
  cancelled,
  notAvailable,
}

/// iOS-focused Face ID controller
/// Follows Apple's authentication patterns
class FaceIdAuthController extends GetxController {
  final BiometricAuthService _authService;

  FaceIdAuthController(this._authService);

  final _state = FaceIdState.idle.obs;
  final _errorMessage = ''.obs;

  FaceIdState get state => _state.value;
  String get errorMessage => _errorMessage.value;

  /// Check if Face ID is available on this device
  Future<bool> isFaceIdAvailable() async {
    try {
      final canAuth = await _authService.canAuthenticateWithBiometrics();
      if (!canAuth) {
        _state.value = FaceIdState.notAvailable;
        return false;
      }

      // Check specifically for Face ID (iOS only)
      final availableBiometrics = await _authService.getAvailableBiometrics();
      final hasFaceId = availableBiometrics.contains(BiometricType.face);

      if (!hasFaceId) {
        _state.value = FaceIdState.notAvailable;
        return false;
      }

      return true;
    } catch (e) {
      _state.value = FaceIdState.notAvailable;
      return false;
    }
  }

  /// Authenticate with Face ID immediately
  /// No delays, starts instantly
  Future<bool> authenticate({
    required String reason,
  }) async {
    _state.value = FaceIdState.authenticating;
    _errorMessage.value = '';

    try {
      final result = await _authService.authenticate(
        reason: reason,
        biometricOnly: true,
        stickyAuth: true,
        useErrorDialogs: false, // We handle UI ourselves
      );

      if (result.success) {
        _state.value = FaceIdState.success;
        return true;
      } else {
        _state.value = FaceIdState.cancelled;
        return false;
      }
    } catch (e) {
      _state.value = FaceIdState.failed;
      _errorMessage.value = _getUserFriendlyError(e.toString());
      return false;
    }
  }

  /// Convert technical errors to user-friendly messages
  String _getUserFriendlyError(String error) {
    if (error.contains('NotAvailable') || error.contains('not available')) {
      return 'Face ID is not available';
    } else if (error.contains('LockedOut') || error.contains('locked')) {
      return 'Too many attempts. Try again later';
    } else if (error.contains('PermanentlyLockedOut')) {
      return 'Face ID is locked. Use device passcode';
    } else {
      return 'Face ID failed';
    }
  }

  /// Reset to idle state
  void reset() {
    _state.value = FaceIdState.idle;
    _errorMessage.value = '';
  }
}
