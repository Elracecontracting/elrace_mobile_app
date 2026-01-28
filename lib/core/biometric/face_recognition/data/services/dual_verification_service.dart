import 'dart:developer';
import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'face_embedding_storage_service.dart';
import 'firebase_face_service.dart';
import 'facenet_service.dart';
import 'face_detector_service.dart';
import '../../domain/entities/face_embedding.dart';
import '../../config/face_recognition_config.dart';

/// Dual Verification Service
/// 
/// Provides enhanced security by verifying faces against BOTH:
/// 1. Local encrypted storage (fast, offline-capable)
/// 2. Firebase cloud storage (authoritative, device-bound)
/// 
/// Security Features:
/// - Device binding enforcement
/// - Dual verification requirement
/// - Anti-fraud detection
/// - Comprehensive audit logging
class DualVerificationService {
  final FaceEmbeddingStorageService _localStorageService;
  final FirebaseFaceService _firebaseService;
  final FaceNetService _faceNetService;
  final FaceDetectorService _faceDetectorService;

  // Verification thresholds (stricter for dual verification)
  static const double _localThreshold = 0.60;      // Euclidean distance
  static const double _firebaseThreshold = 0.65;   // Cosine similarity
  static const double _strictThreshold = 0.70;     // For high-security mode

  DualVerificationService({
    FaceEmbeddingStorageService? localStorageService,
    FirebaseFaceService? firebaseService,
    FaceNetService? faceNetService,
    FaceDetectorService? faceDetectorService,
  }) : _localStorageService = localStorageService ?? FaceEmbeddingStorageService(),
       _firebaseService = firebaseService ?? FirebaseFaceService(),
       _faceNetService = faceNetService ?? FaceNetService(),
       _faceDetectorService = faceDetectorService ?? FaceDetectorService();

  /// Initialize all services
  Future<void> initialize() async {
    await _faceNetService.initialize();
    await _faceDetectorService.initialize();
    log('✅ DualVerificationService initialized');
  }

  // ==================== DUAL VERIFICATION ====================

  /// Perform comprehensive face verification against both local and Firebase
  /// 
  /// Returns [DualVerificationResult] with detailed verification info
  Future<DualVerificationResult> verifyFace({
    required String userId,
    required File imageFile,
    bool requireBothSources = true,
    bool enforceDeviceBinding = true,
    SecurityLevel securityLevel = SecurityLevel.standard,
  }) async {
    log('\n🔐 ========== DUAL FACE VERIFICATION ==========');
    log('👤 User ID: $userId');
    log('🔒 Security Level: $securityLevel');
    log('📱 Device Binding: $enforceDeviceBinding');

    try {
      // Step 1: Detect face in image
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetectorService.detectFacesFromInputImage(inputImage);

      if (faces.isEmpty) {
        return DualVerificationResult.failed(
          reason: 'No face detected in image',
          errorType: DualVerificationError.noFaceDetected,
        );
      }

      if (faces.length > 1) {
        return DualVerificationResult.failed(
          reason: 'Multiple faces detected',
          errorType: DualVerificationError.multipleFaces,
        );
      }

      final face = faces.first;

      // Step 2: Check liveness
      final livenessResult = _faceDetectorService.checkLiveness(
        face,
        eyeOpenThreshold: 0.15,
        maxHeadEulerAngleY: 25.0,
        maxHeadEulerAngleZ: 25.0,
      );

      if (!livenessResult) {
        return DualVerificationResult.failed(
          reason: 'Liveness check failed',
          errorType: DualVerificationError.livenessCheckFailed,
        );
      }

      // Step 3: Extract current embedding
      final currentEmbedding = await _faceNetService.getEmbeddingFromFile(
        imageFile,
        face.boundingBox,
      );

      if (currentEmbedding == null) {
        return DualVerificationResult.failed(
          reason: 'Could not extract face embedding',
          errorType: DualVerificationError.embeddingExtractionFailed,
        );
      }

      // Step 4: Check device binding first (if enabled)
      if (enforceDeviceBinding) {
        final deviceStatus = await _firebaseService.checkDeviceBinding(userId);
        
        if (deviceStatus.status == DeviceStatus.differentDevice) {
          log('⛔ Device binding check FAILED');
          return DualVerificationResult.failed(
            reason: 'Face registered on different device: ${deviceStatus.registeredDeviceId}',
            errorType: DualVerificationError.deviceMismatch,
            deviceBindingStatus: deviceStatus,
          );
        }
      }

      // Step 5: Verify against local storage
      final localResult = await _verifyLocal(userId, currentEmbedding, securityLevel);
      log('📱 Local verification: ${localResult.isVerified ? "✅ PASS" : "❌ FAIL"} (best: ${localResult.bestScore?.toStringAsFixed(4)})');

      // Step 6: Verify against Firebase
      final firebaseResult = await _firebaseService.verifyFace(
        userId: userId,
        currentEmbedding: currentEmbedding,
        threshold: _getThreshold(securityLevel),
        validateDevice: enforceDeviceBinding,
      );
      log('☁️ Firebase verification: ${firebaseResult.isVerified ? "✅ PASS" : "❌ FAIL"} (similarity: ${firebaseResult.similarity?.toStringAsFixed(4)})');

      // Step 7: Combine results based on requirements
      final combinedResult = _combineResults(
        localResult: localResult,
        firebaseResult: firebaseResult,
        requireBoth: requireBothSources,
        securityLevel: securityLevel,
      );

      log('🎯 Final Result: ${combinedResult.isVerified ? "✅ VERIFIED" : "❌ REJECTED"}');
      log('========================================\n');

      return combinedResult;

    } catch (e) {
      log('❌ Dual verification error: $e');
      return DualVerificationResult.failed(
        reason: 'Verification system error: $e',
        errorType: DualVerificationError.systemError,
      );
    }
  }

  /// Verify against local storage
  Future<LocalVerificationResult> _verifyLocal(
    String userId,
    List<double> currentEmbedding,
    SecurityLevel securityLevel,
  ) async {
    try {
      final storedEmbeddings = await _localStorageService.getEmbeddings(userId);
      
      if (storedEmbeddings.isEmpty) {
        return LocalVerificationResult(
          isVerified: false,
          hasStoredData: false,
          message: 'No local embeddings found',
        );
      }

      double bestDistance = double.infinity;
      String? bestLabel;

      for (final stored in storedEmbeddings) {
        final distance = _faceNetService.euclideanDistance(
          currentEmbedding,
          stored.embedding,
        );
        
        if (distance < bestDistance) {
          bestDistance = distance;
          bestLabel = stored.label;
        }
      }

      final threshold = _getLocalThreshold(securityLevel);
      final isVerified = bestDistance <= threshold;

      return LocalVerificationResult(
        isVerified: isVerified,
        hasStoredData: true,
        bestScore: bestDistance,
        bestMatchLabel: bestLabel,
        threshold: threshold,
        message: isVerified ? 'Local verification passed' : 'Local verification failed',
      );
    } catch (e) {
      return LocalVerificationResult(
        isVerified: false,
        hasStoredData: false,
        message: 'Local verification error: $e',
      );
    }
  }

  /// Get threshold based on security level
  double _getThreshold(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.relaxed:
        return 0.55;
      case SecurityLevel.standard:
        return 0.65;
      case SecurityLevel.strict:
        return 0.70;
      case SecurityLevel.maximum:
        return 0.80;
    }
  }

  /// Get local threshold based on security level
  double _getLocalThreshold(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.relaxed:
        return 0.70;
      case SecurityLevel.standard:
        return 0.60;
      case SecurityLevel.strict:
        return 0.50;
      case SecurityLevel.maximum:
        return 0.40;
    }
  }

  /// Combine local and Firebase results
  DualVerificationResult _combineResults({
    required LocalVerificationResult localResult,
    required FirebaseVerificationResult firebaseResult,
    required bool requireBoth,
    required SecurityLevel securityLevel,
  }) {
    // Handle error cases first
    if (firebaseResult.errorType == VerificationErrorType.deviceMismatch) {
      return DualVerificationResult.failed(
        reason: firebaseResult.message,
        errorType: DualVerificationError.deviceMismatch,
        localResult: localResult,
        firebaseResult: firebaseResult,
      );
    }

    if (firebaseResult.errorType == VerificationErrorType.noDataFound) {
      return DualVerificationResult.failed(
        reason: 'No face data in Firebase - registration required',
        errorType: DualVerificationError.noFirebaseData,
        localResult: localResult,
        firebaseResult: firebaseResult,
      );
    }

    // Check based on requirements
    bool finalVerified;
    String message;

    if (requireBoth) {
      // BOTH must pass
      if (!localResult.hasStoredData) {
        // No local data - rely only on Firebase
        finalVerified = firebaseResult.isVerified;
        message = finalVerified 
            ? 'Verified via Firebase (no local data)'
            : 'Firebase verification failed';
      } else {
        finalVerified = localResult.isVerified && firebaseResult.isVerified;
        message = finalVerified
            ? 'Both local and Firebase verification passed'
            : 'Dual verification failed';
      }
    } else {
      // EITHER can pass (less secure, for fallback scenarios)
      finalVerified = localResult.isVerified || firebaseResult.isVerified;
      message = finalVerified
          ? 'Verification passed'
          : 'All verification methods failed';
    }

    // Additional security check for maximum level
    if (securityLevel == SecurityLevel.maximum && finalVerified) {
      // Both scores must be above threshold
      if (firebaseResult.similarity != null && firebaseResult.similarity! < 0.75) {
        finalVerified = false;
        message = 'Maximum security threshold not met';
      }
    }

    return DualVerificationResult(
      isVerified: finalVerified,
      message: message,
      localResult: localResult,
      firebaseResult: firebaseResult,
      verificationMethod: _determineMethod(localResult, firebaseResult),
    );
  }

  VerificationMethod _determineMethod(
    LocalVerificationResult local,
    FirebaseVerificationResult firebase,
  ) {
    if (local.isVerified && firebase.isVerified) {
      return VerificationMethod.bothPassed;
    } else if (local.isVerified) {
      return VerificationMethod.localOnly;
    } else if (firebase.isVerified) {
      return VerificationMethod.firebaseOnly;
    }
    return VerificationMethod.nonePassed;
  }

  // ==================== REGISTRATION ====================

  /// Register face with dual storage (local + Firebase)
  Future<DualRegistrationResult> registerFace({
    required String userId,
    required String userName,
    required File imageFile,
    bool enforceDeviceBinding = true,
  }) async {
    log('\n📝 ========== DUAL FACE REGISTRATION ==========');
    log('👤 User ID: $userId');
    log('📱 Device Binding: $enforceDeviceBinding');

    try {
      // Step 1: Detect face
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetectorService.detectFacesFromInputImage(inputImage);

      if (faces.isEmpty || faces.length > 1) {
        return DualRegistrationResult(
          success: false,
          message: faces.isEmpty ? 'No face detected' : 'Multiple faces detected',
        );
      }

      final face = faces.first;

      // Step 2: Check face quality
      final quality = _faceDetectorService.getFaceQuality(face);
      if (quality < 0.5) {
        return DualRegistrationResult(
          success: false,
          message: 'Face quality too low. Please ensure good lighting.',
        );
      }

      // Step 3: Extract embedding
      final embedding = await _faceNetService.getEmbeddingFromFile(
        imageFile,
        face.boundingBox,
      );

      if (embedding == null) {
        return DualRegistrationResult(
          success: false,
          message: 'Could not extract face features',
        );
      }

      // Step 4: Check device binding - prevent re-registration from different device
      if (enforceDeviceBinding) {
        final deviceStatus = await _firebaseService.checkDeviceBinding(userId);
        
        if (deviceStatus.status == DeviceStatus.differentDevice) {
          return DualRegistrationResult(
            success: false,
            message: 'Face already registered on different device. Contact admin for transfer.',
            deviceStatus: deviceStatus,
          );
        }
      }

      // Step 5: Save to local storage
      final localEmbedding = FaceEmbedding(
        embedding: embedding,
        userId: userId,
        createdAt: DateTime.now(),
        label: 'primary',
      );
      await _localStorageService.saveEmbedding(localEmbedding);
      log('✅ Saved to local storage');

      // Step 6: Save to Firebase
      final firebaseSuccess = await _firebaseService.saveFaceData(
        userId: userId,
        userName: userName,
        faceEmbedding: embedding,
        faceFeatures: {}, // Add face features if needed
        enforceDeviceBinding: enforceDeviceBinding,
      );

      if (!firebaseSuccess) {
        // Rollback local storage
        await _localStorageService.deleteEmbeddings(userId);
        
        return DualRegistrationResult(
          success: false,
          message: 'Failed to save to Firebase. Registration cancelled.',
        );
      }

      log('✅ Saved to Firebase');
      log('========================================\n');

      return DualRegistrationResult(
        success: true,
        message: 'Face registered successfully on both local and cloud storage',
        localSaved: true,
        firebaseSaved: true,
      );

    } catch (e) {
      log('❌ Registration error: $e');
      return DualRegistrationResult(
        success: false,
        message: 'Registration error: $e',
      );
    }
  }

  // ==================== UTILITIES ====================

  /// Check if user has complete registration (both local + Firebase)
  Future<RegistrationStatus> checkRegistrationStatus(String userId) async {
    final hasLocal = await _localStorageService.hasEmbeddings(userId);
    final firebaseData = await _firebaseService.getFaceData(userId);
    final hasFirebase = firebaseData != null && 
                        firebaseData.faceEmbedding != null &&
                        firebaseData.faceEmbedding!.isNotEmpty;

    final deviceStatus = await _firebaseService.checkDeviceBinding(userId);

    return RegistrationStatus(
      hasLocalData: hasLocal,
      hasFirebaseData: hasFirebase,
      isComplete: hasLocal && hasFirebase,
      deviceStatus: deviceStatus,
    );
  }

  /// Sync local data with Firebase (if out of sync)
  Future<bool> syncWithFirebase(String userId) async {
    try {
      final firebaseData = await _firebaseService.getFaceData(userId);
      
      if (firebaseData?.faceEmbedding == null) {
        log('⚠️ No Firebase data to sync');
        return false;
      }

      // Delete existing local data
      await _localStorageService.deleteEmbeddings(userId);

      // Save Firebase data locally
      final embedding = FaceEmbedding(
        embedding: firebaseData!.faceEmbedding!,
        userId: userId,
        createdAt: DateTime.now(),
        label: 'synced_from_firebase',
      );

      await _localStorageService.saveEmbedding(embedding);
      log('✅ Synced Firebase data to local storage');
      
      return true;
    } catch (e) {
      log('❌ Sync error: $e');
      return false;
    }
  }

  /// Clear all data for user (both local + Firebase)
  Future<bool> clearAllData(String userId) async {
    try {
      await _localStorageService.deleteEmbeddings(userId);
      await _firebaseService.deleteFaceData(userId);
      return true;
    } catch (e) {
      log('❌ Clear data error: $e');
      return false;
    }
  }
}

// ==================== ENUMS & DATA MODELS ====================

/// Security levels for verification
enum SecurityLevel {
  relaxed,   // For testing/demo
  standard,  // Normal operations
  strict,    // High security areas
  maximum,   // Maximum security (both must pass with high scores)
}

/// Verification method used
enum VerificationMethod {
  bothPassed,
  localOnly,
  firebaseOnly,
  nonePassed,
}

/// Dual verification error types
enum DualVerificationError {
  noFaceDetected,
  multipleFaces,
  livenessCheckFailed,
  embeddingExtractionFailed,
  deviceMismatch,
  noLocalData,
  noFirebaseData,
  verificationFailed,
  systemError,
}

/// Result of local verification
class LocalVerificationResult {
  final bool isVerified;
  final bool hasStoredData;
  final double? bestScore;
  final String? bestMatchLabel;
  final double? threshold;
  final String message;

  LocalVerificationResult({
    required this.isVerified,
    required this.hasStoredData,
    this.bestScore,
    this.bestMatchLabel,
    this.threshold,
    required this.message,
  });
}

/// Combined result of dual verification
class DualVerificationResult {
  final bool isVerified;
  final String message;
  final DualVerificationError? errorType;
  final LocalVerificationResult? localResult;
  final FirebaseVerificationResult? firebaseResult;
  final DeviceBindingStatus? deviceBindingStatus;
  final VerificationMethod? verificationMethod;

  DualVerificationResult({
    required this.isVerified,
    required this.message,
    this.errorType,
    this.localResult,
    this.firebaseResult,
    this.deviceBindingStatus,
    this.verificationMethod,
  });

  factory DualVerificationResult.failed({
    required String reason,
    required DualVerificationError errorType,
    LocalVerificationResult? localResult,
    FirebaseVerificationResult? firebaseResult,
    DeviceBindingStatus? deviceBindingStatus,
  }) {
    return DualVerificationResult(
      isVerified: false,
      message: reason,
      errorType: errorType,
      localResult: localResult,
      firebaseResult: firebaseResult,
      deviceBindingStatus: deviceBindingStatus,
      verificationMethod: VerificationMethod.nonePassed,
    );
  }
}

/// Result of dual registration
class DualRegistrationResult {
  final bool success;
  final String message;
  final bool localSaved;
  final bool firebaseSaved;
  final DeviceBindingStatus? deviceStatus;

  DualRegistrationResult({
    required this.success,
    required this.message,
    this.localSaved = false,
    this.firebaseSaved = false,
    this.deviceStatus,
  });
}

/// Registration status across both storage systems
class RegistrationStatus {
  final bool hasLocalData;
  final bool hasFirebaseData;
  final bool isComplete;
  final DeviceBindingStatus deviceStatus;

  RegistrationStatus({
    required this.hasLocalData,
    required this.hasFirebaseData,
    required this.isComplete,
    required this.deviceStatus,
  });
}
