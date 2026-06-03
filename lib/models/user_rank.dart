import 'package:isar/isar.dart';

import '../features/ranks/domain/military_ranks.dart';

part 'user_rank.g.dart';

/// Persisted snapshot of the user's military ranking. A single row (the latest
/// calculation) is kept and overwritten on each recalc; [rankHistory] retains
/// the overall-rank timeline for the Phase-2 history chart.
///
/// Isar can't store `Map`s, so the per-exercise and per-muscle-group maps are
/// stored as embedded lists and surfaced through map getters.
@collection
class UserRank {
  Id id = Isar.autoIncrement;

  /// [MilitaryRank] ordinal — stored as an int (see [overallRank]).
  int overallRankIndex = 0;

  /// Composite rank points on the 0–9 scale (also what [overallRankIndex]
  /// floors from).
  double overallScore = 0;

  /// exercise id → best gender-adjusted allometric score.
  List<ExerciseScore> perExerciseScores = [];

  /// muscle-group name → [MilitaryRank] ordinal.
  List<MuscleGroupRankEntry> perMuscleGroupRanks = [];

  /// Body weight (kg) used for the last calculation, so we can detect when a
  /// new weigh-in should trigger a recalc.
  double bodyWeightAtCalculation = 0;

  DateTime lastCalculatedAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Overall-rank timeline (oldest first) for the history chart.
  List<RankSnapshot> rankHistory = [];

  @ignore
  MilitaryRank get overallRank => rankFromIndex(overallRankIndex);
  set overallRank(MilitaryRank rank) => overallRankIndex = rank.index;

  /// exercise id → score, reconstructed from [perExerciseScores].
  @ignore
  Map<String, double> get exerciseScoreMap =>
      {for (final e in perExerciseScores) e.exerciseId: e.score};

  /// muscle-group name → rank ordinal, reconstructed from
  /// [perMuscleGroupRanks].
  @ignore
  Map<String, int> get muscleGroupRankMap =>
      {for (final e in perMuscleGroupRanks) e.group: e.rank};
}

/// Embedded: one exercise's best score.
@embedded
class ExerciseScore {
  ExerciseScore({this.exerciseId = '', this.score = 0});
  String exerciseId;
  double score;
}

/// Embedded: one muscle group's rank (stored as the [MilitaryRank] ordinal).
@embedded
class MuscleGroupRankEntry {
  MuscleGroupRankEntry({this.group = '', this.rank = 0});
  String group;
  int rank;
}

/// Embedded: a point on the overall-rank history timeline.
@embedded
class RankSnapshot {
  RankSnapshot({this.date, this.rankIndex = 0});
  DateTime? date;
  int rankIndex;

  @ignore
  MilitaryRank get rank => rankFromIndex(rankIndex);
}
