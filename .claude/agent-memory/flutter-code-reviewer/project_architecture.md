---
name: Project Architecture
description: FitAI stack, conventions, and deliberate design decisions (updated April 2026)
type: project
---

Flutter fitness app targeting iOS (and Android). Dual persistence: Isar (local data) + Firebase (social/community).

**App entry:** CupertinoApp.router with Material ThemeData wrapper in builder.

**Stack:** Flutter + Riverpod (manual providers, no code-gen) + Isar v3 + Firebase (Auth, Firestore, Storage) + go_router.

**Why manual providers:** isar_generator has codegen conflicts with other build_runner generators, so all Riverpod providers are hand-written. Never suggest migrating to code-generated providers.

**Color system:** iOS-native black/white/blue palette. Legacy variable names in AppColors (purple, lime, purpleDark, etc.) are misleading — they map to blues and white, not their namesake colors. Always check actual hex values before referencing colors.

**Key directories:**
- `lib/data/` — static in-memory databases: `us_food_database.dart` (142 foods), `exercise_library.dart` (106 exercises), `workout_templates.dart` (20 templates), `supplement_library.dart` (20+ supplements)
- `lib/models/` — Isar @collection classes + plain Dart models (17 collections)
- `lib/providers/` — all Riverpod providers (12+ provider files)
- `lib/services/` — auth_service, storage_service, firestore_service, notification_service, supplement_api_service, pr_migration_service, anthropic_service, open_food_facts_service
- `lib/features/<feature>/presentation/` — screens and widgets
- `lib/features/community/domain/` — Firestore domain models (not Isar)
- `lib/features/community/data/` — Firestore repository classes
- `lib/core/` — shared widgets, constants, utils, database init, theme

**Routing:** go_router with StatefulShellRoute.indexedStack (5 tabs). Uses `context.go()` for navigation. Auth/onboarding/profile-setup are standalone routes with redirect guards.

**How to apply:** Use this context when reviewing new files to understand where they fit and whether they follow the established patterns.
