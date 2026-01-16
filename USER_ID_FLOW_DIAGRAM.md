# userId Flow Diagram

## Registration Flow (After Login)

```
Login Screen
    ↓
SharedPreferences gets: { uid: "X", emp_id: "Y", emp_profile_id: "Z", username: "W" }
    ↓
UnifiedBiometricHelper._getCurrentUserId()
    │
    └─→ Checks priority: emp_id > emp_profile_id > uid > username
    │   (Takes first non-empty value)
    │
    └─→ Returns: "Y" (if emp_id exists)
        OR "Z" (if emp_profile_id exists)
        OR "X" (if uid exists)
        OR "W" (if username exists)
    ↓
FaceRecognitionHelper.registerFace(userId: "Y")
    ↓
FaceRegistrationScreen(userId: "Y", isVerification: false)
    ↓
FaceEmbeddingStorageService.saveEmbedding(userId: "Y", embedding: [...])
    │
    └─→ Creates file: face_embeddings_Y.bin (ENCRYPTED)
    ↓
✅ Registration Complete - Face stored under "Y"
```

## Check-In/Out Verification Flow

```
Check-In/Out Button Tapped (custom_swipe_button.dart)
    ↓
UnifiedBiometricHelper.authenticateForAttendance(context)
    │
    └─→ _getCurrentUserId() → returns "Y"
    │
    └─→ FaceRecognitionHelper.authenticateForAttendance(context, userId: "Y")
        ↓
        FaceRegistrationScreen(userId: "Y", isVerification: true)
            ↓
            _captureAndRegister() calls StartFaceVerification event
            ↓
            FaceRecognitionRepositoryImpl.verifyFace(userId: "Y")
                ↓
                FaceEmbeddingStorageService.getEmbeddings(userId: "Y")
                │
                └─→ Tries to read: face_embeddings_Y.bin
                │
                └─→ If found: Reads stored embeddings
                    If NOT found: ❌ "No registered face found for this user"
                ↓
                Compares current face with stored embeddings
                    │
                    ├─→ If distance < 0.65: ✅ Verification SUCCESS
                    └─→ If distance >= 0.65: ❌ Face doesn't match
```

## The Problem: userId MISMATCH

### Scenario 1: emp_id has value ✅ CORRECT

```
Registration: userId = emp_id = "123456" → Saves as face_embeddings_123456.bin
Verification: userId = emp_id = "123456" → Reads from face_embeddings_123456.bin ✅ FOUND
```

### Scenario 2: emp_id empty but emp_profile_id has value ✅ CORRECT

```
Registration: userId = emp_profile_id = "ABC789" → Saves as face_embeddings_ABC789.bin
Verification: userId = emp_profile_id = "ABC789" → Reads from face_embeddings_ABC789.bin ✅ FOUND
```

### Scenario 3: MISMATCH (emp_id in registration, emp_profile_id in verification) ❌ BUG

```
Registration: userId = emp_id = "123456" → Saves as face_embeddings_123456.bin
Verification: userId = emp_profile_id = "ABC789" → Tries to read face_embeddings_ABC789.bin ❌ NOT FOUND!
```

---

## How to Identify the Issue

1. **During Registration:**

   - Look for: `✅ Selected emp_id: 123456` (or whatever is selected)
   - **Write down this value**

2. **During Check-In Verification:**

   - Look for: `✅ Selected emp_id: 123456` (should be SAME)
   - If it says: `✅ Selected emp_profile_id: ABC789` ← **THIS IS THE BUG!**

3. **The Fix:**
   - Make sure BOTH registration and verification use the same field
   - The priority logic should always select the same field in the same order

---

## Expected Log Output Format

### Registration

```
🔍 UnifiedBiometricHelper: Getting user ID...
  - uid: 12345
  - username: johndoe
  - emp_id: EMP123
  - emp_profile_id: PROF456
✅ Selected emp_id: EMP123

📱 ===== FACE REGISTRATION CALL =====
👤 User ID for registration: EMP123
=====================================

🎬 FaceRegistrationScreen initialized
  🎬 Mode: REGISTRATION
  🎬 User ID: EMP123
```

### Check-In Verification

```
🔍 UnifiedBiometricHelper: Getting user ID...
  - uid: 12345
  - username: johndoe
  - emp_id: EMP123
  - emp_profile_id: PROF456
✅ Selected emp_id: EMP123

📍 ===== UnifiedBiometricHelper.authenticateForAttendance =====
📍 Selected userId to pass: EMP123
====================================================================

📱 ===== FACE VERIFICATION (ATTENDANCE) CALL =====
👤 User ID for verification: EMP123
📍 Action: Check In
================================================

🎬 FaceRegistrationScreen initialized
  🎬 Mode: VERIFICATION
  🎬 User ID: EMP123
```

→ **All show same userId: EMP123** ✅ CORRECT
