import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import '../../../../../resources/app_colors.dart';
import '../bloc/face_recognition_bloc.dart';
import '../bloc/face_recognition_event.dart';
import '../bloc/face_recognition_state.dart';

/// Face Registration/Verification Screen - Unified UI
///
/// This screen can be used for both registration and verification of user's face
/// Set isVerification=true to use for check-in/check-out verification
class FaceRegistrationScreen extends StatefulWidget {
  final String userId;
  final String title;
  final String subtitle;
  final bool isVerification; // If true, verify instead of register
  final VoidCallback?
      onVerificationSuccess; // Called when verification succeeds

  const FaceRegistrationScreen({
    super.key,
    required this.userId,
    this.title = 'Register Your Face',
    this.subtitle = 'Look at the camera to register your identity',
    this.isVerification = false,
    this.onVerificationSuccess,
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
  bool _registrationSuccess = false; // Allow pop after success
  Timer? _autoRegistrationTimer;
  Timer? _registrationTimeoutTimer; // Timeout to prevent infinite loading

  // Face detection for auto-retry
  FaceDetector? _faceDetector;
  bool _isMonitoringForFace = false;
  bool _faceCurrentlyVisible = false;

  // 🆕 متغيرات التحديات
  String _currentChallengeText = '';
  String _currentChallengeInstruction = '';
  int _currentChallengeIndex = 0;
  int _totalChallenges = 3;
  List<String> _completedChallenges = [];
  int _currentChallengeIcon = 0xe3fc; // visibility icon
  bool _showChallengeUI = false;
  String _challengeStatusMessage = '';

  @override
  void initState() {
    super.initState();

    // Debug: Print screen mode and userId
    print('\n🎬 ===== FACE REGISTRATION SCREEN INIT =====');
    print(
        '📱 Mode: ${widget.isVerification ? "VERIFICATION" : "REGISTRATION"}');
    print('👤 User ID: ${widget.userId}');
    print('📝 Title: ${widget.title}');
    print('==========================================\n');

    _checkIfMandatory();
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
    _stopFaceMonitoring();
    setState(() {
      _isProcessing = false;
      _autoRegistrationAttempted = false;
      _showTryAgainButton = false;
      _faceCurrentlyVisible = false;
    });
    _startAutoRegistration();
  }

  void _startFaceMonitoring() async {
    if (_isMonitoringForFace ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isMonitoringForFace = true);
    print('👁️ Starting face monitoring for auto-retry...');

    try {
      await _cameraController!.startImageStream((CameraImage image) async {
        if (!_isMonitoringForFace || !_showTryAgainButton) return;

        // Detect face
        final detected = await _detectFaceInImage(image);

        if (detected && !_faceCurrentlyVisible && mounted) {
          setState(() => _faceCurrentlyVisible = true);
          print('😊 Face detected! Auto-retrying...');

          // Stop monitoring and auto-retry
          _stopFaceMonitoring();
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            _resetForRetry();
          }
        }
      });
    } catch (e) {
      print('⚠️ Face monitoring error: $e');
    }
  }

  void _stopFaceMonitoring() async {
    if (!_isMonitoringForFace) return;

    _isMonitoringForFace = false;
    try {
      await _cameraController?.stopImageStream();
    } catch (e) {
      print('⚠️ Error stopping face monitoring: $e');
    }
  }

  Future<bool> _detectFaceInImage(CameraImage image) async {
    if (_faceDetector == null) return false;

    try {
      final allBytes = BytesBuilder();
      for (final Plane plane in image.planes) {
        allBytes.add(plane.bytes);
      }
      final bytes = allBytes.toBytes();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final faces = await _faceDetector!.processImage(inputImage);
      return faces.isNotEmpty;
    } catch (e) {
      return false;
    }
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

    print('📸 Starting capture with anti-spoofing...');

    // Cancel any existing timeout
    _registrationTimeoutTimer?.cancel();

    // Add timeout to prevent infinite loading
    _registrationTimeoutTimer = Timer(const Duration(seconds: 30), () {
      print('⏰ Registration timeout - forcing retry state');
      if (mounted && _isProcessing) {
        setState(() {
          _isProcessing = false;
          _showTryAgainButton = true;
        });
        // Try to stop the image stream if it's still running
        try {
          _cameraController?.stopImageStream();
        } catch (e) {
          print('⚠️ Error stopping stream on timeout: $e');
        }
      }
    });

    try {
      int frameCount = 0;
      const int requiredFrames = 20; // 🆕 جمع 20 إطار للتحديات (~3-4 ثانية)
      final List<CameraImage> capturedFrames = [];
      bool registrationTriggered = false;

      // Start image stream and collect multiple frames
      await _cameraController!.startImageStream((CameraImage image) async {
        if (registrationTriggered) return;

        frameCount++;

        // Collect frames with small intervals (every 3rd frame ~100ms apart)
        if (frameCount % 3 == 0 && capturedFrames.length < requiredFrames) {
          capturedFrames.add(image);
          print('📷 Captured frame ${capturedFrames.length}/$requiredFrames');
        }

        // Once we have enough frames, trigger registration
        if (capturedFrames.length >= requiredFrames && !registrationTriggered) {
          registrationTriggered = true;

          print(
              '✅ ${capturedFrames.length} frames captured, stopping stream...');

          // Stop stream
          try {
            await _cameraController!.stopImageStream();
          } catch (e) {
            print('⚠️ Error stopping stream: $e');
          }

          // Trigger registration/verification with multiple frames for anti-spoofing
          if (mounted) {
            if (widget.isVerification) {
              // 🆕 استخدام التحقق النشط مع التحديات المتعددة
              print('🔍 Triggering ACTIVE LIVENESS verification...');
              context.read<FaceRecognitionBloc>().add(
                    StartActiveLivenessVerification(
                      frames: capturedFrames,
                      userId: widget.userId,
                    ),
                  );
            } else {
              print('🔄 Triggering registration with anti-spoof check...');
              context.read<FaceRecognitionBloc>().add(
                    StartFaceRegistration(
                      image:
                          capturedFrames.last, // Use last frame for embedding
                      userId: widget.userId,
                      label: 'primary',
                      additionalImages: capturedFrames, // For anti-spoof
                    ),
                  );
            }
          }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final cameraSize = screenWidth * 0.65;

    return WillPopScope(
      onWillPop: () async {
        // Allow pop if registration was successful
        if (_registrationSuccess) return true;
        if (_isMandatory) return false;
        Navigator.of(context).pop(false);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: BlocConsumer<FaceRecognitionBloc, FaceRecognitionState>(
          listener: (context, state) {
            print('🎯 FaceRecognitionBloc state: ${state.runtimeType}');

            if (state is FaceRecognitionCameraReady) {
              setState(() => _cameraController = state.cameraController);
              _startAutoRegistration();
            } else if (state is FaceRegistrationSuccess) {
              print('✅ Face registration SUCCESS - navigating back...');
              _stopFaceMonitoring();
              _registrationTimeoutTimer?.cancel();

              // Mark success flag to allow WillPopScope to let us pop
              _registrationSuccess = true;

              // Mark as registered BEFORE popping
              SharedPref().setPreferencesBoolean('isFaceRegistered', true);
              SharedPref()
                  .setPreferencesBoolean('pendingFaceVerification', false);
              SharedPref()
                  .setPreferencesBoolean('isFaceRegistrationInProgress', false);

              // Use Navigator.maybePop to work with WillPopScope
              if (mounted) {
                print('🔙 Popping with result: true');
                Navigator.of(context).pop(true);
              }
            } else if (state is FaceVerificationResult) {
              // Handle verification result
              print('🔍 Face verification result: ${state.isVerified}');
              _stopFaceMonitoring();
              _registrationTimeoutTimer?.cancel();

              if (state.isVerified) {
                print('✅ Face verification SUCCESS');
                _registrationSuccess = true;
                setState(() {
                  _showChallengeUI = false;
                  _challengeStatusMessage = '✅ تم التحقق بنجاح!';
                });

                // Call callback if provided
                if (widget.isVerification &&
                    widget.onVerificationSuccess != null) {
                  widget.onVerificationSuccess!();
                }

                // Also trigger check-in if needed (for check-in flow)
                if (widget.isVerification && mounted) {
                  // Pop and return true for check-in success
                  Navigator.of(context).pop(true);
                }
              } else {
                print('❌ Face verification FAILED: ${state.message}');
                setState(() {
                  _isProcessing = false;
                  _showTryAgainButton = true;
                  _showChallengeUI = false;
                  _challengeStatusMessage = state.message;
                });
              }
            } 
            // 🆕 حالة عرض التحدي الحالي
            else if (state is LivenessChallengeInProgress) {
              print('🎯 Challenge: ${state.challengeText}');
              setState(() {
                _showChallengeUI = true;
                _currentChallengeText = state.challengeText;
                _currentChallengeInstruction = state.challengeInstruction;
                _currentChallengeIndex = state.currentChallengeIndex;
                _totalChallenges = state.totalChallenges;
                _completedChallenges = state.completedChallenges;
                _currentChallengeIcon = state.iconCodePoint;
                _isProcessing = true;
              });
            }
            // 🆕 نجاح تحدي واحد
            else if (state is SingleChallengeSuccess) {
              print('✅ Challenge passed: ${state.challengeName}');
              setState(() {
                _challengeStatusMessage = state.message;
              });
            }
            // 🆕 فشل تحدي واحد
            else if (state is SingleChallengeFailed) {
              print('❌ Challenge failed: ${state.challengeName}');
              setState(() {
                _isProcessing = false;
                _showTryAgainButton = true;
                _showChallengeUI = false;
                _challengeStatusMessage = state.message;
              });
            }
            // 🆕 اكتمال فحص الحيوية
            else if (state is LivenessCheckComplete) {
              print('🏁 Liveness check complete: ${state.passed}');
              if (state.passed) {
                setState(() {
                  _challengeStatusMessage = state.message;
                });
              }
            }
            else if (state is FaceRecognitionError) {
              print('❌ Face registration ERROR: ${state.message}');
              _registrationTimeoutTimer?.cancel(); // Cancel timeout on error
              setState(() {
                _isProcessing = false;
                _showTryAgainButton = true;
                _showChallengeUI = false;
                _challengeStatusMessage = state.message;
              });
              // Start monitoring for face to auto-retry
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && _showTryAgainButton) {
                  _startFaceMonitoring();
                }
              });
            } else if (state is FaceRecognitionLoading) {
              print('⏳ Face registration LOADING...');
              setState(() => _isProcessing = true);
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: Column(
                children: [
                  // Minimal Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        if (!_isMandatory)
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(false),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.close,
                                  color: AppColors.primaryColor, size: 22),
                            ),
                          )
                        else
                          const SizedBox(width: 38),
                        const Spacer(),
                        const SizedBox(width: 38),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title Section - Clean & Centered (Dynamic based on mode)
                  Text(
                    widget.isVerification
                        ? (widget.title.isEmpty
                            ? 'التحقق من هويتك'
                            : widget.title)
                        : 'تسجيل الوجه',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isVerification
                        ? (widget.subtitle.isEmpty
                            ? 'اتبع التعليمات للتحقق'
                            : widget.subtitle)
                        : 'ضع وجهك داخل الدائرة',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 15,
                    ),
                  ),
                  
                  // 🆕 واجهة التحديات النشطة
                  if (widget.isVerification && _showChallengeUI) ...[
                    const SizedBox(height: 16),
                    _buildChallengeProgressIndicator(),
                    const SizedBox(height: 12),
                    _buildCurrentChallengeCard(),
                  ]
                  // 🆕 تعليمات بسيطة عند التحقق
                  else if (widget.isVerification && _isProcessing) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility, color: AppColors.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '👁️ انظر للكاميرا واتبع التعليمات',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(flex: 1),

                  // Camera Preview - Clean Circular Design with Animations
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
                                width: cameraSize +
                                    40 +
                                    (30 * _pulseAnimation!.value),
                                height: cameraSize +
                                    40 +
                                    (30 * _pulseAnimation!.value),
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
                              final delayedValue =
                                  (_pulseAnimation!.value + 0.5) % 1.0;
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
                                          AppColors.primaryColor
                                              .withOpacity(0.7)
                                        ]
                                      : [
                                          AppColors.primaryColor
                                              .withOpacity(0.6),
                                          AppColors.primaryColor
                                              .withOpacity(0.3)
                                        ],
                            ),
                            boxShadow: _isProcessing && !_showTryAgainButton
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryColor
                                          .withOpacity(0.3),
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
                                    child:
                                        _buildCameraContent(state, cameraSize),
                                  ),
                                  // Scanning line effect
                                  if (_isProcessing &&
                                      !_showTryAgainButton &&
                                      _pulseAnimation != null)
                                    AnimatedBuilder(
                                      animation: _pulseAnimation!,
                                      builder: (context, child) {
                                        return Positioned(
                                          top: _pulseAnimation!.value *
                                              cameraSize,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 3,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.transparent,
                                                  AppColors.primaryColor
                                                      .withOpacity(0.8),
                                                  AppColors.primaryColor,
                                                  AppColors.primaryColor
                                                      .withOpacity(0.8),
                                                  Colors.transparent,
                                                ],
                                                stops: const [
                                                  0.0,
                                                  0.2,
                                                  0.5,
                                                  0.8,
                                                  1.0
                                                ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primaryColor
                                                      .withOpacity(0.5),
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
                        if (_showTryAgainButton && !_faceCurrentlyVisible) ...[
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
                                    _challengeStatusMessage.isNotEmpty
                                        ? _challengeStatusMessage
                                        : 'لم يتم اكتشاف الوجه',
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
                                'حاول مرة أخرى',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ] else if (_showTryAgainButton &&
                            _faceCurrentlyVisible) ...[
                          Text(
                            'تم اكتشاف الوجه! جاري المحاولة...',
                            style: TextStyle(
                              color: AppColors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else if (_isProcessing && _showChallengeUI) ...[
                          // عند عرض التحديات - لا نعرض نص إضافي
                          const SizedBox.shrink(),
                        ] else if (_isProcessing) ...[
                          Text(
                            'جاري المسح...',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'جاهز للمسح',
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
                  if (!_showTryAgainButton && !_showChallengeUI)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMinimalTip(
                              Icons.lightbulb_outline, 'إضاءة جيدة'),
                          const SizedBox(width: 24),
                          _buildMinimalTip(Icons.face_outlined, 'وجه للأمام'),
                          const SizedBox(width: 24),
                          _buildMinimalTip(
                              Icons.visibility_outlined, 'عيون مفتوحة'),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 60),
                ],
              ),
            );
          },
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

  /// 🆕 مؤشر تقدم التحديات
  Widget _buildChallengeProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalChallenges, (index) {
              final isCompleted = index < _completedChallenges.length;
              final isCurrent = index == _currentChallengeIndex;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isCurrent ? 32 : 24,
                      height: isCurrent ? 32 : 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.green
                            : isCurrent
                                ? AppColors.primaryColor
                                : AppColors.grey.withOpacity(0.3),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isCurrent ? Colors.white : AppColors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isCurrent ? 14 : 12,
                                ),
                              ),
                      ),
                    ),
                    if (index < _totalChallenges - 1)
                      Container(
                        width: 20,
                        height: 2,
                        color: isCompleted
                            ? AppColors.green
                            : AppColors.grey.withOpacity(0.3),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'التحدي ${_currentChallengeIndex + 1} من $_totalChallenges',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 🆕 بطاقة التحدي الحالي
  Widget _buildCurrentChallengeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.15),
            AppColors.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // أيقونة التحدي
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              IconData(_currentChallengeIcon, fontFamily: 'MaterialIcons'),
              color: AppColors.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          
          // عنوان التحدي
          Text(
            _currentChallengeText,
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // تعليمات التحدي
          Text(
            _currentChallengeInstruction,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          
          // رسالة الحالة
          if (_challengeStatusMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _challengeStatusMessage.contains('✅')
                    ? AppColors.green.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _challengeStatusMessage,
                style: TextStyle(
                  color: _challengeStatusMessage.contains('✅')
                      ? AppColors.green
                      : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCameraContent(FaceRecognitionState state, double size) {
    if (_permissionDenied) {
      return Container(
        color: AppColors.lightBlue,
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
        color: AppColors.lightBlue,
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
    _autoRegistrationTimer?.cancel();
    _registrationTimeoutTimer?.cancel(); // Cancel timeout timer
    _pulseAnimationController?.dispose();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }
}
