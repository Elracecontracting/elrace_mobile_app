# ✅ Complete Logging Setup for userId Debugging

## What Was Added

I've added comprehensive logging throughout the entire face verification flow to help you identify which userId is being used at each step.

### Logging Points Added:

1. **UnifiedBiometricHelper** (`lib/core/biometric/unified_biometric_helper.dart`)

   - `_getCurrentUserId()`: Prints all available user ID fields (uid, username, emp_id, emp_profile_id)
   - `authenticateForAttendance()`: Prints the selected userId before passing to FaceRecognitionHelper

2. **FaceRecognitionHelper** (`lib/core/biometric/face_recognition_helper.dart`)

   - `registerFace()`: Prints userId when registration starts
   - `authenticateForAttendance()`: Prints userId and check-in/out action type

3. **FaceRegistrationScreen** (Already had logging)

   - `initState()`: Prints mode (REGISTRATION/VERIFICATION) and userId

4. **Previous logging** (From earlier work)
   - `FaceEmbeddingStorageService`: Prints userId when saving/retrieving embeddings
   - `FaceRecognitionRepository`: Prints userId during verification

---

## How to Use This

### Step 1: Run the app and login

```
Watch for output like:
🔍 UnifiedBiometricHelper: Getting user ID...
  - uid: 12345
  - username: johndoe
  - emp_id: EMP123
  - emp_profile_id: PROF456
✅ Selected emp_id: EMP123  ← Write this down!
```

### Step 2: Go to register face (first time after login)

```
Watch for:
📱 ===== FACE REGISTRATION CALL =====
👤 User ID for registration: EMP123   ← Should match Step 1
=====================================

🎬 ===== FACE REGISTRATION SCREEN INIT =====
📱 Mode: REGISTRATION
👤 User ID: EMP123  ← Should still match
```

### Step 3: Return to home and tap Check In button

```
Watch for:
📍 ===== UnifiedBiometricHelper.authenticateForAttendance =====
📍 Selected userId to pass: EMP123   ← Should STILL be same!
====================================================================

📱 ===== FACE VERIFICATION (ATTENDANCE) CALL =====
👤 User ID for verification: EMP123   ← Must match Step 2!
📍 Action: Check In
================================================

🎬 ===== FACE REGISTRATION SCREEN INIT =====
📱 Mode: VERIFICATION
👤 User ID: EMP123  ← Should match all previous!
```

---

## What to Look For

### ✅ If You See Same Value Throughout:

```
Registration: EMP123
Verification: EMP123
→ userId is correct, the issue is elsewhere (face quality, embeddings, etc.)
```

### ❌ If You See Different Values:

```
Registration: EMP123
Verification: PROF456
→ THIS IS THE BUG! The values don't match
```

---

## If userId Changes

If you see different values between registration and verification:

### Most Common Causes:

1. **Data cleared between login and check-in** - User ID fields became empty
2. **Different login response** - Different user data on second read
3. **Priority order issue** - One field is empty, falls back to next

### The Fix:

If the issue is emp_id being used in registration but emp_profile_id in verification:

- Both should use the same field
- You'll need to ensure consistent login data or adjust the priority order

---

## Files with Logging

All logging is already active in these files:

- [lib/core/biometric/unified_biometric_helper.dart](../lib/core/biometric/unified_biometric_helper.dart#L20-L60)
- [lib/core/biometric/face_recognition_helper.dart](../lib/core/biometric/face_recognition_helper.dart#L15-L85)
- [lib/core/biometric/face_recognition/presentation/screens/face_registration_screen.dart](../lib/core/biometric/face_recognition/presentation/screens/face_registration_screen.dart#L61-L70)

---

## Next Steps

1. Run `flutter run` with logging enabled
2. Login to the app
3. Register your face
4. Go back to home screen
5. Tap Check In button
6. Check the console/terminal output
7. Report which userId values appear at each step

Once you identify if there's a mismatch, we can fix it!
