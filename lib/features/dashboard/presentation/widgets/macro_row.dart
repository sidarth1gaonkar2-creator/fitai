import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/macro_targets.dart';
import '../../../../models/enums.dart';

class MacroRow extends StatelessWidget {
  const MacroRow({
    super.key,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.tdee,
    required this.goal,
  });

  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double tdee;
  final Goal goal;

  MacroTargets get _targets => macroTargetsFor(tdee: tdee, goal: goal);

  @override
  Widget build(BuildContext context) {
    final targets = _targets;

    return Row(
      children: [
        Expanded(
          child: _MacroBar(
            label: 'Protein',
            current: proteinGrams,
            target: targets.protein,
            color: AppColors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MacroBar(
            label: 'Carbs',
            current: carbsGrams,
            target: targets.carbs,
            color: AppColors.purpleLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MacroBar(
            label: 'Fat',
            current: fatGrams,
            target: targets.fat,
            color: AppColors.lime,
          ),
        ),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  final String label;
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
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: AppColors.darkTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.darkSurface,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${current.toInt()}g / ${target.toInt()}g (${target > 0 ? ((current / target) * 100).toInt() : 0}%)',
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
