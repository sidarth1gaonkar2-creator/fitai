import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../data/exercise_library.dart';
import '../models/enums.dart';
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

/// Map of exercise name (lowercased) → best weight ever lifted.
/// Used for personal-record detection.
final personalRecordsProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final isar = ref.watch(isarProvider);
  final exercises = await isar.workoutExercises.where().findAll();
  final records = <String, double>{};

  for (final exercise in exercises) {
    await exercise.sets.load();
    for (final set in exercise.sets) {
      final key = exercise.name.toLowerCase();
      final current = records[key];
      if (current == null || set.weight > current) {
        records[key] = set.weight;
      }
    }
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
