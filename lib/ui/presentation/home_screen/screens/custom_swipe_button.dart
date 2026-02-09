import 'dart:async';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/data/services/auto_checkout_service.dart';
import 'package:el_race/data/services/checkin_reminder_notification_service.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/project_list_dialog.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_in_bloc/check_in_bloc.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_out_bloc/check_out_bloc.dart';
import 'package:el_race/utils/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  // Time display variables - updated via BlocListener
  String _checkInDisplayTime = '00:00:00';
  String _checkOutDisplayTime = '00:00:00';
  String _totalHoursDisplay = '00:00';
  
  // Timer للعداد التصاعدي
  Timer? _liveTimer;

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
    _loadDisplayTimes(); // Load saved times on init
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

  /// Load display times from SharedPref
  void _loadDisplayTimes() {
    final checkIn = SharedPref().getPreferenceString('checkInDisplayTime');
    final checkOut = SharedPref().getPreferenceString('checkOutDisplayTime');

    print('\n⏰ ===== LOADING DISPLAY TIMES =====');
    print('⏰ Reading from SharedPref:');
    print('⏰   checkInDisplayTime = "$checkIn"');
    print('⏰   checkOutDisplayTime = "$checkOut"');

    setState(() {
      _checkInDisplayTime =
          (checkIn.isEmpty || checkIn == '--:--') ? '00:00:00' : checkIn;
      _checkOutDisplayTime =
          (checkOut.isEmpty || checkOut == '--:--') ? '00:00:00' : checkOut;
      _calculateTotalHours();
    });

    print('⏰ After setState:');
    print('⏰   _checkInDisplayTime (GREEN/LEFT) = $_checkInDisplayTime');
    print('⏰   _checkOutDisplayTime (RED/RIGHT) = $_checkOutDisplayTime');
    print('⏰ ===================================\n');
  }

  /// Calculate total hours between check-in and check-out
  void _calculateTotalHours() {
    if (_checkInDisplayTime == '00:00:00' || _checkOutDisplayTime == '00:00:00') {
      _totalHoursDisplay = '00:00';
      return;
    }

    try {
      // Parse times (format: HH:mm:ss)
      final checkInParts = _checkInDisplayTime.split(':');
      final checkOutParts = _checkOutDisplayTime.split(':');

      if (checkInParts.length >= 2 && checkOutParts.length >= 2) {
        final checkInMinutes = int.parse(checkInParts[0]) * 60 + int.parse(checkInParts[1]);
        final checkOutMinutes = int.parse(checkOutParts[0]) * 60 + int.parse(checkOutParts[1]);

        int totalMinutes = checkOutMinutes - checkInMinutes;
        if (totalMinutes < 0) {
          totalMinutes += 24 * 60; // Handle crossing midnight
        }

        final hours = totalMinutes ~/ 60;
        final minutes = totalMinutes % 60;

        _totalHoursDisplay = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      _totalHoursDisplay = '00:00';
    }
  }
  
  /// حساب الوقت التصاعدي من check-in حتى الآن
  void _calculateLiveTotalHours() {
    if (_checkInDisplayTime == '00:00:00') {
      _totalHoursDisplay = '00:00';
      return;
    }

    try {
      // Parse check-in time (format: HH:mm:ss)
      final checkInParts = _checkInDisplayTime.split(':');
      if (checkInParts.length >= 2) {
        final checkInMinutes = int.parse(checkInParts[0]) * 60 + int.parse(checkInParts[1]);
        
        // Get current Dubai time
        final now = DateTime.now().toUtc().add(const Duration(hours: 4));
        final currentMinutes = now.hour * 60 + now.minute;

        int totalMinutes = currentMinutes - checkInMinutes;
        if (totalMinutes < 0) {
          totalMinutes += 24 * 60; // Handle crossing midnight
        }

        final hours = totalMinutes ~/ 60;
        final minutes = totalMinutes % 60;

        _totalHoursDisplay = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      _totalHoursDisplay = '00:00';
    }
  }
  
  /// بدء العداد التصاعدي
  void _startLiveTimer() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted && isCheckedIn) {
        setState(() {
          _calculateLiveTotalHours();
        });
      } else {
        timer.cancel();
      }
    });
    // Update immediately
    _calculateLiveTotalHours();
  }
  
  /// إيقاف العداد التصاعدي
  void _stopLiveTimer() {
    _liveTimer?.cancel();
    _liveTimer = null;
  }

  /// التحقق من أن الوقت الحالي ضمن فترة السماح بـ Check-in
  /// Check-in مسموح من 5:00 AM حتى 11:59 AM بتوقيت دبي
  bool _isCheckInAllowed() {
    final dubaiTime = DateTime.now().toUtc().add(const Duration(hours: 4));
    // Check-in مسموح من الساعة 5 صباحاً حتى 11:59 صباحاً
    if (dubaiTime.hour >= 5 && dubaiTime.hour < 12) {
      return true;
    }
    return false;
  }

  /// الحصول على الوقت الحالي بتوقيت دبي
  DateTime _getDubaiTime() {
    return DateTime.now().toUtc().add(const Duration(hours: 4));
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _arrowController.dispose();
    _checkmarkController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  _loadCheckInState() {
    final storedState = SharedPref().getPreferenceBoolean('isCheckedIn');

    // التحقق من نظام reset عند الساعة 5 صباحاً بتوقيت دبي
    if (storedState) {
      final checkInTime = SharedPref().getPreferenceInt('checkInTime');
      if (checkInTime != 0) {
        final checkInDateTime =
            DateTime.fromMillisecondsSinceEpoch(checkInTime);
        final now = DateTime.now();

        // احسب توقيت دبي (UTC+4)
        final dubaiNow = now.toUtc().add(const Duration(hours: 4));

        // احسب آخر وقت reset (5 صباحاً بتوقيت دبي)
        DateTime lastResetTime;
        if (dubaiNow.hour >= 5) {
          // اليوم الساعة 5 صباحاً
          lastResetTime =
              DateTime(dubaiNow.year, dubaiNow.month, dubaiNow.day, 5, 0);
        } else {
          // أمس الساعة 5 صباحاً
          final yesterday = dubaiNow.subtract(const Duration(days: 1));
          lastResetTime =
              DateTime(yesterday.year, yesterday.month, yesterday.day, 5, 0);
        }

        // تحويل checkInDateTime لتوقيت دبي
        final checkInDubaiTime =
            checkInDateTime.toUtc().add(const Duration(hours: 4));

        // DEBUG: طباعة معلومات التشخيص
        debugPrint('⏰ ===== CHECK-IN RESET DEBUG =====');
        debugPrint('⏰ Dubai Now: $dubaiNow');
        debugPrint('⏰ Check-in Time (stored): $checkInDateTime');
        debugPrint('⏰ Check-in Dubai Time: $checkInDubaiTime');
        debugPrint('⏰ Last Reset Time (5 AM): $lastResetTime');
        debugPrint(
            '⏰ Should reset? ${checkInDubaiTime.isBefore(lastResetTime)}');
        debugPrint('⏰ ================================');

        // إذا كان check-in قبل آخر وقت reset، يجب reset الحالة
        if (checkInDubaiTime.isBefore(lastResetTime)) {
          debugPrint(
              '⏰ Check-in was before 5:00 AM reset time. Resetting state...');
          debugPrint('⏰ Check-in Dubai time: $checkInDubaiTime');
          debugPrint('⏰ Last reset time: $lastResetTime');

          // Reset check in/out state
          SharedPref().setPreferencesBoolean('isCheckedIn', false);
          SharedPref().setPreferenceInt('checkInRecordId', 0);
          SharedPref().setPreferencesString('checkInDisplayTime', '00:00:00');
          SharedPref().setPreferencesString('checkOutDisplayTime', '00:00:00');
          SharedPref().removePreference('checkInProjectId');
          SharedPref().removePreference('checkInBranchId');
          SharedPref().removePreference('checkInAuthMethod');
          SharedPref().setPreferenceInt('checkInTime', 0);

          // Update notifications
          CheckInReminderNotificationService().updateReminders();

          // إيقاف العداد التصاعدي
          _stopLiveTimer();

          setState(() {
            isCheckedIn = false;
            _isVisualCheckedIn = false;
            dragOffset = 0;
            _checkInDisplayTime = '00:00:00';
            _checkOutDisplayTime = '00:00:00';
            _totalHoursDisplay = '00:00';
          });
          return;
        }
      }
    }

    setState(() {
      isCheckedIn = storedState;
      _isVisualCheckedIn = storedState; // Sync visual state with actual state
      dragOffset = isCheckedIn ? (buttonWidth - knobSize) : 0;
    });
    
    // بدء العداد إذا كان checked in
    if (isCheckedIn && _checkOutDisplayTime == '00:00:00') {
      _startLiveTimer();
    }
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
      // التحقق من وقت Check-in قبل السماح (فقط عند محاولة check-in وليس check-out)
      if (!isCheckedIn && !_isCheckInAllowed()) {
        final dubaiTime = _getDubaiTime();
        final timeStr =
            '${dubaiTime.hour.toString().padLeft(2, '0')}:${dubaiTime.minute.toString().padLeft(2, '0')}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Check-in is not available after 11:59 AM. Current time: $timeStr',
              style: const TextStyle(fontSize: 14),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        _resetPosition();
        return;
      }

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
  ///
  /// Note: Check-in/Check-out is global and unified
  /// - Timer applies to all projects (8 hours fixed)
  /// - Project selection is for display/reference only
  /// - Detailed time management handled via job missions
  ///
  /// NOTE: The 8 working hours are global and shared across all projects.
  ///       Switching projects does NOT reset or create a new timer.
  void _performCheckInOut() async {
    if (!isCheckedIn) {
      // Perform global check-in
      sl.get<CheckInBloc>().add(CheckInET());
      Get.find<TimerController>().startTimer();

      // جدولة Auto Check-out في الساعة 5 مساءً
      await AutoCheckoutService.scheduleAutoCheckout();
      debugPrint('✅ Auto checkout scheduled for 5:00 PM after check-in');

      // جدولة إشعارات التذكير بـ check out (من 4 مساءً - 5 مساءً)
      await CheckInReminderNotificationService().updateReminders();
      debugPrint('✅ Check-out reminder notifications scheduled');
    } else {
      // Perform global check-out (manual)
      final checkInRecordId = SharedPref().getPreferenceInt('checkInRecordId');
      if (checkInRecordId != 0) {
        sl
            .get<CheckOutBloc>()
            .add(CheckOutET(checkInRecordId, isAutoCheckout: false));
        Get.find<TimerController>().stopTimer();

        // إلغاء جدولة Auto Check-out عند Check-out اليدوي
        await AutoCheckoutService.cancelAutoCheckout();
        debugPrint('✅ Auto checkout cancelled after manual check-out');

        // Clear saved check-in project (used for display only)
        SharedPref().removePreference('checkInProjectId');
        SharedPref().removePreference('checkInBranchId');
        SharedPref().removePreference('checkInAuthMethod');

        // تحديث الإشعارات لجدولة تذكيرات check in (من 8 صباحاً - 9 صباحاً)
        await CheckInReminderNotificationService().updateReminders();
        debugPrint('✅ Check-in reminder notifications scheduled');
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
    return MultiBlocListener(
      listeners: [
        // Listen to CheckInBloc to update time display after successful check-in
        BlocListener<CheckInBloc, CheckInState>(
          bloc: sl.get<CheckInBloc>(),
          listener: (context, state) {
            if (state is CheckedInST || state is CheckInWarningST) {
              // Reload display times after successful check-in
              _loadDisplayTimes();
              // بدء العداد التصاعدي
              _startLiveTimer();
            } else if (state is CheckInBlockedST) {
              // Check-in is blocked due to time restriction (after 11:59 AM)
              _resetPosition();
              final timeStr =
                  '${state.currentDubaiTime.hour.toString().padLeft(2, '0')}:${state.currentDubaiTime.minute.toString().padLeft(2, '0')}';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Check-in is not available after 11:59 AM. Current time: $timeStr',
                    style: const TextStyle(fontSize: 14),
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
        ),
        // Listen to CheckOutBloc to update time display after successful check-out
        BlocListener<CheckOutBloc, CheckOutState>(
          bloc: sl.get<CheckOutBloc>(),
          listener: (context, state) {
            if (state is CheckedOutST || state is CheckOutWarningST) {
              // Reload display times after successful check-out
              _loadDisplayTimes();
              // إيقاف العداد التصاعدي
              _stopLiveTimer();
            }
          },
        ),
      ],
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Finger animation GIF on top left (behind swipe)
            Positioned(
              left: -80,
              top: -80,
              child: Opacity(
                opacity: 0.4,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(23),
                  ),
                  child: Image.asset(
                    'assets/png/finger.gif',
                    width: 150,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Column(
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
                  color: const Color(0xFFFFFFFF),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
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
                                  color: const Color(0xFF151544),
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
                                transform: Matrix4.identity()
                                  ..scale(scaleX, 1.0),
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
            SizedBox(
              width:
                  buttonWidth * 1.0, // Adjusted width for timeline
              child: Column(
                children: [
                  // Time labels above the timeline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left time label - shows check-in time
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _checkInDisplayTime,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // Total hours text in the middle
                  Text(
                          '$_totalHoursDisplay H',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                      // Right time label - shows check-out time
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _checkOutDisplayTime,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8.h),

                  // Timeline with circles on the line
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
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
                                color: Color(0xFF78DBAD),
                              ),
                            ),

                            Expanded(
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF78DBAD),
                                      Color(0xFF008FC7),
                                    ],
                                  ),
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
                                color: Color(0xFF008FC7),
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
          ],
        ),
      ),
    );
  }
}
