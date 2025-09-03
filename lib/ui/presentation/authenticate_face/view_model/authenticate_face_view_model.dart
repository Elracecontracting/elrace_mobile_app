import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/data/models/user_model.dart';
import 'package:el_race/data/services/face_service.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart'
    as home_bloc;
import 'package:el_race/ui/presentation/home_screen/screens/home_screen.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/timer_controller.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_in_bloc/check_in_bloc.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_out_bloc/check_out_bloc.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/extensions/size_extension.dart';
import 'package:el_race/utils/extract_face_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../../../../utils/di.dart';

class AuthenticateFaceViewController extends GetxController {
  var faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: true,
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  // FaceService for TensorFlow Lite face recognition
  late FaceService faceService;
  var useTensorFlowRecognition = false.obs;
  var faceEmbeddingSize = 192; // MobileFaceNet embedding size
  var similarityThreshold = 0.6.obs; // TensorFlow similarity threshold

  FaceFeatures? faceFeatures;
  var userExists = false.obs;
  var loggingUser = Rxn<UserModel>();
  var isMatching = false.obs;
  var trialNumber = 1.obs;
  var canProcess = true;
  var isBusy = false;
  var hasInternet = true.obs;
  var hasFace = false.obs;
  var isCaptured = false.obs;
  File? capturedImage;
  CameraController? cameraController;

  var currentStep = 0;
  late List<String> steps;
  DateTime? gestureStartTime;
  var gestureProgress = 0.0.obs;

  final instructions = [
    // "Please smile to verify your liveness.",
    "Blink your eyes to confirm you're a live person",
    // "Look directly at the camera",
  ];

  var eyesClosedDetected = false;
  var blinkCompleted = false;
  var runtimeInstruction = ''.obs;

  // Timeout variables for face detection
  var faceDetectionStartTime = 0;
  static int faceDetectionTimeoutMs = 4000; // 6 seconds timeout
  var isTimeoutActive = false.obs;
  Timer? timeoutTimer;
  var hasStartedFaceDetection = false.obs;
  Timer? faceDetectionTimer;
  static int faceDetectionTimeoutSeconds = 10; // 10 seconds to detect face

  @override
  void onInit() {
    super.onInit();

    // Debug: Log face detector configuration
    print('🔧 Face Detector Configuration:');
    print('   - Performance Mode: ${FaceDetectorMode.accurate}');
    print('   - Min Face Size: 0.1');
    print('   - Landmarks: true');
    print('   - Contours: true');
    print('   - Classification: true');
    print('   - Tracking: true');

    InternetConnectionChecker.createInstance()
        .onStatusChange
        .listen((InternetConnectionStatus status) {
      hasInternet.value = status == InternetConnectionStatus.connected;
    });
    steps = ['Blink'];

    // Initialize check-in status
    _initializeCheckInStatus();

    // Initialize FaceService
    faceService = FaceService();

    // Configure multi-factor verification for maximum accuracy
    configureForMaximumAccuracy();

    super.onInit();
  }

  // Initialize FaceService
  Future<void> _initializeFaceService() async {
    try {
      print('🔄 Initializing FaceService...');
      faceService = FaceService();
      print('✅ FaceService initialized successfully');
    } catch (e) {
      print('❌ Error initializing FaceService: $e');
    }
  }

  // Initialize check-in status on startup
  Future<void> _initializeCheckInStatus() async {
    await checkUserCheckInStatus();
    print('🔄 Check-in status initialized: ${getCheckInStatusText()}');
  }

  // Refresh check-in status (call this when you need to update the status)
  Future<void> refreshCheckInStatus() async {
    await checkUserCheckInStatus();
    update(); // Trigger UI update
    print('🔄 Check-in status refreshed: ${getCheckInStatusText()}');
  }

  // Get current check-in status as observable
  bool getCurrentCheckInStatus() {
    return isUserCheckedIn.value;
  }

  // Listen to check-in status changes
  void addCheckInStatusListener(Function(bool) listener) {
    isUserCheckedIn.listen(listener);
  }

  // Force update check-in status from SharedPreferences
  Future<void> forceUpdateCheckInStatus() async {
    print('🔄 Force updating check-in status...');
    await checkUserCheckInStatus();
    update();
    print('✅ Check-in status force updated: ${getCheckInStatusText()}');
  }

  @override
  void onClose() {
    faceDetector.close();
    faceService.dispose();
    _stopTimeoutTimer();
    _resetFaceDetectionTimer();
    super.onClose();
  }

  // Reset face detection timer
  void _resetFaceDetectionTimer() {
    if (faceDetectionTimer != null) {
      faceDetectionTimer!.cancel();
      faceDetectionTimer = null;
      print("🔄 Face detection timer reset");
    }
  }

  // Manually start face detection timeout
  void startManualFaceDetectionTimeout() {
    _resetFaceDetectionTimer(); // Clear any existing timer
    print(
        "⏰ Manual face detection timeout started - ${faceDetectionTimeoutSeconds} seconds");
    faceDetectionTimer =
        Timer(Duration(seconds: faceDetectionTimeoutSeconds), () {
      print("⏰ Manual face detection timeout reached - calling failedToMatch");
      faceDetectionTimer = null;
      if (Get.context != null) {
        failedToMatch(Get.context!);
      }
    });
  }

  // Check if face detection timeout is active
  bool isFaceDetectionTimeoutActive() {
    return faceDetectionTimer != null;
  }

  // Get remaining face detection time in seconds
  int getFaceDetectionRemainingTime() {
    if (faceDetectionTimer == null) return 0;
    // Since we can't easily track the exact remaining time with Timer,
    // we'll return the timeout duration if timer is active
    return faceDetectionTimeoutSeconds;
  }

  // Set custom face detection timeout duration
  void setFaceDetectionTimeout(int seconds) {
    if (seconds > 0) {
      faceDetectionTimeoutSeconds = seconds;
      print("⏰ Face detection timeout set to: ${seconds} seconds");
    }
  }

  // Stop face detection timeout
  void stopFaceDetectionTimeout() {
    if (faceDetectionTimer != null) {
      faceDetectionTimer!.cancel();
      faceDetectionTimer = null;
      print("⏹️ Face detection timeout stopped");
    }
  }

  // Start timeout timer for face detection
  void startFaceDetectionTimeout() {
    faceDetectionStartTime = DateTime.now().millisecondsSinceEpoch;
    isTimeoutActive.value = true;

    timeoutTimer = Timer(Duration(milliseconds: faceDetectionTimeoutMs), () {
      if (isTimeoutActive.value && !isMatching.value) {
        _handleFaceDetectionTimeout();
      }
    });
  }

  // Stop timeout timer
  void _stopTimeoutTimer() {
    timeoutTimer?.cancel();
    timeoutTimer = null;
    isTimeoutActive.value = false;
  }

  // Handle timeout when face detection fails
  void _handleFaceDetectionTimeout() {
    print(
        "Face detection timeout reached - no valid face detected within 6 seconds");
    isTimeoutActive.value = false;

    // Reset states
    currentStep = 0;
    gestureStartTime = null;
    gestureProgress.value = 0.0;
    eyesClosedDetected = false;
    blinkCompleted = false;

    // Call failed matching function after 6 seconds timeout
    if (Get.context != null) {
      print("🚫 Calling failed matching function due to 6 second timeout");
      failedToMatch(Get.context!);
    }
  }

  // Reset timeout state for new authentication session
  void resetTimeoutState() {
    _stopTimeoutTimer();
    faceDetectionStartTime = 0;
    hasStartedFaceDetection.value = false;
    currentStep = 0;
    gestureStartTime = null;
    gestureProgress.value = 0.0;
    eyesClosedDetected = false;
    blinkCompleted = false;
  }

  // Manually start the 6 second timeout
  void startManualTimeout() {
    print("⏰ Manual timeout started - 6 seconds to detect face");
    hasStartedFaceDetection.value = true;
    startFaceDetectionTimeout();
  }

  // Get remaining time in seconds
  int getRemainingTimeSeconds() {
    if (!isTimeoutActive.value || faceDetectionStartTime == 0) {
      return 0;
    }

    final elapsed =
        DateTime.now().millisecondsSinceEpoch - faceDetectionStartTime;
    final remaining = faceDetectionTimeoutMs - elapsed;
    return (remaining / 1000).clamp(0, faceDetectionTimeoutMs / 1000).toInt();
  }

  // Check if timeout is about to expire (last 2 seconds)
  bool isTimeoutAboutToExpire() {
    if (!isTimeoutActive.value) return false;
    final remaining = getRemainingTimeSeconds();
    return remaining <= 2 && remaining > 0;
  }

  // Get timeout progress (0.0 to 1.0)
  double getTimeoutProgress() {
    if (!isTimeoutActive.value || faceDetectionStartTime == 0) {
      return 0.0;
    }

    final elapsed =
        DateTime.now().millisecondsSinceEpoch - faceDetectionStartTime;
    final progress = elapsed / faceDetectionTimeoutMs;
    return progress.clamp(0.0, 1.0);
  }

  // Set custom timeout duration (in milliseconds)
  void setCustomTimeout(int milliseconds) {
    if (milliseconds > 0) {
      faceDetectionTimeoutMs = milliseconds;
      print("⏰ Custom timeout set to: ${milliseconds}ms");
    }
  }

  // Set custom threshold for testing
  void setCustomThreshold(double minThreshold, double maxThreshold) {
    // This method is no longer needed as faceService handles thresholds.
    // Keeping it for now, but it will not have an effect on faceService.
    // customMinThreshold = minThreshold;
    // customMaxThreshold = maxThreshold;
    // useCustomThreshold = true;
    print('🔧 Custom threshold set: ${minThreshold}-${maxThreshold}');
  }

  // Enable custom threshold
  void enableCustomThreshold() {
    // This method is no longer needed.
    // useCustomThreshold = true;
    print(
        '🔧 Custom threshold enabled: ${customMinThreshold}-${customMaxThreshold}');
  }

  // Disable custom threshold (use default)
  void disableCustomThreshold() {
    // This method is no longer needed.
    // useCustomThreshold = false;
    print('🔧 Custom threshold disabled, using default: 0.95-1.05');
  }

  // Get current threshold info
  String getCurrentThresholdInfo() {
    // This method is no longer needed.
    // if (useCustomThreshold) {
    //   return 'Custom: ${customMinThreshold}-${customMaxThreshold}';
    // } else {
    return 'Default: 0.95-1.05';
    // }
  }

  // TensorFlow Lite Face Recognition Methods

  // Extract face embedding using FaceService
  Future<List<double>> extractFaceEmbedding(InputImage inputImage) async {
    if (!faceService.isModelLoaded) {
      print('⚠️ FaceService model not loaded - using geometric fallback');
      return _createGeometricEmbedding(inputImage);
    }

    try {
      // Convert InputImage to Uint8List
      final bytes = inputImage.bytes;
      if (bytes == null) {
        print('❌ InputImage bytes are null');
        return _createGeometricEmbedding(inputImage);
      }

      // Extract embedding using FaceService
      final embedding = await faceService.getEmbedding(bytes);
      print(
          '✅ FaceService embedding extracted: ${embedding.length} dimensions');
      return embedding;
    } catch (e) {
      print('❌ Error extracting FaceService embedding: $e');
      print('💡 Falling back to geometric embedding');
      return _createGeometricEmbedding(inputImage);
    }
  }

  // Create geometric embedding as fallback when FaceService is not available
  Future<List<double>> _createGeometricEmbedding(InputImage inputImage) async {
    try {
      // Extract face features using ML Kit
      final features = await extractFaceFeatures(inputImage, faceDetector);

      // Create a simple geometric embedding from face landmarks
      final embedding = <double>[];

      // Add normalized landmark positions
      if (features.leftEye != null) {
        embedding.add(features.leftEye!.x!.toDouble());
        embedding.add(features.leftEye!.y!.toDouble());
      }
      if (features.rightEye != null) {
        embedding.add(features.rightEye!.x!.toDouble());
        embedding.add(features.rightEye!.y!.toDouble());
      }
      if (features.noseBase != null) {
        embedding.add(features.noseBase!.x!.toDouble());
        embedding.add(features.noseBase!.y!.toDouble());
      }
      if (features.leftMouth != null) {
        embedding.add(features.leftMouth!.x!.toDouble());
        embedding.add(features.leftMouth!.y!.toDouble());
      }
      if (features.rightMouth != null) {
        embedding.add(features.rightMouth!.x!.toDouble());
        embedding.add(features.rightMouth!.y!.toDouble());
      }

      // Pad to 192 dimensions to match FaceService embedding size
      while (embedding.length < 192) {
        embedding.add(0.0);
      }

      print('✅ Created geometric embedding: ${embedding.length} dimensions');
      return embedding;
    } catch (e) {
      print('❌ Error creating geometric embedding: $e');
      // Return a default embedding
      return List.filled(192, 0.0);
    }
  }

  // Compare face embeddings using FaceService
  double compareFaceEmbeddings(
      List<double> embedding1, List<double> embedding2) {
    return faceService.cosineSimilarity(embedding1, embedding2);
  }

  // Enable TensorFlow Lite face recognition
  void enableTensorFlowRecognition() {
    useTensorFlowRecognition.value = true;
    similarityThreshold.value =
        0.9995; // Much higher threshold to prevent false matches
    print(
        '🔧 FaceService face recognition enabled with threshold: ${similarityThreshold.value}');
  }

  // Disable TensorFlow Lite face recognition
  void disableTensorFlowRecognition() {
    useTensorFlowRecognition.value = false;
    print('🔧 FaceService face recognition disabled');
  }

  // Set TensorFlow similarity threshold
  void setTensorFlowThreshold(double threshold) {
    similarityThreshold.value = threshold;
    print('🔧 FaceService similarity threshold set to: $threshold');
  }

  // Get similarity value without matching
  Future<double?> getSimilarityValue() async {
    final uuid = SharedPref.getLoginData().result?.data?.emp_id;
    if (uuid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uuid).get();
      if (doc.exists) {
        UserModel user = UserModel.fromJson(doc.data()!);

        if (user.faceEmbedding != null && user.faceEmbedding!.isNotEmpty) {
          try {
            List<double> currentEmbedding = await extractFaceEmbedding(
                InputImage.fromFilePath(capturedImage!.path));
            double similarity =
                compareFaceEmbeddings(currentEmbedding, user.faceEmbedding!);
            print('📊 Similarity value: $similarity');
            return similarity;
          } catch (e) {
            print('❌ Error getting similarity: $e');
          }
        } else {
          // Fallback to geometric comparison
          double sim = compareFaces(faceFeatures!, user.faceFeatures!);
          print('📊 Geometric similarity value: $sim');
          return sim;
        }
      }
    }
    return null;
  }

  Future<void> setImage(Uint8List imageToAuthenticate) async {
    // image2.bitmap = base64Encode(imageToAuthenticate);
    // image2.imageType = regula.ImageType.PRINTED;
  }

  double compareFaces(FaceFeatures face1, FaceFeatures face2) {
    // Calculate distances between corresponding facial landmarks
    double distEar1 = euclideanDistance(face1.rightEar!, face1.leftEar!);
    double distEar2 = euclideanDistance(face2.rightEar!, face2.leftEar!);

    double distEye1 = euclideanDistance(face1.rightEye!, face1.leftEye!);
    double distEye2 = euclideanDistance(face2.rightEye!, face2.leftEye!);

    double distCheek1 = euclideanDistance(face1.rightCheek!, face1.leftCheek!);
    double distCheek2 = euclideanDistance(face2.rightCheek!, face2.leftCheek!);

    double distMouth1 = euclideanDistance(face1.rightMouth!, face1.leftMouth!);
    double distMouth2 = euclideanDistance(face2.rightMouth!, face2.leftMouth!);

    double distNoseToMouth1 =
        euclideanDistance(face1.noseBase!, face1.bottomMouth!);
    double distNoseToMouth2 =
        euclideanDistance(face2.noseBase!, face2.bottomMouth!);

    // Calculate ratios
    double earRatio = distEar1 / distEar2;
    double eyeRatio = distEye1 / distEye2;
    double cheekRatio = distCheek1 / distCheek2;
    double mouthRatio = distMouth1 / distMouth2;
    double noseToMouthRatio = distNoseToMouth1 / distNoseToMouth2;

    // Calculate weighted average
    double ratio = (eyeRatio * 0.4 +
        earRatio * 0.3 +
        cheekRatio * 0.15 +
        mouthRatio * 0.1 +
        noseToMouthRatio * 0.05);

    log(ratio.toString(), name: "Ratio");
    return ratio;
  }

  double euclideanDistance(Points p1, Points p2) {
    return math
        .sqrt(math.pow((p1.x! - p2.x!), 2) + math.pow((p1.y! - p2.y!), 2));
  }

  // More accurate face recognition variables
  var useMultiFactorVerification = true.obs;
  var geometricWeight = 0.3.obs; // Weight for geometric comparison
  var embeddingWeight = 0.7.obs; // Weight for embedding comparison
  var minGeometricSimilarity = 0.95.obs; // Minimum geometric similarity
  var minEmbeddingSimilarity = 0.998.obs; // Minimum embedding similarity
  var requireBothChecks = true.obs; // Require both checks to pass

  // More accurate face matching with multiple factors
  Future<void> fetchUsersAndMatchFace(BuildContext context,
      {void Function(bool)? onCheckInStatusChanged}) async {
    final uuid = SharedPref.getLoginData().result?.data?.emp_id;
    if (uuid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uuid).get();
      if (doc.exists) {
        UserModel user = UserModel.fromJson(doc.data()!);

        // Check if user has face embedding
        if (user.faceEmbedding == null || user.faceEmbedding!.isEmpty) {
          print('❌ No face embedding found for user');
          failedToMatch(context);
          return;
        }

        try {
          // Multi-factor verification
          bool matchResult = await performMultiFactorVerification(user);

          if (matchResult) {
            print('✅ Multi-factor face match successful');
            matchFaces(context,
                onCheckInStatusChanged: onCheckInStatusChanged, user: user);
          } else {
            print('❌ Multi-factor face match failed');
            failedToMatch(context);
          }
        } catch (e) {
          print('❌ Multi-factor verification failed: $e');
          failedToMatch(context);
        }
      }
    }
  }

  // Perform multi-factor face verification
  Future<bool> performMultiFactorVerification(UserModel user) async {
    print('🔍 Performing multi-factor face verification...');

    bool geometricPass = false;
    bool embeddingPass = false;
    double geometricSimilarity = 0.0;
    double embeddingSimilarity = 0.0;

    // Factor 1: Geometric comparison
    try {
      geometricSimilarity = compareFaces(faceFeatures!, user.faceFeatures!);
      geometricPass = geometricSimilarity >= minGeometricSimilarity.value;
      print(
          '📐 Geometric similarity: $geometricSimilarity (threshold: ${minGeometricSimilarity.value}) - ${geometricPass ? "✅ PASS" : "❌ FAIL"}');
    } catch (e) {
      print('❌ Geometric comparison failed: $e');
    }

    // Factor 2: Embedding comparison
    try {
      List<double> currentEmbedding = await extractFaceEmbedding(
          InputImage.fromFilePath(capturedImage!.path));
      embeddingSimilarity =
          compareFaceEmbeddings(currentEmbedding, user.faceEmbedding!);
      embeddingPass = embeddingSimilarity >= minEmbeddingSimilarity.value;
      print(
          '🧠 Embedding similarity: $embeddingSimilarity (threshold: ${minEmbeddingSimilarity.value}) - ${embeddingPass ? "✅ PASS" : "❌ FAIL"}');
    } catch (e) {
      print('❌ Embedding comparison failed: $e');
    }

    // Calculate weighted score
    double weightedScore = (geometricSimilarity * geometricWeight.value) +
        (embeddingSimilarity * embeddingWeight.value);

    print('📊 Weighted score: $weightedScore');
    print(
        '📊 Geometric weight: ${geometricWeight.value}, Embedding weight: ${embeddingWeight.value}');

    // Determine final result
    bool finalResult;
    if (requireBothChecks.value) {
      // Require both checks to pass
      finalResult = geometricPass && embeddingPass;
      print('🔒 Both checks required: ${finalResult ? "✅ PASS" : "❌ FAIL"}');
    } else {
      // Use weighted score
      double minWeightedScore =
          (minGeometricSimilarity.value * geometricWeight.value) +
              (minEmbeddingSimilarity.value * embeddingWeight.value);
      finalResult = weightedScore >= minWeightedScore;
      print(
          '⚖️ Weighted score check: ${finalResult ? "✅ PASS" : "❌ FAIL"} (threshold: $minWeightedScore)');
    }

    return finalResult;
  }

  void matchFaces(BuildContext context,
      {void Function(bool)? onCheckInStatusChanged,
      required UserModel user}) async {
    print("[DEBUG] Checking user's check-in status from SharedPreferences");

    // for (List user in users) {
    // image1.bitmap = (user.first as UserModel).image;
    // image1.imageType = regula.ImageType.PRINTED;

    // var request = regula.MatchFacesRequest();
    // request.images = [image1, image2];
    // dynamic value = await regula.FaceSDK.matchFaces(jsonEncode(request));
    // var response = regula.MatchFacesResponse.fromJson(json.decode(value));
    // dynamic str = await regula.FaceSDK.matchFacesSimilarityThresholdSplit(jsonEncode(response!.results), 0.75);
    // var split = regula.MatchFacesSimilarityThresholdSplit.fromJson(json.decode(str));

    // similarity.value = split!.matchedFaces.isNotEmpty
    //     ? (split.matchedFaces[0]!.similarity! * 100).toStringAsFixed(2)
    //     : "error";
    // debugPrint("similarity.value: ${similarity.value}");
    // if (similarity.value != "error" && similarity.value != '' && double.parse(similarity.value) > 90.00) {
    // faceMatched = true;
    loggingUser.value = user;
    updateFaceRecognitionStatus(
        context, home_bloc.FaceRecognitionStatus.matched);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 2));
    Navigator.of(context).pop(); // Close loading

    // Check user's current check-in status
    final isCheckedIn = checkUserCheckInStatus();
    print(
        '🔍 Current check-in status: ${isCheckedIn ? "Checked In" : "Not Checked In"}');

    if (!isCheckedIn) {
      // User is not checked in - perform check-in
      print('✅ User not checked in - performing check-in');
      sl.get<CheckInBloc>().add(CheckInET());
      onCheckInStatusChanged?.call(true);
      Get.find<TimerController>().startTimer();
    } else {
      // User is already checked in - perform check-out
      print('✅ User already checked in - performing check-out');
      final checkInRecordId = currentCheckInRecordId.value;
      sl.get<CheckOutBloc>().add(CheckOutET(checkInRecordId));
      onCheckInStatusChanged?.call(false);
      Get.find<TimerController>().stopTimer();
    }

    /// ✅ Only navigate if face matched and check-in/out processed
    updateFaceRecognitionStatus(context, home_bloc.FaceRecognitionStatus.idle);
    await Future.delayed(const Duration(milliseconds: 200));
    Util.fetchHomeScreenData(context);
    Util.pushPageAndRemoveRoutes(const HomeScreen(), context);
    return;

    // break;
    // }

    // }
  }

  failedToMatch(BuildContext context) async {
    updateFaceRecognitionStatus(
        context, home_bloc.FaceRecognitionStatus.failed);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Authentication Failed"),
        content: const Text("Face doesn't match. Please try again."),
        actions: [
          TextButton(
            onPressed: () {
              updateFaceRecognitionStatus(
                  context, home_bloc.FaceRecognitionStatus.idle);
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
    await Future.delayed(const Duration(milliseconds: 200));
    updateFaceRecognitionStatus(context, home_bloc.FaceRecognitionStatus.idle);
  }

  void updateFaceRecognitionStatus(
      BuildContext context, home_bloc.FaceRecognitionStatus status) {
    try {
      print('updateFaceRecognitionStatus: $status');
      // if (context.mounted && Get.isRegistered<AuthenticateFaceViewController>()) {
      print('context.mounted: ${context.mounted}');
      context
          .read<home_bloc.HomeBloc>()
          .add(home_bloc.UpdateFaceRecognitionStatus(status));
      // }
    } catch (e) {
      print("Error updating face recognition status: $e");
    }
  }

  void showFailureDialog({required String title, required String description}) {
    if (Get.isDialogOpen != true && Get.context != null) {
      Get.dialog(
        AlertDialog(
          title: Text(title),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("Ok", style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );
    }
  }

  void setCameraController(CameraController controller) {
    cameraController = controller;
  }

  var currentZone = FaceSizeZone.perfect.obs;

  void Function(bool)? onCheckInStatusChanged;

  // Check-in status detection
  var isUserCheckedIn = false.obs;
  var currentCheckInRecordId = 0.obs;

  // Custom threshold variables for testing
  static double customMinThreshold = 0.95;
  static double customMaxThreshold = 1.05;
  static bool useCustomThreshold = false;

  // Check user's current check-in status from SharedPreferences
  bool checkUserCheckInStatus() {
    try {
      final checkInRecordId = SharedPref().getPreferenceInt('checkInRecordId');

      currentCheckInRecordId.value = checkInRecordId;
      isUserCheckedIn.value = checkInRecordId != 0;

      print('🔍 Check-in status check:');
      print('   - checkInRecordId: $checkInRecordId');
      print('   - isUserCheckedIn: ${isUserCheckedIn.value}');

      return isUserCheckedIn.value;
    } catch (e) {
      print('❌ Error checking check-in status: $e');
      isUserCheckedIn.value = false;
      return false;
    }
  }

  // Get current check-in status text
  String getCheckInStatusText() {
    if (isUserCheckedIn.value) {
      return "Checked In (ID: ${currentCheckInRecordId.value})";
    }
    return "Not Checked In";
  }

  Future<void> processImage(InputImage inputImage, BuildContext context) async {
    if (!canProcess || isBusy) return;
    isBusy = true;

    // Start face detection timeout timer if not already started
    if (faceDetectionTimer == null) {
      print(
          "⏰ Face detection timeout started - ${faceDetectionTimeoutSeconds} seconds to detect face");
      faceDetectionTimer =
          Timer(Duration(seconds: faceDetectionTimeoutSeconds), () {
        if (hasFace.value == false) {
          print("⏰ Face detection timeout reached - calling failedToMatch");
          faceDetectionTimer = null;
          failedToMatch(context);
        }
      });
    }

    try {
      final faces = await faceDetector.processImage(inputImage);

      // Debug: Log face detection results
      print('🔍 Face detection result: ${faces.length} faces found');
      if (faces.isNotEmpty) {
        print('📍 First face bounds: ${faces.first.boundingBox}');
        print('👁️ Left eye open: ${faces.first.leftEyeOpenProbability}');
        print('👁️ Right eye open: ${faces.first.rightEyeOpenProbability}');

        // Face detected - cancel the timeout timer
        if (faceDetectionTimer != null) {
          faceDetectionTimer!.cancel();
          faceDetectionTimer = null;
          print("✅ Face detected - timeout timer cancelled");
        }
      }

      hasFace.value = false;

      if (faces.isNotEmpty &&
          cameraController != null &&
          cameraController!.value.isInitialized) {
        final face = faces.first;
        final camera = cameraController!.description;

        // Face detected - stop the timeout timer since we found a face
        if (isTimeoutActive.value) {
          _stopTimeoutTimer();
          print("✅ Face detected - timeout timer stopped");
        }

        // Get the preview size from the controller
        final Size imageSize = cameraController!.value.previewSize!;
        final Rect faceRect = face.boundingBox;

        print('📱 Image size: $imageSize');
        print('🎯 Face rect: $faceRect');

        // Calculate scale factors between image and your detector preview area (0.30.sh x 0.30.sh)
        final double viewWidth = 0.30.sh;
        final double viewHeight = 0.30.sh;

        print('📐 View dimensions: ${viewWidth}x${viewHeight}');

        // In portrait mode, ML Kit uses landscape coordinates — so swap
        final double scaleX = viewWidth / imageSize.height;
        final double scaleY = viewHeight / imageSize.width;

        print('📏 Scale factors: scaleX=$scaleX, scaleY=$scaleY');

        // Flip horizontally for front camera
        final bool isFrontCamera =
            camera.lensDirection == CameraLensDirection.front;

        Rect scaledRect = Rect.fromLTRB(
          faceRect.left * scaleX,
          faceRect.top * scaleY,
          faceRect.right * scaleX,
          faceRect.bottom * scaleY,
        );

        if (isFrontCamera) {
          final double centerX = viewWidth / 2;
          scaledRect = Rect.fromLTRB(
            2 * centerX - scaledRect.right,
            scaledRect.top,
            2 * centerX - scaledRect.left,
            scaledRect.bottom,
          );
        }

        print('🎯 Scaled face rect: $scaledRect');

        final Offset circleCenter = Offset(viewWidth / 2, viewHeight / 2);
        final double circleRadius = viewWidth / 2;

        print('⭕ Circle center: $circleCenter, radius: $circleRadius');

        bool passed = false;
        if (isFaceInsideCircle(scaledRect, circleCenter, circleRadius)) {
          print('✅ Face is inside circle!');
          hasFace.value = true;

          final double faceWidth = scaledRect.width;
          final double faceHeight = scaledRect.height;

          final double minFaceSize = viewWidth * 0.4;
          final double maxFaceSize = viewWidth * 0.7;
          const double buffer = 10;

          print('📏 Face size: ${faceWidth}x${faceHeight}');
          print('📏 Min size: $minFaceSize, Max size: $maxFaceSize');

          FaceSizeZone newZone;

          final bool isTooSmall = faceWidth < (minFaceSize - buffer) ||
              faceHeight < (minFaceSize - buffer);
          final bool isTooBig = faceWidth > (maxFaceSize + buffer) ||
              faceHeight > (maxFaceSize + buffer);

          if (isTooSmall) {
            newZone = FaceSizeZone.tooSmall;
            print('📏 Face too small');
          } else if (isTooBig) {
            newZone = FaceSizeZone.tooBig;
            print('📏 Face too big');
          } else {
            newZone = FaceSizeZone.perfect;
            print('📏 Face size perfect');
          }

          if (newZone != currentZone.value) {
            currentZone.value = newZone;

            switch (newZone) {
              case FaceSizeZone.tooSmall:
                runtimeInstruction.value = "Come closer to the camera";
                break;
              case FaceSizeZone.tooBig:
                runtimeInstruction.value = "Move a little back";
                break;
              case FaceSizeZone.perfect:
                runtimeInstruction.value = "Perfect!";
                break;
            }
          }

          if (currentStep >= steps.length) return;
          switch (steps[currentStep]) {
            case 'Blink':
              final leftEyeOpen = face.leftEyeOpenProbability;
              final rightEyeOpen = face.rightEyeOpenProbability;

              print(
                  '👁️ leftEyeOpen: $leftEyeOpen, rightEyeOpen: $rightEyeOpen');

              final eyesClosed = (leftEyeOpen != null && leftEyeOpen < 0.3) &&
                  (rightEyeOpen != null && rightEyeOpen < 0.3);

              final eyesOpen = (leftEyeOpen != null && leftEyeOpen > 0.6) &&
                  (rightEyeOpen != null && rightEyeOpen > 0.6);

              if (!eyesClosedDetected && eyesClosed) {
                print('👁️ Eyes closed detected!');
                eyesClosedDetected = true;
              }

              if (eyesClosedDetected && eyesOpen) {
                print('👁️ Eyes open detected!');
                blinkCompleted = true;
                eyesClosedDetected = false;
              }

              passed = blinkCompleted;
              print('✅ Blink step passed: $passed');
              break;
          }

          if (passed) {
            if (gestureStartTime == null) {
              gestureStartTime = DateTime.now();
              print('⏰ Gesture timer started');
            } else {
              final elapsed =
                  DateTime.now().difference(gestureStartTime!).inMilliseconds;
              gestureProgress.value = (elapsed / 3000).clamp(0.0, 1.0);

              if (elapsed >= 3000) {
                gestureStartTime = null;
                gestureProgress.value = 0.0;
                currentStep++;
                print('✅ Step completed, moving to next: $currentStep');
                if (currentStep >= steps.length && !isCaptured.value) {
                  print('📸 Capturing image...');
                  await _captureImage(context);
                }
              }
            }
          } else {
            gestureStartTime = null;
            gestureProgress.value = 0.0;
          }
        } else {
          print('❌ Face is NOT inside circle');
          hasFace.value = false;
          gestureStartTime = null;
          gestureProgress.value = 0.0;

          // Restart timeout timer if face is not in correct position
          if (!isTimeoutActive.value) {
            startFaceDetectionTimeout();
            print("⏰ Face not in position - restarting 6 second timeout");
          }
        }
      } else {
        print('❌ No faces detected or camera not ready');
        if (faces.isEmpty) {
          print('❌ Face detector returned empty result');
        }
        if (cameraController == null) {
          print('❌ Camera controller is null');
        } else if (!cameraController!.value.isInitialized) {
          print('❌ Camera controller not initialized');
        }

        // Restart timeout timer if no faces detected
        if (!isTimeoutActive.value) {
          startFaceDetectionTimeout();
          print("⏰ No faces detected - restarting 6 second timeout");
        }
      }
    } catch (e) {
      print('❌ Error in processImage: $e');
      // Restart timeout timer if error occurs
      if (!isTimeoutActive.value) {
        startFaceDetectionTimeout();
        print("⏰ Error occurred - restarting 6 second timeout");
      }
    } finally {
      isBusy = false;
      update();
    }
  }

  Future<void> _captureImage(BuildContext context) async {
    try {
      // Stop timeout timer since we're now processing the captured image
      _stopTimeoutTimer();

      final XFile file = await cameraController!.takePicture();
      File originalFile = File(file.path);

      // Extract features using unflipped image
      Uint8List originalBytes = originalFile.readAsBytesSync();
      setImage(originalBytes);
      isCaptured.value = true;

      InputImage inputImage = InputImage.fromFilePath(originalFile.path);
      faceFeatures = await extractFaceFeatures(inputImage, faceDetector);

      // Flip image only for UI if using front camera
      File displayImage = originalFile;
      if (cameraController!.description.lensDirection ==
          CameraLensDirection.front) {
        displayImage = await _flipImageHorizontally(originalFile);
      }

      // Now update UI just once with the display image
      capturedImage = displayImage;
      isMatching.value = true;
      update();

      fetchUsersAndMatchFace(
        context,
        onCheckInStatusChanged: onCheckInStatusChanged,
      );
    } catch (e) {
      print("Capture failed: $e");
      // Restart timeout if capture fails
      startFaceDetectionTimeout();
    }
  }

  Future<File> _flipImageHorizontally(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    img.Image? original = img.decodeImage(bytes);
    if (original == null) return imageFile;

    img.Image flipped = img.flipHorizontal(original);
    final flippedBytes = img.encodeJpg(flipped);

    return await imageFile.writeAsBytes(flippedBytes);
  }

  bool isFaceInsideCircle(
      Rect faceRect, Offset circleCenter, double circleRadius) {
    final corners = [
      faceRect.topLeft,
      faceRect.topRight,
      faceRect.bottomLeft,
      faceRect.bottomRight,
    ];

    // More lenient circle detection - check if center of face is inside circle
    final faceCenter = Offset(
      faceRect.left + faceRect.width / 2,
      faceRect.top + faceRect.height / 2,
    );

    final centerDistance = (faceCenter - circleCenter).distance;
    final isCenterInside = centerDistance <= circleRadius;

    // Also check if at least 3 corners are inside (more lenient than all 4)
    int cornersInside = 0;
    for (final point in corners) {
      if ((point - circleCenter).distance <= circleRadius) {
        cornersInside++;
      }
    }

    print('📐 Corners inside circle: $cornersInside/4');

    // Accept if center is inside OR at least 3 corners are inside
    return isCenterInside || cornersInside >= 3;
  }

  void openSettings() async {
    bool opened = await openAppSettings();
    if (!opened) {
      // Handle failure to open settings (optional)
      print("Failed to open app settings.");
    }
  }

  // Optimize threshold based on testing results
  void optimizeThreshold({
    required double yourSimilarity,
    required double daughterSimilarity,
    required double wifeSimilarity,
  }) {
    print('🔧 Optimizing threshold based on test results...');
    print('   - Your similarity: $yourSimilarity');
    print('   - Daughter similarity: $daughterSimilarity');
    print('   - Wife similarity: $wifeSimilarity');

    // Find the best threshold
    double bestThreshold =
        (yourSimilarity + math.max(daughterSimilarity, wifeSimilarity)) / 2;

    // Ensure threshold is reasonable
    bestThreshold = bestThreshold.clamp(0.6, 0.95);

    print('   - Recommended threshold: $bestThreshold');

    // Set the optimized threshold
    setTensorFlowThreshold(bestThreshold);

    print('✅ Threshold optimized to: ${similarityThreshold.value}');
  }

  // Configure multi-factor verification for maximum accuracy
  void configureForMaximumAccuracy() {
    print('🔧 Configuring for maximum accuracy...');

    // Set strict thresholds
    minGeometricSimilarity.value = 0.98; // Very high geometric threshold
    minEmbeddingSimilarity.value = 0.997; // Very high embedding threshold

    // Require both checks to pass
    requireBothChecks.value = true;

    // Set weights (embedding more important)
    geometricWeight.value = 0.2;
    embeddingWeight.value = 0.8;
  }

  // Configure for balanced accuracy and usability
  void configureForBalancedAccuracy() {
    print('🔧 Configuring for balanced accuracy...');

    // Set moderate thresholds
    minGeometricSimilarity.value = 0.95;
    minEmbeddingSimilarity.value = 0.998;

    // Use weighted score instead of requiring both
    requireBothChecks.value = false;

    // Balanced weights
    geometricWeight.value = 0.3;
    embeddingWeight.value = 0.7;
  }

  // Set custom thresholds for multi-factor verification
  void setMultiFactorThresholds({
    required double geometricThreshold,
    required double embeddingThreshold,
    bool requireBoth = true,
    double geoWeight = 0.3,
    double embWeight = 0.7,
  }) {
    minGeometricSimilarity.value = geometricThreshold;
    minEmbeddingSimilarity.value = embeddingThreshold;
    requireBothChecks.value = requireBoth;
    geometricWeight.value = geoWeight;
    embeddingWeight.value = embWeight;

    print('🔧 Multi-factor thresholds updated:');
    print('   - Geometric: $geometricThreshold');
    print('   - Embedding: $embeddingThreshold');
    print('   - Require both: $requireBoth');
    print('   - Weights: ${geoWeight}/${embWeight}');
  }
}

enum FaceSizeZone { tooSmall, perfect, tooBig }


  // Future<void> _triggerFaceRecognition() async {
  //   // Show matching status icon
  //   context.read<HomeBloc>().add(const UpdateFaceRecognitionStatus(FaceRecognitionStatus.matching));

  //   try {
  //     // Initialize camera (front)
  //     final cameras = await availableCameras();
  //     final frontCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
  //     _cameraController = CameraController(frontCamera, ResolutionPreset.low, enableAudio: false);
  //     await _cameraController!.initialize();

  //     // Detect face with ML Kit
  //     final faceDetector = FaceDetector(
  //       options: FaceDetectorOptions(
  //         enableContours: false,
  //         enableClassification: true,
  //         enableLandmarks: false,
  //         enableTracking: false,
  //       ),
  //     );

  //     bool blinkVerified = false;
  //     bool eyesClosedDetected = false;

  //     // Loop until blink is detected or timeout
  //     final startTime = DateTime.now();
  //     while (!blinkVerified && DateTime.now().difference(startTime).inSeconds < 5) {
  //       final XFile frameFile = await _cameraController!.takePicture();
  //       final inputImage = InputImage.fromFilePath(frameFile.path);
  //       final faces = await faceDetector.processImage(inputImage);

  //       if (faces.isNotEmpty) {
  //         final face = faces.first;
  //         final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
  //         final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;

  //         final eyesClosed = leftEyeOpen < 0.5 && rightEyeOpen < 0.5;
  //         final eyesOpen = leftEyeOpen > 0.8 && rightEyeOpen > 0.8;

  //         if (eyesClosed) {
  //           eyesClosedDetected = true;
  //         }

  //         if (eyesClosedDetected && eyesOpen) {
  //           blinkVerified = true;
  //         }
  //       }
  //     }

  //     if (!blinkVerified) {
  //       if (mounted) setState(() => matchResult = null);
  //       context.read<HomeBloc>().add(const UpdateFaceRecognitionStatus(FaceRecognitionStatus.idle));
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Blink not detected. Please try again')),
  //       );
  //       throw Exception("Blink not detected. Please try again.");
  //     }

  //     // Capture final image after blink for matching
  //     final XFile finalFile = await _cameraController!.takePicture();
  //     final imageFile = File(finalFile.path);
  //     final inputImage = InputImage.fromFilePath(imageFile.path);

  //     // Extract features
  //     _faceController!.faceFeatures = await extractFaceFeatures(inputImage, _faceController!.faceDetector);
  //     bool matched = false;

  //     final uuid = SharedPref.getLoginData().result?.data?.emp_id;
  //     if (uuid != null) {
  //       final doc = await FirebaseFirestore.instance.collection('users').doc(uuid).get();
  //       if (doc.exists) {
  //         UserModel user = UserModel.fromJson(doc.data()!);
  //         double sim = _faceController!.compareFaces(_faceController!.faceFeatures!, user.faceFeatures!);
  //         debugPrint('sim: $sim');

  //         // Stricter threshold
  //         if (sim >= 0.97 && sim <= 1.3) {
  //           matched = true;
  //         }   
  //       }
  //     }

  //     // Handle match result
  //     if (matched) {
  //       if (!isCheckedIn) {
  //         SharedPref().setPreferencesBoolean('isCheckedIn', true);
  //         sl.get<CheckInBloc>().add(CheckInET());
  //         Get.find<TimerController>().startTimer();
  //       } else {
  //         final checkInRecordId = SharedPref().getPreferenceInt('checkInRecordId');
  //         SharedPref().setPreferencesBoolean('isCheckedIn', false);
  //         if (checkInRecordId != 0) {
  //           sl.get<CheckOutBloc>().add(CheckOutET(checkInRecordId));
  //           Get.find<TimerController>().stopTimer();
  //         } else {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text('Check-In Record ID not found.')),
  //           );
  //         }
  //       }
  //     }

  //     _checkmarkController.forward(from: 0.0);
  //     context.read<HomeBloc>().add(UpdateFaceRecognitionStatus(
  //       matched ? FaceRecognitionStatus.matched : FaceRecognitionStatus.failed,
  //     ));

  //     Future.delayed(const Duration(seconds: 2), () {
  //       if (mounted) setState(() => matchResult = null);
  //       context.read<HomeBloc>().add(const UpdateFaceRecognitionStatus(FaceRecognitionStatus.idle));

  //       if (matched) {
  //         Util.fetchHomeScreenData(context);
  //         Util.pushPageAndRemoveRoutes(const HomeScreen(), context);
  //       }
  //     });

  //     if (!matched) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Face not recognized. Please try again.')),
  //       );
  //     }
  //   } catch (e) {
  //     setState(() => matchResult = false);
  //     _checkmarkController.forward(from: 0.0);
  //     context.read<HomeBloc>().add(const UpdateFaceRecognitionStatus(FaceRecognitionStatus.failed));
  //     Future.delayed(const Duration(seconds: 2), () {
  //       if (mounted) setState(() => matchResult = null);
  //       context.read<HomeBloc>().add(const UpdateFaceRecognitionStatus(FaceRecognitionStatus.idle));
  //     });
  //     _resetPosition();
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Face recognition failed: $e')),
  //     );
  //   } finally {
  //     await _cameraController?.dispose();
  //     _cameraController = null;
  //   }
  // }
