import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../core/utils/logger.dart';
import '../../../data/exercise_library.dart';
import '../../../services/notification_service.dart';
import '../../../models/enums.dart';
import '../../../models/personal_record.dart';
import '../../../models/workout.dart';
import '../../../models/workout_exercise.dart';
import '../../../models/workout_set.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/drill_sergeant_providers.dart';
import '../../../providers/health_providers.dart';
import '../../../providers/isar_provider.dart';
import '../../../providers/personal_records_hall_providers.dart';
import '../../themes/providers/theme_providers.dart';
import '../../../providers/unit_system_provider.dart';
import '../../../providers/workout_providers.dart';
import '../../../services/currency_service.dart';
import '../../community/data/leaderboard_repository.dart';
import '../../community/data/user_repository.dart';
import '../../community/domain/leaderboard_entry.dart';
import '../../ranks/domain/exercise_standards.dart';
import '../../ranks/domain/strength_calculator.dart';
import '../../ranks/providers/rank_providers.dart';
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
      _checkPersonalRecord(exercise.name, set.weight, set.reps);
      startRestTimer();
    }
  }

  /// Live in-workout PR check that drives the transient "PR!" badge. Compares
  /// ESTIMATED 1RM (Epley) so a higher-rep set at a slightly lower weight is
  /// still recognised. All weights here are in KG (the canonical storage unit),
  /// so the candidate and the stored best are computed and compared in KG.
  Future<void> _checkPersonalRecord(
      String exerciseName, double weight, int reps) async {
    // A set only counts once it has real data — NOT gated on the ✓ checkmark.
    if (weight <= 0 || reps <= 0) return;
    final isar = _ref.read(isarProvider);
    final existing = await isar.personalRecords
        .where()
        .exerciseNameEqualTo(exerciseName)
        .findAll();
    final candidateE1rmKg = estimatedOneRepMaxKg(weightKg: weight, reps: reps);
    final bestE1rmKg = existing.isNotEmpty
        ? estimatedOneRepMaxKg(
            weightKg: existing.first.weightKg, reps: existing.first.bestReps)
        : 0.0;
    if (candidateE1rmKg > bestE1rmKg) {
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

  Future<int?> saveWorkout() async {
    if (state.title.trim().isEmpty || state.exercises.isEmpty) return null;

    state = state.copyWith(isSaving: true);
    final isar = _ref.read(isarProvider);
    int? savedWorkoutId;

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
        savedWorkoutId = workout.id;

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

      // Detect and persist new PRs. A "PR" is now the best ESTIMATED 1RM
      // (Epley, rep-capped) ever achieved for the exercise — so heavier loads
      // OR more reps can set one. All weights are in KG (canonical storage),
      // so every e1RM below is computed and compared in KG.
      final newPRNames = <String>[];
      for (final activeExercise in state.exercises) {
        // Pick the set with the best estimated 1RM — NOT the single heaviest
        // set. A set counts as performed when it has real data (weight > 0 &&
        // reps > 0); the ✓ checkmark is a rest-timer affordance and must NOT
        // gate the ranking pipeline.
        double bestWeight = 0;
        int bestReps = 0;
        double bestE1rmKg = 0;
        for (final s in activeExercise.sets) {
          if (s.weight <= 0 || s.reps <= 0) continue;
          final e1rmKg = estimatedOneRepMaxKg(weightKg: s.weight, reps: s.reps);
          if (e1rmKg > bestE1rmKg) {
            bestE1rmKg = e1rmKg;
            bestWeight = s.weight;
            bestReps = s.reps;
          }
        }
        if (bestE1rmKg <= 0) continue;

        final existingList = await isar.personalRecords
            .where()
            .exerciseNameEqualTo(activeExercise.name)
            .findAll();
        final existing = existingList.isNotEmpty ? existingList.first : null;

        // "Best ever, never decreases": overwrite only when this session's best
        // estimated 1RM beats the stored one (both in KG). A lighter/deload day
        // leaves the record — and therefore the rank — untouched.
        final existingE1rmKg = existing == null
            ? 0.0
            : estimatedOneRepMaxKg(
                weightKg: existing.weightKg, reps: existing.bestReps);

        if (existing == null || bestE1rmKg > existingE1rmKg) {
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

          // Fire PR notification — use the aggressive Drill Sergeant
          // variant when the user has opted into that personality.
          final drill = _ref.read(drillSergeantProvider);
          if (drill.enabled) {
            NotificationService.instance.showDrillSergeantPRNotification(
              activeExercise.name,
              bestWeight,
            );
          } else {
            NotificationService.instance
                .showPRNotification(activeExercise.name, bestWeight);
          }
        }
      }

      _ref.invalidate(allWorkoutsProvider);
      _ref.invalidate(workoutDatesProvider);
      _ref.invalidate(todayWorkoutProvider);
      _ref.invalidate(streakProvider);
      _ref.invalidate(personalRecordsProvider);
      _ref.invalidate(allPersonalRecordsProvider);

      // Sync workout count + leaderboard entry to Firestore
      final userId = _ref.read(currentUserIdProvider);
      if (userId != null) {
        _ref.read(userRepositoryProvider).incrementWorkoutCount(userId);
        unawaited(_syncLeaderboardEntry(userId));
      }

      // Sync the workout to Apple Health (iOS, connected, sync-workouts on)
      unawaited(_syncWorkoutToHealth());

      // Award coins: workout + PR + streak milestones. Each is independent
      // so a workout that hits a 7-day streak AND sets a PR earns all three.
      unawaited(_awardCoinsForWorkout(prCount: newPRNames.length));

      AppLogger.log('Workout saved: "${state.title.trim()}"');
      state = state.copyWith(isSaving: false, newPRs: newPRNames);
      return savedWorkoutId;
    } catch (e, st) {
      AppLogger.error('Workout save failed', error: e, stack: st);
      state = state.copyWith(isSaving: false);
      return null;
    }
  }

  /// Awards coins for the saved workout: base reward plus per-PR bonus plus
  /// a one-time streak-milestone reward when the user just hit a 7- or 30-day
  /// streak. Streak milestone state is debounced via SharedPreferences so we
  /// don't double-pay on the same streak day.
  Future<void> _awardCoinsForWorkout({required int prCount}) async {
    final coins = _ref.read(userThemeStateProvider.notifier);
    try {
      await coins.awardCoins(CurrencyService.coinsPerWorkout);
      if (prCount > 0) {
        await coins.awardCoins(CurrencyService.coinsPerPR * prCount);
      }
      final streak = await _ref.read(streakProvider.future);
      final prefs = _ref.read(sharedPreferencesProvider);
      const k7 = 'currency_streak7_awarded';
      const k30 = 'currency_streak30_awarded';
      if (streak >= 7 && !(prefs.getBool(k7) ?? false)) {
        await coins.awardCoins(CurrencyService.coinsPerStreak7);
        await prefs.setBool(k7, true);
      }
      if (streak >= 30 && !(prefs.getBool(k30) ?? false)) {
        await coins.awardCoins(CurrencyService.coinsPerStreak30);
        await prefs.setBool(k30, true);
      }
    } catch (e, st) {
      AppLogger.error('Coin award failed', error: e, stack: st);
    }
  }

  /// Writes the most recently saved workout to Apple Health if the user is on
  /// iOS, has connected Apple Health, and has the Sync Workouts toggle on.
  /// Estimated calories: total completed-set volume × 0.05, clamped to
  /// [50, 1500] so degenerate inputs don't produce silly values.
  Future<void> _syncWorkoutToHealth() async {
    if (!_ref.read(healthConnectedProvider)) return;
    if (!_ref.read(healthPrefsProvider).syncWorkouts) return;

    final end = DateTime.now();
    final start = state.startTime;
    double volume = 0;
    for (final ex in state.exercises) {
      for (final s in ex.sets) {
        if (s.isCompleted) volume += s.weight * s.reps;
      }
    }
    final estCalories = (volume * 0.05).clamp(50.0, 1500.0).toDouble();

    try {
      final service = _ref.read(healthServiceProvider);
      await service.writeWorkout(
        start: start,
        end: end,
        caloriesBurned: estCalories,
        workoutType: 'strength',
      );
    } catch (e, st) {
      AppLogger.error('Apple Health workout sync failed', error: e, stack: st);
    }
  }

  Future<void> _syncLeaderboardEntry(String userId) async {
    try {
      final isar = _ref.read(isarProvider);
      final workouts = await isar.workouts.where().findAll();
      final totalWorkouts = workouts.length;

      double totalVolume = 0;
      for (final w in workouts) {
        await w.exercises.load();
        for (final ex in w.exercises) {
          await ex.sets.load();
          for (final s in ex.sets) {
            if (s.isCompleted) {
              totalVolume += s.weight * s.reps;
            }
          }
        }
      }

      final streak = await _ref.read(streakProvider.future);

      final user = await _ref
          .read(userRepositoryProvider)
          .getUser(userId);

      // Pull the freshly-computed ranking so the leaderboard sorts by strength
      // rank rather than raw activity. Best-effort: if it fails we still write
      // the activity stats below with zeroed scores.
      final calc = await _ref.read(rankCalculatorProvider.future);
      final groups = calc.muscleGroupPoints;
      double bestKg(String id) => calc.exerciseBestWeightKg[id] ?? 0;

      final entry = LeaderboardEntry(
        userId: userId,
        username: user?.username ?? 'User',
        avatarUrl: user?.profilePictureUrl,
        rankIndex: calc.overall.index,
        scoreOverall: calc.overallPoints,
        scoreChest: groups[RankGroup.chest] ?? 0,
        scoreBack: groups[RankGroup.back] ?? 0,
        scoreLegs: groups[RankGroup.legs] ?? 0,
        scoreShoulders: groups[RankGroup.shoulders] ?? 0,
        scoreArms: groups[RankGroup.arms] ?? 0,
        benchKg: bestKg('barbell_bench_press'),
        squatKg: bestKg('barbell_back_squat'),
        deadliftKg: bestKg('conventional_deadlift'),
        currentStreak: streak,
        totalWorkouts: totalWorkouts,
        totalVolume: totalVolume,
      );

      await _ref
          .read(leaderboardRepositoryProvider)
          .updateEntry(entry);
    } catch (e, st) {
      AppLogger.error(
        'Leaderboard entry sync failed (userId=$userId)',
        error: e,
        stack: st,
      );
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
