import 'package:flutter/material.dart';
import 'package:el_race/core/biometric/android/android_biometric_helper.dart';

/// Example screen showing Android biometric authentication
/// Demonstrates the fast Material 3 biometric experience
class AndroidBiometricExampleScreen extends StatefulWidget {
  const AndroidBiometricExampleScreen({Key? key}) : super(key: key);

  @override
  State<AndroidBiometricExampleScreen> createState() =>
      _AndroidBiometricExampleScreenState();
}

class _AndroidBiometricExampleScreenState
    extends State<AndroidBiometricExampleScreen> {
  bool _hasBiometric = false;
  String _lastResult = '';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await AndroidBiometricHelper.isBiometricAvailable();
    setState(() {
      _hasBiometric = available;
      _lastResult =
          available ? 'Biometric available' : 'Biometric not available';
    });
  }

  Future<void> _authenticateForAttendance() async {
    final authenticated =
        await AndroidBiometricHelper.authenticateForAttendance(context);
    setState(() {
      _lastResult =
          authenticated ? '✅ Attendance verified' : '❌ Authentication failed';
    });
  }

  Future<void> _authenticateForSensitiveData() async {
    final authenticated =
        await AndroidBiometricHelper.authenticateForSensitiveData(context);
    setState(() {
      _lastResult = authenticated ? '✅ Access granted' : '❌ Access denied';
    });
  }

  Future<void> _authenticateForPayment() async {
    final authenticated =
        await AndroidBiometricHelper.authenticateForPayment(context);
    setState(() {
      _lastResult =
          authenticated ? '✅ Payment authorized' : '❌ Payment cancelled';
    });
  }

  Future<void> _authenticateCustom() async {
    final authenticated = await AndroidBiometricHelper.authenticate(
      context: context,
      title: 'Custom Action',
      subtitle: 'Authenticate to continue',
      reason: 'Authenticate to proceed',
    );
    setState(() {
      _lastResult = authenticated
          ? '✅ Custom action completed'
          : '❌ Authentication failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Android Biometric Example'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          _buildStatusCard(colorScheme),
          const SizedBox(height: 24),

          // Example Scenarios
          Text(
            'EXAMPLE SCENARIOS',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            colorScheme: colorScheme,
            title: 'Attendance Check-In',
            subtitle: 'Verify attendance with biometric',
            icon: Icons.fingerprint,
            onTap: _authenticateForAttendance,
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            colorScheme: colorScheme,
            title: 'Access Sensitive Data',
            subtitle: 'View secure information',
            icon: Icons.lock,
            onTap: _authenticateForSensitiveData,
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            colorScheme: colorScheme,
            title: 'Authorize Payment',
            subtitle: 'Complete a transaction',
            icon: Icons.payment,
            onTap: _authenticateForPayment,
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            colorScheme: colorScheme,
            title: 'Custom Action',
            subtitle: 'Custom biometric prompt',
            icon: Icons.star,
            onTap: _authenticateCustom,
          ),
          const SizedBox(height: 24),

          // Last Result
          Text(
            'LAST RESULT',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildResultCard(colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.fingerprint,
              size: 56,
              color: _hasBiometric
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _hasBiometric ? 'Biometric Available' : 'Biometric Not Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasBiometric
                  ? 'Your device supports biometric authentication'
                  : 'Biometric is not configured on this device',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCard({
    required ColorScheme colorScheme,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      child: InkWell(
        onTap: _hasBiometric ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _hasBiometric
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: _hasBiometric
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _hasBiometric
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          _lastResult.isEmpty ? 'No authentication attempts yet' : _lastResult,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
