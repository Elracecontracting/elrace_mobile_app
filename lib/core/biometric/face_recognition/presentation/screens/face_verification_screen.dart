import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../bloc/face_recognition_bloc.dart';
import '../bloc/face_recognition_event.dart';
import '../bloc/face_recognition_state.dart';

/// Face Verification Screen - Replaces old biometric authentication
///
/// This screen verifies user identity using face recognition
class FaceVerificationScreen extends StatefulWidget {
  final String userId;
  final String title;
  final String subtitle;

  const FaceVerificationScreen({
    Key? key,
    required this.userId,
    this.title = 'Verify Your Identity',
    this.subtitle = 'Look at the camera to continue',
  }) : super(key: key);

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  CameraController? _cameraController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    context.read<FaceRecognitionBloc>().add(InitializeCamera(frontCamera));
  }

  void _captureAndVerify() async {
    if (_isProcessing || _cameraController == null) return;

    setState(() => _isProcessing = true);

    try {
      await _cameraController!.startImageStream((CameraImage image) async {
        await _cameraController!.stopImageStream();

        if (mounted) {
          context.read<FaceRecognitionBloc>().add(
                StartFaceVerification(
                  image: image,
                  userId: widget.userId,
                ),
              );
        }
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Failed to capture image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<FaceRecognitionBloc, FaceRecognitionState>(
        listener: (context, state) {
          if (state is FaceRecognitionCameraReady) {
            setState(() {
              _cameraController = state.cameraController;
              _isProcessing = false;
            });
            // Auto-capture after camera is ready
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _captureAndVerify();
            });
          } else if (state is FaceVerificationResult) {
            if (state.isVerified) {
              Navigator.of(context).pop(true);
            } else {
              setState(() => _isProcessing = false);
              // Show error but don't auto-retry, let user click Try Again
            }
          } else if (state is FaceRecognitionError) {
            setState(() => _isProcessing = false);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48), // Balance close button
                    ],
                  ),
                ),

                // Camera Preview
                Expanded(
                  child: _buildCameraPreview(state),
                ),

                // Status
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (_isProcessing)
                        const CircularProgressIndicator(color: Colors.blue)
                      else
                        const Icon(Icons.face, size: 48, color: Colors.blue),
                      const SizedBox(height: 16),
                      Text(
                        _getStatusText(state),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // Try Again button on error or failed verification
                      if ((state is FaceRecognitionError ||
                              (state is FaceVerificationResult &&
                                  !state.isVerified)) &&
                          !_isProcessing) ...[
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _captureAndVerify,
                          icon: const Icon(Icons.refresh),
                          label: const Text(
                            'Try Again',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCameraPreview(FaceRecognitionState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blue),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CameraPreview(_cameraController!),
    );
  }

  String _getStatusText(FaceRecognitionState state) {
    if (state is FaceRecognitionLoading) {
      return 'Verifying...';
    } else if (_isProcessing) {
      return 'Processing...';
    } else if (state is FaceRecognitionError) {
      return 'Error: ${state.message}';
    } else if (state is FaceVerificationResult && !state.isVerified) {
      return 'Verification Failed: ${state.message}';
    }
    return 'Position your face in the frame';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
