import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/field_manual.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../data/curated_meal_plans.dart';
import '../../../models/enums.dart';
import '../../../providers/nutrition_providers.dart';

class MealPlanPreviewScreen extends ConsumerWidget {
  const MealPlanPreviewScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = curatedMealPlans.firstWhere((p) => p.id == planId);

    final palette = AppColors.of(context);
    return Scaffold(
      backgroundColor: FieldManual.ink,
      appBar: CupertinoNavigationBar(
        backgroundColor: FieldManual.ink.withValues(alpha: 0.82),
        border: const Border(
          bottom: BorderSide(color: FieldManual.hairline),
        ),
        middle: Text(
          plan.name,
          style: FieldManual.title(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Macro summary header
                SliverToBoxAdapter(child: _MacroSummary(plan: plan)),

                // Each meal section
                ...plan.meals.expand((meal) => [
                  SliverToBoxAdapter(
                    child: _MealHeader(mealType: meal.type, meal: meal),
                  ),
                  SliverList.builder(
                    itemCount: meal.foods.length,
                    itemBuilder: (context, index) =>
                        _FoodRow(food: meal.foods[index]),
                  ),
                ]),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),

          // Import button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => _import(context, ref, plan),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.onAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    'IMPORT THIS PLAN',
                    style: FieldManual.label(
                      color: palette.onAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _import(
    BuildContext context,
    WidgetRef ref,
    CuratedMealPlan plan,
  ) async {
    final success = await importMealPlan(ref, plan: plan);
    if (!context.mounted) return;

    showCupertinoToast(
      context,
      success
          ? 'Meal plan imported! ${plan.totalCalories} calories added'
          : 'Failed to import meal plan',
    );

    if (success) {
      ref.read(nutritionTabProvider.notifier).state = 1;
      context.go('/nutrition');
    }
  }
}

// ---------------------------------------------------------------------------
// Macro summary card
// ---------------------------------------------------------------------------

class _MacroSummary extends StatelessWidget {
  const _MacroSummary({required this.plan});

  final CuratedMealPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FieldManual.field,
        border: Border.all(color: FieldManual.hairline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.goalDescription,
            style: FieldManual.body(
              fontSize: 14,
              color: FieldManual.mutedBone,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroColumn(label: 'CALORIES', value: '${plan.totalCalories}'),
              _MacroColumn(label: 'PROTEIN', value: '${plan.totalProtein}G'),
              _MacroColumn(label: 'CARBS', value: '${plan.totalCarbs}G'),
              _MacroColumn(label: 'FAT', value: '${plan.totalFat}G'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroColumn extends StatelessWidget {
  const _MacroColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: FieldManual.readout(fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: FieldManual.label(fontSize: 11),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Meal header
// ---------------------------------------------------------------------------

class _MealHeader extends StatelessWidget {
  const _MealHeader({required this.mealType, required this.meal});

  final MealType mealType;
  final MealPlanMeal meal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(
            mealType.label.toUpperCase(),
            style: FieldManual.title(),
          ),
          const Spacer(),
          Text(
            '${meal.totalCalories.toInt()} KCAL',
            style: FieldManual.readout(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Food row
// ---------------------------------------------------------------------------

class _FoodRow extends StatelessWidget {
  const _FoodRow({required this.food});

  final MealPlanFood food;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: FieldManual.field,
        border: Border.all(color: FieldManual.hairline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: FieldManual.body(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${food.servingSize.toInt()}${food.servingUnit}',
                  style: FieldManual.label(fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${food.calories.toInt()} KCAL',
                style: FieldManual.readout(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                'P${food.protein.toInt()} C${food.carbs.toInt()} F${food.fat.toInt()}',
                style: FieldManual.readout(
                  fontSize: 10,
                  color: FieldManual.mutedBone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
