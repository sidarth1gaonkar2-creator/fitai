import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/nutrient_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../models/enums.dart';
import '../../../providers/nutrition_providers.dart';
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
  List<FoodSearchResult> _results = const [];
  // Session-scoped cache so repeat searches don't burn quota.
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
    try {
      final spoon = ref.read(spoonacularServiceProvider);
      final results = await spoon.searchMenuItems(q);
      if (!mounted) return;
      _cache[q] = results;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Scaffold(
      appBar: CupertinoNavigationBar(
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
        middle: Text(
          widget.restaurantName.isEmpty
              ? 'Search Menu Items'
              : widget.restaurantName,
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
                  color: palette.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                style: TextStyle(color: palette.text, fontSize: 14),
                placeholderStyle: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 14,
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOffline ? Icons.wifi_off : Icons.cloud_off_outlined,
                size: 48,
                color: palette.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                isOffline
                    ? 'No internet connection.'
                    : 'Could not load menu items.',
                style: TextStyle(color: palette.text),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _runSearch,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
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
            style: TextStyle(color: palette.textSecondary),
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
                style: TextStyle(color: palette.textSecondary),
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
        food.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: palette.text,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '${food.caloriesPer100g.toInt()} kcal/100g · '
          'P${food.proteinPer100g.toInt()} '
          'C${food.carbsPer100g.toInt()} '
          'F${food.fatPer100g.toInt()}',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: palette.textSecondary,
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
