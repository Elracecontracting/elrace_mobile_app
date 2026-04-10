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

      // Debug: Print available data
      // debugPrint('🔍 UnifiedBiometricHelper: Getting user ID...');
      // debugPrint('  - uid: ${loginData.result?.data?.uid}');
      // debugPrint('  - username: ${loginData.result?.data?.username}');
      // debugPrint('  - emp_id: ${loginData.result?.data?.emp_id}');
      debugPrint(
          '  - emp_profile_id: ${loginData.result?.data?.emp_profile_id}');

      // Priority: emp_id > emp_profile_id > uid > username
      // Apply same null/empty/"null" checks as registration to ensure consistency
      final empId = loginData.result?.data?.emp_id;
      final empProfileId = loginData.result?.data?.emp_profile_id;
      final uid = loginData.result?.data?.uid?.toString();
      final username = loginData.result?.data?.username;

      String? userId;
      if (empId != null && empId.isNotEmpty && empId != 'null') {
        userId = empId;
        // debugPrint('✅ Selected emp_id: $userId');
      } else if (empProfileId != null && empProfileId.isNotEmpty && empProfileId != 'null') {
        userId = empProfileId;
        // debugPrint('✅ Selected emp_profile_id: $userId');
      } else if (uid != null && uid.isNotEmpty && uid != 'null') {
        userId = uid;
        // debugPrint('✅ Selected uid: $userId');
      } else if (username != null && username.isNotEmpty && username != 'null') {
        userId = username;
        // debugPrint('✅ Selected username: $userId');
      }

      if (userId == null || userId.isEmpty) {
        // debugPrint('❌ UnifiedBiometricHelper: No user ID found');
        // debugPrint('   Login data structure: ${loginData.result?.data}');
        return null;
      }

      return userId;
    } catch (e) {
      // debugPrint('❌ UnifiedBiometricHelper: Error getting user ID: $e');
      return null;
    }
  }

  /// Authenticate for attendance (check-in/out)
  /// Now uses Face Recognition instead of platform biometrics
  static Future<bool> authenticateForAttendance(BuildContext context) async {
    // print('\n📍 ===== UnifiedBiometricHelper.authenticateForAttendance =====');
    final userId = await _getCurrentUserId();
    // print('📍 Selected userId to pass: $userId');
    print(
        '====================================================================\n');

    if (userId == null) {
      // print('❌ authenticateForAttendance: userId is null, returning false');
      return false;
    }

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
