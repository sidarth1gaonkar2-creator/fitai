import 'exercise_standards.dart';
import 'military_ranks.dart';

/// Contribution of each muscle group to the overall rank (spec §6). Legs are
/// weighted heaviest as the largest muscle group; core/arms lightest.
const Map<RankGroup, double> kOverallWeights = {
  RankGroup.legs: 0.25,
  RankGroup.back: 0.20,
  RankGroup.chest: 0.20,
  RankGroup.shoulders: 0.15,
  RankGroup.arms: 0.10,
  RankGroup.core: 0.10,
};

/// Composite rank points (0–9) from per-group rank points. The fixed weights
/// are renormalized over the groups that actually have data, so a lifter who
/// hasn't trained (say) core isn't dragged down by a phantom zero — but with
/// all six groups present this reduces to the plain weighted average the spec
/// describes. Returns 0 when there's nothing to score.
double overallRankPoints(Map<RankGroup, double> groupPoints) {
  var weighted = 0.0;
  var totalWeight = 0.0;
  for (final entry in groupPoints.entries) {
    final weight = kOverallWeights[entry.key] ?? 0;
    weighted += weight * entry.value;
    totalWeight += weight;
  }
  if (totalWeight <= 0) return 0;
  return weighted / totalWeight;
}

/// The user's overall [MilitaryRank] from their per-group rank points.
MilitaryRank overallRank(Map<RankGroup, double> groupPoints) =>
    rankFromPoints(overallRankPoints(groupPoints));
