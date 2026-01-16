# Quick Reference Card - userId Logging

## 🎯 Your Mission

Find if userId stays the same from registration to verification

## 📋 Checklist - Run This

```
[ ] 1. Run: flutter run
[ ] 2. Open app terminal/console
[ ] 3. Login with your account
[ ] 4. Search console for: ✅ Selected
     - Write down: ___________
[ ] 5. Go to register face (or tap if already registered)
[ ] 6. Search console for: 📱 FACE REGISTRATION CALL
     - Look for: 👤 User ID for registration: ___________
[ ] 7. Complete registration and go home
[ ] 8. Tap Check In button
[ ] 9. Search console for: 📍 UnifiedBiometricHelper.authenticateForAttendance
     - Look for: 📍 Selected userId to pass: ___________
[ ] 10. Compare Step 6 and Step 9
      - If SAME: ✅ userId is correct
      - If DIFFERENT: ❌ Found the bug!
```

---

## 📊 Log Output Examples

### What You Should See During Registration:

```
🔍 UnifiedBiometricHelper: Getting user ID...
  - uid: 12345
  - username: john.doe
  - emp_id: EMP-2024-001
  - emp_profile_id: PROF-98765
✅ Selected emp_id: EMP-2024-001

📱 ===== FACE REGISTRATION CALL =====
👤 User ID for registration: EMP-2024-001
=====================================

🎬 ===== FACE REGISTRATION SCREEN INIT =====
📱 Mode: REGISTRATION
👤 User ID: EMP-2024-001
📝 Title: Register Your Face
```

### What You Should See During Check-In Verification:

```
🔍 UnifiedBiometricHelper: Getting user ID...
  - uid: 12345
  - username: john.doe
  - emp_id: EMP-2024-001
  - emp_profile_id: PROF-98765
✅ Selected emp_id: EMP-2024-001

📍 ===== UnifiedBiometricHelper.authenticateForAttendance =====
📍 Selected userId to pass: EMP-2024-001
====================================================================

📱 ===== FACE VERIFICATION (ATTENDANCE) CALL =====
👤 User ID for verification: EMP-2024-001
📍 Action: Check In
================================================

🎬 ===== FACE REGISTRATION SCREEN INIT =====
📱 Mode: VERIFICATION
👤 User ID: EMP-2024-001
```

---

## ⚠️ Red Flags - If You See:

### ❌ Different User IDs:

```
Registration: EMP-2024-001
Verification: PROF-98765
→ FOUND THE BUG! The userId changes!
```

### ❌ Empty User ID:

```
❌ UnifiedBiometricHelper: No user ID found
→ Login data not saved properly
```

### ❌ Missing Logs:

```
No output for "FACE REGISTRATION CALL" or "FACE VERIFICATION CALL"
→ registerFace() or authenticateForAttendance() not called
```

---

## 🔍 Search Strategy

### Option 1: Search Terminal Directly

In your terminal, look for lines containing:

- `Selected` → Shows which userId was chosen
- `User ID for` → Shows userId for registration or verification
- `Mode:` → Shows if it's REGISTRATION or VERIFICATION

### Option 2: Filter Console Output

Run in terminal:

```bash
flutter run 2>&1 | grep "Selected\|User ID\|Mode:"
```

### Option 3: Save and Search

```bash
flutter run > logs.txt 2>&1
# Then open logs.txt and search for "User ID"
```

---

## ✅ Success Indicators

- [ ] Same userId shows in registration
- [ ] Same userId shows in verification
- [ ] No "No user ID found" errors
- [ ] Face verification succeeds after registration
- [ ] Check-in/out works successfully

---

## 📁 Supporting Documents

For more details:

- [DEBUG_SUMMARY.md](./DEBUG_SUMMARY.md) - Full debugging setup
- [USER_ID_FLOW_DIAGRAM.md](./USER_ID_FLOW_DIAGRAM.md) - Visual flow
- [CONSOLE_LOG_MARKERS.md](./CONSOLE_LOG_MARKERS.md) - Detailed log reference

---

## 💡 Pro Tips

**Tip 1:** Run registration and verification back-to-back without leaving app

- This ensures login data doesn't change

**Tip 2:** Use device's USB cable for better log visibility

- Console output is clearer than wireless debugging

**Tip 3:** Take a screenshot of the logs

- Easy to compare registration vs verification userId

**Tip 4:** If userId constantly changes

- May be an issue with how login data is stored/retrieved
- Check SharedPreferences persistence

---

## 🎯 Next Action

**Once you identify the issue, send me:**

1. The userId from registration
2. The userId from verification
3. Which field they came from (emp_id, emp_profile_id, uid, username)

Then we can apply the fix!
