import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../models/weight_entry.dart';
import '../../../../providers/unit_system_provider.dart';
import 'chart_axis.dart';

/// Body-weight line chart.
///
/// Renders ONE solid line per data source the user actually has:
///   * Manual entries only  → single solid line, no legend, no fill.
///   * Apple Health entries only → same (one solid line, no legend).
///   * Both sources → two solid lines (manual = primary colour, health =
///     amber) with a tidy two-dot legend above the chart, still no fill.
///
/// We intentionally don't show a 7-day-MA-vs-raw split anymore — the screenshot
/// audit flagged the dotted-blue + solid-blue overlay as confusing, and the
/// MA is what users actually care about for trend reading.
class WeightChart extends ConsumerWidget {
  const WeightChart({
    super.key,
    required this.entries,
    this.healthEntries = const [],
  });

  final List<WeightEntry> entries;

  /// Optional second series sourced from Apple Health. When non-empty AND
  /// distinct from the manual entries, the chart shows both lines + a
  /// legend.
  final List<({DateTime date, double weightKg})> healthEntries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final units = ref.watch(unitSystemProvider);
    final isImperial = units == UnitSystem.imperial;

    if (entries.length < 2) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Log your weight to see trends.',
            style: textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    double toDisplay(double kg) =>
        isImperial ? UnitConverter.kgToLbs(kg) : kg;
    final unitLabel = UnitConverter.weightUnit(units);

    // Build the manual series as a 7-day moving average — that's the line
    // users want to see (raw daily values are too noisy on phone-width).
    final maSpots = <FlSpot>[];
    final firstDate = entries.first.date;
    for (var i = 0; i < entries.length; i++) {
      final x = entries[i].date.difference(firstDate).inDays.toDouble();
      double sum = 0;
      int count = 0;
      for (var j = i; j >= 0 && (i - j) < 7; j--) {
        sum += toDisplay(entries[j].weightKg);
        count++;
      }
      maSpots.add(FlSpot(x, sum / count));
    }

    final healthSpots = <FlSpot>[
      for (final h in healthEntries)
        FlSpot(
          h.date.difference(firstDate).inDays.toDouble(),
          toDisplay(h.weightKg),
        ),
    ];

    final hasHealth = healthSpots.isNotEmpty;

    final allValues = <double>[
      ...maSpots.map((s) => s.y),
      ...healthSpots.map((s) => s.y),
    ];
    final rawMin = allValues.reduce((a, b) => a < b ? a : b);
    final rawMax = allValues.reduce((a, b) => a > b ? a : b);
    // Tight headroom — body weight rarely swings far, so a couple of units
    // of padding is enough for a clean read.
    final range = niceRange(
      rawMin - 1,
      rawMax + 1,
      minHeadroomFactor: 1.02,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend only when both sources contribute — single-source charts
        // don't need it.
        if (hasHealth) ...[
          Row(
            children: [
              _LegendDot(color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                'Manual',
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              const _LegendDot(color: Color(0xFFFF9F0A)),
              const SizedBox(width: 4),
              Text(
                'Apple Health',
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: range.minY,
              maxY: range.maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: range.interval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: range.interval,
                    getTitlesWidget: (value, meta) {
                      if (value > range.maxY - range.interval * 0.01) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          '${value.toInt()}',
                          style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y.toStringAsFixed(1)} $unitLabel',
                        TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                // Manual series — solid line, no area fill, small dots.
                LineChartBarData(
                  spots: maSpots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: colorScheme.primary,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                      radius: 2.5,
                      color: colorScheme.primary,
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
                // Apple Health series — second solid line, only when present.
                if (hasHealth)
                  LineChartBarData(
                    spots: healthSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: const Color(0xFFFF9F0A),
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                        radius: 2.5,
                        color: const Color(0xFFFF9F0A),
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
