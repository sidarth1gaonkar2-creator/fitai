import '../../../data/exercise_library.dart';
import '../../ranks/domain/exercise_standards.dart';
import '../../ranks/domain/military_ranks.dart';
import '../../ranks/providers/rank_providers.dart';

/// Immutable summary stats for a finished workout — the "always shown" part of
/// the results screen, independent of any rank movement.
class WorkoutSummary {
  const WorkoutSummary({
    required this.title,
    required this.duration,
    required this.sets,
    required this.exercises,
    required this.volumeKg,
  });

  final String title;
  final Duration duration;

  /// Number of logged working sets (reps > 0).
  final int sets;
  final int exercises;

  /// Total tonnage in KG (Σ weight×reps across weighted sets). Converted to the
  /// user's unit at display time.
  final double volumeKg;
}

/// Per-muscle-group outcome for the results screen. The badge ([rank]) is the
/// CURRENT (post-save) rank and is always shown; [rankedUp]/[improved] are only
/// true when a genuine delta was earned this session.
class MuscleResult {
  const MuscleResult({
    required this.group,
    required this.rank,
    required this.rankedUp,
    required this.improved,
  });

  final RankGroup group;
  final MilitaryRank rank;

  /// The group's rank tier increased vs. before the save.
  final bool rankedUp;

  /// The group's points rose without a tier change (▲ improved).
  final bool improved;
}

/// Per-exercise outcome — only emitted for this session's exercises that
/// actually earned something (a new PR, and/or a tier increase).
class ExerciseResult {
  const ExerciseResult({
    required this.name,
    required this.newPR,
    required this.rankedUp,
  });

  final String name;
  final bool newPR;
  final bool rankedUp;
}

/// The fully-diffed outcome of a finished workout: always a summary + current
/// per-muscle badges, with deltas only where genuinely earned. Built by
/// [computeWorkoutResults] — pure data, no invented improvement.
class WorkoutResults {
  const WorkoutResults({
    required this.summary,
    required this.overallRank,
    required this.overallRankedUp,
    required this.muscles,
    required this.exercises,
  });

  final WorkoutSummary summary;

  /// Current (post-save) overall rank.
  final MilitaryRank overallRank;
  final bool overallRankedUp;

  /// Groups with rankable data now, in [RankGroup] order, each with its badge.
  final List<MuscleResult> muscles;

  /// This session's exercises that earned a PR and/or a rank tier increase.
  final List<ExerciseResult> exercises;

  bool get anyMuscleRankedUp => muscles.any((m) => m.rankedUp);
  bool get anyMuscleImproved => muscles.any((m) => m.improved);
  bool get hasNewPRs => exercises.any((e) => e.newPR);

  /// True when the session produced any rank/score progress at all — drives the
  /// "earned this session" section vs. a plain summary.
  bool get earnedAnything =>
      overallRankedUp ||
      anyMuscleRankedUp ||
      anyMuscleImproved ||
      exercises.isNotEmpty;
}

/// Canonical score-map key for an exercise name. MUST match `_compute` in
/// rank_providers (`lookupExercise(...)?.id ?? name.toLowerCase()`) so the
/// before/after diff reads the same map entry the calculator wrote.
String exerciseScoreKey(String name) =>
    lookupExercise(name: name)?.id ?? name.toLowerCase();

/// Diffs the rank state captured BEFORE the save ([before]) against the state
/// recomputed AFTER it ([after]) to produce a [WorkoutResults].
///
/// * [before] is null only when the pre-save snapshot failed — then no deltas
///   are reported (current badges still show).
/// * When the session set no new PR, the caller passes `after == before`:
///   scores are unchanged, so every delta is false and nothing fake is shown
///   (PR1: a score only moves on a new estimated-1RM PR).
WorkoutResults computeWorkoutResults({
  required RankCalculation? before,
  required RankCalculation after,
  required WorkoutSummary summary,
  required List<String> sessionExerciseNames,
  required List<String> prNames,
}) {
  // Overall — a real promotion vs. the pre-save snapshot.
  final overallRankedUp =
      before != null && after.overall.index > before.overall.index;

  // Per-muscle — list every group that has rankable data now (with its badge).
  // Treat an unranked group as the Private baseline (index 0) so first-time
  // entry at Private isn't mis-reported as a promotion, while newly earning a
  // real rank (Corporal+) or climbing a tier is.
  final muscles = <MuscleResult>[];
  for (final group in RankGroup.values) {
    final afterRank = after.muscleGroupRanks[group];
    if (afterRank == null) continue; // no rankable data → no badge
    final beforeIndex = before?.muscleGroupRanks[group]?.index ?? 0;
    final afterPts = after.muscleGroupPoints[group] ?? 0;
    final beforePts = before?.muscleGroupPoints[group] ?? 0;
    final rankedUp = before != null && afterRank.index > beforeIndex;
    final improved = before != null && !rankedUp && afterPts > beforePts + 1e-6;
    muscles.add(MuscleResult(
      group: group,
      rank: afterRank,
      rankedUp: rankedUp,
      improved: improved,
    ));
  }

  // Per-exercise — only this session's exercises, and only those that earned a
  // PR and/or a tier increase. (A score can only move via a new PR, so a
  // rank-up here always coincides with a PR.)
  final prSet = prNames.map((n) => n.toLowerCase()).toSet();
  final exercises = <ExerciseResult>[];
  final seen = <String>{};
  for (final name in sessionExerciseNames) {
    final lower = name.toLowerCase();
    if (!seen.add(lower)) continue; // de-dupe repeated names within a session
    final key = exerciseScoreKey(name);
    final afterIndex = after.exerciseRanks[key];
    final beforeIndex = before?.exerciseRanks[key] ?? 0;
    final rankedUp =
        before != null && afterIndex != null && afterIndex > beforeIndex;
    final newPR = prSet.contains(lower);
    if (newPR || rankedUp) {
      exercises
          .add(ExerciseResult(name: name, newPR: newPR, rankedUp: rankedUp));
    }
  }

  return WorkoutResults(
    summary: summary,
    overallRank: after.overall,
    overallRankedUp: overallRankedUp,
    muscles: muscles,
    exercises: exercises,
  );
}
