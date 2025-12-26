import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:el_race/core/services/biometric_auth_service.dart';
import 'package:el_race/core/biometric/ios/face_id_auth_controller.dart';
import 'package:el_race/core/biometric/ios/face_id_cupertino_sheet.dart';

/// iOS-specific Face ID helper
/// Premium authentication experience for iOS only
class FaceIdHelper {
  FaceIdHelper._();

  /// Initialize Face ID controller (call once at app start)
  static void initialize() {
    if (Platform.isIOS) {
      Get.lazyPut<FaceIdAuthController>(
        () => FaceIdAuthController(BiometricAuthService.instance),
      );
    }
  }

  /// Check if Face ID is available on this device
  static Future<bool> isFaceIdAvailable() async {
    if (!Platform.isIOS) return false;

    try {
      final controller = Get.find<FaceIdAuthController>();
      return await controller.isFaceIdAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Authenticate for attendance (check-in/out)
  /// Shows premium iOS Face ID sheet
  static Future<bool> authenticateForAttendance(BuildContext context) async {
    if (!Platform.isIOS) return false;

    return await showFaceIdCupertinoSheet(
      context: context,
      title: 'Confirm Attendance',
      subtitle: 'Use Face ID to verify check-in',
      reason: 'Authenticate to record your attendance',
    );
  }

  /// Authenticate for sensitive data access
  static Future<bool> authenticateForSensitiveData(BuildContext context) async {
    if (!Platform.isIOS) return false;

    return await showFaceIdCupertinoSheet(
      context: context,
      title: 'Verify Identity',
      subtitle: 'Use Face ID to access sensitive information',
      reason: 'Authenticate to view secure data',
    );
  }

  /// Authenticate for payments or financial actions
  static Future<bool> authenticateForPayment(BuildContext context) async {
    if (!Platform.isIOS) return false;

    return await showFaceIdCupertinoSheet(
      context: context,
      title: 'Confirm Payment',
      subtitle: 'Use Face ID to authorize this transaction',
      reason: 'Authenticate to complete payment',
    );
  }

  /// Authenticate for profile changes
  static Future<bool> authenticateForProfileChange(BuildContext context) async {
    if (!Platform.isIOS) return false;

    return await showFaceIdCupertinoSheet(
      context: context,
      title: 'Verify Identity',
      subtitle: 'Use Face ID to update your profile',
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
    if (!Platform.isIOS) return false;

    return await showFaceIdCupertinoSheet(
      context: context,
      title: title,
      subtitle: subtitle,
      reason: reason,
    );
  }
}
