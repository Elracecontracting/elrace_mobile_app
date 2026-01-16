import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:el_race/core/biometric/face_recognition/face_recognition_di.dart';
import 'package:el_race/core/biometric/face_recognition/data/services/face_embedding_storage_service.dart';
import 'package:el_race/core/biometric/face_recognition/presentation/screens/face_registration_screen.dart';
import 'package:el_race/core/biometric/face_recognition/presentation/screens/face_verification_screen.dart';
import 'package:el_race/core/biometric/face_recognition/presentation/bloc/face_recognition_bloc.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_in_bloc/check_in_bloc.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_out_bloc/check_out_bloc.dart';
import 'package:el_race/utils/di.dart';
import 'package:el_race/core/utils/shared_pref.dart';

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
          ));
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate for check-in/check-out using face recognition
  /// Uses FaceRegistrationScreen in verification mode
  static Future<bool> authenticateForAttendance(
    BuildContext context, {
    required String userId,
  }) async {
    // Determine if check-in or check-out based on current state
    final isCheckedIn = await _isCurrentlyCheckedIn();
    final actionType = isCheckedIn ? 'Check Out' : 'Check In';

    try {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) =>
                    FaceRecognitionDI.get<FaceRecognitionBloc>(),
              ),
              BlocProvider(
                create: (context) => sl.get<CheckInBloc>(),
              ),
              BlocProvider(
                create: (context) => sl.get<CheckOutBloc>(),
              ),
            ],
            child: FaceRegistrationScreen(
              userId: userId,
              isVerification: true,
              title: 'Verify for $actionType',
              subtitle: 'Position your face to complete $actionType',
              onVerificationSuccess: () async {
                // Trigger check-in/out after verification based on current state
                if (context.mounted) {
                  final currentlyCheckedIn = await _isCurrentlyCheckedIn();
                  if (currentlyCheckedIn) {
                    // User is checked in → perform check-out
                    final checkInRecordId =
                        SharedPref().getPreferenceInt('checkInRecordIdBloc');
                    sl.get<CheckOutBloc>().add(
                        CheckOutET(checkInRecordId, isAutoCheckout: false));
                  } else {
                    // User is NOT checked in → perform check-in
                    sl.get<CheckInBloc>().add(CheckInET());
                  }
                }
              },
            ),
          ),
        ),
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Helper to check if user is currently checked in
  static Future<bool> _isCurrentlyCheckedIn() async {
    try {
      return SharedPref().getPreferenceBoolean('isCheckedIn');
    } catch (e) {
      debugPrint('Error checking check-in status: $e');
      return false;
    }
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

  /// Clear all stored face embeddings (for debugging/cleanup)
  /// Call this to reset face registration data and force re-registration
  static Future<void> clearAllFaceData() async {
    try {
      print('\n🗑️ Clearing all face embeddings...');
      final storageService =
          FaceRecognitionDI.get<FaceEmbeddingStorageService>();
      await storageService.deleteAllEmbeddings();

      // Also reset the registration flags so user will be prompted to register again
      SharedPref().setPreferencesBoolean('isFaceRegistered', false);
      SharedPref().setPreferencesBoolean('pendingFaceVerification', true);
      SharedPref().setPreferencesBoolean('isFaceRegistrationInProgress', false);

      print('✅ All face data cleared and flags reset\n');
    } catch (e) {
      print('❌ Error clearing face data: $e');
    }
  }
}
