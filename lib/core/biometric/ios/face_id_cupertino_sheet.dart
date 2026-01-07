import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:el_race/core/biometric/ios/face_id_auth_controller.dart';

/// Premium iOS Face ID authentication sheet
/// Designed to feel like Apple Pay / iCloud Keychain
class FaceIdCupertinoSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final String reason;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;
  final VoidCallback? onError;

  const FaceIdCupertinoSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.reason,
    this.onSuccess,
    this.onCancel,
    this.onError,
  });

  @override
  State<FaceIdCupertinoSheet> createState() => _FaceIdCupertinoSheetState();
}

class _FaceIdCupertinoSheetState extends State<FaceIdCupertinoSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _pulseAnimation;

  final FaceIdAuthController _controller = Get.find<FaceIdAuthController>();
  bool _hasStartedAuth = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAuthenticationImmediately();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Entrance animation: scale from 0.96 to 1.0
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Entrance animation: fade in
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Continuous pulse animation for Face ID icon
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  /// Start authentication IMMEDIATELY (no delay)
  Future<void> _startAuthenticationImmediately() async {
    if (_hasStartedAuth) return;
    _hasStartedAuth = true;

    // Start pulse animation
    _animationController.repeat(reverse: true);

    // Wait a tiny moment for sheet to appear (feels more natural)
    await Future.delayed(const Duration(milliseconds: 150));

    final success = await _controller.authenticate(reason: widget.reason);

    if (!mounted) return;

    if (success) {
      _onSuccess();
    } else {
      if (_controller.state == FaceIdState.cancelled) {
        _onCancel();
      } else {
        _onError();
      }
    }
  }

  void _onSuccess() {
    HapticFeedback.lightImpact();
    widget.onSuccess?.call();
    _dismissWithAnimation();
  }

  void _onCancel() {
    HapticFeedback.lightImpact();
    widget.onCancel?.call();
    _dismissWithAnimation();
  }

  void _onError() {
    HapticFeedback.mediumImpact();
    widget.onError?.call();
    // Show error briefly then dismiss
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _dismissWithAnimation();
    });
  }

  Future<void> _dismissWithAnimation() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Tapping backdrop cancels
        _onCancel();
      },
      child: Container(
        color: CupertinoColors.black.withOpacity(0.4),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent dismiss when tapping sheet
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: _buildFaceIdSheet(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaceIdSheet() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.darkColor.withOpacity(0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: CupertinoColors.white.withOpacity(0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFaceIdIcon(),
                const SizedBox(height: 24),
                _buildTitle(),
                const SizedBox(height: 8),
                _buildSubtitle(),
                const SizedBox(height: 16),
                Obx(() => _buildStateIndicator()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaceIdIcon() {
    return Obx(() {
      final state = _controller.state;
      final iconColor = _getIconColor(state);

      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale =
              state == FaceIdState.authenticating ? _pulseAnimation.value : 1.0;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  CupertinoIcons.person_crop_circle_badge_checkmark,
                  size: 44,
                  color: iconColor,
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Color _getIconColor(FaceIdState state) {
    switch (state) {
      case FaceIdState.success:
        return CupertinoColors.systemGreen;
      case FaceIdState.failed:
        return CupertinoColors.systemRed;
      case FaceIdState.authenticating:
        return CupertinoColors.systemBlue;
      case FaceIdState.cancelled:
      case FaceIdState.notAvailable:
      case FaceIdState.idle:
        return CupertinoColors.white;
    }
  }

  Widget _buildTitle() {
    return Text(
      widget.title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.white,
        letterSpacing: 0.2,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    return Text(
      widget.subtitle,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: CupertinoColors.white.withOpacity(0.7),
        height: 1.3,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStateIndicator() {
    final state = _controller.state;

    if (state == FaceIdState.failed) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          _controller.errorMessage,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.systemRed,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (state == FaceIdState.success) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: CupertinoColors.systemGreen,
              size: 16,
            ),
            SizedBox(width: 6),
            Text(
              'Success',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.systemGreen,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Show Face ID authentication sheet (iOS-style)
/// Returns true if authenticated successfully
Future<bool> showFaceIdCupertinoSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required String reason,
}) async {
  bool authenticated = false;

  await showCupertinoModalPopup(
    context: context,
    barrierColor: CupertinoColors.black
        .withOpacity(0.0), // Transparent - sheet has its own backdrop
    builder: (context) => FaceIdCupertinoSheet(
      title: title,
      subtitle: subtitle,
      reason: reason,
      onSuccess: () => authenticated = true,
      onCancel: () => authenticated = false,
      onError: () => authenticated = false,
    ),
  );

  return authenticated;
}
