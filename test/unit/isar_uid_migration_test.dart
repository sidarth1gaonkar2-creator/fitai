import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitai/core/database/isar_uid_migration.dart';

/// Tests for the legacy 'default'-instance → per-uid instance migration
/// (docs/uid-scoping-audit.md §3): the pure owner-attribution rule, and the
/// file-move executor's kill-safety / never-claim-for-a-future-sign-in
/// guarantees. Pure file + prefs operations — no Isar natives needed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('decideLegacyDbMigration (pure attribution rule)', () {
    test('no legacy DB → none, regardless of auth state', () {
      final d = decideLegacyDbMigration(
        legacyExists: false,
        recordedOwnerUid: 'A',
        signedInUid: 'B',
      );
      expect(d.action, LegacyDbAction.none);
      expect(d.ownerUid, isNull);
    });

    test('recorded owner wins — even when a DIFFERENT user is signed in', () {
      final d = decideLegacyDbMigration(
        legacyExists: true,
        recordedOwnerUid: 'A',
        signedInUid: 'B',
      );
      expect(d.action, LegacyDbAction.moveToOwner);
      expect(d.ownerUid, 'A');
    });

    test('unowned + signed in → claimed for the CURRENTLY signed-in uid', () {
      final d = decideLegacyDbMigration(
        legacyExists: true,
        recordedOwnerUid: null,
        signedInUid: 'B',
      );
      expect(d.action, LegacyDbAction.moveToOwner);
      expect(d.ownerUid, 'B');
    });

    test('unowned + signed out → parked, never assigned', () {
      final d = decideLegacyDbMigration(
        legacyExists: true,
        recordedOwnerUid: null,
        signedInUid: null,
      );
      expect(d.action, LegacyDbAction.park);
      expect(d.ownerUid, isNull);
    });
  });

  group('IsarUidMigration.run (file-move executor)', () {
    late Directory tempDir;
    late SharedPreferences prefs;

    File legacyFile() => File('${tempDir.path}/default.isar');
    File instanceFile(String uid) => File('${tempDir.path}/u_$uid.isar');

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('isar_uid_migration_test');
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('moves the legacy DB to the RECORDED owner, not the signed-in user',
        () async {
      legacyFile().writeAsStringSync('legacy-bytes');

      final settled = await IsarUidMigration.run(
        prefs: prefs,
        signedInUid: 'B',
        recordedOwnerUid: 'A',
        directory: tempDir.path,
      );

      expect(settled, isTrue);
      expect(legacyFile().existsSync(), isFalse);
      expect(instanceFile('A').existsSync(), isTrue);
      expect(instanceFile('A').readAsStringSync(), 'legacy-bytes');
      expect(instanceFile('B').existsSync(), isFalse);
      expect(prefs.getBool(isarUidMigrationDoneKey), isTrue);
      expect(prefs.getString(isarUidMigrationOwnerKey), 'A');
    });

    test('claims an unowned legacy DB for the currently signed-in user',
        () async {
      legacyFile().writeAsStringSync('legacy-bytes');

      final settled = await IsarUidMigration.run(
        prefs: prefs,
        signedInUid: 'B',
        recordedOwnerUid: null,
        directory: tempDir.path,
      );

      expect(settled, isTrue);
      expect(legacyFile().existsSync(), isFalse);
      expect(instanceFile('B').readAsStringSync(), 'legacy-bytes');
      expect(prefs.getString(isarUidMigrationOwnerKey), 'B');
    });

    test(
        'parks an unowned legacy DB when signed out — and NEVER claims it '
        'for a future sign-in', () async {
      legacyFile().writeAsStringSync('legacy-bytes');

      final settled = await IsarUidMigration.run(
        prefs: prefs,
        signedInUid: null,
        recordedOwnerUid: null,
        directory: tempDir.path,
      );

      expect(settled, isTrue);
      expect(legacyFile().existsSync(), isTrue, reason: 'parked in place');
      expect(prefs.getBool(isarUidMigrationDoneKey), isTrue);
      expect(prefs.getString(isarUidMigrationOwnerKey), kParkedOwner);

      // User C signs in on a later launch: the parked DB must NOT be claimed
      // (this is exactly the claim-for-next-user bug the batch kills).
      final again = await IsarUidMigration.run(
        prefs: prefs,
        signedInUid: 'C',
        recordedOwnerUid: null,
        directory: tempDir.path,
      );

      expect(again, isTrue);
      expect(legacyFile().existsSync(), isTrue, reason: 'still parked');
      expect(instanceFile('C').existsSync(), isFalse);
      expect(prefs.getString(isarUidMigrationOwnerKey), kParkedOwner);
    });

    test('fresh install: nothing to migrate → settled, flag set', () async {
      final settled = await IsarUidMigration.run(
        prefs: prefs,
        signedInUid: 'A',
        recordedOwnerUid: null,
        directory: tempDir.path,
      );

      expect(settled, isTrue);
      expect(prefs.getBool(isarUidMigrationDoneKey), isTrue);
      expect(prefs.getString(isarUidMigrationOwnerKey), isNull);
      expect(instanceFile('A').existsSync(), isFalse,
          reason: 'migration never creates instances, only moves them');
    });

    test('kill recovery: moved but unflagged → converges to done, DB intact',
        () async {
      // A previous run renamed default.isar → u_A.isar, then was killed
      // before setting the done flag.
      instanceFile('A').writeAsStringSync('already-moved');

      final settled = await IsarUidMigration.run(
        prefs: prefs,
        signedInUid: 'A',
        recordedOwnerUid: 'A',
        directory: tempDir.path,
      );

      expect(settled, isTrue);
      expect(prefs.getBool(isarUidMigrationDoneKey), isTrue);
      expect(instanceFile('A').readAsStringSync(), 'already-moved');
    });

    test('conflict: target instance already exists → parks, never overwrites',
        () async {
      legacyFile().writeAsStringSync('old-legacy');
      instanceFile('A').writeAsStringSync('newer-per-uid-data');

      final settled = await IsarUidMigration.run(
        prefs: prefs,
        signedInUid: 'A',
        recordedOwnerUid: 'A',
        directory: tempDir.path,
      );

      expect(settled, isTrue);
      expect(instanceFile('A').readAsStringSync(), 'newer-per-uid-data',
          reason: 'the newer per-uid DB must never be overwritten');
      expect(legacyFile().existsSync(), isTrue, reason: 'legacy parked');
      expect(prefs.getString(isarUidMigrationOwnerKey), kParkedOwner);
      expect(prefs.getBool(isarUidMigrationDoneKey), isTrue);
    });

    test('stale lock files are cleaned up by the move', () async {
      legacyFile().writeAsStringSync('legacy-bytes');
      File('${tempDir.path}/default.isar.lock').writeAsStringSync('lock');

      await IsarUidMigration.run(
        prefs: prefs,
        signedInUid: 'A',
        recordedOwnerUid: null,
        directory: tempDir.path,
      );

      expect(File('${tempDir.path}/default.isar.lock').existsSync(), isFalse);
      expect(instanceFile('A').existsSync(), isTrue);
    });

    test('done flag short-circuits every later run', () async {
      await prefs.setBool(isarUidMigrationDoneKey, true);
      legacyFile().writeAsStringSync('parked-forever');

      final settled = await IsarUidMigration.run(
        prefs: prefs,
        signedInUid: 'B',
        recordedOwnerUid: null,
        directory: tempDir.path,
      );

      expect(settled, isTrue);
      expect(legacyFile().existsSync(), isTrue);
      expect(instanceFile('B').existsSync(), isFalse);
    });
  });
}
