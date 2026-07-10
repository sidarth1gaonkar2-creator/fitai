import 'dart:io';

import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/ai_message.dart';
import '../../models/cached_menu_item.dart';
import '../../models/completed_day.dart';
import '../../models/custom_meal_plan.dart';
import '../../models/custom_meal_plan_food.dart';
import '../../models/custom_meal_plan_meal.dart';
import '../../models/food_entry.dart';
import '../../models/meal.dart';
import '../../models/nutrition_log.dart';
import '../../models/onboarding_progress.dart';
import '../../models/personal_record.dart';
import '../../models/saved_meal.dart';
import '../../models/saved_meal_item.dart';
import '../../models/saved_workout_template.dart';
import '../../models/supplement.dart';
import '../../models/supplement_log.dart';
import '../../models/user_profile.dart';
import '../../models/user_rank.dart';
import '../../models/user_theme_state.dart';
import '../../models/weight_entry.dart';
import '../../models/workout.dart';
import '../../models/workout_exercise.dart';
import '../../models/workout_set.dart';
import '../utils/logger.dart';
import 'isar_service.dart';

/// One-time migration of the legacy single 'default' Isar instance into the
/// per-account instance scheme (docs/uid-scoping-audit.md §3).
///
/// Runs in bootstrap BEFORE the first `Isar.open` of the launch, so no
/// instance holds the legacy file while it is moved. Idempotent and
/// kill-safe: the done flag is set ONLY after verified success, and a re-run
/// after a mid-migration kill converges (a moved-but-unflagged DB is detected
/// by the legacy file's absence; a partially row-copied target is overwritten
/// by the id-preserving re-copy).

/// Set once the legacy DB's fate is settled (moved, parked, or absent).
const String isarUidMigrationDoneKey = 'isar_uid_migration_done';

/// Diagnostic record of where the legacy DB went: a uid, [kParkedOwner], or
/// unset when there was nothing to migrate.
const String isarUidMigrationOwnerKey = 'isar_uid_migration_owner';

/// [isarUidMigrationOwnerKey] value for a legacy DB parked unclaimed.
const String kParkedOwner = 'parked';

/// What to do with the legacy 'default' instance.
enum LegacyDbAction {
  /// No legacy DB on disk — fresh install, or a previous run already moved it
  /// and was killed before flagging.
  none,

  /// Move the legacy DB to [LegacyDbDecision.ownerUid]'s instance.
  moveToOwner,

  /// Leave the legacy DB in place, unclaimed — and never claim it later.
  park,
}

class LegacyDbDecision {
  const LegacyDbDecision(this.action, [this.ownerUid]);

  final LegacyDbAction action;

  /// Set iff [action] is [LegacyDbAction.moveToOwner].
  final String? ownerUid;
}

/// PURE owner-attribution rule (unit-tested in isolation). Verbatim from the
/// audit §3:
///
/// > The legacy DB is assigned to `prefs.localProfileOwnerUid` if set; else
/// > to the currently-signed-in uid at migration time if signed in; else it
/// > is parked, unclaimed — never assigned to a future sign-in.
///
/// Claiming for the *currently signed-in* user is NOT the claim-for-next-user
/// bug: the legacy data was that user's live working set at upgrade time, and
/// the v1.1.x onboarding gate would have claimed it for that same uid on the
/// same launch anyway. Once parked, the decision is final (the done flag
/// short-circuits every later run), so no future sign-in can inherit it.
LegacyDbDecision decideLegacyDbMigration({
  required bool legacyExists,
  required String? recordedOwnerUid,
  required String? signedInUid,
}) {
  if (!legacyExists) return const LegacyDbDecision(LegacyDbAction.none);
  if (recordedOwnerUid != null) {
    return LegacyDbDecision(LegacyDbAction.moveToOwner, recordedOwnerUid);
  }
  if (signedInUid != null) {
    return LegacyDbDecision(LegacyDbAction.moveToOwner, signedInUid);
  }
  return const LegacyDbDecision(LegacyDbAction.park);
}

class IsarUidMigration {
  /// Single mechanism switch. `false` = primary file move — VALID because the
  /// instance name ≡ file name in Isar 3.1.0+1 (`Isar.path` is
  /// `'$directory/$name.isar'`; the name is only a path/registry key, never
  /// embedded in the file). `true` = link-aware row-copy fallback; flip only
  /// after device-verifying it, since it must reconstruct the six forward
  /// IsarLinks relations by hand.
  static const bool kUseRowCopyFallback = false;

  /// Executes the migration. Returns true when the legacy DB's fate is
  /// settled (including "nothing to do"); false when this launch should fall
  /// back to opening the legacy 'default' instance (identical to v1.1.x
  /// behavior — no worse than before) and retry next launch.
  static Future<bool> run({
    required SharedPreferences prefs,
    required String? signedInUid,
    required String? recordedOwnerUid,
    required String directory,
  }) async {
    if (prefs.getBool(isarUidMigrationDoneKey) ?? false) return true;

    try {
      final legacy = File('$directory/${Isar.defaultName}.isar');
      final decision = decideLegacyDbMigration(
        legacyExists: legacy.existsSync(),
        recordedOwnerUid: recordedOwnerUid,
        signedInUid: signedInUid,
      );

      switch (decision.action) {
        case LegacyDbAction.none:
          // Fresh install, or recovery from a kill between move and flag.
          await _markDone(prefs, owner: null);
          return true;

        case LegacyDbAction.park:
          // Signed out with an unattributable legacy DB (rare: pre-owner-key
          // build upgraded while signed out). Park it forever — assigning it
          // to whoever signs in NEXT is exactly the cross-account bug this
          // batch exists to kill.
          AppLogger.log(
              'Isar uid migration: legacy DB has no attributable owner — '
              'parked unclaimed (will never be auto-claimed)');
          await _markDone(prefs, owner: kParkedOwner);
          return true;

        case LegacyDbAction.moveToOwner:
          final owner = decision.ownerUid!;
          final targetName = IsarService.instanceNameForUid(owner);
          final target = File('$directory/$targetName.isar');

          if (target.existsSync()) {
            // Exotic: both legacy and target exist (kill + attribution change
            // between runs). Never overwrite the newer per-uid data — park
            // the legacy file instead.
            AppLogger.error(
                'Isar uid migration: $targetName.isar already exists next to '
                'the legacy DB — parking the legacy DB, not overwriting');
            await _markDone(prefs, owner: kParkedOwner);
            return true;
          }

          if (kUseRowCopyFallback) {
            await _rowCopy(directory: directory, ownerUid: owner);
          } else {
            await _moveFile(legacy: legacy, target: target);
          }

          // Verify before flagging: target present, legacy gone.
          if (!target.existsSync() || legacy.existsSync()) {
            throw StateError(
                'post-migration verification failed (target exists: '
                '${target.existsSync()}, legacy exists: '
                '${legacy.existsSync()})');
          }
          await _markDone(prefs, owner: owner);
          AppLogger.log(
              'Isar uid migration: legacy DB migrated to $targetName');
          return true;
      }
    } catch (e, st) {
      AppLogger.error(
          'Isar uid migration failed — using the legacy instance this '
          'launch, retrying next launch',
          error: e,
          stack: st);
      return false;
    }
  }

  /// Flag ordering is the kill-safety contract: owner first, done LAST.
  static Future<void> _markDone(SharedPreferences prefs,
      {required String? owner}) async {
    if (owner != null) {
      await prefs.setString(isarUidMigrationOwnerKey, owner);
    }
    await prefs.setBool(isarUidMigrationDoneKey, true);
  }

  /// Primary mechanism: rename the whole mdbx file — atomic on APFS, moves
  /// rows AND link tables intact. Stale lock files are deleted first (Isar
  /// recreates them on open).
  static Future<void> _moveFile({
    required File legacy,
    required File target,
  }) async {
    final legacyLock = File('${legacy.path}.lock');
    if (legacyLock.existsSync()) await legacyLock.delete();
    final targetLock = File('${target.path}.lock');
    if (targetLock.existsSync()) await targetLock.delete();
    await legacy.rename(target.path);
  }

  // ── Row-copy fallback ──────────────────────────────────────────────────
  //
  // Copies every collection with ids preserved (so a killed run re-copies
  // idempotently — putAll overwrites the same ids), reconstructs the six
  // FORWARD IsarLinks relations (backlinks are derived by Isar), verifies
  // per-collection counts + the wallet's coins value explicitly, and only
  // then deletes the source via close(deleteFromDisk: true).

  static Future<void> _rowCopy({
    required String directory,
    required String ownerUid,
  }) async {
    final src = await Isar.open(IsarService.schemas,
        directory: directory, name: Isar.defaultName);
    final dst = await Isar.open(IsarService.schemas,
        directory: directory, name: IsarService.instanceNameForUid(ownerUid));
    var verified = false;
    try {
      // 1. Rows — every collection, ids preserved, counts verified inline.
      await _copyVerified<UserProfile>(src, dst, 'UserProfile');
      await _copyVerified<Workout>(src, dst, 'Workout');
      await _copyVerified<WorkoutExercise>(src, dst, 'WorkoutExercise');
      await _copyVerified<WorkoutSet>(src, dst, 'WorkoutSet');
      await _copyVerified<NutritionLog>(src, dst, 'NutritionLog');
      await _copyVerified<Meal>(src, dst, 'Meal');
      await _copyVerified<FoodEntry>(src, dst, 'FoodEntry');
      await _copyVerified<AIMessage>(src, dst, 'AIMessage');
      await _copyVerified<WeightEntry>(src, dst, 'WeightEntry');
      await _copyVerified<OnboardingProgress>(src, dst, 'OnboardingProgress');
      await _copyVerified<CompletedDay>(src, dst, 'CompletedDay');
      await _copyVerified<CustomMealPlan>(src, dst, 'CustomMealPlan');
      await _copyVerified<CustomMealPlanMeal>(src, dst, 'CustomMealPlanMeal');
      await _copyVerified<CustomMealPlanFood>(src, dst, 'CustomMealPlanFood');
      await _copyVerified<PersonalRecord>(src, dst, 'PersonalRecord');
      await _copyVerified<SavedMeal>(src, dst, 'SavedMeal');
      await _copyVerified<SavedMealItem>(src, dst, 'SavedMealItem');
      await _copyVerified<Supplement>(src, dst, 'Supplement');
      await _copyVerified<SupplementLog>(src, dst, 'SupplementLog');
      await _copyVerified<UserThemeState>(src, dst, 'UserThemeState');
      await _copyVerified<CachedMenuItem>(src, dst, 'CachedMenuItem');
      await _copyVerified<UserRank>(src, dst, 'UserRank');
      await _copyVerified<SavedWorkoutTemplate>(
          src, dst, 'SavedWorkoutTemplate');

      // 2. Forward links (backlinks derive automatically).
      await _relink<Workout, WorkoutExercise>(
          src, dst, (w) => w.exercises, (w) => w.id, (e) => e.id);
      await _relink<WorkoutExercise, WorkoutSet>(
          src, dst, (e) => e.sets, (e) => e.id, (s) => s.id);
      await _relink<NutritionLog, Meal>(
          src, dst, (n) => n.meals, (n) => n.id, (m) => m.id);
      await _relink<Meal, FoodEntry>(
          src, dst, (m) => m.foodEntries, (m) => m.id, (f) => f.id);
      await _relink<CustomMealPlan, CustomMealPlanMeal>(
          src, dst, (p) => p.meals, (p) => p.id, (m) => m.id);
      await _relink<CustomMealPlanMeal, CustomMealPlanFood>(
          src, dst, (m) => m.foods, (m) => m.id, (f) => f.id);

      // 3. The coins wallet, explicitly — the one value that must never be
      // corrupted by this migration.
      final srcCoins = (await src.collection<UserThemeState>().get(1))?.coins;
      final dstCoins = (await dst.collection<UserThemeState>().get(1))?.coins;
      if (srcCoins != dstCoins) {
        throw StateError('row-copy verification failed for the coins wallet: '
            'src=$srcCoins dst=$dstCoins');
      }
      verified = true;
    } finally {
      // Source is deleted ONLY after verification; on failure both DBs stay
      // on disk for the next attempt.
      await src.close(deleteFromDisk: verified);
      await dst.close();
    }
  }

  /// Copies all of [T]'s rows from [src] to [dst] (ids preserved) and
  /// verifies the destination count matches.
  static Future<void> _copyVerified<T>(Isar src, Isar dst, String label) async {
    final rows = await src.collection<T>().where().findAll();
    await dst.writeTxn(() async {
      await dst.collection<T>().putAll(rows);
    });
    final dstCount = await dst.collection<T>().count();
    if (dstCount != rows.length) {
      throw StateError('row-copy verification failed for $label: '
          'src=${rows.length} dst=$dstCount');
    }
  }

  /// Re-establishes one forward IsarLinks relation on the destination: for
  /// every source parent, loads its linked child ids and adds the same ids on
  /// the destination copy (valid because the row copy preserved ids).
  static Future<void> _relink<P, C>(
    Isar src,
    Isar dst,
    IsarLinks<C> Function(P parent) linksOf,
    Id Function(P parent) parentIdOf,
    Id Function(C child) childIdOf,
  ) async {
    final srcParents = await src.collection<P>().where().findAll();
    for (final srcParent in srcParents) {
      final srcLinks = linksOf(srcParent);
      await srcLinks.load();
      if (srcLinks.isEmpty) continue;
      final childIds = srcLinks.map(childIdOf).toList();

      final dstParent = await dst.collection<P>().get(parentIdOf(srcParent));
      if (dstParent == null) continue;
      final children =
          (await dst.collection<C>().getAll(childIds)).whereType<C>().toList();
      await dst.writeTxn(() async {
        final links = linksOf(dstParent)..addAll(children);
        await links.save();
      });
    }
  }
}
