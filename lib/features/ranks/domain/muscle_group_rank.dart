import 'exercise_standards.dart';
import 'military_ranks.dart';

/// One exercise's best (highest) gender-adjusted allometric [score], paired
/// with its [standard] so the aggregator knows the thresholds, group, and
/// compound/isolation weighting.
class ScoredExercise {
  const ScoredExercise({required this.standard, required this.score});
  final ExerciseStandard standard;
  final double score;
}

/// Weighted-average rank points (0–9) for each muscle group that has rankable
/// data. Within a group, compound lifts count 2× and isolation lifts 1×, and
/// each exercise contributes the rank points of its single best attempt.
/// Groups with no rankable PRs are simply absent from the result.
Map<RankGroup, double> muscleGroupRankPoints(Iterable<ScoredExercise> scored) {
  final weightedSum = <RankGroup, double>{};
  final weightTotal = <RankGroup, double>{};

  for (final s in scored) {
    if (!s.standard.rankable) continue;
    final points = rankPointsForScore(s.score, s.standard.thresholds);
    final weight = s.standard.isCompound ? 2.0 : 1.0;
    final group = s.standard.group;
    weightedSum[group] = (weightedSum[group] ?? 0) + points * weight;
    weightTotal[group] = (weightTotal[group] ?? 0) + weight;
  }

  final result = <RankGroup, double>{};
  for (final group in weightedSum.keys) {
    final total = weightTotal[group] ?? 0;
    if (total > 0) result[group] = weightedSum[group]! / total;
  }
  return result;
}

/// Floors each group's rank points to a concrete [MilitaryRank].
Map<RankGroup, MilitaryRank> muscleGroupRanks(
  Map<RankGroup, double> points,
) => {
  for (final entry in points.entries) entry.key: rankFromPoints(entry.value),
};
