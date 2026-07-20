import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';

/// Field Manual water counter — a horizontal mono instrument with ≥44pt
/// steppers, replacing the dot-row water tracker. One glass = 250 ml; goal 8.
class CanteenCard extends StatelessWidget {
  const CanteenCard({
    super.key,
    required this.glasses,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int glasses;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  static const _goal = 8;

  @override
  Widget build(BuildContext context) {
    final goalMet = glasses >= _goal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FieldManual.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CANTEEN', style: FieldManual.label(fontSize: 9)),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: FieldManual.readout(
                      fontSize: 20,
                      color: goalMet
                          ? AppColors.of(context).accent
                          : FieldManual.bone,
                    ),
                    children: [
                      TextSpan(text: '$glasses'),
                      TextSpan(
                        text: ' / $_goal GLASSES',
                        style: FieldManual.readout(
                          fontSize: 12,
                          color: FieldManual.mutedBone,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _Stepper(
            label: 'Remove a glass of water',
            icon: CupertinoIcons.minus,
            enabled: glasses > 0,
            onTap: onDecrement,
          ),
          const SizedBox(width: 10),
          _Stepper(
            label: 'Add a glass of water',
            icon: CupertinoIcons.plus,
            enabled: true,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onTap();
              }
            : null,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: enabled ? FieldManual.fieldRaised : FieldManual.field,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: FieldManual.hairlineStrong),
          ),
          child: Icon(
            icon,
            size: 16,
            color: enabled
                ? FieldManual.bone
                : FieldManual.bone.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
