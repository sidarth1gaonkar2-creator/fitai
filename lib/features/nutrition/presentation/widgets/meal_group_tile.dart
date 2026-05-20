import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider, Icons, Theme;
import 'package:flutter/services.dart';

import '../../../../core/constants/nutrient_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../data/food_emojis.dart';
import '../../../../models/food_entry.dart';

/// Collapsible row that renders every [FoodEntry] that shares a
/// `mealGroupId` (i.e. all ingredients logged together from a single saved
/// meal) as one summary line. Tap to expand the ingredient list; tap the
/// summary again to collapse. Long-press or swipe to delete the whole group.
class MealGroupTile extends StatefulWidget {
  const MealGroupTile({
    super.key,
    required this.entries,
    required this.onDeleteGroup,
    this.isLocked = false,
  });

  /// All entries in the group. Must share `mealGroupId`; the first entry's
  /// `mealGroupName` / `mealGroupEmoji` are used as the display label.
  final List<FoodEntry> entries;
  final VoidCallback onDeleteGroup;
  final bool isLocked;

  @override
  State<MealGroupTile> createState() => _MealGroupTileState();
}

class _MealGroupTileState extends State<MealGroupTile> {
  bool _expanded = false;

  double get _totalCal => widget.entries.fold(0, (s, e) => s + e.calories);
  double get _totalPro => widget.entries.fold(0, (s, e) => s + e.protein);
  double get _totalCarb => widget.entries.fold(0, (s, e) => s + e.carbs);
  double get _totalFat => widget.entries.fold(0, (s, e) => s + e.fat);

  String get _displayName =>
      widget.entries.first.mealGroupName ?? 'Saved meal';
  String get _displayEmoji =>
      widget.entries.first.mealGroupEmoji ?? FoodEmojis.defaultEmoji;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final itemCount = widget.entries.length;

    final summary = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Emoji avatar — visually distinguishes a grouped row from a
          // standalone food entry without needing a separate icon column.
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_displayEmoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayName,
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    _MacroPill(
                      label: 'P',
                      grams: _totalPro,
                      bg: palette.accent.withValues(alpha: 0.12),
                      fg: palette.accent,
                    ),
                    _MacroPill(
                      label: 'C',
                      grams: _totalCarb,
                      bg: palette.accent.withValues(alpha: 0.08),
                      fg: palette.accent,
                    ),
                    _MacroPill(
                      label: 'F',
                      grams: _totalFat,
                      bg: NutrientIcons.fatColor.withValues(alpha: 0.14),
                      fg: NutrientIcons.fatColor,
                    ),
                    _CountPill(count: itemCount),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_totalCal.toInt()}',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: palette.accent,
            ),
          ),
          Text(
            ' kcal',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          AnimatedRotation(
            duration: const Duration(milliseconds: 180),
            turns: _expanded ? 0.5 : 0,
            child: Icon(
              CupertinoIcons.chevron_down,
              size: 14,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _expanded = !_expanded);
          },
          child: summary,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(left: 46, right: 4, bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                        height: 12,
                        color: palette.border,
                      ),
                      for (final e in widget.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _IngredientRow(entry: e),
                        ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );

    if (widget.isLocked) return body;

    // Swipe-to-delete (the whole group). We use the same Dismissible pattern
    // as the standalone food entry tile for consistency.
    return Dismissible(
      key: ValueKey('group-${widget.entries.first.mealGroupId}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.3},
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        widget.onDeleteGroup();
        if (context.mounted) {
          showCupertinoToast(context, 'Removed $_displayName');
        }
        // Return false because [onDeleteGroup] mutates the source list; the
        // parent rebuild handles removal. Mirrors the food entry tile.
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: palette.destructive.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete, color: CupertinoColors.white),
      ),
      child: body,
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.entry});

  final FoodEntry entry;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  fontFamily: 'Poppins',
                  color: palette.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'P${entry.protein.toInt()} '
                'C${entry.carbs.toInt()} '
                'F${entry.fat.toInt()}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${entry.calories.toInt()} kcal',
          style: textTheme.bodySmall?.copyWith(
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({
    required this.label,
    required this.grams,
    required this.bg,
    required this.fg,
  });

  final String label;
  final double grams;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label ${grams.toInt()}g',
        style: textTheme.labelSmall
            ?.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$count items',
        style: textTheme.labelSmall?.copyWith(
          color: palette.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
