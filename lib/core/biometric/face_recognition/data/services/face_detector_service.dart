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
  /// 🆕 ENHANCED v2.0 - Stricter Anti-Spoofing
  /// 
  /// Liveness Detection Logic:
  /// 1. Check if eyes are open (leftEyeOpenProbability > threshold)
  /// 2. Optionally check for smile (smilingProbability)
  /// 3. Check head pose angles (ensure face is frontal but not TOO static)
  /// 4. 🆕 Verify eye data is actually available (photos might return null/fixed values)
  ///
  /// Returns true if the face appears to be a live person
  bool checkLiveness(
    Face face, {
    double eyeOpenThreshold = 0.55, // Raised from 0.5 to 0.55 to prevent photo attacks
    double? smilingThreshold,
    double maxHeadEulerAngleY = 12.0, // Reduced from 15 to 12 degrees
    double maxHeadEulerAngleZ = 12.0, // Reduced from 15 to 12 degrees
  }) {
    // Check if classification data is available
    if (face.leftEyeOpenProbability == null ||
        face.rightEyeOpenProbability == null) {
      // If classification is disabled, we can't check liveness
      print('⚠️ SECURITY WARNING: Eye classification data not available!');
      return false; // Reject if eye classification data is not available
    }

    // 🆕 Enhanced Check: Verify eye values are in realistic range
    // Photos often return constant values like 0.99 or exactly 1.0
    final leftEye = face.leftEyeOpenProbability!;
    final rightEye = face.rightEyeOpenProbability!;
    
    // Suspicious: both eyes at exactly same value (photos often do this)
    if ((leftEye - rightEye).abs() < 0.001 && leftEye > 0.9) {
      print('⚠️ SECURITY WARNING: Eyes have identical high values - suspicious!');
      // Don't fail yet, but log as suspicious
    }
    
    // Suspicious: perfect 1.0 values (unrealistic for real eyes)
    if (leftEye >= 0.99 && rightEye >= 0.99) {
      print('⚠️ SECURITY WARNING: Eyes show perfect 1.0 values - possible photo!');
      // We'll rely on blink detection to catch this
    }

    // Check 1: Both eyes should be reasonably open
    final leftEyeOpen = leftEye > eyeOpenThreshold;
    final rightEyeOpen = rightEye > eyeOpenThreshold;

    print('👁️ Liveness Check - Left Eye: ${leftEye.toStringAsFixed(3)}, Right Eye: ${rightEye.toStringAsFixed(3)}');
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
  /// 🆕 ENHANCED v2.0 - Better detection of photo attacks
  /// Returns a score from 0.0 to 1.0 indicating face quality
  /// Higher score = better quality for registration
  double getFaceQuality(Face face) {
    double qualityScore = 1.0;

    // Factor 1: Face size (larger is better, up to a point)
    final faceArea = face.boundingBox.width * face.boundingBox.height;
    final sizeScore = (faceArea / (640 * 480)).clamp(0.0, 1.0);
    qualityScore *= sizeScore;

    // 🆕 ANTI-SPOOF: Reject if face is too large (screen-sized) - possible photo attack
    // A face taking up more than 80% of frame might be a photo on a screen
    if (sizeScore > 0.8) {
      print('⚠️ ANTI-SPOOF: Face too large (${(sizeScore * 100).toInt()}%) - possible screen photo');
      qualityScore *= 0.5; // Penalize significantly
    }

    // Factor 2: Head pose (frontal is better)
    if (face.headEulerAngleY != null && face.headEulerAngleZ != null) {
      final yawScore =
          1.0 - (face.headEulerAngleY!.abs() / 90.0).clamp(0.0, 1.0);
      final rollScore =
          1.0 - (face.headEulerAngleZ!.abs() / 90.0).clamp(0.0, 1.0);
      qualityScore *= (yawScore + rollScore) / 2;
      
      // 🆕 ANTI-SPOOF: Penalize perfectly centered poses (photos are often centered)
      if (face.headEulerAngleY!.abs() < 0.5 && face.headEulerAngleZ!.abs() < 0.5) {
        print('⚠️ ANTI-SPOOF: Head perfectly centered (yaw=${face.headEulerAngleY!.toStringAsFixed(2)}, roll=${face.headEulerAngleZ!.toStringAsFixed(2)})');
        // Don't penalize quality, but log for anti-spoof tracking
      }
    }

    // Factor 3: Eyes open (if available)
    if (face.leftEyeOpenProbability != null &&
        face.rightEyeOpenProbability != null) {
      final eyeScore =
          (face.leftEyeOpenProbability! + face.rightEyeOpenProbability!) / 2;
      qualityScore *= eyeScore;
      
      // 🆕 ANTI-SPOOF: Penalize perfect eye values (unnatural for real people)
      if (face.leftEyeOpenProbability! > 0.98 && face.rightEyeOpenProbability! > 0.98) {
        print('⚠️ ANTI-SPOOF: Eyes too perfect (${face.leftEyeOpenProbability!.toStringAsFixed(3)}, ${face.rightEyeOpenProbability!.toStringAsFixed(3)})');
        qualityScore *= 0.85; // Slight penalty for perfect values
      }
    }

    return qualityScore.clamp(0.0, 1.0);
  }
  
  /// 🆕 NEW: Enhanced anti-spoof scoring
  /// 
  /// Checks multiple indicators that suggest a photo/video attack:
  /// - Eye values too perfect or identical
  /// - Face size suggesting screen/photo
  /// - Bounding box position suggesting photo layout
  /// 
  /// Returns score 0.0 (definitely fake) to 1.0 (likely real)
  double getAntiSpoofScore(Face face) {
    double score = 1.0;
    
    // Check 1: Eye probability analysis
    if (face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
      final leftEye = face.leftEyeOpenProbability!;
      final rightEye = face.rightEyeOpenProbability!;
      
      // Perfect eye values (>0.995) are suspicious - RELAXED
      if (leftEye > 0.995 && rightEye > 0.995) {
        score *= 0.85;
        print('🔍 Anti-Spoof: Perfect eye values detected (-15%)');
      }
      
      // BOTH identical AND perfect values are very suspicious - RELAXED
      if ((leftEye - rightEye).abs() < 0.003 && leftEye > 0.98 && rightEye > 0.98) {
        score *= 0.85;
        print('🔍 Anti-Spoof: Identical perfect eye probabilities (-15%)');
      }
      
      // Very low eye values with face still detected = closed eyes in photo
      if (leftEye < 0.1 && rightEye < 0.1) {
        score *= 0.4;
        print('🔍 Anti-Spoof: Very low eye probabilities (-60%)');
      }
    }
    
    // Check 2: Head pose analysis
    if (face.headEulerAngleY != null && face.headEulerAngleZ != null) {
      // Perfectly centered face (< 0.3 degrees) is suspicious
      if (face.headEulerAngleY!.abs() < 0.3 && face.headEulerAngleZ!.abs() < 0.3) {
        score *= 0.85;
        print('🔍 Anti-Spoof: Perfectly centered pose (-15%)');
      }
    }
    
    // Check 3: Face size analysis  
    final faceArea = face.boundingBox.width * face.boundingBox.height;
    final screenFraction = faceArea / (640 * 480);
    
    // VERY large face (>95% of frame) suggests photo on screen - RELAXED
    if (screenFraction > 0.95) {
      score *= 0.7;
      print('🔍 Anti-Spoof: Face extremely large (${(screenFraction * 100).toInt()}%) (-30%)');
    }
    
    // Check 4: Face contour stability (tracked faces in photos don't change contours)
    // Note: This requires tracking across frames (done in LivenessService)
    
    print('🛡️ Anti-Spoof Score: ${(score * 100).toInt()}%');
    return score.clamp(0.0, 1.0);
  }

  /// Convert CameraImage to InputImage for ML Kit processing
  ///
  /// Handles different image formats (YUV, BGRA, etc.) and rotations
  InputImage _convertCameraImage(CameraImage image) {
    // For front camera on Android, we typically need rotation270deg
    // This handles the most common case for selfie/face registration
    const rotation = InputImageRotation.rotation270deg;

    // Get image format - force NV21 on Android for ML Kit compatibility
    final format = InputImageFormat.nv21;

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
