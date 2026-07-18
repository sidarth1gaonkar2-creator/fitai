import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../models/weight_entry.dart';
import '../../../../providers/unit_system_provider.dart';
import 'chart_axis.dart';

/// Body-weight line chart — single solid series, no legend.
///
/// Renders the user's manually-logged weight entries as-is: each entry sits
/// at its true logged value (no moving average — only fl_chart's visual
/// curve smoothing). The Apple Health weight series was removed: it visually
/// confused the chart (two overlapping lines for what users perceive as
/// "one number") and the data is already syncable into manual entries
/// via the import button on Settings → Apple Health.
class WeightChart extends ConsumerWidget {
  const WeightChart({
    super.key,
    required this.entries,
  });

  final List<WeightEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final units = ref.watch(unitSystemProvider);
    final isImperial = units == UnitSystem.imperial;

    // 0 entries: nothing logged yet — invite the first log rather than drawing
    // an empty axis.
    if (entries.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Log your first weight to see your trend.',
            textAlign: TextAlign.center,
            style: FieldManual.body(color: FieldManual.mutedBone),
          ),
        ),
      );
    }

    double toDisplay(double kg) =>
        isImperial ? UnitConverter.kgToLbs(kg) : kg;
    final unitLabel = UnitConverter.weightUnit(units);

    // Plot the actual logged values (converted to the viewer's unit) so each
    // entry sits at its true Y — a freshly logged 183 lb shows at 183, not at a
    // smoothed average of recent entries. fl_chart's curve smoothing keeps the
    // line readable without distorting where the points land.
    final spots = <FlSpot>[];
    final firstDate = entries.first.date;
    final spanDays = entries.last.date.difference(firstDate).inDays.toDouble();
    for (var i = 0; i < entries.length; i++) {
      final x = entries[i].date.difference(firstDate).inDays.toDouble();
      spots.add(FlSpot(x, toDisplay(entries[i].weightKg)));
    }

    final rawMin = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final rawMax = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    // A single entry needs explicit bounds: one point collapses fl_chart's
    // X-range (minX == maxX → divide-by-zero → blank). Give the lone point a
    // ±0.5-day window and a rounded ±2-unit Y band so it renders as a single
    // centered dot with sane axes instead of nothing.
    final single = entries.length == 1;
    final NiceRange range;
    final double? minX;
    final double? maxX;
    if (single) {
      final minY = (rawMin - 2).floorToDouble();
      range = NiceRange(minY: minY, maxY: minY + 4, interval: 1);
      minX = -0.5;
      maxX = 0.5;
    } else {
      // Tight headroom — body weight rarely swings far, so a couple of units
      // of padding is enough for a clean read.
      range = niceRange(rawMin - 1, rawMax + 1, minHeadroomFactor: 1.02);
      minX = null; // let fl_chart derive 0..spanDays from the spots
      maxX = null;
    }

    final latest = toDisplay(entries.last.weightKg);
    return Semantics(
      label: 'Body weight trend chart: ${entries.length} '
          '${entries.length == 1 ? 'entry' : 'entries'} since '
          '${formatShortDate(firstDate)}, latest '
          '${latest.toStringAsFixed(1)} $unitLabel.',
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minX: minX,
            maxX: maxX,
            minY: range.minY,
            maxY: range.maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: range.interval,
              getDrawingHorizontalLine: chartGridLine,
            ),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: dateAxisTitles(
                firstDate: firstDate,
                spanDays: spanDays,
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: chartLeftAxisReservedSize,
                  interval: range.interval,
                  getTitlesWidget: (value, meta) {
                    if (value > range.maxY - range.interval * 0.01) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        // Fractional intervals keep one decimal — a 72.5
                        // tick must not truncate to 72.
                        formatAxisValue(value, range.interval),
                        style: chartAxisLabelStyle,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => FieldManual.fieldRaised,
                tooltipBorder: chartTooltipBorder,
                tooltipRoundedRadius: 4,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      '${spot.y.toStringAsFixed(1)} $unitLabel',
                      chartTooltipTextStyle,
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: palette.accent,
                barWidth: 2,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                    radius: single ? 5 : 2.5,
                    color: palette.accent,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
