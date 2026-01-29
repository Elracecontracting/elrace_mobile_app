import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:el_race/core/biometric/face_recognition/presentation/bloc/face_recognition_bloc.dart';
import 'package:el_race/core/biometric/face_recognition/presentation/bloc/face_recognition_event.dart';
import 'package:el_race/core/biometric/face_recognition/presentation/bloc/face_recognition_state.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_in_bloc/check_in_bloc.dart';
import 'package:el_race/resources/app_colors.dart';

/// Face Verification screen for Check-in/Check-out
/// Uses SAME UI/UX as Face Registration Screen but for verification
class CheckInFaceVerificationScreen extends StatefulWidget {
  final bool isCheckIn; // true = check-in, false = check-out
  final String userId;

  const CheckInFaceVerificationScreen({
    Key? key,
    required this.isCheckIn,
    required this.userId,
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
  bool _isProcessing = false;
  bool _permissionDenied = false;
  bool _autoVerificationAttempted = false;
  bool _showTryAgainButton = false;
  bool _verificationSuccess = false;
  Timer? _autoVerificationTimer;
  Timer? _verificationTimeoutTimer;

  // Face detection for auto-retry
  FaceDetector? _faceDetector;
  bool _isMonitoringForFace = false;
  bool _faceCurrentlyVisible = false;

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
    _initializeCamera();
    _initializeFaceDetector();
  }

  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableClassification: false,
        enableTracking: false,
        enableLandmarks: false,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.15,
      ),
    );
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

    // Get available cameras
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    // Initialize camera via BLoC
    context.read<FaceRecognitionBloc>().add(InitializeCamera(frontCamera));
  }

  void _startAutoVerification() {
    if (_autoVerificationAttempted) return;

    setState(() {
      _isProcessing = true;
      _autoVerificationAttempted = true;
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

    print('👀 Monitoring for face (verification)...');

    try {
      bool faceDetected = false;
      bool isMonitoring = true;

      await _cameraController!.startImageStream((CameraImage image) async {
        if (faceDetected || !isMonitoring) return;

        // Quick check: just verify we can process the image
        if (mounted && _isProcessing && !_showTryAgainButton) {
          faceDetected = true;
          isMonitoring = false;

          await _cameraController!.stopImageStream();

          // Small delay to stabilize
          await Future.delayed(const Duration(milliseconds: 300));

          if (mounted) {
            _captureAndVerify();
          }
        }
      });
    } catch (e) {
      print('❌ Error monitoring face: $e');
      setState(() {
        _isProcessing = false;
        _showTryAgainButton = true;
      });
    }
  }

  Future<void> _captureAndVerify() async {
    if (!mounted || _cameraController == null) return;

    print('\n🔐 ===== FACE VERIFICATION FOR CHECK-IN =====');
    print('📸 Capturing frames for face verification...');

    // Cancel any existing timeout
    _verificationTimeoutTimer?.cancel();

    // Set timeout for verification (30 seconds)
    _verificationTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && _isProcessing && !_verificationSuccess) {
        print('⏱️ Verification timeout');
        setState(() {
          _isProcessing = false;
          _showTryAgainButton = true;
        });
        _showError('Verification timeout. Please try again.');
      }
    });

    try {
      int frameCount = 0;
      const int requiredFrames = 15; // 🆕 جمع 15 إطار لفحص الرمش (~1.5 ثانية)
      final List<CameraImage> capturedFrames = [];
      bool verificationTriggered = false;

      // Start image stream and collect multiple frames
      await _cameraController!.startImageStream((CameraImage image) async {
        if (verificationTriggered) return;

        frameCount++;

        // Collect frames with small intervals (every 3rd frame ~100ms apart)
        if (frameCount % 3 == 0 && capturedFrames.length < requiredFrames) {
          capturedFrames.add(image);
          print('📷 Captured frame ${capturedFrames.length}/$requiredFrames');
        }

        // Once we have enough frames, trigger verification
        if (capturedFrames.length >= requiredFrames && !verificationTriggered) {
          verificationTriggered = true;

          print(
              '✅ ${capturedFrames.length} frames captured, stopping stream...');

          // Stop stream
          try {
            await _cameraController!.stopImageStream();
          } catch (e) {
            print('⚠️ Error stopping stream: $e');
          }

          // 🆕 Trigger multi-frame verification with blink check
          if (mounted) {
            print('🎯 Starting MULTI-FRAME face verification with BLINK CHECK...');
            context.read<FaceRecognitionBloc>().add(
                  StartMultiFrameVerification(
                    frames: capturedFrames,
                    userId: widget.userId,
                  ),
                );
          }
        }
      });
    } catch (e) {
      print('❌ Error capturing/verifying: $e');
      setState(() {
        _isProcessing = false;
        _showTryAgainButton = true;
      });
      _showError('Failed to capture image. Please try again.');
    }
  }

  void _stopFaceMonitoring() {
    if (_isMonitoringForFace && _cameraController != null) {
      try {
        _cameraController!.stopImageStream();
      } catch (e) {
        print('⚠️ Error stopping image stream: $e');
      }
      _isMonitoringForFace = false;
    }
  }

  void _resetForRetry() {
    _stopFaceMonitoring();
    setState(() {
      _isProcessing = false;
      _autoVerificationAttempted = false;
      _showTryAgainButton = false;
      _faceCurrentlyVisible = false;
    });
    _startAutoVerification();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cameraSize = screenWidth * 0.65;

    return WillPopScope(
      onWillPop: () async => !_isProcessing || _verificationSuccess,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: MultiBlocListener(
          listeners: [
            // Listen to FaceRecognitionBloc for verification result
            BlocListener<FaceRecognitionBloc, FaceRecognitionState>(
              listener: (context, state) {
                print('🔔 FaceRecognitionBloc State: ${state.runtimeType}');

                if (state is FaceRecognitionCameraReady) {
                  setState(() {
                    _cameraController = state.cameraController;
                  });
                  _startAutoVerification();
                } else if (state is FaceVerificationResult) {
                  _verificationTimeoutTimer?.cancel();

                  if (state.isVerified) {
                    print('✅ Face verification SUCCESS!');
                    setState(() {
                      _verificationSuccess = true;
                      _isProcessing = false;
                    });

                    // Delay to show success, then trigger check-in
                    Future.delayed(const Duration(milliseconds: 800), () {
                      if (mounted) {
                        print('🎯 Triggering check-in API call...');
                        context.read<CheckInBloc>().add(CheckInET());
                      }
                    });
                  } else {
                    print('❌ Face verification FAILED');
                    setState(() {
                      _isProcessing = false;
                      _showTryAgainButton = true;
                    });
                    _showError(state.message);
                  }
                } else if (state is FaceRecognitionError) {
                  print('❌ Face verification ERROR: ${state.message}');
                  _verificationTimeoutTimer?.cancel();
                  setState(() {
                    _isProcessing = false;
                    _showTryAgainButton = true;
                  });
                  _showError(state.message);
                }
              },
            ),
            // Listen to CheckInBloc for check-in result
            BlocListener<CheckInBloc, CheckInState>(
              listener: (context, state) {
                print('🔔 CheckInBloc State: ${state.runtimeType}');

                if (state is CheckedInST) {
                  print('✅ Check-in API SUCCESS!');
                  // Success - close with true
                  Navigator.of(context).pop(true);
                } else if (state is CheckInErrorST) {
                  print('❌ Check-in API ERROR: ${state.errorMessage}');
                  setState(() {
                    _isProcessing = false;
                    _showTryAgainButton = true;
                  });
                  _showError(state.errorMessage);
                } else if (state is CheckInBlockedST) {
                  print('⏰ Check-in BLOCKED: ${state.message}');
                  final timeStr =
                      '${state.currentDubaiTime.hour.toString().padLeft(2, '0')}:${state.currentDubaiTime.minute.toString().padLeft(2, '0')}';
                  setState(() {
                    _isProcessing = false;
                    _showTryAgainButton = false;
                  });
                  _showError(
                      'Check-in is not available after 11:59 AM. Current time: $timeStr');
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) Navigator.of(context).pop(false);
                  });
                }
              },
            ),
          ],
          child: SafeArea(
            child: Column(
              children: [
                // Minimal Header - Same as Registration Screen
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _verificationSuccess || _isProcessing
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.close,
                              color: AppColors.primaryColor, size: 22),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 38),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Title Section - Clean & Centered
                Text(
                  widget.isCheckIn ? 'Verify for Check In' : 'Verify for Check Out',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Position your face in the circle',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 15,
                  ),
                ),

                const Spacer(flex: 1),

                // Camera Preview - Same Style as Registration Screen
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing outer rings when processing
                      if (_isProcessing &&
                          !_showTryAgainButton &&
                          _pulseAnimation != null)
                        AnimatedBuilder(
                          animation: _pulseAnimation!,
                          builder: (context, child) {
                            return Container(
                              width: cameraSize + 40 + (30 * _pulseAnimation!.value),
                              height: cameraSize + 40 + (30 * _pulseAnimation!.value),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryColor.withOpacity(
                                      0.4 * (1 - _pulseAnimation!.value)),
                                  width: 3,
                                ),
                              ),
                            );
                          },
                        ),

                      // Second pulse ring (delayed)
                      if (_isProcessing &&
                          !_showTryAgainButton &&
                          _pulseAnimation != null)
                        AnimatedBuilder(
                          animation: _pulseAnimation!,
                          builder: (context, child) {
                            final delayedValue = (_pulseAnimation!.value + 0.5) % 1.0;
                            return Container(
                              width: cameraSize + 40 + (30 * delayedValue),
                              height: cameraSize + 40 + (30 * delayedValue),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryColor
                                      .withOpacity(0.3 * (1 - delayedValue)),
                                  width: 2,
                                ),
                              ),
                            );
                          },
                        ),

                      // Main camera container
                      Container(
                        width: cameraSize + 16,
                        height: cameraSize + 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _showTryAgainButton
                                ? _faceCurrentlyVisible
                                    ? [
                                        AppColors.green.withOpacity(0.8),
                                        AppColors.green.withOpacity(0.5)
                                      ]
                                    : [
                                        AppColors.red.withOpacity(0.8),
                                        AppColors.red.withOpacity(0.5)
                                      ]
                                : _isProcessing
                                    ? [
                                        AppColors.primaryColor,
                                        AppColors.primaryColor.withOpacity(0.7)
                                      ]
                                    : [
                                        AppColors.primaryColor.withOpacity(0.6),
                                        AppColors.primaryColor.withOpacity(0.3)
                                      ],
                          ),
                          boxShadow: _isProcessing && !_showTryAgainButton
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryColor.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ]
                              : null,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white,
                          ),
                          padding: const EdgeInsets.all(5),
                          child: ClipOval(
                            child: Stack(
                              children: [
                                SizedBox(
                                  width: cameraSize,
                                  height: cameraSize,
                                  child: _buildCameraContent(
                                      context.read<FaceRecognitionBloc>().state,
                                      cameraSize),
                                ),
                                // Scanning line effect
                                if (_isProcessing &&
                                    !_showTryAgainButton &&
                                    _pulseAnimation != null)
                                  AnimatedBuilder(
                                    animation: _pulseAnimation!,
                                    builder: (context, child) {
                                      return Positioned(
                                        top: _pulseAnimation!.value * cameraSize,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 3,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                AppColors.primaryColor.withOpacity(0.8),
                                                AppColors.primaryColor,
                                                AppColors.primaryColor.withOpacity(0.8),
                                                Colors.transparent,
                                              ],
                                              stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primaryColor.withOpacity(0.5),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Spacer(flex: 1),

                // Status Section - Minimal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      if (_verificationSuccess) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  color: AppColors.green, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                'Verification Successful',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_showTryAgainButton && !_faceCurrentlyVisible) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.orange.shade300, size: 18),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Face not detected',
                                  style: TextStyle(
                                    color: Colors.orange.shade300,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _resetForRetry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Try Again',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ] else if (_showTryAgainButton && _faceCurrentlyVisible) ...[
                        Text(
                          'Face detected! Retrying...',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else if (_isProcessing) ...[
                        Text(
                          'Scanning...',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Ready to scan',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Minimal Tips - Just Icons
                if (!_showTryAgainButton && !_verificationSuccess)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMinimalTip(Icons.lightbulb_outline, 'Good light'),
                        const SizedBox(width: 24),
                        _buildMinimalTip(Icons.face_outlined, 'Face forward'),
                        const SizedBox(width: 24),
                        _buildMinimalTip(Icons.visibility_outlined, 'Eyes open'),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalTip(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: AppColors.primaryColor.withOpacity(0.6), size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildCameraContent(FaceRecognitionState state, double size) {
    if (_permissionDenied) {
      return Container(
        color: AppColors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined,
                color: AppColors.primaryColor.withOpacity(0.4), size: 40),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _initializeCamera,
              child: Text(
                'Enable Camera',
                style: TextStyle(color: AppColors.primaryColor),
              ),
            ),
          ],
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        color: AppColors.white,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _cameraController!.value.previewSize?.height ?? size,
        height: _cameraController!.value.previewSize?.width ?? size,
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
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
    _stopFaceMonitoring();
    _autoVerificationTimer?.cancel();
    _verificationTimeoutTimer?.cancel();
    _pulseAnimationController?.dispose();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }
}
