import 'package:flutter_test/flutter_test.dart';

import 'package:fitai/features/ranks/domain/exercise_rank_detail.dart';
import 'package:fitai/features/ranks/domain/exercise_standards.dart';
import 'package:fitai/features/ranks/domain/military_ranks.dart';
import 'package:fitai/features/ranks/domain/muscle_group_rank.dart';
import 'package:fitai/features/ranks/domain/overall_rank.dart';
import 'package:fitai/features/ranks/domain/strength_calculator.dart';
import 'package:fitai/core/utils/unit_converter.dart';
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

    // Scores the exercise on the ESTIMATED 1RM of a [reps]-rep set, matching
    // the production calculator. Defaults to the 5-rep working set the
    // thresholds are calibrated to.
    ScoredExercise scoredFor(String id, double weightKg, {int reps = 5}) {
      final std = exerciseStandards[id]!;
      final score = allometricScoreFromKg(
        weightKg: estimatedOneRepMaxKg(weightKg: weightKg, reps: reps),
        bodyWeightKg: bodyWeightKg,
        sex: Sex.male,
        weightMultiplier: std.weightMultiplier,
      );
      return ScoredExercise(standard: std, score: score);
    }

    // Squat 1.75×, deadlift 2×, bench 1.25×, OHP 0.75×, row 1.25× BW.
    List<ScoredExercise> intermediateMale({int reps = 5}) => [
          scoredFor('barbell_back_squat', 140, reps: reps),
          scoredFor('conventional_deadlift', 160, reps: reps),
          scoredFor('barbell_bench_press', 100, reps: reps),
          scoredFor('overhead_press', 60, reps: reps),
          scoredFor('barbell_bent_over_row', 100, reps: reps),
        ];

    test('a 5-rep intermediate male still lands at Sergeant (recalibration '
        'stability)', () {
      final overall = overallRank(muscleGroupRankPoints(intermediateMale()));
      expect(overall, MilitaryRank.sergeant_e5);
    });

    test('rep count shifts rank modestly: 1 < 5 < 12, bounded spread', () {
      final r1 = overallRank(muscleGroupRankPoints(intermediateMale(reps: 1)));
      final r5 = overallRank(muscleGroupRankPoints(intermediateMale(reps: 5)));
      final r12 = overallRank(muscleGroupRankPoints(intermediateMale(reps: 12)));
      // 5 reps is the calibration anchor; a heavy single sits one rank below
      // and a 12-rep set one above — a sensible two-rank spread end to end,
      // not a wild jump.
      expect(r5, MilitaryRank.sergeant_e5);
      expect(r1, MilitaryRank.specialist_e4);
      expect(r12, MilitaryRank.staffSergeant_e6);
      expect(r1.index, lessThanOrEqualTo(r5.index));
      expect(r5.index, lessThanOrEqualTo(r12.index));
      expect(r12.index - r1.index, lessThanOrEqualTo(3));
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

    test('a 5-rep working set is rank-stable after recalibration', () {
      // 80 kg male, 100 kg bench × 5 → Epley e1RM 116.7 kg → score ≈ 8.04.
      // With thresholds recalibrated to the 5-rep e1RM basis this lands at
      // Specialist (E4) — the SAME rank the old raw-100 kg scoring produced,
      // even though the underlying score is now higher (8.04 vs 6.9).
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
      expect(d.score, closeTo(8.04, 0.2));
      expect(d.progressToNext, closeTo(0.89, 0.06));
      // Gap is measured in estimated-1RM kg (~1.8 kg of e1RM to the next rank).
      expect(d.weightToNextKg, isNotNull);
      expect(d.weightToNextKg!, closeTo(1.8, 1.0));
    });

    test('a heavy single sits one rank below the same weight for 5 reps', () {
      // 100 kg × 1 → e1RM 100 kg → score ≈ 6.9. Against the recalibrated
      // thresholds that is Corporal (E3) — one rank below the 5-rep set above.
      // The intended, fairer down-shift for single-rep specialists.
      final d = computeExerciseRankDetail(
        standard: bench,
        bestWeightKg: 100,
        bestReps: 1,
        bodyWeightKg: 80,
        sex: Sex.male,
      );
      expect(d.score, closeTo(6.9, 0.2));
      expect(d.rank, MilitaryRank.corporal_e3);
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

  group('estimated 1RM (Epley)', () {
    test('a true single (reps ≤ 1) returns the weight unchanged', () {
      expect(estimatedOneRepMaxKg(weightKg: 100, reps: 1), 100);
      expect(estimatedOneRepMaxKg(weightKg: 100, reps: 0), 100);
    });

    test('more reps at the same weight raise the estimate', () {
      final r3 = estimatedOneRepMaxKg(weightKg: 100, reps: 3);
      final r8 = estimatedOneRepMaxKg(weightKg: 100, reps: 8);
      expect(r8, greaterThan(r3));
      // Epley: 100 × (1 + 5/30) = 116.667.
      expect(estimatedOneRepMaxKg(weightKg: 100, reps: 5),
          closeTo(116.667, 1e-3));
    });

    test('reps are capped at $kOneRmRepCap so high-rep sets do not run away',
        () {
      final atCap = estimatedOneRepMaxKg(weightKg: 100, reps: kOneRmRepCap);
      expect(estimatedOneRepMaxKg(weightKg: 100, reps: 20), atCap);
      expect(estimatedOneRepMaxKg(weightKg: 100, reps: 30), atCap);
      expect(atCap, closeTo(100 * (1 + kOneRmRepCap / 30), 1e-9));
    });

    test('a light high-rep set never out-estimates a heavier single', () {
      // 70 kg × 20 (capped to 12) must stay below a genuine 100 kg single.
      expect(estimatedOneRepMaxKg(weightKg: 70, reps: 20),
          lessThan(estimatedOneRepMaxKg(weightKg: 100, reps: 1)));
    });

    test('non-positive load returns 0 (no NaN / divide-by-zero downstream)', () {
      expect(estimatedOneRepMaxKg(weightKg: 0, reps: 5), 0);
      expect(estimatedOneRepMaxKg(weightKg: -10, reps: 5), 0);
    });
  });

  group('custom exercise mapping (PR2)', () {
    test('representativeMuscleForRankGroup round-trips through '
        'rankGroupForMuscle for every group', () {
      for (final g in RankGroup.values) {
        expect(rankGroupForMuscle(representativeMuscleForRankGroup(g)), g);
      }
    });

    test('a custom exercise resolves to a rankable, isolation standard in its '
        'chosen group', () {
      // A custom exercise has no id/name match — only the muscle group that
      // saveWorkout stamps from the user's choice. It must still rank.
      final std = standardForExercise(
        name: 'Totally Made Up Movement',
        muscleGroup: MuscleGroup.shoulders,
      );
      expect(std, isNotNull);
      expect(std!.rankable, isTrue);
      expect(std.group, RankGroup.shoulders);
      // Customs default to isolation (1× group weight) — an unknown movement
      // shouldn't carry a compound's 2× influence.
      expect(std.isCompound, isFalse);
    });

    test('a custom uses group-appropriate thresholds, not another group\'s',
        () {
      final shoulders = standardForExercise(
          name: 'X', muscleGroup: MuscleGroup.shoulders)!;
      final legs =
          standardForExercise(name: 'Y', muscleGroup: MuscleGroup.quads)!;
      // A Shoulders custom must not inherit the much heavier Legs thresholds.
      expect(shoulders.thresholds, isNot(equals(legs.thresholds)));
      expect(shoulders.thresholds.first, lessThan(legs.thresholds.first));
    });

    test('a cardio-only signal stays unrankable (no group)', () {
      expect(
        standardForExercise(name: 'Z', muscleGroup: MuscleGroup.cardio),
        isNull,
      );
    });
  });

  group('rank-up target (PR3 Part B)', () {
    final bench = exerciseStandards['barbell_bench_press']!;

    test('workingWeightForOneRepMaxKg inverts estimatedOneRepMaxKg (rep cap)',
        () {
      for (final reps in [1, 3, 5, 12, 20]) {
        final e1rm = estimatedOneRepMaxKg(weightKg: 120, reps: reps);
        expect(workingWeightForOneRepMaxKg(oneRepMaxKg: e1rm, reps: reps),
            closeTo(120, 1e-9));
      }
      expect(workingWeightForOneRepMaxKg(oneRepMaxKg: 0, reps: 5), 0);
    });

    test('target weight at the PR reps reaches the next rank threshold', () {
      final d = computeExerciseRankDetail(
        standard: bench,
        bestWeightKg: 100,
        bestReps: 5,
        bodyWeightKg: 80,
        sex: Sex.male,
      );
      expect(d.nextRank, isNotNull);
      expect(d.targetReps, 5);
      expect(d.targetWeightKg, isNotNull);
      // Lifting the target weight for the PR reps lands a score AT the next
      // rank's threshold — the definition of the target.
      final scoreAtTarget = allometricScoreFromKg(
        weightKg:
            estimatedOneRepMaxKg(weightKg: d.targetWeightKg!, reps: d.targetReps),
        bodyWeightKg: 80,
        sex: Sex.male,
        weightMultiplier: bench.weightMultiplier,
      );
      expect(scoreAtTarget, closeTo(bench.thresholds[d.nextRank!.index], 0.05));
      // You must add weight to rank up, so the target exceeds the current best.
      expect(d.targetWeightKg!, greaterThan(100));
    });

    test('target weight is kg-internal and converts once for display', () {
      final d = computeExerciseRankDetail(
        standard: bench,
        bestWeightKg: 100,
        bestReps: 5,
        bodyWeightKg: 80,
        sex: Sex.male,
      );
      final kg = d.targetWeightKg!;
      // Same physical target for both users; metric shows kg, imperial shows
      // lbs = kg × 2.20462 — a single display-time conversion.
      expect(UnitConverter.kgToDisplayWeight(kg, UnitSystem.metric),
          closeTo(kg, 1e-9));
      expect(UnitConverter.kgToDisplayWeight(kg, UnitSystem.imperial),
          closeTo(kg * 2.20462, 1e-6));
    });

    test('maxed lift has no target', () {
      final d = computeExerciseRankDetail(
        standard: bench,
        bestWeightKg: 400,
        bestReps: 1,
        bodyWeightKg: 80,
        sex: Sex.male,
      );
      expect(d.nextRank, isNull);
      expect(d.targetWeightKg, isNull);
    });
  });

  group('unit safety', () {
    test('the same physical lift entered in kg vs lbs yields the same score',
        () {
      // The app always stores kg; imperial input is converted at entry. So an
      // imperial user typing 220.462 lbs @ 176.37 lbs bodyweight must score
      // identically to a metric user with 100 kg @ 80 kg — the score is the
      // unitless 0–9 value.
      final liftKgFromImperial =
          UnitConverter.displayWeightToKg(220.462, UnitSystem.imperial);
      final bwKgFromImperial =
          UnitConverter.displayWeightToKg(176.3696, UnitSystem.imperial);

      final metricScore = allometricScoreFromKg(
        weightKg: estimatedOneRepMaxKg(weightKg: 100, reps: 5),
        bodyWeightKg: 80,
        sex: Sex.male,
      );
      final imperialScore = allometricScoreFromKg(
        weightKg: estimatedOneRepMaxKg(weightKg: liftKgFromImperial, reps: 5),
        bodyWeightKg: bwKgFromImperial,
        sex: Sex.male,
      );
      expect(imperialScore, closeTo(metricScore, 1e-6));
    });
  });
}
