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

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  CameraController? _cameraController;
  bool _isProcessing = false;
  bool _isMandatory = false; // Track if registration is mandatory
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    // Check if this is mandatory (after login) or optional (during swipe)
    _checkIfMandatory();
    _initializeCamera();
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

  void _captureAndRegister() async {
    if (_isProcessing || _cameraController == null) return;

    setState(() => _isProcessing = true);

    try {
      // Start image stream
      await _cameraController!.startImageStream((CameraImage image) async {
        // Stop stream immediately to process only one frame
        await _cameraController!.stopImageStream();

        // Trigger registration
        if (mounted) {
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
      setState(() => _isProcessing = false);
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
                _isProcessing = false;
              });
              // Auto-capture after camera is ready
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) _captureAndRegister();
              });
            } else if (state is FaceRegistrationSuccess) {
              // Registration successful - navigate back
              Navigator.of(context).pop(true);
            } else if (state is FaceRecognitionError) {
              setState(() => _isProcessing = false);
              // Don't show error, let user try again or close
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
                        // Retry button if error
                        if (state is FaceRecognitionError && !_isProcessing)
                          Column(
                            children: [
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _captureAndRegister,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try Again'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CameraPreview(_cameraController!),
    );
  }

  String _getStatusText(FaceRecognitionState state) {
    if (state is FaceRecognitionLoading) {
      return 'Registering your face...';
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
    _cameraController?.dispose();
    super.dispose();
  }
}
