import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:el_race/core/services/biometric_auth_service.dart';
import 'package:el_race/core/biometric/android/android_biometric_controller.dart';
import 'package:el_race/core/biometric/android/android_biometric_sheet.dart';

/// Android-specific biometric helper
/// Fast, modern Material 3 experience for Android only
class AndroidBiometricHelper {
  AndroidBiometricHelper._();

  /// Initialize Android biometric controller (call once at app start)
  static void initialize() {
    if (Platform.isAndroid) {
      Get.lazyPut<AndroidBiometricController>(
        () => AndroidBiometricController(BiometricAuthService.instance),
      );
    }
  }

  /// Check if biometric authentication is available on this device
  static Future<bool> isBiometricAvailable() async {
    if (!Platform.isAndroid) return false;

    try {
      final controller = Get.find<AndroidBiometricController>();
      return await controller.isBiometricAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Authenticate for attendance (check-in/out)
  /// Shows fast Material 3 biometric sheet
  static Future<bool> authenticateForAttendance(BuildContext context) async {
    if (!Platform.isAndroid) return false;

    return await showAndroidBiometricSheet(
      context: context,
      title: 'Verify Attendance',
      subtitle: 'Authenticate to record check-in',
      reason: 'Authenticate to record your attendance',
    );
  }

  /// Authenticate for sensitive data access
  static Future<bool> authenticateForSensitiveData(BuildContext context) async {
    if (!Platform.isAndroid) return false;

    return await showAndroidBiometricSheet(
      context: context,
      title: 'Verify Identity',
      subtitle: 'Authenticate to view sensitive information',
      reason: 'Authenticate to access secure data',
    );
  }

  /// Authenticate for payments or financial actions
  static Future<bool> authenticateForPayment(BuildContext context) async {
    if (!Platform.isAndroid) return false;

    return await showAndroidBiometricSheet(
      context: context,
      title: 'Confirm Payment',
      subtitle: 'Authenticate to authorize transaction',
      reason: 'Authenticate to complete payment',
    );
  }

  /// Authenticate for profile changes
  static Future<bool> authenticateForProfileChange(BuildContext context) async {
    if (!Platform.isAndroid) return false;

    return await showAndroidBiometricSheet(
      context: context,
      title: 'Verify Identity',
      subtitle: 'Authenticate to update profile',
      reason: 'Authenticate to modify your information',
    );
  }

  /// Generic authentication with custom messaging
  static Future<bool> authenticate({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String reason,
  }) async {
    if (!Platform.isAndroid) return false;

    return await showAndroidBiometricSheet(
      context: context,
      title: title,
      subtitle: subtitle,
      reason: reason,
    );
  }
}
