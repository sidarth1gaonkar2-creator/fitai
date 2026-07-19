import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../models/user_theme_state.dart';
import '../../../providers/entitlement_providers.dart';
import '../../../providers/isar_provider.dart';
import '../domain/app_theme_data.dart';
import '../domain/theme_gate.dart';
import '../domain/theme_registry.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public providers
// ─────────────────────────────────────────────────────────────────────────────

/// The full UserThemeState row (singleton). Watching this gets you reactive
/// updates whenever ownership/equipped/balances change.
final userThemeStateProvider =
    StateNotifierProvider<UserThemeStateNotifier, UserThemeState>((ref) {
  final isar = ref.watch(isarProvider);
  return UserThemeStateNotifier(isar);
});

/// Resolved [AppThemeData] for the currently-equipped theme. Cheap to watch
/// — falls back to [defaultTheme] if the equipped ID was ever removed from
/// the registry.
final activeThemeProvider = Provider<AppThemeData>((ref) {
  final state = ref.watch(userThemeStateProvider);
  return themeById(state.equippedThemeId);
});

/// Set of all owned theme IDs (including the implicit default and any
/// [AppThemeData.ownedByDefault] grants — the default plus cash skins in
/// preview while their IAP is deferred). Ownership == bought with coins or
/// granted free; see [unlockedThemesProvider] for what the user can equip.
final ownedThemesProvider = Provider<Set<String>>((ref) {
  final state = ref.watch(userThemeStateProvider);
  return {
    defaultTheme.id,
    for (final t in themeRegistry)
      if (t.ownedByDefault) t.id,
    ...state.ownedThemeIds,
  };
});

/// Everything the user can equip right now: coin-owned themes plus — while
/// Airborne is active — every standard coin theme. Airborne bypasses the coin
/// price only; it never writes ownership or touches the wallet, so a lapsed
/// subscription re-locks whatever wasn't bought with coins.
final unlockedThemesProvider = Provider<Set<String>>((ref) {
  return unlockedThemeIds(
    owned: ref.watch(ownedThemesProvider),
    airborneActive: ref.watch(airborneActiveProvider),
  );
});

/// Coin balance shortcut — watch this for the chip in the store header.
final coinBalanceProvider = Provider<int>((ref) {
  return ref.watch(userThemeStateProvider).coins;
});

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// All writes to the theme state funnel through here. Each mutating method
/// updates the in-memory state immediately (for snappy UI), then persists to
/// Isar in a single write transaction. The Isar write is awaited so callers
/// can show toasts / dialogs only after the change is durable.
class UserThemeStateNotifier extends StateNotifier<UserThemeState> {
  UserThemeStateNotifier(this._isar) : super(_load(_isar));

  final Isar _isar;

  /// Loads the singleton row synchronously. On first launch (or after
  /// `isar.clear()`) the row is missing — we return defaults and lazily
  /// write them on the next mutation. We don't write defaults eagerly here
  /// because constructors can't await; the user simply has the defaults
  /// in memory until they do something that triggers a save.
  static UserThemeState _load(Isar isar) {
    final existing = isar.userThemeStates.getSync(1);
    if (existing != null) return existing;
    return UserThemeState.defaults();
  }

  /// Equips [themeId] and — when [markOwned] — records it as owned (no-op if
  /// already owned). Returns true on success, false if the theme isn't in the
  /// registry.
  ///
  /// Pass `markOwned: false` for Airborne-unlocked equips: the subscription
  /// bypasses the coin price but must never grant permanent ownership, or a
  /// lapsed subscription would leave the theme unlocked forever.
  Future<bool> equip(String themeId, {bool markOwned = true}) async {
    if (!_existsInRegistry(themeId)) return false;
    final next = _clone(state)
      ..equippedThemeId = themeId
      ..updatedAt = DateTime.now();
    if (markOwned && !next.ownedThemeIds.contains(themeId)) {
      next.ownedThemeIds = [...next.ownedThemeIds, themeId];
    }
    await _persist(next);
    return true;
  }

  /// Spends [theme.price] from the matching wallet and adds the theme to
  /// owned + equips it. Returns:
  ///   * `PurchaseResult.success` — bought and equipped
  ///   * `PurchaseResult.alreadyOwned` — was already owned (no-op aside
  ///     from equipping)
  ///   * `PurchaseResult.insufficientFunds` — not enough coins
  ///   * `PurchaseResult.notPurchasable` — not sold for coins at all
  Future<PurchaseResult> purchase(AppThemeData theme) async {
    // Deepest guard in the economy: a theme that isn't sold for coins can
    // never be bought here, whatever the UI does. The Airborne flagship
    // carries price 0, so without this a `coins >= price` check upstream
    // would read as "affordable" and hand it over for nothing.
    if (!isCoinPurchasable(theme) && theme.id != defaultTheme.id) {
      return PurchaseResult.notPurchasable;
    }
    if (state.ownedThemeIds.contains(theme.id) ||
        theme.id == defaultTheme.id) {
      await equip(theme.id);
      return PurchaseResult.alreadyOwned;
    }
    if (state.coins < theme.price) return PurchaseResult.insufficientFunds;

    final next = _clone(state)..coins = state.coins - theme.price;
    next.ownedThemeIds = [...next.ownedThemeIds, theme.id];
    next.equippedThemeId = theme.id;
    next.updatedAt = DateTime.now();
    await _persist(next);
    return PurchaseResult.success;
  }

  /// Adds [amount] coins to the wallet. Used by the workouts controller etc.
  /// for in-app earnings. Negative amounts are ignored — call [spendCoins]
  /// for deductions.
  Future<void> awardCoins(int amount) async {
    if (amount <= 0) return;
    final next = _clone(state)
      ..coins = state.coins + amount
      ..updatedAt = DateTime.now();
    await _persist(next);
  }

  /// Spends [amount] coins if the wallet has enough. Returns true on success.
  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return true;
    if (state.coins < amount) return false;
    final next = _clone(state)
      ..coins = state.coins - amount
      ..updatedAt = DateTime.now();
    await _persist(next);
    return true;
  }

  // ── Internal helpers ───────────────────────────────────────────────────

  bool _existsInRegistry(String themeId) {
    for (final t in themeRegistry) {
      if (t.id == themeId) return true;
    }
    return false;
  }

  UserThemeState _clone(UserThemeState src) {
    return UserThemeState()
      ..id = 1
      ..equippedThemeId = src.equippedThemeId
      ..ownedThemeIds = List.of(src.ownedThemeIds)
      ..coins = src.coins
      // `gems` is a dormant, never-surfaced field (single-currency model).
      // Copied only to satisfy the late field / preserve any legacy balance
      // until it's dropped in the planned schema bump. See user_theme_state.dart.
      ..gems = src.gems
      ..updatedAt = src.updatedAt;
  }

  Future<void> _persist(UserThemeState next) async {
    state = next;
    try {
      await _isar.writeTxn(() async {
        await _isar.userThemeStates.put(next);
      });
    } catch (e, st) {
      debugPrint('[UserThemeState] persist failed: $e\n$st');
      // Intentionally not rethrowing — UI state is already updated; a
      // failed write means the change won't survive a restart, which is
      // acceptable for a cosmetic setting.
    }
  }
}

/// Tri-state result for [UserThemeStateNotifier.purchase]. The UI uses this
/// to decide between a success toast, a "you already own this" no-op, and a
/// "not enough coins" error dialog.
enum PurchaseResult {
  success,
  alreadyOwned,
  insufficientFunds,

  /// Not sold for coins — a cash skin or the Airborne-exclusive flagship.
  notPurchasable,
}
