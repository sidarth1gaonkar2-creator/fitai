import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider, Icons, Theme;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../models/enums.dart';
import '../../../../models/food_entry.dart';
import 'food_entry_tile.dart';

class MealSection extends StatelessWidget {
  const MealSection({
    super.key,
    required this.mealType,
    required this.entries,
    required this.onAddFood,
    required this.onDeleteEntry,
    this.isLocked = false,
  });

  final MealType mealType;
  final List<FoodEntry> entries;
  final VoidCallback onAddFood;
  final void Function(int entryId) onDeleteEntry;

  /// When true, hides the "Add Food" button and disables swipe-to-delete.
  final bool isLocked;

  IconData get _icon => switch (mealType) {
        MealType.breakfast => Icons.egg_outlined,
        MealType.lunch => Icons.lunch_dining_outlined,
        MealType.dinner => Icons.dinner_dining_outlined,
        MealType.snack => Icons.cookie_outlined,
      };

  double get _totalCalories =>
      entries.fold(0, (sum, e) => sum + e.calories);

  double get _totalProtein =>
      entries.fold(0, (sum, e) => sum + e.protein);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final palette = AppColors.of(context);

    return CupertinoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _icon,
                    color: palette.text,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mealType.label,
                    style: textTheme.titleSmall?.copyWith(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                ),
                if (entries.isNotEmpty) ...[
                  // Protein subtotal
                  Text(
                    '${_totalProtein.toInt()}g P',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Calorie subtotal
                  Text(
                    '${_totalCalories.toInt()} kcal',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else ...[
                  Text(
                    '0 kcal',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            if (entries.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              ...entries.map((entry) => FoodEntryTile(
                    entry: entry,
                    onDelete: () => onDeleteEntry(entry.id),
                    isLocked: isLocked,
                  )),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'No foods logged yet.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (!isLocked) ...[
              const SizedBox(height: 8),
              Center(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onAddFood,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.add, size: 18, color: AppColors.of(context).accent),
                      const SizedBox(width: 4),
                      Text(
                        'Add Food',
                        style: TextStyle(color: AppColors.of(context).accent),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
    );
  }
}
