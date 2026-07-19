import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Dismissible, DismissDirection, FloatingActionButton, Icons, RoundedRectangleBorder, Scaffold;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/field_manual.dart';
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
    final ts = MediaQuery.textScalerOf(context);
    final frequentAsync = ref.watch(frequentMealsProvider);
    final filteredAsync = ref.watch(savedMealSearchProvider(_query));

    return Scaffold(
      backgroundColor: FieldManual.ink,
      appBar: CupertinoNavigationBar(
        middle: Text('SAVED MEALS', style: FieldManual.title()),
        backgroundColor: FieldManual.ink.withValues(alpha: 0.82),
        border: const Border(
          bottom: BorderSide(color: FieldManual.hairline),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        // Quiet Chrome: the Field Manual casts no shadows.
        elevation: 0,
        highlightElevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        onPressed: () => context.push('/nutrition/saved-meals/create'),
        icon: const Icon(Icons.add),
        label: Text(
          'CREATE MEAL',
          style: FieldManual.label(color: palette.onAccent, fontSize: 11),
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
                style: FieldManual.body(),
                placeholderStyle:
                    FieldManual.body(color: FieldManual.mutedBone),
                itemColor: FieldManual.mutedBone,
                decoration: BoxDecoration(
                  color: FieldManual.fieldRaised,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: FieldManual.hairline),
                ),
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
                                    'FREQUENTLY USED',
                                    style: FieldManual.label(fontSize: 10),
                                  ),
                                ),
                                SizedBox(
                                  height: ts.scale(120),
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
                            'ALL SAVED MEALS',
                            style: FieldManual.label(fontSize: 10),
                          ),
                        ),
                      ] else if (filtered.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No saved meals match "$_query"',
                              style: FieldManual.body(
                                fontSize: 14,
                                color: FieldManual.mutedBone,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_outline,
                size: 56, color: FieldManual.mutedBone),
            const SizedBox(height: 12),
            Text(
              'No saved meals yet',
              style: FieldManual.title(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Save a meal from your nutrition log to reuse it with one tap.',
              textAlign: TextAlign.center,
              style: FieldManual.body(color: FieldManual.mutedBone),
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FieldManual.field,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FieldManual.hairline),
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
                    style: FieldManual.title().copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${meal.totalCalories.toInt()} KCAL',
              style: FieldManual.readout(fontSize: 12),
            ),
            if (meal.useCount > 0)
              Text(
                'USED ${meal.useCount}×',
                style: FieldManual.label(fontSize: 11),
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
          // 0.9 alpha over the dark surface (same idiom as food_entry_tile's
          // swipe background). The glyph is INK: the AA-safe alert red is
          // light, so bone on this fill reads 2.53:1 while ink reads 5.33:1.
          color: palette.destructive.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.delete, color: FieldManual.ink),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: FieldManual.field,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FieldManual.hairline),
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
                      style: FieldManual.title(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${meal.totalCalories.toInt()} KCAL',
                          style: FieldManual.readout(fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '· $itemCount item${itemCount == 1 ? '' : 's'} · '
                            'used ${timeago.format(meal.lastUsedAt, locale: 'en_short')}',
                            style: FieldManual.body(
                              fontSize: 12,
                              color: FieldManual.mutedBone,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${meal.useCount}×',
                    style: FieldManual.readout(
                      fontSize: 11,
                      color: palette.onAccent,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: FieldManual.mutedBone,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
