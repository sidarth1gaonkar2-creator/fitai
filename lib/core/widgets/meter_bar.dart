import 'package:flutter/widgets.dart';

import '../motion.dart';
import '../theme/field_manual.dart';

/// The shared animated meter bar: a hairline track whose fill sweeps from
/// its previous fraction to the new one on the [Motion] clock. Fill-color
/// changes (e.g. bone → alert on overshoot) tween over the same duration.
/// The first build sweeps from zero once; kept-alive screens (the tab
/// shell) never re-trigger it, and reduced motion snaps instantly.
class MeterBar extends StatelessWidget {
  const MeterBar({
    super.key,
    required this.fraction,
    required this.fill,
    this.height = 2,
    this.track,
    this.radius = 1,
  });

  /// Target fill fraction; clamped to 0..1.
  final double fraction;
  final Color fill;
  final double height;

  /// Track color behind the fill; the hairline when null.
  final Color? track;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.meterDurationOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0).toDouble()),
      duration: duration,
      curve: Motion.meterCurve,
      builder: (context, animatedFraction, _) => TweenAnimationBuilder<Color?>(
        // begin == end: no color motion on first build, only on changes.
        tween: ColorTween(begin: fill, end: fill),
        duration: duration,
        curve: Motion.meterCurve,
        builder: (context, animatedFill, _) => ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Container(color: track ?? FieldManual.hairline),
                FractionallySizedBox(
                  widthFactor: animatedFraction,
                  child: Container(color: animatedFill ?? fill),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
