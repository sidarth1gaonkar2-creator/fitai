import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Theme;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/food_emojis.dart';
import '../../../../models/saved_meal.dart';
import '../../../../providers/saved_meal_providers.dart';
import '../../../nutrition/presentation/widgets/use_saved_meal_sheet.dart';

/// Dashboard "Quick Log" strip — three most-used saved meals shown as
/// one-tap cards. Collapses to nothing when the user has no saved meals.
class SavedMealsQuickLog extends ConsumerWidget {
  const SavedMealsQuickLog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(frequentMealsProvider);
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (meals) {
        if (meals.isEmpty) return const SizedBox.shrink();
        final top = meals.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
              child: Row(
                children: [
                  Icon(Icons.bookmark, size: 14, color: palette.accent),
                  const SizedBox(width: 6),
                  Text(
                    'Quick Log',
                    style: textTheme.labelLarge?.copyWith(
                      color: palette.accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push('/nutrition/saved-meals'),
                    child: Text(
                      'See All',
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                for (int i = 0; i < top.length; i++) ...[
                  Expanded(
                    child: _QuickLogCard(
                      meal: top[i],
                      onTap: () => _openUseSheet(context, top[i]),
                    ),
                  ),
                  if (i < top.length - 1) const SizedBox(width: 8),
                ],
                // Pad out the row so a single saved meal doesn't stretch to
                // full width.
                for (int j = top.length; j < 3; j++) ...[
                  const Expanded(child: SizedBox.shrink()),
                  if (j < 2) const SizedBox(width: 8),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _openUseSheet(BuildContext context, SavedMeal meal) async {
    HapticFeedback.selectionClick();
    await showCupertinoModalPopup<bool>(
      context: context,
      builder: (_) => UseSavedMealSheet(meal: meal),
    );
  }
}

class _QuickLogCard extends StatelessWidget {
  const _QuickLogCard({required this.meal, required this.onTap});

  final SavedMeal meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(meal.emoji ?? FoodEmojis.defaultEmoji,
                    style: const TextStyle(fontSize: 22)),
                const Spacer(),
                Icon(Icons.add_circle,
                    size: 18, color: palette.accent),
              ],
            ),
            Text(
              meal.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
            Text(
              '${meal.totalCalories.toInt()} kcal',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
