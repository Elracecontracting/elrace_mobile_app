import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
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
    super.key,
    required this.userId,
    this.title = 'Verify Your Identity',
    this.subtitle = 'Look at the camera to continue',
  });

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  AnimationController? _pulseAnimationController;
  Animation<double>? _pulseAnimation;
  bool _isProcessing = false;
  bool _permissionDenied = false;
  bool _autoVerificationAttempted = false;
  bool _showTryAgainButton = false;
  Timer? _autoVerificationTimer;

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
    _initializeCamera();
  }

  void _initializePulseAnimation() {
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseAnimationController!,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _permissionDenied = true;
        _isProcessing = false;
      });
      _showError('Camera permission is required to continue');
      return;
    }

    setState(() => _permissionDenied = false);

    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    context.read<FaceRecognitionBloc>().add(InitializeCamera(frontCamera));
  }

  void _startAutoVerification() {
    if (_autoVerificationAttempted) return;

    setState(() {
      _isProcessing = true;
      _autoVerificationAttempted = true;
    });

    // Try to capture and verify automatically after 1 second
    _autoVerificationTimer = Timer(const Duration(seconds: 1), () {
      if (mounted && _isProcessing && !_showTryAgainButton) {
        _captureAndVerify();
      }
    });
  }

  void _resetForRetry() {
    setState(() {
      _isProcessing = false;
      _autoVerificationAttempted = false;
      _showTryAgainButton = false;
    });
    _startAutoVerification();
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
            });
            // Start auto-verification after camera is ready
            _startAutoVerification();
          } else if (state is FaceVerificationResult) {
            if (state.isVerified) {
              Navigator.of(context).pop(true);
            } else {
              setState(() {
                _isProcessing = false;
                _showTryAgainButton = true;
              });
            }
          } else if (state is FaceRecognitionError) {
            setState(() {
              _isProcessing = false;
              _showTryAgainButton = true;
            });
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

                // Camera Preview with Face Oval Overlay
                Expanded(
                  child: Stack(
                    children: [
                      _buildCameraPreview(state),
                      // Face oval overlay with pulse animation
                      if (_pulseAnimation != null)
                        AnimatedBuilder(
                          animation: _pulseAnimation!,
                          builder: (context, child) {
                            return CustomPaint(
                              size: Size.infinite,
                              painter: FaceOvalPainter(
                                animationValue: _pulseAnimation!.value,
                                isProcessing:
                                    _isProcessing && !_showTryAgainButton,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),

                // Status and Try Again Button
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (_isProcessing && !_showTryAgainButton) ...[
                        const CircularProgressIndicator(
                          color: Colors.blue,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Verifying...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ] else if (_showTryAgainButton) ...[
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.orange),
                        const SizedBox(height: 16),
                        Text(
                          _getStatusText(state),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _resetForRetry,
                          icon: const Icon(Icons.refresh, size: 24),
                          label: const Text(
                            'Try Again',
                            style: TextStyle(
                              fontSize: 18,
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
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                        ),
                      ] else ...[
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
    if (_permissionDenied) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Camera permission is required',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _initializeCamera,
            child: const Text('Grant permission'),
          ),
        ],
      );
    }

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
    _autoVerificationTimer?.cancel();
    _pulseAnimationController?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }
}

/// Custom painter for face oval overlay with animated pulse
class FaceOvalPainter extends CustomPainter {
  final double animationValue;
  final bool isProcessing;

  FaceOvalPainter({
    this.animationValue = 0.0,
    this.isProcessing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Determine color based on processing state
    final baseColor = isProcessing ? Colors.greenAccent : Colors.white;

    // Main oval stroke
    final paint = Paint()
      ..color = baseColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.height * 0.6,
    );

    canvas.drawOval(ovalRect, paint);

    // Animated pulsing effect when processing
    if (isProcessing && animationValue > 0) {
      final pulsePaint = Paint()
        ..color = baseColor.withOpacity(0.3 * (1 - animationValue))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final pulseRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.7 * (1 + animationValue * 0.1),
        height: size.height * 0.6 * (1 + animationValue * 0.1),
      );

      canvas.drawOval(pulseRect, pulsePaint);
    }

    // Corner markers for better guidance
    final cornerPaint = Paint()
      ..color = baseColor.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final markerLength = 20.0;

    // Top-left corner
    canvas.drawLine(
      Offset(ovalRect.left, ovalRect.top + markerLength),
      Offset(ovalRect.left, ovalRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(ovalRect.left, ovalRect.top),
      Offset(ovalRect.left + markerLength, ovalRect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(ovalRect.right - markerLength, ovalRect.top),
      Offset(ovalRect.right, ovalRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(ovalRect.right, ovalRect.top),
      Offset(ovalRect.right, ovalRect.top + markerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(ovalRect.left, ovalRect.bottom - markerLength),
      Offset(ovalRect.left, ovalRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(ovalRect.left, ovalRect.bottom),
      Offset(ovalRect.left + markerLength, ovalRect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(ovalRect.right - markerLength, ovalRect.bottom),
      Offset(ovalRect.right, ovalRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(ovalRect.right, ovalRect.bottom - markerLength),
      Offset(ovalRect.right, ovalRect.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant FaceOvalPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isProcessing != isProcessing;
  }
}
