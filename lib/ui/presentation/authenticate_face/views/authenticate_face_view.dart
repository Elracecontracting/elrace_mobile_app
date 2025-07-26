import 'package:camera/camera.dart';
import 'package:el_race/resources/app_colors.dart';
import 'package:el_race/resources/app_string.dart';
import 'package:el_race/ui/presentation/signin/data/model.dart';
import 'package:el_race/ui/widgets/detector_view.dart';
import 'package:el_race/ui/widgets/scanning_animation/animated_view.dart';
import 'package:el_race/utils/extensions/size_extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../view_model/authenticate_face_view_model.dart';

class AuthenticateFaceView extends GetView<AuthenticateFaceViewController> {
  final LoginResponseModel loginResponseModel;
  final bool isLeftToRight;
  final void Function(bool)? onCheckInStatusChanged;


  const AuthenticateFaceView({
    Key? key,
    required this.loginResponseModel,
    required this.isLeftToRight,
    this.onCheckInStatusChanged, // ✅ Add this line
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthenticateFaceViewController>(
      init: AuthenticateFaceViewController(),
      builder: (controller) {
        controller.isLeftToRight = isLeftToRight;
        controller.onCheckInStatusChanged = onCheckInStatusChanged;
        return SafeArea(
          child: Scaffold(
            backgroundColor: AppColors.primaryBlack,
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: AppColors.primaryBlack,
              iconTheme: const IconThemeData(color: Colors.black),
              elevation: 0,
            ),
            body: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 50),
                              child: Text(
                                textAlign: TextAlign.center,
                                "Welcome back! Use face scan to sign in securely.",
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 24,
                                  color: AppColors.textColor,
                                ),
                              ),
                            ),
                            Center(
                              child: SizedBox(
                                width: 200, // Set the width for the Lottie animation
                                height: 120, // Set the height for the Lottie animation
                                child: Visibility(
                                    visible: !controller.hasFace.value,
                                    child: Lottie.asset(AppString.inside)),
                              ),
                            ),

                            const SizedBox(height: 20),
                            Stack(
                              children: [
                                controller.capturedImage != null
                                    ? Container(
                                  padding: EdgeInsets.only(top: 0.013.sh),
                                  alignment: Alignment.center,
                                  child: CircleAvatar(
                                    radius: 0.15.sh,
                                    backgroundColor: const Color(0xffD9D9D9),
                                    backgroundImage: FileImage(controller.capturedImage!),
                                  ),
                                )
                                    : Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    TweenAnimationBuilder<double>(
                                      tween: Tween<double>(
                                          begin: 0,
                                          end: controller.gestureProgress.value),
                                      duration: const Duration(milliseconds: 300),
                                      builder: (context, value, child) {
                                        return SizedBox(
                                          height: 0.31.sh,
                                          width: 0.31.sh,
                                          child: CircularProgressIndicator(
                                            value: value,
                                            strokeWidth: 15,
                                            backgroundColor: controller.hasFace.value?AppColors.loaderColors.withAlpha(50):AppColors.red.withAlpha(100),
                                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.loaderColors),
                                          ),
                                        );
                                      },
                                    ),
                                    Container(
                                      alignment: Alignment.center,
                                      height: 0.30.sh,
                                      width: 0.30.sh,
                                      decoration: const BoxDecoration(shape: BoxShape.circle),
                                      child: DetectorView(
                                        cameraSize: Size(0.30.sh, 0.30.sh),
                                        onController: controller.setCameraController,
                                        title: 'Face Detector',
                                        onImage: (inputImage) {
                                          controller.onCheckInStatusChanged = onCheckInStatusChanged;
                                          controller.processImage(inputImage, context);
                                        },
                                        initialCameraLensDirection: CameraLensDirection.front,
                                      ),
                                    ),
                                  ],
                                ),
                                controller.isMatching.value
                                    ? Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 0.015.sh),
                                    child: const AnimatedView(),
                                  ),
                                )
                                    : const SizedBox(),
                              ],
                            ),
                            const SizedBox(height: 20),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                final slideAnimation = Tween<Offset>(
                                  begin: const Offset(0.0, 0.3), // slide in from bottom
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOut,
                                ));

                                return SlideTransition(
                                  position: slideAnimation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                controller.hasFace.value
                                    ? controller.runtimeInstruction.value
                                    : "No face detected",
                                key: ValueKey(controller.runtimeInstruction.value), // must change for animation to trigger
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: controller.hasFace.value
                                      ? AppColors.loaderColors
                                      : AppColors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // ...controller.instructions.map((tip) => Padding(
                            //   padding: const EdgeInsets.symmetric(vertical: 10.0),
                            //   child: Row(
                            //     children: [
                            //       const Icon(Icons.check_circle_rounded,
                            //           color: AppColors.loaderColors,
                            //           size: 24),
                            //       const SizedBox(width: 10),
                            //       Expanded(
                            //         child: Text(
                            //           tip,
                            //           style: TextStyle(
                            //             fontSize: 0.020.sh,
                            //             fontWeight: FontWeight.w400,
                            //             color: Colors.grey,
                            //           ),
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // )),

                          ],
                        )
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
}
