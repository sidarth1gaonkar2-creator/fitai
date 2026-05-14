import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../models/weight_entry.dart';
import '../../../../providers/unit_system_provider.dart';

class WeightChart extends ConsumerWidget {
  const WeightChart({
    super.key,
    required this.entries,
    this.healthEntries = const [],
  });

  final List<WeightEntry> entries;

  /// Optional second series sourced from Apple Health. When non-empty, the
  /// chart shows both lines with a legend.
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

    final rawSpots = <FlSpot>[];
    final maSpots = <FlSpot>[];
    final firstDate = entries.first.date;

    for (var i = 0; i < entries.length; i++) {
      final x = entries[i].date.difference(firstDate).inDays.toDouble();
      rawSpots.add(FlSpot(x, toDisplay(entries[i].weightKg)));

      // 7-day moving average
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

    final allValues = [
      ...entries.map((e) => toDisplay(e.weightKg)),
      ...healthEntries.map((e) => toDisplay(e.weightKg)),
    ];
    final minY = allValues.reduce((a, b) => a < b ? a : b) - 2;
    final maxY = allValues.reduce((a, b) => a > b ? a : b) + 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (healthEntries.isNotEmpty) ...[
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
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '${value.toInt()}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
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
            // Raw weight (dotted)
            LineChartBarData(
              spots: rawSpots,
              isCurved: false,
              color: colorScheme.primary.withValues(alpha: 0.35),
              barWidth: 1.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: colorScheme.primary.withValues(alpha: 0.5),
                  strokeWidth: 0,
                ),
              ),
              dashArray: [4, 4],
              belowBarData: BarAreaData(show: false),
            ),
            // 7-day moving average (solid)
            LineChartBarData(
              spots: maSpots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: colorScheme.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
            // Apple Health overlay (orange dashed)
            if (healthSpots.isNotEmpty)
              LineChartBarData(
                spots: healthSpots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: const Color(0xFFFF9F0A),
                barWidth: 2,
                dashArray: const [6, 4],
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
