import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data' show BytesBuilder;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:el_race/core/biometric/face_recognition/presentation/bloc/face_recognition_bloc.dart';
import 'package:el_race/core/biometric/face_recognition/presentation/bloc/face_recognition_event.dart';
import 'package:el_race/core/biometric/face_recognition/presentation/bloc/face_recognition_state.dart';
import 'package:el_race/core/biometric/face_recognition/data/services/liveness_service.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_in_bloc/check_in_bloc.dart';
import 'package:el_race/resources/app_colors.dart';

/// Face Verification screen for Check-in/Check-out
/// Professional guided UI: blink once + slight head movement
class CheckInFaceVerificationScreen extends StatefulWidget {
  final bool isCheckIn;
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
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  AnimationController? _pulseAnimationController;
  Animation<double>? _pulseAnimation;
  AnimationController? _successAnimController;
  Animation<double>? _successScaleAnim;

  bool _isProcessing = false;
  bool _permissionDenied = false;
  bool _showTryAgainButton = false;
  bool _verificationSuccess = false;
  bool _livenessStarted = false;
  bool _isSubmitting = false;
  Timer? _verificationTimeoutTimer;
  String _errorMessage = '';

  // Real-time liveness tracking
  final SimpleLivenessTracker _livenessTracker = SimpleLivenessTracker();
  FaceDetector? _livenessDetector;
  final List<CameraImage> _collectedFrames = [];
  bool _isStreamingForLiveness = false;
  int _frameSkipCounter = 0;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    print('\n🎬 ===== CHECK-IN FACE VERIFICATION (SIMPLE LIVENESS) =====');
    print('📱 Mode: ${widget.isCheckIn ? "CHECK-IN" : "CHECK-OUT"}');
    print('👤 User ID: ${widget.userId}');

    _initializeAnimations();
    _initializeLivenessDetector();
    _initializeCamera();
  }

  void _initializeAnimations() {
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseAnimationController!, curve: Curves.easeInOut),
    );

    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successAnimController!, curve: Curves.elasticOut),
    );
  }

  void _initializeLivenessDetector() {
    _livenessDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableClassification: true,
        enableTracking: false,
        enableLandmarks: false,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.15,
      ),
    );
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() { _permissionDenied = true; _isProcessing = false; });
      _showError('Camera permission is required');
      return;
    }

    setState(() => _permissionDenied = false);
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    context.read<FaceRecognitionBloc>().add(InitializeCamera(frontCamera));
  }

  void _startLivenessTracking() {
    if (_isStreamingForLiveness || _cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() {
      _livenessStarted = true;
      _isProcessing = true;
      _isStreamingForLiveness = true;
    });

    _livenessTracker.reset();
    _collectedFrames.clear();
    _frameSkipCounter = 0;

    _verificationTimeoutTimer?.cancel();
    _verificationTimeoutTimer = Timer(const Duration(seconds: 25), () {
      if (mounted && !_verificationSuccess && !_isSubmitting) {
        _stopLivenessStream();
        setState(() {
          _isProcessing = false;
          _showTryAgainButton = true;
          _errorMessage = 'Timeout. Please try again.';
        });
      }
    });

    try {
      _cameraController!.startImageStream((CameraImage image) {
        if (!_isStreamingForLiveness || _isSubmitting) return;

        _frameSkipCounter++;
        if (_frameSkipCounter % 3 != 0) return;

        if (_collectedFrames.length < 25) {
          _collectedFrames.add(image);
        }

        if (!_isDetecting) {
          _isDetecting = true;
          _processFrameForLiveness(image);
        }
      });
    } catch (e) {
      print('❌ Error starting liveness stream: $e');
      setState(() {
        _isProcessing = false;
        _showTryAgainButton = true;
        _errorMessage = 'Camera error';
      });
    }
  }

  Future<void> _processFrameForLiveness(CameraImage image) async {
    if (!mounted || _livenessDetector == null) {
      _isDetecting = false;
      return;
    }

    try {
      final allBytes = BytesBuilder();
      for (final plane in image.planes) {
        allBytes.add(plane.bytes);
      }
      final bytes = allBytes.toBytes();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final faces = await _livenessDetector!.processImage(inputImage);

      if (faces.isNotEmpty) {
        _livenessTracker.addFace(faces.first);
      } else {
        _livenessTracker.noFace();
      }

      if (mounted) {
        setState(() {});

        if (_livenessTracker.isComplete && !_isSubmitting) {
          print('✅ SimpleLiveness COMPLETE for check-in!');
          _onLivenessComplete();
        }
      }
    } catch (e) {
      // Silently continue
    }

    _isDetecting = false;
  }

  void _onLivenessComplete() {
    _isSubmitting = true;
    _verificationTimeoutTimer?.cancel();

    Future.delayed(const Duration(milliseconds: 300), () async {
      _stopLivenessStream();

      if (!mounted || _collectedFrames.isEmpty) return;

      setState(() => _isSubmitting = true);

      print('🔍 Triggering face verification for check-in...');
      context.read<FaceRecognitionBloc>().add(
        StartMultiFrameVerification(
          frames: _collectedFrames,
          userId: widget.userId,
        ),
      );
    });
  }

  void _stopLivenessStream() {
    _isStreamingForLiveness = false;
    try {
      _cameraController?.stopImageStream();
    } catch (e) {
      print('⚠️ Error stopping stream: $e');
    }
  }

  void _resetForRetry() {
    _stopLivenessStream();
    _livenessTracker.reset();
    _collectedFrames.clear();
    setState(() {
      _isProcessing = false;
      _showTryAgainButton = false;
      _livenessStarted = false;
      _isSubmitting = false;
      _errorMessage = '';
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _startLivenessTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cameraSize = screenWidth * 0.62;
    final livenessStatus = _livenessTracker.status;

    return WillPopScope(
      onWillPop: () async => !_isProcessing || _verificationSuccess,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: MultiBlocListener(
          listeners: [
            BlocListener<FaceRecognitionBloc, FaceRecognitionState>(
              listener: (context, state) {
                print('🔔 FaceRecognitionBloc State: ${state.runtimeType}');

                if (state is FaceRecognitionCameraReady) {
                  setState(() => _cameraController = state.cameraController);
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) _startLivenessTracking();
                  });
                } else if (state is FaceVerificationResult) {
                  _verificationTimeoutTimer?.cancel();
                  if (state.isVerified) {
                    print('✅ Face verification SUCCESS!');
                    setState(() {
                      _verificationSuccess = true;
                      _isProcessing = false;
                    });
                    _successAnimController?.forward();

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
                      _isSubmitting = false;
                      _showTryAgainButton = true;
                      _errorMessage = state.message;
                    });
                  }
                } else if (state is FaceRecognitionError) {
                  print('❌ Error: ${state.message}');
                  _verificationTimeoutTimer?.cancel();
                  setState(() {
                    _isProcessing = false;
                    _isSubmitting = false;
                    _showTryAgainButton = true;
                    _errorMessage = state.message;
                  });
                }
              },
            ),
            BlocListener<CheckInBloc, CheckInState>(
              listener: (context, state) {
                print('🔔 CheckInBloc State: ${state.runtimeType}');

                if (state is CheckedInST) {
                  print('✅ Check-in API SUCCESS!');
                  Navigator.of(context).pop(true);
                } else if (state is CheckInErrorST) {
                  print('❌ Check-in API ERROR: ${state.errorMessage}');
                  setState(() {
                    _isProcessing = false;
                    _isSubmitting = false;
                    _showTryAgainButton = true;
                    _errorMessage = state.errorMessage;
                  });
                } else if (state is CheckInBlockedST) {
                  final timeStr =
                      '${state.currentDubaiTime.hour.toString().padLeft(2, '0')}:${state.currentDubaiTime.minute.toString().padLeft(2, '0')}';
                  setState(() {
                    _isProcessing = false;
                    _showTryAgainButton = false;
                  });
                  _showError('Check-in not available after 11:59 AM. Current: $timeStr');
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
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _verificationSuccess || _isProcessing
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close, color: AppColors.primaryColor, size: 20),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 36),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Title ──
                Text(
                  widget.isCheckIn ? 'Check-in Verification' : 'Check-out Verification',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getSubtitleText(livenessStatus),
                  style: TextStyle(color: AppColors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // ── Step Indicators ──
                if (_livenessStarted && !_verificationSuccess)
                  _buildStepIndicators(livenessStatus),

                const Spacer(flex: 1),

                // ── Camera Preview ──
                _buildCameraSection(cameraSize, livenessStatus),

                const SizedBox(height: 16),

                const Spacer(flex: 1),

                // ── Status Section ──
                _buildStatusSection(livenessStatus),

                const SizedBox(height: 20),

                // ── Tips ──
                if (!_showTryAgainButton && !_verificationSuccess && !_livenessStarted)
                  _buildTips(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSubtitleText(SimpleLivenessStatus status) {
    if (_verificationSuccess) return 'Verified successfully!';
    if (_isSubmitting) return 'Processing...';
    if (_showTryAgainButton) return 'Please try again';
    if (!_livenessStarted) return 'Position your face in the circle';
    if (!status.faceVisible) return 'Face not detected';
    if (!status.blinksComplete) return 'Blink your eyes';
    if (!status.movementComplete) return 'Move your head slightly';
    return 'Great! Processing...';
  }

  Widget _buildStepIndicators(SimpleLivenessStatus status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(child: _buildStepCard(
            icon: Icons.visibility_outlined,
            title: 'Blink Once',
            subtitle: status.blinksComplete ? 'Done' : 'Blink now',
            isComplete: status.blinksComplete,
            isActive: !status.blinksComplete && status.faceVisible,
          )),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 24, height: 3,
            decoration: BoxDecoration(
              color: status.blinksComplete ? AppColors.green : AppColors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildStepCard(
            icon: Icons.swap_horiz_rounded,
            title: 'Move Head',
            subtitle: 'Slight movement',
            isComplete: status.movementComplete,
            isActive: status.blinksComplete && !status.movementComplete && status.faceVisible,
          )),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isComplete,
    required bool isActive,
  }) {
    final Color bgColor = isComplete
        ? AppColors.green.withOpacity(0.08)
        : isActive ? AppColors.primaryColor.withOpacity(0.08) : Colors.grey.withOpacity(0.05);
    final Color borderColor = isComplete
        ? AppColors.green.withOpacity(0.3)
        : isActive ? AppColors.primaryColor.withOpacity(0.25) : Colors.grey.withOpacity(0.1);
    final Color iconColor = isComplete
        ? AppColors.green
        : isActive ? AppColors.primaryColor : AppColors.grey.withOpacity(0.4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isComplete
                ? Icon(Icons.check_circle_rounded, key: const ValueKey('done'), color: AppColors.green, size: 28)
                : Icon(icon, key: const ValueKey('icon'), color: iconColor, size: 26),
          ),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(
            color: isComplete ? AppColors.green : (isActive ? AppColors.primaryColor : AppColors.grey),
            fontSize: 13, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 2),
          Text(
            isComplete ? 'Done ✓' : subtitle,
            style: TextStyle(
              color: isComplete ? AppColors.green.withOpacity(0.7) : AppColors.grey.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSection(double cameraSize, SimpleLivenessStatus status) {
    List<Color> borderGradient;
    if (_verificationSuccess) {
      borderGradient = [AppColors.green, AppColors.green.withOpacity(0.7)];
    } else if (_showTryAgainButton) {
      borderGradient = [Colors.red.withOpacity(0.7), Colors.red.withOpacity(0.4)];
    } else if (status.isComplete || _isSubmitting) {
      borderGradient = [AppColors.green, AppColors.green.withOpacity(0.6)];
    } else if (_livenessStarted && status.faceVisible) {
      borderGradient = [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.6)];
    } else {
      borderGradient = [AppColors.primaryColor.withOpacity(0.5), AppColors.primaryColor.withOpacity(0.2)];
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_livenessStarted && !_showTryAgainButton && !_verificationSuccess && _pulseAnimation != null)
            AnimatedBuilder(
              animation: _pulseAnimation!,
              builder: (context, child) {
                return Container(
                  width: cameraSize + 36 + (24 * _pulseAnimation!.value),
                  height: cameraSize + 36 + (24 * _pulseAnimation!.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (status.blinksComplete ? AppColors.green : AppColors.primaryColor)
                          .withOpacity(0.3 * (1 - _pulseAnimation!.value)),
                      width: 2.5,
                    ),
                  ),
                );
              },
            ),

          Container(
            width: cameraSize + 12,
            height: cameraSize + 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: borderGradient,
              ),
              boxShadow: [
                if (!_showTryAgainButton)
                  BoxShadow(color: borderGradient.first.withOpacity(0.25), blurRadius: 16, spreadRadius: 3),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.white),
              padding: const EdgeInsets.all(4),
              child: ClipOval(
                child: Stack(
                  children: [
                    SizedBox(
                      width: cameraSize, height: cameraSize,
                      child: _buildCameraContent(cameraSize),
                    ),
                    if (_livenessStarted && !_showTryAgainButton && !_verificationSuccess && _pulseAnimation != null)
                      AnimatedBuilder(
                        animation: _pulseAnimation!,
                        builder: (context, child) {
                          return Positioned(
                            top: _pulseAnimation!.value * cameraSize,
                            left: 0, right: 0,
                            child: Container(
                              height: 2.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppColors.primaryColor.withOpacity(0.6),
                                    AppColors.primaryColor.withOpacity(0.8),
                                    AppColors.primaryColor.withOpacity(0.6),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    if (_verificationSuccess && _successScaleAnim != null)
                      AnimatedBuilder(
                        animation: _successScaleAnim!,
                        builder: (context, child) {
                          return Container(
                            width: cameraSize, height: cameraSize,
                            color: AppColors.green.withOpacity(0.3 * _successScaleAnim!.value),
                            child: Center(
                              child: Transform.scale(
                                scale: _successScaleAnim!.value,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.green,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: AppColors.green.withOpacity(0.4), blurRadius: 20, spreadRadius: 4),
                                    ],
                                  ),
                                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                                ),
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
    );
  }

  Widget _buildStatusSection(SimpleLivenessStatus status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          if (_verificationSuccess) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.green, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Verification Successful!',
                    style: TextStyle(color: AppColors.green, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ] else if (_showTryAgainButton) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.orange.shade400, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _errorMessage.isNotEmpty ? _errorMessage : 'Face not detected',
                      style: TextStyle(color: Colors.orange.shade400, fontSize: 13, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _resetForRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Try Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ] else if (_isSubmitting) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Verifying...',
                  style: TextStyle(color: AppColors.primaryColor, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ] else if (_livenessStarted) ...[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _getSubtitleText(status),
                key: ValueKey(status.currentStep),
                style: TextStyle(
                  color: status.faceVisible ? AppColors.primaryColor : Colors.orange.shade400,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTips() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMinimalTip(Icons.lightbulb_outline, 'Good light'),
          const SizedBox(width: 20),
          _buildMinimalTip(Icons.face_outlined, 'Face forward'),
          const SizedBox(width: 20),
          _buildMinimalTip(Icons.visibility_outlined, 'Eyes open'),
        ],
      ),
    );
  }

  Widget _buildMinimalTip(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryColor.withOpacity(0.5), size: 18),
        ),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(color: AppColors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildCameraContent(double size) {
    if (_permissionDenied) {
      return Container(
        color: const Color(0xFFF5F7FA),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, color: AppColors.primaryColor.withOpacity(0.4), size: 36),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _initializeCamera,
              child: const Text('Enable Camera', style: TextStyle(color: AppColors.primaryColor)),
            ),
          ],
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        color: const Color(0xFFF5F7FA),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor, strokeWidth: 2),
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
      SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _stopLivenessStream();
    _verificationTimeoutTimer?.cancel();
    _pulseAnimationController?.dispose();
    _successAnimController?.dispose();
    _cameraController?.dispose();
    _livenessDetector?.close();
    super.dispose();
  }
}
