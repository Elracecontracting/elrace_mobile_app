import 'package:camera/camera.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/resources/app_colors.dart';
import 'package:el_race/resources/app_string.dart';
import 'package:el_race/ui/presentation/home_screen/screens/home_screen.dart';
import 'package:el_race/ui/presentation/register_face/view_model/register_face_view_model.dart';
import 'package:el_race/ui/widgets/custom_button.dart';
import 'package:el_race/ui/widgets/custom_toast.dart';
import 'package:el_race/ui/widgets/detector_view.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/extensions/size_extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
// For generating user ID


class RegisterFaceView extends StatefulWidget {
  const RegisterFaceView({super.key});

  @override
  State<RegisterFaceView> createState() => _RegisterFaceViewState();
}

class _RegisterFaceViewState extends State<RegisterFaceView> with TickerProviderStateMixin{
  //  late AnimationController _arrowController;
  // late Animation<double> _arrowScaleAnimation;

  // late AnimationController _checkmarkController;
  // late Animation<double> _checkmarkScaleAnimation;

  // CameraController? _cameraController;
  // AuthenticateFaceViewController? _faceController;
  // bool? matchResult;
  // bool isProcessingFace = false;
  // late HomeBloc homeBloc;

  // @override
  // void initState() {
  //   super.initState();
  //   homeBloc = HomeBloc.get(context);
  //   _initializeAnimationControllers();
  //   _faceController = Get.put(AuthenticateFaceViewController());
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _startFaceRecognitionFlow();
  //   });
  // }

  // void _initializeAnimationControllers() {
  //   _arrowController = AnimationController(
  //     vsync: this,
  //     duration: const Duration(milliseconds: 800),
  //   )..repeat(reverse: true);

  //   _arrowScaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
  //     CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
  //   );

  //   _checkmarkController = AnimationController(
  //     vsync: this,
  //     duration: const Duration(milliseconds: 600),
  //   );

  //   _checkmarkScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
  //     CurvedAnimation(parent: _checkmarkController, curve: Curves.elasticOut),
  //   );
  // }

  // Future<void> _initializeCamera() async {
  //   final cameras = await availableCameras();
  //   final frontCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
  //   _cameraController = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);
  //   await _cameraController!.initialize();
  //   _faceController?.setCameraController(_cameraController!);
  // }

  // Future<void> _startFaceRecognitionFlow() async {
  //   try {
  //     final uuid = SharedPref.getLoginData().result?.data?.emp_id;
  //     final name = SharedPref.getLoginData().result?.data?.name;

  //     if (uuid == null || uuid.isEmpty || name == null || name.isEmpty) {
  //       CustomToast().showToast("User data is missing");
  //       return;
  //     }
  //     // Step 1: Initialize camera
  //     await _initializeCamera();

  //     // Step 2: Take a picture
  //     final file = await _cameraController!.takePicture();
  //     final imageFile = File(file.path);

  //     // Step 3: Convert to base64
  //     final imageBytes = await imageFile.readAsBytes();
  //     final imageBase64 = base64Encode(imageBytes);

  //     // Step 4: Prepare InputImage for face feature extraction
  //     final inputImage = InputImage.fromFilePath(imageFile.path);

  //     // Step 5: Extract face features
  //     final faceFeatures = await extractFaceFeatures(inputImage, _faceController!.faceDetector);

  //     // Step 6: Check if face data exists
  //     if (imageBase64.isEmpty || faceFeatures == null) {
  //       CustomToast().showToast("Face data missing");
  //       return;
  //     }

  //     // Step 7: Build user model
  //     final userId = const Uuid().v1();
  //     final user = UserModel(
  //       id: userId,
  //       name: name.trim().toUpperCase(),
  //       image: imageBase64,
  //       registeredOn: DateTime.now().millisecondsSinceEpoch,
  //       faceFeatures: faceFeatures,
  //       uuid: uuid,
  //     );

  //     // Step 8: Store in Firestore
  //     await FirebaseFirestore.instance.collection("users").doc(uuid).set(user.toJson());

  //     CustomToast().showToast("SignIn Success!");
  //     Util.pushPageAndRemoveRoutes(const HomeScreen(), context);
  //   } catch (e) {
  //     debugPrint("SignIn Error: $e");
  //     CustomToast().showToast("SignIn Failed! Try Again.");
  //     await Future.delayed(const Duration(seconds: 2));
  //     _startFaceRecognitionFlow();
  //   } finally {
  //     await _cameraController?.dispose();
  //     _cameraController = null;
  //   }
  // }

  // @override
  // void dispose() {
  //   _arrowController.dispose();
  //   _checkmarkController.dispose();
  //   _cameraController?.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RegisterFaceViewController>(
      init: RegisterFaceViewController(),
      builder: (controller) {
        return SafeArea(
          child: Scaffold(
            backgroundColor: AppColors.primaryBlack,
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: AppColors.appBarColor,
              iconTheme: const IconThemeData(color: Colors.black),
              elevation: 0,
            ),
            body: Column(
              children: [

                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Visibility(
                            visible: controller.capturedImage == null,
                            child: Center(
                              child: SizedBox(
                                width: 200, // Set the width for the Lottie animation
                                height: 120, // Set the height for the Lottie animation
                                child: getLottieAnimation(controller),
                              ),
                            ),
                          ),
                  
                  
                          const SizedBox(height: 20),
                          controller.capturedImage != null
                              ? CircleAvatar(
                            radius: 0.15.sh,
                            backgroundImage: FileImage(controller.capturedImage!),
                          )
                              : Stack(
                            alignment: Alignment.center,
                            children: [
                              // TweenAnimationBuilder<double>(
                              //   tween: Tween(begin: 0, end: controller.gestureProgress.value),
                              //   duration: const Duration(milliseconds: 300),
                              //   builder: (_, value, __) {
                              //     return SizedBox(
                              //       height: 0.31.sh,
                              //       width: 0.31.sh,
                              //       child: CircularProgressIndicator(
                              //         value: value,
                              //         strokeWidth: 15,
                              //         backgroundColor: controller.hasFace.value?AppColors.loaderColors.withAlpha(50):AppColors.red.withAlpha(100),
                              //         valueColor: const AlwaysStoppedAnimation(AppColors.loaderColors),
                              //       ),
                              //     );
                              //   },
                              // ),
                              DetectorView(
                                cameraSize: Size(0.40.sh, 0.40.sh),
                                title: 'Face Detector',
                                onController: controller.setCameraController,
                                onImage: (inputImage) => controller.processImage(inputImage, context),
                                initialCameraLensDirection: CameraLensDirection.front,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // AnimatedSwitcher(
                          //   duration: const Duration(milliseconds: 400),
                          //   transitionBuilder: (Widget child, Animation<double> animation) {
                          //     final slideAnimation = Tween<Offset>(
                          //       begin: const Offset(0.0, 0.3), // slide in from bottom
                          //       end: Offset.zero,
                          //     ).animate(CurvedAnimation(
                          //       parent: animation,
                          //       curve: Curves.easeOut,
                          //     ));
                  
                          //     return SlideTransition(
                          //       position: slideAnimation,
                          //       child: FadeTransition(
                          //         opacity: animation,
                          //         child: child,
                          //       ),
                          //     );
                          //   },
                          //   child: Text(
                          //     controller.capturedImage!=null?"":controller.hasFace.value
                          //         ? controller.runtimeInstruction.value
                          //         : "No face detected",
                          //     key: ValueKey(controller.runtimeInstruction.value), // must change for animation to trigger
                          //     style: TextStyle(
                          //       fontWeight: FontWeight.w600,
                          //       fontSize: 14,
                          //       color: controller.hasFace.value
                          //           ? AppColors.loaderColors
                          //           : AppColors.red,
                          //     ),
                          //     textAlign: TextAlign.center,
                          //   ),
                          // ),
                          const SizedBox(height: 20,),
                          ListView.builder(
                            itemCount: controller.gestureDescriptions.length,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                            itemBuilder: (context, index) {
                              final item = controller.gestureDescriptions[index];
                              final color = controller.getStatusColor(item.statusKey!.value);
                  
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: Row(
                                  children: [
                                    AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        transitionBuilder: (child, animation) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0.0, 0.3),
                                              end: Offset.zero,
                                            ).animate(CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOut,
                                            )),
                                            child: FadeTransition(opacity: animation, child: child),
                                          );
                                        },
                                        child: Icon(item.statusKey!.value == "Approved"?Icons.check_circle_rounded:item.statusKey!.value == "In progress"?Icons.radio_button_checked:Icons.radio_button_unchecked,
                                            color: color,
                                            size: 24)
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 0.020.sh,
                                          fontWeight: FontWeight.w400,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 30),
                          if (controller.capturedImage != null)
                            CustomButton(
                              text: "Home Screen",
                              onTap: () async {
                                  SharedPref().setPreferencesBoolean('isRegistered', true); // Save registration status
                                final name =SharedPref.getLoginData().result?.data?.name;

                                if (name == null || name.isEmpty) {
                                  CustomToast().showToast("User name is missing");
                                  return;
                                }

                                  await controller.registerUser(name, SharedPref.getLoginData().result?.data?.emp_id ?? "");

                                Util.pushPage(const HomeScreen(), context);
                              },
                            )

                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: controller.hasInternet.value ? 0 : 20,
                  width: double.infinity,
                  color: AppColors.lightRed,
                  alignment: Alignment.center,
                  child: controller.hasInternet.value
                      ? const SizedBox.shrink()
                      : const Text(
                    "No Internet Connection",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

  }

  Widget getLottieAnimation(controller) {
    if (controller.currentStep < controller.gestureDescriptions.length) {
      final gestureKey = controller.gestureDescriptions[controller.currentStep].step;
      final animationPath = controller.gestureAnimations[gestureKey] ?? AppString.inside;
      return Lottie.asset(controller.hasFace.value ? animationPath : AppString.inside);
    } else {
      return const SizedBox();
    }
  }
}