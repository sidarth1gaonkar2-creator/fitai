import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../providers/health_providers.dart';
import 'chart_axis.dart';

/// "Fitness Trends" section on the Progress screen.
///
/// Visible only on iOS + connected (the caller gates this). Shows:
///   * Weekly Move calories bar chart (active energy burned).
///   * Weekly Exercise minutes bar chart (with empty state when no data).
///   * Weekly Steps bar chart.
///   * Resting Heart Rate stat card.
///   * VO2 Max stat card — only when data is available (not in `health 13.3.1`
///     today, but the card is here for the day it lands).
///
/// The earlier "Calories burned" line chart + standalone "Activity Trends"
/// section was duplicate data (Apple Health's daily active energy burned IS
/// the Move calories number). Steps moved here so the three Apple-Health
/// charts live together and the user only sees each metric once.
class FitnessTrends extends ConsumerWidget {
  const FitnessTrends({super.key});

  static const _moveColor = Color(0xFFFA114F);
  static const _exerciseColor = Color(0xFF92E82A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    final moveAsync =
        ref.watch(weeklyHealthDataProvider(HealthDataType.ACTIVE_ENERGY_BURNED));
    final exerciseAsync =
        ref.watch(weeklyHealthDataProvider(HealthDataType.EXERCISE_TIME));
    final stepsAsync = ref.watch(weeklyStepsProvider);
    final restingHr = ref.watch(restingHeartRateProvider).valueOrNull;
    final vo2 = ref.watch(latestVO2MaxProvider).valueOrNull;
    final labels = _last7DayLabels();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Move calories (last 7 days)',
          style: textTheme.bodyMedium?.copyWith(
            color: palette.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: moveAsync.when(
            loading: () => const ShimmerBox(
                width: double.infinity, height: 160, borderRadius: 12),
            error: (_, _) => const SizedBox.shrink(),
            data: (values) => _Bars(
              values: values,
              labels: labels,
              barColor: _moveColor,
              unit: 'kcal',
              palette: palette,
              emptyMessage: 'No active calories tracked this week',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Exercise minutes (last 7 days)',
          style: textTheme.bodyMedium?.copyWith(
            color: palette.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: exerciseAsync.when(
            loading: () => const ShimmerBox(
                width: double.infinity, height: 160, borderRadius: 12),
            error: (_, _) => const SizedBox.shrink(),
            data: (values) => _Bars(
              values: values,
              labels: labels,
              barColor: _exerciseColor,
              unit: 'min',
              palette: palette,
              emptyMessage: 'No exercise data this week',
            ),
          ),
        ),
        const SizedBox(height: 16),
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
                width: double.infinity, height: 180, borderRadius: 12),
            error: (_, _) => const SizedBox.shrink(),
            data: (steps) => _Bars(
              values: steps.map((e) => e.toDouble()).toList(),
              labels: labels,
              barColor: palette.accent,
              unit: '',
              palette: palette,
              emptyMessage: 'No steps tracked this week',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Resting HR',
                value: restingHr != null ? '$restingHr' : '—',
                unit: 'bpm',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'VO₂ max',
                value: vo2 != null ? vo2.toStringAsFixed(1) : '—',
                unit: 'mL/kg·min',
              ),
            ),
          ],
        ),
      ],
    );
  }

  static List<String> _last7DayLabels() {
    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    final labels = <String>[];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      labels.add(weekdayLabels[(d.weekday - 1).clamp(0, 6)]);
    }
    return labels;
  }
}

class _Bars extends StatelessWidget {
  const _Bars({
    required this.values,
    required this.labels,
    required this.barColor,
    required this.unit,
    required this.palette,
    required this.emptyMessage,
  });

  final List<double> values;
  final List<String> labels;
  final Color barColor;
  final String unit;
  final Palette palette;

  /// Shown when every value in `values` is zero. Drawing a chart full of
  /// zero bars produces nonsensical axis labels (0, 0, 0, 0) and signals
  /// "broken" to the user; a one-line message reads cleaner.
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final allZero = values.isEmpty || values.every((v) => v <= 0);
    if (allZero) {
      return Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        alignment: Alignment.center,
        child: Text(
          emptyMessage,
          style: textTheme.bodyMedium?.copyWith(
            color: palette.textSecondary,
          ),
        ),
      );
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final axis = niceAxis(maxValue, minHeadroomFactor: 1.15);

    return BarChart(
      BarChartData(
        maxY: axis.maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: axis.interval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: palette.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
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
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (_, _, rod, _) => BarTooltipItem(
              unit.isEmpty
                  ? '${rod.toY.toInt()}'
                  : '${rod.toY.toInt()} $unit',
              TextStyle(color: palette.text, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                  color: barColor,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: palette.text,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: textTheme.bodySmall
                    ?.copyWith(color: palette.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
