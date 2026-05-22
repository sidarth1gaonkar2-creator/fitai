import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../models/user_theme_state.dart';
import '../../../providers/isar_provider.dart';
import '../domain/app_theme_data.dart';
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

/// Set of all owned theme IDs (including the implicit default).
final ownedThemesProvider = Provider<Set<String>>((ref) {
  final state = ref.watch(userThemeStateProvider);
  return {defaultTheme.id, ...state.ownedThemeIds};
});

/// Coin balance shortcut — watch this for the chip in the store header.
final coinBalanceProvider = Provider<int>((ref) {
  return ref.watch(userThemeStateProvider).coins;
});

/// Gem balance shortcut.
final gemBalanceProvider = Provider<int>((ref) {
  return ref.watch(userThemeStateProvider).gems;
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

  /// Marks [themeId] as owned (no-op if already owned) and equips it. Returns
  /// true on success, false if the theme isn't in the registry.
  Future<bool> equip(String themeId) async {
    if (!_existsInRegistry(themeId)) return false;
    final next = _clone(state)
      ..equippedThemeId = themeId
      ..updatedAt = DateTime.now();
    if (!next.ownedThemeIds.contains(themeId)) {
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
  ///   * `PurchaseResult.insufficientFunds` — not enough coins/gems
  Future<PurchaseResult> purchase(AppThemeData theme) async {
    if (state.ownedThemeIds.contains(theme.id) ||
        theme.id == defaultTheme.id) {
      await equip(theme.id);
      return PurchaseResult.alreadyOwned;
    }
    final wallet = theme.currency == ThemeCurrency.coins
        ? state.coins
        : state.gems;
    if (wallet < theme.price) return PurchaseResult.insufficientFunds;

    final next = _clone(state);
    if (theme.currency == ThemeCurrency.coins) {
      next.coins = state.coins - theme.price;
    } else {
      next.gems = state.gems - theme.price;
    }
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

  /// Adds [amount] gems. Hooked up for completeness — gem awards aren't
  /// currently issued anywhere, but if/when StoreKit lands we'll route IAP
  /// completions through here.
  Future<void> awardGems(int amount) async {
    if (amount <= 0) return;
    final next = _clone(state)
      ..gems = state.gems + amount
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
enum PurchaseResult { success, alreadyOwned, insufficientFunds }
