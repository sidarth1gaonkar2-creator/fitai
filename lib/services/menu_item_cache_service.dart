import 'package:isar/isar.dart';

import '../features/nutrition/domain/food_search_result.dart';
import '../models/cached_menu_item.dart';
import '../models/enums.dart';

/// Persistent menu-item cache + token-bucket rate limiter.
///
/// Two-tier reads:
///   1. Isar cache — keyed by lowercased "restaurant userQuery". Fresh ≤ 7 days.
///   2. Caller falls back to API only when the cache is empty / stale,
///      and only when [tryAcquireSlot] returns true (≤ 5 calls / minute).
///
/// API results are persisted via [persistResults] so the next identical
/// search costs nothing for a week. The rate limiter is in-memory only
/// — restarting the app effectively resets the burst window, which is
/// fine: a daily provider quota is the real ceiling.
class MenuItemCacheService {
  MenuItemCacheService(this._isar);

  final Isar _isar;

  static const Duration _ttl = Duration(days: 7);
  static const int _maxCallsPerMinute = 5;
  static const Duration _window = Duration(seconds: 60);

  // Sliding-window rate limiter — drops timestamps older than [_window]
  // and refuses new calls once the list length hits [_maxCallsPerMinute].
  final List<DateTime> _recentCalls = [];

  /// Returns true if the caller can make an API call right now (and
  /// records the timestamp). Returns false if we'd exceed
  /// [_maxCallsPerMinute] in the trailing 60s — the caller should fall
  /// back to cached/pre-seed data instead of hitting the network.
  bool tryAcquireSlot() {
    final now = DateTime.now();
    _recentCalls.removeWhere((t) => now.difference(t) > _window);
    if (_recentCalls.length >= _maxCallsPerMinute) return false;
    _recentCalls.add(now);
    return true;
  }

  /// Returns fresh (≤ 7 days old) cache rows for the exact [queryKey].
  /// Stale rows are filtered out but not deleted — they may still beat
  /// an empty result, and a successful refetch will overwrite them.
  Future<List<FoodSearchResult>> readCache(String queryKey) async {
    final all = await _isar.cachedMenuItems
        .filter()
        .queryKeyEqualTo(queryKey, caseSensitive: false)
        .findAll();
    final now = DateTime.now();
    final fresh = all
        .where((r) => now.difference(r.fetchedAt) < _ttl)
        .map(_toResult)
        .toList();
    return fresh;
  }

  /// Persists every result for a search under one [queryKey]. Existing
  /// rows for the same key are deleted first so a re-fetch replaces the
  /// previous batch rather than stacking on top.
  Future<void> persistResults(
    String queryKey,
    String restaurantName,
    List<FoodSearchResult> results,
  ) async {
    if (results.isEmpty) return;
    await _isar.writeTxn(() async {
      // Delete-then-insert keeps the cache from growing unbounded across
      // refetches.
      final existing = await _isar.cachedMenuItems
          .filter()
          .queryKeyEqualTo(queryKey, caseSensitive: false)
          .findAll();
      if (existing.isNotEmpty) {
        await _isar.cachedMenuItems
            .deleteAll(existing.map((e) => e.id).toList());
      }
      final rows = results
          .map((r) => CachedMenuItem()
            ..queryKey = queryKey
            ..restaurantName = restaurantName
            ..itemName = r.name
            ..imageUrl = r.imageUrl
            ..calories = r.caloriesPer100g
            ..protein = r.proteinPer100g
            ..carbs = r.carbsPer100g
            ..fat = r.fatPer100g
            ..defaultServingSize = r.defaultServingSize
            ..servingUnit = r.servingUnit
            ..sodiumMg = r.sodiumMgPer100g
            ..fibre = r.fibrePer100g
            ..sugar = r.sugarPer100g
            ..vitaminDMcg = r.vitaminDMcgPer100g
            ..ironMg = r.ironMgPer100g
            ..calciumMg = r.calciumMgPer100g
            ..vitaminCMg = r.vitaminCMgPer100g
            ..magnesiumMg = r.magnesiumMgPer100g
            ..potassiumMg = r.potassiumMgPer100g
            ..zincMg = r.zincMgPer100g
            ..vitaminB12Mcg = r.vitaminB12McgPer100g
            ..folateMcg = r.folateMcgPer100g
            ..fetchedAt = DateTime.now())
          .toList();
      await _isar.cachedMenuItems.putAll(rows);
    });
  }

  /// Build the canonical cache key. Both arguments are trimmed and
  /// lowercased; a missing userQuery falls back to the restaurant name
  /// alone so the auto-fire-on-open search seeds the same cache row as
  /// the user typing the restaurant name manually.
  static String buildKey(String restaurantName, String userQuery) {
    final r = restaurantName.trim().toLowerCase();
    final u = userQuery.trim().toLowerCase();
    if (r.isEmpty) return u;
    if (u.isEmpty || u == r) return r;
    return '$r $u';
  }

  FoodSearchResult _toResult(CachedMenuItem c) => FoodSearchResult(
        name: c.itemName,
        brand: c.restaurantName,
        imageUrl: c.imageUrl,
        caloriesPer100g: c.calories,
        proteinPer100g: c.protein,
        carbsPer100g: c.carbs,
        fatPer100g: c.fat,
        defaultServingSize: c.defaultServingSize,
        servingUnit: c.servingUnit,
        sodiumMgPer100g: c.sodiumMg,
        fibrePer100g: c.fibre,
        sugarPer100g: c.sugar,
        vitaminDMcgPer100g: c.vitaminDMcg,
        ironMgPer100g: c.ironMg,
        calciumMgPer100g: c.calciumMg,
        vitaminCMgPer100g: c.vitaminCMg,
        magnesiumMgPer100g: c.magnesiumMg,
        potassiumMgPer100g: c.potassiumMg,
        zincMgPer100g: c.zincMg,
        vitaminB12McgPer100g: c.vitaminB12Mcg,
        folateMcgPer100g: c.folateMcg,
        source: FoodSource.spoonacular,
      );
}
