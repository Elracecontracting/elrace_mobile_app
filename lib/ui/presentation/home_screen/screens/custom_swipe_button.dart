import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/project_list_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:flutter_translate/flutter_translate.dart';
import 'package:el_race/ui/presentation/authenticate_face/view_model/authenticate_face_view_model.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart' hide CheckInET, CheckOutET;
import '../widgets/timer_controller.dart';

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
  bool _isVisualCheckedIn = false; // Visual state for transitions
  late AnimationController _arrowController;
  late Animation<double> _arrowScaleAnimation;
  late Animation<double> _arrowTranslationAnimation;
  bool? matchResult; // null = no result, true = matched, false = not matched
  late AnimationController _checkmarkController;
  late Animation<double> _checkmarkScaleAnimation;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
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
      return Color.lerp(const Color(0xFFE8E8F0), const Color(0xFFD0D0E0),
          (progress - 0.2) / 0.2)!;
    } else if (progress < 0.6) {
      return Color.lerp(const Color(0xFFD0D0E0), const Color(0xFF8080C0),
          (progress - 0.4) / 0.2)!;
    } else if (progress < 0.8) {
      return Color.lerp(const Color(0xFF8080C0), const Color(0xFF4040A0),
          (progress - 0.6) / 0.2)!;
    } else {
      return Color.lerp(const Color(0xFF4040A0), const Color(0xFF1E1E50),
          (progress - 0.8) / 0.2)!;
    }
  }

  void _resetPosition() {
    setState(() {
      dragOffset = isCheckedIn ? (buttonWidth - knobSize) : 0;
      isDragging = false;
      startSwipe = false;
      _isVisualCheckedIn =
          isCheckedIn; // Reset visual state to match actual state
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

    // Forward movement animation controller
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _faceController = Get.put(AuthenticateFaceViewController());

    // Start forward movement animation with a small delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _bounceController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _arrowController.dispose();
    _checkmarkController.dispose();
    _bounceController.dispose();
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
            context.read<HomeBloc>().add(const UpdateFaceRecognitionStatus(
                FaceRecognitionStatus.matching));
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main swipe button container
          GestureDetector(
            onHorizontalDragStart: (_) => setState(() => isDragging = true),
            onHorizontalDragUpdate: (details) {
              setState(() {
                dragOffset += details.delta.dx;
                dragOffset = dragOffset.clamp(0.0, buttonWidth - knobSize);

                // Calculate swipe progress for smooth visual transitions
                final progress = dragOffset / (buttonWidth - knobSize);

                if (dragOffset > 2.0) {
                  startSwipe = true;
                  // Smooth visual state transition based on swipe progress
                  if (progress > 0.3) {
                    if (_isVisualCheckedIn != !isCheckedIn) {
                      _isVisualCheckedIn = !isCheckedIn;
                      // Haptic feedback when visual state changes
                      HapticFeedback.lightImpact();
                    }
                  } else {
                    if (_isVisualCheckedIn != isCheckedIn) {
                      _isVisualCheckedIn = isCheckedIn;
                    }
                  }
                } else {
                  startSwipe = false;
                  if (_isVisualCheckedIn != isCheckedIn) {
                    _isVisualCheckedIn = isCheckedIn;
                  }
                }
              });
            },
            onHorizontalDragEnd: (_) => _onDragEnd(),
            child: Container(
              width: buttonWidth,
              height: buttonHeight,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(27.5), // Highly rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Dynamic background that transitions between light gray and dark blue
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(27.5),
                        color: _isVisualCheckedIn
                            ? const Color(
                                0xFF1E1E50) // Dark blue when checked in
                            : const Color(
                                0xFFE8E8E8), // Light gray when checked out
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center text with dynamic color
                  Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: GoogleFonts.inter(
                        color: _isVisualCheckedIn
                            ? Colors
                                .white // White text when checked in (dark blue background)
                            : const Color(
                                0xFF1A1A53), // Dark blue text when checked out (light gray background)
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      child: Text(
                        _isVisualCheckedIn
                            ? translate(
                                'custom_swipe_button.swipe_to_check_out')
                            : translate(
                                'custom_swipe_button.swipe_to_check_in'),
                      ),
                    ),
                  ),

                  // Dynamic chevron icons that change position and direction based on state
                  Positioned(
                    left: _isVisualCheckedIn
                        ? null
                        : 8, // Left side when checked out
                    right: _isVisualCheckedIn
                        ? 8
                        : null, // Right side when checked in
                    top: (buttonHeight - 36) / 2,
                    child: AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_bounceAnimation.value, 0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                  _isVisualCheckedIn
                                      ? Icons
                                          .chevron_left // Left-pointing when on right side (check in)
                                      : Icons
                                          .chevron_right, // Right-pointing when on left side (check out)
                                  key: ValueKey(_isVisualCheckedIn),
                                  color: _isVisualCheckedIn
                                      ? Colors
                                          .white // White arrows when checked in (dark blue background)
                                      : const Color(
                                          0xFF666666), // Dark gray arrows when checked out
                                  size: 36,
                                  weight: 900,
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(-25, 0),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    _isVisualCheckedIn
                                        ? Icons
                                            .chevron_left // Left-pointing when on right side (check in)
                                        : Icons
                                            .chevron_right, // Right-pointing when on left side (check out)
                                    key: ValueKey(_isVisualCheckedIn),
                                    color: _isVisualCheckedIn
                                        ? Colors
                                            .white // White arrows when checked in (dark blue background)
                                        : const Color(
                                            0xFF666666), // Dark gray arrows when checked out
                                    size: 36,
                                    weight: 900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Visual swipe progress indicator
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: dragOffset + knobSize,
                      height: buttonHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(27.5),
                        color: _isVisualCheckedIn
                            ? const Color(0xFF1E1E50)
                                .withOpacity(0.3) // Semi-transparent dark blue
                            : const Color(0xFFE8E8E8).withOpacity(
                                0.3), // Semi-transparent light gray
                      ),
                    ),
                  ),

                  // Swipe knob (invisible but functional)
                  Positioned(
                    left: dragOffset,
                    top: (buttonHeight - knobSize) / 2,
                    child: Container(
                      width: knobSize,
                      height: knobSize,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(knobSize / 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Timeline component below the button
          SizedBox(height: 20.h),
          Container(
            width: buttonWidth * 0.7, // Decreased width to 70% of button width
            child: Column(
              children: [
                // Time labels above the timeline
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left time label - shows remaining time from TimerController
                    Obx(() {
                      final timer = Get.find<TimerController>().timeLeft.value;
                      final formatted =
                          timer.toString().split('.').first.padLeft(8, "0");

                      return Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF1E1E50),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          formatted,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1E1E50),
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }),

                    // Right time label - shows 00:00:00 when checked out
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF1E1E50),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '00:00:00',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1E1E50),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8.h),

                // Timeline line with ellipse markers in Stack
                Stack(
                  children: [
                    // Bright white horizontal line
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),

                    // Left marker - Green ellipse image
                    Positioned(
                      left: -6,
                      top: -8,
                      child: Image.asset(
                        'assets/png/Ellipse_green.png',
                        width: 16,
                        height: 16,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Right marker - Red ellipse image
                    Positioned(
                      right: -6,
                      top: -8,
                      child: Image.asset(
                        'assets/png/Ellipse_red.png',
                        width: 16,
                        height: 16,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
