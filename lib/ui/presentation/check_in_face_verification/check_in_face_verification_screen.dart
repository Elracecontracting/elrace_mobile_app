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
  String _statusMessage = 'ضع وجهك في الإطار';
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
          _statusMessage = 'خطأ في تشغيل الكاميرا';
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
      _statusMessage = 'جاري التحقق من الوجه...';
    });

    // Try to capture and verify automatically for 1 second
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
      _statusMessage = 'جاري التحقق من الوجه...';
    });
    _startAutoVerification();
  }

  Future<void> _captureAndVerify() async {
    if (!_isProcessing || _cameraController == null) return;

    try {
      // Capture image
      final XFile imageFile = await _cameraController!.takePicture();

      print('\n🎯 ===== CHECK-IN FACE VERIFICATION =====');
      print('📸 Image captured: ${imageFile.path}');

      // Trigger face verification in BLoC
      if (mounted) {
        context.read<CheckInBloc>().add(
              VerifyFaceForCheckInET(imagePath: imageFile.path),
            );
      }
    } catch (e) {
      print('❌ Error capturing image: $e');
      setState(() {
        _statusMessage = '❌ خطأ في التقاط الصورة';
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
          widget.isCheckIn ? 'تسجيل حضور' : 'تسجيل انصراف',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: BlocListener<CheckInBloc, CheckInState>(
        listener: (context, state) {
          if (state is FaceVerificationSuccessST) {
            // Verification success - proceed with check-in
            setState(() {
              _statusMessage = '✅ تم التحقق بنجاح';
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
              _statusMessage = '⚠️ يجب تسجيل الوجه أولاً';
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
                              'جاري التحقق...',
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
                              'حاول مرة أخرى',
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
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.isCheckIn ? 'لتسجيل الحضور:' : 'لتسجيل الانصراف:',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '• ضع وجهك داخل الإطار البيضاوي\n• انتظر حتى يتم التحقق تلقائياً',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
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
      center: Offset(size.width / 2, size.height / 2 - 50),
      width: size.width * 0.7,
      height: size.height * 0.5,
    );

    canvas.drawOval(ovalRect, paint);

    // Animated pulsing effect when processing
    if (isProcessing && animationValue > 0) {
      final pulsePaint = Paint()
        ..color = baseColor.withOpacity(0.3 * (1 - animationValue))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final pulseRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2 - 50),
        width: size.width * 0.7 * (1 + animationValue * 0.1),
        height: size.height * 0.5 * (1 + animationValue * 0.1),
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
