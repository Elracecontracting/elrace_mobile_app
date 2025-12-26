import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:el_race/core/services/biometric_auth_service.dart';
import 'package:el_race/core/biometric/biometric_auth_state.dart';

/// Controller for managing biometric authentication state and flow
///
/// This controller provides a clean, state-driven API for biometric authentication
/// that can be used throughout the app. It manages all state transitions and
/// delegates actual biometric operations to BiometricAuthService.
class BiometricAuthController extends GetxController {
  final BiometricAuthService _biometricService = BiometricAuthService.instance;

  // Reactive state - expose the Rx object for ever() listeners
  final Rx<BiometricAuthState> _state = const BiometricAuthIdle().obs;
  BiometricAuthState get state => _state.value;
  Rx<BiometricAuthState> get rx => _state; // Public getter for ever() listeners

  // Cached biometric info
  String _biometricTypeName = '';
  bool _hasFaceId = false;
  bool _hasFingerprint = false;

  @override
  void onInit() {
    super.onInit();
    checkAvailability();
  }

  /// Check if biometric authentication is available on this device
  Future<void> checkAvailability() async {
    _state.value = const BiometricAuthCheckingAvailability();

    try {
      final isAvailable =
          await _biometricService.canAuthenticateWithBiometrics();

      if (!isAvailable) {
        _state.value = const BiometricAuthNotAvailable(
          reason: 'Biometric authentication is not available on this device',
        );
        return;
      }

      // Get biometric details
      _biometricTypeName = await _biometricService.getBiometricTypeName();
      _hasFaceId = await _biometricService.isFaceIdAvailable();
      _hasFingerprint = await _biometricService.isFingerprintAvailable();

      _state.value = BiometricAuthAvailable(
        biometricTypeName: _biometricTypeName,
        hasFaceId: _hasFaceId,
        hasFingerprint: _hasFingerprint,
      );

      debugPrint('🔐 BiometricAuthController: $_biometricTypeName available');
    } catch (e) {
      debugPrint('🔐 BiometricAuthController: Error checking availability: $e');
      _state.value = BiometricAuthNotAvailable(
        reason: 'Unable to check biometric availability',
      );
    }
  }

  /// Authenticate user with biometrics
  ///
  /// [reason] - User-facing explanation of why authentication is needed
  /// [biometricOnly] - If true, only biometric authentication (no passcode fallback)
  Future<bool> authenticate({
    required String reason,
    bool biometricOnly = true,
  }) async {
    // Ensure biometrics are available
    if (state is! BiometricAuthAvailable) {
      await checkAvailability();
      if (state is! BiometricAuthAvailable) {
        return false;
      }
    }

    // Start authentication
    _state.value = BiometricAuthAuthenticating(
      biometricTypeName: _biometricTypeName,
    );

    try {
      final result = await _biometricService.authenticate(
        reason: reason,
        biometricOnly: biometricOnly,
        stickyAuth: true,
        useErrorDialogs: false, // We handle UI ourselves
      );

      if (result.success) {
        _state.value = const BiometricAuthSuccess();
        debugPrint('🔐 BiometricAuthController: ✅ Authentication successful');

        // Auto-reset to available after a short delay
        Future.delayed(const Duration(milliseconds: 800), () {
          if (_state.value is BiometricAuthSuccess) {
            _state.value = BiometricAuthAvailable(
              biometricTypeName: _biometricTypeName,
              hasFaceId: _hasFaceId,
              hasFingerprint: _hasFingerprint,
            );
          }
        });

        return true;
      } else {
        _handleAuthenticationError(result);
        return false;
      }
    } catch (e) {
      debugPrint('🔐 BiometricAuthController: ❌ Error: $e');
      _state.value = const BiometricAuthFailure(
        errorMessage: 'An unexpected error occurred',
        errorType: BiometricAuthErrorType.unknown,
        canRetry: true,
      );
      return false;
    }
  }

  /// Handle authentication errors and set appropriate state
  void _handleAuthenticationError(BiometricAuthResult result) {
    final errorType = result.errorType!;
    final errorMessage = result.errorMessage ?? 'Authentication failed';

    switch (errorType) {
      case BiometricAuthErrorType.lockedOut:
        _state.value = BiometricAuthLockedOut(
          message: errorMessage,
          isPermanent: false,
        );
        break;

      case BiometricAuthErrorType.permanentlyLockedOut:
        _state.value = BiometricAuthLockedOut(
          message: errorMessage,
          isPermanent: true,
        );
        break;

      case BiometricAuthErrorType.canceled:
        _state.value = const BiometricAuthCancelled();
        // Auto-reset to available after cancellation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_state.value is BiometricAuthCancelled) {
            _state.value = BiometricAuthAvailable(
              biometricTypeName: _biometricTypeName,
              hasFaceId: _hasFaceId,
              hasFingerprint: _hasFingerprint,
            );
          }
        });
        break;

      case BiometricAuthErrorType.notEnrolled:
        _state.value = const BiometricAuthNotAvailable(
          reason:
              'No biometrics enrolled. Please set up biometric authentication in Settings.',
        );
        break;

      case BiometricAuthErrorType.notAvailable:
        _state.value = BiometricAuthNotAvailable(
          reason: errorMessage,
        );
        break;

      default:
        final canRetry = errorType == BiometricAuthErrorType.timeout ||
            errorType == BiometricAuthErrorType.unknown;
        _state.value = BiometricAuthFailure(
          errorMessage: errorMessage,
          errorType: errorType,
          canRetry: canRetry,
        );
        break;
    }

    debugPrint('🔐 BiometricAuthController: ❌ $errorMessage');
  }

  /// Reset state to idle
  void reset() {
    _state.value = const BiometricAuthIdle();
  }

  /// Reset state to available (after error)
  void resetToAvailable() {
    _state.value = BiometricAuthAvailable(
      biometricTypeName: _biometricTypeName,
      hasFaceId: _hasFaceId,
      hasFingerprint: _hasFingerprint,
    );
  }

  /// Cancel ongoing authentication
  Future<void> cancel() async {
    await _biometricService.stopAuthentication();
    _state.value = const BiometricAuthCancelled();
  }

  @override
  void onClose() {
    _biometricService.stopAuthentication();
    super.onClose();
  }
}
