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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Local results — instant
    final localResults = _currentQuery.isNotEmpty
        ? ref.watch(foodLocalSearchProvider(_currentQuery))
        : <FoodSearchResult>[];

    // Remote results — async
    final remoteAsync = _currentQuery.isNotEmpty
        ? ref.watch(foodRemoteSearchProvider(_currentQuery))
        : null;

    return Scaffold(
      appBar: CupertinoNavigationBar(
        backgroundColor: AppColors.of(context).background.withValues(alpha: 0.8),
        border: null,
        middle: CupertinoTextField(
          controller: _searchController,
          autofocus: true,
          placeholder: 'Search foods...',
          decoration: BoxDecoration(
            color: AppColors.of(context).surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          style: TextStyle(color: AppColors.of(context).text, fontSize: 14),
          placeholderStyle: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 14,
          ),
          onChanged: _onSearchChanged,
        ),
        trailing: CupertinoButton(
          padding: const EdgeInsets.all(8),
          onPressed: () =>
              context.go('/nutrition/scan/${widget.mealType.name}'),
          child: const Icon(CupertinoIcons.qrcode_viewfinder, size: 22),
        ),
      ),
      body: _buildBody(
        context,
        localResults,
        remoteAsync,
        colorScheme,
        textTheme,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<FoodSearchResult> localResults,
    AsyncValue<List<FoodSearchResult>>? remoteAsync,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Empty query — show prompt
    if (_currentQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              'Search for a food or scan a barcode.',
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
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

    return CustomScrollView(
      slivers: [
        // Local results section — always at top, renders first frame
        if (localResults.isNotEmpty) ...[
          _SectionHeader(
            label: 'US Foods',
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
            label: 'From USDA',
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
          _SectionHeader(
            label: 'From USDA',
            icon: Icons.public_outlined,
          ),
          SliverList.builder(
            itemCount: remoteData.length,
            itemBuilder: (context, index) => _FoodResultTile(
              food: remoteData[index],
              mealType: widget.mealType,
              returnMode: widget.returnMode,
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
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
    final color = isPrimary ? palette.accent : palette.textSecondary;

    return SliverToBoxAdapter(
      child: Padding(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: isPrimary ? 'Poppins' : null,
                fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          if (food.brand != null) ...[
            Flexible(
              child: Text(
                food.brand!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            Text(
              ' · ',
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
          Text(
            '${food.caloriesPer100g.toInt()} kcal/100g',
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          Text(
            ' · ',
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          Text(
            'P${food.proteinPer100g.toInt()} '
            'C${food.carbsPer100g.toInt()} '
            'F${food.fatPer100g.toInt()}',
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isOffline = error is SocketException;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.wifi_off : Icons.cloud_off_outlined,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOffline
                  ? 'No internet. Showing local results only.'
                  : 'Could not load online results.',
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 56,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No results found for "$query"',
              textAlign: TextAlign.center,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search term or scan a barcode.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () =>
                  context.go('/nutrition/scan/${mealType.name}'),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Barcode'),
            ),
          ],
        ),
      ),
    );
  }
}
