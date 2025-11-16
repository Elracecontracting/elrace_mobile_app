import 'package:camera/camera.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/authenticate_face/view_model/authenticate_face_view_model.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/project_list_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;

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
  final double buttonHeight = 48.w; // Reduced from 56.w to 48.w for shorter bar
  final double knobSize =
      35.w; // Reduced from 40.w to 35.w to maintain proportion

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
    final iconColor =
        _isVisualCheckedIn ? Colors.white : const Color(0xFF666666);
    final iconData =
        _isVisualCheckedIn ? Icons.chevron_left : Icons.chevron_right;
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final currentLocale = LocalizedApp.of(context).delegate.currentLocale;
    // مقدار التداخل بين السهمين
    const overlap = 12.0;
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
                borderRadius: BorderRadius.circular(
                    40), // Increased radius even more for whole widget
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
                    child: Opacity(
                      opacity: 0.6,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          image: const DecorationImage(
                            image: AssetImage('assets/newapp/check_in_background.png'),
                            fit: BoxFit.cover,
                          ),
                          // color: _isVisualCheckedIn
                          //     ? const Color(
                          //         0xFF1E1E50) // Dark blue when checked in
                          //     : const Color(
                          //         0xFFE8E8E8), // Light gray when checked out
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Stack(
                            children: [
                              // Inner shadow effect using gradient
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(40),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.0),
                                        Colors.black.withOpacity(0.0),
                                        Colors.black.withOpacity(0.15),
                                        Colors.black.withOpacity(0.25),
                                      ],
                                      stops: const [0.0, 0.3, 0.7, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              // Additional inner shadow from top
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(40),
                                      topRight: Radius.circular(40),
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.2),
                                        Colors.black.withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Center text with dynamic color
                  Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: GoogleFonts.akatab(
                        color: _isVisualCheckedIn
                            ? Colors
                                .white // White text when checked in (dark blue background)
                            : const Color(
                                0xFF1A1A53), // Dark blue text when checked out (light gray background)
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
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
                  PositionedDirectional(
                    start: _isVisualCheckedIn ? null : 8,
                    end: _isVisualCheckedIn ? 8 : null,
                    top: (buttonHeight - 32) / 2,
                    child: AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (context, _) {
                        return Transform.translate(
                          offset: Offset(_bounceAnimation.value, 0),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            // مهم: نكدّس القديم والجديد فوق بعض عشان العرض ما يتغيّرش أثناء السويتش
                            layoutBuilder: (current, previous) => Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                ...previous,
                                if (current != null) current,
                              ],
                            ),
                            transitionBuilder: (child, anim) =>
                                FadeTransition(opacity: anim, child: child),
                            child: SizedBox(
                              key: ValueKey(
                                  _isVisualCheckedIn), // نبدّل المجموعة ككتلة واحدة
                              width: 44, // اضبطه حسب ذوقك
                              height: 32, // نفس ارتفاع الأيقونة
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                clipBehavior: Clip.none,
                                children: [
                                  // السهم الأول (الأساسي)
                                  Icon(iconData,
                                      size: 32, weight: 900, color: iconColor),

                                  // السهم الثاني متداخل لليمين/اليسار حسب اتجاه اللغة
                                  Transform.translate(
                                    offset:
                                        Offset(isRTL ? overlap : -overlap, 0),
                                    child: Icon(iconData,
                                        size: 32,
                                        weight: 900,
                                        color: iconColor),
                                  ),
                                ],
                              ),
                            ),
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
                        borderRadius: BorderRadius.circular(40),
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
          SizedBox(height: 16.h),
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
                      final formatted = timer.toString().split('.').first.padLeft(8, "0");

                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
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
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
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
