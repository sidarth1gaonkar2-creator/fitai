import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/workout.dart';
import '../../../models/workout_exercise.dart';
import '../../../models/workout_set.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/isar_provider.dart';
import '../../../providers/workout_providers.dart';
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

  void addExercise(String name) {
    final exercise = ActiveExercise(
      name: name,
      order: state.exercises.length,
      sets: const [ActiveSet(order: 0)],
    );
    state = state.copyWith(exercises: [...state.exercises, exercise]);
  }

  void removeExercise(int index) {
    final updated = List<ActiveExercise>.from(state.exercises)..removeAt(index);
    state = state.copyWith(exercises: updated);
  }

  void addSet(int exerciseIndex) {
    final exercises = List<ActiveExercise>.from(state.exercises);
    final exercise = exercises[exerciseIndex];
    final newSet = ActiveSet(order: exercise.sets.length);
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
    final records = await _ref.read(personalRecordsProvider.future);
    final key = exerciseName.toLowerCase();
    final currentBest = records[key];
    if (currentBest == null || weight > currentBest) {
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

  void loadFromTemplate({
    required String title,
    required List<ActiveExercise> exercises,
  }) {
    state = ActiveWorkoutState(
      title: title,
      exercises: exercises,
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
              ..order = activeSet.order;
            await isar.workoutSets.put(set);
            exercise.sets.add(set);
          }
          await exercise.sets.save();

          workout.exercises.add(exercise);
        }
        await workout.exercises.save();
      });

      _ref.invalidate(allWorkoutsProvider);
      _ref.invalidate(workoutDatesProvider);
      _ref.invalidate(todayWorkoutProvider);
      _ref.invalidate(streakProvider);
      _ref.invalidate(personalRecordsProvider);

      state = state.copyWith(isSaving: false);
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
