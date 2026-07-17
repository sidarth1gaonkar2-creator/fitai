import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../data/curated_meal_plans.dart';

class MealPlanCard extends StatelessWidget {
  const MealPlanCard({
    super.key,
    required this.plan,
    required this.onPreview,
    required this.onImport,
  });

  final CuratedMealPlan plan;
  final VoidCallback onPreview;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: FieldManual.field,
        border: Border.all(color: FieldManual.hairline),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan name
          Text(
            plan.name,
            style: FieldManual.title(),
          ),
          const SizedBox(height: 8),

          // Goal chip — description is a sentence, so it keeps sentence case.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: palette.accent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              plan.goalDescription,
              style: FieldManual.body(
                fontSize: 12,
                color: palette.onAccent,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.local_fire_department_outlined,
                label: '${plan.totalCalories} KCAL',
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.fitness_center_outlined,
                label: '${plan.totalProtein}G PROTEIN',
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.restaurant_outlined,
                label: '${plan.mealCount} MEALS',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onPreview,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FieldManual.bone,
                    side: const BorderSide(color: FieldManual.hairlineStrong),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    'PREVIEW',
                    style: FieldManual.label(
                      color: FieldManual.bone,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onImport,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    'IMPORT TODAY',
                    style: FieldManual.label(
                      color: palette.onAccent,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.of(context).accent),
        const SizedBox(width: 4),
        Text(
          label,
          style: FieldManual.readout(fontSize: 11),
        ),
      ],
    );
  }
}
