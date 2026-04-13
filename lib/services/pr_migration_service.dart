import 'package:isar/isar.dart';
import '../data/exercise_library.dart';
import '../models/enums.dart';
import '../models/personal_record.dart';
import '../models/workout_exercise.dart';

class PRMigrationService {
  /// One-time migration: scans all existing WorkoutExercises/Sets and
  /// populates the PersonalRecord collection.
  static Future<void> migrate(Isar isar) async {
    final existing = await isar.personalRecords.count();
    if (existing > 0) return; // already migrated

    final exercises = await isar.workoutExercises.where().findAll();
    // exerciseName -> best record data
    final best = <String, _PRData>{};

    for (final exercise in exercises) {
      await exercise.sets.load();
      final muscle = _muscleGroupFor(exercise.name);
      for (final set in exercise.sets) {
        final key = exercise.name.toLowerCase();
        final current = best[key];
        if (current == null || set.weight > current.weight) {
          best[key] = _PRData(
            exerciseName: exercise.name,
            weight: set.weight,
            reps: set.reps,
            muscleGroup: muscle,
          );
        }
      }
    }

    if (best.isEmpty) return;

    await isar.writeTxn(() async {
      for (final entry in best.values) {
        if (entry.weight <= 0) continue;
        final pr = PersonalRecord()
          ..exerciseName = entry.exerciseName
          ..weightKg = entry.weight
          ..bestReps = entry.reps
          ..dateAchieved = DateTime.now()
          ..muscleGroup = entry.muscleGroup;
        await isar.personalRecords.put(pr);
      }
    });
  }

  static MuscleGroup _muscleGroupFor(String exerciseName) {
    final def = exerciseLibrary
        .where((e) => e.name.toLowerCase() == exerciseName.toLowerCase())
        .firstOrNull;
    return def?.primaryMuscles.firstOrNull ?? MuscleGroup.chest;
  }
}

class _PRData {
  _PRData({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.muscleGroup,
  });

  final String exerciseName;
  final double weight;
  final int reps;
  final MuscleGroup muscleGroup;
}
