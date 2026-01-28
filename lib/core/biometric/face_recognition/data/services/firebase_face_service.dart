import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:math' as math;

/// Firebase Face Service
/// 
/// Handles all Firebase-related face recognition operations including:
/// - Face data storage and retrieval from Firestore
/// - Device binding and validation
/// - Cross-device face verification
/// - Security logging and audit trail
class FirebaseFaceService {
  final FirebaseFirestore _firestore;
  final DeviceInfoPlugin _deviceInfo;
  
  // Collection names
  static const String _usersCollection = 'users';
  static const String _faceAuditCollection = 'face_audit_logs';
  
  FirebaseFaceService({
    FirebaseFirestore? firestore,
    DeviceInfoPlugin? deviceInfo,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  // ==================== DEVICE MANAGEMENT ====================

  /// Get unique device identifier
  Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id; // Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios';
      }
      return 'unknown_device';
    } catch (e) {
      log('❌ Error getting device ID: $e');
      return 'error_device_id';
    }
  }

  /// Get device info for logging
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'device_id': info.id,
          'model': info.model,
          'manufacturer': info.manufacturer,
          'android_version': info.version.release,
          'sdk_int': info.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'device_id': info.identifierForVendor ?? 'unknown',
          'model': info.model,
          'system_version': info.systemVersion,
          'name': info.name,
        };
      }
      return {'platform': 'unknown'};
    } catch (e) {
      return {'platform': 'error', 'error': e.toString()};
    }
  }

  // ==================== FACE DATA MANAGEMENT ====================

  /// Get face data from Firebase for a user
  Future<FirebaseFaceData?> getFaceData(String userId) async {
    try {
      log('🔍 Firebase: Getting face data for user: $userId');
      
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        log('❌ Firebase: No face data found for user: $userId');
        return null;
      }

      final data = doc.data()!;
      log('✅ Firebase: Face data retrieved for user: $userId');
      
      return FirebaseFaceData.fromJson(data, userId);
    } catch (e) {
      log('❌ Firebase error getting face data: $e');
      return null;
    }
  }

  /// Save face data to Firebase with device binding
  Future<bool> saveFaceData({
    required String userId,
    required String userName,
    required List<double> faceEmbedding,
    required Map<String, dynamic> faceFeatures,
    String? imageBase64,
    bool enforceDeviceBinding = true,
  }) async {
    try {
      log('💾 Firebase: Saving face data for user: $userId');
      
      final deviceId = await getDeviceId();
      final deviceInfo = await getDeviceInfo();
      final now = DateTime.now();

      // Check existing registration
      final existingData = await getFaceData(userId);
      
      if (existingData != null && enforceDeviceBinding) {
        // Check if trying to register from a different device
        if (existingData.registeredDeviceId != null &&
            existingData.registeredDeviceId != deviceId) {
          log('⚠️ Firebase: Device mismatch! Existing: ${existingData.registeredDeviceId}, Current: $deviceId');
          
          // Log this security event
          await _logSecurityEvent(
            userId: userId,
            eventType: 'DEVICE_MISMATCH_REGISTRATION',
            deviceId: deviceId,
            details: {
              'existing_device': existingData.registeredDeviceId,
              'attempted_device': deviceId,
              'blocked': true,
            },
          );
          
          return false; // Block registration from different device
        }
      }

      // Prepare data to save
      final faceData = {
        'id': userId,
        'name': userName,
        'uuid': userId,
        'image': imageBase64,
        'faceEmbedding': faceEmbedding,
        'faceFeatures': faceFeatures,
        'registeredOn': now.millisecondsSinceEpoch,
        'registeredDeviceId': deviceId,
        'registeredDeviceInfo': deviceInfo,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        'securityVersion': 2, // Track security version for future migrations
      };

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .set(faceData, SetOptions(merge: false)); // Replace completely

      // Log successful registration
      await _logSecurityEvent(
        userId: userId,
        eventType: 'FACE_REGISTERED',
        deviceId: deviceId,
        details: {
          'embedding_size': faceEmbedding.length,
          'has_image': imageBase64 != null,
        },
      );

      log('✅ Firebase: Face data saved successfully for user: $userId');
      return true;
    } catch (e) {
      log('❌ Firebase error saving face data: $e');
      return false;
    }
  }

  // ==================== VERIFICATION ====================

  /// Verify face embedding against Firebase stored data
  /// Returns verification result with confidence score
  Future<FirebaseVerificationResult> verifyFace({
    required String userId,
    required List<double> currentEmbedding,
    double threshold = 0.60,
    bool validateDevice = true,
  }) async {
    try {
      log('🔐 Firebase: Verifying face for user: $userId');
      
      final faceData = await getFaceData(userId);
      
      if (faceData == null) {
        return FirebaseVerificationResult(
          isVerified: false,
          errorType: VerificationErrorType.noDataFound,
          message: 'No face data found in Firebase',
        );
      }

      if (faceData.faceEmbedding == null || faceData.faceEmbedding!.isEmpty) {
        return FirebaseVerificationResult(
          isVerified: false,
          errorType: VerificationErrorType.noEmbedding,
          message: 'No face embedding stored',
        );
      }

      // Validate device if enabled
      if (validateDevice) {
        final currentDeviceId = await getDeviceId();
        
        if (faceData.registeredDeviceId != null &&
            faceData.registeredDeviceId != currentDeviceId) {
          log('⚠️ Firebase: Device mismatch during verification!');
          
          await _logSecurityEvent(
            userId: userId,
            eventType: 'DEVICE_MISMATCH_VERIFICATION',
            deviceId: currentDeviceId,
            details: {
              'registered_device': faceData.registeredDeviceId,
              'verification_device': currentDeviceId,
            },
          );
          
          return FirebaseVerificationResult(
            isVerified: false,
            errorType: VerificationErrorType.deviceMismatch,
            message: 'Face was registered on a different device',
            registeredDeviceId: faceData.registeredDeviceId,
          );
        }
      }

      // Calculate similarity
      final similarity = cosineSimilarity(
        currentEmbedding,
        faceData.faceEmbedding!,
      );

      final euclidean = euclideanDistance(
        currentEmbedding,
        faceData.faceEmbedding!,
      );

      log('📊 Firebase: Cosine similarity: $similarity, Euclidean: $euclidean');

      final isVerified = similarity >= threshold;

      // Log verification attempt
      await _logSecurityEvent(
        userId: userId,
        eventType: isVerified ? 'VERIFICATION_SUCCESS' : 'VERIFICATION_FAILED',
        deviceId: await getDeviceId(),
        details: {
          'cosine_similarity': similarity,
          'euclidean_distance': euclidean,
          'threshold': threshold,
          'passed': isVerified,
        },
      );

      return FirebaseVerificationResult(
        isVerified: isVerified,
        similarity: similarity,
        euclideanDistance: euclidean,
        threshold: threshold,
        message: isVerified ? 'Face verified successfully' : 'Face verification failed',
      );
    } catch (e) {
      log('❌ Firebase verification error: $e');
      return FirebaseVerificationResult(
        isVerified: false,
        errorType: VerificationErrorType.systemError,
        message: 'Verification error: $e',
      );
    }
  }

  // ==================== DEVICE BINDING ====================

  /// Check if user's face is registered on a different device
  Future<DeviceBindingStatus> checkDeviceBinding(String userId) async {
    try {
      final faceData = await getFaceData(userId);
      final currentDeviceId = await getDeviceId();

      if (faceData == null) {
        return DeviceBindingStatus(
          status: DeviceStatus.notRegistered,
          message: 'No face registration found',
        );
      }

      if (faceData.registeredDeviceId == null) {
        return DeviceBindingStatus(
          status: DeviceStatus.noDeviceBinding,
          message: 'Face registered without device binding',
        );
      }

      if (faceData.registeredDeviceId == currentDeviceId) {
        return DeviceBindingStatus(
          status: DeviceStatus.sameDevice,
          message: 'Same device as registration',
          registeredDeviceId: faceData.registeredDeviceId,
        );
      }

      return DeviceBindingStatus(
        status: DeviceStatus.differentDevice,
        message: 'Face registered on different device',
        registeredDeviceId: faceData.registeredDeviceId,
        currentDeviceId: currentDeviceId,
      );
    } catch (e) {
      return DeviceBindingStatus(
        status: DeviceStatus.error,
        message: 'Error checking device binding: $e',
      );
    }
  }

  /// Transfer face registration to new device (requires admin approval)
  Future<bool> requestDeviceTransfer({
    required String userId,
    required String reason,
  }) async {
    try {
      final currentDeviceId = await getDeviceId();
      final deviceInfo = await getDeviceInfo();

      await _firestore.collection('device_transfer_requests').add({
        'userId': userId,
        'requestedDeviceId': currentDeviceId,
        'deviceInfo': deviceInfo,
        'reason': reason,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      await _logSecurityEvent(
        userId: userId,
        eventType: 'DEVICE_TRANSFER_REQUESTED',
        deviceId: currentDeviceId,
        details: {'reason': reason},
      );

      return true;
    } catch (e) {
      log('❌ Error requesting device transfer: $e');
      return false;
    }
  }

  // ==================== SECURITY LOGGING ====================

  /// Log security events for audit trail
  Future<void> _logSecurityEvent({
    required String userId,
    required String eventType,
    required String deviceId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _firestore.collection(_faceAuditCollection).add({
        'userId': userId,
        'eventType': eventType,
        'deviceId': deviceId,
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'platform': Platform.isAndroid ? 'android' : 'ios',
      });
    } catch (e) {
      log('⚠️ Failed to log security event: $e');
    }
  }

  /// Get recent security events for a user
  Future<List<Map<String, dynamic>>> getSecurityEvents(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_faceAuditCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      log('❌ Error getting security events: $e');
      return [];
    }
  }

  // ==================== MATH HELPERS ====================

  /// Calculate cosine similarity between two embeddings
  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Calculate Euclidean distance between two embeddings
  double euclideanDistance(List<double> a, List<double> b) {
    if (a.length != b.length) return double.infinity;

    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }

    return math.sqrt(sum);
  }

  // ==================== CLEANUP ====================

  /// Delete face data for a user (use with caution!)
  Future<bool> deleteFaceData(String userId) async {
    try {
      final deviceId = await getDeviceId();
      
      await _firestore.collection(_usersCollection).doc(userId).delete();

      await _logSecurityEvent(
        userId: userId,
        eventType: 'FACE_DATA_DELETED',
        deviceId: deviceId,
        details: {},
      );

      return true;
    } catch (e) {
      log('❌ Error deleting face data: $e');
      return false;
    }
  }
}

// ==================== DATA MODELS ====================

/// Face data retrieved from Firebase
class FirebaseFaceData {
  final String id;
  final String? name;
  final String? uuid;
  final String? image;
  final List<double>? faceEmbedding;
  final Map<String, dynamic>? faceFeatures;
  final int? registeredOn;
  final String? registeredDeviceId;
  final Map<String, dynamic>? registeredDeviceInfo;
  final int? securityVersion;

  FirebaseFaceData({
    required this.id,
    this.name,
    this.uuid,
    this.image,
    this.faceEmbedding,
    this.faceFeatures,
    this.registeredOn,
    this.registeredDeviceId,
    this.registeredDeviceInfo,
    this.securityVersion,
  });

  factory FirebaseFaceData.fromJson(Map<String, dynamic> json, String id) {
    return FirebaseFaceData(
      id: id,
      name: json['name'] as String?,
      uuid: json['uuid'] as String?,
      image: json['image'] as String?,
      faceEmbedding: json['faceEmbedding'] != null
          ? List<double>.from(json['faceEmbedding'])
          : null,
      faceFeatures: json['faceFeatures'] as Map<String, dynamic>?,
      registeredOn: json['registeredOn'] as int?,
      registeredDeviceId: json['registeredDeviceId'] as String?,
      registeredDeviceInfo: json['registeredDeviceInfo'] as Map<String, dynamic>?,
      securityVersion: json['securityVersion'] as int?,
    );
  }
}

/// Verification result from Firebase
class FirebaseVerificationResult {
  final bool isVerified;
  final double? similarity;
  final double? euclideanDistance;
  final double? threshold;
  final VerificationErrorType? errorType;
  final String message;
  final String? registeredDeviceId;

  FirebaseVerificationResult({
    required this.isVerified,
    this.similarity,
    this.euclideanDistance,
    this.threshold,
    this.errorType,
    required this.message,
    this.registeredDeviceId,
  });
}

/// Verification error types
enum VerificationErrorType {
  noDataFound,
  noEmbedding,
  deviceMismatch,
  systemError,
}

/// Device binding status
class DeviceBindingStatus {
  final DeviceStatus status;
  final String message;
  final String? registeredDeviceId;
  final String? currentDeviceId;

  DeviceBindingStatus({
    required this.status,
    required this.message,
    this.registeredDeviceId,
    this.currentDeviceId,
  });
}

/// Device status enum
enum DeviceStatus {
  notRegistered,
  noDeviceBinding,
  sameDevice,
  differentDevice,
  error,
}
