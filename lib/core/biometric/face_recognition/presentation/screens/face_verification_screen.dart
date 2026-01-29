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
    });
    _startAutoVerification();
  }

  // 🔒 جمع إطارات متعددة لفحص الرمش
  final List<CameraImage> _collectedFrames = [];
  int _frameCollectionTarget = 15; // جمع 15 إطار (~1.5 ثانية)

  void _captureAndVerify() async {
    if (_isProcessing || _cameraController == null) return;

    setState(() => _isProcessing = true);
    _collectedFrames.clear();

    try {
      // 📸 جمع إطارات متعددة لفحص الرمش
      await _cameraController!.startImageStream((CameraImage image) async {
        if (_collectedFrames.length < _frameCollectionTarget) {
          _collectedFrames.add(image);
          print('📸 Collected frame ${_collectedFrames.length}/$_frameCollectionTarget');
        }
        
        if (_collectedFrames.length >= _frameCollectionTarget) {
          await _cameraController!.stopImageStream();
          
          if (mounted) {
            print('✅ All frames collected, starting multi-frame verification...');
            // إرسال جميع الإطارات للتحقق من الرمش
            context.read<FaceRecognitionBloc>().add(
                  StartMultiFrameVerification(
                    frames: List.from(_collectedFrames),
                    userId: widget.userId,
                  ),
                );
          }
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

                // Liveness Instructions
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
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
                          children: [
                            Icon(Icons.tips_and_updates,
                                color: Colors.amber.shade300, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Tips for best results:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildInstructionRow(
                            Icons.remove_red_eye, '👁️ Blink naturally during scan'),
                        const SizedBox(height: 6),
                        _buildInstructionRow(
                            Icons.block, '🚫 Use your LIVE face, NOT a photo'),
                        const SizedBox(height: 6),
                        _buildInstructionRow(
                            Icons.face, '📷 Look directly at the camera'),
                        const SizedBox(height: 6),
                        _buildInstructionRow(
                            Icons.light_mode, '💡 Ensure good lighting'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstructionRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
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
    final center = Offset(size.width / 2, size.height / 2);
    final ovalWidth = size.width * 0.72;
    final ovalHeight = size.height * 0.62;

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
