import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator, Theme;
import '../../../../core/constants/nutrient_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
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
    return CupertinoCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CalorieRing(
                consumed: calories,
                target: calorieTarget,
                compact: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MacroProgressBar(
                    label: 'Protein',
                    icon: const Icon(NutrientIcons.proteinIcon,
                        size: 13, color: NutrientIcons.proteinColor),
                    consumed: protein,
                    target: proteinTarget,
                    baseColor: NutrientIcons.proteinColor,
                    isSodium: false,
                  ),
                  const SizedBox(height: 10),
                  _MacroProgressBar(
                    label: 'Carbs',
                    icon: const Icon(NutrientIcons.carbsIcon,
                        size: 13, color: NutrientIcons.carbsColor),
                    consumed: carbs,
                    target: carbsTarget,
                    baseColor: NutrientIcons.carbsColor,
                    isSodium: false,
                  ),
                  const SizedBox(height: 10),
                  _MacroProgressBar(
                    label: 'Fat',
                    icon: NutrientIcons.fatIconWidget(size: 13),
                    consumed: fat,
                    target: fatTarget,
                    baseColor: NutrientIcons.fatColor,
                    isSodium: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroProgressBar extends StatelessWidget {
  const _MacroProgressBar({
    required this.label,
    required this.icon,
    required this.consumed,
    required this.target,
    required this.baseColor,
    required this.isSodium,
  });

  final String label;
  final Widget icon;
  final double consumed;
  final double target;
  final Color baseColor;
  final bool isSodium;

  Color _barColor(BuildContext context) {
    final palette = AppColors.of(context);
    if (target <= 0) return baseColor;
    final ratio = consumed / target;

    if (isSodium) {
      if (ratio > 1.0) return palette.destructive;
      if (ratio > 0.9) return palette.success;
      return baseColor;
    }

    if (ratio > 1.1) return palette.destructive;
    if (ratio >= 0.9) return palette.success;
    return baseColor;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final barColor = _barColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            icon,
            const SizedBox(width: 4),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: baseColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${consumed.toInt()}g / ${target.toInt()}g (${target > 0 ? ((consumed / target) * 100).toInt() : 0}%)',
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
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            );
          },
        ),
      ],
    );
  }
}
