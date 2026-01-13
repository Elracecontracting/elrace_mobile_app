/// Enhanced Face Recognition Configuration
///
/// Centralized configuration for all face recognition parameters
class FaceRecognitionConfig {
  // ==================== ENROLLMENT CONFIG ====================

  /// Number of samples to collect during enrollment
  static const int enrollmentSamples = 3;

  /// Labels for enrollment samples
  static const List<String> enrollmentLabels = ['front', 'left15', 'right15'];

  /// Instructions for each enrollment step (Arabic)
  static const List<String> enrollmentInstructions = [
    'انظر مباشرة للكاميرا',
    'لف رأسك قليلاً لليسار',
    'لف رأسك قليلاً لليمين',
  ];

  // ==================== VERIFICATION CONFIG ====================

  /// Enable active challenge liveness (recommended: true)
  static const bool enableActiveChallenge = true;

  /// Enable multi-frame liveness check
  static const bool enableMultiFrameLiveness = true;

  /// Timeout for verification challenge (seconds)
  static const int verificationTimeoutSeconds = 6;

  // ==================== MATCHING CONFIG ====================

  /// Use cosine similarity (true) or Euclidean distance (false)
  static const bool useCosineSimilarity = true;

  /// Cosine similarity threshold (0.0 - 1.0, higher = stricter)
  /// Recommended: 0.55 - 0.65
  static const double cosineSimilarityThreshold = 0.55;

  /// Euclidean distance threshold (lower = stricter)
  /// Recommended: 0.8 - 1.0
  static const double euclideanDistanceThreshold = 0.8;

  // ==================== QUALITY CONFIG ====================

  /// Enrollment quality config (stricter)
  static const double enrollmentMinFaceSize = 0.25; // 25% of image
  static const double enrollmentMaxYaw = 15.0;
  static const double enrollmentMaxPitch = 15.0;
  static const double enrollmentMaxRoll = 10.0;
  static const double enrollmentMinBlur = 150.0;
  static const double enrollmentMinBrightness = 80.0;
  static const double enrollmentMaxBrightness = 200.0;
  static const double enrollmentMinContrast = 40.0;

  /// Verification quality config (more lenient)
  static const double verificationMinFaceSize = 0.20; // 20% of image
  static const double verificationMaxYaw = 25.0;
  static const double verificationMaxPitch = 20.0;
  static const double verificationMaxRoll = 15.0;
  static const double verificationMinBlur = 100.0;
  static const double verificationMinBrightness = 60.0;
  static const double verificationMaxBrightness = 220.0;
  static const double verificationMinContrast = 30.0;

  // ==================== LIVENESS CONFIG ====================

  /// Minimum frames for multi-frame liveness
  static const int livenessMinFrames = 10;

  /// Maximum frames for multi-frame liveness
  static const int livenessMaxFrames = 20;

  /// Timeout for multi-frame liveness (seconds)
  static const int livenessTimeoutSeconds = 2;

  // ==================== PERFORMANCE CONFIG ====================

  /// Enable warm isolate (recommended: false until asset loading issue is fixed)
  /// Note: Currently disabled due to ServicesBinding not available in isolate
  static const bool useWarmIsolate = false;

  /// Throttling duration between inferences (milliseconds)
  static const int throttlingMs = 300;

  /// Cache duration for last embedding (seconds)
  static const int cacheDurationSeconds = 2;

  // ==================== SECURITY CONFIG ====================

  /// Maximum retry attempts before cooldown
  static const int maxRetryAttempts = 3;

  /// Cooldown duration after max retries (seconds)
  static const int cooldownDurationSeconds = 60;

  /// Enable device binding (optional security)
  static const bool enableDeviceBinding = false;

  /// Enable root/jailbreak detection warning
  static const bool enableRootDetection = true;

  // ==================== STORAGE CONFIG ====================

  /// Model version identifier
  static const String modelVersion = 'mobilefacenet_v1';

  /// Embedding dimensions
  static const int embeddingDimensions = 192;

  /// Alignment version
  static const int alignmentVersion = 1;

  /// Liveness version
  static const int livenessVersion = 2;

  // ==================== HELPERS ====================

  /// Get threshold based on similarity method
  static double get matchingThreshold => useCosineSimilarity
      ? cosineSimilarityThreshold
      : euclideanDistanceThreshold;

  /// Get current configuration summary
  static Map<String, dynamic> getConfigSummary() {
    return {
      'enrollment': {
        'samples': enrollmentSamples,
        'minFaceSize': enrollmentMinFaceSize,
        'maxYaw': enrollmentMaxYaw,
        'minBlur': enrollmentMinBlur,
      },
      'verification': {
        'activeChallenge': enableActiveChallenge,
        'timeout': verificationTimeoutSeconds,
        'minFaceSize': verificationMinFaceSize,
      },
      'matching': {
        'method': useCosineSimilarity ? 'cosine' : 'euclidean',
        'threshold': matchingThreshold,
      },
      'security': {
        'maxRetries': maxRetryAttempts,
        'cooldown': cooldownDurationSeconds,
        'deviceBinding': enableDeviceBinding,
      },
      'performance': {
        'warmIsolate': useWarmIsolate,
        'throttling': throttlingMs,
      },
    };
  }
}
