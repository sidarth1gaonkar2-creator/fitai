import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../core/utils/logger.dart';
import '../features/community/data/leaderboard_repository.dart';
import '../features/community/domain/leaderboard_entry.dart';
import '../models/enums.dart';
import '../models/personal_record.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';

/// Result returned from [seedWorkoutHistory] for the settings confirmation
/// dialog.
class SeedWorkoutsResult {
  const SeedWorkoutsResult({
    required this.workouts,
    required this.prs,
    required this.totalSets,
  });
  final int workouts;
  final int prs;
  final int totalSets;
}

/// Stamp written to [Workout.notes] so re-runs can wipe their previous
/// output instead of stacking duplicate workouts. Picked to be obviously
/// not user-typed.
const _seedMarker = '[seeded:workout-history]';

/// Pounds → kilograms (matches `UnitConverter.lbsToKg`).
double _lbsToKg(double lbs) => lbs / 2.20462;

/// Single exercise definition for a session — name + 4 sets at one weight
/// in pounds (we convert to kg at write time since storage is canonical
/// kg). Each session uses the same weight across all sets per the spec:
/// "Bench: 185→205 lbs (4×8)" describes progression *across sessions*.
class _ExerciseEntry {
  const _ExerciseEntry({
    required this.name,
    required this.weightLbs,
    required this.sets,
    required this.reps,
    required this.muscle,
  });
  final String name;
  final double weightLbs;
  final int sets;
  final int reps;
  final MuscleGroup muscle;
}

class _Session {
  const _Session({
    required this.title,
    required this.daysAgo,
    required this.durationMin,
    required this.exercises,
  });
  final String title;
  final int daysAgo;
  final int durationMin;
  final List<_ExerciseEntry> exercises;
}

/// 12 sessions in a Push / Pull / Legs rotation over the trailing 30 days.
/// Weights ramp across the 4 sessions per category so the strength chart
/// has a visible upward trend and the final session is the PR.
List<_Session> _buildSessions() {
  // PUSH — 4 sessions ramping bench 185 → 205 lbs.
  final pushWeights = [
    {'bench': 185.0, 'incline': 55.0, 'lateral': 20.0, 'tri': 50.0},
    {'bench': 190.0, 'incline': 58.0, 'lateral': 22.0, 'tri': 53.0},
    {'bench': 195.0, 'incline': 60.0, 'lateral': 22.0, 'tri': 55.0},
    {'bench': 205.0, 'incline': 65.0, 'lateral': 25.0, 'tri': 60.0},
  ];
  final pushDays = [29, 22, 14, 7];

  final pullWeights = [
    {'row': 135.0, 'lat': 120.0, 'curl': 65.0, 'face': 40.0},
    {'row': 145.0, 'lat': 125.0, 'curl': 68.0, 'face': 43.0},
    {'row': 155.0, 'lat': 130.0, 'curl': 72.0, 'face': 47.0},
    {'row': 165.0, 'lat': 140.0, 'curl': 75.0, 'face': 50.0},
  ];
  final pullDays = [27, 19, 12, 5];

  final legWeights = [
    {'squat': 225.0, 'rdl': 155.0, 'press': 270.0, 'calf': 135.0},
    {'squat': 245.0, 'rdl': 165.0, 'press': 290.0, 'calf': 145.0},
    {'squat': 260.0, 'rdl': 175.0, 'press': 305.0, 'calf': 150.0},
    {'squat': 275.0, 'rdl': 185.0, 'press': 320.0, 'calf': 155.0},
  ];
  final legDays = [24, 17, 9, 2];

  final sessions = <_Session>[];

  for (var i = 0; i < 4; i++) {
    final w = pushWeights[i];
    sessions.add(_Session(
      title: 'Push Day',
      daysAgo: pushDays[i],
      durationMin: 45 + (i * 3),
      exercises: [
        _ExerciseEntry(
          name: 'Barbell Bench Press',
          weightLbs: w['bench']!,
          sets: 4,
          reps: 8,
          muscle: MuscleGroup.chest,
        ),
        _ExerciseEntry(
          name: 'Incline Dumbbell Press',
          weightLbs: w['incline']!,
          sets: 3,
          reps: 10,
          muscle: MuscleGroup.chest,
        ),
        _ExerciseEntry(
          name: 'Dumbbell Lateral Raise',
          weightLbs: w['lateral']!,
          sets: 3,
          reps: 12,
          muscle: MuscleGroup.shoulders,
        ),
        _ExerciseEntry(
          name: 'Tricep Pushdown',
          weightLbs: w['tri']!,
          sets: 3,
          reps: 12,
          muscle: MuscleGroup.triceps,
        ),
      ],
    ));
  }

  for (var i = 0; i < 4; i++) {
    final w = pullWeights[i];
    sessions.add(_Session(
      title: 'Pull Day',
      daysAgo: pullDays[i],
      durationMin: 50 + (i * 2),
      exercises: [
        _ExerciseEntry(
          name: 'Barbell Bent Over Row',
          weightLbs: w['row']!,
          sets: 4,
          reps: 8,
          muscle: MuscleGroup.upperBack,
        ),
        _ExerciseEntry(
          name: 'Lat Pulldown',
          weightLbs: w['lat']!,
          sets: 3,
          reps: 10,
          muscle: MuscleGroup.lats,
        ),
        _ExerciseEntry(
          name: 'Barbell Curl',
          weightLbs: w['curl']!,
          sets: 3,
          reps: 10,
          muscle: MuscleGroup.biceps,
        ),
        _ExerciseEntry(
          name: 'Face Pulls',
          weightLbs: w['face']!,
          sets: 3,
          reps: 15,
          muscle: MuscleGroup.shoulders,
        ),
      ],
    ));
  }

  for (var i = 0; i < 4; i++) {
    final w = legWeights[i];
    sessions.add(_Session(
      title: 'Legs Day',
      daysAgo: legDays[i],
      durationMin: 55 + (i * 2),
      exercises: [
        _ExerciseEntry(
          name: 'Barbell Back Squat',
          weightLbs: w['squat']!,
          sets: 4,
          reps: 5,
          muscle: MuscleGroup.quads,
        ),
        _ExerciseEntry(
          name: 'Romanian Deadlift',
          weightLbs: w['rdl']!,
          sets: 3,
          reps: 10,
          muscle: MuscleGroup.hamstrings,
        ),
        _ExerciseEntry(
          name: 'Leg Press',
          weightLbs: w['press']!,
          sets: 3,
          reps: 12,
          muscle: MuscleGroup.quads,
        ),
        _ExerciseEntry(
          name: 'Calf Raise',
          weightLbs: w['calf']!,
          sets: 4,
          reps: 15,
          muscle: MuscleGroup.calves,
        ),
      ],
    ));
  }

  // Sort oldest-first so the strength chart's x-axis reads naturally.
  sessions.sort((a, b) => b.daysAgo.compareTo(a.daysAgo));
  return sessions;
}

/// Writes 12 PPL workouts + PRs to the current user's Isar database and
/// best-effort syncs the aggregates (workoutsCount + leaderboard entry) to
/// Firestore.
///
/// Idempotent: any prior workouts whose notes contain [_seedMarker] are
/// wiped before the new batch is written, so re-running this from the
/// Settings → Developer tile replaces the seed in place rather than
/// stacking up another twelve sessions every tap.
Future<SeedWorkoutsResult> seedWorkoutHistory({
  required Isar isar,
  required FirebaseFirestore firestore,
  required String? currentUserId,
  required String? currentUsername,
  required LeaderboardRepository leaderboardRepository,
}) async {
  final sessions = _buildSessions();
  final now = DateTime.now();

  // 1. Wipe prior seeded workouts (idempotency).
  await isar.writeTxn(() async {
    final prior = await isar.workouts
        .filter()
        .notesEqualTo(_seedMarker)
        .findAll();
    for (final w in prior) {
      await w.exercises.load();
      for (final ex in w.exercises) {
        await ex.sets.load();
        for (final s in ex.sets) {
          await isar.workoutSets.delete(s.id);
        }
        await isar.workoutExercises.delete(ex.id);
      }
      await isar.workouts.delete(w.id);
    }
  });

  // 2. Write each session. Reuse a single writeTxn so we either get every
  //    session or none — partial seeds are confusing to look at.
  var totalSets = 0;
  await isar.writeTxn(() async {
    for (final session in sessions) {
      final workoutDate = now.subtract(Duration(days: session.daysAgo));

      final workout = Workout()
        ..title = session.title
        ..date = workoutDate
        ..durationMinutes = session.durationMin
        ..notes = _seedMarker;
      await isar.workouts.put(workout);

      for (var exIdx = 0; exIdx < session.exercises.length; exIdx++) {
        final entry = session.exercises[exIdx];
        final weightKg = _lbsToKg(entry.weightLbs);

        final exercise = WorkoutExercise()
          ..name = entry.name
          ..order = exIdx;
        await isar.workoutExercises.put(exercise);

        for (var setIdx = 0; setIdx < entry.sets; setIdx++) {
          final set = WorkoutSet()
            ..reps = entry.reps
            ..weight = weightKg
            ..isCompleted = true
            ..order = setIdx
            ..exerciseName = entry.name;
          await isar.workoutSets.put(set);
          exercise.sets.add(set);
          totalSets++;
        }
        await exercise.sets.save();

        workout.exercises.add(exercise);
      }
      await workout.exercises.save();
    }
  });

  // 3. PRs — find the heaviest set per exercise across the seed and write
  //    or upgrade the PersonalRecord row. We never downgrade a row the
  //    user might already have set higher manually; only overwrite when
  //    our seed peak exceeds the existing record.
  final peakByExercise = <String, ({double weightKg, int reps, MuscleGroup muscle})>{};
  for (final s in sessions) {
    for (final e in s.exercises) {
      final kg = _lbsToKg(e.weightLbs);
      final prior = peakByExercise[e.name];
      if (prior == null || kg > prior.weightKg) {
        peakByExercise[e.name] = (
          weightKg: kg,
          reps: e.reps,
          muscle: e.muscle,
        );
      }
    }
  }

  var prsWritten = 0;
  for (final entry in peakByExercise.entries) {
    await isar.writeTxn(() async {
      final existingList = await isar.personalRecords
          .where()
          .exerciseNameEqualTo(entry.key)
          .findAll();
      final existing =
          existingList.isNotEmpty ? existingList.first : null;

      if (existing != null && existing.weightKg >= entry.value.weightKg) {
        return; // user's manually-set PR wins
      }

      if (existing != null) {
        existing
          ..weightKg = entry.value.weightKg
          ..bestReps = entry.value.reps
          ..dateAchieved = now
          ..muscleGroup = entry.value.muscle;
        await isar.personalRecords.put(existing);
      } else {
        final pr = PersonalRecord()
          ..exerciseName = entry.key
          ..weightKg = entry.value.weightKg
          ..bestReps = entry.value.reps
          ..dateAchieved = now
          ..muscleGroup = entry.value.muscle;
        await isar.personalRecords.put(pr);
      }
      prsWritten++;
    });
  }

  // 4. Best-effort Firestore sync. Mirrors what the real finish flow
  //    does (`incrementWorkoutCount` + leaderboard entry update), but we
  //    SET the workout count from the live Isar total so re-running the
  //    seed doesn't drift the counter upward by 12 every time. Wrapped
  //    in try/catch so a rule denial or offline mode doesn't fail the
  //    whole seed — the local data is what powers the charts anyway.
  if (currentUserId != null) {
    try {
      final allWorkouts = await isar.workouts.where().findAll();
      final totalWorkouts = allWorkouts.length;

      double totalVolume = 0;
      for (final w in allWorkouts) {
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

      await firestore.collection('users').doc(currentUserId).update({
        'workoutsCount': totalWorkouts,
      });

      await leaderboardRepository.updateEntry(
        LeaderboardEntry(
          userId: currentUserId,
          username: currentUsername ?? 'You',
          currentStreak: 0,
          totalWorkouts: totalWorkouts,
          totalVolume: totalVolume,
        ),
      );
    } catch (e, st) {
      // Local seed already landed; surface this in the log but don't
      // fail the call — the user can still see the workouts in the
      // local-only Progress screen.
      debugPrint('[SeedWorkouts] Firestore sync skipped: $e');
      AppLogger.error(
        'Workout-history seeder: Firestore sync failed',
        error: e,
        stack: st,
      );
    }
  }

  return SeedWorkoutsResult(
    workouts: sessions.length,
    prs: prsWritten,
    totalSets: totalSets,
  );
}
