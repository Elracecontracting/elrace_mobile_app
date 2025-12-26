import 'package:flutter/material.dart';
import 'package:el_race/core/biometric/widgets/biometric_auth_bottom_sheet.dart';

/// Helper class for easy biometric authentication throughout the app
///
/// Provides static methods for common authentication scenarios.
class BiometricAuthHelper {
  BiometricAuthHelper._();

  /// Show biometric authentication for check-in/check-out
  static Future<bool> authenticateForAttendance(BuildContext context) async {
    return await BiometricAuthBottomSheet.show(
      context: context,
      title: 'Verify Your Identity',
      subtitle: 'Authenticate to record your attendance',
      reason: 'Authenticate to check in',
    );
  }

  /// Show biometric authentication for secure actions
  static Future<bool> authenticateForSecureAction(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) async {
    return await BiometricAuthBottomSheet.show(
      context: context,
      title: title,
      subtitle: subtitle,
      reason: 'Authenticate to continue',
    );
  }

  /// Show biometric authentication for viewing sensitive data
  static Future<bool> authenticateForSensitiveData(BuildContext context) async {
    return await BiometricAuthBottomSheet.show(
      context: context,
      title: 'Unlock Sensitive Data',
      subtitle: 'Authenticate to view protected information',
      reason: 'Authenticate to access sensitive data',
    );
  }

  /// Show biometric authentication with custom parameters
  static Future<bool> authenticate({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String reason,
    bool biometricOnly = true,
  }) async {
    return await BiometricAuthBottomSheet.show(
      context: context,
      title: title,
      subtitle: subtitle,
      reason: reason,
      biometricOnly: biometricOnly,
    );
  }
}
