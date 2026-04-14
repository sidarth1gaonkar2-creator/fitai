import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../data/exercise_library.dart';
import '../../../services/notification_service.dart';
import '../../../models/enums.dart';
import '../../../models/personal_record.dart';
import '../../../models/workout.dart';
import '../../../models/workout_exercise.dart';
import '../../../models/workout_set.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/isar_provider.dart';
import '../../../providers/personal_records_hall_providers.dart';
import '../../../providers/workout_providers.dart';
import '../../community/data/user_repository.dart';
import '../domain/active_workout_state.dart';

const commonExercises = [
  'Barbell Bench Press',
  'Incline Dumbbell Press',
  'Dumbbell Flyes',
  'Overhead Press',
  'Lateral Raises',
  'Front Raises',
  'Barbell Back Squat',
  'Front Squat',
  'Leg Press',
  'Leg Extension',
  'Leg Curl',
  'Romanian Deadlift',
  'Conventional Deadlift',
  'Barbell Row',
  'Pull-Up',
  'Chin-Up',
  'Lat Pulldown',
  'Seated Cable Row',
  'Face Pull',
  'Barbell Curl',
  'Dumbbell Curl',
  'Hammer Curl',
  'Tricep Pushdown',
  'Skull Crushers',
  'Overhead Tricep Extension',
  'Calf Raises',
  'Hip Thrust',
  'Plank',
  'Cable Crunch',
  'Dumbbell Shoulder Press',
];

class WorkoutsController extends StateNotifier<ActiveWorkoutState> {
  WorkoutsController(this._ref)
      : super(ActiveWorkoutState(startTime: DateTime.now()));

  final Ref _ref;
  Timer? _restTimer;

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  Future<void> addExercise(String name) async {
    dev.log('[addExercise] Looking up previous data for "$name"');
    final lastSet = await _ref.read(lastSetForExerciseProvider(name).future);
    dev.log('[addExercise] lastSet: ${lastSet != null ? 'reps=${lastSet.reps}, weight=${lastSet.weight}, exerciseName=${lastSet.exerciseName}' : 'null'}');
    final exercise = ActiveExercise(
      name: name,
      order: state.exercises.length,
      sets: [
        ActiveSet(
          order: 0,
          previousReps: lastSet?.reps,
          previousWeight: lastSet != null && lastSet.weight > 0
              ? lastSet.weight
              : null,
        ),
      ],
    );
    dev.log('[addExercise] previousReps=${exercise.sets.first.previousReps}, previousWeight=${exercise.sets.first.previousWeight}');
    state = state.copyWith(exercises: [...state.exercises, exercise]);
  }

  void removeExercise(int index) {
    final updated = List<ActiveExercise>.from(state.exercises)..removeAt(index);
    state = state.copyWith(exercises: updated);
  }

  void addSet(int exerciseIndex) {
    final exercises = List<ActiveExercise>.from(state.exercises);
    final exercise = exercises[exerciseIndex];
    final firstSet = exercise.sets.isNotEmpty ? exercise.sets.first : null;
    final newSet = ActiveSet(
      order: exercise.sets.length,
      previousReps: firstSet?.previousReps,
      previousWeight: firstSet?.previousWeight,
    );
    exercises[exerciseIndex] =
        exercise.copyWith(sets: [...exercise.sets, newSet]);
    state = state.copyWith(exercises: exercises);
  }

  void removeSet(int exerciseIndex, int setIndex) {
    final exercises = List<ActiveExercise>.from(state.exercises);
    final exercise = exercises[exerciseIndex];
    final sets = List<ActiveSet>.from(exercise.sets)..removeAt(setIndex);
    exercises[exerciseIndex] = exercise.copyWith(sets: sets);
    state = state.copyWith(exercises: exercises);
  }

  void updateSet(
    int exerciseIndex,
    int setIndex, {
    int? reps,
    double? weight,
  }) {
    final exercises = List<ActiveExercise>.from(state.exercises);
    final exercise = exercises[exerciseIndex];
    final sets = List<ActiveSet>.from(exercise.sets);
    sets[setIndex] = sets[setIndex].copyWith(reps: reps, weight: weight);
    exercises[exerciseIndex] = exercise.copyWith(sets: sets);
    state = state.copyWith(exercises: exercises);
  }

  Future<void> completeSet(int exerciseIndex, int setIndex) async {
    final exercises = List<ActiveExercise>.from(state.exercises);
    final exercise = exercises[exerciseIndex];
    final sets = List<ActiveSet>.from(exercise.sets);
    final set = sets[setIndex];
    sets[setIndex] = set.copyWith(isCompleted: !set.isCompleted);
    exercises[exerciseIndex] = exercise.copyWith(sets: sets);
    state = state.copyWith(exercises: exercises);

    // If completing (not un-completing), check for PR and start rest timer
    if (!set.isCompleted) {
      HapticFeedback.mediumImpact();
      _checkPersonalRecord(exercise.name, set.weight);
      startRestTimer();
    }
  }

  Future<void> _checkPersonalRecord(String exerciseName, double weight) async {
    if (weight <= 0) return;
    final isar = _ref.read(isarProvider);
    final existing = await isar.personalRecords
        .where()
        .exerciseNameEqualTo(exerciseName)
        .findAll();
    final currentBest = existing.isNotEmpty ? existing.first.weightKg : 0.0;
    if (weight > currentBest) {
      state = state.copyWith(prExerciseName: () => exerciseName);
      Future.delayed(const Duration(seconds: 3), dismissPR);
    }
  }

  void dismissPR() {
    if (mounted) {
      state = state.copyWith(prExerciseName: () => null);
    }
  }

  void startRestTimer({int seconds = 90}) {
    _restTimer?.cancel();
    state = state.copyWith(restTimerSeconds: () => seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = state.restTimerSeconds;
      if (current == null || current <= 1) {
        timer.cancel();
        if (mounted) {
          state = state.copyWith(restTimerSeconds: () => null);
        }
      } else {
        state = state.copyWith(restTimerSeconds: () => current - 1);
      }
    });
  }

  void adjustRestTimer(int delta) {
    final current = state.restTimerSeconds;
    if (current != null) {
      final next = (current + delta).clamp(0, 600);
      state = state.copyWith(restTimerSeconds: () => next);
    }
  }

  void skipRestTimer() {
    _restTimer?.cancel();
    state = state.copyWith(restTimerSeconds: () => null);
  }

  Future<void> loadFromTemplate({
    required String title,
    required List<ActiveExercise> exercises,
  }) async {
    // Enrich each exercise with previous set data
    final enriched = <ActiveExercise>[];
    for (final ex in exercises) {
      final lastSet =
          await _ref.read(lastSetForExerciseProvider(ex.name).future);
      dev.log('[loadFromTemplate] "${ex.name}" lastSet: ${lastSet != null ? 'reps=${lastSet.reps}, weight=${lastSet.weight}' : 'null'}');
      if (lastSet != null && (lastSet.reps > 0 || lastSet.weight > 0)) {
        final enrichedSets = ex.sets
            .map((s) => s.copyWith(
                  previousReps: () => lastSet.reps,
                  previousWeight: () =>
                      lastSet.weight > 0 ? lastSet.weight : null,
                ))
            .toList();
        enriched.add(ex.copyWith(sets: enrichedSets));
      } else {
        enriched.add(ex);
      }
    }
    state = ActiveWorkoutState(
      title: title,
      exercises: enriched,
      startTime: DateTime.now(),
    );
  }

  Future<void> loadWorkout(int id) async {
    final isar = _ref.read(isarProvider);
    final workout = await isar.workouts.get(id);
    if (workout == null) return;

    await workout.exercises.load();
    final activeExercises = <ActiveExercise>[];
    for (final exercise in workout.exercises) {
      await exercise.sets.load();
      final activeSets = exercise.sets
          .map((s) => ActiveSet(
                reps: s.reps,
                weight: s.weight,
                isCompleted: s.isCompleted,
                order: s.order,
              ))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      activeExercises.add(ActiveExercise(
        name: exercise.name,
        order: exercise.order,
        sets: activeSets,
      ));
    }
    activeExercises.sort((a, b) => a.order.compareTo(b.order));

    state = ActiveWorkoutState(
      title: workout.title,
      exercises: activeExercises,
      startTime: workout.date,
      editingWorkoutId: id,
    );
  }

  Future<bool> saveWorkout() async {
    if (state.title.trim().isEmpty || state.exercises.isEmpty) return false;

    state = state.copyWith(isSaving: true);
    final isar = _ref.read(isarProvider);

    try {
      await isar.writeTxn(() async {
        // If editing, delete old linked data first
        if (state.editingWorkoutId != null) {
          final old = await isar.workouts.get(state.editingWorkoutId!);
          if (old != null) {
            await old.exercises.load();
            for (final exercise in old.exercises) {
              await exercise.sets.load();
              for (final set in exercise.sets) {
                await isar.workoutSets.delete(set.id);
              }
              await isar.workoutExercises.delete(exercise.id);
            }
            await isar.workouts.delete(old.id);
          }
        }

        final now = DateTime.now();
        final durationMinutes =
            now.difference(state.startTime).inMinutes.clamp(1, 999);

        final workout = Workout()
          ..title = state.title.trim()
          ..date = state.editingWorkoutId != null ? state.startTime : now
          ..durationMinutes = durationMinutes;
        await isar.workouts.put(workout);

        for (final activeExercise in state.exercises) {
          final exercise = WorkoutExercise()
            ..name = activeExercise.name
            ..order = activeExercise.order;
          await isar.workoutExercises.put(exercise);

          for (final activeSet in activeExercise.sets) {
            final set = WorkoutSet()
              ..reps = activeSet.reps
              ..weight = activeSet.weight
              ..isCompleted = activeSet.isCompleted
              ..order = activeSet.order
              ..exerciseName = activeExercise.name;
            dev.log('[saveWorkout] Saving set: exerciseName="${set.exerciseName}", reps=${set.reps}, weight=${set.weight}');
            await isar.workoutSets.put(set);
            exercise.sets.add(set);
          }
          await exercise.sets.save();

          workout.exercises.add(exercise);
        }
        await workout.exercises.save();
      });

      // Detect and persist new PRs
      final newPRNames = <String>[];
      for (final activeExercise in state.exercises) {
        double bestWeight = 0;
        int bestReps = 0;
        for (final s in activeExercise.sets) {
          if (s.isCompleted && s.weight > bestWeight) {
            bestWeight = s.weight;
            bestReps = s.reps;
          }
        }
        if (bestWeight <= 0) continue;

        final existingList = await isar.personalRecords
            .where()
            .exerciseNameEqualTo(activeExercise.name)
            .findAll();
        final existing = existingList.isNotEmpty ? existingList.first : null;

        if (existing == null || bestWeight > existing.weightKg) {
          final muscle = exerciseLibrary
                  .where((e) =>
                      e.name.toLowerCase() ==
                      activeExercise.name.toLowerCase())
                  .firstOrNull
                  ?.primaryMuscles
                  .firstOrNull ??
              MuscleGroup.chest;

          await isar.writeTxn(() async {
            if (existing != null) {
              existing.weightKg = bestWeight;
              existing.bestReps = bestReps;
              existing.dateAchieved = DateTime.now();
              existing.muscleGroup = muscle;
              await isar.personalRecords.put(existing);
            } else {
              final pr = PersonalRecord()
                ..exerciseName = activeExercise.name
                ..weightKg = bestWeight
                ..bestReps = bestReps
                ..dateAchieved = DateTime.now()
                ..muscleGroup = muscle;
              await isar.personalRecords.put(pr);
            }
          });
          newPRNames.add(activeExercise.name);

          // Fire PR notification
          NotificationService.instance
              .showPRNotification(activeExercise.name, bestWeight);
        }
      }

      _ref.invalidate(allWorkoutsProvider);
      _ref.invalidate(workoutDatesProvider);
      _ref.invalidate(todayWorkoutProvider);
      _ref.invalidate(streakProvider);
      _ref.invalidate(personalRecordsProvider);
      _ref.invalidate(allPersonalRecordsProvider);

      // Sync workout count to Firestore
      final userId = _ref.read(currentUserIdProvider);
      if (userId != null) {
        _ref.read(userRepositoryProvider).incrementWorkoutCount(userId);
      }

      state = state.copyWith(isSaving: false, newPRs: newPRNames);
      return true;
    } catch (_) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  Future<bool> deleteWorkout(int id) async {
    final isar = _ref.read(isarProvider);
    try {
      await isar.writeTxn(() async {
        final workout = await isar.workouts.get(id);
        if (workout == null) return;
        await workout.exercises.load();
        for (final exercise in workout.exercises) {
          await exercise.sets.load();
          for (final set in exercise.sets) {
            await isar.workoutSets.delete(set.id);
          }
          await isar.workoutExercises.delete(exercise.id);
        }
        await isar.workouts.delete(id);
      });

      _ref.invalidate(allWorkoutsProvider);
      _ref.invalidate(workoutDatesProvider);
      _ref.invalidate(todayWorkoutProvider);
      _ref.invalidate(streakProvider);
      _ref.invalidate(personalRecordsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final activeWorkoutProvider =
    StateNotifierProvider.autoDispose<WorkoutsController, ActiveWorkoutState>(
        (ref) {
  return WorkoutsController(ref);
});
