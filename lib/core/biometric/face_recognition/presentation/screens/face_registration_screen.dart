import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../bloc/face_recognition_bloc.dart';
import '../bloc/face_recognition_event.dart';
import '../bloc/face_recognition_state.dart';

/// Face Registration Screen - Same UI as Verification Screen
///
/// This screen registers user's face using the same modern UI
class FaceRegistrationScreen extends StatefulWidget {
  final String userId;
  final String title;
  final String subtitle;

  const FaceRegistrationScreen({
    super.key,
    required this.userId,
    this.title = 'Register Your Face',
    this.subtitle = 'Look at the camera to register your identity',
  });

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  AnimationController? _pulseAnimationController;
  Animation<double>? _pulseAnimation;
  bool _isProcessing = false;
  bool _isMandatory = false;
  bool _permissionDenied = false;
  bool _autoRegistrationAttempted = false;
  bool _showTryAgainButton = false;
  Timer? _autoRegistrationTimer;

  @override
  void initState() {
    super.initState();
    _checkIfMandatory();
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

  Future<void> _checkIfMandatory() async {
    // If title contains "Required", it's mandatory
    _isMandatory = widget.title.contains('Required');
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

    // Get available cameras
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    // Initialize camera via BLoC
    context.read<FaceRecognitionBloc>().add(InitializeCamera(frontCamera));
  }

  void _startAutoRegistration() {
    if (_autoRegistrationAttempted) return;

    setState(() {
      _isProcessing = true;
      _autoRegistrationAttempted = true;
    });

    // Start monitoring for face detection
    _monitorForFace();
  }

  void _monitorForFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() {
        _isProcessing = false;
        _showTryAgainButton = true;
      });
      return;
    }

    print('👀 Monitoring for face...');

    try {
      bool faceDetected = false;
      bool isMonitoring = true;

      await _cameraController!.startImageStream((CameraImage image) async {
        if (faceDetected || !isMonitoring) return;

        // Quick check: just verify we can process the image
        // We'll do full face detection in the registration step
        if (mounted && _isProcessing && !_showTryAgainButton) {
          faceDetected = true;
          isMonitoring = false;

          print('✅ Ready to capture, stopping monitor...');

          try {
            await _cameraController!.stopImageStream();
          } catch (e) {
            print('⚠️ Error stopping monitor stream: $e');
          }

          // Wait a moment then capture
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            _captureAndRegister();
          }
        }
      });
    } catch (e) {
      print('❌ Error monitoring for face: $e');
      setState(() {
        _isProcessing = false;
        _showTryAgainButton = true;
      });
    }
  }

  void _resetForRetry() {
    setState(() {
      _isProcessing = false;
      _autoRegistrationAttempted = false;
      _showTryAgainButton = false;
    });
    _startAutoRegistration();
  }

  void _captureAndRegister() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print('❌ Camera not ready');
      setState(() {
        _isProcessing = false;
        _showTryAgainButton = true;
      });
      return;
    }

    print('📸 Starting capture...');

    try {
      bool imageCaptured = false;

      // Start image stream
      await _cameraController!.startImageStream((CameraImage image) async {
        if (imageCaptured) return; // Prevent multiple captures
        imageCaptured = true;

        print('✅ Image captured, stopping stream...');

        // Stop stream
        try {
          await _cameraController!.stopImageStream();
        } catch (e) {
          print('⚠️ Error stopping stream: $e');
        }

        // Trigger registration
        if (mounted) {
          print('🔄 Triggering registration in BLoC...');
          context.read<FaceRecognitionBloc>().add(
                StartFaceRegistration(
                  image: image,
                  userId: widget.userId,
                  label: 'primary',
                ),
              );
        }
      });
    } catch (e) {
      print('❌ Error in capture: $e');
      setState(() {
        _isProcessing = false;
        _showTryAgainButton = true;
      });
      _showError('Failed to capture image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Allow back button if not mandatory, prevent if mandatory
        if (_isMandatory) {
          return false;
        }
        // Return false (cancel) when closing
        Navigator.of(context).pop(false);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocConsumer<FaceRecognitionBloc, FaceRecognitionState>(
          listener: (context, state) {
            if (state is FaceRecognitionCameraReady) {
              setState(() {
                _cameraController = state.cameraController;
              });
              // Start auto-registration after camera is ready
              _startAutoRegistration();
            } else if (state is FaceRegistrationSuccess) {
              // Registration successful - navigate back
              Navigator.of(context).pop(true);
            } else if (state is FaceRecognitionError) {
              setState(() {
                _isProcessing = false;
                _showTryAgainButton = true;
              });
            } else if (state is FaceRecognitionLoading) {
              setState(() => _isProcessing = true);
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: Column(
                children: [
                  // Header with close button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Close button (only if not mandatory)
                        if (!_isMandatory)
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 28,
                            ),
                          )
                        else
                          const SizedBox(width: 48), // Spacer
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
                                textAlign: TextAlign.center,
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
                        const SizedBox(width: 48), // Balance the close button
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
                              'Registering...',
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
            textAlign: TextAlign.center,
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

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  String _getStatusText(FaceRecognitionState state) {
    if (state is FaceRecognitionLoading) {
      return 'Registering your face...';
    } else if (_isProcessing && !_autoRegistrationAttempted) {
      return 'Looking for your face...';
    } else if (_isProcessing) {
      return 'Processing...';
    } else if (state is FaceRecognitionError) {
      return 'Registration failed. Please click "Try Again"\nThis step is required to continue.';
    } else if (state is FaceRegistrationSuccess) {
      return 'Registration successful!';
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
    _autoRegistrationTimer?.cancel();
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
    final baseColor = isProcessing ? Colors.greenAccent : Colors.white;

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

    final cornerPaint = Paint()
      ..color = baseColor.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final markerLength = 20.0;

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
