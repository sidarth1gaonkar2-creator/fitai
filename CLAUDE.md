# DrillFit (repo: fitai)

Drill-sergeant fitness app with military rank progression. **iOS-only.**
Bundle `com.sidarth.fitai`, Firebase project `fitai-8ad4f`, app name DrillFit.

## Stack

- Flutter/Dart (CI pins Flutter 3.41.6), Riverpod (`flutter_riverpod`), `go_router`, `fl_chart`
- **Isar v3.1** local DB with per-uid named instances (`u_<uid>.isar`; `anon` when
  signed out) since the uid-scoping batch. `isarProvider` is the facade over the
  active instance — **never open Isar instances directly**. Design: `docs/uid-scoping-audit.md`.
- Firebase: Auth (Google + Apple sign-in), Firestore, Storage, Functions
  (`functions/index.js`, Node)
- Secrets via `flutter_dotenv` from bundled `assets/.env` — never hardcode keys

## Layout

- `lib/app.dart` — root widget; its auth listener is the single choke point for
  account transitions (Isar swap + reconcilers)
- `lib/core/` — constants, database, theme, utils (incl. `AppLogger`), widgets
- `lib/features/` — ai_coach, auth, community, dashboard, nutrition, onboarding,
  progress, ranks, settings, shell, splash, supplements, themes, tutorial, workouts
- `lib/providers/`, `lib/routing/`, `lib/services/`, `lib/models/`, `lib/data/`
- `functions/` — Firebase Cloud Functions
- `test/` — `unit/`, `widget/`, `helpers/` (mocktail)

## Build & release (Codemagic CI, iOS-only)

1. Bump version in `pubspec.yaml` (`version: x.y.z+build`) on Windows — version
   bumps happen **only** via pubspec.
2. Commit and push to `main`.
3. Start the Codemagic build (Release mode, Flutter 3.41.6) → TestFlight.

**NEVER build from unverified checkouts** — confirm the CI checkout matches the
pushed commit before shipping. Local machine is Windows: no iOS builds locally;
`flutter test` and `flutter analyze` do work.

## Rules

- **Audit before implement**: read the relevant code path end-to-end (and any
  docs/ design note) before changing it.
- **No silent catch blocks** — every catch must call `AppLogger.error(...)`
  (`lib/core/utils/logger.dart`).
- Store timestamps in **UTC**. Documented local-civil-date exceptions only, e.g.
  gym-streak `GymStreakData.lastAwardedEpochDay`
  (`lib/features/workouts/domain/streak_rewards.dart`).
- 14 onboarding widget-test failures are the pre-existing baseline — don't chase
  them in unrelated work, and don't add new failures.
- **Proof-of-completion** for delegated tasks = raw `git log` / `git status`
  output, not prose summaries.

## Commands

```bash
flutter test                                              # unit + widget tests
flutter analyze
dart run build_runner build --delete-conflicting-outputs  # Isar codegen
```
