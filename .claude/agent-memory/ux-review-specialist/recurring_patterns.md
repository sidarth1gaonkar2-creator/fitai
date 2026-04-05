---
name: Recurring Patterns
description: Anti-patterns and good practices observed consistently across the FitAI codebase
type: project
---

## Recurring Anti-Patterns

**Silent error swallowing in charts and async widgets**
- Pattern: `error: (_, _) => const SizedBox.shrink()` used in StrengthChart (line 77), NutritionTrends (line 36), WorkoutsScreen calendar section (line 42), StrengthChart exercise picker (line 40), SettingsScreen profile section (line 55).
- Impact: Users see content disappear with no explanation or recovery path.
- Fix: Always use ErrorCard instead. ErrorCard exists and accepts onRetry.

**TextButton.icon as primary interactive element below 48dp**
- Pattern: MealSection "Add Food" and ExerciseCard "Add Set" both use TextButton.icon, which defaults to 36dp height.
- Fix: Wrap in SizedBox(height: 48) or use minimumSize: const Size(double.infinity, 48) on ButtonStyle.

**Missing haptics on tappable cards and list items**
- Pattern: WorkoutListTile, GoalStep _GoalCard, ActivityStep ListTile, FoodSearchScreen food result ListTile all have onTap with no HapticFeedback call.
- Convention established: lightImpact for selections, mediumImpact for confirmations/saves, heavyImpact for destructive actions.

**Missing haptics before destructive confirmations**
- Pattern: WorkoutDetailScreen delete FilledButton and AICoachScreen Clear History FilledButton fire no haptic when user taps confirm.
- HapticFeedback.heavyImpact() should be called inside the onPressed handler before the action executes.

**CustomPainter and chart widgets missing Semantics**
- Pattern: CalorieRing (CustomPainter) and MacroRow _MacroBar LinearProgressIndicator convey numeric data but have no Semantics wrappers.
- Fix: Wrap with Semantics(label: '$consumed of $target calories consumed').

**No retry action on inline error states**
- Pattern: DashboardScreen and WorkoutsScreen error branches show plain Text('Something went wrong.') with no retry button.
- ErrorCard widget exists and supports onRetry — use it consistently everywhere an async branch errors.

**Force-unwrap operators on navigation-supplied data**
- Pattern: app_router.dart line 145 `state.extra! as FoodSearchResult`; EditProfileScreen line 76 `findFirst()!`.
- Both will throw on null. Fix with null-check + error navigation/snackbar.

**Color-only macro identification**
- Pattern: DailySummaryHeader _MacroChip uses single letters P/C/F with color to distinguish macros. Fails for color-blind users.
- Fix: Use full labels "Protein" / "Carbs" / "Fat" or add semanticLabel.

## Good Patterns to Preserve

**Shimmer loading system** — custom ShimmerBox/ShimmerList/ShimmerCard used on Dashboard and Nutrition; avoids third-party dependency. Extend to StrengthChart and NutritionTrends.

**Manual Riverpod providers** — all providers are manual (no codegen) due to Isar v3 conflict; intentional and correct.

**Contextual empty states in WorkoutsScreen** — distinguishes "no workouts ever" vs "no workouts on selected date". Apply this pattern to other filtered lists.

**Error message friendliness** — FoodSearchScreen and AICoachController both map SocketException to human-readable messages. Extend to all network calls.

**Discard/delete confirmation dialogs** — WorkoutLoggingScreen and WorkoutDetailScreen both confirm destructive actions before executing. Maintain this pattern.

**Inline save-state buttons** — WorkoutLoggingScreen Finish and FoodDetailScreen Add both disable the button and show a 20dp CircularProgressIndicator while saving. Good pattern; copy to any other save flow.

**HapticFeedback.selectionClick() on NavigationBar** — ShellScreen fires selectionClick on every tab switch. Correct use of the lighter selection haptic for navigation.
