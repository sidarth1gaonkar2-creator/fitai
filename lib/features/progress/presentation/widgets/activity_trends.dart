import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../providers/health_providers.dart';
import 'chart_axis.dart';

/// Weekly activity charts powered by Apple Health.
///
/// Top section — daily steps for the last 7 days (bar chart).
/// Bottom section — daily active calories burned (line chart).
class ActivityTrends extends ConsumerWidget {
  const ActivityTrends({super.key});

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  List<String> _last7DayLabels() {
    // Oldest-first labels matching the provider output.
    final now = DateTime.now();
    final labels = <String>[];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      // weekday is 1=Mon..7=Sun
      labels.add(_weekdayLabels[(d.weekday - 1).clamp(0, 6)]);
    }
    return labels;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(weeklyStepsProvider);
    final caloriesAsync = ref.watch(weeklyActiveCaloriesProvider);
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final labels = _last7DayLabels();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Steps (last 7 days)',
          style: textTheme.bodyMedium?.copyWith(
            color: palette.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: stepsAsync.when(
            loading: () => const ShimmerBox(
              width: double.infinity,
              height: 180,
              borderRadius: 12,
            ),
            error: (_, _) => Center(
              child: Text(
                'Could not load steps',
                style: TextStyle(color: palette.textSecondary),
              ),
            ),
            data: (steps) =>
                _StepsBarChart(steps: steps, labels: labels, palette: palette),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Calories burned (last 7 days)',
          style: textTheme.bodyMedium?.copyWith(
            color: palette.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: caloriesAsync.when(
            loading: () => const ShimmerBox(
              width: double.infinity,
              height: 180,
              borderRadius: 12,
            ),
            error: (_, _) => Center(
              child: Text(
                'Could not load calories',
                style: TextStyle(color: palette.textSecondary),
              ),
            ),
            data: (cals) => _CaloriesLineChart(
              calories: cals,
              labels: labels,
              palette: palette,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepsBarChart extends StatelessWidget {
  const _StepsBarChart({
    required this.steps,
    required this.labels,
    required this.palette,
  });

  final List<int> steps;
  final List<String> labels;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxValue = steps.isEmpty
        ? 1000.0
        : (steps.reduce((a, b) => a > b ? a : b)).toDouble();
    // Round the axis to the next clean step (5k / 10k / 25k) so labels
    // don't end up as ugly multiples like "21k" stacked next to "20k".
    final axis = niceAxis(maxValue, minHeadroomFactor: 1.15);

    return BarChart(
      BarChartData(
        maxY: axis.maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: axis.interval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: palette.border,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: axis.interval,
              getTitlesWidget: (value, _) {
                // Hide the duplicate top label that fl_chart sometimes
                // draws when the bar reaches maxY exactly.
                if (value > axis.maxY - axis.interval * 0.01) {
                  return const SizedBox.shrink();
                }
                return Text(
                  shortenAxisLabel(value.toInt()),
                  style: textTheme.bodySmall
                      ?.copyWith(color: palette.textSecondary),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[i],
                    style: textTheme.bodySmall
                        ?.copyWith(color: palette.textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, _) {
              return BarTooltipItem(
                '${rod.toY.toInt()}',
                TextStyle(
                  color: palette.text,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        barGroups: [
          for (int i = 0; i < steps.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: steps[i].toDouble(),
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                  color: palette.accent,
                ),
              ],
            ),
        ],
      ),
    );
  }

}

class _CaloriesLineChart extends StatelessWidget {
  const _CaloriesLineChart({
    required this.calories,
    required this.labels,
    required this.palette,
  });

  final List<double> calories;
  final List<String> labels;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxValue = calories.isEmpty
        ? 500.0
        : calories.reduce((a, b) => a > b ? a : b);
    final axis = niceAxis(maxValue, minHeadroomFactor: 1.15);

    final spots = <FlSpot>[
      for (int i = 0; i < calories.length; i++)
        FlSpot(i.toDouble(), calories[i]),
    ];

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: axis.maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: axis.interval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: palette.border,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: axis.interval,
              getTitlesWidget: (value, _) {
                if (value > axis.maxY - axis.interval * 0.01) {
                  return const SizedBox.shrink();
                }
                return Text(
                  shortenAxisLabel(value.toInt()),
                  style: textTheme.bodySmall
                      ?.copyWith(color: palette.textSecondary),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[i],
                    style: textTheme.bodySmall
                        ?.copyWith(color: palette.textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${s.y.toInt()} kcal',
                      TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xFFFF9F0A),
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 3,
                color: const Color(0xFFFF9F0A),
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFFF9F0A).withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}
