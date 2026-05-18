import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/exercisedb_exercise.dart';
import '../services/exercisedb_service.dart';

/// Process-wide service. Keep it `Provider` (not autoDispose) so the
/// in-memory cache survives across screen transitions.
final exerciseDBServiceProvider = Provider<ExerciseDBService>((ref) {
  return ExerciseDBService();
});

/// Look up ExerciseDB data for a given local exercise name. autoDispose so
/// idle screens don't pin the entry — the SharedPreferences cache makes the
/// next access cheap anyway.
final exerciseDBProvider =
    FutureProvider.family.autoDispose<ExerciseDBExercise?, String>(
        (ref, exerciseName) async {
  if (exerciseName.trim().isEmpty) return null;
  final service = ref.read(exerciseDBServiceProvider);
  return service.getExercise(exerciseName);
});
