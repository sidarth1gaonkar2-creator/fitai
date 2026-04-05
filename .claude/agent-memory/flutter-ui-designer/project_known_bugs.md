---
name: Known Bugs and Planned Fixes
description: Confirmed bugs found via code research, with exact file locations and root causes
type: project
---

## Fix 1 — Micronutrient Section always-show
**File:** `lib/features/nutrition/presentation/nutrition_screen.dart` lines 90–93
**Bug:** Two `if (micros.values.any((v) => v > 0))` guards hide the entire `MicronutrientSection` when no food has been logged.
**Finding:** `MicronutrientSection` itself handles zero values correctly — `_MicronutrientRow` shows "0.00 / 18 mg (0%)" and an empty progress bar at 0. The only needed change is removing both conditional guards in `nutrition_screen.dart` (the widget and the SizedBox spacer after it) so `MicronutrientSection(consumed: micros)` always renders.
**Note:** The subtitle already says "0 of 10 nutrients tracked today" when all values are zero — this is correct zero-state text.

## Fix 2 — DayCompletionSheet missing
**File:** `lib/features/nutrition/presentation/widgets/complete_day_button.dart` lines 38–51
**Bug:** `_CompleteButton.onComplete` callback calls `completeDay(ref)` directly inside the `onComplete` closure. No bottom sheet is shown before committing.
**Data available from CompletedDay model:** caloriesConsumed, proteinConsumed, carbsConsumed, fatConsumed, calorieTarget, proteinTarget, carbsTarget, fatTarget, macrosHit.
**Score formula:** Can be computed before writing — use same `inRange()` logic from `completeDay()` in nutrition_providers.dart to count how many of 3 macros are in range (0-3), multiply by ~33 to get 0–100 score.
**Plan:** New widget `DayCompletionSheet` shown via `showModalBottomSheet`. Only calls `completeDay(ref)` if user taps "Confirm". Celebration shown if score >= 80 (all macros hit).

## Fix 3 — Settings back button
**File:** `lib/features/settings/presentation/settings_screen.dart` line 24
**Bug:** `CloseButton()` uses `Navigator.pop()`. Since `/settings` is defined as a standalone `GoRoute` outside the `StatefulShellRoute`, `Navigator.pop()` does not restore the shell/tab state — it may show a black screen or go nowhere if settings was pushed from dashboard.
**Router structure confirmed:** `/settings` uses `slideUpTransitionPage` so it's on the Navigator stack. `Navigator.pop()` technically works BUT the correct idiom for go_router routes outside the shell is `context.go('/dashboard')` to ensure the shell branch is correctly restored.
**Fix:** Replace `const CloseButton()` with `IconButton(icon: const Icon(Icons.close), onPressed: () => context.go('/dashboard'))`.

## Fix 4 — Food search local results
**File:** `lib/features/nutrition/presentation/food_search_screen.dart` lines 50–57
**Finding:** `foodLocalSearchProvider` IS a synchronous `Provider.family<List<FoodSearchResult>, String>` — not a FutureProvider. `FoodSearchScreen` reads it directly via `ref.watch(foodLocalSearchProvider(_currentQuery))` which returns synchronously in the same frame. There is NO loading state needed for local results. The remote provider (`foodRemoteSearchProvider`) is a `FutureProvider.family` and is handled separately with shimmer skeletons.
**Conclusion:** Local search is already truly instant. No change needed to the provider architecture. The 400ms debounce on the TextField is the only delay before local results appear — this is intentional UX to avoid flickering on every keystroke. This fix is a no-op; the implementation is correct.

## Fix 5 — NutritionSummaryCard macro bars
**File:** `lib/features/nutrition/presentation/widgets/daily_summary_header.dart`
**Finding:** All 3 macro bars already show "Xg / Yg" format (line 152). Color coding is implemented correctly via `_macroColor()`: <90% primary, 90-110% secondary, >110% error (lines 96-115). CalorieRing is 120x120 (line 38-40 — not 120dp as stated, it's the correct size for the nutrition screen; the dashboard ring is 200x200). Card is always the first item in NutritionScreen's column.
**Gap found:** `_MacroProgressBar` does NOT show percentage. The label row shows only "Xg / Yg" — the percentage is missing from the nutrition card's macro bars (though it IS shown in MicronutrientSection rows). This is the only genuine gap.
**Fix:** Add a percentage text to `_MacroProgressBar` label row — e.g., append "(72%)" after the gram values.

**Why:** 120dp CalorieRing is appropriate for the Nutrition screen (beside the macro bars). The Dashboard uses 200dp. Both are correct by design.
