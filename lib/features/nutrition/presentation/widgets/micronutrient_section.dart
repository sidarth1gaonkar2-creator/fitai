import 'package:flutter/cupertino.dart' hide CupertinoExpansionTile;
import '../../../../core/constants/micro_rdas.dart';
import '../../../../core/constants/nutrient_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/widgets/cupertino_helpers.dart';

/// Collapsible card showing 10 tracked micronutrients vs their RDA targets.
/// Sodium colour logic is inverted (alert when over the upper limit).
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
    return CupertinoExpansionTile(
      leading: Icon(
        CupertinoIcons.lab_flask,
        color: AppColors.of(context).accent,
        size: 22,
      ),
      title: Text(
        'MICRONUTRIENTS',
        style: FieldManual.title(),
      ),
      subtitle: Text(
        _trackedCount > 0
            ? '$_trackedCount of ${microRdaTargets.length} nutrients tracked today'
            : 'Track food to see your nutrient targets',
        style: FieldManual.body(
          fontSize: 12,
          color: FieldManual.mutedBone,
        ),
      ),
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

  /// True overshoot only — on-track progress is bone (DESIGN.md). Sodium's
  /// inverted logic survives: exceeding the upper limit is the alert case.
  bool _isOvershoot() {
    if (target <= 0) return false;
    final ratio = consumed / target;
    if (isSodium) return ratio > 1.0;
    return ratio > 1.1;
  }

  @override
  Widget build(BuildContext context) {
    final (iconData, iconColor) = NutrientIcons.forMicro(name);
    final unit = _unit(name);
    final progress =
        target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final percent =
        target > 0 ? ((consumed / target) * 100).clamp(0.0, 999.0) : 0.0;
    final fillColor = _isOvershoot()
        ? FieldManual.alert
        : FieldManual.bone.withValues(alpha: 0.85);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Nutrient colours stay on small icons only — scanning aid.
              Icon(iconData, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: FieldManual.body(fontSize: 13),
                ),
              ),
              Text(
                '${_formatValue(consumed)}/${_formatValue(target)} '
                '${unit.toUpperCase()} (${percent.toInt()}%)',
                style: FieldManual.readout(
                  fontSize: 11,
                  color: FieldManual.mutedBone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // Bone fill on a hairline track — the RationsPanel bar idiom.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress.toDouble()),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: SizedBox(
                  height: 3,
                  child: Stack(
                    children: [
                      Container(color: FieldManual.hairline),
                      FractionallySizedBox(
                        widthFactor: value,
                        child: Container(color: fillColor),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
