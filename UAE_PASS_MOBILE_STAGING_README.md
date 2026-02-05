# UAE PASS Mobile (STAGING) Integration – ELRACE

## Architecture Summary (1 page)

- **Flow**: Login starts in the app → UAE PASS opens in system browser → UAE PASS redirects to backend callback (`https://erp.elrace.com/uaepass/callback`) → backend exchanges code using client_secret → backend redirects to app deep link (`elrace://uaepass/success?...`) → app validates and completes session → Dashboard.
- **Security**: `client_secret` never touches Flutter. State is generated in-app and stored in secure storage to validate callback. Tokens/sessions are stored in `flutter_secure_storage` and login data is cached in SharedPreferences (existing app convention).
- **Deep Links**: `app_links` listens for new links. UAE PASS links are handled by `UaepassLinkHandler` and passed into `UaepassAuthService`.
- **State Management**: `UaepassAuthCubit` drives loading/success/error states, displayed on `AuthLoadingScreen`.
- **Error Mapping**: Backend errors are mapped to exactly 4 UI buckets: Existing users only, Unverified/Not eligible, Something went wrong, User cancel.
- **Staging Config**: `UaepassConfig.staging()` centralizes all staging values and feature flags.
- **Debug Logging**: `UaepassLogger` provides masked, debug-only logging throughout the flow.

---

## Debug Logging

All UAE PASS debug logs are controlled by `kDebugMode` and will NOT appear in release builds.

### Security Rules (Enforced)

- ❌ `client_secret` is NEVER logged
- ✅ Tokens are masked: first 6 chars + `***` + last 4 chars
- ✅ All sensitive fields (`token`, `access_token`, `id_token`, `refresh_token`, `secret`, `code`) are auto-masked

### Log Points

1. **Login Start** - client_id, redirect_uri, scope, state, full auth URL
2. **Browser Open** - launch mode, success/failure
3. **Deep Link Received** - full URI, parsed parts, session/tx params
4. **API Calls** - method, URL, request/response bodies (masked)
5. **Error Mapping** - which of the 4 error types was selected
6. **Logout** - confirmation of storage cleared

### Helper Functions (lib/utils/uaepass_logger.dart)

- `UaepassLogger.log(msg)` - basic log
- `UaepassLogger.logKV(key, value)` - key-value with auto-masking
- `UaepassLogger.logUri(label, uri)` - parse and log URI parts
- `UaepassLogger.maskSensitive(str)` - manual token masking
- `UaepassLogger.safeJsonEncode(map)` - JSON with masked sensitive fields

---

## Sample Console Output

### Successful Login

```
============================================================
🔐 UAE PASS UAE PASS LOGIN START
============================================================
🔐 UAE PASS   Environment: STAGING
🔐 UAE PASS   Timestamp: 2026-02-05T14:32:15.123456
🔐 UAE PASS   client_id: auh_elrace_mob_stage
🔐 UAE PASS   redirect_uri (raw): https://erp.elrace.com/uaepass/callback
🔐 UAE PASS   redirect_uri (encoded): https%3A%2F%2Ferp.elrace.com%2Fuaepass%2Fcallback
🔐 UAE PASS   scope: urn:uae:digitalid:profile:general
🔐 UAE PASS   response_type: code
🔐 UAE PASS   state: a1b2c3d4-e5f6-7890-abcd-ef1234567890
🔐 UAE PASS   state stored in: memory + secure_storage
🔐 UAE PASS Authorization URL:
🔐 UAE PASS   Full URL: https://stg-id.uaepass.ae/idshub/authorize?response_type=code&client_id=auh_elrace_mob_stage&...
🔐 UAE PASS Opening system browser for UAE PASS
🔐 UAE PASS   LaunchMode: externalApplication (Custom Tabs / Safari)
🔐 UAE PASS ✅ Browser opened successfully

============================================================
🔐 UAE PASS DEEPLINK RECEIVED
============================================================
🔐 UAE PASS Incoming URI:
🔐 UAE PASS   Full URI: elrace://uaepass/success?session=abc123&state=a1b2c3d4-e5f6-7890-abcd-ef1234567890
🔐 UAE PASS   Scheme: elrace
🔐 UAE PASS   Host: uaepass
🔐 UAE PASS   Path: /success
🔐 UAE PASS   Query: session=abc123&state=...
🔐 UAE PASS   Stored state: a1b2c3d4-e5f6-7890-abcd-ef1234567890
🔐 UAE PASS   Incoming state: a1b2c3d4-e5f6-7890-abcd-ef1234567890
🔐 UAE PASS ✅ State validation passed

============================================================
🔐 UAE PASS API: SESSION EXCHANGE
============================================================
🔐 UAE PASS   Endpoint: uaepass/mobile/session
🔐 UAE PASS   Method: POST
🔐 UAE PASS   Request body: {"session": "abc123***7890"}
🔐 UAE PASS   Response status: 200
🔐 UAE PASS Response body (masked):
{
  "result": {
    "success": true,
    "token": "eyJhbG***wxyz",
    "data": { "uid": 123, "name": "Ahmed" }
  }
}
🔐 UAE PASS ✅ UAEPASS LOGIN SUCCESS
🔐 UAE PASS   User ID: 123
🔐 UAE PASS   Name: Ahmed
```

### Error: Something Went Wrong

```
============================================================
🔐 UAE PASS DEEPLINK RECEIVED
============================================================
🔐 UAE PASS   Full URI: elrace://uaepass/error?error=server_error
🔐 UAE PASS   error param: server_error
🔐 UAE PASS ❌ No session or tx in deeplink
🔐 UAE PASS ❌ UAEPASS LOGIN FAILED
🔐 UAE PASS   Error mapping result: GENERIC
🔐 UAE PASS Cubit: Emitting failure state
🔐 UAE PASS   Failure type: AuthFailureType.generic
🔐 UAE PASS   UI Message: Something went wrong
```

### User Cancel

```
============================================================
🔐 UAE PASS DEEPLINK RECEIVED
============================================================
🔐 UAE PASS   Full URI: elrace://uaepass/error?error=access_denied
🔐 UAE PASS   Cancel detected: error=access_denied, status=null, result=null
🔐 UAE PASS ⚠️ User cancelled or declined
🔐 UAE PASS ❌ UAEPASS LOGIN FAILED
🔐 UAE PASS Cubit: Emitting failure state
🔐 UAE PASS   Failure type: AuthFailureType.cancelled
🔐 UAE PASS   UI Message: User cancel
```

---

## File Plan (what changed)

- **Config**
  - lib/config/uaepass_config.dart: Staging configuration, URLs, flags, UI messages.
- **Services**
  - lib/services/api_client.dart: Minimal Dio wrapper.
  - lib/services/uaepass_auth_service.dart: startLogin, handleCallbackOrResult, mapErrorsToUiMessages, logout.
- **State**
  - lib/auth/uaepass_auth_cubit.dart
  - lib/auth/uaepass_auth_state.dart
- **Deep Links**
  - lib/deep_links/uaepass_link_handler.dart
- **UI**
  - lib/ui/auth/auth_loading_screen.dart
  - lib/ui/auth/error_dialog.dart
  - lib/ui/auth/dashboard_screen.dart
  - lib/ui/presentation/signin/sign_in_screen.dart: added UAE PASS button.
- **Platform**
  - android/app/src/main/AndroidManifest.xml: deep link intent-filters.
  - ios/Runner/Info.plist: URL scheme.
- **DI / App Wiring**
  - lib/utils/di.dart: registrations.
  - lib/main.dart: UAE PASS deep link handler + cubit.
- **Models**
  - lib/services/uaepass_models.dart: LoginSuccess/LoginFailure models

---

## STAGING Configuration

Edit in [lib/config/uaepass_config.dart](lib/config/uaepass_config.dart):

- clientId: `auh_elrace_mob_stage`
- redirectUrl: `https://erp.elrace.com/uaepass/callback`
- authorizationBaseUrl / authorizationPath: **keep staging from UAE PASS guide**
- baseApiUrl: `https://erp.elrace.com/api/`
- sessionExchangePath: `uaepass/mobile/session`
- resultPollingPath: `uaepass/result`
- Deep link scheme/host/path: `elrace://uaepass/success` and `elrace://uaepass/error`
- Feature flags:
  - useBackendRedirectDeepLink: `true` (preferred)
  - enablePollingFallback: `false` (option 2)

> **Important**: Add the official UAE PASS button asset to `assets/png/uaepass_button.png` to match the PDF mockup exactly.

---

## Deep Link Testing Commands

### Android (via adb)

```bash
# Success scenario with session
adb shell am start -a android.intent.action.VIEW \
  -d "elrace://uaepass/success?session=test123\&state=abc" \
  com.elrace.elraceapp

# Success scenario with tx
adb shell am start -a android.intent.action.VIEW \
  -d "elrace://uaepass/success?tx=txn456\&state=abc" \
  com.elrace.elraceapp

# Error: User cancelled
adb shell am start -a android.intent.action.VIEW \
  -d "elrace://uaepass/error?error=access_denied\&code=CANCELLED" \
  com.elrace.elraceapp

# Error: Not eligible
adb shell am start -a android.intent.action.VIEW \
  -d "elrace://uaepass/error?error_code=NOT_ELIGIBLE\&message=User%20not%20eligible" \
  com.elrace.elraceapp

# Error: Existing users only
adb shell am start -a android.intent.action.VIEW \
  -d "elrace://uaepass/error?error_code=EXISTING_USERS_ONLY" \
  com.elrace.elraceapp

# Generic error
adb shell am start -a android.intent.action.VIEW \
  -d "elrace://uaepass/error?error=server_error" \
  com.elrace.elraceapp
```

### iOS Simulator (via xcrun simctl)

```bash
# Get booted device ID
xcrun simctl list | grep Booted

# Success scenario with session
xcrun simctl openurl booted "elrace://uaepass/success?session=test123&state=abc"

# Success scenario with tx
xcrun simctl openurl booted "elrace://uaepass/success?tx=txn456&state=abc"

# Error: User cancelled
xcrun simctl openurl booted "elrace://uaepass/error?error=access_denied&code=CANCELLED"

# Error: Not eligible
xcrun simctl openurl booted "elrace://uaepass/error?error_code=NOT_ELIGIBLE&message=User%20not%20eligible"

# Error: Existing users only
xcrun simctl openurl booted "elrace://uaepass/error?error_code=EXISTING_USERS_ONLY"

# Generic error
xcrun simctl openurl booted "elrace://uaepass/error?error=server_error"
```

---

## Expected Console Output

### Test 1: Deep Link Success (manual test)

```
============================================================
🔐 UAE PASS DEEPLINK RECEIVED
============================================================
🔐 UAE PASS Full URI: elrace://uaepass/success?session=test123&state=abc
🔐 UAE PASS   Scheme: elrace
🔐 UAE PASS   Host: uaepass
🔐 UAE PASS   Path: /success
🔐 UAE PASS   Query: session=test123&state=abc
🔐 UAE PASS Query Parameters:
🔐 UAE PASS     session: test123
🔐 UAE PASS     state: abc
🔐 UAE PASS   Is Success Link: true
🔐 UAE PASS   Is Error Link: false
🔐 UAE PASS   Session param: test123
🔐 UAE PASS   TX param: <not present>
🔐 UAE PASS   Error param: <not present>
🔐 UAE PASS ✅ Session found - storing temporarily
🔐 UAE PASS Processing as UAE PASS callback...
🔐 UAE PASS Cubit: handleCallbackOrResult called

============================================================
🔐 UAE PASS DEEPLINK RECEIVED
============================================================
🔐 UAE PASS Incoming URI:
🔐 UAE PASS   Full URI: elrace://uaepass/success?session=test123&state=abc
🔐 UAE PASS   ...
🔐 UAE PASS   session param: test123
🔐 UAE PASS   Session stored, proceeding to exchange

============================================================
🔐 UAE PASS API: SESSION EXCHANGE
============================================================
🔐 UAE PASS   Endpoint: uaepass/mobile/session
🔐 UAE PASS   Method: POST
🔐 UAE PASS   Request body: {"session": "test12***t123"}
(API call happens here - will fail until backend is ready)
```

### Test 2: Deep Link Error - User Cancelled

```
============================================================
🔐 UAE PASS DEEPLINK RECEIVED
============================================================
🔐 UAE PASS Full URI: elrace://uaepass/error?error=access_denied&code=CANCELLED
🔐 UAE PASS   Scheme: elrace
🔐 UAE PASS   Host: uaepass
🔐 UAE PASS   Path: /error
🔐 UAE PASS   Query: error=access_denied&code=CANCELLED
🔐 UAE PASS Query Parameters:
🔐 UAE PASS     error: access_denied
🔐 UAE PASS     code: CANCELLED
🔐 UAE PASS   Is Success Link: false
🔐 UAE PASS   Is Error Link: true
🔐 UAE PASS   Session param: <not present>
🔐 UAE PASS   TX param: <not present>
🔐 UAE PASS   Error param: access_denied
🔐 UAE PASS ⚠️ Error code received: access_denied
🔐 UAE PASS Processing as UAE PASS callback...

🔐 UAE PASS   Cancel detected: error=access_denied, status=null, result=null
🔐 UAE PASS ⚠️ User cancelled or declined
🔐 UAE PASS ❌ UAEPASS LOGIN FAILED
🔐 UAE PASS Cubit: Emitting failure state
🔐 UAE PASS   Failure type: AuthFailureType.cancelled
🔐 UAE PASS   UI Message: User cancel
```

### Test 3: "I have approved" Button Press

```
============================================================
🔐 UAE PASS TRY FINALIZE LOGIN
============================================================
🔐 UAE PASS User pressed "I have approved" button
🔐 UAE PASS Cubit: tryFinalizeLogin called

============================================================
🔐 UAE PASS TRY FINALIZE FROM STORED DATA
============================================================
🔐 UAE PASS ⚠️ No stored session/tx and polling disabled
🔐 UAE PASS User may need to wait for deep link callback
🔐 UAE PASS Cubit: Finalization failed
🔐 UAE PASS   Failure type: AuthFailureType.generic
🔐 UAE PASS   UI Message: Something went wrong
```

(If backend sends deep link with session first, then button press would succeed)

---

## Backend Contract (required)

### 1) Session Exchange (preferred flow)

**POST** `/api/uaepass/mobile/session`

**Request**

```json
{ "session": "<session_or_tx_from_backend_redirect>" }
```

**Success Response (must match LoginResponseModel)**

```json
{
  "jsonrpc": "2.0",
  "id": null,
  "result": {
    "success": true,
    "token": "<app_session_token>",
    "data": { "uid": 123, "emp_id": "...", "name": "..." }
  }
}
```

**Failure Response**

```json
{
  "success": false,
  "error_code": "EXISTING_USERS_ONLY|NOT_ELIGIBLE|CANCELLED|GENERIC",
  "message": "..."
}
```

### 2) Polling Result (fallback option)

**GET** `/api/uaepass/result?tx=<transactionId>`

Same response format as above. App polls until timeout.

---

## Android Setup

1. **Deep link intent-filter** already added in:
   - [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)
2. Ensure Android 12+ exported requirements remain satisfied (already set).

## iOS Setup

1. **URL Scheme** added in:
   - [ios/Runner/Info.plist](ios/Runner/Info.plist)
2. If you decide to use **Universal Links**, add Associated Domains:
   - `applinks:<your-domain>`

---

## How to Run (STAGING)

1. Ensure UAE PASS staging user is created/upgraded per UAE PASS docs.
2. Configure **staging** values in [lib/config/uaepass_config.dart](lib/config/uaepass_config.dart).
3. Add UAE PASS button asset at `assets/png/uaepass_button.png`.
4. Build & run.

---

## Test Checklist (STAGING)

- [ ] Deep link success (adb/xcrun command)
- [ ] Deep link error cancelled (adb/xcrun command)
- [ ] Deep link error not eligible (adb/xcrun command)
- [ ] Deep link error existing users only (adb/xcrun command)
- [ ] Deep link error generic (adb/xcrun command)
- [ ] "I have approved" button press
- [ ] Login success (full flow with UAE PASS)
- [ ] Cancel scenario (full flow)

## Assessment Demo Notes

1. Open Login → tap **Sign in with UAE PASS**.
2. System browser opens UAE PASS → approve.
3. App resumes via deep link → Loading → Dashboard.
4. Repeat for each error scenario and show the corresponding UI message.
5. Logout → verify Login screen.

---

## Notes / Compliance

- No `client_secret` in Flutter.
- Uses system browser (Custom Tabs / Safari) for UAE PASS authentication.
- Logs are non-sensitive; no token or code is printed in production builds.
