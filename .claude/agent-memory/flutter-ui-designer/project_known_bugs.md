---
name: Known Bugs and Planned Fixes
description: Confirmed bugs found via code research, with exact file locations and root causes
type: project
---

## RESOLVED — Dark theme + UI overhaul fixes (2026-04-06)

### Theme default was ThemeMode.system
**File:** `lib/providers/settings_providers.dart`
**Fix applied:** Changed `ThemeMode.system` → `ThemeMode.dark` so the app defaults to dark mode always.

### Calendar BOTTOM OVERFLOW
**File:** `lib/features/workouts/presentation/widgets/workout_calendar.dart`
**Root cause:** `GridView.builder` inside `Column` inside another `Column` — `shrinkWrap: true` but height was unbounded.
**Fix applied:** Replaced `Card.filled()` with an explicit `Container` (darkSurface, border). Used `SliverGridDelegateWithFixedCrossAxisCount` with `mainAxisExtent: 36.0` and wrapped the GridView in a `SizedBox` with calculated height (`rowCount * 36 + (rowCount-1) * 2`). Changed `shrinkWrap: false` with explicit height. Calendar never overflows.

### Tab toggle pill style (Workouts + Nutrition)
**Fix applied:** Inactive pills now use `Border.all(color: Colors.white.withValues(alpha: 0.6))` and white text. Active pill stays lime green with black text. Container is darkSurface (#242424) with very subtle white border.

### Calendar card styling (white background)
**Fix applied:** Replaced `Card.filled()` with explicit `Container(color: AppColors.darkSurface)` so calendar card matches design token (#242424) instead of Flutter's `colorScheme.surfaceContainerHighest`.

### Workouts screen missing header / overflow in Column body
**Fix applied:** Removed `AppBar`. Added `_WorkoutsHeader` widget (purple background, SafeArea, title + search/bell/profile icons, pill tab toggle). Body is now `Column` with `Expanded(child: TabBarView(...))`. History tab uses `CustomScrollView` with `SliverList` instead of `Column + Expanded + ListView` to avoid double scroll + overflow.

### Shell bottom nav overlap
**File:** `lib/features/shell/presentation/shell_screen.dart`
**Fix applied:** Added `extendBody: false` to shell Scaffold + explicit `backgroundColor: AppColors.darkBackground`.

### Remaining items (not yet fixed — tracked below)

## Fix 1 — Micronutrient Section always-show
**File:** `lib/features/nutrition/presentation/nutrition_screen.dart` lines 90–93
**Bug:** `MicronutrientSection` hidden when no micros logged.

## Fix 2 — DayCompletionSheet missing
**File:** `lib/features/nutrition/presentation/widgets/complete_day_button.dart`
**Bug:** No confirmation sheet before calling `completeDay(ref)`.

## Fix 3 — Settings back button
**File:** `lib/features/settings/presentation/settings_screen.dart` line 24
**Bug:** `CloseButton()` uses `Navigator.pop()` — should be `context.go('/dashboard')`.
