import '../../../models/enums.dart';
import 'exercise_standards.dart';
import 'military_ranks.dart';
import 'strength_calculator.dart';

/// Everything the UI needs to show a single exercise's rank: the current rank,
/// the gender-adjusted score, the best logged weight, and the progress toward
/// the next rank ("15 more lbs to Staff Sergeant").
class ExerciseRankDetail {
  const ExerciseRankDetail({
    required this.group,
    required this.rank,
    required this.score,
    required this.bestWeightKg,
    required this.bestReps,
    required this.progressToNext,
    required this.nextRank,
    required this.weightToNextKg,
    required this.targetWeightKg,
    required this.targetReps,
    required this.hasData,
  });

  /// The exercise has a logged PR but no rankable standard (e.g. a bodyweight
  /// movement). Callers should render nothing.
  static const ExerciseRankDetail? notRankable = null;

  final RankGroup group;
  final MilitaryRank rank;

  /// Gender-adjusted allometric score for the best attempt.
  final double score;

  /// Best logged weight, in kg, as stored on the PR (per-implement for
  /// dumbbells).
  final double bestWeightKg;
  final int bestReps;

  /// Progress through the current rank band toward [nextRank], 0..1 (1.0 when
  /// already at the top rank).
  final double progressToNext;

  /// The next rank up, or null when already at the apex (SMA).
  final MilitaryRank? nextRank;

  /// Additional per-implement weight (kg) needed to reach [nextRank], or null
  /// when maxed.
  final double? weightToNextKg;

  /// Per-implement weight (kg) that — lifted for [targetReps] — reaches
  /// [nextRank]. The concrete "lift X for your usual reps" target. Null when
  /// maxed. Converted to the user's unit at the UI.
  final double? targetWeightKg;

  /// Rep count the [targetWeightKg] target is anchored to — the user's PR-set
  /// reps, so the target reads in their actual rep scheme ("195 × 5").
  final int targetReps;

  /// False when the exercise is rankable but has no logged PR yet — the UI
  /// shows the "log this to earn your rank" empty state.
  final bool hasData;
}

/// Builds an [ExerciseRankDetail] from a best attempt. Pure (no Isar/Riverpod)
/// so it's directly unit-testable.
ExerciseRankDetail computeExerciseRankDetail({
  required ExerciseStandard standard,
  required double bestWeightKg,
  required int bestReps,
  required double bodyWeightKg,
  Sex? sex,
}) {
  final hasData = bestWeightKg > 0 && bodyWeightKg > 0;
  // Score on the ESTIMATED 1RM (Epley, rep-capped) of the best attempt, to
  // match the calculator's basis. [bestWeightKg] and the e1RM are both in KG;
  // allometricScoreFromKg performs the lone kg→lbs conversion internally.
  final estimatedOneRmKg =
      estimatedOneRepMaxKg(weightKg: bestWeightKg, reps: bestReps);
  final score = allometricScoreFromKg(
    weightKg: estimatedOneRmKg,
    bodyWeightKg: bodyWeightKg,
    sex: sex,
    weightMultiplier: standard.weightMultiplier,
  );

  final points = rankPointsForScore(score, standard.thresholds);
  final rankIndex = points.floor().clamp(0, MilitaryRank.values.length - 1);
  final rank = rankFromIndex(rankIndex);

  final isMaxed = rankIndex >= MilitaryRank.values.length - 1;
  final nextRank = isMaxed ? null : rankFromIndex(rankIndex + 1);
  final progress = isMaxed ? 1.0 : (points - rankIndex).clamp(0.0, 1.0);

  double? weightToNextKg;
  double? targetWeightKg;
  if (nextRank != null) {
    final nextThreshold = standard.thresholds[rankIndex + 1];
    final needed = weightKgForScore(
      targetScore: nextThreshold,
      bodyWeightKg: bodyWeightKg,
      sex: sex,
      weightMultiplier: standard.weightMultiplier,
    );
    // `needed` is the estimated-1RM (kg) required for the next rank, so measure
    // the gap against the current estimated 1RM (kg) — not the raw logged
    // weight — to keep both sides of the subtraction in the same metric.
    final delta = needed - estimatedOneRmKg;
    weightToNextKg = delta > 0 ? delta : 0;
    // Concrete target: the working weight that hits `needed` at the user's PR
    // reps (≥1 whenever there's data), so the hint reads "195 × 5 → Corporal".
    targetWeightKg = workingWeightForOneRepMaxKg(
      oneRepMaxKg: needed,
      reps: bestReps,
    );
  }

  return ExerciseRankDetail(
    group: standard.group,
    rank: rank,
    score: score,
    bestWeightKg: bestWeightKg,
    bestReps: bestReps,
    progressToNext: progress,
    nextRank: nextRank,
    weightToNextKg: weightToNextKg,
    targetWeightKg: targetWeightKg,
    targetReps: bestReps,
    hasData: hasData,
  );
}
