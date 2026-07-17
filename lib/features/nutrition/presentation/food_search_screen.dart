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
import '../../../models/enums.dart';
import '../../../models/saved_meal.dart';
import '../../../providers/nutrition_providers.dart';
import '../../../providers/saved_meal_providers.dart';
import '../domain/food_search_result.dart';
import 'widgets/use_saved_meal_sheet.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({
    super.key,
    required this.mealType,
    this.returnMode = false,
  });

  final MealType mealType;
  final bool returnMode;

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _currentQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _currentQuery = value.trim().length >= 2 ? value.trim() : '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Local results — instant
    final localResults = _currentQuery.isNotEmpty
        ? ref.watch(foodLocalSearchProvider(_currentQuery))
        : <FoodSearchResult>[];

    // Remote results — async
    final remoteAsync = _currentQuery.isNotEmpty
        ? ref.watch(foodRemoteSearchProvider(_currentQuery))
        : null;

    return Scaffold(
      backgroundColor: FieldManual.ink,
      appBar: CupertinoNavigationBar(
        backgroundColor: FieldManual.ink.withValues(alpha: 0.82),
        border: const Border(
          bottom: BorderSide(color: FieldManual.hairline),
        ),
        middle: _FmFocusRing(
          builder: (context, focused) => CupertinoTextField(
            controller: _searchController,
            autofocus: true,
            placeholder: 'Search foods...',
            decoration: BoxDecoration(
              color: FieldManual.fieldRaised,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: focused
                    ? AppColors.of(context).accent
                    : FieldManual.hairline,
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            style: FieldManual.body(fontSize: 14),
            placeholderStyle:
                FieldManual.body(fontSize: 14, color: FieldManual.mutedBone),
            onChanged: _onSearchChanged,
          ),
        ),
        trailing: CupertinoButton(
          padding: const EdgeInsets.all(8),
          onPressed: () =>
              context.go('/nutrition/scan/${widget.mealType.name}'),
          child: const Icon(CupertinoIcons.qrcode_viewfinder,
              size: 22,
              color: FieldManual.bone,
              semanticLabel: 'Scan barcode'),
        ),
      ),
      body: _buildBody(
        context,
        localResults,
        remoteAsync,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<FoodSearchResult> localResults,
    AsyncValue<List<FoodSearchResult>>? remoteAsync,
  ) {
    // Empty query — show prompt
    if (_currentQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, size: 48, color: FieldManual.mutedBone),
            const SizedBox(height: 8),
            Text(
              'Search for a food or scan a barcode.',
              style: FieldManual.body(
                fontSize: 14,
                color: FieldManual.mutedBone,
              ),
            ),
          ],
        ),
      );
    }

    final remoteData = remoteAsync?.valueOrNull;
    final remoteIsLoading =
        remoteAsync != null && remoteAsync.isLoading && !remoteAsync.hasValue;
    final remoteHasError = remoteAsync != null &&
        remoteAsync.hasError &&
        !remoteAsync.hasValue;
    final bothEmpty = localResults.isEmpty &&
        (remoteData == null || remoteData.isEmpty) &&
        !remoteIsLoading;

    if (bothEmpty && !remoteHasError) {
      return _EmptyState(
        query: _currentQuery,
        mealType: widget.mealType,
        onRetry: () => setState(() {
          final q = _currentQuery;
          _currentQuery = '';
          Future.microtask(() => setState(() => _currentQuery = q));
        }),
      );
    }

    // Suggested saved meals — only meaningful when the user is logging
    // into a real meal section (not in returnMode, where we'd just pop
    // with the food not the meal).
    final savedMealMatches = widget.returnMode
        ? <SavedMeal>[]
        : (ref
                .watch(savedMealsMatchingProvider(_currentQuery))
                .valueOrNull ??
            const <SavedMeal>[]);

    return CustomScrollView(
      slivers: [
        if (savedMealMatches.isNotEmpty) ...[
          _SectionHeader(
            label: 'SAVED MEALS',
            icon: Icons.bookmark_outline,
            isPrimary: true,
          ),
          SliverList.builder(
            itemCount: savedMealMatches.length,
            itemBuilder: (context, index) => _SavedMealSuggestionTile(
              meal: savedMealMatches[index],
            ),
          ),
        ],
        // Local results section — always at top, renders first frame
        if (localResults.isNotEmpty) ...[
          _SectionHeader(
            label: 'FOOD DATABASE',
            icon: Icons.bolt_outlined,
            isPrimary: true,
          ),
          SliverList.builder(
            itemCount: localResults.length,
            itemBuilder: (context, index) => _FoodResultTile(
              food: localResults[index],
              mealType: widget.mealType,
              returnMode: widget.returnMode,
            ),
          ),
        ],

        // USDA remote results section
        if (remoteIsLoading) ...[
          _SectionHeader(
            label: 'FROM USDA',
            icon: Icons.cloud_outlined,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: List.generate(
                    3,
                    (i) => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: ShimmerCard(height: 64),
                        )),
              ),
            ),
          ),
        ] else if (remoteHasError) ...[
          SliverToBoxAdapter(
            child: _RemoteErrorBanner(
              error: remoteAsync.error,
              onRetry: () => setState(() {
                final q = _currentQuery;
                _currentQuery = '';
                Future.microtask(() => setState(() => _currentQuery = q));
              }),
            ),
          ),
        ] else if (remoteData != null && remoteData.isNotEmpty) ...[
          // Split the merged remote result into USDA (Common Foods) vs.
          // Spoonacular (Branded & Restaurant) so the user can tell at a
          // glance where each row came from. The unified provider already
          // merges them in priority order.
          ..._buildRemoteSections(remoteData),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  /// Splits the merged remote list into two visually-grouped sections.
  List<Widget> _buildRemoteSections(List<FoodSearchResult> remoteData) {
    final usda = remoteData
        .where((r) => r.source == FoodSource.usda)
        .toList();
    final branded = remoteData
        .where((r) => r.source == FoodSource.spoonacular)
        .toList();
    return [
      if (usda.isNotEmpty) ...[
        _SectionHeader(
          label: 'COMMON FOODS',
          icon: Icons.public_outlined,
        ),
        SliverList.builder(
          itemCount: usda.length,
          itemBuilder: (context, index) => _FoodResultTile(
            food: usda[index],
            mealType: widget.mealType,
            returnMode: widget.returnMode,
          ),
        ),
      ],
      if (branded.isNotEmpty) ...[
        _SectionHeader(
          label: 'BRANDED & RESTAURANT',
          icon: Icons.storefront_outlined,
        ),
        SliverList.builder(
          itemCount: branded.length,
          itemBuilder: (context, index) => _FoodResultTile(
            food: branded[index],
            mealType: widget.mealType,
            returnMode: widget.returnMode,
          ),
        ),
      ],
    ];
  }
}

// ---------------------------------------------------------------------------
// Section header sliver
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.icon,
    this.isPrimary = false,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    // The accent marks the primary sections via the icon only — mono labels
    // stay muted bone at small sizes (Field Manual label rule).
    final iconColor = isPrimary ? palette.accent : FieldManual.mutedBone;

    return SliverToBoxAdapter(
      child: Padding(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(label, style: FieldManual.label(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Food result tile
// ---------------------------------------------------------------------------

class _FoodResultTile extends StatelessWidget {
  const _FoodResultTile({
    required this.food,
    required this.mealType,
    this.returnMode = false,
  });

  final FoodSearchResult food;
  final MealType mealType;
  final bool returnMode;

  @override
  Widget build(BuildContext context) {
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
                errorBuilder: (_, _, _) => _CategoryFoodIcon(name: food.name),
              ),
            )
          : _CategoryFoodIcon(name: food.name),
      title: Text(
        food.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        // Food names are user content — never uppercase.
        style: FieldManual.title().copyWith(fontSize: 15),
      ),
      subtitle: Row(
        children: [
          if (food.brand != null) ...[
            Flexible(
              child: Text(
                food.brand!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FieldManual.body(
                  fontSize: 12,
                  color: FieldManual.mutedBone,
                ),
              ),
            ),
            Text(
              ' · ',
              style: FieldManual.body(
                fontSize: 12,
                color: FieldManual.mutedBone,
              ),
            ),
          ],
          Text(
            '${food.caloriesPer100g.toInt()} KCAL/100G · '
            'P${food.proteinPer100g.toInt()} '
            'C${food.carbsPer100g.toInt()} '
            'F${food.fatPer100g.toInt()}',
            style: FieldManual.readout(
              fontSize: 11,
              color: FieldManual.mutedBone,
            ),
          ),
        ],
      ),
      onTap: () {
        if (returnMode) {
          Navigator.of(context).pop(food);
        } else {
          context.go(
            '/nutrition/food/${mealType.name}',
            extra: food,
          );
        }
      },
    );
  }
}

class _CategoryFoodIcon extends StatelessWidget {
  const _CategoryFoodIcon({required this.name});
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

// ---------------------------------------------------------------------------
// Remote error banner
// ---------------------------------------------------------------------------

class _RemoteErrorBanner extends StatelessWidget {
  const _RemoteErrorBanner({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isOffline = error is SocketException;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.wifi_off : Icons.cloud_off_outlined,
            size: 18,
            color: FieldManual.mutedBone,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOffline
                  ? 'No internet. Showing local results only.'
                  : 'Could not load online results.',
              style: FieldManual.body(
                fontSize: 12,
                color: FieldManual.mutedBone,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'RETRY',
              style: FieldManual.label(
                fontSize: 10,
                color: AppColors.of(context).accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Both-empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.query,
    required this.mealType,
    required this.onRetry,
  });

  final String query;
  final MealType mealType;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_outlined,
              size: 56,
              color: FieldManual.mutedBone,
            ),
            const SizedBox(height: 12),
            Text(
              'No results found for "$query"',
              textAlign: TextAlign.center,
              style: FieldManual.body(fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search term or scan a barcode.',
              textAlign: TextAlign.center,
              style: FieldManual.body(
                fontSize: 13,
                color: FieldManual.mutedBone,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () =>
                  context.go('/nutrition/scan/${mealType.name}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: FieldManual.bone,
                side: const BorderSide(color: FieldManual.hairlineStrong),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
              ),
              icon: const Icon(Icons.qr_code_scanner,
                  color: FieldManual.bone),
              label: Text(
                'SCAN BARCODE',
                style: FieldManual.label(
                  fontSize: 11,
                  color: FieldManual.bone,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Suggestion row shown above food search results when the current query
/// matches a saved meal. Tapping opens the use-meal bottom sheet, letting
/// the user log the entire meal instead of adding a single ingredient.
class _SavedMealSuggestionTile extends StatelessWidget {
  const _SavedMealSuggestionTile({required this.meal});

  final SavedMeal meal;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showCupertinoModalPopup<bool>(
          context: context,
          builder: (_) => UseSavedMealSheet(meal: meal),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: palette.accent.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Text(meal.emoji ?? '🔖',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      // Meal names are user content — never uppercase.
                      'Log entire "${meal.name}"?',
                      style: FieldManual.body(fontSize: 14).copyWith(
                        fontWeight: FontWeight.w600,
                        fontVariations: const [FontVariation('wght', 600)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${meal.totalCalories.toInt()} KCAL · SAVED MEAL',
                      style: FieldManual.readout(
                        fontSize: 11,
                        color: FieldManual.mutedBone,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_right,
                  size: 16, color: palette.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tracks whether a descendant text field holds focus so the builder can
/// paint the Field Manual accent focus border. Presentation only — the
/// wrapper node is unfocusable and skipped in traversal, so keyboard and
/// tap behavior are untouched.
class _FmFocusRing extends StatefulWidget {
  const _FmFocusRing({required this.builder});

  final Widget Function(BuildContext context, bool focused) builder;

  @override
  State<_FmFocusRing> createState() => _FmFocusRingState();
}

class _FmFocusRingState extends State<_FmFocusRing> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: widget.builder(context, _focused),
    );
  }
}
