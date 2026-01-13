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
    extends State<CheckInFaceVerificationScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = 'ضع وجهك في الإطار';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
      }
    } catch (e) {
      print('❌ Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'خطأ في تشغيل الكاميرا';
        });
      }
    }
  }

  Future<void> _captureAndVerify() async {
    if (_isProcessing || _cameraController == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'جاري التحقق من الوجه...';
    });

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
        _statusMessage = 'خطأ في التقاط الصورة';
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
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
            });

            // Show error and close after delay
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).pop(false);
              }
            });
          } else if (state is FaceNotEnrolledST) {
            setState(() {
              _statusMessage = '⚠️ يجب تسجيل الوجه أولاً';
              _isProcessing = false;
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
            });

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).pop(false);
              }
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

            // Face oval overlay
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: FaceOvalPainter(),
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

            // Capture button
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : GestureDetector(
                        onTap: _captureAndVerify,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
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
                      '• ضع وجهك داخل الإطار البيضاوي\n• اضغط على زر الكاميرا',
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

/// Custom painter for face oval overlay
class FaceOvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 50),
      width: size.width * 0.7,
      height: size.height * 0.5,
    );

    canvas.drawOval(ovalRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
