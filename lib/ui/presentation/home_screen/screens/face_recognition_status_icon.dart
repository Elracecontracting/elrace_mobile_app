import 'package:camera/camera.dart';
import 'package:el_race/resources/app_string.dart';
import 'package:el_race/ui/presentation/authenticate_face/view_model/authenticate_face_view_model.dart';
import 'package:el_race/ui/widgets/detector_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:lottie/lottie.dart';

import '../bloc/home_bloc.dart';

class FaceRecognitionStatusIcon extends StatefulWidget {
  final FaceRecognitionStatus status;
  const FaceRecognitionStatusIcon({Key? key, required this.status})
      : super(key: key);

  @override
  State<FaceRecognitionStatusIcon> createState() =>
      _FaceRecognitionStatusIconState();
}

class _FaceRecognitionStatusIconState extends State<FaceRecognitionStatusIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    if (widget.status != FaceRecognitionStatus.idle) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant FaceRecognitionStatusIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == FaceRecognitionStatus.matching) {
      _controller.repeat();
    } else if (widget.status != FaceRecognitionStatus.idle &&
        oldWidget.status == FaceRecognitionStatus.idle) {
      _controller.forward(from: 0.0);
    } else if (widget.status == FaceRecognitionStatus.idle) {
      _controller.reset();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status == FaceRecognitionStatus.idle)
      return const SizedBox.shrink();
    if (widget.status == FaceRecognitionStatus.matching) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: RotationTransition(
              turns: _controller,
              child: Icon(
                Icons.autorenew,
                color: Colors.green.shade300,
                size: 40,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Container(
            width: 320.w,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(10))),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200, // Set the width for the Lottie animation
                  height: 120, // Set the height for the Lottie animation
                  child: Visibility(
                      visible: true, child: Lottie.asset(AppString.inside)),
                ),
                Container(
                  alignment: Alignment.center,
                  height: 0.30.sh,
                  width: 0.30.sh,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: GetBuilder<AuthenticateFaceViewController>(
                      init: AuthenticateFaceViewController(),
                      builder: (controller) {
                        return DetectorView(
                          cameraSize: Size(0.30.sh, 0.30.sh),
                          onController: controller.setCameraController,
                          title: 'Face Detector',
                          onImage: (inputImage) {
                            controller.processImage(inputImage, context);
                          },
                          initialCameraLensDirection: CameraLensDirection.front,
                        );
                      }),
                ),
                const SizedBox(
                  height: 6,
                ),

              ],
            ),
          ),
        ],
      );
    }
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        widget.status == FaceRecognitionStatus.matched
            ? Icons.check_circle
            : Icons.close,
        color: widget.status == FaceRecognitionStatus.matched
            ? Colors.green
            : Colors.red,
        size: 50,
      ),
    );
  }
}
