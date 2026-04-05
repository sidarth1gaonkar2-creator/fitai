import 'package:flutter/material.dart';
import '../../../../features/dashboard/presentation/widgets/calorie_ring.dart';

/// Renamed from DailySummaryHeader — now shows CalorieRing + macro progress bars.
class NutritionSummaryCard extends StatelessWidget {
  const NutritionSummaryCard({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double calorieTarget;
  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Calorie ring — 120x120
              SizedBox(
                width: 120,
                height: 120,
                child: CalorieRing(
                  consumed: calories,
                  target: calorieTarget,
                ),
              ),
              const SizedBox(width: 16),
              // Macro progress bars
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MacroProgressBar(
                      label: 'Protein',
                      consumed: protein,
                      target: proteinTarget,
                      color: _macroColor(
                        context,
                        protein,
                        proteinTarget,
                        isSodium: false,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MacroProgressBar(
                      label: 'Carbs',
                      consumed: carbs,
                      target: carbsTarget,
                      color: _macroColor(
                        context,
                        carbs,
                        carbsTarget,
                        isSodium: false,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MacroProgressBar(
                      label: 'Fat',
                      consumed: fat,
                      target: fatTarget,
                      color: _macroColor(
                        context,
                        fat,
                        fatTarget,
                        isSodium: false,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Colour-codes a macro bar based on consumption ratio.
  /// <90%  → primary, 90–110% → secondary, >110% → error
  static Color _macroColor(
    BuildContext context,
    double consumed,
    double target, {
    required bool isSodium,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    if (target <= 0) return colorScheme.primary;
    final ratio = consumed / target;
    if (isSodium) {
      if (ratio > 1.0) return colorScheme.error;
      if (ratio > 0.9) return colorScheme.secondary;
      return colorScheme.primary;
    }
    if (ratio > 1.1) return colorScheme.error;
    if (ratio >= 0.9) return colorScheme.secondary;
    return colorScheme.primary;
  }
}

class _MacroProgressBar extends StatelessWidget {
  const _MacroProgressBar({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
  });

  final String label;
  final double consumed;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '${consumed.toInt()}g / ${target.toInt()}g',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            );
          },
        ),
      ],
    );
  }
}
