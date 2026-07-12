import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:fitai/features/themes/domain/theme_gate.dart';
import 'package:fitai/features/themes/domain/theme_registry.dart';
import 'package:fitai/features/themes/providers/theme_providers.dart';
import 'package:fitai/models/user_theme_state.dart';

/// The five standard coin themes Airborne unlocks (spec list — hardcoded on
/// purpose so a registry reclassification fails loudly here).
const _standardIds = {'emerald', 'sunset', 'crimson', 'ocean', 'lavender'};
const _premiumIds = {'neon_pulse', 'stealth'};

// ── In-memory Isar stand-in ──────────────────────────────────────────────────
// UserThemeStateNotifier only touches the singleton row: getSync(1) on load,
// put() inside writeTxn on persist. A tiny fake keeps the persistence path
// real without native Isar libs.

class _FakeThemeCollection extends Fake
    implements IsarCollection<UserThemeState> {
  UserThemeState? row;

  @override
  UserThemeState? getSync(Id id) => row;

  @override
  Future<Id> put(UserThemeState object) async {
    row = object;
    return object.id;
  }
}

class _FakeIsar extends Fake implements Isar {
  _FakeIsar(this.themes);
  final _FakeThemeCollection themes;

  @override
  IsarCollection<T> collection<T>() => themes as IsarCollection<T>;

  @override
  Future<T> writeTxn<T>(Future<T> Function() callback, {bool silent = false}) =>
      callback();
}

UserThemeState _seed({int coins = 50, List<String>? owned}) =>
    UserThemeState()
      ..id = 1
      ..equippedThemeId = 'midnight_blue'
      ..ownedThemeIds = owned ?? const ['midnight_blue', 'slate']
      ..coins = coins
      ..gems = 0
      ..updatedAt = DateTime.utc(2026);

(UserThemeStateNotifier, _FakeThemeCollection) _notifier(
    {int coins = 50, List<String>? owned}) {
  final collection = _FakeThemeCollection()
    ..row = _seed(coins: coins, owned: owned);
  return (UserThemeStateNotifier(_FakeIsar(collection)), collection);
}

void main() {
  group('isStandardCoinTheme', () {
    test('classifies the registry exactly: paid + non-premium only', () {
      final standard = {
        for (final t in themeRegistry)
          if (isStandardCoinTheme(t)) t.id,
      };
      expect(standard, _standardIds);
      for (final t in themeRegistry) {
        if (t.price == 0 || t.isPremium) {
          expect(isStandardCoinTheme(t), isFalse, reason: t.id);
        }
      }
    });
  });

  group('unlockedThemeIds', () {
    const owned = {'midnight_blue', 'slate'};

    test('without Airborne the owned set passes through untouched', () {
      expect(unlockedThemeIds(owned: owned, airborneActive: false), owned);
    });

    test('with Airborne adds exactly the standard coin themes', () {
      final unlocked = unlockedThemeIds(owned: owned, airborneActive: true);
      expect(unlocked, owned.union(_standardIds));
    });

    test('premium themes are never Airborne-unlocked', () {
      final unlocked = unlockedThemeIds(owned: owned, airborneActive: true);
      for (final id in _premiumIds) {
        expect(unlocked, isNot(contains(id)));
      }
    });

    test('coin-owned premium themes survive regardless of Airborne', () {
      for (final airborne in [true, false]) {
        final unlocked = unlockedThemeIds(
          owned: {...owned, 'stealth'},
          airborneActive: airborne,
        );
        expect(unlocked, contains('stealth'));
      }
    });
  });

  group('UserThemeStateNotifier — Airborne equip vs coin ownership', () {
    final emerald = themeById('emerald');

    test('equip(markOwned: false) equips WITHOUT granting ownership or '
        'touching coins (Airborne price bypass)', () async {
      final (notifier, collection) = _notifier(coins: 50);
      final ok = await notifier.equip('emerald', markOwned: false);
      expect(ok, isTrue);
      expect(notifier.state.equippedThemeId, 'emerald');
      expect(notifier.state.ownedThemeIds, isNot(contains('emerald')),
          reason: 'a lapsed subscription must re-lock the theme');
      expect(notifier.state.coins, 50, reason: 'wallet is sacred');
      // Persisted row agrees with in-memory state.
      expect(collection.row?.equippedThemeId, 'emerald');
      expect(collection.row?.ownedThemeIds, isNot(contains('emerald')));
    });

    test('default equip still marks ownership (pre-existing behavior)',
        () async {
      final (notifier, _) = _notifier();
      await notifier.equip('emerald');
      expect(notifier.state.ownedThemeIds, contains('emerald'));
    });

    test('coin purchase still spends the wallet and grants ownership',
        () async {
      final (notifier, _) = _notifier(coins: 600);
      final result = await notifier.purchase(emerald);
      expect(result, PurchaseResult.success);
      expect(notifier.state.coins, 600 - emerald.price);
      expect(notifier.state.ownedThemeIds, contains('emerald'));
      expect(notifier.state.equippedThemeId, 'emerald');
    });

    test('insufficient coins still refuses the purchase', () async {
      final (notifier, _) = _notifier(coins: 100);
      final result = await notifier.purchase(emerald);
      expect(result, PurchaseResult.insufficientFunds);
      expect(notifier.state.coins, 100);
      expect(notifier.state.ownedThemeIds, isNot(contains('emerald')));
    });
  });
}
