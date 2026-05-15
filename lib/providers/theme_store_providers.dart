import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/theme_store.dart';
import '../services/currency_service.dart';
import 'unit_system_provider.dart';

/// Single CurrencyService instance backed by the app-wide SharedPreferences.
final currencyServiceProvider = Provider<CurrencyService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CurrencyService(prefs);
});

// ───────────────────────────────────────────────────────────────────────────
// Coin balance — exposed as a StateNotifier so the dashboard / store update
// reactively when coins are earned or spent.
// ───────────────────────────────────────────────────────────────────────────

class CoinBalanceNotifier extends StateNotifier<int> {
  CoinBalanceNotifier(this._service) : super(_service.coins);

  final CurrencyService _service;

  Future<void> award(int amount, String reason) async {
    state = await _service.awardCoins(amount: amount, reason: reason);
  }

  Future<bool> spend(int amount, String reason) async {
    final ok = await _service.spendCoins(amount: amount, reason: reason);
    if (ok) state = _service.coins;
    return ok;
  }

  void refresh() => state = _service.coins;
}

final coinBalanceProvider =
    StateNotifierProvider<CoinBalanceNotifier, int>((ref) {
  return CoinBalanceNotifier(ref.read(currencyServiceProvider));
});

final gemBalanceProvider = Provider<int>((ref) {
  return ref.watch(currencyServiceProvider).gems;
});

// ───────────────────────────────────────────────────────────────────────────
// Theme ownership + active theme — both persisted via SharedPreferences.
// We avoid Isar for these to sidestep the v3 codegen issues; the data is
// a small list of strings + one active-id string.
// ───────────────────────────────────────────────────────────────────────────

class ThemeOwnership extends StateNotifier<Set<String>> {
  ThemeOwnership(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'purchased_theme_ids';

  static Set<String> _load(SharedPreferences prefs) {
    final list = prefs.getStringList(_key) ?? const <String>[];
    return {defaultTheme.id, ...list};
  }

  bool owns(String themeId) =>
      themeId == defaultTheme.id || state.contains(themeId);

  Future<void> add(String themeId) async {
    if (state.contains(themeId)) return;
    final next = {...state, themeId};
    state = next;
    await _prefs.setStringList(
      _key,
      next.where((id) => id != defaultTheme.id).toList(),
    );
  }
}

final themeOwnershipProvider =
    StateNotifierProvider<ThemeOwnership, Set<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeOwnership(prefs);
});

class ActiveThemeNotifier extends StateNotifier<String> {
  ActiveThemeNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'active_theme_id';

  static String _load(SharedPreferences prefs) {
    return prefs.getString(_key) ?? defaultTheme.id;
  }

  Future<void> setActive(String themeId) async {
    state = themeId;
    await _prefs.setString(_key, themeId);
  }
}

final activeThemeIdProvider =
    StateNotifierProvider<ActiveThemeNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ActiveThemeNotifier(prefs);
});

/// Resolved [AppThemePack] for the currently-active theme.
final activeThemeProvider = Provider<AppThemePack>((ref) {
  final id = ref.watch(activeThemeIdProvider);
  return themeById(id);
});
