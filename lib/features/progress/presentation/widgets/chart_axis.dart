import 'dart:math' as math;

/// Rounded axis bounds for an fl_chart Y-axis.
///
/// `niceAxis()` picks a clean step size (1, 2, 2.5, or 5 × 10^n) and a max
/// that's just above the data's true max, giving 4–5 evenly-spaced labels
/// at human-readable round numbers. Use it instead of `maxY: rawMax * 1.2`
/// to avoid the "21k stacked over 20k" Y-axis crowding bug.
class NiceAxis {
  const NiceAxis({required this.maxY, required this.interval});

  /// Use as `LineChartData.maxY` / `BarChartData.maxY`.
  final double maxY;

  /// Use as `FlGridData.horizontalInterval` AND as the
  /// `SideTitles.interval` on the left titles, so fl_chart only emits
  /// labels at multiples of [interval] (no overlap with maxY).
  final double interval;
}

/// Compute a nice rounded axis for a chart whose actual data max is [rawMax].
///
/// [minHeadroomFactor] adds breathing room above the top bar/point so the
/// highest value never crowds the top label. 1.10 = ~10% padding, which is
/// enough to keep a tooltip + dot visible above the top gridline.
NiceAxis niceAxis(double rawMax, {double minHeadroomFactor = 1.10}) {
  if (!rawMax.isFinite || rawMax <= 0) {
    return const NiceAxis(maxY: 1, interval: 0.25);
  }
  final target = rawMax * minHeadroomFactor;
  const niceSteps = <double>[1, 2, 2.5, 5];

  // Start one order of magnitude below the target — small enough that we
  // won't skip past the right tick count.
  var pow10 = math
      .pow(10, (math.log(target) / math.ln10).floor() - 1)
      .toDouble();
  if (pow10 < 1e-6) pow10 = 1e-6;

  for (var i = 0; i < 20; i++) {
    for (final base in niceSteps) {
      final step = base * pow10;
      // Prefer 4 ticks, then 5 — both produce a clean look with the chart
      // gridline density we use elsewhere.
      for (final ticks in const [4, 5]) {
        final maxY = step * ticks;
        if (maxY >= target) {
          return NiceAxis(maxY: maxY, interval: step);
        }
      }
    }
    pow10 *= 10;
  }
  // Pathological fallback — shouldn't happen in practice.
  return NiceAxis(maxY: target, interval: target / 4);
}

/// Same shape but for axes that need a non-zero minimum (e.g. body weight
/// hovering around 75kg — starting at 0 would compress the line to a flat
/// streak across the top). Picks a rounded minimum just below the data
/// minimum so the line breathes.
class NiceRange {
  const NiceRange({
    required this.minY,
    required this.maxY,
    required this.interval,
  });
  final double minY;
  final double maxY;
  final double interval;
}

NiceRange niceRange(
  double rawMin,
  double rawMax, {
  double minHeadroomFactor = 1.05,
}) {
  if (!rawMin.isFinite || !rawMax.isFinite || rawMin >= rawMax) {
    return const NiceRange(minY: 0, maxY: 1, interval: 0.25);
  }
  final span = (rawMax - rawMin) * minHeadroomFactor;
  // Pick a step that gives 4–5 intervals over the padded span.
  const niceSteps = <double>[1, 2, 2.5, 5];
  var pow10 = math
      .pow(10, (math.log(span) / math.ln10).floor() - 1)
      .toDouble();
  if (pow10 < 1e-6) pow10 = 1e-6;
  for (var i = 0; i < 20; i++) {
    for (final base in niceSteps) {
      final step = base * pow10;
      for (final ticks in const [4, 5]) {
        final candidateSpan = step * ticks;
        if (candidateSpan >= span) {
          // Anchor minY at a step boundary just below rawMin so labels are
          // round numbers (e.g. 70, 72.5, 75, …).
          final minY = (rawMin / step).floor() * step;
          final maxY = minY + candidateSpan;
          if (maxY >= rawMax * minHeadroomFactor) {
            return NiceRange(minY: minY, maxY: maxY, interval: step);
          }
        }
      }
    }
    pow10 *= 10;
  }
  return NiceRange(minY: rawMin, maxY: rawMax, interval: span / 4);
}

/// Shorthand for Y-axis tick labels: "21k" instead of "21000". Used by the
/// step chart and any other large-number axis.
String shortenAxisLabel(num n) {
  final abs = n.abs();
  if (abs >= 1000) {
    final v = n / 1000;
    // Drop the trailing .0 — "5k" reads better than "5.0k".
    return v == v.truncateToDouble()
        ? '${v.toInt()}k'
        : '${v.toStringAsFixed(1)}k';
  }
  return n.toInt().toString();
}
