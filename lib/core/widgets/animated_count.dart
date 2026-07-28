import 'package:flutter/widgets.dart';

import '../motion.dart';

/// Animated number readout: when [value] changes, [builder] receives values
/// counting from the previous number to the new one on the [Motion] clock —
/// in sync with the meter sweeping beside it. The first build counts up from
/// zero once, matching the meters' entry sweep; reduced motion snaps
/// straight to the target.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.builder,
  });

  final double value;
  final Widget Function(BuildContext context, double value) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: Motion.countDurationOf(context),
      curve: Motion.meterCurve,
      builder: (context, animated, _) => builder(context, animated),
    );
  }
}
