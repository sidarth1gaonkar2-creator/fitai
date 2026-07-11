import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitai/core/database/isar_uid_migration.dart' show kParkedOwner;
import 'package:fitai/core/utils/scoped_prefs.dart';

/// Tests for the global→uid-scoped SharedPreferences migration
/// (docs/uid-scoping-audit.md §3, prefs half): the shared §3 owner
/// attribution rule, kill-safety (sticky owner, copy-then-delete,
/// flag-set-last), and the account-deletion teardown helper.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  group('scopedKey', () {
    test('produces the proven <base>_<uid> suffix pattern', () {
      expect(scopedKey('gym_streak_current', 'abc123'),
          'gym_streak_current_abc123');
      expect(scopedKey('hidden_posts', 'u1'), 'hidden_posts_u1');
    });
  });

  group('PrefsUidMigration.run — §3 owner attribution', () {
    test('recorded owner wins — even when a DIFFERENT user is signed in',
        () async {
      final prefs = await prefsWith({
        'gym_streak_current': 7,
        'training_schedule_configured': true,
        'morning_motivation_time': '06:30',
      });

      await PrefsUidMigration.run(
        prefs: prefs,
        signedInUid: 'B',
        recordedOwnerUid: 'A',
      );

      // Values moved to A's keys, types preserved, globals deleted.
      expect(prefs.getInt(scopedKey('gym_streak_current', 'A')), 7);
      expect(
          prefs.getBool(scopedKey('training_schedule_configured', 'A')), isTrue);
      expect(prefs.getString(scopedKey('morning_motivation_time', 'A')),
          '06:30');
      expect(prefs.containsKey('gym_streak_current'), isFalse);
      expect(prefs.containsKey('training_schedule_configured'), isFalse);
      expect(prefs.containsKey('morning_motivation_time'), isFalse);
      // Nothing landed under B.
      expect(prefs.getKeys().where((k) => k.endsWith('_B')), isEmpty);
      expect(prefs.getBool(prefsUidMigrationDoneKey), isTrue);
      expect(prefs.getString(prefsUidMigrationOwnerKey), 'A');
    });

    test('no recorded owner + signed in → claimed for the signed-in uid',
        () async {
      final prefs = await prefsWith({'gym_streak_current': 3});

      await PrefsUidMigration.run(
        prefs: prefs,
        signedInUid: 'B',
        recordedOwnerUid: null,
      );

      expect(prefs.getInt(scopedKey('gym_streak_current', 'B')), 3);
      expect(prefs.containsKey('gym_streak_current'), isFalse);
      expect(prefs.getString(prefsUidMigrationOwnerKey), 'B');
    });

    test('no owner at all → globals parked unclaimed, NEVER claimed later',
        () async {
      final prefs = await prefsWith({'gym_streak_current': 9});

      await PrefsUidMigration.run(
        prefs: prefs,
        signedInUid: null,
        recordedOwnerUid: null,
      );

      // Globals stay in place; no scoped copy exists; fate is settled.
      expect(prefs.getInt('gym_streak_current'), 9);
      expect(prefs.getKeys().where((k) => k.startsWith('gym_streak_current_')),
          isEmpty);
      expect(prefs.getBool(prefsUidMigrationDoneKey), isTrue);
      expect(prefs.getString(prefsUidMigrationOwnerKey), kParkedOwner);

      // A user signing in on a later launch must NOT inherit the parked keys.
      await PrefsUidMigration.run(
        prefs: prefs,
        signedInUid: 'C',
        recordedOwnerUid: null,
      );
      expect(prefs.getInt('gym_streak_current'), 9);
      expect(prefs.getKeys().where((k) => k.endsWith('_C')), isEmpty);
    });

    test('nothing to migrate → flag set immediately, no owner recorded',
        () async {
      final prefs = await prefsWith({'theme_mode': 'dark'});

      await PrefsUidMigration.run(
        prefs: prefs,
        signedInUid: 'A',
        recordedOwnerUid: 'A',
      );

      expect(prefs.getBool(prefsUidMigrationDoneKey), isTrue);
      expect(prefs.getString(prefsUidMigrationOwnerKey), isNull);
    });

    test('global-ok device keys are never touched', () async {
      final prefs = await prefsWith({
        'gym_streak_current': 2,
        'theme_mode': 'dark',
        'unit_system': 'imperial',
        'tutorial_completed': true,
        'pr_migration_done': true,
      });

      await PrefsUidMigration.run(
        prefs: prefs,
        signedInUid: 'A',
        recordedOwnerUid: null,
      );

      expect(prefs.getString('theme_mode'), 'dark');
      expect(prefs.getString('unit_system'), 'imperial');
      expect(prefs.getBool('tutorial_completed'), isTrue);
      expect(prefs.getBool('pr_migration_done'), isTrue);
      expect(prefs.getInt(scopedKey('gym_streak_current', 'A')), 2);
    });

    test('whole notif_* family moves in one pass (incl. JSON strings)',
        () async {
      final prefs = await prefsWith({
        'notif_workout_enabled': true,
        'notif_workout_days': '[1,3,5]',
        'notif_workout_hour': 6,
        'notif_rest_days': '[7]',
        'notif_challenge_enabled': false,
      });

      await PrefsUidMigration.run(
        prefs: prefs,
        signedInUid: null,
        recordedOwnerUid: 'A',
      );

      expect(prefs.getBool(scopedKey('notif_workout_enabled', 'A')), isTrue);
      expect(prefs.getString(scopedKey('notif_workout_days', 'A')), '[1,3,5]');
      expect(prefs.getInt(scopedKey('notif_workout_hour', 'A')), 6);
      expect(prefs.getString(scopedKey('notif_rest_days', 'A')), '[7]');
      expect(prefs.getBool(scopedKey('notif_challenge_enabled', 'A')), isFalse);
      expect(prefs.getKeys().where(uidScopedPrefsBaseKeys.contains), isEmpty);
    });
  });

  group('PrefsUidMigration.run — idempotency & kill-safety', () {
    test('done flag short-circuits every later run', () async {
      final prefs = await prefsWith({
        prefsUidMigrationDoneKey: true,
        'gym_streak_current': 5, // would-be migratable, must stay untouched
      });

      await PrefsUidMigration.run(
        prefs: prefs,
        signedInUid: 'A',
        recordedOwnerUid: 'A',
      );

      expect(prefs.getInt('gym_streak_current'), 5);
      expect(prefs.containsKey(scopedKey('gym_streak_current', 'A')), isFalse);
    });

    test(
        'killed mid-migration: sticky owner finishes the SAME migration '
        'even if the auth state changed before the retry', () async {
      // Simulates: first run decided owner A, moved one key, then was killed
      // before the flag was set. By the next launch, B is signed in.
      final prefs = await prefsWith({
        prefsUidMigrationOwnerKey: 'A',
        scopedKey('gym_streak_current', 'A'): 4, // already moved
        'training_schedule_configured': true, // not yet moved
      });

      await PrefsUidMigration.run(
        prefs: prefs,
        signedInUid: 'B',
        recordedOwnerUid: null,
      );

      // The remaining key joins A — not B.
      expect(
          prefs.getBool(scopedKey('training_schedule_configured', 'A')), isTrue);
      expect(prefs.getInt(scopedKey('gym_streak_current', 'A')), 4);
      expect(prefs.getKeys().where((k) => k.endsWith('_B')), isEmpty);
      expect(prefs.getBool(prefsUidMigrationDoneKey), isTrue);
    });

    test(
        'copy-then-delete per key: a re-run never overwrites a scoped value '
        'whose global was already deleted', () async {
      // First run moved gym_streak_current (global deleted), was killed, and
      // the user then earned streak days (scoped value advanced to 10).
      final prefs = await prefsWith({
        prefsUidMigrationOwnerKey: 'A',
        scopedKey('gym_streak_current', 'A'): 10,
        'notif_workout_hour': 6, // still global from the interrupted run
      });

      await PrefsUidMigration.run(
        prefs: prefs,
        signedInUid: 'A',
        recordedOwnerUid: 'A',
      );

      expect(prefs.getInt(scopedKey('gym_streak_current', 'A')), 10); // kept
      expect(prefs.getInt(scopedKey('notif_workout_hour', 'A')), 6);
      expect(prefs.getBool(prefsUidMigrationDoneKey), isTrue);
    });
  });

  group('removeUidScopedPrefs (account-deletion teardown)', () {
    test("removes only the deleted account's keys", () async {
      final prefs = await prefsWith({
        scopedKey('gym_streak_current', 'A'): 7,
        scopedKey('saved_quick_adds_v1', 'A'): '[]',
        scopedKey('gym_streak_current', 'B'): 2,
        'theme_mode': 'dark',
      });

      await removeUidScopedPrefs(prefs, 'A');

      expect(prefs.getKeys().where((k) => k.endsWith('_A')), isEmpty);
      expect(prefs.getInt(scopedKey('gym_streak_current', 'B')), 2);
      expect(prefs.getString('theme_mode'), 'dark');
    });
  });
}
