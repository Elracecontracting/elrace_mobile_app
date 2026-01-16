# User ID Logging Trace - Face Registration vs Verification

## Complete Logging Flow

### 1. When you tap "Check In/Out" button (custom_swipe_button.dart)

```
→ UnifiedBiometricHelper.authenticateForAttendance() is called
```

### 2. In UnifiedBiometricHelper (unified_biometric_helper.dart)

**Location:** `authenticateForAttendance()` method

```
OUTPUT 📍:
📍 ===== UnifiedBiometricHelper.authenticateForAttendance =====
📍 Selected userId to pass: <VALUE_HERE>
====================================================================
```

**Also shows which field is selected:**

```
OUTPUT ✅:
🔍 UnifiedBiometricHelper: Getting user ID...
  - uid: <VALUE>
  - username: <VALUE>
  - emp_id: <VALUE>
  - emp_profile_id: <VALUE>
✅ Selected emp_id: <VALUE>   (or emp_profile_id, uid, username)
```

### 3. In FaceRecognitionHelper (face_recognition_helper.dart)

**Location:** `authenticateForAttendance()` method

```
OUTPUT 📱:
📱 ===== FACE VERIFICATION (ATTENDANCE) CALL =====
👤 User ID for verification: <SAME_VALUE_FROM_STEP_2>
📍 Action: Check In (or Check Out)
================================================
```

### 4. In FaceRegistrationScreen (face_registration_screen.dart)

**Location:** `initState()` method

```
OUTPUT 🎬:
🎬 FaceRegistrationScreen initialized
  🎬 Mode: VERIFICATION
  🎬 User ID: <SAME_VALUE_FROM_STEP_3>
  🎬 Title: Verify for Check In
  🎬 isVerification: true
```

### 5. When you submit the verification

**Location:** `_captureAndRegister()` method

```
OUTPUT 🔍:
🔍 Triggering verification with anti-spoof check...
```

### 6. In FaceEmbeddingStorageService (face_embedding_storage_service.dart)

**Location:** `getEmbeddings()` method when retrieving stored embeddings for comparison

```
OUTPUT 📂:
📂 FaceEmbeddingStorageService.getEmbeddings()
   userId: <SHOULD_BE_SAME_VALUE>
   Retrieved embeddings count: <NUMBER>
```

### 7. In FaceRecognitionRepository (face_recognition_repository_impl.dart)

**Location:** `verifyFace()` method

```
OUTPUT 🔐:
🔐 Face verification started
   userId: <SHOULD_BE_SAME_VALUE>
   Stored embeddings: <NUMBER>
   Face similarity: <0.0-1.0>
```

---

## CRITICAL COMPARISON POINTS

### During Registration (after login):

- Note the userId printed in Steps 2-3
- This is stored in the binary file: `face_embeddings_<USER_ID>.bin`

### During Verification (check-in/out):

- Note the userId printed in Steps 2-3 (should be IDENTICAL)
- This is searched in: `face_embeddings_<USER_ID>.bin`

## If Verification Fails

### Error: "No registered face found for this user"

**Likely causes:**

1. **userId mismatch** - Registration used one value, verification used different value

   - Example: Registration used `emp_id: "123"` but verification used `emp_profile_id: "456"`
   - Check that Step 2 and Step 3 show IDENTICAL userId values

2. **File not found** - No embeddings file exists

   - Check file system: `face_embeddings_<USER_ID>.bin` doesn't exist
   - This means registration wasn't completed successfully

3. **Corrupted file** - Binary file is corrupted
   - File exists but can't be read
   - Would see error in Step 6

---

## Debug Checklist

✅ Run the app and login
✅ Go to registration and register your face - note userId printed in Steps 2-3
✅ Complete registration and return to home screen
✅ Tap Check In button
✅ Verify your face - note userId printed in Steps 2-3
✅ Check that the userId values are IDENTICAL between registration and verification

If they're different, you've found the bug!
