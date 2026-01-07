import 'package:flutter/cupertino.dart';
import 'package:el_race/core/biometric/ios/face_id_helper.dart';

/// Example screen showing iOS Face ID authentication
/// Demonstrates the premium Face ID experience
class IosFaceIdExampleScreen extends StatefulWidget {
  const IosFaceIdExampleScreen({super.key});

  @override
  State<IosFaceIdExampleScreen> createState() => _IosFaceIdExampleScreenState();
}

class _IosFaceIdExampleScreenState extends State<IosFaceIdExampleScreen> {
  bool _hasFaceId = false;
  String _lastResult = '';

  @override
  void initState() {
    super.initState();
    _checkFaceIdAvailability();
  }

  Future<void> _checkFaceIdAvailability() async {
    final available = await FaceIdHelper.isFaceIdAvailable();
    setState(() {
      _hasFaceId = available;
      _lastResult =
          available ? 'Face ID is available' : 'Face ID not available';
    });
  }

  Future<void> _authenticateForAttendance() async {
    final authenticated = await FaceIdHelper.authenticateForAttendance(context);
    setState(() {
      _lastResult = authenticated
          ? '✅ Attendance authenticated'
          : '❌ Authentication failed';
    });
  }

  Future<void> _authenticateForSensitiveData() async {
    final authenticated =
        await FaceIdHelper.authenticateForSensitiveData(context);
    setState(() {
      _lastResult =
          authenticated ? '✅ Sensitive data access granted' : '❌ Access denied';
    });
  }

  Future<void> _authenticateForPayment() async {
    final authenticated = await FaceIdHelper.authenticateForPayment(context);
    setState(() {
      _lastResult =
          authenticated ? '✅ Payment authorized' : '❌ Payment cancelled';
    });
  }

  Future<void> _authenticateCustom() async {
    final authenticated = await FaceIdHelper.authenticate(
      context: context,
      title: 'Custom Action',
      subtitle: 'Use Face ID to perform this action',
      reason: 'Authenticate to continue',
    );
    setState(() {
      _lastResult = authenticated
          ? '✅ Custom action authenticated'
          : '❌ Authentication failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('iOS Face ID Example'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 24),

            // Example Scenarios
            _buildSectionTitle('Example Scenarios'),
            const SizedBox(height: 12),
            _buildExampleButton(
              title: 'Attendance Check-In',
              subtitle: 'Verify attendance with Face ID',
              icon: CupertinoIcons.checkmark_shield,
              onTap: _authenticateForAttendance,
            ),
            const SizedBox(height: 12),
            _buildExampleButton(
              title: 'Access Sensitive Data',
              subtitle: 'View secure information',
              icon: CupertinoIcons.lock_shield,
              onTap: _authenticateForSensitiveData,
            ),
            const SizedBox(height: 12),
            _buildExampleButton(
              title: 'Authorize Payment',
              subtitle: 'Complete a transaction',
              icon: CupertinoIcons.money_dollar_circle,
              onTap: _authenticateForPayment,
            ),
            const SizedBox(height: 12),
            _buildExampleButton(
              title: 'Custom Action',
              subtitle: 'Custom Face ID prompt',
              icon: CupertinoIcons.star,
              onTap: _authenticateCustom,
            ),
            const SizedBox(height: 24),

            // Last Result
            _buildSectionTitle('Last Result'),
            const SizedBox(height: 12),
            _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.person_crop_circle_badge_checkmark,
            size: 48,
            color: _hasFaceId
                ? CupertinoColors.systemGreen
                : CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 12),
          Text(
            _hasFaceId ? 'Face ID Available' : 'Face ID Not Available',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasFaceId
                ? 'Your device supports Face ID authentication'
                : 'Face ID is not configured on this device',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.systemGrey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildExampleButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _hasFaceId ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _hasFaceId
              ? CupertinoColors.systemGrey6
              : CupertinoColors.systemGrey6.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hasFaceId
                    ? CupertinoColors.systemBlue.withValues(alpha: 0.15)
                    : CupertinoColors.systemGrey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: _hasFaceId
                    ? CupertinoColors.systemBlue
                    : CupertinoColors.systemGrey,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _hasFaceId
                          ? CupertinoColors.label
                          : CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        _lastResult.isEmpty ? 'No authentication attempts yet' : _lastResult,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
