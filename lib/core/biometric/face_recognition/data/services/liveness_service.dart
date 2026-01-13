import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'face_detector_service.dart';

/// Enhanced Liveness Detection Service with Multi-frame Analysis and Active Challenges
///
/// Features:
/// - Multi-frame analysis (10-20 frames over 1-2 seconds)
/// - Active random challenges (blink, head turn, etc.)
/// - Anti-spoofing: prevents photo/video replay attacks
/// - Real-time feedback for user guidance
class LivenessService {
  final FaceDetectorService _faceDetectorService;

  LivenessService(this._faceDetectorService);

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
  blinkTwice,
  turnHeadLeft,
  turnHeadRight,
  lookUp,
  lookDown,
}

extension LivenessChallengeExtension on LivenessChallenge {
  String get displayText {
    switch (this) {
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
    }
  }
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
  eyesClosed,
  challengeFailed,
  insufficientFrames,
  error,
}
