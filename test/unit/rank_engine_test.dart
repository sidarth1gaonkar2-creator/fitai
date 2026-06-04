import 'package:flutter_test/flutter_test.dart';

import 'package:fitai/features/ranks/domain/exercise_rank_detail.dart';
import 'package:fitai/features/ranks/domain/exercise_standards.dart';
import 'package:fitai/features/ranks/domain/military_ranks.dart';
import 'package:fitai/features/ranks/domain/muscle_group_rank.dart';
import 'package:fitai/features/ranks/domain/overall_rank.dart';
import 'package:fitai/features/ranks/domain/strength_calculator.dart';
import 'package:fitai/models/enums.dart';

void main() {
  group('allometric score', () {
    test('matches the spec examples (within rounding)', () {
      expect(allometricScoreLbs(weightLbs: 135, bodyWeightLbs: 150),
          closeTo(4.8, 0.2));
      expect(allometricScoreLbs(weightLbs: 225, bodyWeightLbs: 150),
          closeTo(8.0, 0.2));
      expect(allometricScoreLbs(weightLbs: 315, bodyWeightLbs: 150),
          closeTo(11.2, 0.3));
      expect(allometricScoreLbs(weightLbs: 1000, bodyWeightLbs: 500),
          closeTo(15.9, 0.4));
    });

    test('heavier lifter at the same BW ratio scores higher (absolute matters)',
        () {
      final small = allometricScoreLbs(weightLbs: 300, bodyWeightLbs: 150);
      final big = allometricScoreLbs(weightLbs: 1000, bodyWeightLbs: 500);
      expect(big, greaterThan(small));
    });

    test('edge cases return 0 (no NaN / no divide-by-zero)', () {
      expect(allometricScoreLbs(weightLbs: 200, bodyWeightLbs: 0), 0);
      expect(allometricScoreLbs(weightLbs: 0, bodyWeightLbs: 80), 0);
      expect(allometricScoreFromKg(weightKg: 100, bodyWeightKg: 0, sex: Sex.male),
          0);
    });

    test('dumbbell multiplier doubles the effective load', () {
      final single = allometricScoreFromKg(
          weightKg: 30, bodyWeightKg: 80, sex: Sex.male, weightMultiplier: 1.0);
      final paired = allometricScoreFromKg(
          weightKg: 30, bodyWeightKg: 80, sex: Sex.male, weightMultiplier: 2.0);
      expect(paired, closeTo(single * 2, 1e-9));
    });
  });

  group('gender multiplier', () {
    test('female outranks male at the same lift; null is the middle ground',
        () {
      expect(genderMultiplier(Sex.male), 1.0);
      expect(genderMultiplier(Sex.female), 1.35);
      expect(genderMultiplier(null), 1.15);
    });
  });

  group('rank mapping', () {
    final bench = exerciseStandards['barbell_bench_press']!.thresholds;

    test('below the first threshold stays Private', () {
      expect(rankIndexForScore(1.0, bench), 0);
      expect(rankPointsForScore(0, bench), 0);
    });

    test('rank points are bounded to 0..9', () {
      expect(rankPointsForScore(-5, bench), 0);
      expect(rankPointsForScore(1000, bench), 9);
    });

    test('a maxed score reaches the top rank', () {
      expect(rankFromPoints(rankPointsForScore(100, bench)),
          MilitaryRank.sgmArmy_e10);
    });
  });

  group('full pipeline', () {
    const bodyWeightKg = 80.0; // ~176 lb

    ScoredExercise scoredFor(String id, double weightKg) {
      final std = exerciseStandards[id]!;
      final score = allometricScoreFromKg(
        weightKg: weightKg,
        bodyWeightKg: bodyWeightKg,
        sex: Sex.male,
        weightMultiplier: std.weightMultiplier,
      );
      return ScoredExercise(standard: std, score: score);
    }

    test('a decent intermediate male lands at Sergeant', () {
      // Squat 1.75×, deadlift 2×, bench 1.25×, OHP 0.75×, row 1.25× BW.
      final scored = [
        scoredFor('barbell_back_squat', 140),
        scoredFor('conventional_deadlift', 160),
        scoredFor('barbell_bench_press', 100),
        scoredFor('overhead_press', 60),
        scoredFor('barbell_bent_over_row', 100),
      ];
      final groupPoints = muscleGroupRankPoints(scored);
      final overall = overallRank(groupPoints);
      expect(overall, MilitaryRank.sergeant_e5);
    });

    test('no PRs → Private', () {
      expect(overallRank(muscleGroupRankPoints(const [])),
          MilitaryRank.private_e1);
      expect(overallRankPoints(const {}), 0);
    });

    test('bodyweight / cardio exercises are skipped', () {
      final scored = [
        ScoredExercise(
          standard: exerciseStandards['push_up']!,
          score: 99, // even a huge fake score is ignored — not rankable
        ),
      ];
      expect(muscleGroupRankPoints(scored), isEmpty);
    });

    test('every library exercise resolves to a standard', () {
      // Spot-check the lookup path used by the calculator.
      expect(standardForExercise(name: 'Barbell Bench Press'), isNotNull);
      expect(standardForExercise(name: 'Conventional Deadlift')!.group,
          RankGroup.back);
      // Unknown custom exercise falls back via its muscle group.
      expect(
        standardForExercise(name: 'Some Custom Press', muscleGroup: MuscleGroup.chest),
        isNotNull,
      );
    });
  });

  group('per-exercise rank detail', () {
    final bench = exerciseStandards['barbell_bench_press']!;

    test('weightKgForScore inverts the score formula', () {
      final score = allometricScoreFromKg(
          weightKg: 100, bodyWeightKg: 80, sex: Sex.male);
      final back = weightKgForScore(
          targetScore: score, bodyWeightKg: 80, sex: Sex.male);
      expect(back, closeTo(100, 0.1));
    });

    test('detail exposes rank, next rank, and weight-to-next', () {
      // 80 kg male, 100 kg bench (1.25×) → score ≈ 6.9 → Specialist (E4).
      final d = computeExerciseRankDetail(
        standard: bench,
        bestWeightKg: 100,
        bestReps: 5,
        bodyWeightKg: 80,
        sex: Sex.male,
      );
      expect(d.hasData, isTrue);
      expect(d.rank, MilitaryRank.specialist_e4);
      expect(d.nextRank, MilitaryRank.sergeant_e5);
      expect(d.score, closeTo(6.9, 0.2));
      expect(d.progressToNext, closeTo(0.89, 0.06));
      // ~2 kg to clear the Sergeant threshold (bench score 7.0).
      expect(d.weightToNextKg, isNotNull);
      expect(d.weightToNextKg!, closeTo(1.6, 1.0));
    });

    test('no PR yet → hasData false, Private', () {
      final d = computeExerciseRankDetail(
        standard: bench,
        bestWeightKg: 0,
        bestReps: 0,
        bodyWeightKg: 80,
        sex: Sex.male,
      );
      expect(d.hasData, isFalse);
      expect(d.rank, MilitaryRank.private_e1);
    });

    test('a maxed lift has no next rank', () {
      final d = computeExerciseRankDetail(
        standard: bench,
        bestWeightKg: 400, // absurd → tops out
        bestReps: 1,
        bodyWeightKg: 80,
        sex: Sex.male,
      );
      expect(d.rank, MilitaryRank.sgmArmy_e10);
      expect(d.nextRank, isNull);
      expect(d.weightToNextKg, isNull);
      expect(d.progressToNext, 1.0);
    });
  });
}
