---
name: Phase 5 UI Widgets — Nutrition + Workout Redesign
description: All widgets built in Phase 5, their file paths, key design decisions, and integration points
type: project
---

Phase 5 (UI widgets) implemented 2026-04-05. All widgets complete.

**Why:** Cronometer-style nutrition redesign + exercise picker overhaul + muscle diagram + workout templates.

**How to apply:** Reference these patterns and paths for future feature work.

## New files created

| File | Widget(s) |
|------|-----------|
| `lib/core/widgets/muscle_group_diagram.dart` | `MuscleGroupDiagram` — CustomPainter, display-only, front+back silhouettes |
| `lib/features/nutrition/presentation/widgets/micronutrient_section.dart` | `MicronutrientSection` — ExpansionTile, 10 nutrients, inverted sodium logic |
| `lib/features/nutrition/presentation/widgets/complete_day_button.dart` | `CompleteDayButton` — ConsumerWidget, locked banner with trophy |
| `lib/features/workouts/presentation/exercise_picker_sheet.dart` | `ExercisePickerSheet`, `showExercisePickerSheet()` — SearchBar + FilterChips + 106 exercises |
| `lib/features/workouts/presentation/widgets/exercise_picker_card.dart` | `ExercisePickerCard` — muscle icon, difficulty badge, equipment tag |
| `lib/features/workouts/presentation/template_picker_sheet.dart` | `TemplatePickerContent`, `TemplateCard`, `showTemplatePickerSheet()` |
| `lib/features/workouts/presentation/template_preview_screen.dart` | `TemplatePreviewScreen` — ConsumerStatefulWidget, swipe-to-remove, loadFromTemplate |

## Modified files

| File | Change |
|------|--------|
| `lib/features/nutrition/presentation/widgets/daily_summary_header.dart` | Renamed class → `NutritionSummaryCard`; now CalorieRing (120×120) + 3 `_MacroProgressBar` widgets |
| `lib/features/nutrition/presentation/widgets/meal_section.dart` | Added protein subtotal, `isLocked` param |
| `lib/features/nutrition/presentation/widgets/food_entry_tile.dart` | Replaced subtitle text with `_MacroTag` chips (P/C/F) + `_ServingTag` |
| `lib/features/nutrition/presentation/nutrition_screen.dart` | Uses `NutritionSummaryCard`, `MicronutrientSection`, `CompleteDayButton` in bottomNavigationBar |
| `lib/features/nutrition/presentation/food_search_screen.dart` | Dual-source: local instant + remote shimmer; `CustomScrollView` with section headers |
| `lib/features/workouts/presentation/workout_logging_screen.dart` | `_showAddExerciseSheet` now calls `showExercisePickerSheet()` |
| `lib/features/workouts/presentation/workout_detail_screen.dart` | Added `MuscleGroupDiagram` after info row, aggregated from `exerciseLibrary` |
| `lib/features/workouts/presentation/workouts_screen.dart` | Added `TabBar` (History / Templates); `WorkoutsScreen` is now `ConsumerStatefulWidget` |

## Key design patterns established

- **Macro colour coding**: Uses `AppColors.of(context).accent` (iOS blue) for primary, `AppColors.of(context).destructive` for over-budget. Legacy code may still reference `AppColors.purple`/`purpleLight`/`lime` — these map to blue/light-blue/white, NOT their namesake colors.
- **MuscleGroupDiagram**: Non-interactive. Normalised 0-1 coords scaled to canvas.
- **ExercisePickerSheet**: Multi-muscle filter groups mapped locally (Legs = quads+hamstrings+glutes+calves). Provider only supports single MuscleGroup; multi-group filtering is done locally after provider query.
- **TemplatePreviewScreen**: Calls `loadFromTemplate()` on `activeWorkoutProvider.notifier` then `context.go('/workouts/new')`.
- **CompleteDayButton**: `completeDay(ref)` / `uncompleteDay(ref)` are top-level functions in `nutrition_providers.dart`.
- **isLocked on MealSection / FoodEntryTile**: Passed from `todayCompletedDayProvider != null`.
