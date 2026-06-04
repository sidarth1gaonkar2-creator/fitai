import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/utils/logger.dart';
import '../../../data/exercise_library.dart';
import '../../../models/enums.dart';
import '../../../models/personal_record.dart';
import '../../../models/user_rank.dart';
import '../../../providers/isar_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../providers/workout_providers.dart';
import '../domain/exercise_rank_detail.dart';
import '../domain/exercise_standards.dart';
import '../domain/military_ranks.dart';
import '../domain/muscle_group_rank.dart';
import '../domain/overall_rank.dart';
import '../domain/strength_calculator.dart';

/// The fully-computed ranking for the current user — the in-memory result the
/// read providers and (eventually) the UI derive from. Pure data: produced by
/// [rankCalculatorProvider], which also persists a [UserRank] row.
class RankCalculation {
  const RankCalculation({
    required this.overall,
    required this.overallPoints,
    required this.muscleGroupPoints,
    required this.muscleGroupRanks,
    required this.exerciseScores,
    required this.exerciseRanks,
    required this.bodyWeightKg,
  });

  final MilitaryRank overall;
  final double overallPoints;
  final Map<RankGroup, double> muscleGroupPoints;
  final Map<RankGroup, MilitaryRank> muscleGroupRanks;

  /// canonical exercise id (or lowercased name) → best gender-adjusted score.
  final Map<String, double> exerciseScores;

  /// canonical exercise id (or lowercased name) → rank index for that exercise.
  final Map<String, int> exerciseRanks;

  final double bodyWeightKg;

  static const empty = RankCalculation(
    overall: MilitaryRank.private_e1,
    overallPoints: 0,
    muscleGroupPoints: {},
    muscleGroupRanks: {},
    exerciseScores: {},
    exerciseRanks: {},
    bodyWeightKg: 0,
  );
}

/// Computes the user's ranking from their PRs + body weight and persists the
/// result to Isar. Re-runs automatically whenever PRs or the profile change
/// (it watches [personalRecordsProvider] and [userProfileProvider]), so a new
/// PR re-ranks the user on the next frame.
final rankCalculatorProvider = FutureProvider<RankCalculation>((ref) async {
  final isar = ref.watch(isarProvider);
  final profile = await ref.watch(userProfileProvider.future);
  // Depend on the PR map so a newly-set PR triggers a recalculation. We read
  // the full PR rows from Isar below (the map lacks muscle-group data).
  await ref.watch(personalRecordsProvider.future);

  final bodyWeightKg = profile?.weight ?? 0;
  final sex = profile?.sex;

  final calc = await _compute(isar, bodyWeightKg: bodyWeightKg, sex: sex);

  // Persist as a best-effort side effect — a failure here must not break the
  // returned (live) calculation.
  try {
    await _persist(isar, calc);
  } catch (e, st) {
    AppLogger.error('Rank persist failed', error: e, stack: st);
  }

  return calc;
});

/// Reads the persisted [UserRank] row, ensuring a calculation has run (and
/// saved) first. Returns null only before the very first calculation.
final userRankProvider = FutureProvider<UserRank?>((ref) async {
  await ref.watch(rankCalculatorProvider.future);
  final isar = ref.watch(isarProvider);
  return isar.userRanks.where().findFirst();
});

/// The user's overall military rank.
final overallRankProvider = FutureProvider<MilitaryRank>((ref) async {
  final calc = await ref.watch(rankCalculatorProvider.future);
  return calc.overall;
});

/// Rank for a single muscle group, or null when that group has no rankable data.
final muscleGroupRankProvider =
    FutureProvider.family<MilitaryRank?, RankGroup>((ref, group) async {
  final calc = await ref.watch(rankCalculatorProvider.future);
  return calc.muscleGroupRanks[group];
});

/// Rank for a specific exercise (by canonical id or lowercased name), or null
/// when there's no rankable PR for it.
final exerciseRankProvider =
    FutureProvider.family<MilitaryRank?, String>((ref, exerciseId) async {
  final calc = await ref.watch(rankCalculatorProvider.future);
  final idx = calc.exerciseRanks[exerciseId];
  return idx == null ? null : rankFromIndex(idx);
});

/// Full per-exercise rank detail (rank, score, best weight, progress to next)
/// keyed by the exercise's display **name** — the value the workout / exercise
/// / PR screens already have. Returns:
///   * null  → the exercise isn't rankable (bodyweight / cardio) — show nothing
///   * `hasData == false` → rankable but no PR yet — show the empty state
///   * a full detail otherwise
final exerciseRankDetailProvider =
    FutureProvider.family<ExerciseRankDetail?, String>(
        (ref, exerciseName) async {
  final standard = standardForExercise(name: exerciseName);
  if (standard == null || !standard.rankable) return null;

  final profile = await ref.watch(userProfileProvider.future);
  // Re-run whenever a new PR lands.
  await ref.watch(personalRecordsProvider.future);
  final isar = ref.watch(isarProvider);

  final bodyWeightKg = profile?.weight ?? 0;
  final sex = profile?.sex;

  // Best PR for this exercise (PRs are best-per-exercise; dedupe defensively).
  final prs = await isar.personalRecords.where().findAll();
  PersonalRecord? best;
  for (final pr in prs) {
    if (pr.exerciseName.toLowerCase() != exerciseName.toLowerCase()) continue;
    if (best == null || pr.weightKg > best.weightKg) best = pr;
  }

  return computeExerciseRankDetail(
    standard: standard,
    bestWeightKg: best?.weightKg ?? 0,
    bestReps: best?.bestReps ?? 0,
    bodyWeightKg: bodyWeightKg,
    sex: sex,
  );
});

// ─── Internals ──────────────────────────────────────────────────────────────

Future<RankCalculation> _compute(
  Isar isar, {
  required double bodyWeightKg,
  required Sex? sex,
}) async {
  final prs = await isar.personalRecords.where().findAll();

  // Best (highest) score per exercise — PRs should already be one-per-exercise,
  // but dedupe defensively so a stray duplicate can't double-count.
  final bestScore = <String, double>{};
  final bestScored = <String, ScoredExercise>{};

  for (final pr in prs) {
    if (pr.weightKg <= 0 || bodyWeightKg <= 0) continue;
    final standard = standardForExercise(
      name: pr.exerciseName,
      muscleGroup: pr.muscleGroup,
    );
    if (standard == null || !standard.rankable) continue;

    final score = allometricScoreFromKg(
      weightKg: pr.weightKg,
      bodyWeightKg: bodyWeightKg,
      sex: sex,
      weightMultiplier: standard.weightMultiplier,
    );
    if (score <= 0) continue;

    final def = lookupExercise(name: pr.exerciseName);
    final key = def?.id ?? pr.exerciseName.toLowerCase();

    if ((bestScore[key] ?? -1) < score) {
      bestScore[key] = score;
      bestScored[key] = ScoredExercise(standard: standard, score: score);
    }
  }

  final exerciseRanks = <String, int>{
    for (final entry in bestScored.entries)
      entry.key: rankIndexForScore(entry.value.score, entry.value.standard.thresholds),
  };

  final groupPoints = muscleGroupRankPoints(bestScored.values);
  final groupRanks = muscleGroupRanks(groupPoints);
  final overallPoints = overallRankPoints(groupPoints);

  return RankCalculation(
    overall: rankFromPoints(overallPoints),
    overallPoints: overallPoints,
    muscleGroupPoints: groupPoints,
    muscleGroupRanks: groupRanks,
    exerciseScores: bestScore,
    exerciseRanks: exerciseRanks,
    bodyWeightKg: bodyWeightKg,
  );
}

Future<void> _persist(Isar isar, RankCalculation calc) async {
  await isar.writeTxn(() async {
    final existing = await isar.userRanks.where().findFirst();
    final row = existing ?? UserRank();

    row
      ..overallRankIndex = calc.overall.index
      ..overallScore = calc.overallPoints
      ..perExerciseScores = [
        for (final e in calc.exerciseScores.entries)
          ExerciseScore(exerciseId: e.key, score: e.value),
      ]
      ..perMuscleGroupRanks = [
        for (final e in calc.muscleGroupRanks.entries)
          MuscleGroupRankEntry(group: e.key.name, rank: e.value.index),
      ]
      ..bodyWeightAtCalculation = calc.bodyWeightKg
      ..lastCalculatedAt = DateTime.now();

    // Append to the history timeline only when the overall rank actually
    // changes (or on the very first calculation) — not on every recompute.
    final history = [...row.rankHistory];
    final lastRankIndex = history.isNotEmpty ? history.last.rankIndex : null;
    if (lastRankIndex != calc.overall.index) {
      history.add(RankSnapshot(date: DateTime.now(), rankIndex: calc.overall.index));
      row.rankHistory = history;
    }

    await isar.userRanks.put(row);
  });
}
