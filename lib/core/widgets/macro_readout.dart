import 'package:flutter/cupertino.dart';

import '../theme/field_manual.dart';
import 'animated_count.dart';
import 'meter_bar.dart';

/// A labeled mono macro readout with a hairline progress bar — the shared
/// instrument used by the dashboard RationsPanel and the nutrition summary.
/// On-track fills bone; a genuine overshoot (>110% of target) turns the bar
/// alert. The numbers carry the story either way — color is never the only
/// signal (the Semantics label spells out the overshoot).
class MacroReadout extends StatelessWidget {
  const MacroReadout({
    super.key,
    required this.label,
    required this.grams,
    required this.target,
  });

  final String label;
  final double grams;
  final double target;

  @override
  Widget build(BuildContext context) {
    final fraction =
        target <= 0 ? 0.0 : (grams / target).clamp(0.0, 1.0).toDouble();
    final over = target > 0 && grams > target * 1.1;
    return Semantics(
      label: '$label ${grams.round()} of ${target.round()} grams'
          '${over ? ', over target' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: FieldManual.label(fontSize: 11)),
          const SizedBox(height: 4),
          AnimatedCount(
            value: grams,
            builder: (context, animated) => Text(
              '${animated.round()}/${target.round()}G',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FieldManual.readout(fontSize: 13),
            ),
          ),
          const SizedBox(height: 6),
          MeterBar(
            fraction: fraction,
            fill: over
                ? FieldManual.alert
                : FieldManual.bone.withValues(alpha: 0.85),
          ),
        ],
      ),
    );
  }
}
