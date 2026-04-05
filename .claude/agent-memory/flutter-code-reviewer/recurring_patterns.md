---
name: Recurring Code Patterns
description: Anti-patterns and good patterns observed in the codebase during review sessions
type: reference
---

## Known Anti-Patterns to Flag

**1. Unsafe dynamic cast in workout detail screen**
`exercise.name as String` in `WorkoutDetailScreen._loadExercises()` — the field is already
typed as `String` in the Isar model, so the cast is redundant but still dangerous if the
schema ever changes. Line 240 of `workout_detail_screen.dart`.

**2. FutureBuilder inside a ConsumerWidget build method**
`WorkoutDetailScreen` uses `FutureBuilder` to load Isar links. This is not idiomatic Riverpod
and will re-trigger on every parent rebuild. Prefer a `FutureProvider.family` or move link
loading into the existing `workoutByIdProvider`.

**3. `saveWorkout()` — exercise link saved before exercise added to workout**
In `workouts_controller.dart` saveWorkout(), `workout.exercises.save()` is called before
`workout.exercises.add(exercise)`, meaning the first save is a no-op. Sets are also saved
before being added to `exercise.sets`. The data is saved correctly on the second `.save()`
call but the structure is confusing and fragile.

**4. Multi-muscle filter group uses provider null + local re-filter**
`ExercisePickerSheet._onGroupSelected()` sets muscle to null for multi-muscle groups (Back,
Legs, Arms, Core) and then re-filters the provider result locally in `build()`. This works
but is architecturally awkward — the `ExerciseFilterState` only holds one `MuscleGroup?`.
If the filter ever needs to support multi-select natively, the state class must be extended.

**5. `shouldRepaint` on `_BodyDiagramPainter` uses list identity, not equality**
`oldDelegate.primaryMuscles != primaryMuscles` compares list references, not contents.
A new `List<MuscleGroup>` with the same elements will always trigger a repaint.

**6. `micros.isNotEmpty` hides the section even when all values are 0**
`todayMicronutrientsProvider` always returns a full map with 10 keys (all initialised to 0).
`micros.isNotEmpty` is always true, so the condition never hides the section. The guard
should be `micros.values.any((v) => v > 0)` to match the user-visible meaning.

**7. `_primaryMuscles` and `_secondaryMuscles` getters in TemplatePreviewScreen**
Both are non-cached getters that iterate the full exercise library O(N×M) on every access.
`_secondaryMuscles` additionally calls `_primaryMuscles` internally, doubling the work.
Computed in `build()` and used in two places — should be computed once in a local variable.

## Good Patterns (Keep Doing)

- `ref.invalidate(provider)` after every mutation — consistently done in all providers.
- `try/catch` wrapping all `isar.writeTxn()` calls — consistent throughout.
- `context.mounted` checks after every async gap before using `context` — well done.
- Timer (`_elapsedTimer`, `_restTimer`, `_debounce`) cancelled in `dispose()` — no leaks.
- `TextEditingController` and `TabController` disposed in every `StatefulWidget` — clean.
- Dual food search (local instant + remote async) with graceful degradation on network error.
- `AsyncValue.when(data:, loading:, error:)` fully handled in all provider consumers.
- No hardcoded colours — all use `Theme.of(context).colorScheme.*`.
- No sensitive data printed to console.
- No hardcoded API keys found.
