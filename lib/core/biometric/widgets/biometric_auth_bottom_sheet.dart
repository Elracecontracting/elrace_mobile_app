import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:el_race/core/biometric/biometric_auth_controller.dart';
import 'package:el_race/core/biometric/biometric_auth_state.dart';

/// Modern, elegant biometric authentication bottom sheet
///
/// Inspired by Apple Pay, Revolut, and modern fintech apps.
/// Platform-adaptive with smooth animations and clear UX.
class BiometricAuthBottomSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final String reason;
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;
  final bool biometricOnly;

  const BiometricAuthBottomSheet({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.onSuccess,
    this.onCancel,
    this.biometricOnly = true,
  }) : super(key: key);

  /// Show the biometric authentication bottom sheet
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String reason,
    bool biometricOnly = true,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => BiometricAuthBottomSheet(
        title: title,
        subtitle: subtitle,
        reason: reason,
        onSuccess: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
        biometricOnly: biometricOnly,
      ),
    );

    return result ?? false;
  }

  @override
  State<BiometricAuthBottomSheet> createState() =>
      _BiometricAuthBottomSheetState();
}

class _BiometricAuthBottomSheetState extends State<BiometricAuthBottomSheet>
    with SingleTickerProviderStateMixin {
  late BiometricAuthController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(BiometricAuthController());

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();

    // Listen to state changes
    ever(_controller.rx, _handleStateChange);
  }

  void _handleStateChange(BiometricAuthState state) {
    if (state is BiometricAuthSuccess) {
      // Success - animate out and close
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          widget.onSuccess();
        }
      });
    }
  }

  void _authenticate() async {
    await _controller.authenticate(
      reason: widget.reason,
      biometricOnly: widget.biometricOnly,
    );
  }

  void _cancel() {
    _controller.cancel();
    widget.onCancel?.call();
  }

  @override
  void dispose() {
    _animationController.dispose();
    Get.delete<BiometricAuthController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Obx(() => _buildContent(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final state = _controller.state;

    if (state is BiometricAuthCheckingAvailability) {
      return _buildLoadingContent(context);
    } else if (state is BiometricAuthAvailable) {
      return _buildAvailableContent(context, state);
    } else if (state is BiometricAuthAuthenticating) {
      return _buildAuthenticatingContent(context, state);
    } else if (state is BiometricAuthSuccess) {
      return _buildSuccessContent(context);
    } else if (state is BiometricAuthFailure) {
      return _buildFailureContent(context, state);
    } else if (state is BiometricAuthLockedOut) {
      return _buildLockedOutContent(context, state);
    } else if (state is BiometricAuthNotAvailable) {
      return _buildNotAvailableContent(context, state);
    }

    return _buildIdleContent(context);
  }

  Widget _buildLoadingContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          Text(
            'Checking biometrics...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableContent(
      BuildContext context, BiometricAuthAvailable state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          _BiometricIcon(
            hasFaceId: state.hasFaceId,
            hasFingerprint: state.hasFingerprint,
            size: 80,
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            widget.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            widget.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Authenticate Button
          _ModernButton(
            onPressed: _authenticate,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  state.hasFaceId ? Icons.face : Icons.fingerprint,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Authenticate with ${state.biometricTypeName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Cancel Button
          TextButton(
            onPressed: _cancel,
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticatingContent(
      BuildContext context, BiometricAuthAuthenticating state) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing icon
          _PulsingBiometricIcon(
            hasFaceId: state.biometricTypeName.toLowerCase().contains('face'),
            size: 80,
          ),
          const SizedBox(height: 24),

          Text(
            'Authenticating...',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Please use your ${state.biometricTypeName}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon with animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          Text(
            'Authenticated!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureContent(
      BuildContext context, BiometricAuthFailure state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Authentication Failed',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            state.errorMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Retry or Close
          if (state.canRetry) ...[
            _ModernButton(
              onPressed: _authenticate,
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          TextButton(
            onPressed: _cancel,
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedOutContent(
      BuildContext context, BiometricAuthLockedOut state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 48,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            state.isPermanent ? 'Locked Out' : 'Temporarily Locked',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: _cancel,
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotAvailableContent(
      BuildContext context, BiometricAuthNotAvailable state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.block,
              size: 48,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Not Available',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.reason,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: _cancel,
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Initializing...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// Platform-adaptive biometric icon
class _BiometricIcon extends StatelessWidget {
  final bool hasFaceId;
  final bool hasFingerprint;
  final double size;

  const _BiometricIcon({
    required this.hasFaceId,
    required this.hasFingerprint,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        hasFaceId ? Icons.face : Icons.fingerprint,
        size: size * 0.6,
        color: theme.primaryColor,
      ),
    );
  }
}

/// Pulsing biometric icon for authenticating state
class _PulsingBiometricIcon extends StatefulWidget {
  final bool hasFaceId;
  final double size;

  const _PulsingBiometricIcon({
    required this.hasFaceId,
    required this.size,
  });

  @override
  State<_PulsingBiometricIcon> createState() => _PulsingBiometricIconState();
}

class _PulsingBiometricIconState extends State<_PulsingBiometricIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.hasFaceId ? Icons.face : Icons.fingerprint,
              size: widget.size * 0.6,
              color: theme.primaryColor,
            ),
          ),
        );
      },
    );
  }
}

/// Modern button widget
class _ModernButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _ModernButton({
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: child,
      ),
    );
  }
}
