import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:el_race/core/biometric/android/android_biometric_controller.dart';

/// Premium Android biometric authentication bottom sheet
/// Material 3 design with fast, confident motion
class AndroidBiometricSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final String reason;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;
  final VoidCallback? onError;

  const AndroidBiometricSheet({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.reason,
    this.onSuccess,
    this.onCancel,
    this.onError,
  }) : super(key: key);

  @override
  State<AndroidBiometricSheet> createState() => _AndroidBiometricSheetState();
}

class _AndroidBiometricSheetState extends State<AndroidBiometricSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  final AndroidBiometricController _controller =
      Get.find<AndroidBiometricController>();
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
      duration: const Duration(milliseconds: 250),
    );

    // Slide up animation - faster than iOS
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Fade in animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Pulse animation for icon
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
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

    // Very brief delay for sheet to appear (feels snappier on Android)
    await Future.delayed(const Duration(milliseconds: 100));

    final success = await _controller.authenticate(reason: widget.reason);

    if (!mounted) return;

    if (success) {
      _onSuccess();
    } else {
      if (_controller.state == AndroidBiometricState.cancelled) {
        _onCancel();
      } else {
        _onError();
      }
    }
  }

  void _onSuccess() {
    HapticFeedback.mediumImpact();
    widget.onSuccess?.call();
    _dismissWithAnimation();
  }

  void _onCancel() {
    HapticFeedback.lightImpact();
    widget.onCancel?.call();
    _dismissWithAnimation();
  }

  void _onError() {
    HapticFeedback.heavyImpact();
    widget.onError?.call();
    // Show error briefly then allow retry or dismiss
    Future.delayed(const Duration(milliseconds: 2000), () {
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => _onCancel(), // Tap backdrop to cancel
      child: Container(
        color: Colors.black54,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: Offset(
                    0,
                    MediaQuery.of(context).size.height *
                        0.3 *
                        _slideAnimation.value),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: child,
                ),
              ),
            );
          },
          child: GestureDetector(
            onTap: () {}, // Prevent dismiss when tapping sheet
            child: _buildBiometricSheet(context, colorScheme),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricSheet(BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBiometricIcon(colorScheme),
              const SizedBox(height: 20),
              _buildTitle(colorScheme),
              const SizedBox(height: 8),
              _buildSubtitle(colorScheme),
              const SizedBox(height: 16),
              Obx(() => _buildStateIndicator(context, colorScheme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricIcon(ColorScheme colorScheme) {
    return Obx(() {
      final state = _controller.state;
      final iconColor = _getIconColor(state, colorScheme);

      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = state == AndroidBiometricState.authenticating
              ? _pulseAnimation.value
              : 1.0;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForState(state),
                size: 36,
                color: iconColor,
              ),
            ),
          );
        },
      );
    });
  }

  IconData _getIconForState(AndroidBiometricState state) {
    switch (state) {
      case AndroidBiometricState.success:
        return Icons.check_circle;
      case AndroidBiometricState.failed:
        return Icons.error_outline;
      case AndroidBiometricState.authenticating:
      case AndroidBiometricState.idle:
      case AndroidBiometricState.cancelled:
      case AndroidBiometricState.notAvailable:
        return Icons.fingerprint;
    }
  }

  Color _getIconColor(AndroidBiometricState state, ColorScheme colorScheme) {
    switch (state) {
      case AndroidBiometricState.success:
        return colorScheme.primary;
      case AndroidBiometricState.failed:
        return colorScheme.error;
      case AndroidBiometricState.authenticating:
        return colorScheme.primary;
      case AndroidBiometricState.idle:
      case AndroidBiometricState.cancelled:
      case AndroidBiometricState.notAvailable:
        return colorScheme.onSurfaceVariant;
    }
  }

  Widget _buildTitle(ColorScheme colorScheme) {
    return Text(
      widget.title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0.15,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(ColorScheme colorScheme) {
    return Text(
      widget.subtitle,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStateIndicator(BuildContext context, ColorScheme colorScheme) {
    final state = _controller.state;

    if (state == AndroidBiometricState.failed) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            Text(
              _controller.errorMessage,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _startAuthenticationImmediately(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (state == AndroidBiometricState.success) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: colorScheme.primary,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Success',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    if (state == AndroidBiometricState.authenticating) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Touch sensor',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Show Android biometric authentication sheet (Material 3)
/// Returns true if authenticated successfully
Future<bool> showAndroidBiometricSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required String reason,
}) async {
  if (!Platform.isAndroid) return false;

  bool authenticated = false;

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: false,
    builder: (context) => AndroidBiometricSheet(
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
