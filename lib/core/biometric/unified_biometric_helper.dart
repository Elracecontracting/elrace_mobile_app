import 'package:flutter/material.dart';
import 'package:el_race/core/biometric/device_auth_service.dart';
import 'package:el_race/core/biometric/pin_auth_service.dart';
import 'package:el_race/core/biometric/screens/pin_setup_screen.dart';
import 'package:el_race/core/biometric/screens/pin_verify_sheet.dart';

/// Unified authentication helper.
///
/// **Strategy:**
/// 1. If the device supports biometrics (Face ID / fingerprint) → use them.
/// 2. Otherwise, fall back to a 4-6 digit PIN.
///    - If the user has not set a PIN yet, open [PinSetupScreen] first.
///    - Then show [PinVerifySheet] to verify.
class UnifiedBiometricHelper {
  UnifiedBiometricHelper._();

  static final _deviceAuth = DeviceAuthService.instance;
  static final _pinAuth = PinAuthService.instance;

  // ─────────────────────── public API ───────────────────────

  /// Authenticate for check-in / check-out.
  static Future<bool> authenticateForAttendance(BuildContext context) async {
    return _authenticate(context, reason: 'تحقق من هويتك لتسجيل الحضور');
  }

  /// Authenticate for sensitive data access.
  static Future<bool> authenticateForSensitiveData(BuildContext context) async {
    return _authenticate(context, reason: 'تحقق من هويتك لعرض البيانات');
  }

  /// Authenticate for payments.
  static Future<bool> authenticateForPayment(BuildContext context) async {
    return _authenticate(context, reason: 'تحقق من هويتك لإتمام الدفع');
  }

  /// Authenticate for profile changes.
  static Future<bool> authenticateForProfileChange(BuildContext context) async {
    return _authenticate(context, reason: 'تحقق من هويتك لتعديل الملف الشخصي');
  }

  /// Generic authentication with a custom [reason].
  static Future<bool> authenticate({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String reason,
  }) async {
    return _authenticate(context, reason: reason);
  }

  /// Whether the user needs to set up their auth method (PIN setup).
  /// Returns `true` when the device has no biometrics AND no PIN has been set.
  static Future<bool> needsSetup() async {
    final hasBio = await _deviceAuth.isBiometricAvailable();
    if (hasBio) return false;
    return !(await _pinAuth.hasPin());
  }

  /// Open PIN setup flow. Returns `true` when setup completed.
  static Future<bool> setupPin(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
    );
    return result ?? false;
  }

  // ─────────────────────── internals ───────────────────────

  static Future<bool> _authenticate(
    BuildContext context, {
    required String reason,
  }) async {
    final hasBio = await _deviceAuth.isBiometricAvailable();

    if (hasBio) {
      // ── Device biometrics (Face ID / fingerprint / device passcode) ──
      return await _deviceAuth.authenticate(
        reason: reason,
        biometricOnly: false, // allow device passcode as OS fallback
      );
    }

    // ── PIN fallback ──
    final hasPin = await _pinAuth.hasPin();
    if (!hasPin) {
      // First-time: force user to set a PIN
      final didSetup = await setupPin(context);
      if (!didSetup) return false;
    }

    if (!context.mounted) return false;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PinVerifySheet(subtitle: reason),
    );
    return ok ?? false;
  }
}
