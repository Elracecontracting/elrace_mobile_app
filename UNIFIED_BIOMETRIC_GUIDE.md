# 🎯 Unified Biometric Authentication

**Platform-adaptive biometric authentication** that automatically uses the right UI for each platform.

## Overview

This unified helper provides a **single API** that works across iOS and Android, automatically selecting:

- **iOS**: Premium Face ID with Cupertino design
- **Android**: Fast Material 3 biometric authentication

---

## 🚀 Quick Start

### 1. Already Initialized

The unified helper uses the platform-specific implementations, which are already initialized in `main.dart`:

```dart
// Already done in main.dart
FaceIdHelper.initialize();           // iOS
AndroidBiometricHelper.initialize(); // Android
```

### 2. Import Once, Use Everywhere

```dart
import 'package:el_race/core/biometric/unified_biometric_helper.dart';
```

### 3. Use Platform-Agnostic API

```dart
// Works on both iOS and Android
final authenticated = await UnifiedBiometricHelper.authenticateForAttendance(context);

if (authenticated) {
  // Proceed with action
}
```

---

## 📱 API Reference

### Check Availability

```dart
final available = await UnifiedBiometricHelper.isBiometricAvailable();

if (available) {
  // Show biometric option
}
```

### Pre-built Scenarios

#### Attendance

```dart
await UnifiedBiometricHelper.authenticateForAttendance(context);
```

#### Sensitive Data

```dart
await UnifiedBiometricHelper.authenticateForSensitiveData(context);
```

#### Payments

```dart
await UnifiedBiometricHelper.authenticateForPayment(context);
```

#### Profile Changes

```dart
await UnifiedBiometricHelper.authenticateForProfileChange(context);
```

#### Custom

```dart
await UnifiedBiometricHelper.authenticate(
  context: context,
  title: 'Your Title',
  subtitle: 'Your message',
  reason: 'Authentication reason',
);
```

---

## 🎨 What You Get Per Platform

### iOS (Face ID)

- **Design**: Cupertino frosted glass modal
- **Animation**: 300ms fade + scale
- **Icon**: Face ID (person badge)
- **Colors**: System colors (dark mode first)
- **Feel**: Premium, like Apple Pay
- **Speed**: <150ms trigger

### Android (Fingerprint/Biometric)

- **Design**: Material 3 bottom sheet
- **Animation**: 250ms slide + fade (faster!)
- **Icon**: Fingerprint/face unlock
- **Colors**: ColorScheme (Material You)
- **Feel**: Fast, confident, modern
- **Speed**: <100ms trigger

---

## 💡 Usage Examples

### Simple Button Press

```dart
ElevatedButton(
  onPressed: () async {
    final auth = await UnifiedBiometricHelper.authenticateForAttendance(context);
    if (auth) {
      // Do something
    }
  },
  child: Text('Check In'),
)
```

### With Loading State

```dart
bool _isAuthenticating = false;

Future<void> _handleCheckIn() async {
  setState(() => _isAuthenticating = true);

  final authenticated = await UnifiedBiometricHelper.authenticateForAttendance(context);

  setState(() => _isAuthenticating = false);

  if (authenticated) {
    await checkIn();
  }
}
```

### With Error Handling

```dart
Future<void> _handleSecureAction() async {
  final authenticated = await UnifiedBiometricHelper.authenticateForSensitiveData(context);

  if (authenticated) {
    try {
      await performSecureAction();
    } catch (e) {
      // Handle action error
    }
  } else {
    // Authentication failed or cancelled
    showSnackBar('Authentication cancelled');
  }
}
```

---

## 🔧 Integration in Swipe Button

The swipe button already uses the unified helper:

```dart
// In custom_swipe_button.dart
import 'package:el_race/core/biometric/unified_biometric_helper.dart';

onConfirmed: () async {
  // Platform-adaptive: Face ID on iOS, Fingerprint on Android
  final authenticated = await UnifiedBiometricHelper.authenticateForAttendance(context);

  if (authenticated) {
    _performCheckInOut();
  } else {
    _resetPosition();
  }
}
```

---

## 🎯 Benefits

### Single API

- Import once
- Works everywhere
- No platform checks needed

### Platform-Optimized

- iOS gets premium Face ID UI
- Android gets fast Material 3 UI
- Each feels native

### Consistent Behavior

- Same function calls
- Same return values
- Predictable flow

### Easy to Test

- Mock both platforms
- Test business logic once
- UI tests per platform

---

## 📊 Comparison

| Feature        | iOS          | Android                | Unified                |
| -------------- | ------------ | ---------------------- | ---------------------- |
| Import         | FaceIdHelper | AndroidBiometricHelper | UnifiedBiometricHelper |
| Platform check | Manual       | Manual                 | **Automatic**          |
| API calls      | iOS-specific | Android-specific       | **Same for both**      |
| UI             | Cupertino    | Material 3             | **Auto-selected**      |
| Maintenance    | Separate     | Separate               | **Single point**       |

---

## 🔄 When to Use Each

### Use UnifiedBiometricHelper When:

✅ Writing shared/common code  
✅ Building cross-platform features  
✅ Simplifying authentication calls  
✅ Reducing boilerplate

### Use Platform-Specific Helpers When:

✅ Platform-exclusive features  
✅ Custom platform UI needed  
✅ Advanced platform APIs  
✅ Platform-specific testing

---

## 🧪 Testing

### Unit Tests

```dart
test('authenticates on iOS', () async {
  // Platform.isIOS returns true
  final result = await UnifiedBiometricHelper.authenticateForAttendance(context);
  // Verify FaceIdHelper was called
});

test('authenticates on Android', () async {
  // Platform.isAndroid returns true
  final result = await UnifiedBiometricHelper.authenticateForAttendance(context);
  // Verify AndroidBiometricHelper was called
});
```

### Widget Tests

```dart
testWidgets('shows biometric prompt', (tester) async {
  await tester.pumpWidget(MyWidget());
  await tester.tap(find.text('Authenticate'));
  await tester.pumpAndSettle();

  // Verify platform-specific UI appears
});
```

---

## 📝 Best Practices

### 1. Always Check Availability

```dart
if (await UnifiedBiometricHelper.isBiometricAvailable()) {
  // Show biometric option
} else {
  // Show alternative (PIN, password)
}
```

### 2. Handle Cancellation Gracefully

```dart
final authenticated = await UnifiedBiometricHelper.authenticate(...);

if (!authenticated) {
  // User cancelled or failed - don't block them
  // Offer alternative authentication
}
```

### 3. Don't Block Critical Flows

```dart
// ❌ Bad: Blocking critical action
await UnifiedBiometricHelper.authenticate(...); // Must pass
await criticalAction();

// ✅ Good: Optional security layer
final auth = await UnifiedBiometricHelper.authenticate(...);
if (auth) {
  await enhancedAction();
} else {
  await basicAction();
}
```

### 4. Provide Context

```dart
// ✅ Good: Clear reason
await UnifiedBiometricHelper.authenticate(
  context: context,
  title: 'Verify Payment',
  subtitle: 'Confirm $amount transaction',
  reason: 'Authenticate to complete purchase',
);
```

---

## 🎁 Migration Guide

### From BiometricAuthHelper

**Before:**

```dart
import 'package:el_race/core/biometric/biometric_auth_helper.dart';

final auth = await BiometricAuthHelper.authenticateForAttendance(context);
```

**After:**

```dart
import 'package:el_race/core/biometric/unified_biometric_helper.dart';

final auth = await UnifiedBiometricHelper.authenticateForAttendance(context);
```

API is identical - just change the import!

---

## 🔍 Under the Hood

```dart
// The unified helper automatically selects:

if (Platform.isIOS) {
  return await FaceIdHelper.authenticateForAttendance(context);
} else if (Platform.isAndroid) {
  return await AndroidBiometricHelper.authenticateForAttendance(context);
}
```

That's it! Simple delegation to platform-specific implementations.

---

## 📚 Related Documentation

- [iOS Face ID Guide](FACE_ID_IOS_GUIDE.md) - iOS-specific details
- [Android Biometric Guide](ANDROID_BIOMETRIC_GUIDE.md) - Android-specific details
- [Implementation Summary](IOS_FACE_ID_IMPLEMENTATION.md) - Overall architecture

---

## ✨ Summary

```dart
// ✨ One import
import 'package:el_race/core/biometric/unified_biometric_helper.dart';

// ✨ One API
await UnifiedBiometricHelper.authenticateForAttendance(context);

// ✨ Two native experiences
// iOS: Premium Face ID with frosted glass
// Android: Fast Material 3 bottom sheet
```

**Write once. Native everywhere. 🎯**
