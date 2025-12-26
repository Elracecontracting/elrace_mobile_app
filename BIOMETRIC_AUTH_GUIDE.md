# Biometric Authentication Implementation Guide

## Overview

This Flutter application now uses a unified, clean biometric authentication implementation based on the official `local_auth` package. All Face ID, Touch ID, fingerprint, and other biometric authentication is handled through a single, centralized service.

## Architecture

### Core Service: `BiometricAuthService`

**Location:** `/lib/core/services/biometric_auth_service.dart`

This is the **single source of truth** for all biometric authentication in the app.

#### Key Features:

- ✅ Singleton pattern for consistent state
- ✅ Clean async API with clear result types
- ✅ Comprehensive error handling
- ✅ Platform-agnostic (iOS & Android)
- ✅ No biometric data storage
- ✅ Professional logging
- ✅ Easy to test and mock

### API Methods

#### 1. Check Availability

```dart
Future<bool> canAuthenticateWithBiometrics()
```

Returns `true` if:

- Device has biometric hardware
- Device is secured (PIN/password set)
- User has enrolled biometrics

#### 2. Get Available Biometric Types

```dart
Future<List<BiometricType>> getAvailableBiometrics()
```

Returns list of available biometric types:

- `BiometricType.face` - Face ID (iOS), Face Unlock (Android)
- `BiometricType.fingerprint` - Touch ID (iOS), Fingerprint (Android)
- `BiometricType.iris` - Iris scanner (some Android devices)
- `BiometricType.strong` - Strong biometrics (Android)
- `BiometricType.weak` - Weak biometrics (Android)

#### 3. Check Specific Biometric Types

```dart
Future<bool> isFaceIdAvailable()
Future<bool> isFingerprintAvailable()
```

#### 4. Get User-Friendly Name

```dart
Future<String> getBiometricTypeName()
```

Returns platform-appropriate names:

- iOS: "Face ID" or "Touch ID"
- Android: "Face Unlock" or "Fingerprint"

#### 5. Authenticate

```dart
Future<BiometricAuthResult> authenticate({
  required String reason,
  bool biometricOnly = true,
  bool stickyAuth = true,
  bool useErrorDialogs = true,
})
```

**Parameters:**

- `reason` - User-facing message (required)
- `biometricOnly` - If false, allows device passcode fallback
- `stickyAuth` - If true, survives app backgrounding
- `useErrorDialogs` - If true, shows system error dialogs

**Returns:** `BiometricAuthResult` with:

- `success` - Boolean indicating authentication result
- `errorMessage` - User-friendly error message (if failed)
- `errorType` - Specific error type for handling

#### 6. Stop Authentication

```dart
Future<void> stopAuthentication()
```

Cancels ongoing authentication (useful for cleanup).

---

## Result Handling

### `BiometricAuthResult`

```dart
class BiometricAuthResult {
  final bool success;
  final String? errorMessage;
  final BiometricAuthErrorType? errorType;
}
```

### Error Types

```dart
enum BiometricAuthErrorType {
  notEnrolled,           // No biometrics registered
  notAvailable,          // Biometrics not supported
  lockedOut,             // Temporarily locked (too many attempts)
  permanentlyLockedOut,  // Permanently locked
  canceled,              // User canceled
  timeout,               // Authentication timed out
  unknown,               // Other errors
}
```

---

## Usage Examples

### Basic Usage

```dart
import 'package:el_race/core/services/biometric_auth_service.dart';

final biometricService = BiometricAuthService.instance;

// Check availability
final canUse = await biometricService.canAuthenticateWithBiometrics();
if (!canUse) {
  print('Biometrics not available');
  return;
}

// Authenticate
final result = await biometricService.authenticate(
  reason: 'Please authenticate to continue',
);

if (result.success) {
  // Authentication successful
  print('✅ User authenticated');
} else {
  // Handle error
  print('❌ Error: ${result.errorMessage}');
}
```

### Error Handling

```dart
final result = await biometricService.authenticate(
  reason: 'Authenticate to access secure data',
);

if (result.success) {
  navigateToSecureScreen();
} else {
  switch (result.errorType) {
    case BiometricAuthErrorType.notEnrolled:
      showSetupBiometricsDialog();
      break;
    case BiometricAuthErrorType.lockedOut:
      showLockedOutMessage();
      break;
    case BiometricAuthErrorType.canceled:
      // User canceled, no action needed
      break;
    default:
      showGenericError(result.errorMessage);
  }
}
```

### In a ViewModel/Controller

```dart
class MyViewModel {
  final BiometricAuthService _biometricService = BiometricAuthService.instance;

  Future<bool> authenticateUser() async {
    final canAuth = await _biometricService.canAuthenticateWithBiometrics();
    if (!canAuth) return false;

    final result = await _biometricService.authenticate(
      reason: 'Authenticate to check in',
    );

    return result.success;
  }
}
```

### In a Widget

See `/lib/core/services/biometric_auth_example.dart` for a complete example widget.

---

## Migration from Legacy Code

### Before (Old FaceIDRepo)

```dart
final faceIdRepo = FaceIDRepo();
final success = await faceIdRepo.authenticateWithBiometrics();
```

### After (New BiometricAuthService)

```dart
final biometricService = BiometricAuthService.instance;
final result = await biometricService.authenticate(
  reason: 'Please authenticate',
);
final success = result.success;
```

---

## Platform Configuration

### iOS - Info.plist

Already configured in `/ios/Runner/Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>Face ID is used to securely check you into your workplace without typing a password.</string>
```

### Android - AndroidManifest.xml

Already configured in `/android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

---

## Security Best Practices

### ✅ DO:

- Use `BiometricAuthService.instance` for all biometric operations
- Always check `canAuthenticateWithBiometrics()` before authenticating
- Provide clear, user-friendly `reason` text
- Handle all error types appropriately
- Use `biometricOnly: true` for sensitive operations
- Call `stopAuthentication()` in widget dispose if needed

### ❌ DON'T:

- Never directly use `LocalAuthentication` in UI or business logic
- Never store biometric data (the OS handles it)
- Never use empty or generic reason strings
- Never ignore error types
- Never auto-trigger authentication without user intent
- Never crash on biometric unavailability

---

## Testing

### Mocking BiometricAuthService

```dart
class MockBiometricAuthService extends BiometricAuthService {
  bool mockCanAuthenticate = true;
  bool mockAuthSuccess = true;

  @override
  Future<bool> canAuthenticateWithBiometrics() async {
    return mockCanAuthenticate;
  }

  @override
  Future<BiometricAuthResult> authenticate({
    required String reason,
    bool biometricOnly = true,
    bool stickyAuth = true,
    bool useErrorDialogs = true,
  }) async {
    if (mockAuthSuccess) {
      return BiometricAuthResult.success();
    } else {
      return BiometricAuthResult.failure(
        'Mock authentication failed',
        errorType: BiometricAuthErrorType.canceled,
      );
    }
  }
}
```

---

## Legacy Code Status

### Refactored Files

1. ✅ **FaceIDRepo** (`/lib/ui/presentation/landing_screen/repository/face_id_repo.dart`)

   - Now wraps `BiometricAuthService`
   - Backwards compatible
   - New code should use `BiometricAuthService` directly

2. ✅ **AuthVerificationService** (`/lib/core/services/auth_verification_service.dart`)
   - All biometric methods now use `BiometricAuthService`
   - No direct `LocalAuthentication` usage
   - Clean separation of concerns

### Files Using Biometric Auth

- `/lib/ui/presentation/landing_screen/bloc/face_id_bloc/face_id_bloc.dart` - Uses `FaceIDRepo`
- `/lib/core/services/auth_verification_service.dart` - Uses `BiometricAuthService`

---

## Common Issues & Solutions

### Issue: "Biometric authentication is not available"

**Solution:** Check:

1. Device has biometric hardware
2. Device is secured (PIN/password set)
3. User has enrolled at least one biometric
4. App permissions are granted

### Issue: "Authentication fails silently"

**Solution:**

- Check `result.errorType` and `result.errorMessage`
- Enable debug logging to see detailed errors
- Verify platform permissions are configured

### Issue: "Face ID works on simulator but not device"

**Solution:**

- Ensure Info.plist has `NSFaceIDUsageDescription`
- Check device Face ID is enrolled in Settings
- Verify app has permission to use Face ID

---

## Logging

All biometric operations include debug logging:

```
🔐 BiometricAuthService: Biometrics available: [BiometricType.face]
🔐 BiometricAuthService: Starting authentication...
🔐 BiometricAuthService: ✅ Authentication successful
```

---

## Dependencies

**Required Package:**

```yaml
dependencies:
  local_auth: ^2.3.0
```

---

## Summary

✅ **Centralized:** Single service for all biometric authentication  
✅ **Clean API:** Simple, intuitive methods with clear results  
✅ **Secure:** No biometric data storage, OS handles everything  
✅ **Professional:** Comprehensive error handling and logging  
✅ **Testable:** Easy to mock and test  
✅ **Platform-agnostic:** Works on iOS and Android  
✅ **Production-ready:** Follows Flutter best practices

**Main Service:** `/lib/core/services/biometric_auth_service.dart`  
**Example Usage:** `/lib/core/services/biometric_auth_example.dart`  
**Legacy Wrapper:** `/lib/ui/presentation/landing_screen/repository/face_id_repo.dart`

---

## Next Steps

1. Replace remaining direct `FaceIDRepo` usage with `BiometricAuthService`
2. Add biometric authentication to new features
3. Consider adding biometric enrollment check in onboarding
4. Add analytics for biometric usage patterns (success/failure rates)

---

**Last Updated:** December 25, 2025  
**Author:** Senior Flutter Security Engineer  
**Version:** 1.0.0
