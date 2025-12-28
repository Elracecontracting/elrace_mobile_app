/// Quick Start Example for Face Recognition System
/// Copy this code to get started quickly!

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/biometric/face_recognition/face_recognition_di.dart';
import 'core/biometric/face_recognition/presentation/bloc/face_recognition_bloc.dart';
import 'core/biometric/face_recognition/presentation/screens/face_registration_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Face Recognition System
  await FaceRecognitionDI.init();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Recognition Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String userId = 'user_12345'; // Your user ID

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Face Authentication')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.face, size: 100, color: Colors.blue),
            SizedBox(height: 32),
            
            // Register Face Button
            ElevatedButton.icon(
              onPressed: () => _navigateToRegistration(context),
              icon: Icon(Icons.person_add),
              label: Text('Register Face'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Verify Face Button
            ElevatedButton.icon(
              onPressed: () => _navigateToVerification(context),
              icon: Icon(Icons.verified_user),
              label: Text('Verify Face'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToRegistration(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (_) => FaceRecognitionDI.get<FaceRecognitionBloc>(),
          child: FaceRegistrationScreen(userId: userId),
        ),
      ),
    );
  }

  void _navigateToVerification(BuildContext context) {
    // Implement similar to registration
    // Create a FaceVerificationScreen (similar to FaceRegistrationScreen)
  }
}

/// =============================================================================
/// ALTERNATIVE: Simple Programmatic Usage (No UI)
/// =============================================================================

import 'package:camera/camera.dart';
import 'core/biometric/face_recognition/domain/usecases/register_face_usecase.dart';
import 'core/biometric/face_recognition/domain/usecases/verify_face_usecase.dart';

class FaceAuthService {
  final RegisterFaceUseCase _registerUseCase;
  final VerifyFaceUseCase _verifyUseCase;

  FaceAuthService()
      : _registerUseCase = FaceRecognitionDI.get<RegisterFaceUseCase>(),
        _verifyUseCase = FaceRecognitionDI.get<VerifyFaceUseCase>();

  /// Register a face
  Future<bool> registerFace(CameraImage image, String userId) async {
    final result = await _registerUseCase(
      image: image,
      userId: userId,
      label: 'primary',
    );

    return result.fold(
      (failure) {
        print('Registration failed: ${failure.message}');
        return false;
      },
      (embedding) {
        print('Face registered successfully!');
        return true;
      },
    );
  }

  /// Verify a face
  Future<bool> verifyFace(CameraImage image, String userId) async {
    final result = await _verifyUseCase(
      image: image,
      userId: userId,
    );

    return result.fold(
      (failure) {
        print('Verification failed: ${failure.message}');
        return false;
      },
      (verificationResult) {
        print('Verified: ${verificationResult.isVerified}');
        print('Confidence: ${(verificationResult.confidence * 100).toStringAsFixed(1)}%');
        return verificationResult.isVerified;
      },
    );
  }
}

/// =============================================================================
/// USAGE EXAMPLE
/// =============================================================================

void exampleUsage() async {
  // Initialize
  await FaceRecognitionDI.init();

  // Create service
  final faceAuth = FaceAuthService();

  // Assuming you have a CameraImage from camera stream
  CameraImage? currentFrame;

  // Register
  if (currentFrame != null) {
    bool success = await faceAuth.registerFace(currentFrame, 'user_123');
    if (success) {
      print('✅ Registration successful!');
    }
  }

  // Verify
  if (currentFrame != null) {
    bool verified = await faceAuth.verifyFace(currentFrame, 'user_123');
    if (verified) {
      print('✅ Access granted!');
    } else {
      print('❌ Access denied!');
    }
  }
}
