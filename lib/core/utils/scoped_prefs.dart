import 'package:shared_preferences/shared_preferences.dart';

import '../database/isar_uid_migration.dart'
    show LegacyDbAction, decideLegacyDbMigration, kParkedOwner;
import 'logger.dart';

/// Uniform uid-scoped SharedPreferences key: `<base>_<uid>` — the proven
/// `hidden_posts_$uid` pattern, adopted for every per-user pref
/// (docs/uid-scoping-audit.md §5). THE one place the scheme is defined.
String scopedKey(String base, String uid) => '${base}_$uid';

/// Every per-user (must-scope) prefs base key (audit §1b). This list is the
/// single source of truth for (a) the one-time global→scoped migration below
/// and (b) account-deletion teardown ([removeUidScopedPrefs]). Keys born
/// scoped (`hidden_posts_<uid>`) and device-level keys (theme, units,
/// tutorial, health_*, caches, migration flags) deliberately do NOT appear.
const List<String> uidScopedPrefsBaseKeys = [
  // Gym streak (drives the coin multiplier)
  'gym_streak_current',
  'gym_streak_last_awarded_epoch_day',
  // Training schedule opt-in
  'training_schedule_configured',
  // Notification settings — the whole notif_* family
  // (notif_workout_days doubles as the streak schedule source of truth)
  'notif_workout_enabled',
  'notif_workout_days',
  'notif_workout_hour',
  'notif_workout_minute',
  'notif_breakfast_enabled',
  'notif_breakfast_hour',
  'notif_breakfast_minute',
  'notif_lunch_enabled',
  'notif_lunch_hour',
  'notif_lunch_minute',
  'notif_dinner_enabled',
  'notif_dinner_hour',
  'notif_dinner_minute',
  'notif_water_enabled',
  'notif_streak_enabled',
  'notif_pr_enabled',
  'notif_supplement_enabled',
  'notif_rest_days',
  'notif_challenge_enabled',
  // Rank-up celebration once-only marker
  'last_celebrated_rank_index',
  // Nutrition quick-add presets
  'saved_quick_adds_v1',
  // Custom exercise → rank-group registry
  'custom_exercise_groups_v1',
  // Drill sergeant / morning motivation voice prefs
  'drill_sergeant_enabled',
  'drill_sergeant_intensity',
  'drill_sergeant_full_metal',
  'morning_motivation_enabled',
  'morning_motivation_time',
];

/// Deletes every uid-scoped pref belonging to [uid] (account-deletion
/// teardown, audit §4). Device-level keys and other accounts' keys survive.
/// `hidden_posts_<uid>` is removed separately at the call site (its key
/// helper lives with the community providers).
Future<void> removeUidScopedPrefs(SharedPreferences prefs, String uid) async {
  for (final base in uidScopedPrefsBaseKeys) {
    await prefs.remove(scopedKey(base, uid));
  }
}

/// Set once the global keys' fate is settled (moved, parked, or absent).
const String prefsUidMigrationDoneKey = 'prefs_uid_migration_done';

/// The owner the migration decided on: a uid, [kParkedOwner], or unset when
/// there was nothing to migrate. Written BEFORE any key moves, so a re-run
/// after a mid-migration kill finishes the SAME migration under the same
/// owner instead of re-deciding against a possibly different auth state.
const String prefsUidMigrationOwnerKey = 'prefs_uid_migration_owner';

/// One-time migration of the legacy GLOBAL per-user prefs into the uid-scoped
/// key scheme (docs/uid-scoping-audit.md §3, prefs half). Shares the §3 owner
/// attribution rule with the Isar move verbatim ([decideLegacyDbMigration]):
/// recorded `localProfileOwnerUid` wins; else the currently-signed-in uid
/// claims; else the globals are left in place, unclaimed forever — never
/// assigned to a future sign-in.
///
/// Kill-safe and idempotent: the owner decision is persisted first (sticky),
/// each key is copy-then-delete (a deleted global can never be re-copied over
/// a scoped value the user has since changed), and the done flag is set LAST.
class PrefsUidMigration {
  /// [recordedOwnerUid] is `prefs.localProfileOwnerUid` (the v1.1.x owner
  /// marker; retired in PR-C). Throws only on prefs-layer failures — the
  /// caller logs and retries next launch (scoped readers see defaults until
  /// then; no data is lost, the globals are still in place).
  static Future<void> run({
    required SharedPreferences prefs,
    required String? signedInUid,
    required String? recordedOwnerUid,
  }) async {
    if (prefs.getBool(prefsUidMigrationDoneKey) ?? false) return;

    final present =
        uidScopedPrefsBaseKeys.where(prefs.containsKey).toList(growable: false);

    var owner = prefs.getString(prefsUidMigrationOwnerKey);
    if (owner == null) {
      final decision = decideLegacyDbMigration(
        legacyExists: present.isNotEmpty,
        recordedOwnerUid: recordedOwnerUid,
        signedInUid: signedInUid,
      );
      owner = switch (decision.action) {
        LegacyDbAction.none => null,
        LegacyDbAction.moveToOwner => decision.ownerUid,
        LegacyDbAction.park => kParkedOwner,
      };
      // Sticky decision BEFORE the first move (see prefsUidMigrationOwnerKey).
      if (owner != null) {
        await prefs.setString(prefsUidMigrationOwnerKey, owner);
      }
    }

    if (owner != null && owner != kParkedOwner) {
      for (final base in present) {
        if (await _copy(prefs, base, scopedKey(base, owner))) {
          await prefs.remove(base);
        } else {
          // Should be unreachable (all values are our own bool/int/String);
          // leave the global in place rather than lose it.
          AppLogger.error(
              'Prefs uid migration: unsupported value type for "$base" — '
              'left as a global key');
        }
      }
    }

    // LAST — parked and nothing-to-migrate are settled fates too.
    await prefs.setBool(prefsUidMigrationDoneKey, true);
  }

  /// Type-preserving copy of one pref. Returns false for a value type
  /// SharedPreferences can't round-trip (never expected for our keys).
  static Future<bool> _copy(
      SharedPreferences prefs, String from, String to) async {
    final value = prefs.get(from);
    if (value is bool) {
      await prefs.setBool(to, value);
    } else if (value is int) {
      await prefs.setInt(to, value);
    } else if (value is double) {
      await prefs.setDouble(to, value);
    } else if (value is String) {
      await prefs.setString(to, value);
    } else if (value is List) {
      // getStringList surfaces as List<Object?>; ours only ever hold strings.
      await prefs.setStringList(to, value.cast<String>());
    } else {
      return false;
    }
    return true;
  }
}
