import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/nutrient_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/field_manual.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../data/restaurant_preseed_items.dart';
import '../../../models/enums.dart';
import '../../../providers/nutrition_providers.dart';
import '../../../services/menu_item_cache_service.dart';
import '../../../services/spoonacular_service.dart';
import '../domain/food_search_result.dart';

/// Spoonacular-backed menu-item search for restaurants we don't hand-model
/// (Cheesecake Factory, Applebee's, etc.). The query is pre-filled with the
/// restaurant name so the user just types the dish they want — "tuscan
/// chicken", "salmon", etc. — and we append it onto the chain name when
/// hitting `/food/menuItems/search`.
///
/// In-memory result cache is keyed by the full query string, so re-typing
/// the same search inside one session is free (no API hit). Cache is
/// cleared on screen dispose.
class RestaurantApiSearchScreen extends ConsumerStatefulWidget {
  const RestaurantApiSearchScreen({
    super.key,
    required this.restaurantName,
    this.mealType,
  });

  /// Pre-filled restaurant name (e.g. "Cheesecake Factory"). Pass an empty
  /// string for the "Other Restaurant" catch-all so the user starts with a
  /// blank query.
  final String restaurantName;

  /// Optional meal section to route the food into once the user picks an
  /// item. Defaults to lunch downstream if null.
  final MealType? mealType;

  @override
  ConsumerState<RestaurantApiSearchScreen> createState() =>
      _RestaurantApiSearchScreenState();
}

class _RestaurantApiSearchScreenState
    extends ConsumerState<RestaurantApiSearchScreen> {
  late final TextEditingController _searchController;
  Timer? _debounce;
  String _currentQuery = '';
  bool _loading = false;
  Object? _error;
  /// True when this session has been told by Spoonacular that the
  /// daily quota is gone. We stop hitting the API for the remainder of
  /// the screen lifetime and surface the curated/cached data only.
  bool _quotaExhausted = false;
  List<FoodSearchResult> _results = const [];
  // Session-scoped memoisation so re-typing the same query (which is
  // common as a user backspaces and retypes) doesn't re-query Isar.
  final Map<String, List<FoodSearchResult>> _cache = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Auto-fire the restaurant name as the initial search when we have one
    // so the user lands on a list of popular items immediately rather than
    // an empty screen.
    if (widget.restaurantName.isNotEmpty) {
      _currentQuery = widget.restaurantName;
      WidgetsBinding.instance.addPostFrameCallback((_) => _runSearch());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String get _effectiveQuery {
    final user = _searchController.text.trim();
    final restaurant = widget.restaurantName.trim();
    if (restaurant.isEmpty) return user;
    if (user.isEmpty) return restaurant;
    return '$restaurant $user';
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final q = _effectiveQuery;
      if (q == _currentQuery) return;
      setState(() => _currentQuery = q);
      _runSearch();
    });
  }

  /// Pulls results from (1) session memo, (2) Isar cache, (3) curated
  /// pre-seed for the chain, then optionally (4) Spoonacular if we
  /// don't have enough rows and the rate limiter / daily-quota permit.
  Future<void> _runSearch() async {
    final q = _currentQuery;
    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _error = null;
        _loading = false;
      });
      return;
    }
    if (_cache.containsKey(q)) {
      setState(() {
        _results = _cache[q]!;
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final cacheSvc = ref.read(menuItemCacheServiceProvider);
    final restaurant = widget.restaurantName.trim();
    // The user typed everything to the right of the restaurant name —
    // we use that as the secondary search filter against pre-seed and
    // cache keys.
    final userPart = q.startsWith(restaurant)
        ? q.substring(restaurant.length).trim()
        : q;
    final cacheKey = MenuItemCacheService.buildKey(restaurant, userPart);

    // 1. Isar cache (≤ 7 days old).
    List<FoodSearchResult> combined;
    try {
      combined = await cacheSvc.readCache(cacheKey);
    } catch (_) {
      combined = const [];
    }

    // 2. Pre-seed curated list. Merge by item name (case-insensitive)
    //    so the cache wins when the same item exists in both — cache
    //    has the real Spoonacular nutrition, pre-seed is a fallback.
    final seen = combined
        .map((r) => r.name.toLowerCase().trim())
        .toSet();
    final preSeed = preSeedResultsFor(
        restaurantName: restaurant, query: userPart);
    for (final item in preSeed) {
      if (seen.add(item.name.toLowerCase().trim())) combined.add(item);
    }

    // 3. If we already have a healthy result count OR we've already
    //    been told quota is gone, skip the network call.
    if (combined.length >= 8 || _quotaExhausted) {
      if (!mounted) return;
      _cache[q] = combined;
      setState(() {
        _results = combined;
        _loading = false;
      });
      return;
    }

    // 4. Rate-limited API call. tryAcquireSlot returns false if we've
    //    already burned the 5 calls-per-minute budget; in that case we
    //    return whatever cache + pre-seed gave us without surfacing an
    //    error (degraded but not broken).
    if (!cacheSvc.tryAcquireSlot()) {
      if (!mounted) return;
      _cache[q] = combined;
      setState(() {
        _results = combined;
        _loading = false;
      });
      return;
    }

    try {
      final spoon = ref.read(spoonacularServiceProvider);
      final apiResults = await spoon.searchMenuItems(q);
      if (!mounted) return;
      // Persist the API batch under this cache key so the next 7 days
      // of identical searches cost nothing.
      await cacheSvc.persistResults(cacheKey, restaurant, apiResults);
      for (final item in apiResults) {
        if (seen.add(item.name.toLowerCase().trim())) combined.add(item);
      }
      if (!mounted) return;
      _cache[q] = combined;
      setState(() {
        _results = combined;
        _loading = false;
      });
    } on SpoonacularQuotaException {
      if (!mounted) return;
      _cache[q] = combined;
      setState(() {
        _quotaExhausted = true;
        _results = combined;
        _loading = false;
        // Empty cache + empty pre-seed → show the friendly limit
        // message. If we have *some* results, just show them silently
        // (a banner could distract from a usable list).
        _error = combined.isEmpty
            ? const _QuotaExhaustedError()
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = combined;
        _loading = false;
        _error = combined.isEmpty ? e : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Scaffold(
      backgroundColor: FieldManual.scaffold,
      appBar: CupertinoNavigationBar(
        backgroundColor: FieldManual.ink.withValues(alpha: 0.82),
        border: const Border(
          bottom: BorderSide(color: FieldManual.hairline),
        ),
        middle: Text(
          // Restaurant names are content and keep their case; the static
          // fallback is a designation.
          widget.restaurantName.isEmpty
              ? 'SEARCH MENU ITEMS'
              : widget.restaurantName,
          style: FieldManual.title(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: CupertinoTextField(
                controller: _searchController,
                autofocus: true,
                placeholder: widget.restaurantName.isEmpty
                    ? 'Search any restaurant or food...'
                    : 'Search ${widget.restaurantName} menu...',
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Icon(
                    CupertinoIcons.search,
                    size: 18,
                    color: palette.textSecondary,
                  ),
                ),
                decoration: BoxDecoration(
                  color: FieldManual.fieldRaised,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: FieldManual.hairline),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                style: FieldManual.body(fontSize: 14),
                placeholderStyle: FieldManual.body(
                  fontSize: 14,
                  color: FieldManual.mutedBone,
                ),
                onChanged: _onChanged,
                onSubmitted: (_) {
                  _debounce?.cancel();
                  setState(() => _currentQuery = _effectiveQuery);
                  _runSearch();
                },
              ),
            ),
            Expanded(child: _buildBody(palette)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Palette palette) {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: ShimmerCard(height: 64),
        ),
      );
    }
    if (_error != null) {
      final isOffline = _error is SocketException;
      final isQuota = _error is _QuotaExhaustedError;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isQuota
                    ? Icons.timer_outlined
                    : isOffline
                        ? Icons.wifi_off
                        : Icons.cloud_off_outlined,
                size: 48,
                color: palette.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                isQuota
                    ? 'Daily search limit reached.\nTry again tomorrow or browse our '
                        'built-in restaurant menus.'
                    : isOffline
                        ? 'No internet connection.'
                        : 'Could not load menu items.',
                style: FieldManual.body(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (!isQuota)
                OutlinedButton.icon(
                  onPressed: _runSearch,
                  style: _secondaryButtonStyle,
                  icon: const Icon(Icons.refresh,
                      size: 18, color: FieldManual.bone),
                  label: Text('RETRY',
                      style: FieldManual.label(
                          fontSize: 11, color: FieldManual.bone)),
                ),
              if (isQuota)
                OutlinedButton.icon(
                  onPressed: () => context.go('/nutrition/restaurants'),
                  style: _secondaryButtonStyle,
                  icon: const Icon(Icons.menu_book_outlined,
                      size: 18, color: FieldManual.bone),
                  label: Text('BROWSE BUILT-IN MENUS',
                      style: FieldManual.label(
                          fontSize: 11, color: FieldManual.bone)),
                ),
            ],
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      if (_currentQuery.isEmpty) {
        return Center(
          child: Text(
            'Start typing to search.',
            style: FieldManual.body(color: FieldManual.mutedBone),
          ),
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_outlined,
                  size: 48, color: palette.textSecondary),
              const SizedBox(height: 8),
              Text(
                'No items found — try a different search.',
                style: FieldManual.body(color: FieldManual.mutedBone),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _results.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, indent: 76, color: palette.separator),
      itemBuilder: (context, index) => _ResultTile(
        food: _results[index],
        mealType: widget.mealType ?? MealType.lunch,
      ),
    );
  }
}

/// Field Manual secondary button: transparent fill, hairline border, sharp
/// 4pt geometry, 44pt minimum target.
final ButtonStyle _secondaryButtonStyle = OutlinedButton.styleFrom(
  foregroundColor: FieldManual.bone,
  side: const BorderSide(color: FieldManual.hairlineStrong),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  minimumSize: const Size(44, 44),
);

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.food, required this.mealType});

  final FoodSearchResult food;
  final MealType mealType;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: food.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                food.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _Fallback(name: food.name),
              ),
            )
          : _Fallback(name: food.name),
      title: Text(
        // Dish names are content — never uppercased.
        food.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: FieldManual.title().copyWith(fontSize: 15),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '${food.caloriesPer100g.toInt()} KCAL/100G · '
          'P${food.proteinPer100g.toInt()} '
          'C${food.carbsPer100g.toInt()} '
          'F${food.fatPer100g.toInt()}',
          style: FieldManual.readout(
            fontSize: 11,
            color: FieldManual.mutedBone,
          ),
        ),
      ),
      trailing: Icon(CupertinoIcons.chevron_right,
          size: 16, color: palette.textSecondary),
      onTap: () => context.go(
        '/nutrition/food/${mealType.name}',
        extra: food,
      ),
    );
  }
}

/// Marker error used when Spoonacular tells us the daily quota has been
/// exhausted. Lets [_buildBody] swap to a friendly "limit reached" panel
/// without coupling the UI to the typed [SpoonacularQuotaException].
class _QuotaExhaustedError implements Exception {
  const _QuotaExhaustedError();
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final category = NutrientIcons.categoryFromName(name);
    final color = NutrientIcons.forFoodCategoryColor(category);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        NutrientIcons.forFoodCategory(category),
        color: color,
        size: 22,
      ),
    );
  }
}
