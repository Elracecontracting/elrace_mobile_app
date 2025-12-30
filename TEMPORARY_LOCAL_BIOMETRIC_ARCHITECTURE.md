# LOCAL FACE VERIFICATION FOR ATTENDANCE

## ✅ LOCAL PRODUCTION-READY FOR WORKPLACE USE (WITH KNOWN LIMITATIONS)

## 7. SCOPE & LIMITATIONS (ATTENDANCE)

Purpose: Record attendance/presence and reduce casual misuse. Not designed to resist determined spoofing.

What this does **not** prevent:

- Printed or screen photos shown to the camera
- Video replays or deepfakes presented to the camera
- 3D masks or sophisticated spoofs
- Shared/unlocked devices being used by others
- Rooted/jailbroken devices extracting local embeddings
- Memory inspection by malware on a compromised device
- Precise audit trails or non-repudiation

Operational notes:

- Use in supervised workplace settings to deter casual proxy check-ins.
- Consider pairing with physical presence controls (badge, turnstile) if higher assurance is needed.
- Thresholds are tuned for convenience; adjust after field testing.

Why local-only is acceptable here:

- Attendance is a low-risk, on-premise workflow; data stays on-device.
- No dependency on connectivity for check-in at entry points.
- Faster check-ins and simpler ops; privacy is improved by not uploading images.
  Step 1: SESSION INITIALIZATION
  ├─ Start attendance check-in session for userId
  ├─ Load stored embeddings from secure storage
  ├─ If no embeddings found: Return "NOT_REGISTERED"
  └─ Set session state: AWAITING_VERIFICATION_FACE

Step 2: CAMERA STREAM PROCESSING (Same as Enrollment Steps 2-5)
├─ Capture frame → ML Kit detection → Quality checks
├─ Crop & normalize → Extract embedding
└─ ⚠️ Collect 1-3 live embeddings for comparison

Step 3: BASIC PRESENCE CHECK (Same as Registration Step 7)
├─ Apply blink or motion check
└─ ⚠️ WARNING: This is easily spoofed

Step 4: LOCAL SIMILARITY MATCHING (CASUAL-MISUSE RESISTANCE ONLY)
├─ For each stored embedding:
│ ├─ Calculate distance (Euclidean or Cosine)
│ ├─ Example: cosineDistance = 1 - (dot(A,B) / (norm(A)\*norm(B)))
│ └─ Store distance value
├─ Find minimum distance (or maximum similarity)
├─ Apply threshold:
│ ├─ Cosine Distance < 0.4: MATCH (⚠️ adjust threshold)
│ ├─ Cosine Distance >= 0.4: NO_MATCH
│ └─ ⚠️ WARNING: Thresholds are NOT calibrated for security
└─ Return match result

Step 5: RESULT HANDLING
├─ If MATCH:
│ ├─ Log verification success (timestamp, metadata)
│ └─ Return success to UI
├─ If NO_MATCH:
│ ├─ Log verification failure
│ └─ Return failure to UI
└─ If SUSPICIOUS (e.g., multiple rapid failures):
├─ Implement basic rate limiting
└─ Lock out user temporarily (optional)

Step 6: CLEANUP
├─ Clear camera frames
├─ Clear extracted embeddings from memory
└─ End verification session

```

---

## 3. FLUTTER FOLDER STRUCTURE

```

lib/
├── core/
│ ├── biometric/
│ │ ├── domain/
│ │ │ ├── entities/
│ │ │ │ ├── face_embedding.dart # Data class for embeddings
│ │ │ │ ├── verification_result.dart # Result model
│ │ │ │ └── biometric_session.dart # Session state
│ │ │ ├── repositories/
│ │ │ │ └── i_face_verification_repository.dart # ★ Interface
│ │ │ └── use_cases/
│ │ │ ├── enroll_face_use_case.dart
│ │ │ └── verify_face_use_case.dart
│ │ ├── data/
│ │ │ ├── repositories/
│ │ │ │ ├── local_face_verification_repository.dart # ★ LOCAL (TEMPORARY)
│ │ │ │ └── remote_face_verification_repository.dart # ★ FUTURE (stub)
│ │ │ ├── data_sources/
│ │ │ │ ├── face_detection_data_source.dart # ML Kit wrapper
│ │ │ │ ├── face_embedding_data_source.dart # TFLite wrapper
│ │ │ │ └── secure_storage_data_source.dart # FlutterSecureStorage wrapper
│ │ │ └── models/
│ │ │ └── face_embedding_model.dart # JSON serialization
│ │ ├── presentation/
│ │ │ ├── registration/
│ │ │ │ ├── employee_face_registration_screen.dart
│ │ │ │ └── registration_state.dart (or cubit)
│ │ │ └── attendance_checkin/
│ │ │ ├── attendance_checkin_screen.dart
│ │ │ └── attendance_checkin_state.dart (or cubit)
│ │ ├── utils/
│ │ │ ├── face_preprocessing.dart # Crop/resize/normalize
│ │ │ ├── similarity_calculator.dart # Distance functions
│ │ │ └── liveness_checker.dart # Basic blink/motion
│ │ └── biometric_di.dart # Dependency injection
│ └── config/
│ └── feature_flags.dart # ★ Feature flag for disabling in prod
├── assets/
│ └── ml_models/
│ └── mobilefacenet.tflite # Face embedding model
└── main.dart

````

### Key Files Explained

| File                                       | Purpose                                  | Migration Impact             |
| ------------------------------------------ | ---------------------------------------- | ---------------------------- |
| `i_face_verification_repository.dart`      | **Abstraction layer** - defines contract | NO CHANGE when migrating     |
| `local_face_verification_repository.dart`  | **TEMPORARY** local implementation       | REPLACED in migration        |
| `remote_face_verification_repository.dart` | **FUTURE** server-side implementation    | ACTIVATED in migration       |
| `feature_flags.dart`                       | Controls local biometric availability    | Set to `false` in production |

---

## 4. CORE INTERFACES & CLASSES

### 4.1 Domain Layer (Abstraction)

#### `IFaceVerificationRepository` (Interface)

```dart
// ★ THIS INTERFACE NEVER CHANGES - LOCAL AND REMOTE BOTH IMPLEMENT IT

abstract class IFaceVerificationRepository {
  /// Register an employee face for attendance
  /// Local: Stores embeddings locally (attendance scope)
  /// Remote (optional future): send to central store
  Future<EnrollmentResult> registerEmployeeFace({
    required String userId,
    required List<FaceEmbedding> embeddings,
    Map<String, dynamic>? metadata,
  });

  /// Check-in attendance against stored data
  /// Local: Matches locally using cosine/euclidean distance
  /// Remote (optional): centralized check
  Future<VerificationResult> checkInAttendance({
    required String userId,
    required List<FaceEmbedding> liveEmbeddings,
  });

  /// Delete all face data for a user
  Future<void> deleteFaceData(String userId);

  /// Check if user has enrolled face data
  Future<bool> isEnrolled(String userId);
}
````

#### `FaceEmbedding` (Entity)

```dart
class FaceEmbedding {
  final List<double> vector;     // e.g., 128 or 512 dimensions
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  // ⚠️ WARNING: Never include raw image data

  FaceEmbedding({
    required this.vector,
    required this.timestamp,
    this.metadata,
  }) : assert(vector.isNotEmpty, 'Embedding vector cannot be empty');

  // Normalization (L2)
  List<double> get normalized {
    final magnitude = math.sqrt(vector.fold(0.0, (sum, val) => sum + val * val));
    return vector.map((v) => v / magnitude).toList();
  }
}
```

#### `VerificationResult` (Entity)

```dart
enum VerificationStatus {
  success,          // Face matched
  failure,          // Face did not match
  notEnrolled,      // No face data found
  livenessFailure,  // Failed liveness check (⚠️ weak check)
  error,            // Technical error
}

class VerificationResult {
  final VerificationStatus status;
  final double? confidenceScore;    // 0.0 - 1.0
  final String? errorMessage;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  // ⚠️ WARNING: This is NOT a security audit trail
  // In production, server-side logging is required

  VerificationResult({
    required this.status,
    this.confidenceScore,
    this.errorMessage,
    required this.timestamp,
    this.metadata,
  });

  bool get isSuccess => status == VerificationStatus.success;
}
```

### 4.2 Data Layer (Implementation)

#### `LocalFaceVerificationRepository` (Attendance Local Production)

```dart
// Local attendance implementation (prevents casual misuse only)
// Not spoof-resistant; suitable for on-premise attendance contexts

class LocalFaceVerificationRepository implements IFaceVerificationRepository {
  final SecureStorageDataSource _secureStorage;
  final SimilarityCalculator _similarityCalculator;

  // ⚠️ DEVELOPMENT ONLY THRESHOLD - NOT CALIBRATED
  static const double _matchThreshold = 0.4; // Cosine distance (tune per site)

  LocalFaceVerificationRepository({
    required SecureStorageDataSource secureStorage,
    required SimilarityCalculator similarityCalculator,
  })  : _secureStorage = secureStorage,
        _similarityCalculator = similarityCalculator;

  @override
  Future<EnrollmentResult> registerEmployeeFace({
    required String userId,
    required List<FaceEmbedding> embeddings,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final storageKey = _getStorageKey(userId);

      final data = {
        'version': '1.0',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'embeddings': embeddings.map((e) => e.toJson()).toList(),
        'metadata': {
          ...?metadata,
          'registration_type': 'LOCAL_ATTENDANCE',
          'note': 'Prevents casual misuse; not spoof-resistant',
        },
      };

      await _secureStorage.write(storageKey, jsonEncode(data));

      return EnrollmentResult.success(
        message: 'Employee face registered locally for attendance.',
      );
    } catch (e) {
      return EnrollmentResult.failure(errorMessage: e.toString());
    }
  }

  @override
  Future<VerificationResult> checkInAttendance({
    required String userId,
    required List<FaceEmbedding> liveEmbeddings,
  }) async {
    try {
      // 1. Load stored embeddings
      final storedData = await _loadStoredEmbeddings(userId);
      if (storedData == null) {
        return VerificationResult(
          status: VerificationStatus.notEnrolled,
          timestamp: DateTime.now(),
        );
      }

      final storedEmbeddings = storedData['embeddings'] as List<FaceEmbedding>;

      // 2. ⚠️ LOCAL MATCHING - NOT SERVER-SIDE
      double bestScore = double.infinity;

      for (final stored in storedEmbeddings) {
        for (final live in liveEmbeddings) {
          final distance = _similarityCalculator.cosineDistance(
            stored.normalized,
            live.normalized,
          );

          if (distance < bestScore) {
            bestScore = distance;
          }
        }
      }

      // 3. Apply threshold
      final isMatch = bestScore < _matchThreshold;

      return VerificationResult(
        status: isMatch ? VerificationStatus.success : VerificationStatus.failure,
        confidenceScore: isMatch ? (1.0 - bestScore) : null,
        timestamp: DateTime.now(),
        metadata: {
          'matching_type': 'LOCAL_COSINE_DISTANCE',
          'threshold': _matchThreshold,
        },
      );

    } catch (e) {
      return VerificationResult(
        status: VerificationStatus.error,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  @override
  Future<void> deleteFaceData(String userId) async {
    final storageKey = _getStorageKey(userId);
    await _secureStorage.delete(storageKey);
  }

  @override
  Future<bool> isEnrolled(String userId) async {
    final data = await _loadStoredEmbeddings(userId);
    return data != null;
  }

  // Private helpers
  String _getStorageKey(String userId) => 'face_embedding_$userId';

  Future<Map<String, dynamic>?> _loadStoredEmbeddings(String userId) async {
    final storageKey = _getStorageKey(userId);
    final jsonString = await _secureStorage.read(storageKey);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}
```

#### `RemoteFaceVerificationRepository` (Optional Future)

```dart
// Optional future implementation for central attendance aggregation

class RemoteFaceVerificationRepository implements IFaceVerificationRepository {
  final BiometricApiClient _apiClient; // e.g., iProov, Onfido, AWS Rekognition

  @override
  Future<EnrollmentResult> registerEmployeeFace({
    required String userId,
    required List<FaceEmbedding> embeddings,
    Map<String, dynamic>? metadata,
  }) async {
    // Send embeddings to central attendance service (if added later)

    final response = await _apiClient.post(
      '/biometric/enroll',
      body: {
        'user_id': userId,
        'embeddings': embeddings.map((e) => e.vector).toList(),
        'metadata': metadata,
      },
    );

    return EnrollmentResult.fromJson(response.data);
  }

  @override
  Future<VerificationResult> checkInAttendance({
    required String userId,
    required List<FaceEmbedding> liveEmbeddings,
  }) async {
    // Server-side attendance check (matching & policy handled remotely)

    final response = await _apiClient.post(
      '/biometric/verify',
      body: {
        'user_id': userId,
        'live_embeddings': liveEmbeddings.map((e) => e.vector).toList(),
      },
    );

    return VerificationResult.fromJson(response.data);
  }

  // ... other methods
}
```

---

## 5. LOCAL MATCHING LOGIC (DETAILED)

### 5.1 Similarity Calculator

```dart
class SimilarityCalculator {
  /// Calculates Euclidean distance between two embedding vectors
  /// Lower distance = more similar
  /// ⚠️ WARNING: This is a basic similarity metric
  /// ⚠️ NOT calibrated for security purposes
  double euclideanDistance(List<double> a, List<double> b) {
    assert(a.length == b.length, 'Vectors must have same dimension');

    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }

    return math.sqrt(sum);
  }

  /// Calculates Cosine distance (1 - cosine similarity)
  /// Range: 0.0 (identical) to 2.0 (opposite)
  /// ⚠️ PREFERRED for face embeddings
  double cosineDistance(List<double> a, List<double> b) {
    assert(a.length == b.length, 'Vectors must have same dimension');

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    normA = math.sqrt(normA);
    normB = math.sqrt(normB);

    if (normA == 0.0 || normB == 0.0) {
      return 2.0; // Maximum distance
    }

    final cosineSimilarity = dotProduct / (normA * normB);
    return 1.0 - cosineSimilarity;
  }

  /// ⚠️ WARNING: Threshold selection is CRITICAL but NOT calibrated here
  /// Typical ranges (cosine distance):
  /// - 0.0 - 0.3: Strong match (low false reject, higher false accept)
  /// - 0.3 - 0.6: Moderate zone (tune based on testing)
  /// - 0.6+: No match
  ///
  /// ⚠️ In production: Thresholds must be calibrated on diverse datasets
  /// ⚠️ Factors: demographics, lighting, device cameras, etc.
}
```

### 5.2 Threshold Selection Strategy (Development)

```dart
class BiometricThresholdConfig {
  // ⚠️ DEVELOPMENT ONLY - NOT PRODUCTION-CALIBRATED

  static const double relaxedThreshold = 0.5;   // Higher false accept
  static const double balancedThreshold = 0.4;  // Balanced (use this)
  static const double strictThreshold = 0.3;    // Higher false reject

  static double get currentThreshold {
    // ⚠️ In dev: Use balanced
    // ✓ In production: Server determines threshold based on:
    //   - User demographics
    //   - Transaction risk level
    //   - Historical fraud patterns
    return balancedThreshold;
  }

  // ⚠️ WARNING: This is NOT adaptive
  // ✓ Future: Server-side adaptive thresholds based on ML models
}
```

---

## 6. MIGRATION PLAN: LOCAL → BANK-GRADE

### 6.1 Migration Steps

```
Phase 1: PREPARATION (Before Migration)
├─ 1. Audit all usage of LocalFaceVerificationRepository
├─ 2. Implement RemoteFaceVerificationRepository (stub with real API)
├─ 3. Add feature flag: FeatureFlags.useBankGradeBiometrics
├─ 4. Update dependency injection to support both implementations
└─ 5. Write integration tests for RemoteFaceVerificationRepository

Phase 2: PARALLEL OPERATION (Testing)
├─ 1. Enable remote repository for 5% of test users
├─ 2. Run both local and remote verification in parallel
├─ 3. Compare results (for validation, not decision-making)
├─ 4. Monitor server performance, latency, success rates
└─ 5. Fix any discrepancies

Phase 3: GRADUAL ROLLOUT
├─ 1. Increase remote repository usage to 25% → 50% → 100%
├─ 2. Migrate existing local enrollments to server:
│  ├─ Option A: Force re-enrollment (recommended)
│  └─ Option B: Upload existing embeddings (⚠️ not recommended)
├─ 3. Disable local repository via feature flag
└─ 4. Remove local repository code in next release

Phase 4: CLEANUP
├─ 1. Delete LocalFaceVerificationRepository class
├─ 2. Remove local matching logic (SimilarityCalculator)
├─ 3. Remove TFLite model from app bundle (if server-side inference)
└─ 4. Update documentation to remove "DEV ONLY" warnings
```

### 6.2 Code Changes Required

**File:** `biometric_di.dart`

```dart
// BEFORE (Local Only):
void setupBiometricDI() {
  final getIt = GetIt.instance;

  getIt.registerLazySingleton<IFaceVerificationRepository>(
    () => LocalFaceVerificationRepository(...),
  );
}

// AFTER (Feature Flag Controlled):
void setupBiometricDI() {
  final getIt = GetIt.instance;

  getIt.registerLazySingleton<IFaceVerificationRepository>(
    () {
      if (FeatureFlags.useBankGradeBiometrics) {
        return RemoteFaceVerificationRepository(
          apiClient: getIt<BiometricApiClient>(),
        );
      } else {
        // ⚠️ Fallback for legacy users or dev testing
        return LocalFaceVerificationRepository(...);
      }
    },
  );
}
```

**No changes required in:**

- UI layer (EnrollmentScreen, VerificationScreen)
- Use cases (EnrollFaceUseCase, VerifyFaceUseCase)
- Business logic

This demonstrates the power of the repository pattern.

### 6.3 Data Migration Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                   DATA MIGRATION OPTIONS                         │
└─────────────────────────────────────────────────────────────────┘

Option 1: FORCE RE-ENROLLMENT (RECOMMENDED ✓)
├─ Pros:
│  ├─ Clean break from local data
│  ├─ Server controls enrollment quality
│  └─ User undergoes proper liveness checks
├─ Cons:
│  └─ User friction (must re-enroll)
└─ Implementation:
   ├─ On login: Check if server has biometric data
   ├─ If not: Show "Please re-enroll for enhanced security"
   └─ Guide through new enrollment flow

Option 2: UPLOAD EXISTING EMBEDDINGS (NOT RECOMMENDED ⚠️)
├─ Pros:
│  └─ No user friction
├─ Cons:
│  ├─ Local embeddings may be compromised
│  ├─ No liveness check during enrollment
│  ├─ Potential legal/compliance issues
│  └─ Security team will reject this
└─ Implementation:
   ├─ Load local embeddings
   ├─ Upload to server with metadata: "MIGRATED_FROM_LOCAL"
   └─ Server applies stricter thresholds to migrated data

✓ RECOMMENDED: Option 1 (Force Re-Enrollment)
```

---

## 7. WHAT THIS DOES NOT PROTECT AGAINST

### 7.1 Critical Vulnerabilities (Local Implementation)

```
┌────────────────────────────────────────────────────────────────────┐
│          ⚠️⚠️⚠️ SECURITY LIMITATIONS ⚠️⚠️⚠️                      │
└────────────────────────────────────────────────────────────────────┘

✗ PRESENTATION ATTACKS (Spoofing):
  ├─ High-quality printed photos
  ├─ Digital photos on another device
  ├─ Video replay attacks
  ├─ 3D masks
  ├─ Deepfakes
  └─ WHY: No depth sensing, no texture analysis, weak liveness

✗ BIOMETRIC DATA THEFT:
  ├─ Root/jailbroken devices can extract embeddings from secure storage
  ├─ Malware can intercept embeddings in memory
  ├─ Embeddings stored locally are vulnerable to device compromise
  └─ WHY: Client-side storage, no hardware-backed security modules (HSM)

✗ REPLAY ATTACKS:
  ├─ Attacker captures network traffic (if any)
  ├─ Replays verification requests with stolen embeddings
  └─ WHY: No server-side challenge-response, no session tokens

✗ CREDENTIAL STUFFING:
  ├─ Attacker uses stolen device to bypass biometrics
  └─ WHY: Device compromise = full access

✗ FALSE ACCEPTANCE ATTACKS:
  ├─ Threshold not calibrated for security
  ├─ No statistical validation of false accept rate (FAR)
  └─ WHY: Development thresholds, not production-tuned

✗ TEMPLATE REVERSAL:
  ├─ Some embedding models are reversible (can reconstruct face)
  ├─ Embeddings stored locally can be used across apps
  └─ WHY: No cancellable biometrics, no template protection

✗ REGULATORY COMPLIANCE:
  ├─ GDPR: No proper consent flow, no data processing agreement
  ├─ PSD2: Does not meet Strong Customer Authentication (SCA)
  ├─ CCPA: No user data rights implementation
  └─ WHY: Local implementation, no audit trail

✗ INSIDER THREATS:
  ├─ Developer with device access can extract biometric data
  └─ WHY: No separation of concerns, no key management

✗ SIDE-CHANNEL ATTACKS:
  ├─ Timing attacks on similarity calculation
  ├─ Memory dumps during verification
  └─ WHY: No constant-time operations, no memory protection
```

### 7.2 Liveness Detection Limitations

```
┌────────────────────────────────────────────────────────────────────┐
│       ⚠️ "LIVENESS" CHECKS ARE NOT ANTI-SPOOFING ⚠️              │
└────────────────────────────────────────────────────────────────────┘

Blink Detection:
├─ ✓ Detects: Static photos without eyes
├─ ✗ Does NOT detect:
│  ├─ Photos with eyes closed then opened (simulating blink)
│  ├─ Videos of person blinking
│  ├─ Cutout photos with moving eyes
│  └─ Animated GIFs
└─ Why: Only tracks eye landmark changes, no depth/texture analysis

Motion Consistency:
├─ ✓ Detects: Static images that don't move
├─ ✗ Does NOT detect:
│  ├─ Videos with natural motion
│  ├─ Photos moved by hand (simulating head movement)
│  └─ Morphing attacks
└─ Why: Only tracks bounding box position, no 3D analysis

Challenge-Response (e.g., "Smile"):
├─ ✓ Detects: Static photos
├─ ✗ Does NOT detect:
│  ├─ Pre-recorded videos with smiles
│  ├─ Deepfake videos responding to challenges
│  └─ Accomplice attacks (real person following instructions)
└─ Why: Predictable challenges, no randomness, no depth sensing

✓ Real Liveness Detection Requires:
  ├─ Passive liveness (no user action required)
  ├─ Texture analysis (skin pores, micro-movements)
  ├─ 3D depth sensing (infrared, structured light)
  ├─ Challenge-response with server-side randomness
  ├─ Video analysis for motion continuity
  └─ Machine learning models trained on spoofing attacks
```

### 7.3 Comparison Table

| Security Feature       | Local (DEV)             | Bank-Grade (PROD)       |
| ---------------------- | ----------------------- | ----------------------- |
| **Face Detection**     | ✓ ML Kit                | ✓ SDK-based             |
| **Liveness Detection** | ⚠️ Weak (blink/motion)  | ✓ Passive + Active      |
| **Anti-Spoofing**      | ✗ None                  | ✓ Multi-modal           |
| **Embedding Storage**  | ⚠️ Local secure storage | ✓ HSM / Server-side     |
| **Matching**           | ⚠️ Local (cosine)       | ✓ Server-side           |
| **Threshold**          | ⚠️ Hardcoded            | ✓ Adaptive / Risk-based |
| **Audit Trail**        | ✗ None                  | ✓ Tamper-proof logs     |
| **Data Encryption**    | ⚠️ OS-level             | ✓ End-to-end + At rest  |
| **Compliance**         | ✗ Not compliant         | ✓ GDPR/PSD2/CCPA        |
| **Attack Resistance**  | ✗ Low                   | ✓ High                  |
| **False Accept Rate**  | ⚠️ Unknown              | ✓ < 0.001% (calibrated) |

---

## 8. FEATURE FLAGS

### 8.1 Feature Flag Implementation

```dart
// config/feature_flags.dart

class FeatureFlags {
  static const bool enableLocalBiometrics = bool.fromEnvironment(
    'ENABLE_LOCAL_BIOMETRICS',
    defaultValue: true, // Local is acceptable for attendance
  );

  // Optional future: centralized attendance repository
  static const bool useBankGradeBiometrics = bool.fromEnvironment(
    'ENABLE_BANK_GRADE_BIOMETRICS',
    defaultValue: false,
  );

  // Build-time check
  static void validateProductionConfig() {
    // For attendance, local is allowed; no fail-fast required.
  }
}

// main.dart
void main() {
  FeatureFlags.validateProductionConfig(); // ⚠️ Check on startup
  runApp(MyApp());
}
```

### 8.2 UI Banner

```dart
// presentation/enrollment/enrollment_screen.dart

Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Face Enrollment')),
    body: Column(
      children: [
        // Show context banner
        if (FeatureFlags.enableLocalBiometrics) ...[
          Container(
            color: Colors.blueGrey.shade900,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Face verification is used only to record attendance.',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ... rest of UI
      ],
    ),
  );
}
```

---

## 9. RECOMMENDED THIRD-PARTY SOLUTIONS (FUTURE)

When migrating to bank-grade biometrics, consider these vendors:

### 9.1 KYC/Biometric SDKs

| Provider            | Strengths                                    | Use Case                        |
| ------------------- | -------------------------------------------- | ------------------------------- |
| **iProov**          | Genuine Presence Assurance, strong liveness  | Banking, fintech, high-security |
| **Onfido**          | Full KYC suite, document + face verification | Identity verification           |
| **Jumio**           | Real-time liveness, fraud detection          | Onboarding, compliance          |
| **AWS Rekognition** | Cloud-based, scalable                        | General face verification       |
| **FaceTec**         | 3D liveness, strong anti-spoofing            | Mobile banking                  |
| **Veriff**          | AI-powered, fast verification                | Crypto, fintech                 |

### 9.2 Selection Criteria

```
✓ Passive liveness detection (no user action required)
✓ ISO/IEC 30107-3 compliance (anti-spoofing)
✓ NIST FRVT benchmark performance
✓ GDPR/CCPA compliance
✓ Audit trails and logging
✓ Multi-factor authentication support
✓ SDK size and performance impact
✓ Regional data residency options
✓ Cost (per verification)
```

---

## 10. CODE WARNINGS & MARKERS

All code in the local implementation MUST include these markers:

```dart
// ⚠️⚠️⚠️ TEMPORARY LOCAL IMPLEMENTATION - NOT BANK-GRADE ⚠️⚠️⚠️
// TODO(security): Replace with RemoteFaceVerificationRepository before production
// TODO(compliance): This does NOT meet PSD2/GDPR requirements
// MIGRATION: See TEMPORARY_LOCAL_BIOMETRIC_ARCHITECTURE.md Section 6

class LocalFaceVerificationRepository implements IFaceVerificationRepository {
  // ...
}
```

---

## 11. TESTING STRATEGY

### 11.1 Unit Tests (Local Repository)

```dart
// test/biometric/local_face_verification_repository_test.dart

void main() {
  group('LocalFaceVerificationRepository (DEV ONLY)', () {
    test('⚠️ enrollFace stores embeddings locally', () async {
      // Given
      final repo = LocalFaceVerificationRepository(...);
      final embeddings = [FaceEmbedding(vector: [0.1, 0.2, ...])];

      // When
      final result = await repo.enrollFace(
        userId: 'test_user',
        embeddings: embeddings,
      );

      // Then
      expect(result.isSuccess, true);
      expect(result.message, contains('DEV ONLY')); // ⚠️ Marker check
    });

    test('⚠️ verifyFace matches using cosine distance', () async {
      // Given
      await repo.enrollFace(userId: 'test_user', embeddings: [storedEmbedding]);

      // When
      final result = await repo.verifyFace(
        userId: 'test_user',
        liveEmbeddings: [matchingEmbedding],
      );

      // Then
      expect(result.status, VerificationStatus.success);
      expect(result.metadata['matching_type'], 'LOCAL_COSINE_DISTANCE'); // ⚠️
    });
  });
}
```

### 11.2 Integration Tests (Mock Remote Repository)

```dart
// test/biometric/remote_face_verification_repository_test.dart

void main() {
  group('RemoteFaceVerificationRepository (FUTURE)', () {
    test('✓ enrollFace sends data to server', () async {
      // Given
      final mockApiClient = MockBiometricApiClient();
      final repo = RemoteFaceVerificationRepository(apiClient: mockApiClient);

      // When
      await repo.enrollFace(userId: 'test_user', embeddings: [embedding]);

      // Then
      verify(mockApiClient.post('/biometric/enroll', body: any)).called(1);
    });
  });
}
```

---

## 12. PERFORMANCE CONSIDERATIONS

### 12.1 Local Implementation

| Operation               | Expected Time | Optimization                              |
| ----------------------- | ------------- | ----------------------------------------- |
| Face detection (ML Kit) | 50-100ms      | Process every 100-200ms (not every frame) |
| TFLite inference        | 30-80ms       | Use GPU delegate if available             |
| Embedding extraction    | 30-80ms       | Cache model in memory                     |
| Similarity calculation  | <5ms          | Vectorized operations                     |
| Secure storage read     | 10-50ms       | Cache in-memory (with encryption)         |
| Secure storage write    | 20-100ms      | Batch writes if multiple embeddings       |

**Total enrollment time:** 5-10 seconds (3-5 samples)  
**Total verification time:** 1-3 seconds

### 12.2 Memory Management

```dart
// ⚠️ CRITICAL: Clear sensitive data from memory immediately after use

class BiometricMemoryManager {
  static void clearEmbedding(List<double> embedding) {
    // Overwrite with zeros
    for (int i = 0; i < embedding.length; i++) {
      embedding[i] = 0.0;
    }
  }

  static void clearImageData(Uint8List imageData) {
    // Overwrite with zeros
    imageData.fillRange(0, imageData.length, 0);
  }
}

// Usage after verification:
try {
  final result = await verifyFace(liveEmbeddings);
  return result;
} finally {
  // ⚠️ Always clear sensitive data
  for (final embedding in liveEmbeddings) {
    BiometricMemoryManager.clearEmbedding(embedding.vector);
  }
}
```

---

## 13. DEPENDENCIES

### 13.1 Required Flutter Packages

```yaml
# pubspec.yaml

dependencies:
  # Camera access
  camera: ^0.10.0

  # ML Kit Face Detection
  google_mlkit_face_detection: ^0.7.0

  # TFLite inference
  tflite_flutter: ^0.10.0

  # Secure storage
  flutter_secure_storage: ^9.0.0

  # State management
  flutter_bloc: ^8.1.0 # or provider, riverpod

  # Dependency injection
  get_it: ^7.6.0

  # Utils
  equatable: ^2.0.5

dev_dependencies:
  # Testing
  mockito: ^5.4.0
  flutter_test:
    sdk: flutter
```

### 13.2 ML Model

```
assets/ml_models/mobilefacenet.tflite
Size: ~4MB
Input: 112x112x3 (RGB)
Output: 128-dimensional embedding
License: Apache 2.0 (verify before use)

⚠️ Download from trusted source or train your own
⚠️ Validate model hash/checksum
⚠️ Test on diverse faces before deployment
```

---

## 14. EMPLOYEE NOTICE & DATA DELETION (LIGHTWEIGHT)

- Show a simple notice: “Face verification is used only to record attendance. Embeddings stay on this device. You can request deletion.”
- Provide a delete action that clears local embeddings for the employee.
- No regulatory claims; this is a workplace attendance aid.

---

## 15. DEPLOYMENT CHECKLIST

### 15.1 Pre-Production Validation

```
□ LocalFaceVerificationRepository is enabled (default for attendance)
□ Optional: RemoteFaceVerificationRepository stub compiles behind flag
□ Employee notice is displayed (“Face verification is used only to record attendance”)
□ Delete/clear attendance embeddings action is available
□ Threshold tuned after field testing at site
□ Basic performance check: detection + embedding latency acceptable on target devices
□ Optional: screen protection is enabled to deter casual shoulder surfing
□ Team briefed on limitations (photos/videos can bypass)
```

---

## 16. SUMMARY

### What We Built (Local Attendance)

- ✓ ML Kit face detection
- ✓ TFLite embedding extraction
- ✓ Local secure storage for embeddings
- ⚠️ Basic presence checks (not spoof-resistant)
- ✓ Local cosine distance matching
- ✓ Repository pattern with optional remote path

### What We Did NOT Build

- ✗ Spoof/deepfake resistance
- ✗ Centralized audit trails
- ✗ Regulatory guarantees
- ✗ Multi-factor security

### Optional Future

1. Implement `RemoteFaceVerificationRepository` for central aggregation (if needed)
2. Toggle via feature flag per site
3. Keep local as default for on-prem attendance

### Key Takeaway

```
┌─────────────────────────────────────────────────────────────────┐
│  Local face verification suitable for workplace attendance.    │
│  Prevents casual proxy check-ins; not designed for spoofing.   │
│  Keep data on-device; add remote aggregation only if needed.   │
└─────────────────────────────────────────────────────────────────┘
```

---

## APPENDIX A: GLOSSARY

| Term                    | Definition                                                      |
| ----------------------- | --------------------------------------------------------------- |
| **Embedding**           | Mathematical vector representation of a face (e.g., 128 floats) |
| **FAR**                 | False Accept Rate - % of imposters incorrectly accepted         |
| **FRR**                 | False Reject Rate - % of genuine users incorrectly rejected     |
| **Liveness Detection**  | Verifying user is physically present (not photo/video)          |
| **Anti-Spoofing**       | Techniques to detect presentation attacks                       |
| **Attendance Check-In** | Face-based presence confirmation for workplace                  |
| **Embedding**           | Mathematical vector representation of a face (e.g., 128 floats) |
| **Cosine Distance**     | 1 - cosine similarity; lower is closer match                    |
| **Presence Check**      | Basic eye/motion sanity check (not spoof-resistant)             |
| **Local-Only**          | Processing and storage happen on-device                         |

---

## APPENDIX B: REFERENCES

- ML Kit Face Detection docs
- TensorFlow Lite (MobileFaceNet) usage guidelines
- Android Keystore / iOS Keychain secure storage basics

---

**Document Control:**

- Version: 1.0
- Last Updated: December 29, 2025
- Next Review: As needed for attendance policy updates
- Owner: Engineering Team
- Classification: Internal - Workplace Attendance
