import 'dart:io';
import 'package:flutter/material.dart';
import 'package:el_race/core/biometric/ios/face_id_helper.dart';
import 'package:el_race/core/biometric/android/android_biometric_helper.dart';

/// Unified biometric helper that automatically chooses the right platform
/// iOS: Premium Face ID experience with Cupertino design
/// Android: Fast Material 3 biometric authentication
class UnifiedBiometricHelper {
  UnifiedBiometricHelper._();

  /// Check if biometric authentication is available
  static Future<bool> isBiometricAvailable() async {
    if (Platform.isIOS) {
      return await FaceIdHelper.isFaceIdAvailable();
    } else if (Platform.isAndroid) {
      return await AndroidBiometricHelper.isBiometricAvailable();
    }
    return false;
  }

  /// Authenticate for attendance (check-in/out)
  /// Platform-adaptive: Face ID on iOS, Fingerprint on Android
  static Future<bool> authenticateForAttendance(BuildContext context) async {
    if (Platform.isIOS) {
      return await FaceIdHelper.authenticateForAttendance(context);
    } else if (Platform.isAndroid) {
      return await AndroidBiometricHelper.authenticateForAttendance(context);
    }
    return false;
  }

  /// Authenticate for sensitive data access
  static Future<bool> authenticateForSensitiveData(BuildContext context) async {
    if (Platform.isIOS) {
      return await FaceIdHelper.authenticateForSensitiveData(context);
    } else if (Platform.isAndroid) {
      return await AndroidBiometricHelper.authenticateForSensitiveData(context);
    }
    return false;
  }

  /// Authenticate for payments
  static Future<bool> authenticateForPayment(BuildContext context) async {
    if (Platform.isIOS) {
      return await FaceIdHelper.authenticateForPayment(context);
    } else if (Platform.isAndroid) {
      return await AndroidBiometricHelper.authenticateForPayment(context);
    }
    return false;
  }

  /// Authenticate for profile changes
  static Future<bool> authenticateForProfileChange(BuildContext context) async {
    if (Platform.isIOS) {
      return await FaceIdHelper.authenticateForProfileChange(context);
    } else if (Platform.isAndroid) {
      return await AndroidBiometricHelper.authenticateForProfileChange(context);
    }
    return false;
  }

  /// Generic authentication with custom messaging
  static Future<bool> authenticate({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String reason,
  }) async {
    if (Platform.isIOS) {
      return await FaceIdHelper.authenticate(
        context: context,
        title: title,
        subtitle: subtitle,
        reason: reason,
      );
    } else if (Platform.isAndroid) {
      return await AndroidBiometricHelper.authenticate(
        context: context,
        title: title,
        subtitle: subtitle,
        reason: reason,
      );
    }
    return false;
  }
}
