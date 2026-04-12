import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Manages a 4-6 digit PIN stored in encrypted secure storage.
///
/// The PIN acts as a fallback when the device has no biometric
/// capability (no Face ID, no fingerprint, etc.).
class PinAuthService {
  PinAuthService._();
  static final PinAuthService instance = PinAuthService._();

  static const _pinKey = 'el_race_user_pin';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Whether the user has already set up a PIN.
  Future<bool> hasPin() async {
    try {
      final pin = await _storage.read(key: _pinKey);
      return pin != null && pin.isNotEmpty;
    } catch (e) {
      debugPrint('PinAuthService.hasPin error: $e');
      return false;
    }
  }

  /// Persist a new PIN (overwrites any existing one).
  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  /// Returns `true` if [enteredPin] matches the stored PIN.
  Future<bool> verifyPin(String enteredPin) async {
    try {
      final stored = await _storage.read(key: _pinKey);
      return stored != null && stored == enteredPin;
    } catch (e) {
      debugPrint('PinAuthService.verifyPin error: $e');
      return false;
    }
  }

  /// Remove the stored PIN (e.g. on logout).
  Future<void> clearPin() async {
    try {
      await _storage.delete(key: _pinKey);
    } catch (_) {}
  }
}
