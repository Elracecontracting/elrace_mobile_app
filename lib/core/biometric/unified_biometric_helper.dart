import 'package:flutter/material.dart';
import 'package:el_race/core/biometric/face_recognition_helper.dart';
import 'package:el_race/core/utils/shared_pref.dart';

/// Unified biometric helper - UPDATED to use Face Recognition
///
/// Previously used platform-specific biometrics (Face ID/Fingerprint)
/// Now uses advanced Face Recognition technology on all platforms
class UnifiedBiometricHelper {
  UnifiedBiometricHelper._();

  /// Check if face recognition is available
  /// Note: Requires user to register their face first
  static Future<bool> isBiometricAvailable() async {
    // Face recognition is available if camera is available
    // In production, you should check camera permissions
    return true; // Face recognition works on all devices with cameras
  }

  /// Helper to get current user ID
  static Future<String?> _getCurrentUserId() async {
    try {
      // Get user ID from SharedPreferences
      final loginData = SharedPref.getLoginData();
      final userId = loginData.result?.data?.uid?.toString() ??
          loginData.result?.data?.username ??
          loginData.result?.data?.emp_id;

      if (userId == null || userId.isEmpty) {
        debugPrint('❌ UnifiedBiometricHelper: No user ID found');
        return null;
      }

      debugPrint('✅ UnifiedBiometricHelper: User ID = $userId');
      return userId;
    } catch (e) {
      debugPrint('❌ UnifiedBiometricHelper: Error getting user ID: $e');
      return null;
    }
  }

  /// Authenticate for attendance (check-in/out)
  /// Now uses Face Recognition instead of platform biometrics
  static Future<bool> authenticateForAttendance(BuildContext context) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return false;

    return await FaceRecognitionHelper.authenticateForAttendance(
      context,
      userId: userId,
    );
  }

  /// Authenticate for sensitive data access
  static Future<bool> authenticateForSensitiveData(BuildContext context) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return false;

    return await FaceRecognitionHelper.authenticateForSensitiveData(
      context,
      userId: userId,
    );
  }

  /// Authenticate for payments
  static Future<bool> authenticateForPayment(BuildContext context) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return false;

    return await FaceRecognitionHelper.authenticateForPayment(
      context,
      userId: userId,
    );
  }

  /// Authenticate for profile changes
  static Future<bool> authenticateForProfileChange(BuildContext context) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return false;

    return await FaceRecognitionHelper.authenticateForSecureAction(
      context,
      userId: userId,
      title: 'Verify Identity',
      subtitle: 'Confirm your identity to change profile settings',
    );
  }

  /// Generic authentication with custom messaging
  static Future<bool> authenticate({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String reason,
  }) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return false;

    return await FaceRecognitionHelper.authenticate(
      context: context,
      userId: userId,
      title: title,
      subtitle: subtitle,
    );
  }
}
