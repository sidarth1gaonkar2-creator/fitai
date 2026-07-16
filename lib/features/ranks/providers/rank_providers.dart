import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/utils/logger.dart';
import '../../../data/exercise_library.dart';
import '../../../models/enums.dart';
import '../../../models/personal_record.dart';
import '../../../models/user_rank.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/isar_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../providers/workout_providers.dart';
import '../../community/data/user_repository.dart';
import '../domain/exercise_rank_detail.dart';
import '../domain/exercise_standards.dart';
import '../domain/military_ranks.dart';
import '../domain/muscle_group_rank.dart';
import '../domain/overall_rank.dart';
import '../domain/strength_calculator.dart';

/// A logged user-custom (off-library) exercise that scored, plus the rank
/// group it was filed under. Its score / rank / best weight live in the
/// [RankCalculation] maps keyed by [key] (the lowercased name), exactly like a
/// built-in exercise keyed by its id — this just carries the display name and
/// group, which aren't otherwise recoverable for an off-library exercise.
class CustomExerciseRank {
  const CustomExerciseRank({required this.name, required this.group});

  /// Original-cased display name, taken from the PR.
  final String name;
  final RankGroup group;

  /// Key into [RankCalculation.exerciseScores] / `exerciseRanks` /
  /// `exerciseBestWeightKg` (matches `_compute`'s fallback key).
  String get key => name.toLowerCase();
}

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
    required this.exerciseBestWeightKg,
    required this.bodyWeightKg,
    this.customExercises = const [],
  });

  final MilitaryRank overall;
  final double overallPoints;
  final Map<RankGroup, double> muscleGroupPoints;
  final Map<RankGroup, MilitaryRank> muscleGroupRanks;

  /// canonical exercise id (or lowercased name) → best gender-adjusted score.
  final Map<String, double> exerciseScores;

  /// canonical exercise id (or lowercased name) → rank index for that exercise.
  final Map<String, int> exerciseRanks;

  /// canonical exercise id (or lowercased name) → best logged weight (kg, as
  /// stored on the PR). Powers the "all exercise ranks" list on the Ranks
  /// screen without re-querying Isar per row.
  final Map<String, double> exerciseBestWeightKg;

  final double bodyWeightKg;

  /// Logged user-custom (off-library) exercises that scored, with the group
  /// they were filed under. Lets the Ranks screen list them — built-in rows
  /// come from [exerciseLibrary], which customs aren't part of.
  final List<CustomExerciseRank> customExercises;

  static const empty = RankCalculation(
    overall: MilitaryRank.private_e1,
    overallPoints: 0,
    muscleGroupPoints: {},
    muscleGroupRanks: {},
    exerciseScores: {},
    exerciseRanks: {},
    exerciseBestWeightKg: {},
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

  // Mirror the overall rank onto the Firestore user doc so the community can
  // show this user's rank badge. Done UNCONDITIONALLY (not gated on a rank
  // change): this provider is read on app launch (the dashboard rank card
  // watches it), so existing users — including those still at Private whose
  // rank never "changed" — get their `rankIndex`/`rankName` backfilled. The
  // write is a guarded, idempotent merge, so re-running is cheap.
  final uid = ref.read(currentUserIdProvider);
  if (uid != null) {
    await ref
        .read(userRepositoryProvider)
        .updateUserRank(uid, calc.overall.index, calc.overall.displayName);
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
final muscleGroupRankProvider = FutureProvider.family<MilitaryRank?, RankGroup>(
  (ref, group) async {
    final calc = await ref.watch(rankCalculatorProvider.future);
    return calc.muscleGroupRanks[group];
  },
);

/// Rank for a specific exercise (by canonical id or lowercased name), or null
/// when there's no rankable PR for it.
final exerciseRankProvider = FutureProvider.family<MilitaryRank?, String>((
  ref,
  exerciseId,
) async {
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
    FutureProvider.family<ExerciseRankDetail?, String>((
      ref,
      exerciseName,
    ) async {
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
        if (pr.exerciseName.toLowerCase() != exerciseName.toLowerCase()) {
          continue;
        }
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
  final bestWeight = <String, double>{};
  // Off-library (user-custom) exercises that scored, keyed by their fallback
  // key, so the Ranks screen can list them under their chosen group.
  final customByKey = <String, CustomExerciseRank>{};

  for (final pr in prs) {
    if (pr.weightKg <= 0 || bodyWeightKg <= 0) continue;
    final standard = standardForExercise(
      name: pr.exerciseName,
      muscleGroup: pr.muscleGroup,
    );
    if (standard == null || !standard.rankable) continue;

    // Score on the best attempt's ESTIMATED 1RM (Epley, rep-capped) rather than
    // raw top weight, so heavier loads OR more reps both raise the score.
    // `pr.weightKg` and the returned e1RM are both in KG; the single kg→lbs
    // conversion still happens once, inside allometricScoreFromKg.
    final estimatedOneRmKg = estimatedOneRepMaxKg(
      weightKg: pr.weightKg,
      reps: pr.bestReps,
    );
    final score = allometricScoreFromKg(
      weightKg: estimatedOneRmKg,
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
      bestWeight[key] = pr.weightKg;
      // No library def → a user-custom exercise. Record its display name and
      // resolved group so the Ranks screen can surface it (built-in rows come
      // from the library, which customs aren't in).
      if (def == null) {
        customByKey[key] = CustomExerciseRank(
          name: pr.exerciseName,
          group: standard.group,
        );
      }
    }
  }

  final exerciseRanks = <String, int>{
    for (final entry in bestScored.entries)
      entry.key: rankIndexForScore(
        entry.value.score,
        entry.value.standard.thresholds,
      ),
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
    exerciseBestWeightKg: bestWeight,
    bodyWeightKg: bodyWeightKg,
    customExercises: customByKey.values.toList(),
  );
}

/// Persists [calc] to Isar and returns the OVERALL rank index that was stored
/// before this write (null on the very first calculation), so callers can tell
/// whether the rank changed.
Future<int?> _persist(Isar isar, RankCalculation calc) async {
  int? previousRankIndex;
  await isar.writeTxn(() async {
    final existing = await isar.userRanks.where().findFirst();
    previousRankIndex = existing?.overallRankIndex;
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
      history.add(
        RankSnapshot(date: DateTime.now(), rankIndex: calc.overall.index),
      );
      row.rankHistory = history;
    }

    await isar.userRanks.put(row);
  });
  return previousRankIndex;
}
