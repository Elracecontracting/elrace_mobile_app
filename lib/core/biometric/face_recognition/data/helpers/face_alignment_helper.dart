import 'dart:math' as math;
import 'dart:ui' show Rect;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

/// Face Alignment Helper
///
/// Aligns faces before generating embeddings using facial landmarks.
/// This improves embedding quality and matching accuracy by normalizing
/// face orientation and position.
///
/// Algorithm:
/// 1. Extract eye landmarks
/// 2. Calculate rotation angle to align eyes horizontally
/// 3. Rotate image to align face
/// 4. Scale and translate to center face
/// 5. Crop to standard size (112x112)
class FaceAlignmentHelper {
  /// Align face using eye landmarks
  ///
  /// Returns aligned and cropped face image ready for embedding
  static img.Image alignFace({
    required img.Image sourceImage,
    required Face face,
    int outputSize = 112,
  }) {
    // Get eye landmarks
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    if (leftEye == null || rightEye == null) {
      // If no landmarks, fall back to simple crop
      return _simpleCrop(sourceImage, face.boundingBox, outputSize);
    }

    // Calculate alignment parameters
    final alignmentParams = _calculateAlignmentParameters(
      leftEye: FacePoint(
          leftEye.position.x.toDouble(), leftEye.position.y.toDouble()),
      rightEye: FacePoint(
          rightEye.position.x.toDouble(), rightEye.position.y.toDouble()),
      outputSize: outputSize,
    );

    // Apply alignment transformation
    final alignedImage = _applyAlignment(
      sourceImage: sourceImage,
      params: alignmentParams,
      outputSize: outputSize,
    );

    return alignedImage;
  }

  /// Calculate alignment parameters from eye positions
  static _AlignmentParameters _calculateAlignmentParameters({
    required FacePoint leftEye,
    required FacePoint rightEye,
    required int outputSize,
  }) {
    // Calculate eye center
    final eyeCenterX = (leftEye.x + rightEye.x) / 2;
    final eyeCenterY = (leftEye.y + rightEye.y) / 2;

    // Calculate rotation angle to align eyes horizontally
    final dY = rightEye.y - leftEye.y;
    final dX = rightEye.x - leftEye.x;
    final angle = math.atan2(dY, dX);

    // Calculate scale to normalize eye distance
    final eyeDistance = math.sqrt(dX * dX + dY * dY);
    final desiredEyeDistance =
        outputSize * 0.35; // Eyes should be 35% of face width
    final scale = desiredEyeDistance / eyeDistance;

    return _AlignmentParameters(
      centerX: eyeCenterX,
      centerY: eyeCenterY,
      angle: angle,
      scale: scale,
    );
  }

  /// Apply alignment transformation to image
  static img.Image _applyAlignment({
    required img.Image sourceImage,
    required _AlignmentParameters params,
    required int outputSize,
  }) {
    // Create output image
    final aligned = img.Image(width: outputSize, height: outputSize);

    // Calculate transformation matrix
    final cosAngle = math.cos(params.angle);
    final sinAngle = math.sin(params.angle);

    // For each pixel in output image, find corresponding source pixel
    for (int y = 0; y < outputSize; y++) {
      for (int x = 0; x < outputSize; x++) {
        // Translate to center
        final xCentered = x - outputSize / 2;
        final yCentered = y - outputSize / 2;

        // Apply inverse scale
        final xScaled = xCentered / params.scale;
        final yScaled = yCentered / params.scale;

        // Apply inverse rotation
        final xRotated = xScaled * cosAngle + yScaled * sinAngle;
        final yRotated = -xScaled * sinAngle + yScaled * cosAngle;

        // Translate back to eye center in source image
        final srcX = (xRotated + params.centerX).round();
        final srcY = (yRotated + params.centerY).round();

        // Check bounds and copy pixel
        if (srcX >= 0 &&
            srcX < sourceImage.width &&
            srcY >= 0 &&
            srcY < sourceImage.height) {
          final pixel = sourceImage.getPixel(srcX, srcY);
          aligned.setPixel(x, y, pixel);
        }
      }
    }

    return aligned;
  }

  /// Simple crop fallback when landmarks are not available
  static img.Image _simpleCrop(
    img.Image sourceImage,
    Rect boundingBox,
    int outputSize,
  ) {
    // Extract bounding box coordinates
    final x = boundingBox.left.round().clamp(0, sourceImage.width);
    final y = boundingBox.top.round().clamp(0, sourceImage.height);
    final width = boundingBox.width.round().clamp(0, sourceImage.width - x);
    final height = boundingBox.height.round().clamp(0, sourceImage.height - y);

    // Crop face region
    final cropped = img.copyCrop(
      sourceImage,
      x: x,
      y: y,
      width: width,
      height: height,
    );

    // Resize to output size
    return img.copyResize(
      cropped,
      width: outputSize,
      height: outputSize,
      interpolation: img.Interpolation.cubic,
    );
  }

  /// Check if face has sufficient landmarks for alignment
  static bool canAlign(Face face) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    return leftEye != null && rightEye != null;
  }

  /// Get alignment quality score (0.0-1.0)
  ///
  /// Higher score means better alignment conditions
  static double getAlignmentQuality(Face face) {
    if (!canAlign(face)) return 0.0;

    double quality = 1.0;

    // Factor 1: Head pose (frontal is better)
    if (face.headEulerAngleY != null) {
      final yawPenalty = (face.headEulerAngleY!.abs() / 45.0).clamp(0.0, 1.0);
      quality *= (1.0 - yawPenalty);
    }

    if (face.headEulerAngleZ != null) {
      final rollPenalty = (face.headEulerAngleZ!.abs() / 45.0).clamp(0.0, 1.0);
      quality *= (1.0 - rollPenalty);
    }

    // Factor 2: Face size (larger is better)
    final faceArea = face.boundingBox.width * face.boundingBox.height;
    final normalizedArea = (faceArea / (640 * 480)).clamp(0.0, 1.0);
    quality *= normalizedArea;

    return quality.clamp(0.0, 1.0);
  }
}

/// Alignment transformation parameters
class _AlignmentParameters {
  final double centerX;
  final double centerY;
  final double angle; // in radians
  final double scale;

  _AlignmentParameters({
    required this.centerX,
    required this.centerY,
    required this.angle,
    required this.scale,
  });
}

/// Face point for landmark positions
class FacePoint {
  final double x;
  final double y;

  FacePoint(this.x, this.y);
}
