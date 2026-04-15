---
name: Known Bugs and Planned Fixes
description: Confirmed bugs found via code research, with exact file locations and root causes
type: project
---

## RESOLVED — Dark theme + UI overhaul fixes (2026-04-06)

All items below were fixed during the purple/lime → iOS-native migration:
- Theme default changed to ThemeMode.dark
- Calendar bottom overflow fixed with explicit SizedBox height
- Tab toggle pill styling updated
- Calendar card styling fixed with explicit Container
- Workouts screen header/overflow fixed
- Shell bottom nav overlap fixed

## Remaining items (not yet fixed)

### Fix 1 — Micronutrient Section always-show
**File:** `lib/features/nutrition/presentation/nutrition_screen.dart` lines 90-93
**Bug:** `MicronutrientSection` hidden when no micros logged.

### Fix 2 — DayCompletionSheet missing
**File:** `lib/features/nutrition/presentation/widgets/complete_day_button.dart`
**Bug:** No confirmation sheet before calling `completeDay(ref)`.

### Fix 3 — Settings back button
**File:** `lib/features/settings/presentation/settings_screen.dart` line 24
**Bug:** `CloseButton()` uses `Navigator.pop()` — should be `context.go('/dashboard')`.

### Fix 4 — Theme.of(context) fallback risk
**File:** `lib/app.dart`
**Bug:** CupertinoApp.router does not provide a Material Theme ancestor by default. The builder wraps with `Theme(data: ...)` but any widget rendered outside the builder (e.g., in a separate Navigator) would get ThemeData.fallback() (light M3). All Material widgets must be inside the builder tree.
