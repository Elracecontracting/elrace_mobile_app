import 'dart:math' as math;
import 'dart:ui' show Rect;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

/// Quality Gate Helper
///
/// Validates face image quality before processing.
/// Ensures only high-quality faces are used for enrollment and verification.
///
/// Quality checks:
/// - Face size (minimum percentage of image)
/// - Head pose (frontal orientation)
/// - Blur detection (Laplacian variance)
/// - Brightness/contrast
/// - Face visibility
class QualityGateHelper {
  /// Quality configuration for enrollment (stricter)
  static const QualityConfig enrollmentConfig = QualityConfig(
    minFaceSizeRatio: 0.25, // Face must be at least 25% of image width
    maxYaw: 15.0, // Head turn left/right
    maxPitch: 15.0, // Head tilt up/down
    maxRoll: 10.0, // Head tilt left/right
    minBlurScore: 150.0, // Variance of Laplacian
    minBrightness: 80.0,
    maxBrightness: 200.0,
    minContrast: 40.0,
  );

  /// Quality configuration for verification (more lenient)
  static const QualityConfig verificationConfig = QualityConfig(
    minFaceSizeRatio: 0.20, // Face must be at least 20% of image width
    maxYaw: 25.0,
    maxPitch: 20.0,
    maxRoll: 15.0,
    minBlurScore: 100.0,
    minBrightness: 60.0,
    maxBrightness: 220.0,
    minContrast: 30.0,
  );

  /// Check if face passes quality gate
  static QualityCheckResult checkQuality({
    required img.Image image,
    required Face face,
    required QualityConfig config,
  }) {
    final failures = <QualityFailureReason>[];

    // Check 1: Face size
    final faceWidth = face.boundingBox.width;
    final imageWidth = image.width;
    final faceSizeRatio = faceWidth / imageWidth;

    if (faceSizeRatio < config.minFaceSizeRatio) {
      failures.add(QualityFailureReason.faceTooSmall);
    }

    // Check 2: Head pose
    final yaw = face.headEulerAngleY?.abs() ?? 0.0;
    final pitch = face.headEulerAngleX?.abs() ?? 0.0;
    final roll = face.headEulerAngleZ?.abs() ?? 0.0;

    if (yaw > config.maxYaw) {
      failures.add(QualityFailureReason.headNotFrontal);
    }

    if (pitch > config.maxPitch) {
      failures.add(QualityFailureReason.headTilted);
    }

    if (roll > config.maxRoll) {
      failures.add(QualityFailureReason.headRolled);
    }

    // Check 3: Blur detection
    final blurScore = _calculateBlurScore(image, face.boundingBox);
    if (blurScore < config.minBlurScore) {
      failures.add(QualityFailureReason.tooBlurry);
    }

    // Check 4: Brightness
    final brightness = _calculateBrightness(image, face.boundingBox);
    if (brightness < config.minBrightness) {
      failures.add(QualityFailureReason.tooDark);
    }
    if (brightness > config.maxBrightness) {
      failures.add(QualityFailureReason.tooBright);
    }

    // Check 5: Contrast
    final contrast = _calculateContrast(image, face.boundingBox);
    if (contrast < config.minContrast) {
      failures.add(QualityFailureReason.lowContrast);
    }

    // Calculate overall quality score
    final qualityScore = _calculateOverallQuality(
      faceSizeRatio: faceSizeRatio,
      yaw: yaw,
      pitch: pitch,
      roll: roll,
      blurScore: blurScore,
      brightness: brightness,
      contrast: contrast,
      config: config,
    );

    return QualityCheckResult(
      passed: failures.isEmpty,
      failures: failures,
      qualityScore: qualityScore,
      metrics: QualityMetrics(
        faceSizeRatio: faceSizeRatio,
        yaw: yaw,
        pitch: pitch,
        roll: roll,
        blurScore: blurScore,
        brightness: brightness,
        contrast: contrast,
      ),
    );
  }

  /// Calculate blur score using Variance of Laplacian
  ///
  /// Higher score = sharper image
  /// Lower score = blurrier image
  static double _calculateBlurScore(img.Image image, Rect faceBox) {
    // Extract face region
    final x = faceBox.left.round().clamp(0, image.width - 1);
    final y = faceBox.top.round().clamp(0, image.height - 1);
    final width = faceBox.width.round().clamp(1, image.width - x);
    final height = faceBox.height.round().clamp(1, image.height - y);

    if (width < 10 || height < 10) return 0.0;

    // Convert to grayscale for processing
    final grayscale = img.grayscale(img.copyCrop(
      image,
      x: x,
      y: y,
      width: width,
      height: height,
    ));

    // Calculate Laplacian (edge detection)
    double sum = 0.0;
    int count = 0;

    for (int py = 1; py < grayscale.height - 1; py++) {
      for (int px = 1; px < grayscale.width - 1; px++) {
        // Laplacian kernel approximation
        final center = grayscale.getPixel(px, py).r.toDouble();
        final top = grayscale.getPixel(px, py - 1).r.toDouble();
        final bottom = grayscale.getPixel(px, py + 1).r.toDouble();
        final left = grayscale.getPixel(px - 1, py).r.toDouble();
        final right = grayscale.getPixel(px + 1, py).r.toDouble();

        final laplacian = (4 * center) - (top + bottom + left + right);
        sum += laplacian * laplacian;
        count++;
      }
    }

    // Return variance
    return count > 0 ? sum / count : 0.0;
  }

  /// Calculate average brightness of face region
  static double _calculateBrightness(img.Image image, Rect faceBox) {
    final x = faceBox.left.round().clamp(0, image.width - 1);
    final y = faceBox.top.round().clamp(0, image.height - 1);
    final width = faceBox.width.round().clamp(1, image.width - x);
    final height = faceBox.height.round().clamp(1, image.height - y);

    if (width < 1 || height < 1) return 0.0;

    double sum = 0.0;
    int count = 0;

    for (int py = y; py < y + height && py < image.height; py++) {
      for (int px = x; px < x + width && px < image.width; px++) {
        final pixel = image.getPixel(px, py);
        // Calculate luminance (perceived brightness)
        final luminance = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
        sum += luminance;
        count++;
      }
    }

    return count > 0 ? sum / count : 0.0;
  }

  /// Calculate contrast of face region (standard deviation of brightness)
  static double _calculateContrast(img.Image image, Rect faceBox) {
    final x = faceBox.left.round().clamp(0, image.width - 1);
    final y = faceBox.top.round().clamp(0, image.height - 1);
    final width = faceBox.width.round().clamp(1, image.width - x);
    final height = faceBox.height.round().clamp(1, image.height - y);

    if (width < 1 || height < 1) return 0.0;

    // First pass: calculate mean
    double sum = 0.0;
    int count = 0;

    for (int py = y; py < y + height && py < image.height; py++) {
      for (int px = x; px < x + width && px < image.width; px++) {
        final pixel = image.getPixel(px, py);
        final luminance = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
        sum += luminance;
        count++;
      }
    }

    if (count == 0) return 0.0;
    final mean = sum / count;

    // Second pass: calculate variance
    double varianceSum = 0.0;
    for (int py = y; py < y + height && py < image.height; py++) {
      for (int px = x; px < x + width && px < image.width; px++) {
        final pixel = image.getPixel(px, py);
        final luminance = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
        final diff = luminance - mean;
        varianceSum += diff * diff;
      }
    }

    // Return standard deviation (contrast)
    return math.sqrt(varianceSum / count);
  }

  /// Calculate overall quality score (0.0-1.0)
  static double _calculateOverallQuality({
    required double faceSizeRatio,
    required double yaw,
    required double pitch,
    required double roll,
    required double blurScore,
    required double brightness,
    required double contrast,
    required QualityConfig config,
  }) {
    // Normalize each metric to 0.0-1.0 range
    final sizeScore = (faceSizeRatio / config.minFaceSizeRatio).clamp(0.0, 1.0);
    final yawScore = (1.0 - yaw / config.maxYaw).clamp(0.0, 1.0);
    final pitchScore = (1.0 - pitch / config.maxPitch).clamp(0.0, 1.0);
    final rollScore = (1.0 - roll / config.maxRoll).clamp(0.0, 1.0);
    final blurScoreNorm = (blurScore / config.minBlurScore).clamp(0.0, 1.0);

    // Brightness score (bell curve: best at middle)
    final optimalBrightness = (config.minBrightness + config.maxBrightness) / 2;
    final brightnessRange = config.maxBrightness - config.minBrightness;
    final brightnessDiff = (brightness - optimalBrightness).abs();
    final brightnessScore =
        (1.0 - brightnessDiff / (brightnessRange / 2)).clamp(0.0, 1.0);

    final contrastScore = (contrast / config.minContrast).clamp(0.0, 1.0);

    // Weighted average
    final overallScore = (sizeScore * 0.2 +
            yawScore * 0.15 +
            pitchScore * 0.1 +
            rollScore * 0.1 +
            blurScoreNorm * 0.25 +
            brightnessScore * 0.15 +
            contrastScore * 0.05)
        .clamp(0.0, 1.0);

    return overallScore;
  }
}

/// Quality configuration parameters
class QualityConfig {
  final double minFaceSizeRatio; // Minimum face width / image width
  final double maxYaw; // Max head rotation left/right (degrees)
  final double maxPitch; // Max head tilt up/down (degrees)
  final double maxRoll; // Max head tilt left/right (degrees)
  final double minBlurScore; // Minimum Laplacian variance
  final double minBrightness; // Minimum average brightness (0-255)
  final double maxBrightness; // Maximum average brightness (0-255)
  final double minContrast; // Minimum contrast (std dev)

  const QualityConfig({
    required this.minFaceSizeRatio,
    required this.maxYaw,
    required this.maxPitch,
    required this.maxRoll,
    required this.minBlurScore,
    required this.minBrightness,
    required this.maxBrightness,
    required this.minContrast,
  });
}

/// Quality check result
class QualityCheckResult {
  final bool passed;
  final List<QualityFailureReason> failures;
  final double qualityScore; // 0.0-1.0
  final QualityMetrics metrics;

  QualityCheckResult({
    required this.passed,
    required this.failures,
    required this.qualityScore,
    required this.metrics,
  });

  String get failureMessage {
    if (failures.isEmpty) return 'Quality check passed';

    return failures.map((f) => f.message).join(', ');
  }
}

/// Measured quality metrics
class QualityMetrics {
  final double faceSizeRatio;
  final double yaw;
  final double pitch;
  final double roll;
  final double blurScore;
  final double brightness;
  final double contrast;

  QualityMetrics({
    required this.faceSizeRatio,
    required this.yaw,
    required this.pitch,
    required this.roll,
    required this.blurScore,
    required this.brightness,
    required this.contrast,
  });
}

/// Quality failure reasons
enum QualityFailureReason {
  faceTooSmall,
  headNotFrontal,
  headTilted,
  headRolled,
  tooBlurry,
  tooDark,
  tooBright,
  lowContrast,
}

extension QualityFailureReasonExtension on QualityFailureReason {
  String get message {
    switch (this) {
      case QualityFailureReason.faceTooSmall:
        return 'وجهك صغير جداً، اقترب من الكاميرا';
      case QualityFailureReason.headNotFrontal:
        return 'حرك رأسك للأمام (لا تلتفت يميناً أو يساراً)';
      case QualityFailureReason.headTilted:
        return 'ارفع/اخفض رأسك قليلاً للأمام';
      case QualityFailureReason.headRolled:
        return 'عدّل ميل رأسك (لا تميل على الجانب)';
      case QualityFailureReason.tooBlurry:
        return 'الصورة غير واضحة، ثبّت هاتفك';
      case QualityFailureReason.tooDark:
        return 'الإضاءة ضعيفة جداً';
      case QualityFailureReason.tooBright:
        return 'الإضاءة قوية جداً';
      case QualityFailureReason.lowContrast:
        return 'الإضاءة غير كافية، حسّن الإضاءة';
    }
  }
}
