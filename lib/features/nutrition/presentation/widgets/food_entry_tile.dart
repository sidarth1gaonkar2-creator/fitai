import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../models/food_entry.dart';

class FoodEntryTile extends StatelessWidget {
  const FoodEntryTile({
    super.key,
    required this.entry,
    required this.onDelete,
    this.onRestore,
    this.isLocked = false,
  });

  final FoodEntry entry;
  final VoidCallback onDelete;

  /// If non-null, an "Undo" action is offered for 5 seconds after swipe-delete.
  /// Tapping Undo invokes this callback with the deleted entry's data so the
  /// parent can re-insert it.
  final void Function(FoodEntry entry)? onRestore;

  /// When true, disables swipe-to-delete.
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    _MacroTag(
                      label: 'P',
                      grams: entry.protein,
                      bgColor: AppColors.of(context).accent.withValues(alpha: 0.12),
                      textColor: AppColors.of(context).accent,
                    ),
                    _MacroTag(
                      label: 'C',
                      grams: entry.carbs,
                      bgColor: AppColors.of(context).accent.withValues(alpha: 0.08),
                      textColor: AppColors.of(context).accent,
                    ),
                    _MacroTag(
                      label: 'F',
                      grams: entry.fat,
                      bgColor: AppColors.of(context).success.withValues(alpha: 0.12),
                      textColor: AppColors.of(context).success,
                    ),
                    if (entry.servingSize != null)
                      _ServingTag(
                        size: entry.servingSize!,
                        unit: entry.servingUnit ?? 'g',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.calories.toInt()}',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).accent,
            ),
          ),
          Text(
            ' kcal',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    if (isLocked) return tile;

    return _SwipeTile(
      entry: entry,
      onDelete: onDelete,
      onRestore: onRestore,
      child: tile,
    );
  }
}

class _MacroTag extends StatelessWidget {
  const _MacroTag({
    required this.label,
    required this.grams,
    required this.bgColor,
    required this.textColor,
  });

  final String label;
  final double grams;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label ${grams.toInt()}g',
        style: textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ServingTag extends StatelessWidget {
  const _ServingTag({required this.size, required this.unit});

  final double size;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${size.toInt()}$unit',
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─── Swipe-to-delete wrapper ────────────────────────────────────────────────

class _SwipeTile extends StatefulWidget {
  const _SwipeTile({
    required this.entry,
    required this.onDelete,
    required this.child,
    this.onRestore,
  });

  final FoodEntry entry;
  final VoidCallback onDelete;
  final void Function(FoodEntry entry)? onRestore;
  final Widget child;

  @override
  State<_SwipeTile> createState() => _SwipeTileState();
}

class _SwipeTileState extends State<_SwipeTile> {
  double _dragExtent = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = constraints.maxWidth;
        final fraction = tileWidth > 0 ? (_dragExtent / tileWidth).abs() : 0.0;
        final showRed = fraction >= 0.2;

        return Dismissible(
          key: ValueKey(widget.entry.id),
          direction: DismissDirection.endToStart,
          dismissThresholds: const {DismissDirection.endToStart: 0.3},
          onUpdate: (details) {
            setState(() => _dragExtent = details.progress * tileWidth);
          },
          confirmDismiss: (_) async {
            if (_dragExtent.abs() < 40) return false;
            HapticFeedback.mediumImpact();
            final restore = widget.onRestore;
            // Snapshot the entry data BEFORE deletion so we can restore it.
            final snapshot = restore != null ? _cloneEntry(widget.entry) : null;
            widget.onDelete();
            if (context.mounted) {
              if (snapshot != null && restore != null) {
                showCupertinoUndoToast(
                  context,
                  'Removed ${widget.entry.name}',
                  onUndo: () => restore(snapshot),
                );
              } else {
                showCupertinoToast(context, 'Removed ${widget.entry.name}');
              }
            }
            return false;
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: showRed
                ? AppColors.of(context).destructive.withValues(alpha: 0.9)
                : Colors.grey.withValues(alpha: 0.15),
            child: Icon(
              Icons.delete,
              color: showRed ? Colors.white : Colors.grey,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }

  /// Detached copy of an entry's user-visible fields. The clone is not
  /// attached to Isar, so deleting the original does not invalidate this
  /// data — it can be used to re-insert via [addFoodEntry].
  static FoodEntry _cloneEntry(FoodEntry e) {
    return FoodEntry()
      ..name = e.name
      ..calories = e.calories
      ..protein = e.protein
      ..carbs = e.carbs
      ..fat = e.fat
      ..servingSize = e.servingSize
      ..servingUnit = e.servingUnit
      ..vitaminDMcg = e.vitaminDMcg
      ..ironMg = e.ironMg
      ..calciumMg = e.calciumMg
      ..vitaminCMg = e.vitaminCMg
      ..magnesiumMg = e.magnesiumMg
      ..sodiumMg = e.sodiumMg
      ..potassiumMg = e.potassiumMg
      ..zincMg = e.zincMg
      ..vitaminB12Mcg = e.vitaminB12Mcg
      ..folateMcg = e.folateMcg
      ..fibre = e.fibre
      ..sugar = e.sugar;
  }
}
