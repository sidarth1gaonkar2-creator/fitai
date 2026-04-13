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
    this.isLocked = false,
  });

  final FoodEntry entry;
  final VoidCallback onDelete;

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
      entryId: entry.id,
      entryName: entry.name,
      onDelete: onDelete,
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
    required this.entryId,
    required this.entryName,
    required this.onDelete,
    required this.child,
  });

  final int entryId;
  final String entryName;
  final VoidCallback onDelete;
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
          key: ValueKey(widget.entryId),
          direction: DismissDirection.endToStart,
          dismissThresholds: const {DismissDirection.endToStart: 0.3},
          onUpdate: (details) {
            setState(() => _dragExtent = details.progress * tileWidth);
          },
          confirmDismiss: (_) async {
            if (_dragExtent.abs() < 40) return false;
            HapticFeedback.mediumImpact();
            widget.onDelete();
            if (context.mounted) {
              showCupertinoToast(context, 'Removed ${widget.entryName}');
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
}
