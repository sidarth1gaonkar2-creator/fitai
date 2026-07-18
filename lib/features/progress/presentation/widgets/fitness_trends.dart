import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
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
///
/// Field Manual chrome: each chart is a single-series instrument in the one
/// live accent — no Apple-Fitness ring lineage (DESIGN.md anti-reference).
class FitnessTrends extends ConsumerWidget {
  const FitnessTrends({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);

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
        // Mono eyebrow designations over each instrument.
        Text('MOVE CALORIES — LAST 7 DAYS', style: FieldManual.label()),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: moveAsync.when(
            loading: () => const ShimmerBox(
                width: double.infinity, height: 160, borderRadius: 8),
            error: (_, _) => const SizedBox.shrink(),
            data: (values) => _Bars(
              values: values,
              labels: labels,
              barColor: palette.accent,
              unit: 'kcal',
              emptyMessage: 'No active calories tracked this week',
              semanticsName: 'Move calories bar chart, last 7 days',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('EXERCISE MINUTES — LAST 7 DAYS', style: FieldManual.label()),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: exerciseAsync.when(
            loading: () => const ShimmerBox(
                width: double.infinity, height: 160, borderRadius: 8),
            error: (_, _) => const SizedBox.shrink(),
            data: (values) => _Bars(
              values: values,
              labels: labels,
              barColor: palette.accent,
              unit: 'min',
              emptyMessage: 'No exercise data this week',
              semanticsName: 'Exercise minutes bar chart, last 7 days',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('STEPS — LAST 7 DAYS', style: FieldManual.label()),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: stepsAsync.when(
            loading: () => const ShimmerBox(
                width: double.infinity, height: 180, borderRadius: 8),
            error: (_, _) => const SizedBox.shrink(),
            data: (steps) => _Bars(
              values: steps.map((e) => e.toDouble()).toList(),
              labels: labels,
              barColor: palette.accent,
              unit: '',
              emptyMessage: 'No steps tracked this week',
              semanticsName: 'Steps bar chart, last 7 days',
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
                semanticsLabel: restingHr != null
                    ? 'Resting heart rate: $restingHr beats per minute'
                    : 'Resting heart rate: no data',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'VO₂ max',
                value: vo2 != null ? vo2.toStringAsFixed(1) : '—',
                unit: 'mL/kg·min',
                semanticsLabel: vo2 != null
                    ? 'VO2 max: ${vo2.toStringAsFixed(1)} '
                        'millilitres per kilogram per minute'
                    : 'VO2 max: no data',
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
    required this.emptyMessage,
    required this.semanticsName,
  });

  final List<double> values;
  final List<String> labels;
  final Color barColor;
  final String unit;

  /// Shown when every value in `values` is zero. Drawing a chart full of
  /// zero bars produces nonsensical axis labels (0, 0, 0, 0) and signals
  /// "broken" to the user; a one-line message reads cleaner.
  final String emptyMessage;

  /// Spoken chart description prefix, e.g. "Steps bar chart, last 7 days".
  final String semanticsName;

  @override
  Widget build(BuildContext context) {
    final allZero = values.isEmpty || values.every((v) => v <= 0);
    if (allZero) {
      return Container(
        decoration: BoxDecoration(
          color: FieldManual.field,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FieldManual.hairline),
        ),
        alignment: Alignment.center,
        child: Text(
          emptyMessage,
          style: FieldManual.body(color: FieldManual.mutedBone),
        ),
      );
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final total = values.fold<double>(0, (sum, v) => sum + v);
    final axis = niceAxis(maxValue, minHeadroomFactor: 1.15);

    return Semantics(
      label: '$semanticsName: total ${total.round()}'
          '${unit.isEmpty ? '' : ' $unit'}, best day ${maxValue.round()}'
          '${unit.isEmpty ? '' : ' $unit'}.',
      child: BarChart(
        BarChartData(
          maxY: axis.maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: axis.interval,
            getDrawingHorizontalLine: chartGridLine,
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: chartLeftAxisReservedSize,
                interval: axis.interval,
                getTitlesWidget: (value, _) {
                  if (value > axis.maxY - axis.interval * 0.01) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    shortenAxisLabel(value.toInt()),
                    style: chartAxisLabelStyle,
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
                  if (i < 0 || i >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[i], style: chartAxisLabelStyle),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => FieldManual.fieldRaised,
              tooltipBorder: chartTooltipBorder,
              tooltipRoundedRadius: 4,
              getTooltipItem: (_, _, rod, _) => BarTooltipItem(
                unit.isEmpty
                    ? '${rod.toY.toInt()}'
                    : '${rod.toY.toInt()} $unit',
                chartTooltipTextStyle,
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
                    borderRadius: BorderRadius.circular(2),
                    color: barColor,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// FM stat readout: mono eyebrow label over a bone instrument value on a
/// field panel (DESIGN.md §Stat Readout).
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.semanticsLabel,
  });

  final String label;
  final String value;
  final String unit;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: FieldManual.field,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FieldManual.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label.toUpperCase(), style: FieldManual.label(fontSize: 10)),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: FieldManual.readout(fontSize: 22)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      unit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FieldManual.label(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
