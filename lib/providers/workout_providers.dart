import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../data/exercise_library.dart';
import '../models/enums.dart';
import '../models/personal_record.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import 'isar_provider.dart';

/// All workouts sorted by date descending.
final allWorkoutsProvider = FutureProvider<List<Workout>>((ref) async {
  final isar = ref.watch(isarProvider);
  return isar.workouts.where().sortByDateDesc().findAll();
});

/// Workouts for a specific date (day granularity).
final workoutsByDateProvider =
    FutureProvider.family<List<Workout>, DateTime>((ref, date) async {
  final isar = ref.watch(isarProvider);
  final start = DateTime(date.year, date.month, date.day);
  final end = start.add(const Duration(days: 1));
  return isar.workouts
      .filter()
      .dateBetween(start, end, includeUpper: false)
      .findAll();
});

/// Set of dates (normalised to midnight) that have at least one workout.
final workoutDatesProvider = FutureProvider<Set<DateTime>>((ref) async {
  final workouts = await ref.watch(allWorkoutsProvider.future);
  return workouts
      .map((w) => DateTime(w.date.year, w.date.month, w.date.day))
      .toSet();
});

/// Single workout by ID.
final workoutByIdProvider =
    FutureProvider.family<Workout?, int>((ref, id) async {
  final isar = ref.watch(isarProvider);
  return isar.workouts.get(id);
});

/// Loaded exercises (with sets) for a workout id, sorted by `order`.
/// Returns a list of (exerciseName, sets) records so the UI never has to
/// touch IsarLinks during rebuilds.
final workoutExercisesProvider = FutureProvider.family<
    List<({String name, List<({int reps, double weight})> sets})>,
    int>((ref, id) async {
  final isar = ref.watch(isarProvider);
  final workout = await isar.workouts.get(id);
  if (workout == null) return const [];
  await workout.exercises.load();
  final exercises = workout.exercises.toList()
    ..sort((a, b) => a.order.compareTo(b.order));
  final result =
      <({String name, List<({int reps, double weight})> sets})>[];
  for (final exercise in exercises) {
    await exercise.sets.load();
    final sets = exercise.sets.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    result.add((
      name: exercise.name,
      sets: sets
          .map((s) => (reps: s.reps, weight: s.weight))
          .toList(),
    ));
  }
  return result;
});

/// Most recent WorkoutSet for an exercise name.
/// Used to pre-fill weight/reps hints when logging.
final lastSetForExerciseProvider =
    FutureProvider.family<WorkoutSet?, String>((ref, exerciseName) async {
  final isar = ref.watch(isarProvider);
  dev.log('[lastSet] Looking up "$exerciseName"');

  // Fast path: query denormalised exerciseName on WorkoutSet (new data).
  final indexed = await isar.workoutSets
      .where()
      .exerciseNameEqualTo(exerciseName)
      .findAll();
  dev.log('[lastSet] Fast path found ${indexed.length} sets for "$exerciseName"');
  if (indexed.isNotEmpty) {
    indexed.sort((a, b) => b.id.compareTo(a.id));
    final s = indexed.first;
    dev.log('[lastSet] Fast path result: reps=${s.reps}, weight=${s.weight}');
    return s;
  }

  // Fallback: traverse WorkoutExercise links (pre-existing data)
  final exercises = await isar.workoutExercises
      .filter()
      .nameEqualTo(exerciseName)
      .findAll();
  dev.log('[lastSet] Fallback found ${exercises.length} exercises for "$exerciseName"');
  WorkoutSet? best;
  for (final ex in exercises) {
    await ex.sets.load();
    dev.log('[lastSet] Exercise "${ex.name}" has ${ex.sets.length} sets');
    for (final s in ex.sets) {
      if (best == null || s.id > best.id) best = s;
    }
  }
  if (best != null) {
    dev.log('[lastSet] Fallback result: reps=${best.reps}, weight=${best.weight}');
  } else {
    dev.log('[lastSet] No previous data found for "$exerciseName"');
  }
  return best;
});

/// Map of exercise name (lowercased) → best weight ever lifted.
/// Reads from the PersonalRecord Isar collection.
final personalRecordsProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final isar = ref.watch(isarProvider);
  final prs = await isar.personalRecords.where().findAll();
  final records = <String, double>{};
  for (final pr in prs) {
    records[pr.exerciseName.toLowerCase()] = pr.weightKg;
  }
  return records;
});

/// Deletes a workout and all its linked exercises/sets.
Future<bool> deleteWorkoutById(WidgetRef ref, int id) async {
  final isar = ref.read(isarProvider);
  try {
    await isar.writeTxn(() async {
      final workout = await isar.workouts.get(id);
      if (workout == null) return;
      await workout.exercises.load();
      for (final exercise in workout.exercises) {
        await exercise.sets.load();
        for (final s in exercise.sets) {
          await isar.workoutSets.delete(s.id);
        }
        await isar.workoutExercises.delete(exercise.id);
      }
      await isar.workouts.delete(id);
    });
    ref.invalidate(allWorkoutsProvider);
    ref.invalidate(workoutDatesProvider);
    ref.invalidate(personalRecordsProvider);
    return true;
  } catch (_) {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Exercise library filter
// ---------------------------------------------------------------------------

class ExerciseFilterState {
  const ExerciseFilterState({
    this.query = '',
    this.muscleGroup,
  });

  final String query;
  final MuscleGroup? muscleGroup;

  ExerciseFilterState copyWith({
    String? query,
    MuscleGroup? Function()? muscleGroup,
  }) {
    return ExerciseFilterState(
      query: query ?? this.query,
      muscleGroup:
          muscleGroup != null ? muscleGroup() : this.muscleGroup,
    );
  }
}

class ExerciseFilterNotifier extends StateNotifier<ExerciseFilterState> {
  ExerciseFilterNotifier() : super(const ExerciseFilterState());

  void setQuery(String q) => state = state.copyWith(query: q);
  void setMuscleGroup(MuscleGroup? m) =>
      state = state.copyWith(muscleGroup: () => m);
  void reset() => state = const ExerciseFilterState();
}

final exerciseFilterProvider = StateNotifierProvider.autoDispose<
    ExerciseFilterNotifier, ExerciseFilterState>(
  (ref) => ExerciseFilterNotifier(),
);

final filteredExercisesProvider =
    Provider.autoDispose<List<ExerciseDefinition>>((ref) {
  final filter = ref.watch(exerciseFilterProvider);
  return filterExercises(
    query: filter.query,
    muscleGroup: filter.muscleGroup,
  );
});
