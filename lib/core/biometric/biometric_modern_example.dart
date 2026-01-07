import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:el_race/core/biometric/biometric_auth_helper.dart';
import 'package:el_race/core/biometric/biometric_auth_controller.dart';
import 'package:el_race/core/biometric/biometric_auth_state.dart';

/// Modern example screen demonstrating the new biometric authentication UX
///
/// This screen shows:
/// - How to use BiometricAuthHelper for common scenarios
/// - How to use BiometricAuthController directly for custom flows
/// - State-driven UI updates
/// - Modern, elegant design patterns
class BiometricModernExampleScreen extends StatefulWidget {
  const BiometricModernExampleScreen({super.key});

  @override
  State<BiometricModernExampleScreen> createState() =>
      _BiometricModernExampleScreenState();
}

class _BiometricModernExampleScreenState
    extends State<BiometricModernExampleScreen> {
  final BiometricAuthController _controller =
      Get.put(BiometricAuthController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Modern Biometric Auth'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(context),
              const SizedBox(height: 32),

              // Status Card
              Obx(() => _buildStatusCard(context)),
              const SizedBox(height: 32),

              // Action Buttons
              _buildActionButtons(context),
              const SizedBox(height: 24),

              // Info Card
              _buildInfoCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.6),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.security,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Secure Authentication',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Modern biometric authentication with elegant UX',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final state = _controller.state;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    IconData icon;
    Color color;
    String title;
    String subtitle;

    if (state is BiometricAuthAvailable) {
      icon = state.hasFaceId ? Icons.face : Icons.fingerprint;
      color = Colors.green;
      title = '${state.biometricTypeName} Available';
      subtitle = 'Ready for secure authentication';
    } else if (state is BiometricAuthNotAvailable) {
      icon = Icons.block;
      color = Colors.red;
      title = 'Not Available';
      subtitle = state.reason;
    } else if (state is BiometricAuthCheckingAvailability) {
      icon = Icons.refresh;
      color = Colors.blue;
      title = 'Checking...';
      subtitle = 'Verifying biometric availability';
    } else {
      icon = Icons.info_outline;
      color = Colors.grey;
      title = 'Idle';
      subtitle = 'Not initialized';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Try Different Scenarios',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Attendance Check-in
        _ModernActionButton(
          icon: Icons.badge_outlined,
          title: 'Attendance Check-in',
          subtitle: 'Authenticate for attendance',
          onPressed: () async {
            final success =
                await BiometricAuthHelper.authenticateForAttendance(context);
            _showResult(success);
          },
        ),
        const SizedBox(height: 12),

        // Secure Action
        _ModernActionButton(
          icon: Icons.lock_outline,
          title: 'Secure Action',
          subtitle: 'Authenticate for sensitive operation',
          onPressed: () async {
            final success =
                await BiometricAuthHelper.authenticateForSecureAction(
              context,
              title: 'Confirm Action',
              subtitle: 'This action requires authentication',
            );
            _showResult(success);
          },
        ),
        const SizedBox(height: 12),

        // View Sensitive Data
        _ModernActionButton(
          icon: Icons.visibility_outlined,
          title: 'View Sensitive Data',
          subtitle: 'Unlock protected information',
          onPressed: () async {
            final success =
                await BiometricAuthHelper.authenticateForSensitiveData(context);
            _showResult(success);
          },
        ),
        const SizedBox(height: 12),

        // Custom Authentication
        _ModernActionButton(
          icon: Icons.tune,
          title: 'Custom Authentication',
          subtitle: 'Custom title and message',
          onPressed: () async {
            final success = await BiometricAuthHelper.authenticate(
              context: context,
              title: 'Custom Authentication',
              subtitle: 'This is a custom authentication flow',
              reason: 'Authenticate to proceed',
            );
            _showResult(success);
          },
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'About This Implementation',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('✅ Modern, elegant bottom sheet UI'),
          _buildInfoRow('✅ State-driven architecture'),
          _buildInfoRow('✅ Platform-adaptive icons & messaging'),
          _buildInfoRow('✅ Smooth animations & transitions'),
          _buildInfoRow('✅ Production-grade error handling'),
          _buildInfoRow('✅ No biometric data storage'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  void _showResult(bool success) {
    final message = success
        ? '✅ Authentication successful!'
        : '❌ Authentication failed or cancelled';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ModernActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const _ModernActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? Colors.grey[900] : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
