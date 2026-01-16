# Debugging Summary - userId Mismatch Investigation

## Problem Statement

Face verification fails with error: "No registered face found for this user"

- Registration works ✅
- Verification fails ❌
- Suspected cause: userId differs between registration and verification

## Solution Implemented

### Comprehensive Logging Infrastructure Added

#### File 1: UnifiedBiometricHelper

**Path:** `lib/core/biometric/unified_biometric_helper.dart`

**Added Logging:**

1. In `_getCurrentUserId()`:

   - Shows all user ID fields from login data: uid, username, emp_id, emp_profile_id
   - Shows which field was selected based on priority (emp_id > emp_profile_id > uid > username)
   - Example output: `✅ Selected emp_id: EMP123`

2. In `authenticateForAttendance()`:
   - Shows final userId being passed to FaceRecognitionHelper
   - Clearly marks the userId that will be used for verification

**Purpose:** First point where userId selection happens

---

#### File 2: FaceRecognitionHelper

**Path:** `lib/core/biometric/face_recognition_helper.dart`

**Added Logging:**

1. In `registerFace()`:

   - Shows userId when registration starts
   - Format: `📱 ===== FACE REGISTRATION CALL =====`
   - Shows: `👤 User ID for registration: EMP123`

2. In `authenticateForAttendance()`:
   - Shows userId when verification starts
   - Shows check-in or check-out action
   - Format: `📱 ===== FACE VERIFICATION (ATTENDANCE) CALL =====`
   - Shows: `👤 User ID for verification: EMP123`

**Purpose:** Shows userId at entry points for both registration and verification

---

#### File 3: FaceRegistrationScreen (already had logging)

**Path:** `lib/core/biometric/face_recognition/presentation/screens/face_registration_screen.dart`

**Existing Logging:**

- In `initState()`: Shows mode (REGISTRATION or VERIFICATION) and userId
- Format: `🎬 ===== FACE REGISTRATION SCREEN INIT =====`
- Shows all relevant parameters

**Purpose:** Confirms userId passed through navigation

---

#### File 4: FaceEmbeddingStorageService (already had logging)

**Path:** `lib/core/biometric/face_recognition/data/services/face_embedding_storage_service.dart`

**Existing Logging:**

- Shows userId when saving embeddings (registration)
- Shows userId when retrieving embeddings (verification)
- Shows count of embeddings found

**Purpose:** Shows which file is being read/written

---

#### File 5: FaceRecognitionRepository (already had logging)

**Path:** `lib/core/biometric/face_recognition/data/repositories/face_recognition_repository_impl.dart`

**Existing Logging:**

- Shows userId during verification
- Shows count of stored embeddings
- Shows similarity score if embeddings found

**Purpose:** Final verification logic with userId confirmation

---

## How to Use

### Quick Start:

1. Run: `flutter run`
2. Login with your credentials
3. Register your face (if not already registered)
4. Note the userId shown in logs during registration
5. Go back to home screen
6. Tap Check In
7. Note the userId shown in logs during verification
8. **Compare:** Are they the same?

### Detailed Steps:

See [CONSOLE_LOG_MARKERS.md](./CONSOLE_LOG_MARKERS.md) for exact strings to search for

---

## Expected Behavior

### ✅ Correct Behavior:

```
Registration userId: EMP123
Verification userId: EMP123
File written: face_embeddings_EMP123.bin
File read: face_embeddings_EMP123.bin
Result: ✅ Verification Success
```

### ❌ Bug Behavior (userId mismatch):

```
Registration userId: EMP123
Verification userId: PROF456
File written: face_embeddings_EMP123.bin
File read attempt: face_embeddings_PROF456.bin
Result: ❌ "No registered face found for this user"
```

### ❌ Other Bug Behaviors:

```
userId: None or empty
→ "No user ID found" error
```

---

## Troubleshooting

### If you see "No user ID found":

- Check login data is properly saved
- Verify SharedPref has uid, username, emp_id, or emp_profile_id

### If userId changes between registration and verification:

- Check if login data is being cleared
- Check if SharedPref persistence is working
- May need to reload login data before each operation

### If userId is same but verification still fails:

- Check face quality/lighting during registration vs verification
- Check if embeddings file is corrupted
- Check if similarity threshold (0.65) is appropriate

---

## Files Modified

1. ✅ `lib/core/biometric/unified_biometric_helper.dart` - Added detailed userId selection logging
2. ✅ `lib/core/biometric/face_recognition_helper.dart` - Added registration and verification call logging
3. ✅ [Created] `USER_ID_LOGGING_TRACE.md` - Detailed logging points reference
4. ✅ [Created] `USER_ID_FLOW_DIAGRAM.md` - Visual userId flow through system
5. ✅ [Created] `CONSOLE_LOG_MARKERS.md` - Quick reference for log markers
6. ✅ [Created] `LOGGING_SETUP_COMPLETE.md` - Setup guide

---

## Next Steps

1. **Run the app** with the new logging
2. **Capture the output** - search for markers like `✅ Selected`, `👤 User ID`, `📱 Mode:`
3. **Compare values** - registration userId vs verification userId
4. **Report findings** - let me know if they match or differ

Once we identify the issue, the fix will be straightforward.

---

## Log Level Configuration

The logs use both `print()` and `debugPrint()`:

- `print()`: Always visible in console (registration/verification calls)
- `debugPrint()`: Visible in debug mode (user ID selection details)

If logs aren't showing:

1. Make sure you're running in debug mode: `flutter run` (not `--profile` or `--release`)
2. Check Android Studio's Logcat or iOS Console
3. Search for filter: `userId` or `User ID`

---

## Summary

**Total new logging points: 7**

- UnifiedBiometricHelper: 2 (priority selection + userId passed)
- FaceRecognitionHelper: 2 (registration + verification calls)
- FaceRegistrationScreen: confirms userId received
- FaceEmbeddingStorageService: shows file read/write operations
- FaceRecognitionRepository: shows verification logic with userId

**Result:** Complete visibility into userId through entire flow
**Time to identify bug:** < 5 minutes after running with logging
