import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Theme;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../data/food_emojis.dart';
import '../../../../models/enums.dart';
import '../../../../models/saved_meal.dart';
import '../../../../providers/saved_meal_providers.dart';
import '../../../../features/themes/providers/theme_providers.dart';

/// Bottom sheet shown when the user taps a saved-meal card. Lets them pick
/// a target meal section, scale the portion, then logs it into today's
/// nutrition log via [logSavedMeal].
class UseSavedMealSheet extends ConsumerStatefulWidget {
  const UseSavedMealSheet({super.key, required this.meal});

  final SavedMeal meal;

  @override
  ConsumerState<UseSavedMealSheet> createState() =>
      _UseSavedMealSheetState();
}

class _UseSavedMealSheetState extends ConsumerState<UseSavedMealSheet> {
  static const List<double> _portionOptions = [0.5, 1.0, 1.5, 2.0];
  double _portion = 1.0;
  bool _logging = false;

  Future<void> _log(MealType type) async {
    setState(() => _logging = true);
    final ok = await logSavedMeal(
      ref,
      meal: widget.meal,
      mealType: type,
      portionMultiplier: _portion,
    );
    if (!mounted) return;
    setState(() => _logging = false);
    if (ok) {
      // Reward: small coin grant for re-using a saved meal.
      try {
        await ref.read(userThemeStateProvider.notifier).awardCoins(2);
      } catch (_) {/* coin grant must never break the log */}
    }
    if (!mounted) return;
    Navigator.of(context).pop(ok);
    if (ok) {
      showCupertinoToast(context, 'Meal logged 🍽️');
    } else {
      showCupertinoToast(context, 'Could not log meal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final itemsAsync = ref.watch(savedMealItemsProvider(widget.meal.id));
    final cal = widget.meal.totalCalories * _portion;
    final pro = widget.meal.totalProtein * _portion;
    final carb = widget.meal.totalCarbs * _portion;
    final fat = widget.meal.totalFat * _portion;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: palette.textSecondary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      widget.meal.emoji ?? FoodEmojis.defaultEmoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.meal.name,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: palette.text,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Items
                itemsAsync.when(
                  loading: () => const Center(
                      child: CupertinoActivityIndicator()),
                  error: (_, _) => Text(
                    'Could not load items',
                    style: TextStyle(color: palette.textSecondary),
                  ),
                  data: (items) => Container(
                    decoration: BoxDecoration(
                      color: palette.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        for (final it in items) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  it.foodName,
                                  style: textTheme.bodyMedium
                                      ?.copyWith(color: palette.text),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${(it.calories * it.quantity * _portion).toInt()} kcal',
                                style: textTheme.bodySmall?.copyWith(
                                    color: palette.textSecondary),
                              ),
                            ],
                          ),
                          if (it != items.last) const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Totals
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                          label: 'kcal',
                          value: cal.toInt().toString()),
                    ),
                    Expanded(
                      child: _Stat(
                          label: 'P', value: '${pro.toInt()}g'),
                    ),
                    Expanded(
                      child: _Stat(
                          label: 'C', value: '${carb.toInt()}g'),
                    ),
                    Expanded(
                      child: _Stat(
                          label: 'F', value: '${fat.toInt()}g'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Portion',
                  style: textTheme.bodySmall
                      ?.copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: 6),
                CupertinoSlidingSegmentedControl<double>(
                  groupValue: _portion,
                  onValueChanged: (v) {
                    if (v == null) return;
                    HapticFeedback.selectionClick();
                    setState(() => _portion = v);
                  },
                  children: {
                    for (final p in _portionOptions)
                      p: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text('${p}x'),
                      ),
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  'Log to',
                  style: textTheme.bodySmall
                      ?.copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _logButton(MealType.breakfast, 'Breakfast')),
                    const SizedBox(width: 6),
                    Expanded(child: _logButton(MealType.lunch, 'Lunch')),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _logButton(MealType.dinner, 'Dinner')),
                    const SizedBox(width: 6),
                    Expanded(child: _logButton(MealType.snack, 'Snack')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _logButton(MealType type, String label) {
    final palette = AppColors.of(context);
    return CupertinoButton(
      color: palette.accent,
      borderRadius: BorderRadius.circular(10),
      padding: const EdgeInsets.symmetric(vertical: 12),
      onPressed: _logging ? null : () => _log(type),
      child: _logging
          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add,
                    size: 16, color: CupertinoColors.white),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: palette.text,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }
}
