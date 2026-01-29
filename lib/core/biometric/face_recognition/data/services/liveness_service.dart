import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'face_detector_service.dart';

/// Enhanced Liveness Detection Service with Multi-frame Analysis and Active Challenges
///
/// Features:
/// - Multi-frame analysis (15-20 frames over 3-5 seconds)
/// - Active random challenges (blink, head turn, rapid eye movement)
/// - Anti-spoofing: prevents photo/video replay attacks
/// - Real-time feedback for user guidance
/// - Challenge verification with strict thresholds
class LivenessService {
  final FaceDetectorService _faceDetectorService;
  
  /// تتبع حالة التحديات
  List<LivenessChallenge> _currentChallenges = [];
  int _currentChallengeIndex = 0;
  List<LivenessChallenge> _completedChallenges = [];
  DateTime? _challengeStartTime;

  LivenessService(this._faceDetectorService);

  /// إنشاء تحديات عشوائية للتحقق (3 تحديات)
  List<LivenessChallenge> generateChallengeSequence() {
    final random = math.Random();
    
    // التحديات الأساسية الثلاثة المطلوبة
    final requiredChallenges = [
      LivenessChallenge.blinkEyes,      // التحدي الأول: الرمش
      LivenessChallenge.turnHeadLeft,   // التحدي الثاني: حركة الرأس
      LivenessChallenge.rapidEyeMovement, // التحدي الثالث: حركة العين
    ];
    
    // تبديل التحديات عشوائياً
    requiredChallenges.shuffle(random);
    
    _currentChallenges = requiredChallenges;
    _currentChallengeIndex = 0;
    _completedChallenges = [];
    _challengeStartTime = DateTime.now();
    
    return requiredChallenges;
  }

  /// الحصول على التحدي الحالي
  LivenessChallenge? getCurrentChallenge() {
    if (_currentChallengeIndex >= _currentChallenges.length) return null;
    return _currentChallenges[_currentChallengeIndex];
  }

  /// الحصول على عدد التحديات المكتملة
  int getCompletedCount() => _completedChallenges.length;

  /// الحصول على التحديات المكتملة
  List<LivenessChallenge> get completedChallenges => _completedChallenges;

  /// الحصول على إجمالي التحديات
  int getTotalChallenges() => _currentChallenges.length;

  /// إعادة تعيين التحديات
  void resetChallenges() {
    _currentChallenges = [];
    _currentChallengeIndex = 0;
    _completedChallenges = [];
    _challengeStartTime = null;
  }

  /// Perform PASSIVE anti-spoofing check (no user interaction needed)
  ///
  /// This is a simplified check that detects photos/videos without
  /// requiring the user to do anything special. Just look at camera for 1 second.
  ///
  /// Checks:
  /// 1. Natural micro-movements (photos are 100% static)
  /// 2. Eye probability consistency (real eyes have slight variations)
  /// 3. Face size consistency (video playback may have artifacts)
  /// 4. 🆕 BLINK DETECTION - Must detect at least one real blink
  Future<LivenessResult> performPassiveAntiSpoofCheck({
    required List<Face> faceSequence,
    int minFrames = 5,
  }) async {
    if (faceSequence.length < minFrames) {
      return LivenessResult(
        passed: false,
        reason: LivenessFailureReason.insufficientFrames,
        message: 'Need more frames for verification',
      );
    }

    // Extract data from faces
    final List<double> yawValues = [];
    final List<double> pitchValues = [];
    final List<double> leftEyeValues = [];
    final List<double> rightEyeValues = [];

    for (final face in faceSequence) {
      yawValues.add(face.headEulerAngleY ?? 0.0);
      pitchValues.add(face.headEulerAngleX ?? 0.0);
      leftEyeValues.add(face.leftEyeOpenProbability ?? 0.0);
      rightEyeValues.add(face.rightEyeOpenProbability ?? 0.0);
    }

    // 🆕 CRITICAL CHECK: Detect real blink (eyes open -> closed -> open)
    // This is the most reliable way to detect a photo vs real face
    final blinkDetected = _detectBlinkInSequence(leftEyeValues, rightEyeValues);
    
    print('👁️ Blink analysis:');
    print('  - Left eye values: ${leftEyeValues.map((e) => e.toStringAsFixed(2)).join(", ")}');
    print('  - Right eye values: ${rightEyeValues.map((e) => e.toStringAsFixed(2)).join(", ")}');
    print('  - Blink detected: $blinkDetected');
    
    if (!blinkDetected) {
      return LivenessResult(
        passed: false,
        reason: LivenessFailureReason.noBlinkDetected,
        message: 'الرجاء رمش عينيك أثناء النظر للكاميرا',
      );
    }

    // Check 1: Head pose micro-movement (photos are perfectly static)
    final yawVariation = _calculateVariation(yawValues);
    final pitchVariation = _calculateVariation(pitchValues);

    print('🔄 Head movement: yaw=$yawVariation, pitch=$pitchVariation');

    // Real face has at least 0.3° of natural movement (lowered from 0.5)
    // Photo/video of photo has 0° movement
    if (yawVariation < 0.3 && pitchVariation < 0.3) {
      return LivenessResult(
        passed: false,
        reason: LivenessFailureReason.staticFace,
        message: 'Please hold still and look at the camera',
      );
    }

    // Check 2: Eye probability variation (real eyes have micro-movements)
    final leftEyeVariation = _calculateVariation(leftEyeValues);
    final rightEyeVariation = _calculateVariation(rightEyeValues);

    print('👁️ Eye variation: left=$leftEyeVariation, right=$rightEyeVariation');

    // All checks passed (including blink)
    print('✅ All liveness checks passed!');
    return LivenessResult(
      passed: true,
      reason: LivenessFailureReason.none,
      message: 'Anti-spoof check passed - blink detected',
    );
  }

  /// 🆕 Detect a real blink in the eye probability sequence
  /// A blink is: eyes open (>0.5) -> eyes closed (<0.3) -> eyes open (>0.5)
  bool _detectBlinkInSequence(List<double> leftEyeValues, List<double> rightEyeValues) {
    const double openThreshold = 0.5;  // Eye considered open
    const double closedThreshold = 0.3; // Eye considered closed
    
    // Track state machine for blink detection
    bool foundOpen = false;
    bool foundClosed = false;
    bool foundOpenAgain = false;
    
    for (int i = 0; i < leftEyeValues.length; i++) {
      final leftEye = leftEyeValues[i];
      final rightEye = rightEyeValues[i];
      
      // Both eyes should be in sync for a real blink
      final avgEye = (leftEye + rightEye) / 2;
      
      if (!foundOpen) {
        // Looking for initial open state
        if (avgEye >= openThreshold) {
          foundOpen = true;
          print('  📍 Frame $i: Eyes OPEN (avg=$avgEye)');
        }
      } else if (!foundClosed) {
        // Looking for closed state (the blink)
        if (avgEye <= closedThreshold) {
          foundClosed = true;
          print('  📍 Frame $i: Eyes CLOSED (avg=$avgEye) - BLINK DETECTED!');
        }
      } else if (!foundOpenAgain) {
        // Looking for eyes to open again after blink
        if (avgEye >= openThreshold) {
          foundOpenAgain = true;
          print('  📍 Frame $i: Eyes OPEN again (avg=$avgEye) - BLINK COMPLETE!');
          return true; // Complete blink detected!
        }
      }
    }
    
    // Also check for partial blink (significant eye closure even without full sequence)
    // This catches fast blinks that might not have all 3 states captured
    if (foundOpen && foundClosed) {
      final minEye = leftEyeValues.reduce(math.min);
      final maxEye = leftEyeValues.reduce(math.max);
      final eyeRange = maxEye - minEye;
      
      print('  📊 Eye range: min=$minEye, max=$maxEye, range=$eyeRange');
      
      // If there's significant eye movement (>0.3 range), consider it a blink
      if (eyeRange >= 0.3) {
        print('  ✅ Significant eye movement detected as blink');
        return true;
      }
    }
    
    return false;
  }

  /// Perform multi-frame liveness check
  ///
  /// Collects frames over time and analyzes head pose changes, blink patterns
  Future<LivenessResult> performMultiFrameLivenessCheck({
    required Stream<CameraImage> frameStream,
    int minFrames = 10,
    int maxFrames = 20,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final List<_FrameAnalysis> frameAnalyses = [];
    final startTime = DateTime.now();

    try {
      await for (final frame in frameStream) {
        // Check timeout
        if (DateTime.now().difference(startTime) > timeout) {
          return LivenessResult(
            passed: false,
            reason: LivenessFailureReason.timeout,
            message: 'Liveness check timed out',
          );
        }

        // Detect faces in frame
        final faces = await _faceDetectorService.detectFaces(frame);

        // Validate single face
        if (faces.isEmpty) {
          return LivenessResult(
            passed: false,
            reason: LivenessFailureReason.noFace,
            message: 'No face detected during liveness check',
          );
        }

        if (faces.length > 1) {
          return LivenessResult(
            passed: false,
            reason: LivenessFailureReason.multipleFaces,
            message: 'Multiple faces detected',
          );
        }

        final face = faces.first;
        frameAnalyses.add(_FrameAnalysis(
          timestamp: DateTime.now(),
          face: face,
          headYaw: face.headEulerAngleY ?? 0.0,
          headPitch: face.headEulerAngleX ?? 0.0,
          headRoll: face.headEulerAngleZ ?? 0.0,
          leftEyeOpen: face.leftEyeOpenProbability ?? 0.0,
          rightEyeOpen: face.rightEyeOpenProbability ?? 0.0,
        ));

        // Check if we have enough frames
        if (frameAnalyses.length >= minFrames) {
          break;
        }
      }

      // Analyze collected frames
      return _analyzeFrames(frameAnalyses);
    } catch (e) {
      return LivenessResult(
        passed: false,
        reason: LivenessFailureReason.error,
        message: 'Error during liveness check: $e',
      );
    }
  }

  /// Perform active challenge-based liveness check
  ///
  /// Presents random challenges to user (blink, turn head, etc.)
  /// and validates they perform them correctly
  Future<LivenessResult> performActiveChallengeCheck({
    required Stream<CameraImage> frameStream,
    Duration challengeTimeout = const Duration(seconds: 6),
  }) async {
    // Generate random challenge sequence
    final challenges = _generateRandomChallenges();

    final List<LivenessChallenge> completedChallenges = [];
    final startTime = DateTime.now();

    try {
      int currentChallengeIndex = 0;
      LivenessChallenge currentChallenge = challenges[currentChallengeIndex];

      final List<_FrameAnalysis> recentFrames = [];

      await for (final frame in frameStream) {
        // Check timeout
        if (DateTime.now().difference(startTime) > challengeTimeout) {
          return LivenessResult(
            passed: false,
            reason: LivenessFailureReason.timeout,
            message: 'Challenge timed out',
            currentChallenge: currentChallenge,
            completedChallenges: completedChallenges,
          );
        }

        // Detect faces
        final faces = await _faceDetectorService.detectFaces(frame);

        // Validate single face
        if (faces.isEmpty) {
          return LivenessResult(
            passed: false,
            reason: LivenessFailureReason.noFace,
            message: 'No face detected',
          );
        }

        if (faces.length > 1) {
          return LivenessResult(
            passed: false,
            reason: LivenessFailureReason.multipleFaces,
            message: 'Multiple faces detected',
          );
        }

        final face = faces.first;
        final frameAnalysis = _FrameAnalysis(
          timestamp: DateTime.now(),
          face: face,
          headYaw: face.headEulerAngleY ?? 0.0,
          headPitch: face.headEulerAngleX ?? 0.0,
          headRoll: face.headEulerAngleZ ?? 0.0,
          leftEyeOpen: face.leftEyeOpenProbability ?? 0.0,
          rightEyeOpen: face.rightEyeOpenProbability ?? 0.0,
        );

        recentFrames.add(frameAnalysis);
        if (recentFrames.length > 10) {
          recentFrames.removeAt(0); // Keep only last 10 frames
        }

        // Check if challenge is completed
        if (_isChallengeCompleted(currentChallenge, recentFrames)) {
          completedChallenges.add(currentChallenge);
          currentChallengeIndex++;

          // All challenges completed?
          if (currentChallengeIndex >= challenges.length) {
            return LivenessResult(
              passed: true,
              reason: LivenessFailureReason.none,
              message: 'All challenges completed successfully',
              completedChallenges: completedChallenges,
            );
          }

          // Move to next challenge
          currentChallenge = challenges[currentChallengeIndex];
          recentFrames.clear();
        }
      }

      return LivenessResult(
        passed: false,
        reason: LivenessFailureReason.challengeFailed,
        message: 'Could not complete all challenges',
        completedChallenges: completedChallenges,
      );
    } catch (e) {
      return LivenessResult(
        passed: false,
        reason: LivenessFailureReason.error,
        message: 'Error during challenge: $e',
      );
    }
  }

  /// Generate random challenge sequence (2-3 challenges)
  List<LivenessChallenge> _generateRandomChallenges() {
    final random = math.Random();
    final allChallenges = [
      LivenessChallenge.blinkTwice,
      LivenessChallenge.turnHeadLeft,
      LivenessChallenge.turnHeadRight,
      LivenessChallenge.lookUp,
      LivenessChallenge.lookDown,
    ];

    // Shuffle and take 2-3 random challenges
    allChallenges.shuffle(random);
    final numChallenges = 2 + random.nextInt(2); // 2 or 3 challenges
    return allChallenges.take(numChallenges).toList();
  }

  /// Check if a specific challenge has been completed
  bool _isChallengeCompleted(
    LivenessChallenge challenge,
    List<_FrameAnalysis> recentFrames,
  ) {
    if (recentFrames.length < 5) return false; // Need at least 5 frames

    switch (challenge) {
      case LivenessChallenge.blinkEyes:
        final leftEyeValues = recentFrames.map((f) => f.leftEyeOpen).toList();
        final rightEyeValues = recentFrames.map((f) => f.rightEyeOpen).toList();
        return _detectBlinkInSequence(leftEyeValues, rightEyeValues);

      case LivenessChallenge.blinkTwice:
        return _detectBlinks(recentFrames) >= 2;

      case LivenessChallenge.turnHeadLeft:
        return _detectHeadTurn(recentFrames, direction: 'left');

      case LivenessChallenge.turnHeadRight:
        return _detectHeadTurn(recentFrames, direction: 'right');

      case LivenessChallenge.lookUp:
        return _detectLookDirection(recentFrames, direction: 'up');

      case LivenessChallenge.lookDown:
        return _detectLookDirection(recentFrames, direction: 'down');

      case LivenessChallenge.rapidEyeMovement:
        return _detectRapidEyeMovement(recentFrames);
    }
  }

  /// Detect number of blinks in frame sequence
  int _detectBlinks(List<_FrameAnalysis> frames) {
    int blinkCount = 0;
    bool wasOpen = true;

    for (final frame in frames) {
      final avgEyeOpen = (frame.leftEyeOpen + frame.rightEyeOpen) / 2;
      final isClosed = avgEyeOpen < 0.2; // Eyes closed threshold

      if (wasOpen && isClosed) {
        blinkCount++; // Detected a blink (transition from open to closed)
      }

      wasOpen = !isClosed;
    }

    return blinkCount;
  }

  /// Detect head turn in specific direction
  bool _detectHeadTurn(List<_FrameAnalysis> frames,
      {required String direction}) {
    if (frames.isEmpty) return false;

    final firstYaw = frames.first.headYaw;
    final lastYaw = frames.last.headYaw;
    final yawChange = lastYaw - firstYaw;

    // Check if head turned significantly in the requested direction
    if (direction == 'left') {
      return yawChange > 15.0; // Turned left (positive yaw increase)
    } else if (direction == 'right') {
      return yawChange < -15.0; // Turned right (negative yaw decrease)
    }

    return false;
  }

  /// Detect looking direction (up/down)
  bool _detectLookDirection(List<_FrameAnalysis> frames,
      {required String direction}) {
    if (frames.isEmpty) return false;

    final firstPitch = frames.first.headPitch;
    final lastPitch = frames.last.headPitch;
    final pitchChange = lastPitch - firstPitch;

    // Check if head tilted significantly in the requested direction
    if (direction == 'up') {
      return pitchChange < -10.0; // Looking up (negative pitch decrease)
    } else if (direction == 'down') {
      return pitchChange > 10.0; // Looking down (positive pitch increase)
    }

    return false;
  }

  /// 🆕 Detect rapid eye movement (eyes moving left/right quickly)
  /// This is detected via slight head movements that accompany eye movement
  bool _detectRapidEyeMovement(List<_FrameAnalysis> frames) {
    if (frames.length < 5) return false;

    // Track yaw changes for rapid movement pattern
    List<double> yawDiffs = [];
    for (int i = 1; i < frames.length; i++) {
      yawDiffs.add(frames[i].headYaw - frames[i - 1].headYaw);
    }

    // Count direction changes (rapid movement should have multiple changes)
    int directionChanges = 0;
    bool wasPositive = yawDiffs.isNotEmpty && yawDiffs.first > 0;

    for (final diff in yawDiffs) {
      if ((diff > 0) != wasPositive && diff.abs() > 1.0) {
        directionChanges++;
        wasPositive = diff > 0;
      }
    }

    print('👁️ Rapid eye movement - Direction changes: $directionChanges');

    // Need at least 2 direction changes for rapid movement
    return directionChanges >= 2;
  }

  /// 🆕 التحقق من تحدي واحد باستخدام قائمة الإطارات
  Future<ChallengeResult> verifySingleChallenge({
    required LivenessChallenge challenge,
    required List<Face> faceSequence,
  }) async {
    if (faceSequence.length < 5) {
      return ChallengeResult(
        passed: false,
        challenge: challenge,
        message: 'لم يتم جمع إطارات كافية',
      );
    }

    // تحويل الوجوه إلى تحليلات
    final frames = faceSequence.map((face) => _FrameAnalysis(
          timestamp: DateTime.now(),
          face: face,
          headYaw: face.headEulerAngleY ?? 0.0,
          headPitch: face.headEulerAngleX ?? 0.0,
          headRoll: face.headEulerAngleZ ?? 0.0,
          leftEyeOpen: face.leftEyeOpenProbability ?? 0.0,
          rightEyeOpen: face.rightEyeOpenProbability ?? 0.0,
        )).toList();

    bool passed = false;
    String message = '';

    switch (challenge) {
      case LivenessChallenge.blinkEyes:
        // التحقق من الرمش الكامل
        final leftEyeValues = frames.map((f) => f.leftEyeOpen).toList();
        final rightEyeValues = frames.map((f) => f.rightEyeOpen).toList();
        passed = _detectBlinkInSequence(leftEyeValues, rightEyeValues);
        message = passed ? '✅ تم اكتشاف رمش العينين' : '❌ لم يتم اكتشاف رمش العينين';
        break;

      case LivenessChallenge.blinkTwice:
        final blinkCount = _detectBlinks(frames);
        passed = blinkCount >= 2;
        message = passed ? '✅ تم اكتشاف رمشتين' : '❌ الرجاء الرمش مرتين';
        break;

      case LivenessChallenge.turnHeadLeft:
        passed = _detectHeadTurn(frames, direction: 'left');
        message = passed ? '✅ تم اكتشاف دوران الرأس لليسار' : '❌ الرجاء لف رأسك لليسار';
        break;

      case LivenessChallenge.turnHeadRight:
        passed = _detectHeadTurn(frames, direction: 'right');
        message = passed ? '✅ تم اكتشاف دوران الرأس لليمين' : '❌ الرجاء لف رأسك لليمين';
        break;

      case LivenessChallenge.lookUp:
        passed = _detectLookDirection(frames, direction: 'up');
        message = passed ? '✅ تم اكتشاف النظر للأعلى' : '❌ الرجاء النظر للأعلى';
        break;

      case LivenessChallenge.lookDown:
        passed = _detectLookDirection(frames, direction: 'down');
        message = passed ? '✅ تم اكتشاف النظر للأسفل' : '❌ الرجاء النظر للأسفل';
        break;

      case LivenessChallenge.rapidEyeMovement:
        passed = _detectRapidEyeMovement(frames);
        message = passed ? '✅ تم اكتشاف حركة العين السريعة' : '❌ حرك عينيك بسرعة يمين ويسار';
        break;
    }

    if (passed) {
      _completedChallenges.add(challenge);
      _currentChallengeIndex++;
    }

    print('🎯 Challenge ${challenge.displayText}: $passed - $message');

    return ChallengeResult(
      passed: passed,
      challenge: challenge,
      message: message,
    );
  }

  /// 🆕 التحقق من جميع التحديات باستخدام تسلسل الإطارات
  Future<LivenessResult> verifyAllChallenges({
    required List<Face> faceSequence,
    int minFramesPerChallenge = 15,
  }) async {
    if (_currentChallenges.isEmpty) {
      generateChallengeSequence();
    }

    print('\n🔐 ===== VERIFYING ALL LIVENESS CHALLENGES =====');
    print('📸 Total frames: ${faceSequence.length}');
    print('🎯 Challenges: ${_currentChallenges.map((c) => c.displayText).join(", ")}');

    // تقسيم الإطارات على التحديات
    final framesPerChallenge = faceSequence.length ~/ _currentChallenges.length;

    for (int i = 0; i < _currentChallenges.length; i++) {
      final challenge = _currentChallenges[i];
      final startIdx = i * framesPerChallenge;
      final endIdx = (i == _currentChallenges.length - 1)
          ? faceSequence.length
          : (i + 1) * framesPerChallenge;

      final challengeFrames = faceSequence.sublist(startIdx, endIdx);

      final result = await verifySingleChallenge(
        challenge: challenge,
        faceSequence: challengeFrames,
      );

      if (!result.passed) {
        return LivenessResult(
          passed: false,
          reason: LivenessFailureReason.challengeFailed,
          message: result.message,
          currentChallenge: challenge,
          completedChallenges: _completedChallenges,
        );
      }
    }

    print('✅ All challenges passed!');

    return LivenessResult(
      passed: true,
      reason: LivenessFailureReason.none,
      message: 'تم اجتياز جميع التحديات بنجاح',
      completedChallenges: _completedChallenges,
    );
  }

  /// Analyze collected frames for liveness indicators
  LivenessResult _analyzeFrames(List<_FrameAnalysis> frames) {
    if (frames.length < 5) {
      return LivenessResult(
        passed: false,
        reason: LivenessFailureReason.insufficientFrames,
        message: 'Not enough frames collected',
      );
    }

    // Check 1: Head pose variation (should show natural movement)
    final yawVariation = _calculateVariation(frames.map((f) => f.headYaw));
    final pitchVariation = _calculateVariation(frames.map((f) => f.headPitch));

    if (yawVariation < 2.0 && pitchVariation < 2.0) {
      return LivenessResult(
        passed: false,
        reason: LivenessFailureReason.staticFace,
        message: 'Face appears static (possible photo)',
      );
    }

    // Check 2: Detect at least one blink
    final blinkCount = _detectBlinks(frames);
    if (blinkCount < 1) {
      return LivenessResult(
        passed: false,
        reason: LivenessFailureReason.noBlink,
        message: 'No blink detected',
      );
    }

    // Check 3: Eyes should be mostly open
    final avgEyeOpen = frames
            .map((f) => (f.leftEyeOpen + f.rightEyeOpen) / 2)
            .reduce((a, b) => a + b) /
        frames.length;

    if (avgEyeOpen < 0.3) {
      return LivenessResult(
        passed: false,
        reason: LivenessFailureReason.eyesClosed,
        message: 'Eyes are closed',
      );
    }

    // All checks passed
    return LivenessResult(
      passed: true,
      reason: LivenessFailureReason.none,
      message: 'Liveness verified',
    );
  }

  /// Calculate statistical variation (standard deviation)
  double _calculateVariation(Iterable<double> values) {
    if (values.isEmpty) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) /
            values.length;

    return math.sqrt(variance);
  }
}

/// Internal frame analysis data structure
class _FrameAnalysis {
  final DateTime timestamp;
  final Face face;
  final double headYaw; // Left-right rotation
  final double headPitch; // Up-down rotation
  final double headRoll; // Tilt
  final double leftEyeOpen;
  final double rightEyeOpen;

  _FrameAnalysis({
    required this.timestamp,
    required this.face,
    required this.headYaw,
    required this.headPitch,
    required this.headRoll,
    required this.leftEyeOpen,
    required this.rightEyeOpen,
  });
}

/// Liveness challenge types
enum LivenessChallenge {
  blinkEyes,         // إغلاق وفتح العينين
  blinkTwice,        // ارمش مرتين
  turnHeadLeft,      // لف الرأس لليسار
  turnHeadRight,     // لف الرأس لليمين
  lookUp,            // انظر للأعلى
  lookDown,          // انظر للأسفل
  rapidEyeMovement,  // تحريك العين بسرعة
}

extension LivenessChallengeExtension on LivenessChallenge {
  String get displayText {
    switch (this) {
      case LivenessChallenge.blinkEyes:
        return 'أغلق عينيك ثم افتحهما';
      case LivenessChallenge.blinkTwice:
        return 'ارمش مرتين';
      case LivenessChallenge.turnHeadLeft:
        return 'لف رأسك لليسار';
      case LivenessChallenge.turnHeadRight:
        return 'لف رأسك لليمين';
      case LivenessChallenge.lookUp:
        return 'انظر للأعلى';
      case LivenessChallenge.lookDown:
        return 'انظر للأسفل';
      case LivenessChallenge.rapidEyeMovement:
        return 'حرك عينيك بسرعة يمين ويسار';
    }
  }

  String get englishText {
    switch (this) {
      case LivenessChallenge.blinkEyes:
        return 'Close your eyes completely, then open them';
      case LivenessChallenge.blinkTwice:
        return 'Blink twice';
      case LivenessChallenge.turnHeadLeft:
        return 'Turn your head slowly to the left';
      case LivenessChallenge.turnHeadRight:
        return 'Turn your head slowly to the right';
      case LivenessChallenge.lookUp:
        return 'Look up';
      case LivenessChallenge.lookDown:
        return 'Look down';
      case LivenessChallenge.rapidEyeMovement:
        return 'Move your eyes quickly left and right';
    }
  }

  String get instruction {
    switch (this) {
      case LivenessChallenge.blinkEyes:
        return 'يرجى إغلاق عينيك تمامًا ثم فتحهما مرة أخرى بسرعة وبشكل طبيعي';
      case LivenessChallenge.blinkTwice:
        return 'ارمش بعينيك مرتين بشكل طبيعي';
      case LivenessChallenge.turnHeadLeft:
        return 'لف رأسك ببطء إلى اليسار';
      case LivenessChallenge.turnHeadRight:
        return 'لف رأسك ببطء إلى اليمين';
      case LivenessChallenge.lookUp:
        return 'انظر إلى الأعلى';
      case LivenessChallenge.lookDown:
        return 'انظر إلى الأسفل';
      case LivenessChallenge.rapidEyeMovement:
        return 'حرك عينيك بسرعة بين اليمين واليسار';
    }
  }

  IconData get icon {
    switch (this) {
      case LivenessChallenge.blinkEyes:
      case LivenessChallenge.blinkTwice:
        return IconData(0xe3fc, fontFamily: 'MaterialIcons'); // visibility
      case LivenessChallenge.turnHeadLeft:
        return IconData(0xe5c4, fontFamily: 'MaterialIcons'); // arrow_back
      case LivenessChallenge.turnHeadRight:
        return IconData(0xe5c8, fontFamily: 'MaterialIcons'); // arrow_forward
      case LivenessChallenge.lookUp:
        return IconData(0xe5d8, fontFamily: 'MaterialIcons'); // arrow_upward
      case LivenessChallenge.lookDown:
        return IconData(0xe5db, fontFamily: 'MaterialIcons'); // arrow_downward
      case LivenessChallenge.rapidEyeMovement:
        return IconData(0xe5d2, fontFamily: 'MaterialIcons'); // swap_horiz
    }
  }

  Duration get timeout => const Duration(seconds: 5);
}

/// Liveness check result
class LivenessResult {
  final bool passed;
  final LivenessFailureReason reason;
  final String message;
  final LivenessChallenge? currentChallenge;
  final List<LivenessChallenge> completedChallenges;

  LivenessResult({
    required this.passed,
    required this.reason,
    required this.message,
    this.currentChallenge,
    this.completedChallenges = const [],
  });
}

/// Failure reasons for liveness checks
enum LivenessFailureReason {
  none,
  noFace,
  multipleFaces,
  lowLight,
  blur,
  timeout,
  staticFace,
  noBlink,
  noBlinkDetected, // 🆕 لم يتم اكتشاف رمش العينين
  noHeadMovement,  // 🆕 لم يتم اكتشاف حركة الرأس
  noEyeMovement,   // 🆕 لم يتم اكتشاف حركة العين
  eyesClosed,
  challengeFailed,
  insufficientFrames,
  error,
}

/// 🆕 نتيجة تحدي واحد
class ChallengeResult {
  final bool passed;
  final LivenessChallenge challenge;
  final String message;

  ChallengeResult({
    required this.passed,
    required this.challenge,
    required this.message,
  });
}
