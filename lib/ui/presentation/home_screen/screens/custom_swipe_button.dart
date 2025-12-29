import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/project_list_dialog.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_in_bloc/check_in_bloc.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_out_bloc/check_out_bloc.dart';
import 'package:el_race/utils/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:get/get.dart';
import 'package:el_race/core/services/app_config_service.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:el_race/core/biometric/unified_biometric_helper.dart';

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
  bool? matchResult; // null = no result, true = matched, false = not matched
  late AnimationController _checkmarkController;
  late AnimationController _bounceController;
  bool isProcessingFace = false;

  final double buttonWidth = 300.w;
  final double buttonHeight = 48.w; // Reduced from 56.w to 48.w for shorter bar
  final double knobSize =
      35.w; // Reduced from 40.w to 35.w to maintain proportion

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

    _checkmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Forward movement animation controller
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    if (!AppConfigService.instance.isTestMode) {
      if (mounted) {
        _bounceController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _arrowController.dispose();
    _checkmarkController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  _loadCheckInState() {
    final storedState = SharedPref().getPreferenceBoolean('isCheckedIn');
    setState(() {
      isCheckedIn = storedState;
      _isVisualCheckedIn = storedState; // Sync visual state with actual state
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
        // Update visual state based on animation progress
        final progress = dragOffset / (buttonWidth - knobSize);
        if (progress > 0.5) {
          _isVisualCheckedIn = true;
        } else {
          _isVisualCheckedIn = false;
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
            // In Test Mode, bypass authentication and perform action directly
            if (AppConfigService.instance.isTestMode) {
              _performCheckInOut();
              _resetPosition();
              return;
            }

            // Show platform-specific biometric authentication (Face ID on iOS, Fingerprint on Android)
            final authenticated =
                await UnifiedBiometricHelper.authenticateForAttendance(context);

            if (authenticated) {
              // Authentication successful - perform check-in/out
              _performCheckInOut();
            } else {
              // Authentication failed or cancelled - reset position
              _resetPosition();
            }
          },
          onCancelled: () {
            // User cancelled the dialog - reset position
            _resetPosition();
          },
        );
      });
    } else {
      animateTo(isCheckedIn ? (buttonWidth - knobSize) : 0.0, () {});
    }
  }

  /// Perform check-in or check-out action
  void _performCheckInOut() {
    if (!isCheckedIn) {
      // Perform check-in
      sl.get<CheckInBloc>().add(CheckInET());
      Get.find<TimerController>().startTimer();
    } else {
      // Perform check-out
      final checkInRecordId = SharedPref().getPreferenceInt('checkInRecordId');
      if (checkInRecordId != 0) {
        sl.get<CheckOutBloc>().add(CheckOutET(checkInRecordId));
        Get.find<TimerController>().stopTimer();
        // Clear saved check-in project after successful check-out
        SharedPref().removePreference('checkInProjectId');
        SharedPref().removePreference('checkInBranchId');
        SharedPref().removePreference('checkInAuthMethod');
      }
    }

    setState(() {
      isCheckedIn = !isCheckedIn;
      _isVisualCheckedIn = isCheckedIn;
      dragOffset = isCheckedIn ? (buttonWidth - knobSize) : 0;
    });
    SharedPref().setPreferencesBoolean('isCheckedIn', isCheckedIn);
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
                  if (progress > 0.5) {
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
                borderRadius: BorderRadius.circular(40),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Base background image
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                                'assets/newapp/check_in_background.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    // Inner shadow overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    ),

                    // Gradient overlay that appears with opacity based on swipe progress
                    Positioned.fill(
                      child: Opacity(
                        opacity: _isVisualCheckedIn
                            ? 1.0
                            : (dragOffset / (buttonWidth - knobSize))
                                .clamp(0.0, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(40)),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xFF151544),
                                Color(0xFF151544),
                                Color(0xFF151544),
                                Color(0xFF151544),
                                Color(0xFF151544),
                                Color(0xFF3535AA),
                              ],
                              stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Center text with dynamic color and opacity transition
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // First text (SWIPE TO CHECK IN) - fades out during swipe
                          Opacity(
                            opacity: _isVisualCheckedIn
                                ? 0.0
                                : 1.0 -
                                    (dragOffset / (buttonWidth - knobSize))
                                        .clamp(0.0, 1.0),
                            child: Text(
                              translate(
                                  'custom_swipe_button.swipe_to_check_in'),
                              style: GoogleFonts.akatab(
                                color: const Color(0xFF151544),
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          // Second text (SWIPE TO CHECK OUT) - fades in during swipe
                          Opacity(
                            opacity: _isVisualCheckedIn
                                ? 1.0
                                : (dragOffset / (buttonWidth - knobSize))
                                    .clamp(0.0, 1.0),
                            child: Text(
                              translate(
                                  'custom_swipe_button.swipe_to_check_out'),
                              style: GoogleFonts.akatab(
                                color: const Color(0xFFFFFFFF),
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dynamic chevron GIF that changes based on state
                    Positioned(
                      left: _isVisualCheckedIn ? null : dragOffset + 2,
                      right: _isVisualCheckedIn
                          ? (buttonWidth - dragOffset - knobSize)
                          : null,
                      top: (buttonHeight - 40) / 2,
                      child: Builder(
                        builder: (context) {
                          // Calculate progress (0.0 to 1.0)
                          final progress =
                              (dragOffset / (buttonWidth - knobSize))
                                  .clamp(0.0, 1.0);

                          // Calculate opacity and scaleX based on progress
                          // Gradually fade out and shrink horizontally as approaching center
                          // Then fade in and expand horizontally after passing center
                          double opacity;
                          double scaleX;

                          if (progress <= 0.5) {
                            // First half: gradually fade out and shrink towards center
                            opacity = 1.0 - (progress * 2); // 1.0 -> 0.0
                            scaleX = 1.0 - (progress * 2); // 1.0 -> 0.0
                          } else {
                            // Second half: gradually fade in and expand from center
                            opacity = (progress - 0.5) * 2; // 0.0 -> 1.0
                            scaleX = (progress - 0.5) * 2; // 0.0 -> 1.0
                          }

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, anim) =>
                                FadeTransition(opacity: anim, child: child),
                            child: Transform(
                              transform: Matrix4.identity()..scale(scaleX, 1.0),
                              alignment: Alignment.center,
                              child: Opacity(
                                opacity: opacity,
                                child: Transform.flip(
                                  key: ValueKey(_isVisualCheckedIn),
                                  flipX: _isVisualCheckedIn,
                                  child: ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                      _isVisualCheckedIn
                                          ? const Color(0xFF81819d)
                                          : const Color(0xFF848484),
                                      BlendMode.srcIn,
                                    ),
                                    child: Image.asset(
                                      'assets/gif/arrow_animation.gif',
                                      width: 50,
                                      height: 36.88,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Old icon animation code (commented for reference)
                    // PositionedDirectional(
                    //   start: _isVisualCheckedIn ? null : 8,
                    //   end: _isVisualCheckedIn ? 8 : null,
                    //   top: (buttonHeight - 32) / 2,
                    //   child: AnimatedBuilder(
                    //     animation: _bounceAnimation,
                    //     builder: (context, _) {
                    //       return Transform.translate(
                    //         offset: Offset(_bounceAnimation.value, 0),
                    //         child: AnimatedSwitcher(
                    //           duration: const Duration(milliseconds: 300),
                    //           layoutBuilder: (current, previous) => Stack(
                    //             alignment: Alignment.center,
                    //             clipBehavior: Clip.none,
                    //             children: [
                    //               ...previous,
                    //               if (current != null) current,
                    //             ],
                    //           ),
                    //           transitionBuilder: (child, anim) =>
                    //               FadeTransition(opacity: anim, child: child),
                    //           child: SizedBox(
                    //             key: ValueKey(_isVisualCheckedIn),
                    //             width: 44,
                    //             height: 32,
                    //             child: Stack(
                    //               alignment: Alignment.centerLeft,
                    //               clipBehavior: Clip.none,
                    //               children: [
                    //                 Icon(iconData, size: 32, weight: 900, color: iconColor),
                    //                 Transform.translate(
                    //                   offset: Offset(isRTL ? overlap : -overlap, 0),
                    //                   child: Icon(iconData, size: 32, weight: 900, color: iconColor),
                    //                 ),
                    //               ],
                    //             ),
                    //           ),
                    //         ),
                    //       );
                    //     },
                    //   ),
                    // ),

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
          ),

          // Timeline component below the button
          SizedBox(height: 24.h),
          Container(
            width: buttonWidth * 0.9, // Decreased width to 70% of button width
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

                SizedBox(height: 5.h),

                // Timeline with circles on the line
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left green circle
                      Container(
                        width: 15.w,
                        height: 15.w,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          image: const DecorationImage(
                            image: AssetImage('assets/newapp/green_polit.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      Expanded(
                        child: Container(
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
                      ),

                      // Right red circle
                      Container(
                        width: 15.w,
                        height: 15.w,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          image: const DecorationImage(
                            image: AssetImage('assets/newapp/red_polit.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
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
