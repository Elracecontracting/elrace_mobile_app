# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Tech Stack

- **Framework**: Flutter (Dart SDK >=3.3.3 <4.0.0), version 1.0.18+70
- **State Management**: BLoC (`flutter_bloc`) for most features; `Provider` for tasks/announcements; `GetIt` for DI
- **Backend**: Firebase (Firestore, Auth, Messaging, Storage, Cloud Functions)
- **Local Storage**: Hive (primary), SharedPreferences, Flutter Secure Storage
- **Navigation**: GetX routing (`routes/app_routes.dart` for constants, `routes/app_pages.dart` for bindings)
- **Code Generation**: `build_runner` for Hive type adapters (`.g.dart` files)

## Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Analyze / lint
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Regenerate code (Hive adapters, serialization)
dart run build_runner build --delete-conflicting-outputs

# Firebase Cloud Functions (in /functions)
npm install
npm run serve      # local emulator
npm run deploy     # deploy to Firebase
```

## Architecture

### Module Structure
Each feature in `lib/ui/presentation/<feature>/` follows this layout:
```
feature/
├── bloc/        # Events, States, Bloc class
├── data/        # Models, API service layer
├── repository/  # Interface (IXxxRepository) + implementation
├── screens/     # Page widgets
└── widgets/     # Feature-specific components
```

### Initialization (lib/main.dart)
Three-phase startup to avoid blocking the UI:
1. **Phase 1** (before first frame): Firebase, SharedPreferences
2. **Phase 2** (post-frame): GetIt DI setup, Hive, AppConfig, core services
3. **Phase 3** (parallel): Non-critical services (WorkManager, prayer audio, chat lifecycle)

### Dependency Injection
All services are registered in `lib/utils/di.dart` via GetIt. Access via `sl<ServiceType>()` (alias for `GetIt.instance`).

Registration uses guarded helpers to prevent double-init:
```dart
void _registerLazySingletonIfNeeded<T>(T Function() factory) {
  if (!sl.isRegistered<T>()) sl.registerLazySingleton<T>(factory);
}
```
Blocs are registered as lazy singletons. The whole setup is guarded by `if (_diInitialized && sl.isRegistered<HomeBloc>()) return;`.

### BLoC Pattern
Events and states use `sealed class` with `Equatable`. The standard structure:
```dart
// events
sealed class MediaEvent extends Equatable { ... }
final class LoadMedia extends MediaEvent { ... }

// states
sealed class MediaState extends Equatable { ... }
final class MediaLoading extends MediaState { ... }
final class MediaLoaded extends MediaState { ... }

// bloc
class MediaBloc extends Bloc<MediaEvent, MediaState> {
  MediaBloc(this._repository) : super(MediaInitial()) {
    on<LoadMedia>(_onLoadMedia);
  }
}
```
Event handlers follow: emit Loading → fetch via repository → emit Loaded/Error.

### Repository Pattern
Repositories are defined as abstract interfaces and injected via DI:
```dart
abstract class IMediaRepository {
  Future<List<MediaModel>> getMedia();
}
```
Always depend on the interface, never the concrete class.

### Data Models
Models are manually serialized (no `json_serializable`). Hive-persisted models use annotations:
```dart
@HiveType(typeId: 0)
class ReportModel {
  @HiveField(0) final String id;
  @HiveField(1) final String name;

  factory ReportModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
  ReportModel copyWith({...}) { ... }
}
```
After adding or changing `@HiveType`/`@HiveField` annotations, regenerate with `build_runner`.

### Service Layers
Three directories are all named "services" with different scopes:
- `lib/services/` — App-level singletons: `ApiClient`, `UaepassAuthService`
- `lib/core/services/` — Cross-cutting: biometric auth, notifications, attendance sync, KYC liveness, `AppConfigService`
- `lib/data/services/` — Data-layer: `HiveService`, PDF, prayer audio/notifications, `UnifiedWorkmanagerDispatcher`

### Key Services
| Service | Location | Purpose |
|---|---|---|
| `FirebaseService` | `lib/firebase_service.dart` | Push notifications, FCM lifecycle |
| `HiveService` | `lib/data/services/` | Local DB operations |
| `AppConfigService` | `lib/core/services/` | Remote/local config |
| `UaepassAuthService` | `lib/services/` | UAE Pass OAuth flow |
| `UnifiedWorkmanagerDispatcher` | `lib/data/services/` | Background tasks |
| `PrayerAudioService` | `lib/data/services/` | Adhan audio playback |

### Isolated Modules
Two features live outside `lib/ui/presentation/` and have a complete self-contained sub-architecture:
- **`lib/chat/`** — Firebase Realtime Chat (models, repositories, services); UI is in `lib/ui/chat/`
- **`lib/report_module/`** — Reporting feature with its own `core/`, `data/`, and `presentation/` subtree

Treat these as independent sub-apps: they have their own constants, providers, and data layers.

### Naming Conventions
Most `lib/ui/presentation/` folders use `snake_case`, but a few legacy folders don't: `Attendace_list/`, `Email Approval/` (imported as `Email%20Approval` due to the space). Use `snake_case` for all new features.

### State Management Pattern
- **BLoC**: Used for all major features. Blocs are registered in DI and provided at the route/page level.
- **Provider**: Used for `TasksProvider`, `TodoFirebaseProvider`, `QRSurveyDataProvider`, `AnnouncementsProvider`.
- Prefer BLoC for new features to stay consistent with the majority of the codebase.

### Safe BLoC Access
`lib/utils/Util.dart` exposes a `safeGetBloc<T>()` helper that reads a BLoC from DI with retry logic. Use it instead of `sl<T>()` directly when accessing blocs from outside a `BlocProvider` tree (e.g. from a service or deep callback).

### Localization
Flutter Translate with Arabic/English. Strings live in `assets/i18n/`. Always use translation keys, never hardcoded strings.

### Security Features
The app includes jailbreak/root detection (`flutter_jailbreak_detection`), VPN detection, screen protection, and biometric auth. These checks run during initialization — avoid disabling them in non-debug builds.

## Firebase Project
- Project ID: `elrace-new`
- Firestore security rules: `firestore.rules`
- Cloud Functions runtime: Node.js 22 (`functions/`)
- The single Cloud Function `onNewChatMessage` fires on `chats/{chatId}/messages/{messageId}` writes and dispatches FCM push notifications to all chat members except the sender, looking up tokens from `users/{uid}/fcm_tokens`.

## Testing
Test files are in `test/`. Covers widget tests, API service tests, anti-spoofing tests, and user project tests. Uses the standard `flutter_test` package — no Mockito or BDD framework.
