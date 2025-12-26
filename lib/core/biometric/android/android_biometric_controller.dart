import 'package:get/get.dart';
import 'package:el_race/core/services/biometric_auth_service.dart';
import 'package:local_auth/local_auth.dart';

/// Android-specific biometric authentication states
enum AndroidBiometricState {
  idle,
  authenticating,
  success,
  failed,
  cancelled,
  notAvailable,
}

/// Android-focused biometric controller
/// Follows Material Design patterns
class AndroidBiometricController extends GetxController {
  final BiometricAuthService _authService;

  AndroidBiometricController(this._authService);

  final _state = AndroidBiometricState.idle.obs;
  final _errorMessage = ''.obs;
  final _biometricType = ''.obs; // "Fingerprint", "Face unlock", or "Biometric"

  AndroidBiometricState get state => _state.value;
  String get errorMessage => _errorMessage.value;
  String get biometricType => _biometricType.value;

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final canAuth = await _authService.canAuthenticateWithBiometrics();
      if (!canAuth) {
        _state.value = AndroidBiometricState.notAvailable;
        return false;
      }

      // Detect available biometric type for better UX
      final availableBiometrics = await _authService.getAvailableBiometrics();
      if (availableBiometrics.contains(BiometricType.fingerprint)) {
        _biometricType.value = 'Fingerprint';
      } else if (availableBiometrics.contains(BiometricType.face)) {
        _biometricType.value = 'Face unlock';
      } else if (availableBiometrics.contains(BiometricType.strong)) {
        _biometricType.value = 'Biometric';
      } else {
        _biometricType.value = 'Biometric';
      }

      return true;
    } catch (e) {
      _state.value = AndroidBiometricState.notAvailable;
      return false;
    }
  }

  /// Authenticate immediately - no delays
  Future<bool> authenticate({
    required String reason,
  }) async {
    _state.value = AndroidBiometricState.authenticating;
    _errorMessage.value = '';

    try {
      final result = await _authService.authenticate(
        reason: reason,
        biometricOnly: true,
        stickyAuth: true,
        useErrorDialogs: false, // We handle UI ourselves
      );

      if (result.success) {
        _state.value = AndroidBiometricState.success;
        return true;
      } else {
        _state.value = AndroidBiometricState.cancelled;
        return false;
      }
    } catch (e) {
      _state.value = AndroidBiometricState.failed;
      _errorMessage.value = _getUserFriendlyError(e.toString());
      return false;
    }
  }

  /// Convert technical errors to user-friendly messages
  String _getUserFriendlyError(String error) {
    if (error.contains('NotAvailable') || error.contains('not available')) {
      return 'Biometric authentication not available';
    } else if (error.contains('LockedOut') || error.contains('locked')) {
      return 'Too many attempts. Try again later';
    } else if (error.contains('PermanentlyLockedOut')) {
      return 'Biometric locked. Use device PIN';
    } else {
      return 'Authentication failed';
    }
  }

  /// Reset to idle state
  void reset() {
    _state.value = AndroidBiometricState.idle;
    _errorMessage.value = '';
  }
}
