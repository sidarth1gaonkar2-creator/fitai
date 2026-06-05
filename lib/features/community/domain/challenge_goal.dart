import '../../../core/utils/unit_converter.dart';
import '../../ranks/domain/exercise_standards.dart';
import '../../ranks/domain/military_ranks.dart';
import 'challenge.dart';

/// Resolved, display-ready progress of the current user against a rank-based
/// [Challenge] goal. Pure value object — produced by
/// [computeChallengeGoalProgress] from a [RankCalculation]'s raw fields so it
/// stays free of Riverpod/Isar and is directly unit-testable.
class ChallengeGoalProgress {
  const ChallengeGoalProgress({
    required this.progress,
    required this.isComplete,
    required this.headline,
    required this.currentLabel,
    required this.targetLabel,
    this.targetRank,
  });

  /// 0..1 fraction toward the goal.
  final double progress;
  final bool isComplete;

  /// Short objective summary, e.g. "Reach Sergeant".
  final String headline;

  /// Where the user is now, e.g. "Corporal" or "185 lb".
  final String currentLabel;

  /// What they're aiming for, e.g. "Sergeant" or "225 lb bench".
  final String targetLabel;

  /// Target rank for the card badge, or null for pure-weight goals.
  final MilitaryRank? targetRank;
}

/// Computes [ChallengeGoalProgress] for the signed-in user. Pass the raw fields
/// from their `RankCalculation` plus body weight (kg). Returns null when the
/// challenge has no rank goal.
ChallengeGoalProgress? computeChallengeGoalProgress({
  required Challenge challenge,
  required double overallPoints,
  required Map<RankGroup, double> muscleGroupPoints,
  required Map<String, double> exerciseScores,
  required Map<String, double> exerciseBestWeightKg,
  required double bodyWeightKg,
}) {
  if (!challenge.isRankGoal) return null;

  String lbs(double kg) => '${UnitConverter.kgToLbs(kg).round()} lb';
  double bestKg(String? id) =>
      id == null ? 0 : (exerciseBestWeightKg[id] ?? 0);

  switch (challenge.rankGoalType) {
    case RankGoalType.none:
      return null;

    case RankGoalType.overallRank:
      final target = (challenge.targetRankIndex ?? 0).toDouble();
      final targetRank = rankFromIndex(challenge.targetRankIndex ?? 0);
      final current = rankFromPoints(overallPoints);
      return ChallengeGoalProgress(
        progress: target <= 0 ? 1 : (overallPoints / target).clamp(0.0, 1.0),
        isComplete: overallPoints >= target,
        headline: 'Reach ${targetRank.displayName}',
        currentLabel: current.displayName,
        targetLabel: targetRank.displayName,
        targetRank: targetRank,
      );

    case RankGoalType.exerciseRank:
      final id = challenge.goalExerciseId;
      final label = challenge.goalExerciseLabel ?? 'Lift';
      final target = (challenge.targetRankIndex ?? 0).toDouble();
      final targetRank = rankFromIndex(challenge.targetRankIndex ?? 0);
      final standard = standardForExercise(id: id);
      final score = id == null ? null : exerciseScores[id];
      final points = (score != null && standard != null)
          ? rankPointsForScore(score, standard.thresholds)
          : 0.0;
      final current = rankFromPoints(points);
      return ChallengeGoalProgress(
        progress: target <= 0 ? 1 : (points / target).clamp(0.0, 1.0),
        isComplete: points >= target,
        headline: '$label ${targetRank.displayName}',
        currentLabel: '$label · ${current.abbreviation}',
        targetLabel: '${targetRank.displayName} on $label',
        targetRank: targetRank,
      );

    case RankGoalType.allMuscleGroups:
      final target = (challenge.targetRankIndex ?? 0).toDouble();
      final targetRank = rankFromIndex(challenge.targetRankIndex ?? 0);
      final groups = RankGroup.values;
      var met = 0;
      var sum = 0.0;
      for (final g in groups) {
        final p = muscleGroupPoints[g] ?? 0;
        if (p >= target) met++;
        sum += target <= 0 ? 1.0 : (p / target).clamp(0.0, 1.0);
      }
      return ChallengeGoalProgress(
        progress: sum / groups.length,
        isComplete: met == groups.length,
        headline: 'All groups ${targetRank.displayName}',
        currentLabel: '$met/${groups.length} groups',
        targetLabel: '${targetRank.displayName} in every group',
        targetRank: targetRank,
      );

    case RankGoalType.liftWeight:
      final label = challenge.goalExerciseLabel ?? 'Lift';
      final target = challenge.targetWeightLbs ?? 0;
      final bestLbs = UnitConverter.kgToLbs(bestKg(challenge.goalExerciseId));
      return ChallengeGoalProgress(
        progress: target <= 0 ? 1 : (bestLbs / target).clamp(0.0, 1.0),
        isComplete: bestLbs >= target,
        headline: '${target.round()} lb $label',
        currentLabel: '${bestLbs.round()} lb',
        targetLabel: '${target.round()} lb $label',
      );

    case RankGoalType.bodyweightMultiple:
      final label = challenge.goalExerciseLabel ?? 'Lift';
      final mult = challenge.targetBodyweightMultiple ?? 0;
      final best = bestKg(challenge.goalExerciseId);
      final ratio = bodyWeightKg > 0 ? best / bodyWeightKg : 0.0;
      return ChallengeGoalProgress(
        progress: mult <= 0 ? 1 : (ratio / mult).clamp(0.0, 1.0),
        isComplete: ratio >= mult && mult > 0,
        headline: '${_trim(mult)}× BW $label',
        currentLabel: '${_trim(ratio)}× BW',
        targetLabel: '${_trim(mult)}× bodyweight $label',
      );

    case RankGoalType.big3Total:
      final target = challenge.targetWeightLbs ?? 0;
      final totalKg = bestKg('barbell_bench_press') +
          bestKg('barbell_back_squat') +
          bestKg('conventional_deadlift');
      final totalLbs = UnitConverter.kgToLbs(totalKg);
      return ChallengeGoalProgress(
        progress: target <= 0 ? 1 : (totalLbs / target).clamp(0.0, 1.0),
        isComplete: totalLbs >= target,
        headline: '${target.round()} lb total',
        currentLabel: lbs(totalKg),
        targetLabel: '${target.round()} lb big-3 total',
      );
  }
}

/// A user-independent one-line description of a challenge's objective — used in
/// headers where we don't (yet) have the viewer's rank calculation.
String challengeGoalSummary(Challenge challenge) {
  final rankName = challenge.targetRankIndex == null
      ? ''
      : rankFromIndex(challenge.targetRankIndex!).displayName;
  final lift = challenge.goalExerciseLabel ?? 'Lift';
  switch (challenge.rankGoalType) {
    case RankGoalType.none:
      return '';
    case RankGoalType.overallRank:
      return 'Reach $rankName overall rank';
    case RankGoalType.exerciseRank:
      return 'Reach $rankName on $lift';
    case RankGoalType.allMuscleGroups:
      return '$rankName in all 6 muscle groups';
    case RankGoalType.liftWeight:
      return '${(challenge.targetWeightLbs ?? 0).round()} lb $lift';
    case RankGoalType.bodyweightMultiple:
      return '${_trim(challenge.targetBodyweightMultiple ?? 0)}× bodyweight $lift';
    case RankGoalType.big3Total:
      return '${(challenge.targetWeightLbs ?? 0).round()} lb big-3 total';
  }
}

/// Trims a multiplier to at most one decimal ("2" not "2.0", "1.6" kept).
String _trim(double v) {
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}
