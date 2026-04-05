---
name: Project Architecture
description: FitAI stack, conventions, and deliberate design decisions
type: project
---

Flutter fitness app targeting iOS (and Android). Stack: Flutter + Riverpod (manual providers,
no code-gen) + Isar v3 + go_router + Material 3.

**Why:** isar_generator has codegen conflicts with other build_runner generators, so all
Riverpod providers are hand-written. Never suggest migrating to code-generated providers.

**Key directories:**
- `lib/data/` — static in-memory databases: `us_food_database.dart` (142 foods),
  `exercise_library.dart` (106 exercises), `workout_templates.dart` (20 templates)
- `lib/models/` — Isar @collection classes + plain Dart models
- `lib/providers/` — all Riverpod providers
- `lib/features/<feature>/presentation/` — screens and widgets
- `lib/core/` — shared widgets, constants, utils, database init

**Routing:** go_router, uses `context.go()` for navigation.

**How to apply:** Use this context when reviewing new files to understand where they fit and
whether they follow the established patterns.
