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
  final score = allometricScoreFromKg(
    weightKg: bestWeightKg,
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
  if (nextRank != null) {
    final nextThreshold = standard.thresholds[rankIndex + 1];
    final needed = weightKgForScore(
      targetScore: nextThreshold,
      bodyWeightKg: bodyWeightKg,
      sex: sex,
      weightMultiplier: standard.weightMultiplier,
    );
    final delta = needed - bestWeightKg;
    weightToNextKg = delta > 0 ? delta : 0;
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
    hasData: hasData,
  );
}
