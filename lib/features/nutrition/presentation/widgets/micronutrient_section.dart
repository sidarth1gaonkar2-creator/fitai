import 'package:flutter/material.dart';
import '../../../../core/constants/micro_rdas.dart';
import '../../../../core/theme/app_colors.dart';

/// Collapsible card showing 10 tracked micronutrients vs their RDA targets.
/// Sodium colour logic is inverted (red when over the upper limit).
class MicronutrientSection extends StatelessWidget {
  const MicronutrientSection({
    super.key,
    required this.consumed,
  });

  /// Map of nutrient name → consumed amount (matches keys in [microRdaTargets]).
  final Map<String, double> consumed;

  int get _trackedCount =>
      consumed.entries.where((e) => e.value > 0).length;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 12),
        initiallyExpanded: false,
        leading: const Icon(
          Icons.science_outlined,
          color: AppColors.purple,
          size: 22,
        ),
        title: Text(
          'Micronutrients',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _trackedCount > 0
              ? '$_trackedCount of ${microRdaTargets.length} nutrients tracked today'
              : 'Track food to see your nutrient targets',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          // Always show all nutrient rows — tracked ones at full opacity,
          // untracked ones at 40% opacity.
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Column(
              children: microRdaTargets.keys.map((key) {
                final value = consumed[key] ?? 0;
                final isTracked = value > 0;
                return Opacity(
                  opacity: isTracked ? 1.0 : 0.4,
                  child: _MicronutrientRow(
                    name: key,
                    consumed: value,
                    target: microRdaTargets[key] ?? 0,
                    isSodium: key == sodiumKey,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _MicronutrientRow extends StatelessWidget {
  const _MicronutrientRow({
    required this.name,
    required this.consumed,
    required this.target,
    required this.isSodium,
  });

  final String name;
  final double consumed;
  final double target;
  final bool isSodium;

  String _unit(String name) {
    if (name == 'Vitamin D' || name == 'Vitamin B12' || name == 'Folate') {
      return 'mcg';
    }
    return 'mg';
  }

  String _formatValue(double v) {
    if (v >= 100) return v.toStringAsFixed(0);
    if (v >= 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }

  Color _barColor(BuildContext context) {
    if (target <= 0) return AppColors.purple;
    final ratio = consumed / target;

    if (isSodium) {
      // Sodium: normal when under 90%, over = red
      if (ratio > 1.0) return AppColors.error;
      if (ratio > 0.9) return AppColors.lime;
      return AppColors.purple;
    }

    if (ratio > 1.1) return AppColors.error;
    if (ratio >= 0.9) return AppColors.lime;
    return AppColors.purple;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final unit = _unit(name);
    final progress =
        target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final percent =
        target > 0 ? ((consumed / target) * 100).clamp(0.0, 999.0) : 0.0;
    final barColor = _barColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${_formatValue(consumed)} / ${_formatValue(target)} $unit  '
                '(${percent.toInt()}%)',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
