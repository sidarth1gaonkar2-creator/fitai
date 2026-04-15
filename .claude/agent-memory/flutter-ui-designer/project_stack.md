---
name: Project Stack
description: FitAI tech stack, key package versions, and architecture constraints (updated April 2026)
type: project
---

## App Entry
- CupertinoApp.router (lib/app.dart) with Material ThemeData wrapper in builder
- Firebase + Isar dual persistence (Firebase for social, Isar for local data)

## Packages (pubspec.yaml)

### Core
- flutter_riverpod: ^2.6.1
- isar: ^3.1.0+1 + isar_flutter_libs + isar_generator
- go_router: ^14.8.1
- flutter_dotenv: ^5.2.1
- path_provider: ^2.1.5
- shared_preferences: ^2.3.4

### Firebase
- firebase_core: ^3.0.0
- firebase_auth: ^5.0.0
- cloud_firestore: ^5.0.0
- firebase_storage: ^12.0.0
- google_sign_in: ^6.2.0

### UI & Media
- fl_chart: ^0.70.2
- flutter_svg: ^2.0.10+1
- cached_network_image: ^3.3.0
- image_picker: ^1.1.0
- mobile_scanner: ^6.0.2

### Notifications & Time
- flutter_local_notifications: ^21.0.0
- timezone: ^0.11.0
- timeago: ^3.7.0

### Utilities
- uuid: ^4.5.1

### Dev
- build_runner: ^2.4.13
- isar_generator: ^3.1.0+1
- mocktail: ^1.0.4

## Architecture Constraints
- **Isar v3 codegen conflicts with modern build_runner-based codegen** (like Riverpod's @riverpod). All Riverpod providers are written manually. Never suggest code-generated providers.
- No animation packages (lottie, rive) installed
- Shimmer system is custom-built — no shimmer package
- Fonts bundled locally as assets (Poppins + LeagueSpartan), NOT google_fonts

## Assets
- assets/.env (API keys)
- assets/images/body_front.svg, body_back.svg (muscle diagram)
- assets/fonts/ (Poppins Regular/Medium/SemiBold/Bold, LeagueSpartan Regular/Medium/Bold)
