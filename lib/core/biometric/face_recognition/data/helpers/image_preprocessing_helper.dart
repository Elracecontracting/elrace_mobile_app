import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

/// Helper class for image preprocessing operations
///
/// This class handles:
/// 1. Converting CameraImage to Image format
/// 2. Cropping faces based on ML Kit bounding boxes
/// 3. Face alignment and augmentation
class ImagePreprocessingHelper {
  /// Crop face from camera image using the bounding box from ML Kit
  ///
  /// Parameters:
  /// - cameraImage: The original camera frame
  /// - face: The detected face with bounding box
  /// - paddingPercent: Extra padding around the face (default 20%)
  ///
  /// Returns:
  /// - img.Image: Cropped face image ready for embedding generation
  ///
  /// Algorithm:
  /// 1. Convert CameraImage to Image format
  /// 2. Extract bounding box coordinates
  /// 3. Add padding to include more context
  /// 4. Crop the face region
  /// 5. Return the cropped image
  static Future<img.Image> cropFace(
    CameraImage cameraImage,
    Face face, {
    double paddingPercent = 0.2,
  }) async {
    // Step 1: Convert camera image to Image object
    final image = await convertCameraImageToImage(cameraImage);

    // Step 2: Get face bounding box
    final boundingBox = face.boundingBox;

    // Step 3: Calculate padding
    final paddingX = (boundingBox.width * paddingPercent).toInt();
    final paddingY = (boundingBox.height * paddingPercent).toInt();

    // Step 4: Calculate crop coordinates with padding (ensure within bounds)
    final left =
        (boundingBox.left - paddingX).clamp(0, image.width - 1).toInt();
    final top = (boundingBox.top - paddingY).clamp(0, image.height - 1).toInt();
    final right = (boundingBox.right + paddingX).clamp(0, image.width).toInt();
    final bottom =
        (boundingBox.bottom + paddingY).clamp(0, image.height).toInt();

    final width = right - left;
    final height = bottom - top;

    // Step 5: Crop the face region
    final croppedFace = img.copyCrop(
      image,
      x: left,
      y: top,
      width: width,
      height: height,
    );

    return croppedFace;
  }

  /// Convert CameraImage (from camera plugin) to img.Image
  ///
  /// Handles different image formats:
  /// - YUV420 (Android)
  /// - BGRA8888 (iOS)
  /// - NV21, etc.
  static Future<img.Image> convertCameraImageToImage(
      CameraImage cameraImage) async {
    try {
      // Check image format
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToImage(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.nv21) {
        return _convertNV21ToImage(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888ToImage(cameraImage);
      } else {
        throw Exception(
            'Unsupported image format: ${cameraImage.format.group}');
      }
    } catch (e) {
      throw Exception('Failed to convert camera image: $e');
    }
  }

  /// Convert YUV420 format to Image (Android)
  ///
  /// YUV420 is a common format on Android devices
  /// It stores luminance (Y) and chrominance (U, V) separately
  static img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    // Get YUV planes
    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];

    // Create output image
    final image = img.Image(width: width, height: height);

    // YUV to RGB conversion
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yPlane.bytesPerRow + x;
        final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        final yValue = yPlane.bytes[yIndex];
        final uValue = uPlane.bytes[uvIndex];
        final vValue = vPlane.bytes[uvIndex];

        // YUV to RGB conversion formula
        final r = (yValue + 1.370705 * (vValue - 128)).clamp(0, 255).toInt();
        final g =
            (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128))
                .clamp(0, 255)
                .toInt();
        final b = (yValue + 1.732446 * (uValue - 128)).clamp(0, 255).toInt();

        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return image;
  }

  /// Convert NV21 format to Image (Android)
  ///
  /// NV21 is a common YUV format on Android where:
  /// - Plane 0: Y (luminance) data
  /// - Plane 1: Interleaved VU (chrominance) data
  static img.Image _convertNV21ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    // NV21 has Y plane and interleaved VU plane
    final yPlane = cameraImage.planes[0];
    final vuPlane = cameraImage.planes[1];

    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yPlane.bytesPerRow + x;
        // VU plane is interleaved: V at even indices, U at odd indices
        final vuIndex = (y ~/ 2) * vuPlane.bytesPerRow + (x ~/ 2) * 2;

        final yValue = yPlane.bytes[yIndex];
        final vValue = vuPlane.bytes[vuIndex];
        final uValue = vuPlane.bytes[vuIndex + 1];

        // YUV to RGB conversion formula
        final r = (yValue + 1.370705 * (vValue - 128)).clamp(0, 255).toInt();
        final g =
            (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128))
                .clamp(0, 255)
                .toInt();
        final b = (yValue + 1.732446 * (uValue - 128)).clamp(0, 255).toInt();

        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return image;
  }

  /// Convert BGRA8888 format to Image (iOS)
  ///
  /// BGRA8888 is the standard format on iOS devices
  static img.Image _convertBGRA8888ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final bytes = cameraImage.planes[0].bytes;

    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = (y * width + x) * 4;

        final b = bytes[index];
        final g = bytes[index + 1];
        final r = bytes[index + 2];
        final a = bytes[index + 3];

        image.setPixelRgba(x, y, r, g, b, a);
      }
    }

    return image;
  }

  /// Align face to frontal position (optional, advanced)
  ///
  /// Uses facial landmarks to rotate and align the face
  /// This can improve recognition accuracy
  static img.Image? alignFace(img.Image faceImage, Face face) {
    // Get eye landmarks
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    if (leftEye == null || rightEye == null) {
      return faceImage; // Can't align without eye landmarks
    }

    // Calculate rotation angle based on eye positions
    final dx = rightEye.position.x - leftEye.position.x;
    final dy = rightEye.position.y - leftEye.position.y;
    final angle = math.atan2(dy, dx) * 180 / math.pi;

    // Rotate image to align eyes horizontally
    // Note: This is a simplified version
    // Production code should handle scaling and cropping
    // after rotation to keep the face centered

    return faceImage; // Return original for now
  }

  /// Enhance image quality (brightness, contrast, sharpness)
  ///
  /// This can help with faces in poor lighting conditions
  static img.Image enhanceImage(img.Image image) {
    // Adjust brightness
    img.Image enhanced = img.adjustColor(image, brightness: 1.1);

    // Adjust contrast
    enhanced = img.adjustColor(enhanced, contrast: 1.2);

    // Optional: Apply sharpening
    // enhanced = img.sharpen(enhanced);

    return enhanced;
  }

  /// Create multiple augmented versions of a face for robust registration
  ///
  /// Augmentations:
  /// - Slight brightness variations
  /// - Slight contrast variations
  /// - Horizontal flip (mirror)
  ///
  /// This helps create a more robust embedding that works in various conditions
  static List<img.Image> augmentFace(img.Image faceImage) {
    final augmentedImages = <img.Image>[faceImage];

    // Brightness variations
    augmentedImages.add(img.adjustColor(faceImage, brightness: 1.1));
    augmentedImages.add(img.adjustColor(faceImage, brightness: 0.9));

    // Contrast variations
    augmentedImages.add(img.adjustColor(faceImage, contrast: 1.1));

    // Horizontal flip (mirror)
    augmentedImages.add(img.flipHorizontal(faceImage));

    return augmentedImages;
  }
}
