// The full conversion of the StatefulWidget-based `AuthenticateFaceView` to GetX architecture is
// very large. Below is the start of the conversion process. We'll create a GetX Controller and
// a View class. You can continue the logic modularly in the controller.
// 1. Controller: authenticate_face_controller.dart
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/data/models/user_model.dart';
import 'package:el_race/ui/presentation/home_screen/screens/home_screen.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/timer_controller.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_in_bloc/check_in_bloc.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_out_bloc/check_out_bloc.dart';
import 'package:el_race/ui/widgets/custom_toast.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/extensions/size_extension.dart';
import 'package:el_race/utils/extract_face_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_face_api/face_api.dart' as regula;
// import 'package:flutter_face_api/flutter_face_api.dart' as regula;
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../utils/di.dart';



class AuthenticateFaceViewController extends GetxController {
  final faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: true,
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  FaceFeatures? faceFeatures;
  // var image1 = regula.MatchFacesImage();
  // var image2 = regula.MatchFacesImage();

  var similarity = ''.obs;
  var users = [].obs;
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


  @override
  void onInit() {
    super.onInit();
    InternetConnectionChecker().onStatusChange.listen((InternetConnectionStatus status) {
      hasInternet.value = status == InternetConnectionStatus.connected;
    });
    steps = ['Blink', 'Look Straight'];
    super.onInit();
  }

  @override
  void onClose() {
    faceDetector.close();
    super.onClose();
  }

  Future<void> setImage(Uint8List imageToAuthenticate) async {
    // image2.bitmap = base64Encode(imageToAuthenticate);
    // image2.imageType = regula.ImageType.PRINTED;
  }

  double compareFaces(FaceFeatures face1, FaceFeatures face2) {
    double distEar1 = euclideanDistance(face1.rightEar!, face1.leftEar!);
    double distEar2 = euclideanDistance(face2.rightEar!, face2.leftEar!);

    double ratioEar = distEar1 / distEar2;

    double distEye1 = euclideanDistance(face1.rightEye!, face1.leftEye!);
    double distEye2 = euclideanDistance(face2.rightEye!, face2.leftEye!);

    double ratioEye = distEye1 / distEye2;

    double distCheek1 = euclideanDistance(face1.rightCheek!, face1.leftCheek!);
    double distCheek2 = euclideanDistance(face2.rightCheek!, face2.leftCheek!);

    double ratioCheek = distCheek1 / distCheek2;

    double distMouth1 = euclideanDistance(face1.rightMouth!, face1.leftMouth!);
    double distMouth2 = euclideanDistance(face2.rightMouth!, face2.leftMouth!);

    double ratioMouth = distMouth1 / distMouth2;

    double distNoseToMouth1 = euclideanDistance(face1.noseBase!, face1.bottomMouth!);
    double distNoseToMouth2 = euclideanDistance(face2.noseBase!, face2.bottomMouth!);

    double ratioNoseToMouth = distNoseToMouth1 / distNoseToMouth2;

    double ratio = (ratioEye + ratioEar + ratioCheek + ratioMouth + ratioNoseToMouth) / 5;
    log(ratio.toString(), name: "Ratio");

    return ratio;
  }

  double euclideanDistance(Points p1, Points p2) {
    return math.sqrt(math.pow((p1.x! - p2.x!), 2) + math.pow((p1.y! - p2.y!), 2));
  }

  void fetchUsersAndMatchFace(BuildContext context, {required bool isLeftToRight,void Function(bool)? onCheckInStatusChanged}) {
    FirebaseFirestore.instance.collection("users").get().catchError((e) {
      log("Getting User Error: $e");
      isMatching.value = false;
      update();
      CustomToast().showToast("Something went wrong. Please try again.");
    }).then((snap) {
      if (snap.docs.isNotEmpty) {
        users.clear();
        for (var doc in snap.docs) {
          UserModel user = UserModel.fromJson(doc.data());
          double sim = compareFaces(faceFeatures!, user.faceFeatures!);
          if (sim >= 0.8 && sim <= 1.5) {
            users.add([user, sim]);
          }
        }
        users.sort((a, b) => (((a.last as double) - 1).abs()).compareTo(((b.last as double) - 1).abs()));
        matchFaces(context, isLeftToRight: isLeftToRight,onCheckInStatusChanged: onCheckInStatusChanged);
      } else {
        showFailureDialog(title: "No Users Registered", description: "Make sure users are registered first before Authenticating.");
      }
    });
  }

  void matchFaces(BuildContext context, {required bool isLeftToRight,   void Function(bool)? onCheckInStatusChanged}) async {
    print("[DEBUG] Performing ${isLeftToRight ? "Check-In" : "Check-Out"}");

    bool faceMatched = false;
    for (List user in users) {
      UserModel userModel = user.first as UserModel;
      double sim = user.last as double;
      // Print all user info (using toJson if available)
      print("[DEBUG] User info: ");
      try {
        print(userModel.toJson());
      } catch (e) {
        print(userModel);
      }
      print("[DEBUG] Similarity: $sim");
      // Adjust threshold as needed for your use case
      if (sim >= 0.8 && sim <= 1.5) {
        print('matched');
        faceMatched = true;
        loggingUser.value = userModel;

        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
        print('get ');

        await Future.delayed(const Duration(seconds: 2));
        Navigator.of(context).pop(); // Close loading

        if (isLeftToRight) {
          print('isLeftToRight');
          sl.get<CheckInBloc>().add(CheckInET());
          onCheckInStatusChanged?.call(true);
          Get.find<TimerController>().startTimer();
        } else {
          print('shared');
          final checkInRecordId = SharedPref().getPreferenceInt('checkInRecordId');
          debugPrint('checkInRecord: $checkInRecordId ');
          if (checkInRecordId != 0) {
            sl.get<CheckOutBloc>().add(CheckOutET(checkInRecordId));
            onCheckInStatusChanged?.call(false);
            Get.find<TimerController>().stopTimer();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Check-In Record ID not found.')),
            );
          }
        }

        /// ✅ Only navigate if face matched
        Util.fetchHomeScreenData(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );

        break;
      }


    }

    if (!faceMatched) {
      if (trialNumber.value == 4) {
        trialNumber.value = 1;
      } else {
        trialNumber.value++;
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Authentication Failed"),
          content: const Text("Face doesn't match. Please try again."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  ),
                );

                // ⬇️ Reset swipe button via callback
                onCheckInStatusChanged?.call(false);
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
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

  bool isLeftToRight = true;

  Future<void> processImage(InputImage inputImage, BuildContext context) async {

    if (!canProcess || isBusy) return;
    isBusy = true;

    final faces = await faceDetector.processImage(inputImage);
    hasFace.value = false;

    if (faces.isNotEmpty && cameraController != null && cameraController!.value.isInitialized) {
      final face = faces.first;
      final camera = cameraController!.description;

      // Get the preview size from the controller
      final Size imageSize = cameraController!.value.previewSize!;
      final Rect faceRect = face.boundingBox;

      // Calculate scale factors between image and your detector preview area (0.30.sh x 0.30.sh)
      final double viewWidth = 0.30.sh;
      final double viewHeight = 0.30.sh;

      // In portrait mode, ML Kit uses landscape coordinates — so swap
      final double scaleX = viewWidth / imageSize.height;
      final double scaleY = viewHeight / imageSize.width;

      // Flip horizontally for front camera
      final bool isFrontCamera = camera.lensDirection == CameraLensDirection.front;

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

      final Offset circleCenter = Offset(viewWidth / 2, viewHeight / 2);
      final double circleRadius = viewWidth / 2;
      bool passed = false;
      if (isFaceInsideCircle(scaledRect, circleCenter, circleRadius)){
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

        switch (steps[currentStep]) {
          case 'Blink':
            final leftEyeOpen = face.leftEyeOpenProbability;
            final rightEyeOpen = face.rightEyeOpenProbability;

            print('leftEyeOpen: $leftEyeOpen, rightEyeOpen: $rightEyeOpen');

            final eyesClosed = (leftEyeOpen != null && leftEyeOpen < 0.3) &&
                (rightEyeOpen != null && rightEyeOpen < 0.3);

            final eyesOpen = (leftEyeOpen != null && leftEyeOpen > 0.6) &&
                (rightEyeOpen != null && rightEyeOpen > 0.6);

            if (!eyesClosedDetected && eyesClosed) {
              print('Eyes closed detected!');
              eyesClosedDetected = true;
            }

            if (eyesClosedDetected && eyesOpen) {
              print('Eyes open detected!');
              blinkCompleted = true;
              eyesClosedDetected = false;
            }

            passed = blinkCompleted;
            break;
          case 'Look Straight':
            final pitch = face.headEulerAngleX ?? 0; // up/down
            final yaw = face.headEulerAngleY ?? 0;   // left/right
            final roll = face.headEulerAngleZ ?? 0;  // tilt (optional)

            // Tolerance range: only accept if the face is mostly straight
            passed = (pitch > -5 && pitch < 5) &&
                (yaw > -5 && yaw < 5) &&
                (roll > -10 && roll < 10); // roll check is optional
            break;
        }

        if (passed) {
          if (gestureStartTime == null) {
            gestureStartTime = DateTime.now();
          } else {
            final elapsed = DateTime.now().difference(gestureStartTime!).inMilliseconds;
            gestureProgress.value = (elapsed / 1000).clamp(0.0, 1.0);

            if (elapsed >= 1000) {
              gestureStartTime = null;
              gestureProgress.value = 0.0;
              currentStep++;
              if (currentStep >= steps.length && !isCaptured.value) {
                await _captureImage(context);
              }
            }
          }
        } else {
          gestureStartTime = null;
          gestureProgress.value = 0.0;
        }
      }  else {
        hasFace.value = false;
        gestureStartTime = null;
        gestureProgress.value = 0.0;
      }
    }

    isBusy = false;
    update();
  }

  Future<void> _captureImage(BuildContext context) async {
    try {
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
      if (cameraController!.description.lensDirection == CameraLensDirection.front) {
        displayImage = await _flipImageHorizontally(originalFile);
      }

      // Now update UI just once with the display image
      capturedImage = displayImage;
      isMatching.value = true;
      update();

      fetchUsersAndMatchFace(
        context,
        isLeftToRight: isLeftToRight, // ✅ Use controller field
        onCheckInStatusChanged: onCheckInStatusChanged,
      );

    } catch (e) {
      print("Capture failed: $e");
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

  bool isFaceInsideCircle(Rect faceRect, Offset circleCenter, double circleRadius) {
    final corners = [
      faceRect.topLeft,
      faceRect.topRight,
      faceRect.bottomLeft,
      faceRect.bottomRight,
    ];

    for (final point in corners) {
      if ((point - circleCenter).distance > circleRadius) {
        return false; // A corner is outside
      }
    }

    return true;
  }

  void openSettings() async {
    bool opened = await openAppSettings();
    if (!opened) {
      // Handle failure to open settings (optional)
      print("Failed to open app settings.");
    }
  }
}

enum FaceSizeZone { tooSmall, perfect, tooBig }
