import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:el_race/core/biometric/face_recognition/face_recognition_di.dart';
import 'package:el_race/core/biometric/face_recognition/data/services/face_embedding_storage_service.dart';
import 'package:el_race/core/biometric/face_recognition/presentation/screens/face_registration_screen.dart';
import 'package:el_race/core/biometric/face_recognition/presentation/screens/face_verification_screen.dart';
import 'package:el_race/core/biometric/face_recognition/presentation/bloc/face_recognition_bloc.dart';

/// NEW: Helper class for Face Recognition authentication throughout the app
///
/// This replaces the old BiometricAuthHelper with Face Recognition technology
/// instead of local_auth (fingerprint/Face ID)
class FaceRecognitionHelper {
  FaceRecognitionHelper._();

  /// Register user's face for authentication
  /// Call this during user onboarding or settings
  static Future<bool> registerFace(
    BuildContext context, {
    required String userId,
    String title = 'Register Your Face',
    String subtitle = 'Look at the camera to register your identity',
  }) async {
    try {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => FaceRecognitionDI.get<FaceRecognitionBloc>(),
            child: FaceRegistrationScreen(
              userId: userId,
              title: title,
              subtitle: subtitle,
            ),
          ),
        ),
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Face registration failed: $e');
      return false;
    }
  }

  /// Authenticate for check-in/check-out using face recognition
  static Future<bool> authenticateForAttendance(
    BuildContext context, {
    required String userId,
  }) async {
    return await _showFaceVerification(
      context,
      userId: userId,
      title: 'Verify Your Identity',
      subtitle: 'Look at the camera to record your attendance',
    );
  }

  /// Authenticate for secure actions using face recognition
  static Future<bool> authenticateForSecureAction(
    BuildContext context, {
    required String userId,
    required String title,
    required String subtitle,
  }) async {
    return await _showFaceVerification(
      context,
      userId: userId,
      title: title,
      subtitle: subtitle,
    );
  }

  /// Authenticate for viewing sensitive data using face recognition
  static Future<bool> authenticateForSensitiveData(
    BuildContext context, {
    required String userId,
  }) async {
    return await _showFaceVerification(
      context,
      userId: userId,
      title: 'Unlock Sensitive Data',
      subtitle: 'Look at the camera to view protected information',
    );
  }

  /// Authenticate for payment using face recognition
  static Future<bool> authenticateForPayment(
    BuildContext context, {
    required String userId,
  }) async {
    return await _showFaceVerification(
      context,
      userId: userId,
      title: 'Authorize Payment',
      subtitle: 'Verify your identity to complete the transaction',
    );
  }

  /// Generic face authentication with custom parameters
  static Future<bool> authenticate({
    required BuildContext context,
    required String userId,
    required String title,
    required String subtitle,
  }) async {
    return await _showFaceVerification(
      context,
      userId: userId,
      title: title,
      subtitle: subtitle,
    );
  }

  /// Check if user has registered face
  static Future<bool> hasFaceRegistered(String userId) async {
    try {
      final storageService =
          FaceRecognitionDI.get<FaceEmbeddingStorageService>();
      return await storageService.hasEmbeddings(userId);
    } catch (e) {
      debugPrint('Error checking face registration: $e');
      return false;
    }
  }

  /// Delete user's face data
  static Future<bool> deleteFaceData(String userId) async {
    try {
      final storageService =
          FaceRecognitionDI.get<FaceEmbeddingStorageService>();
      await storageService.deleteEmbeddings(userId);
      return true;
    } catch (e) {
      debugPrint('Error deleting face data: $e');
      return false;
    }
  }

  /// Internal: Show face verification screen
  static Future<bool> _showFaceVerification(
    BuildContext context, {
    required String userId,
    required String title,
    required String subtitle,
  }) async {
    try {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => FaceRecognitionDI.get<FaceRecognitionBloc>(),
            child: FaceVerificationScreen(
              userId: userId,
              title: title,
              subtitle: subtitle,
            ),
          ),
        ),
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Face verification failed: $e');
      return false;
    }
  }
}
