import 'package:flutter/material.dart';
import 'package:el_race/core/biometric/face_recognition_helper.dart';
import 'package:el_race/core/services/user_service.dart'; // Assuming you have user service

/// Helper class for easy biometric authentication throughout the app
/// UPDATED: Now uses Face Recognition instead of local_auth
///
/// Provides static methods for common authentication scenarios.
class BiometricAuthHelper {
  BiometricAuthHelper._();

  /// Show face authentication for check-in/check-out
  static Future<bool> authenticateForAttendance(BuildContext context) async {
    // Get current user ID from your user service
    final userId = await _getCurrentUserId();
    if (userId == null) return false;

    return await FaceRecognitionHelper.authenticateForAttendance(
      context,
      userId: userId,
    );
  }

  /// Show face authentication for secure actions
  static Future<bool> authenticateForSecureAction(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return false;

    return await FaceRecognitionHelper.authenticateForSecureAction(
      context,
      userId: userId,
      title: title,
      subtitle: subtitle,
    );
  }

  /// Show face authentication for viewing sensitive data
  static Future<bool> authenticateForSensitiveData(BuildContext context) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return false;

    return await FaceRecognitionHelper.authenticateForSensitiveData(
      context,
      userId: userId,
    );
  }

  /// Show face authentication with custom parameters
  static Future<bool> authenticate({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String reason,
    bool biometricOnly = true, // Kept for compatibility
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

  /// Register user's face for authentication
  /// Call this during onboarding or in settings
  static Future<bool> registerFace(BuildContext context) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return false;

    return await FaceRecognitionHelper.registerFace(
      context,
      userId: userId,
    );
  }

  /// Check if user has registered their face
  static Future<bool> hasFaceRegistered() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return false;

    return await FaceRecognitionHelper.hasFaceRegistered(userId);
  }

  /// Helper to get current user ID
  /// TODO: Replace with your actual user service logic
  static Future<String?> _getCurrentUserId() async {
    try {
      // Replace this with your actual user service
      // Example: return await UserService.instance.getCurrentUserId();
      // For now, return a placeholder
      return 'current_user_id'; // TODO: Implement actual user ID retrieval
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return null;
    }
  }
}
