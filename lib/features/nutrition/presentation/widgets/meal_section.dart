import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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

    return Card(
      child: Padding(
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
                  decoration: const BoxDecoration(
                    color: AppColors.purpleDark,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _icon,
                    color: AppColors.lime,
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
                      color: AppColors.lime,
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
                      color: AppColors.purple,
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
                child: TextButton.icon(
                  onPressed: onAddFood,
                  icon: const Icon(Icons.add, size: 18, color: AppColors.lime),
                  label: const Text(
                    'Add Food',
                    style: TextStyle(color: AppColors.lime),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
