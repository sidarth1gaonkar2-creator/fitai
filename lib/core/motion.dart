import 'package:flutter/widgets.dart';

/// Motion tokens for value meters — rings, bars, and their number readouts.
/// One system: every meter sweeps and every readout counts on the same
/// clock, and reduced motion collapses every duration to zero so values
/// snap instantly.
abstract final class Motion {
  static const Duration meterDuration = Duration(milliseconds: 800);
  static const Curve meterCurve = Curves.easeOutCubic;
  static const Duration countDuration = Duration(milliseconds: 800);

  /// [meterDuration], honoring the platform reduced-motion setting.
  static Duration meterDurationOf(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : meterDuration;

  /// [countDuration], honoring the platform reduced-motion setting.
  static Duration countDurationOf(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : countDuration;
}
