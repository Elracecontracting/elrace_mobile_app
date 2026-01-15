import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_in_bloc/check_in_bloc.dart';
import 'package:el_race/resources/app_colors.dart';

/// Face Verification screen for Check-in/Check-out
/// Uses enhanced face recognition with Liveness + Quality Gates
class CheckInFaceVerificationScreen extends StatefulWidget {
  final bool isCheckIn; // true = check-in, false = check-out

  const CheckInFaceVerificationScreen({
    Key? key,
    required this.isCheckIn,
  }) : super(key: key);

  @override
  State<CheckInFaceVerificationScreen> createState() =>
      _CheckInFaceVerificationScreenState();
}

class _CheckInFaceVerificationScreenState
    extends State<CheckInFaceVerificationScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  AnimationController? _pulseAnimationController;
  Animation<double>? _pulseAnimation;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _autoVerificationAttempted = false;
  bool _showTryAgainButton = false;
  String _statusMessage = 'Position your face in the frame';
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
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });

        // Auto-start verification after camera initializes
        _startAutoVerification();
      }
    } catch (e) {
      print('❌ Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'Camera initialization error';
          _showTryAgainButton = true;
        });
      }
    }
  }

  void _startAutoVerification() {
    if (_autoVerificationAttempted) return;

    setState(() {
      _isProcessing = true;
      _autoVerificationAttempted = true;
      _statusMessage = 'Verifying face...';
    });

    // Try to capture and verify automatically after 2 seconds for better face positioning
    _autoVerificationTimer = Timer(const Duration(seconds: 2), () {
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
      _statusMessage = 'Verifying face...';
    });
    _startAutoVerification();
  }

  Future<void> _captureAndVerify() async {
    if (!_isProcessing || _cameraController == null) return;

    try {
      // Capture multiple images for anti-spoofing check
      // This detects static photos/videos by checking for natural micro-movements
      setState(() {
        _statusMessage = 'Verifying...';
      });

      final List<String> imagePaths = [];

      // Capture 3 images with small delays to detect movement
      for (int i = 0; i < 3; i++) {
        final XFile imageFile = await _cameraController!.takePicture();
        imagePaths.add(imageFile.path);

        // Small delay between captures (200ms)
        if (i < 2) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      print('\n🎯 ===== CHECK-IN FACE VERIFICATION (ANTI-SPOOF) =====');
      print('📸 Captured ${imagePaths.length} images for verification');

      // Trigger face verification in BLoC with multiple images
      if (mounted) {
        context.read<CheckInBloc>().add(
              VerifyFaceForCheckInET(
                imagePath: imagePaths.first, // Main image for embedding
                additionalImagePaths: imagePaths, // All images for anti-spoof
              ),
            );
      }
    } catch (e) {
      print('❌ Error capturing image: $e');
      setState(() {
        _statusMessage = '❌ Image capture failed';
        _isProcessing = false;
        _showTryAgainButton = true;
      });
    }
  }

  @override
  void dispose() {
    _autoVerificationTimer?.cancel();
    _pulseAnimationController?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          widget.isCheckIn ? 'Check In' : 'Check Out',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: BlocListener<CheckInBloc, CheckInState>(
        listener: (context, state) {
          if (state is FaceVerificationSuccessST) {
            // Verification success - proceed with check-in
            setState(() {
              _statusMessage = '✅ Verification successful';
              _isProcessing = false;
            });

            // Delay to show success message, then trigger check-in
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                // Trigger actual check-in API
                context.read<CheckInBloc>().add(CheckInET());
              }
            });
          } else if (state is FaceVerificationFailedST) {
            setState(() {
              _statusMessage = '❌ ${state.reason}';
              _isProcessing = false;
              _showTryAgainButton = true;
            });
          } else if (state is FaceNotEnrolledST) {
            setState(() {
              _statusMessage = '⚠️ Face registration required first';
              _isProcessing = false;
              _showTryAgainButton = false;
            });

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).pop(false);
              }
            });
          } else if (state is CheckedInST) {
            // Check-in successful - close with success
            Navigator.of(context).pop(true);
          } else if (state is CheckInErrorST) {
            setState(() {
              _statusMessage = '❌ ${state.errorMessage}';
              _isProcessing = false;
              _showTryAgainButton = true;
            });
          }
        },
        child: Stack(
          children: [
            // Camera preview
            if (_isCameraInitialized && _cameraController != null)
              Center(
                child: AspectRatio(
                  aspectRatio: _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Face oval overlay with pulse animation
            if (_pulseAnimation != null)
              AnimatedBuilder(
                animation: _pulseAnimation!,
                builder: (context, child) {
                  return CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: FaceOvalPainter(
                      animationValue: _pulseAnimation!.value,
                      isProcessing: _isProcessing && !_showTryAgainButton,
                    ),
                  );
                },
              ),

            // Status message
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Capture/Retry button or Loader
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: _isProcessing && !_showTryAgainButton
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 12),
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
                        ],
                      )
                    : _showTryAgainButton
                        ? ElevatedButton.icon(
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
                              backgroundColor: AppColors.primaryColor,
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
                          )
                        : const SizedBox.shrink(),
              ),
            ),

            // Instructions
            Positioned(
              bottom: 140,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tips_and_updates,
                            color: Colors.amber.shade300, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Tips for best results:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.visibility, color: Colors.white70, size: 14),
                        SizedBox(width: 6),
                        Text('Keep eyes open',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11)),
                        SizedBox(width: 12),
                        Icon(Icons.face, color: Colors.white70, size: 14),
                        SizedBox(width: 6),
                        Text('Look at camera',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for face oval overlay with animated pulse - Enhanced UI/UX
class FaceOvalPainter extends CustomPainter {
  final double animationValue;
  final bool isProcessing;

  FaceOvalPainter({
    this.animationValue = 0.0,
    this.isProcessing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fixed oval dimensions - EXACTLY same size for ALL states
    final center = Offset(size.width / 2, size.height / 2 - 50);
    final ovalWidth = size.width * 0.72;
    final ovalHeight = size.height * 0.52;

    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // Color based on processing state
    final baseColor = isProcessing ? const Color(0xFF00E676) : Colors.white;
    final glowColor = isProcessing ? const Color(0xFF00E676) : Colors.white;

    // Draw outer glow effect - SAME for both states for visual consistency
    for (int i = 2; i >= 1; i--) {
      final glowOpacity = isProcessing
          ? 0.1 * i * (1 - animationValue * 0.3)
          : 0.08 * i; // Subtle glow for white too
      final glowPaint = Paint()
        ..color = glowColor.withOpacity(glowOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0 + (i * 3);

      canvas.drawOval(ovalRect, glowPaint);
    }

    // Main oval stroke - SAME thickness for both states
    final mainPaint = Paint()
      ..color = baseColor.withOpacity(0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    canvas.drawOval(ovalRect, mainPaint);

    // Animated pulsing rings OUTSIDE the main oval (not affecting its size)
    if (isProcessing && animationValue > 0) {
      // First pulse ring
      final pulse1Paint = Paint()
        ..color = glowColor.withOpacity(0.4 * (1 - animationValue))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      final pulse1Rect = Rect.fromCenter(
        center: center,
        width: ovalWidth + (20 * animationValue),
        height: ovalHeight + (20 * animationValue),
      );
      canvas.drawOval(pulse1Rect, pulse1Paint);

      // Second pulse ring (delayed effect)
      if (animationValue > 0.3) {
        final adjustedValue = (animationValue - 0.3) / 0.7;
        final pulse2Paint = Paint()
          ..color = glowColor.withOpacity(0.25 * (1 - adjustedValue))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        final pulse2Rect = Rect.fromCenter(
          center: center,
          width: ovalWidth + (35 * adjustedValue),
          height: ovalHeight + (35 * adjustedValue),
        );
        canvas.drawOval(pulse2Rect, pulse2Paint);
      }
    }

    // Enhanced corner markers with gradient effect
    final cornerPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final markerLength = 25.0;
    final cornerOffset = 2.0; // Slight offset from oval edge

    // Top-left corner
    canvas.drawLine(
      Offset(ovalRect.left - cornerOffset, ovalRect.top + markerLength),
      Offset(ovalRect.left - cornerOffset, ovalRect.top - cornerOffset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(ovalRect.left - cornerOffset, ovalRect.top - cornerOffset),
      Offset(ovalRect.left + markerLength, ovalRect.top - cornerOffset),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(ovalRect.right - markerLength, ovalRect.top - cornerOffset),
      Offset(ovalRect.right + cornerOffset, ovalRect.top - cornerOffset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(ovalRect.right + cornerOffset, ovalRect.top - cornerOffset),
      Offset(ovalRect.right + cornerOffset, ovalRect.top + markerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(ovalRect.left - cornerOffset, ovalRect.bottom - markerLength),
      Offset(ovalRect.left - cornerOffset, ovalRect.bottom + cornerOffset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(ovalRect.left - cornerOffset, ovalRect.bottom + cornerOffset),
      Offset(ovalRect.left + markerLength, ovalRect.bottom + cornerOffset),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(ovalRect.right - markerLength, ovalRect.bottom + cornerOffset),
      Offset(ovalRect.right + cornerOffset, ovalRect.bottom + cornerOffset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(ovalRect.right + cornerOffset, ovalRect.bottom - markerLength),
      Offset(ovalRect.right + cornerOffset, ovalRect.bottom + cornerOffset),
      cornerPaint,
    );

    // Add subtle scanning line effect when processing
    if (isProcessing) {
      final scanLineY = ovalRect.top + (ovalRect.height * animationValue);
      final scanLinePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            glowColor.withOpacity(0.6),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(
            Rect.fromLTWH(ovalRect.left, scanLineY - 2, ovalRect.width, 4))
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(
            ovalRect.left + 20, scanLineY - 1.5, ovalRect.width - 40, 3),
        scanLinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FaceOvalPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isProcessing != isProcessing;
  }
}
