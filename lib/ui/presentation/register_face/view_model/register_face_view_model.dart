import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:el_race/data/models/gesture_description.dart';
import 'package:el_race/data/models/user_model.dart';
import 'package:el_race/data/services/face_service.dart';
import 'package:el_race/resources/app_colors.dart';
import 'package:el_race/resources/app_string.dart';
import 'package:el_race/ui/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import 'dart:math' as math;
import '../../../../utils/extract_face_feature.dart';
import '../../authenticate_face/view_model/authenticate_face_view_model.dart';
class RegisterFaceViewController extends GetxController {
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
  var faceEmbeddingSize = 192; // MobileFaceNet embedding size
  List<double>? faceEmbedding;

  late List<GestureDescription> gestureDescriptions;

  CameraController? cameraController;

  RxBool hasInternet = true.obs;
  RxBool hasFace = false.obs;
  RxBool isCaptured = false.obs;
  RxDouble gestureProgress = 0.0.obs;

  String? imageBase64;
  FaceFeatures? faceFeatures;
  File? capturedImage;

  int currentStep = 0;
  String currentInstruction = '';
  DateTime? gestureStartTime;


  bool _isBusy = false;
  bool canProcess = true;
  bool _eyesClosedDetected = false;
  bool _blinkCompleted = false;
  var currentZone = FaceSizeZone.perfect.obs;

  var runtimeInstruction = ''.obs;

  final gestureAnimations = {
    // "Smile": AppString.smile,
    "Blink": AppString.blink,
    // "Look Left": AppString.left,
    // "Look Right": AppString.right,
    // "Look Straight": AppString.straight,
  };
  @override
  void onInit() {
    super.onInit();
    InternetConnectionChecker().onStatusChange.listen((InternetConnectionStatus status) {
      hasInternet.value = status == InternetConnectionStatus.connected;
      update();
    });

    gestureDescriptions = [
    
      GestureDescription(
        icon: Icons.face,
        step: "Blink",
        title: "Blink both eyes once clearly for detection.",
        statusKey: "Pending".obs,
      ),
   
    ]..shuffle();
    // gestureDescriptions.add(
    //   GestureDescription(
    //   icon: Icons.center_focus_strong,
    //     step: "Look Straight",
    //   title: "Face the camera directly with a neutral expression.",
    //   statusKey: "Pending".obs,),
    // );
    gestureDescriptions.first.statusKey!.value = "In progress";

    currentInstruction = _buildInstruction();

    // Initialize FaceService
    faceService = FaceService();

  }

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
      print('✅ FaceService embedding extracted: ${embedding.length} dimensions');
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

  @override
  void onClose() {
    faceDetector.close();
    faceService.dispose();
    super.onClose();
  }

  void setCameraController(CameraController controller) {
    cameraController = controller;
  }


  Future<void> processImage(InputImage inputImage, BuildContext context) async {
    if (!canProcess || _isBusy) return;
    _isBusy = true;
    print("processImage called");


    final faces = await faceDetector.processImage(inputImage);
    hasFace.value = false;

    if (faces.isNotEmpty && cameraController != null && cameraController!.value.isInitialized) {
      final face = faces.first;
      final camera = cameraController!.description;
      final imageSize = cameraController!.value.previewSize!;
      final faceRect = face.boundingBox;
      final double viewWidth = 0.30.sh;
      final double viewHeight = 0.30.sh;
      
      final scaleX = viewWidth / imageSize.height;
      final scaleY = viewHeight / imageSize.width;
      final isFrontCamera = camera.lensDirection == CameraLensDirection.front;

      var scaledRect = Rect.fromLTRB(
        faceRect.left * scaleX,
        faceRect.top * scaleY,
        faceRect.right * scaleX,
        faceRect.bottom * scaleY,
      );

      if (isFrontCamera) {
        final centerX = viewWidth / 2;
        scaledRect = Rect.fromLTRB(
          2 * centerX - scaledRect.right,
          scaledRect.top,
          2 * centerX - scaledRect.left,
          scaledRect.bottom,
        );
      }

      final circleCenter = Offset(viewWidth / 2, viewHeight / 2);
      final circleRadius = viewWidth / 2;

      if (isFaceInsideCircle(scaledRect, circleCenter, circleRadius)) {
        hasFace.value = true;

        final double faceWidth = scaledRect.width;
        final double faceHeight = scaledRect.height;

        final double minFaceSize = viewWidth * 0.4;
        final double maxFaceSize = viewWidth * 0.7;
        const double buffer = 10;

        FaceSizeZone newZone;

        final bool isTooSmall = faceWidth < (minFaceSize - buffer) || faceHeight < (minFaceSize - buffer);
        final bool isTooBig = faceWidth > (maxFaceSize + buffer) || faceHeight > (maxFaceSize + buffer);

        if (isTooSmall) {
          newZone = FaceSizeZone.tooSmall;
        } else if (isTooBig) {
          newZone = FaceSizeZone.tooBig;
        } else {
          newZone = FaceSizeZone.perfect;
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

        if (currentStep >= gestureDescriptions.length) return;

        if (_validateGesture(face)) {
          if (gestureStartTime == null) {
            gestureStartTime = DateTime.now();
          } else {
            final elapsed = DateTime.now().difference(gestureStartTime!).inMilliseconds;
            gestureProgress.value = (elapsed / 3000).clamp(0.0, 1.0);

            if (elapsed >= 3000) {
              gestureDescriptions[currentStep].statusKey!.value = "Approved";
              gestureStartTime = null;
              gestureProgress.value = 0.0;
              if(currentStep< gestureDescriptions.length) {
                currentStep++;
              }
              if (currentStep >= gestureDescriptions.length && !isCaptured.value) {
                await _captureImage();
              } else {
                currentInstruction = _buildInstruction();
              }
            }
          }
        } else {
          gestureStartTime = null;
          gestureProgress.value = 0.0;
        }
      } else {
        gestureStartTime = null;
        gestureProgress.value = 0.0;
      }
    }

    _isBusy = false;
    update();
  }

  bool _validateGesture(Face face) {
    if (currentStep >= gestureDescriptions.length) return false; // ✅ Prevent out-of-bounds access

    final gesture = gestureDescriptions[currentStep].step;
    switch (gesture) {
      case 'Smile':
        gestureDescriptions[currentStep].statusKey!.value = "In progress";
        return (face.smilingProbability ?? 0) > 0.6;

      case 'Blink':
        gestureDescriptions[currentStep].statusKey!.value = "In progress";
        final left = face.leftEyeOpenProbability;
        final right = face.rightEyeOpenProbability;

        final eyesClosed = (left != null && left < 0.3) && (right != null && right < 0.3);
        final eyesOpen = (left != null && left > 0.6) && (right != null && right > 0.6);

        if (!_eyesClosedDetected && eyesClosed) _eyesClosedDetected = true;
        if (_eyesClosedDetected && eyesOpen) {
          _blinkCompleted = true;
          _eyesClosedDetected = false;
        }

        return _blinkCompleted;

      case 'Look Left':
        gestureDescriptions[currentStep].statusKey!.value = "In progress";
        return face.headEulerAngleY != null && face.headEulerAngleY! > 15;

      case 'Look Right':
        gestureDescriptions[currentStep].statusKey!.value = "In progress";
        return face.headEulerAngleY != null && face.headEulerAngleY! < -15;

      case 'Look Straight':
        gestureDescriptions[currentStep].statusKey!.value = "In progress";
        final pitch = face.headEulerAngleX ?? 0;
        final yaw = face.headEulerAngleY ?? 0;
        final roll = face.headEulerAngleZ ?? 0;
        return (pitch > -5 && pitch < 5) && (yaw > -5 && yaw < 5) && (roll > -10 && roll < 10);

      default:
        return false;
    }
  }


  Future<void> _captureImage() async {
    try {
      final file = await cameraController!.takePicture();
      final originalFile = File(file.path);
      final originalBytes = await originalFile.readAsBytes();
      imageBase64 = base64Encode(originalBytes);

      final inputImage = InputImage.fromFilePath(originalFile.path);
      faceFeatures = await extractFaceFeatures(inputImage, faceDetector);

      // Extract TensorFlow face embedding
      try {
        faceEmbedding = await extractFaceEmbedding(inputImage);
        print('✅ TensorFlow face embedding extracted: ${faceEmbedding!.length} dimensions');
      } catch (e) {
        print('❌ Failed to extract TensorFlow embedding: $e');
        faceEmbedding = null;
      }

      File displayFile = originalFile;
      if (cameraController!.description.lensDirection == CameraLensDirection.front) {
        displayFile = await _flipImageHorizontally(originalFile);
      }

      capturedImage = displayFile;
      isCaptured.value = true;
      update();
    } catch (e) {
      print("Capture failed: $e");
    }
  }

  Future<File> _flipImageHorizontally(File file) async {
    final bytes = await file.readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) return file;

    final flipped = img.flipHorizontal(original);
    return file.writeAsBytes(img.encodeJpg(flipped));
  }

  bool isFaceInsideCircle(Rect faceRect, Offset center, double radius) {
    final corners = [
      faceRect.topLeft,
      faceRect.topRight,
      faceRect.bottomLeft,
      faceRect.bottomRight,
    ];
    for (final point in corners) {
      if ((point - center).distance > radius) return false;
    }
    return true;
  }

  String _buildInstruction() {
    //return 'Now: $gesture\n${gestureDescriptions[gesture]}';
    return gestureDescriptions[currentStep].title;
  }

  // void goToUserDetail(BuildContext context) {
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => UserDetailView(),
  //       settings: RouteSettings(arguments: {
  //         "image": imageBase64,
  //         "face_feature": faceFeatures,
  //       }),
  //     ),
  //   );
  // }


  Color getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppColors.loaderColors;
      case 'In progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  Future<void> registerUser(String name, String uuid) async {
    if (imageBase64 == null || faceFeatures == null) {
      CustomToast().showToast("Face data missing");
      return;
    }

    String userId = const Uuid().v1();
    UserModel user = UserModel(
      id: userId,
      name: name.trim().toUpperCase(),
      image: imageBase64!,
      registeredOn: DateTime.now().millisecondsSinceEpoch,
      faceFeatures: faceFeatures!,
      faceEmbedding: faceEmbedding, // TensorFlow face embedding
      uuid: uuid,
    );

    try {
      debugPrint('--------------userID: $userId');
      debugPrint('--------------user: ${user.toJson()}');
      if (faceEmbedding != null) {
        debugPrint('--------------faceEmbedding: ${faceEmbedding!.length} dimensions');
      }
      await FirebaseFirestore.instance.collection("users").doc(uuid).set(user.toJson());
      CustomToast().showToast("Registration Success!");
    } catch (e) {
      print("Registration Error: $e");
      CustomToast().showToast("Registration Failed! Try Again.");
    }
  }
  void openSettings() async {
    bool opened = await openAppSettings();
    if (!opened) {
      // Handle failure to open settings (optional)
      print("Failed to open app settings.");
    }
  }

}
