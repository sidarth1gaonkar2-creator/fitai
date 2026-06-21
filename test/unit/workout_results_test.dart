import 'package:flutter_test/flutter_test.dart';

import 'package:fitai/features/ranks/domain/exercise_standards.dart';
import 'package:fitai/features/ranks/domain/military_ranks.dart';
import 'package:fitai/features/ranks/providers/rank_providers.dart';
import 'package:fitai/features/workouts/domain/workout_results.dart';

/// Builds a [RankCalculation] for diffing. Only the fields the diff reads are
/// parameterised; the rest are inert defaults.
RankCalculation calc({
  MilitaryRank overall = MilitaryRank.private_e1,
  Map<RankGroup, double> groupPoints = const {},
  Map<RankGroup, MilitaryRank> groupRanks = const {},
  Map<String, int> exerciseRanks = const {},
}) {
  return RankCalculation(
    overall: overall,
    overallPoints: overall.index.toDouble(),
    muscleGroupPoints: groupPoints,
    muscleGroupRanks: groupRanks,
    exerciseScores: const {},
    exerciseRanks: exerciseRanks,
    exerciseBestWeightKg: const {},
    bodyWeightKg: 80,
  );
}

const _summary = WorkoutSummary(
  title: 'Push Day',
  duration: Duration(minutes: 42),
  sets: 12,
  exercises: 4,
  volumeKg: 4200,
);

void main() {
  group('workout results diff (PART C)', () {
    test('no PR ⇒ no fake deltas, but current badges still show', () {
      // The caller passes after == before when the session set no PR.
      final snapshot = calc(
        overall: MilitaryRank.corporal_e3,
        groupRanks: {
          RankGroup.chest: MilitaryRank.corporal_e3,
          RankGroup.back: MilitaryRank.sergeant_e5,
        },
        groupPoints: {RankGroup.chest: 2.3, RankGroup.back: 4.1},
      );

      final r = computeWorkoutResults(
        before: snapshot,
        after: snapshot,
        summary: _summary,
        sessionExerciseNames: const ['Barbell Bench Press'],
        prNames: const [],
      );

      expect(r.overallRankedUp, isFalse);
      expect(r.muscles.length, 2); // both groups still get a badge
      expect(r.muscles.every((m) => !m.rankedUp && !m.improved), isTrue);
      expect(r.exercises, isEmpty);
      expect(r.earnedAnything, isFalse);
      // Badges read the post-save (current) state.
      expect(
        r.muscles.firstWhere((m) => m.group == RankGroup.back).rank,
        MilitaryRank.sergeant_e5,
      );
    });

    test('an overall promotion is detected', () {
      final before = calc(overall: MilitaryRank.privateFc_e2);
      final after = calc(overall: MilitaryRank.corporal_e3);

      final r = computeWorkoutResults(
        before: before,
        after: after,
        summary: _summary,
        sessionExerciseNames: const [],
        prNames: const [],
      );

      expect(r.overallRankedUp, isTrue);
      expect(r.overallRank, MilitaryRank.corporal_e3);
      expect(r.earnedAnything, isTrue);
    });

    test('only the muscle group that climbed a tier is flagged ranked-up', () {
      final before = calc(
        groupRanks: {
          RankGroup.chest: MilitaryRank.corporal_e3, // index 2
          RankGroup.back: MilitaryRank.sergeant_e5, // index 4
        },
        groupPoints: {RankGroup.chest: 2.1, RankGroup.back: 4.2},
      );
      final after = calc(
        groupRanks: {
          RankGroup.chest: MilitaryRank.sergeant_e5, // 2 → 4
          RankGroup.back: MilitaryRank.sergeant_e5, // unchanged
        },
        groupPoints: {RankGroup.chest: 4.1, RankGroup.back: 4.2},
      );

      final r = computeWorkoutResults(
        before: before,
        after: after,
        summary: _summary,
        sessionExerciseNames: const [],
        prNames: const [],
      );

      final chest = r.muscles.firstWhere((m) => m.group == RankGroup.chest);
      final back = r.muscles.firstWhere((m) => m.group == RankGroup.back);
      expect(chest.rankedUp, isTrue);
      expect(back.rankedUp, isFalse);
      expect(back.improved, isFalse);
      expect(r.anyMuscleRankedUp, isTrue);
    });

    test('a points gain without a tier change reads as improved, not ranked-up',
        () {
      final before = calc(
        groupRanks: {RankGroup.legs: MilitaryRank.corporal_e3},
        groupPoints: {RankGroup.legs: 2.1},
      );
      final after = calc(
        groupRanks: {RankGroup.legs: MilitaryRank.corporal_e3}, // same tier
        groupPoints: {RankGroup.legs: 2.7}, // but more points
      );

      final r = computeWorkoutResults(
        before: before,
        after: after,
        summary: _summary,
        sessionExerciseNames: const [],
        prNames: const [],
      );

      final legs = r.muscles.single;
      expect(legs.rankedUp, isFalse);
      expect(legs.improved, isTrue);
      expect(r.earnedAnything, isTrue);
    });

    test('a new-PR exercise appears with newPR flagged', () {
      final snapshot = calc(overall: MilitaryRank.corporal_e3);

      final r = computeWorkoutResults(
        before: snapshot,
        after: snapshot,
        summary: _summary,
        sessionExerciseNames: const ['Barbell Bench Press', 'Lat Pulldown'],
        prNames: const ['Barbell Bench Press'],
      );

      expect(r.exercises.length, 1);
      expect(r.exercises.single.name, 'Barbell Bench Press');
      expect(r.exercises.single.newPR, isTrue);
      expect(r.hasNewPRs, isTrue);
    });

    test('a per-exercise tier increase is flagged (keyed like the calculator)',
        () {
      // A non-library name keys by its lowercased self (lookupExercise → null),
      // matching exerciseScoreKey / _compute's fallback.
      final before = calc(exerciseRanks: const {'my custom lift': 1});
      final after = calc(exerciseRanks: const {'my custom lift': 3});

      final r = computeWorkoutResults(
        before: before,
        after: after,
        summary: _summary,
        sessionExerciseNames: const ['My Custom Lift'],
        prNames: const ['My Custom Lift'],
      );

      expect(r.exercises.single.rankedUp, isTrue);
      expect(r.exercises.single.newPR, isTrue);
    });

    test('a null before-snapshot yields badges but no deltas', () {
      final after = calc(
        overall: MilitaryRank.corporal_e3,
        groupRanks: {RankGroup.chest: MilitaryRank.corporal_e3},
        groupPoints: {RankGroup.chest: 2.5},
      );

      final r = computeWorkoutResults(
        before: null, // snapshot failed
        after: after,
        summary: _summary,
        sessionExerciseNames: const ['Barbell Bench Press'],
        prNames: const [],
      );

      expect(r.muscles.single.rank, MilitaryRank.corporal_e3);
      expect(r.muscles.single.rankedUp, isFalse);
      expect(r.muscles.single.improved, isFalse);
      expect(r.overallRankedUp, isFalse);
      expect(r.exercises, isEmpty);
    });

    test('first-time entry at Private is not mis-reported as a promotion', () {
      // Group had no rankable data before; now appears at Private (index 0).
      final before = calc(groupRanks: const {}, groupPoints: const {});
      final after = calc(
        groupRanks: {RankGroup.core: MilitaryRank.private_e1},
        groupPoints: {RankGroup.core: 0.3},
      );

      final r = computeWorkoutResults(
        before: before,
        after: after,
        summary: _summary,
        sessionExerciseNames: const [],
        prNames: const [],
      );

      final core = r.muscles.single;
      expect(core.rankedUp, isFalse); // reaching Private is not a promotion
      expect(core.improved, isTrue); // but points did rise from 0
    });
  });
}
