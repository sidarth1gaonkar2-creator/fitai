import 'package:flutter/material.dart';
import '../../../../core/constants/nutrient_icons.dart';
import '../../../../core/theme/app_colors.dart';

class MacroRow extends StatelessWidget {
  const MacroRow({
    super.key,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
  });

  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MacroBar(
            label: 'Protein',
            icon: const Icon(NutrientIcons.proteinIcon,
                size: 14, color: NutrientIcons.proteinColor),
            current: proteinGrams,
            target: proteinTarget,
            color: NutrientIcons.proteinColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MacroBar(
            label: 'Carbs',
            icon: const Icon(NutrientIcons.carbsIcon,
                size: 14, color: NutrientIcons.carbsColor),
            current: carbsGrams,
            target: carbsTarget,
            color: NutrientIcons.carbsColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MacroBar(
            label: 'Fat',
            icon: NutrientIcons.fatIconWidget(size: 14),
            current: fatGrams,
            target: fatTarget,
            color: NutrientIcons.fatColor,
          ),
        ),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.icon,
    required this.current,
    required this.target,
    required this.color,
  });

  final String label;
  final Widget icon;
  final double current;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            icon,
            const SizedBox(width: 4),
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.of(context).surface,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${current.toInt()}g / ${target.toInt()}g (${target > 0 ? ((current / target) * 100).toInt() : 0}%)',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.of(context).textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
