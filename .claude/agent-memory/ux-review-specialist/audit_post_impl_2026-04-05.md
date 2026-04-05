---
name: Post-Implementation UX Audit — Phase 5/6 Features (2026-04-05)
description: Targeted review of all new/modified files from the nutrition redesign, food search redesign, exercise picker, muscle diagram, workout templates, workout detail, and settings CloseButton
type: project
---

## Scope
Files reviewed (all newly written or significantly modified):
- nutrition_screen.dart
- widgets/daily_summary_header.dart (NutritionSummaryCard)
- widgets/micronutrient_section.dart
- widgets/complete_day_button.dart
- widgets/meal_section.dart
- widgets/food_entry_tile.dart
- food_search_screen.dart
- exercise_picker_sheet.dart
- widgets/exercise_picker_card.dart
- core/widgets/muscle_group_diagram.dart
- workouts_screen.dart
- template_picker_sheet.dart
- template_preview_screen.dart
- workout_detail_screen.dart
- settings/presentation/settings_screen.dart

## Pre-Implementation Predictions vs Actual

### Resolved from pre-impl review
- [RESOLVED] Dual-source food search blocked on network: local results are now shown instantly via synchronous provider; remote is separate AsyncValue with shimmer while loading. Architecture is correct.
- [RESOLVED] Complete Day discoverability: placed in persistent bottomNavigationBar, always visible.
- [RESOLVED] Micronutrient empty state: tracked vs untracked are grouped; untracked shown with info icon and name list.
- [RESOLVED] Template access point: TabBar History/Templates inside WorkoutsScreen. Clear entry point.
- [RESOLVED] Template preview "Start Workout" button: persistent bottomNavigationBar, always visible.
- [RESOLVED] Template modification before starting: swipe-to-remove implemented.
- [RESOLVED] Exercise picker as modal, not route: DraggableScrollableSheet via showModalBottomSheet. Correct.
- [RESOLVED] Muscle diagram interactive taps: diagram is display-only; filtering done via FilterChip bar.
- [RESOLVED] Dark mode muscle diagram: uses ColorScheme tokens throughout.
- [RESOLVED] Settings CloseButton: CloseButton added as leading in AppBar.
- [RESOLVED] Difficulty badges include text label: text + color used together.

### New issues found in implementation

#### CRITICAL
1. workout_detail_screen.dart line 82-89: FutureBuilder used for _loadExercises inside a ConsumerWidget; the error branch at line 82 shows `Text('Could not load exercises.')` with no retry — plain text error, no ErrorCard, no haptic, user is stuck. The null-workout branch at line 58-59 also uses plain `Text('Workout not found.')` which is a dead-end.
2. food_entry_tile.dart Dismissible: swipe-to-delete fires onDelete immediately with no confirmation and no undo snackbar. This is a destructive action on user-logged food data. Data loss with zero recovery path.
3. template_preview_screen.dart swipe-to-remove: same issue — Dismissible fires _removeExercise immediately with no undo. User can remove all exercises accidentally during normal scrolling gestures.
4. workout_detail_screen.dart line 82-89: FutureBuilder inside workoutAsync.when(data: ...) with no haptic on delete confirm button (line 262 in _confirmDelete).

#### MAJOR  
5. nutrition_screen.dart line 90-92: MicronutrientSection only renders `if (micros.isNotEmpty)`. If all foods lack micro data (very common with Open Food Facts), the section never appears — user has no indication micro tracking exists or how to access it. Should show collapsed section with "Log packaged foods to track micronutrients" message.
6. complete_day_button.dart line 26: error branch returns `SizedBox.shrink()` — silent error swallow. If todayCompletedDayProvider fails, the button disappears with no explanation. Recurs the anti-pattern.
7. exercise_picker_sheet.dart line 215-229: empty state shows `Text('No exercises found.')` with no call-to-action. The "Add custom" tile only appears when there's a search query (showCustom). When a filter chip is selected and no exercises match, users see a dead-end with no path forward. Should add "Try a different filter or type a name to add a custom exercise."
8. workout_detail_screen.dart _confirmDelete: no HapticFeedback.heavyImpact() before the delete action executes (only mediumImpact on Start Workout, no haptic at all in delete confirm). This is a destructive action.
9. template_picker_sheet.dart: no empty state when a category filter returns zero templates. _filtered can be empty; the ListView.builder simply renders nothing.
10. nutrition_screen.dart line 117: `const CompleteDayButton()` wrapped in `const Padding` — the `const` keyword on `Padding` prevents it from seeing the inner child widget state changes correctly. Minor but worth noting.

#### MINOR
11. food_entry_tile.dart _MacroTag: labels 'P', 'C', 'F' are color-coded by macro but have no semanticLabel. Screen readers announce "P 23g" without context — should be "Protein 23g". Recurs the color-only macro anti-pattern from recurring_patterns.md.
12. meal_section.dart line 62-63: protein subtotal label is '${_totalProtein.toInt()}g P' — "P" is not accessible. Should be '${_totalProtein.toInt()}g protein' or have a Semantics label.
13. exercise_picker_card.dart line 26-86: InkWell wraps the entire card content. The onTap is correctly placed on InkWell. However there is no Semantics wrapper and no tooltip, so screen readers announce just the exercise name without muscle group or difficulty context.
14. muscle_group_diagram.dart: Semantics label is constructed correctly at line 27-32. Good.
15. food_search_screen.dart line 271-330: _FoodResultTile ListTile has no haptic in onTap (line 327). Consistent with recurring anti-pattern.
16. template_picker_sheet.dart TemplateCard InkWell: haptic is called in _TemplatePickerContentState.onTap (line 118) — good. But it fires HapticFeedback.lightImpact() on what is a navigation action to a preview screen; correct.
17. settings_screen.dart line 99-105: "Reset All Data" ListTile has no trailing icon to indicate it's tappable (only Icons.delete_forever as leading). No visual affordance that this opens a confirmation dialog. Should add chevron_right or similar.
18. workout_detail_screen.dart line 63: date formatted as `${date.day}/${date.month}/${date.year}` — no zero-padding (e.g., "5/4/2026" instead of "05/04/2026"). Ambiguous day/month ordering for international users.
19. micronutrient_section.dart: ExpansionTile has no haptic feedback on expand/collapse.
20. nutrition_screen.dart const Padding issue (line 116-119): `const Padding` with a non-const child `CompleteDayButton()` — this is a compile warning in strict mode; remove `const` from Padding.

## Decisions That Were Correct vs Pre-Implementation Concerns

- MicronutrientSection collapsing by default: implemented correctly with ExpansionTile.
- Shimmer loading for nutrition screen: implemented correctly (lines 25-48 of nutrition_screen.dart).
- Complete Day as reversible action: implemented correctly with Unlock dialog.
- Template category filters: filter chip bar implemented — but no empty state when chips filter to zero.
- Muscle diagram as display-only: correct decision preserved.
- ExercisePickerSheet multi-muscle group filtering: partially broken — multi-muscle groups pass null to provider and do local filtering (lines 94-101), which is documented as a known limitation in comments. Not a UX bug per se, but filtering "Legs" shows all exercises matching quads/hamstrings/glutes/calves which may include more exercises than expected.
