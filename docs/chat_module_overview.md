# Chat Module Overview

## What is implemented

- Data models: `lib/chat/models/` (chat_message, chat_user, chat_thread, chat_attachment, chat_user_session, chat_presence)
- Services: `lib/chat/services/` (firebase_chat_auth_service, chat_message_service, chat_thread_service, chat_presence_service)
- Repositories: `lib/chat/repositories/` (chat_repository, user_repository)
- UI Screens: `lib/ui/chat/` (chat_list_screen.dart, chat_screen.dart, new_chat_screen.dart)
- UI Widgets: `lib/ui/chat/widgets/` (message_bubble.dart, chat_input_bar.dart, typing_indicator.dart, chat_avatar.dart, presence_indicator.dart)
- Navigation: chat tab added in `lib/ui/presentation/home_screen/screens/main_screens.dart`
- Initialization: chat init triggered from SignIn flow (`sign_in_bloc.dart`) after successful login

## Data flow (high level)

1. User logs in via backend API (Odoo). Login response is parsed into `LoginResponseModel.Data` with fields: odoo_user_id, employee_id, firebase_uid, firebase_custom_token, is_attendance_manager, default_operating_unit_id (branch_id), etc.
2. `ChatUserSession` builds the chat session from login data (prefers employee_id over emp_id, default_operating_unit_id over branch_id).
3. `FirebaseChatAuthService` signs in with the provided `firebase_custom_token`. On success, chat services use Firebase (Auth, Firestore, Storage, Realtime DB) for threads/messages/presence.
4. UI uses `ChatModuleHelper.instance.isChatEnabled` to show chat screens; otherwise shows "الدردشة غير متاحة".

## Current blocker (must fix on backend)

- Error: `CONFIGURATION_NOT_FOUND` from `signInWithCustomToken`.
- Cause: Backend is generating the custom token using a Service Account from a different Firebase project.
- App is configured for Firebase project: `elrace-new` (from `android/app/google-services.json`).
- Action for backend:
  - Download a new Service Account JSON from Firebase Console for project `elrace-new`.
  - Use that JSON in the backend when calling `auth.create_custom_token(...)` (Python/Node examples were shared).
  - Ensure `project_id` inside the JSON equals `elrace-new` and `client_email` ends with `@elrace-new.iam.gserviceaccount.com`.

## Testing once backend fixes token

- Login -> Chat init logs should show Firebase Auth success (no CONFIGURATION_NOT_FOUND).
- `FirebaseAuth.instance.currentUser?.uid` should equal `odoo_{user_id}` (e.g., `odoo_1321`).
- Chat tab should load thread list; sending text/image/file/voice-note should succeed; presence/typing indicators should display.

## File references to check

- Models: `lib/chat/models/chat_user_session.dart`, `lib/ui/presentation/signin/data/model.dart`
- Auth: `lib/chat/services/firebase_chat_auth_service.dart`
- Init: `lib/chat/chat_module_helper.dart`, `lib/ui/presentation/signin/bloc/sign_in_bloc.dart`
- UI: `lib/ui/chat/*.dart`, `lib/ui/chat/widgets/*.dart`
- Navigation: `lib/ui/presentation/home_screen/screens/main_screens.dart`

## Next steps

- Backend: switch to the correct `elrace-new` Service Account and regenerate custom tokens.
- Mobile: retest login + chat; if still failing, capture the new token length/preview log and Firebase error message.
