import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Dismissible, DismissDirection, FloatingActionButton, Icons, Scaffold, Theme;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../data/food_emojis.dart';
import '../../../models/saved_meal.dart';
import '../../../providers/saved_meal_providers.dart';
import 'widgets/use_saved_meal_sheet.dart';

class SavedMealsScreen extends ConsumerStatefulWidget {
  const SavedMealsScreen({super.key});

  @override
  ConsumerState<SavedMealsScreen> createState() => _SavedMealsScreenState();
}

class _SavedMealsScreenState extends ConsumerState<SavedMealsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showUseSheet(SavedMeal meal) async {
    HapticFeedback.selectionClick();
    await showCupertinoModalPopup<bool>(
      context: context,
      builder: (_) => UseSavedMealSheet(meal: meal),
    );
  }

  Future<void> _showLongPressMenu(SavedMeal meal) async {
    HapticFeedback.mediumImpact();
    final choice = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(meal.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 'edit'),
            child: const Text('Edit'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 'duplicate'),
            child: const Text('Duplicate'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, 'delete'),
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'edit':
        context.push('/nutrition/saved-meals/${meal.id}/edit');
      case 'duplicate':
        final items = await ref.read(savedMealItemsProvider(meal.id).future);
        if (!mounted) return;
        await saveMeal(
          ref,
          name: '${meal.name} (copy)',
          emoji: meal.emoji,
          items: items.map(cloneSavedMealItem).toList(),
        );
        if (!mounted) return;
        showCupertinoToast(context, 'Duplicated');
      case 'delete':
        await _confirmDelete(meal);
    }
  }

  Future<void> _confirmDelete(SavedMeal meal) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Delete "${meal.name}"?'),
        content: const Text(
          'This removes the saved meal. Past nutrition log entries are not '
          'affected.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await deleteSavedMeal(ref, meal.id);
      if (!mounted) return;
      showCupertinoToast(
        context,
        ok ? 'Meal deleted' : 'Could not delete meal',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final frequentAsync = ref.watch(frequentMealsProvider);
    final filteredAsync = ref.watch(savedMealSearchProvider(_query));

    return Scaffold(
      backgroundColor: palette.background,
      appBar: CupertinoNavigationBar(
        middle: const Text('Saved Meals'),
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: palette.accent,
        foregroundColor: CupertinoColors.white,
        onPressed: () => context.push('/nutrition/saved-meals/create'),
        icon: const Icon(Icons.add),
        label: const Text(
          'Create Meal',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search saved meals',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: filteredAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ShimmerCard(height: 320),
                ),
                error: (_, _) => Center(
                  child: ErrorCard(
                    message: 'Could not load saved meals.',
                    onRetry: () => ref.invalidate(savedMealsProvider),
                  ),
                ),
                data: (filtered) {
                  if (filtered.isEmpty && _query.isEmpty) {
                    return _EmptyState();
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (_query.isEmpty) ...[
                        frequentAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                          data: (frequent) {
                            if (frequent.isEmpty) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 4, bottom: 6, top: 4),
                                  child: Text(
                                    'Frequently Used',
                                    style: textTheme.labelLarge?.copyWith(
                                      color: palette.accent,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 120,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: frequent.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(width: 10),
                                    itemBuilder: (_, i) => _FrequentCard(
                                      meal: frequent[i],
                                      onTap: () => _showUseSheet(frequent[i]),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 6),
                          child: Text(
                            'All Saved Meals',
                            style: textTheme.labelLarge?.copyWith(
                              color: palette.accent,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ] else if (filtered.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No saved meals match "$_query"',
                              style: textTheme.bodyMedium?.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                      for (final meal in filtered)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _SavedMealRow(
                            meal: meal,
                            onTap: () => _showUseSheet(meal),
                            onDelete: () => _confirmDelete(meal),
                            onLongPress: () => _showLongPressMenu(meal),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_outline,
                size: 56, color: palette.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No saved meals yet',
              style: textTheme.titleMedium?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Save a meal from your nutrition log to reuse it with one tap.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium
                  ?.copyWith(color: palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequentCard extends StatelessWidget {
  const _FrequentCard({required this.meal, required this.onTap});

  final SavedMeal meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  meal.emoji ?? FoodEmojis.defaultEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meal.name,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${meal.totalCalories.toInt()} kcal',
              style: textTheme.bodySmall?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            if (meal.useCount > 0)
              Text(
                'Used ${meal.useCount}×',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: palette.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SavedMealRow extends ConsumerWidget {
  const _SavedMealRow({
    required this.meal,
    required this.onTap,
    required this.onDelete,
    required this.onLongPress,
  });

  final SavedMeal meal;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final itemsAsync = ref.watch(savedMealItemsProvider(meal.id));
    final itemCount = itemsAsync.valueOrNull?.length ?? 0;

    return Dismissible(
      key: ValueKey('saved-meal-${meal.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        // Confirmation dialog is fired by the parent.
        onDelete();
        return false; // Don't auto-remove from list — provider invalidation handles that.
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: palette.destructive,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: CupertinoColors.white),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  meal.emoji ?? FoodEmojis.defaultEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      meal.name,
                      style: textTheme.bodyLarge?.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$itemCount item${itemCount == 1 ? '' : 's'} · '
                      '${meal.totalCalories.toInt()} kcal · '
                      'used ${timeago.format(meal.lastUsedAt, locale: 'en_short')}',
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (meal.useCount >= 5)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${meal.useCount}×',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: palette.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
