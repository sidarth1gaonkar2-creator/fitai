---
name: Provider Conventions
description: Naming, lifecycle, and invalidation patterns for Riverpod providers
type: reference
---

## Naming Conventions
- `*Provider` suffix on all providers.
- `*Notifier` suffix on StateNotifier subclasses.
- Free async mutation functions (e.g., `addFoodEntry`, `completeDay`) live in the
  provider file alongside related providers and accept `WidgetRef` as first param.
- `activeWorkoutProvider` — StateNotifierProvider.autoDispose for the in-progress workout.
- `exerciseFilterProvider` — StateNotifierProvider.autoDispose reset on sheet open.

## autoDispose Usage
- `exerciseFilterProvider` and `filteredExercisesProvider` — autoDispose (sheet-scoped).
- `activeWorkoutProvider` — autoDispose (logging screen-scoped).
- All other providers are persistent (no autoDispose).

## Provider.family Usage
- `workoutsByDateProvider` — family<List<Workout>, DateTime>
- `workoutByIdProvider` — family<Workout?, int>
- `foodLocalSearchProvider` — family<List<FoodSearchResult>, String>
- `foodRemoteSearchProvider` — FutureProvider.family<List<FoodSearchResult>, String>
- `foodSearchProvider` — legacy, kept for barcode lookup compatibility
- `barcodeLookupProvider` — FutureProvider.family<FoodSearchResult?, String>

## Invalidation Pattern After Mutations
After every successful write, the relevant providers are explicitly invalidated:
- Nutrition mutations invalidate: `todayNutritionProvider`, `todayMealsProvider`,
  `streakProvider`, `todayMicronutrientsProvider`
- Workout saves invalidate: `allWorkoutsProvider`, `workoutDatesProvider`,
  `todayWorkoutProvider`, `streakProvider`, `personalRecordsProvider`
- Day completion invalidates: `todayCompletedDayProvider`

## `foodSearchProvider` (legacy)
Uses `ref.watch` inside a FutureProvider for the remote sub-call — this is technically
correct (the outer provider re-runs when the inner one changes) but unusual. When the
remote throws, it is caught and returns `[]`. The legacy provider should not be expanded.
