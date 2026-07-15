import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/field_manual.dart';
import '../../../../data/food_emojis.dart';
import '../../../../models/saved_meal.dart';
import '../../../../providers/saved_meal_providers.dart';
import '../../../nutrition/presentation/widgets/use_saved_meal_sheet.dart';

/// "Quick rations" — the three most-used saved meals as one-tap chips.
/// Renders bare (no card chrome of its own) because it lives inside the
/// rations panel; collapses to nothing when the user has no saved meals.
class SavedMealsQuickLog extends ConsumerWidget {
  const SavedMealsQuickLog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(frequentMealsProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (meals) {
        if (meals.isEmpty) return const SizedBox.shrink();
        final top = meals.take(3).toList();
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'QUICK RATIONS',
                      style: FieldManual.label(fontSize: 9),
                    ),
                  ),
                  Semantics(
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.push('/nutrition/saved-meals'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        child: Text(
                          'SEE ALL',
                          style: FieldManual.label(
                            color: FieldManual.mutedBone,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (int i = 0; i < top.length; i++) ...[
                    Expanded(
                      child: _RationChip(
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
          ),
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

class _RationChip extends StatelessWidget {
  const _RationChip({required this.meal, required this.onTap});

  final SavedMeal meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Log ${meal.name}, ${meal.totalCalories.toInt()} calories',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: FieldManual.fieldRaised,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: FieldManual.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                meal.emoji ?? FoodEmojis.defaultEmoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 6),
              Text(
                meal.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FieldManual.body(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                '${meal.totalCalories.toInt()} KCAL',
                style: FieldManual.label(fontSize: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
