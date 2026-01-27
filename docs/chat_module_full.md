# Chat Module – Full Detail

## 1) Scope and Capabilities

- WhatsApp-like chat inside the app using Firebase (Auth custom token, Firestore, Storage, Realtime DB, Messaging).
- Direct messages (1:1) with text, images, files, voice notes.
- Presence (online/last seen) and typing indicators.
- Thread list, message screen, new chat (search), attachments preview basics.
- Integrated into existing login (Odoo backend) and bottom navigation.

---

## VERIFICATION REPORT (January 27, 2026)

### ✅ 1. Firebase Initialization - VERIFIED

**Location:** `lib/main.dart` (lines 86-106)

```dart
await Future.wait([
  SharedPref().instantiatePreferences(),
  initDI(),
  HiveService.setupHive(),
  Firebase.initializeApp(),  // ✅ Firebase initialized here
]).timeout(const Duration(seconds: 30), ...);
```

**Status:** Firebase is correctly initialized at app startup with proper timeout handling.

---

### ✅ 2. Platform Configuration Files - VERIFIED

| Platform | File                                  | Project ID   | Status     |
| -------- | ------------------------------------- | ------------ | ---------- |
| Android  | `android/app/google-services.json`    | `elrace-new` | ✅ Correct |
| iOS      | `ios/Runner/GoogleService-Info.plist` | `elrace-new` | ✅ Correct |

**Android google-services.json:**

```json
{
  "project_info": {
    "project_number": "392748487890",
    "project_id": "elrace-new",
    "storage_bucket": "elrace-new.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:392748487890:android:c475c90ac7c1dcf00f490b",
        "android_client_info": { "package_name": "com.el_race.app" }
      }
    }
  ]
}
```

---

### ✅ 3. Custom Token Handling - VERIFIED

**Location:** `lib/chat/services/firebase_chat_auth_service.dart` (lines 62-75)

```dart
// Step 1: Sign in to Firebase with custom token
print('🔐 FirebaseChatAuth: Signing in with custom token...');

// Debug: Log token info (first/last chars only for security)
final token = session.firebaseCustomToken!;
print('🔐 FirebaseChatAuth: Token length: ${token.length}');
print('🔐 FirebaseChatAuth: Token preview: ${token.substring(0, 20)}...${token.substring(token.length - 20)}');

final userCredential = await _auth.signInWithCustomToken(
  session.firebaseCustomToken!,
);
```

**Status:** Token length and preview are logged for debugging. Sign-in method is correctly called.

---

### ✅ 4. UID Format Verification - VERIFIED

**Location:** `lib/chat/services/firebase_chat_auth_service.dart` (lines 76-85)

```dart
final firebaseUid = userCredential.user?.uid;
if (firebaseUid == null) {
  return ChatSetupResult.failed('Firebase sign-in succeeded but no UID returned');
}

// Verify UID matches expected (log warning if mismatch)
if (firebaseUid != session.firebaseUid) {
  print('⚠️ FirebaseChatAuth: UID mismatch! Expected: ${session.firebaseUid}, Got: $firebaseUid');
  print('⚠️ FirebaseChatAuth: Using actual UID from Firebase: $firebaseUid');
}
```

**Expected Format:** `odoo_{user_id}` (e.g., `odoo_1321`)

---

### ✅ 5. Error Handling - VERIFIED

**Location:** `lib/chat/services/firebase_chat_auth_service.dart` (lines 115-122)

```dart
} on FirebaseAuthException catch (e) {
  print('❌ FirebaseChatAuth: Firebase Auth error: ${e.code} - ${e.message}');
  return ChatSetupResult.failed('Firebase auth failed: ${e.message}');
} catch (e) {
  print('❌ FirebaseChatAuth: Setup error: $e');
  return ChatSetupResult.failed('Chat setup failed: $e');
}
```

**Status:** Both FirebaseAuthException and general exceptions are caught with detailed logging.

---

### ❌ 6. Current Issue - CONFIGURATION_NOT_FOUND

**Error from logs:**

```
❌ FirebaseChatAuth: Firebase Auth error: unknown - An internal error has occurred. [ CONFIGURATION_NOT_FOUND
```

**Root Cause Analysis:**

- App is configured for Firebase project: `elrace-new` ✅
- Backend is generating custom tokens using a **different** Firebase project's Service Account ❌

**Evidence:**

- Token received: `eyJhbGciOiAiUlMyNTYi...` (length: 928 chars)
- Token format appears valid (RS256 JWT)
- Error occurs specifically on `signInWithCustomToken()` call
- Error code `CONFIGURATION_NOT_FOUND` indicates the token's `iss` (issuer) claim points to a different Firebase project than `elrace-new`

---

### 🔧 REQUIRED BACKEND FIX

The backend team must:

1. **Download correct Service Account:**
   - Go to: https://console.firebase.google.com/project/elrace-new/settings/serviceaccounts/adminsdk
   - Click "Generate new private key"
   - Save the JSON file

2. **Verify JSON contents:**

   ```json
   {
     "project_id": "elrace-new", // ← MUST match
     "client_email": "firebase-adminsdk-xxxxx@elrace-new.iam.gserviceaccount.com"
   }
   ```

3. **Update backend code:**

   ```python
   # Python example
   import firebase_admin
   from firebase_admin import credentials, auth

   cred = credentials.Certificate("/path/to/elrace-new-service-account.json")
   firebase_admin.initialize_app(cred)

   def generate_custom_token(odoo_user_id):
       uid = f"odoo_{odoo_user_id}"
       return auth.create_custom_token(uid).decode('utf-8')
   ```

4. **Restart backend service** after updating.

---

## 2) Key Paths in Repo

- Models: lib/chat/models/
  - chat_message.dart, chat_thread.dart, chat_user.dart, chat_attachment.dart, chat_user_session.dart, chat_presence.dart
- Services: lib/chat/services/
  - firebase_chat_auth_service.dart, chat_message_service.dart, chat_thread_service.dart, chat_presence_service.dart
- Repositories: lib/chat/repositories/
  - chat_repository.dart, user_repository.dart
- UI Screens: lib/ui/chat/
  - chat_list_screen.dart, chat_screen.dart, new_chat_screen.dart
- UI Widgets: lib/ui/chat/widgets/
  - message_bubble.dart, chat_input_bar.dart, typing_indicator.dart, chat_avatar.dart, presence_indicator.dart
- Integration points:
  - Chat init: lib/chat/chat_module_helper.dart
  - Sign-in trigger: lib/ui/presentation/signin/bloc/sign_in_bloc.dart
  - Login response model: lib/ui/presentation/signin/data/model.dart
  - Bottom nav entry: lib/ui/presentation/home_screen/screens/main_screens.dart

## 3) Data Flow (end-to-end)

1. User logs in via Odoo API. Response parsed into LoginResponseModel.Data (includes firebase fields).
2. ChatModuleHelper builds ChatUserSession from login data (prefers employee*id over emp_id; default_operating_unit_id over branch_id; odoo_user_id for UID prefix odoo*...).
3. FirebaseChatAuthService signs in with firebase_custom_token returned from backend.
4. On Firebase auth success:
   - Realtime DB used for presence/typing.
   - Firestore used for threads and messages.
   - Storage used for media (images/files/voice notes) uploads.
5. UI reads ChatModuleHelper.instance.isChatEnabled to decide whether to show chat or the fallback "الدردشة غير متاحة" message.

## 4) Models (essentials)

- ChatMessage: id, threadId, senderId, text, type (text/image/file/audio), status, timestamps, attachments list, read receipts (status/readBy mapped to status).
- ChatThread: id, participantIds, lastMessage, unreadCount, isGroup flag, name/avatar for display.
- ChatUser: id, name, avatarUrl, roleId, branchId, companyId, isOnline, lastSeen.
- ChatAttachment: id, url, type, thumbUrl, name, size, mimeType.
- ChatPresence: isOnline, lastSeen, typing status map.
- ChatUserSession: firebaseUid, odooUserId, employeeId, roleId, branchId, companyId, firebaseCustomToken, hasToken, chatAvailable.

## 5) Services

- firebase_chat_auth_service.dart
  - signInWithCustomToken(); logs token length/preview; handles auth errors.
- chat_message_service.dart
  - send text/image/file/audio; handles uploads to Storage; writes Firestore docs; updates lastMessage.
- chat_thread_service.dart
  - fetch threads, create new DM thread, search users (through repository), watch thread changes.
- chat_presence_service.dart
  - set presence online/offline; set typing flag per thread; watch presence/typing via Realtime DB.

## 6) Repositories

- chat_repository.dart: Facade over services for threads/messages.
- user_repository.dart: Fetch/search users (wired to existing employee list / backend search as implemented earlier).

## 7) UI Behavior

- chat_list_screen.dart: Shows list of threads; if chat disabled shows "الدردشة غير متاحة".
- chat_screen.dart: Message list with bubbles, attachments, voice note support, typing indicator, presence chip.
- new_chat_screen.dart: Search users and start a new DM thread.
- Widgets: message_bubble (handles types), chat_input_bar (text, attachments, mic), typing_indicator, chat_avatar, presence_indicator.

## 8) Integration Points

- Login model (lib/ui/presentation/signin/data/model.dart): includes firebase_uid, firebase_custom_token, odoo_user_id, employee_id, is_attendance_manager, default_operating_unit_id (branchId).
- Chat init (lib/chat/chat_module_helper.dart): builds session + kicks off Firebase auth.
- Sign-in flow (lib/ui/presentation/signin/bloc/sign_in_bloc.dart): after successful login, calls chat init.
- Navigation (lib/ui/presentation/home_screen/screens/main_screens.dart): added chat tab/icon (index 3) to open chat list.

## 9) Firebase Expectations

- App configured for project: elrace-new (from android/app/google-services.json).
- Backend must generate custom tokens using Service Account from the same project elrace-new.
- UID format expected: odoo\_{odoo_user_id} (e.g., odoo_1321).

## 10) Known Issue (blocking)

- Error: CONFIGURATION_NOT_FOUND when calling signInWithCustomToken.
- Root cause: Backend using Service Account from a different Firebase project.
- Required backend fix: regenerate Service Account JSON from elrace-new and use it to create tokens. Ensure project_id inside JSON is elrace-new and client_email ends with @elrace-new.iam.gserviceaccount.com.

## 11) Testing Checklist (after backend fix)

- Login -> Firebase auth succeeds (no CONFIGURATION_NOT_FOUND).
- FirebaseAuth.currentUser.uid equals expected odoo\_{user_id}.
- Chat tab loads threads without "الدردشة غير متاحة".
- Send text, image, file, voice note; verify appears in Firestore and Storage upload succeeds.
- Presence shows online/last seen; typing indicator works when typing from another device/user.
- Notifications (if configured separately) should receive FCM for new messages.

## 12) Quick References

- Session mapping: lib/chat/models/chat_user_session.dart
- Auth: lib/chat/services/firebase_chat_auth_service.dart
- Chat init orchestration: lib/chat/chat_module_helper.dart
- Sign-in trigger: lib/ui/presentation/signin/bloc/sign_in_bloc.dart
- UI screens: lib/ui/chat/
- Widgets: lib/ui/chat/widgets/
- Bottom nav entry: lib/ui/presentation/home_screen/screens/main_screens.dart

## 13) Next Actions

- Backend: switch to correct elrace-new Service Account and regenerate custom tokens.
- Mobile: retest login + chat; capture logs (token length/preview and Firebase error if any) if problem persists.
