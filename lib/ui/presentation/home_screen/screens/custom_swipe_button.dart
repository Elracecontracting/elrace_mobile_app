import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/project_list_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:flutter_translate/flutter_translate.dart';
import 'package:el_race/ui/presentation/authenticate_face/view_model/authenticate_face_view_model.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart' hide CheckInET, CheckOutET;

class CustomSwipeButton extends StatefulWidget {
  const CustomSwipeButton({super.key});

  @override
  State<CustomSwipeButton> createState() => _CustomSwipeButtonState();
}

class _CustomSwipeButtonState extends State<CustomSwipeButton>
    with TickerProviderStateMixin {
  bool isCheckedIn = false;
  double dragOffset = 0.0;
  bool isDragging = false;
  late AnimationController _arrowController;
  late Animation<double> _arrowScaleAnimation;
  late Animation<double> _arrowTranslationAnimation;
  bool? matchResult; // null = no result, true = matched, false = not matched
  late AnimationController _checkmarkController;
  late Animation<double> _checkmarkScaleAnimation;
  AuthenticateFaceViewController? _faceController;
  CameraController? _cameraController;
  bool isProcessingFace = false;

  final double buttonWidth = 300.w;
  final double buttonHeight = 55.w;
  final double knobSize = 40.w;

  Color _getProgressiveColor() {
    if (!isDragging && !isCheckedIn) return Colors.white;
    if (isCheckedIn) return const Color(0xFF1E1E50);
    
    final progress = (dragOffset / (buttonWidth - knobSize)).clamp(0.0, 1.0);
    
    if (progress < 0.4) {
      return Color.lerp(const Color(0xFFE8E8F0), const Color(0xFFD0D0E0), (progress - 0.2) / 0.2)!;
    } else if (progress < 0.6) {
      return Color.lerp(const Color(0xFFD0D0E0), const Color(0xFF8080C0), (progress - 0.4) / 0.2)!;
    } else if (progress < 0.8) {
      return Color.lerp(const Color(0xFF8080C0), const Color(0xFF4040A0), (progress - 0.6) / 0.2)!;
    } else {
      return Color.lerp(const Color(0xFF4040A0), const Color(0xFF1E1E50), (progress - 0.8) / 0.2)!;
    }
  }

  void _resetPosition() {
    setState(() {
      dragOffset = isCheckedIn ? (buttonWidth - knobSize) : 0;
      isDragging = false;
      startSwipe = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCheckInState();
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _arrowTranslationAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
    _arrowScaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
    _checkmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkmarkScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkmarkController, curve: Curves.elasticOut),
    );
    _faceController = Get.put(AuthenticateFaceViewController());
  }

  @override
  void dispose() {
    _arrowController.dispose();
    _checkmarkController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  _loadCheckInState() {
    final storedState = SharedPref().getPreferenceBoolean('isCheckedIn');
    setState(() {
      isCheckedIn = storedState;
      dragOffset = isCheckedIn ? (buttonWidth - knobSize) : 0;
    });
  }

  void animateTo(double target, VoidCallback onComplete) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    late Animation<double> animation;
    animation =
        Tween<double>(begin: dragOffset, end: target).animate(controller);

    animation.addListener(() {
      setState(() {
        dragOffset = animation.value;
        if (dragOffset < 2.0) {
          startSwipe = false;
        }
      });
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        onComplete();
        controller.dispose();
      }
    });

    controller.forward();
  }

  bool startSwipe = false;
  void _onDragEnd() async {
    final threshold = buttonWidth * 0.6;
    if ((!isCheckedIn && dragOffset >= threshold) ||
        (isCheckedIn && dragOffset <= (buttonWidth - knobSize - threshold))) {
      final targetOffset = isCheckedIn ? 0.0 : (buttonWidth - knobSize);
      SharedPref()
          .setPreferencesBoolean('wasCheckedInBeforeFaceAuth', isCheckedIn);
      SharedPref().setPreferencesBoolean('isCheckedIn', isCheckedIn);
      if (!isCheckedIn) SharedPref().setPreferenceInt('checkInRecordId', 0);
      animateTo(targetOffset, () {
        showLeftToRightPopupClean(
          context: context,
          loginResponseModel: SharedPref.getLoginData(),
          isCheckedIn: isCheckedIn,
          onConfirmed: () async {
            context.read<HomeBloc>().add(const UpdateFaceRecognitionStatus(FaceRecognitionStatus.matching));
             _resetPosition();
          },
          onCancelled: _resetPosition,
        );
      });
    } else {
      animateTo(isCheckedIn ? (buttonWidth - knobSize) : 0.0, () {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onHorizontalDragStart: (_) => setState(() => isDragging = true),
            onHorizontalDragUpdate: (details) {
              setState(() {
                dragOffset += details.delta.dx;
                dragOffset = dragOffset.clamp(0.0, buttonWidth - knobSize);
                if (dragOffset > 2.0) {
                  startSwipe = true;
                } else {
                  startSwipe = false;
                }
              });
            },
            onHorizontalDragEnd: (_) => _onDragEnd(),
            child: Stack(
              children: [
                // Main swipe button container
                Container(
                  width: buttonWidth,
                  height: buttonHeight,
                  decoration: const BoxDecoration(
                    color: Colors.transparent, // Remove solid color background
                  ),
                  child: Stack(
                    children: [
                      // Conditional background for both check-in and check-out
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                isCheckedIn
                                    ? 'assets/png/swipe-bg-blue.png' // 👈 Checkout state
                                    : 'assets/png/swipe-button-inner.png', // 👈 Checkin state
                              ),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),

                      // Center text
                      if (isDragging)
                        Positioned.fill(
                          child: Container(
                            width: buttonWidth,
                            height: buttonHeight,
                            decoration: BoxDecoration(
                              color: _getProgressiveColor(),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      Center(
                        child: Text(
                          isCheckedIn
                              ? translate(
                                  'custom_swipe_button.swipe_to_check_out')
                              : translate(
                                  'custom_swipe_button.swipe_to_check_in'),
                          style: GoogleFonts.koulen(
                            color: isCheckedIn || startSwipe
                                ? Colors.white
                                : const Color(0xFF1A1A53),
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                // Arrow icon
                Positioned(
                  left: dragOffset + 19 - 16,
                  top: (buttonHeight - 39) / 2,
                  child: AnimatedBuilder(
                    animation: _arrowController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_arrowTranslationAnimation.value, 0),
                        child: child,
                      );
                    },
                    child: Image.asset(
                      isCheckedIn
                          ? 'assets/png/arrow_left.png'
                          : 'assets/png/arrow_right.png',
                      height: 45.w,
                      fit: BoxFit.cover,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
