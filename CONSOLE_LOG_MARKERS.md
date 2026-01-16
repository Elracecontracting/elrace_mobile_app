# Console Log Markers - Quick Reference

## Search for these exact strings in your terminal/logcat to track the userId

### When Logging In:

Search for: `🔍 UnifiedBiometricHelper: Getting user ID...`

```
This will show all available user ID fields
Look for: ✅ Selected [field_name]: [value]
```

### When Starting Face Registration:

Search for: `📱 ===== FACE REGISTRATION CALL =====`

```
Next line will show:
👤 User ID for registration: [VALUE]
Write this down!
```

### During Face Registration Screen:

Search for: `🎬 ===== FACE REGISTRATION SCREEN INIT =====`

```
Look for these lines:
📱 Mode: REGISTRATION
👤 User ID: [VALUE]
This should match the previous value
```

### When Starting Face Verification (Check-In):

Search for: `📍 ===== UnifiedBiometricHelper.authenticateForAttendance =====`

```
Next line:
📍 Selected userId to pass: [VALUE]
This should match registration value!
```

### When Verification Screen Initializes:

Search for: `📱 ===== FACE VERIFICATION (ATTENDANCE) CALL =====`

```
Next line:
👤 User ID for verification: [VALUE]
Must match registration value!
```

### Also check:

Search for: `🎬 ===== FACE REGISTRATION SCREEN INIT =====`

```
📱 Mode: VERIFICATION
👤 User ID: [VALUE]
Same value check again
```

---

## Complete Flow Summary

```
LOGIN
  ↓
[Search: 🔍 UnifiedBiometricHelper] → Note "✅ Selected [VALUE_A]"
  ↓
TAP REGISTER FACE
  ↓
[Search: 📱 FACE REGISTRATION CALL] → Note "👤 User ID: [VALUE_A]"
  ↓
[Search: 🎬 FACE REGISTRATION SCREEN INIT] → Should see "👤 User ID: [VALUE_A]"
  ↓
COMPLETE REGISTRATION & RETURN HOME
  ↓
TAP CHECK IN
  ↓
[Search: 📍 UnifiedBiometricHelper.authenticateForAttendance] → Note "👤 Selected: [VALUE_B]"
  ↓
[Search: 📱 FACE VERIFICATION CALL] → Should see "👤 User ID: [VALUE_B]"
  ↓
[Search: 🎬 FACE REGISTRATION SCREEN INIT] → Mode should be "VERIFICATION", "👤 User ID: [VALUE_B]"
```

**CRITICAL:** VALUE_A must equal VALUE_B for verification to work!

---

## If Mismatch Found

### Example Mismatch:

```
Registration: VALUE_A = "123456" (emp_id)
Verification: VALUE_B = "ABC789" (emp_profile_id)

Result: "No registered face found for this user"
Reason: Looking for face_embeddings_ABC789.bin but stored as face_embeddings_123456.bin
```

### How to Fix:

Ensure both use same field by checking:

1. Is emp_id consistently available?
   - Yes → Use emp_id for both
   - No → Use emp_profile_id for both
2. Modify priority order if needed in `_getCurrentUserId()` method

---

## Terminal Commands

### macOS/Linux - Run and capture logs:

```bash
flutter run 2>&1 | grep -E "🔍|✅|📱|👤|📍|🎬|Selected"
```

### Watch for specific step:

```bash
flutter run 2>&1 | grep "User ID"
```

### Save logs to file:

```bash
flutter run > flutter_logs.txt 2>&1
# Then search logs for markers
cat flutter_logs.txt | grep "User ID"
```

---

## Document References

For more details, see:

- [USER_ID_FLOW_DIAGRAM.md](./USER_ID_FLOW_DIAGRAM.md) - Visual flow of userId through system
- [USER_ID_LOGGING_TRACE.md](./USER_ID_LOGGING_TRACE.md) - Detailed logging at each point
