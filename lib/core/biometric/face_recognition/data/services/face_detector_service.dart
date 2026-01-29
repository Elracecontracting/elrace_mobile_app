import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show WriteBuffer;
import 'dart:ui' show Size;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Service for detecting faces using Google ML Kit
/// Provides face bounding boxes, landmarks, and tracking information
class FaceDetectorService {
  FaceDetector? _faceDetector;
  bool _isInitialized = false;

  /// Initialize the face detector with options
  ///
  /// Options:
  /// - enableTracking: Track faces across frames (useful for liveness)
  /// - enableLandmarks: Detect facial landmarks (eyes, nose, mouth)
  /// - enableClassification: Get probabilities (smiling, eyes open)
  /// - minFaceSize: Minimum face size relative to image (0.1 = 10%)
  Future<void> initialize({
    bool enableTracking = true,
    bool enableLandmarks = true,
    bool enableClassification = true,
    double minFaceSize = 0.15,
  }) async {
    if (_isInitialized) {
      return;
    }

    final options = FaceDetectorOptions(
      enableTracking: enableTracking,
      enableLandmarks: enableLandmarks,
      enableClassification: enableClassification,
      minFaceSize: minFaceSize,
      performanceMode: FaceDetectorMode.accurate,
    );

    _faceDetector = FaceDetector(options: options);
    _isInitialized = true;
  }

  /// Detect faces in a camera image
  ///
  /// Returns a list of detected faces with bounding boxes and landmarks
  /// Throws exception if not initialized or detection fails
  Future<List<Face>> detectFaces(CameraImage image) async {
    if (!_isInitialized || _faceDetector == null) {
      throw Exception(
          'FaceDetectorService not initialized. Call initialize() first.');
    }

    final inputImage = _convertCameraImage(image);
    final faces = await _faceDetector!.processImage(inputImage);

    return faces;
  }

  /// Detect faces in a static image (for testing or single-shot detection)
  Future<List<Face>> detectFacesFromInputImage(InputImage inputImage) async {
    if (!_isInitialized || _faceDetector == null) {
      throw Exception(
          'FaceDetectorService not initialized. Call initialize() first.');
    }

    return await _faceDetector!.processImage(inputImage);
  }

  /// Check if a face passes basic liveness checks
  ///
  /// Liveness Detection Logic:
  /// 1. Check if eyes are open (leftEyeOpenProbability > threshold)
  /// 2. Optionally check for smile (smilingProbability)
  /// 3. Check head pose angles (ensure face is frontal)
  ///
  /// Returns true if the face appears to be a live person
  bool checkLiveness(
    Face face, {
    double eyeOpenThreshold = 0.5, // ⬆️ زيادة العتبة من 0.3 إلى 0.5 لمنع الصور
    double? smilingThreshold,
    double maxHeadEulerAngleY = 15.0, // ⬇️ تقليل الزاوية المسموحة من 20 إلى 15
    double maxHeadEulerAngleZ = 15.0, // ⬇️ تقليل الزاوية المسموحة من 20 إلى 15
  }) {
    // Check if classification data is available
    if (face.leftEyeOpenProbability == null ||
        face.rightEyeOpenProbability == null) {
      // If classification is disabled, we can't check liveness
      print('⚠️ SECURITY WARNING: Eye classification data not available!');
      return false; // ❌ رفض التحقق إذا لم تكن بيانات العينين متاحة
    }

    // Check 1: Both eyes should be reasonably open
    final leftEyeOpen = face.leftEyeOpenProbability! > eyeOpenThreshold;
    final rightEyeOpen = face.rightEyeOpenProbability! > eyeOpenThreshold;

    print('👁️ Liveness Check - Left Eye: ${face.leftEyeOpenProbability!.toStringAsFixed(2)}, Right Eye: ${face.rightEyeOpenProbability!.toStringAsFixed(2)}');
    print('👁️ Required threshold: $eyeOpenThreshold');

    if (!leftEyeOpen || !rightEyeOpen) {
      print('❌ Liveness FAILED: Eyes not sufficiently open');
      return false; // Eyes are closed or barely open - possible photo attack
    }

    // Check 2: Optional smile check (for interactive liveness)
    if (smilingThreshold != null && face.smilingProbability != null) {
      if (face.smilingProbability! < smilingThreshold) {
        return false;
      }
    }

    // Check 3: Head pose should be roughly frontal
    // headEulerAngleY: rotation around Y-axis (left-right turn)
    // headEulerAngleZ: rotation around Z-axis (head tilt)
    if (face.headEulerAngleY != null && face.headEulerAngleZ != null) {
      final isYawAcceptable = face.headEulerAngleY!.abs() < maxHeadEulerAngleY;
      final isRollAcceptable = face.headEulerAngleZ!.abs() < maxHeadEulerAngleZ;

      if (!isYawAcceptable || !isRollAcceptable) {
        return false; // Head is turned too much
      }
    }

    return true;
  }

  /// Extract face quality metrics for better registration
  ///
  /// Returns a score from 0.0 to 1.0 indicating face quality
  /// Higher score = better quality for registration
  double getFaceQuality(Face face) {
    double qualityScore = 1.0;

    // Factor 1: Face size (larger is better, up to a point)
    final faceArea = face.boundingBox.width * face.boundingBox.height;
    final sizeScore = (faceArea / (640 * 480)).clamp(0.0, 1.0);
    qualityScore *= sizeScore;

    // Factor 2: Head pose (frontal is better)
    if (face.headEulerAngleY != null && face.headEulerAngleZ != null) {
      final yawScore =
          1.0 - (face.headEulerAngleY!.abs() / 90.0).clamp(0.0, 1.0);
      final rollScore =
          1.0 - (face.headEulerAngleZ!.abs() / 90.0).clamp(0.0, 1.0);
      qualityScore *= (yawScore + rollScore) / 2;
    }

    // Factor 3: Eyes open (if available)
    if (face.leftEyeOpenProbability != null &&
        face.rightEyeOpenProbability != null) {
      final eyeScore =
          (face.leftEyeOpenProbability! + face.rightEyeOpenProbability!) / 2;
      qualityScore *= eyeScore;
    }

    return qualityScore.clamp(0.0, 1.0);
  }

  /// Convert CameraImage to InputImage for ML Kit processing
  ///
  /// Handles different image formats (YUV, BGRA, etc.) and rotations
  InputImage _convertCameraImage(CameraImage image) {
    // For front camera on Android, we typically need rotation270deg
    // This handles the most common case for selfie/face registration
    const rotation = InputImageRotation.rotation270deg;

    // Get image format - Android typically uses NV21
    final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    // Create metadata
    final inputImageMetadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    // Concatenate all plane bytes
    final bytes = WriteBuffer();
    for (final plane in image.planes) {
      bytes.putUint8List(plane.bytes);
    }

    return InputImage.fromBytes(
      bytes: bytes.done().buffer.asUint8List(),
      metadata: inputImageMetadata,
    );
  }

  /// Get rotation based on camera sensor orientation and device rotation
  InputImageRotation _getInputImageRotation(
    CameraLensDirection lensDirection,
    int sensorOrientation,
  ) {
    // This is a simplified version - you may need to adjust based on your use case
    if (lensDirection == CameraLensDirection.front) {
      return InputImageRotation.rotation270deg;
    } else {
      return InputImageRotation.rotation90deg;
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    if (_faceDetector != null) {
      await _faceDetector!.close();
      _faceDetector = null;
    }
    _isInitialized = false;
  }

  bool get isInitialized => _isInitialized;
}
