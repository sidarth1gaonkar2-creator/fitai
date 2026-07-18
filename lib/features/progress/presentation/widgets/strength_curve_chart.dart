import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../providers/progress_providers.dart';
import '../../../../providers/unit_system_provider.dart';
import 'chart_axis.dart';
import '../../../../core/widgets/fm_segmented.dart';
import 'strength_chart.dart' show ExercisePickerDropdown;

/// Which metric the user is currently viewing on the strength curve chart.
/// Persisted in a StateProvider so toggling the metric doesn't reset the
/// selected exercise.
enum StrengthMetric { oneRepMax, maxWeight, volume }

/// Default to the actual heaviest weight lifted per session — that's the most
/// intuitive read of "am I getting stronger?". Estimated 1RM and Volume remain
/// available via the toggle.
final strengthMetricProvider =
    StateProvider<StrengthMetric>((_) => StrengthMetric.maxWeight);

/// Detailed strength visualization — picks an exercise and toggles between
/// estimated 1RM, max weight per session, and total session volume. Built
/// to drop into the existing Progress tab.
class StrengthCurveChart extends ConsumerWidget {
  const StrengthCurveChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseNamesAsync = ref.watch(exerciseNamesProvider);
    final selected = ref.watch(selectedExerciseProvider);
    final metric = ref.watch(strengthMetricProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exercise picker (same provider as the existing chart so users
        // don't have to re-pick when switching tabs).
        exerciseNamesAsync.when(
          data: (names) {
            if (names.isEmpty) {
              return Text(
                'Complete workouts to track strength.',
                style: FieldManual.body(color: FieldManual.mutedBone),
              );
            }
            return ExercisePickerDropdown(
              names: names,
              selected: selected,
              onSelected: (value) =>
                  ref.read(selectedExerciseProvider.notifier).state = value,
            );
          },
          loading: () => const ShimmerBox(width: 200, height: 56),
          error: (_, _) => ErrorCard(
            message: 'Could not load exercises.',
            onRetry: () => ref.invalidate(exerciseNamesProvider),
          ),
        ),
        const SizedBox(height: 10),
        FmSegmented<StrengthMetric>(
          segments: const [
            (StrengthMetric.oneRepMax, 'Est. 1RM'),
            (StrengthMetric.maxWeight, 'Max Weight'),
            (StrengthMetric.volume, 'Volume'),
          ],
          selected: metric,
          fontSize: 10,
          onChanged: (value) =>
              ref.read(strengthMetricProvider.notifier).state = value,
        ),
        const SizedBox(height: 12),
        if (selected != null)
          _CurveChart(exerciseName: selected, metric: metric)
        else
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Select an exercise above.',
                style: FieldManual.body(color: FieldManual.mutedBone),
              ),
            ),
          ),
      ],
    );
  }
}

class _CurveChart extends ConsumerWidget {
  const _CurveChart({required this.exerciseName, required this.metric});

  final String exerciseName;
  final StrengthMetric metric;

  String get _metricLabel => switch (metric) {
        StrengthMetric.oneRepMax => 'estimated one-rep max',
        StrengthMetric.maxWeight => 'max weight',
        StrengthMetric.volume => 'volume',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final units = ref.watch(unitSystemProvider);
    final unitLabel = UnitConverter.weightUnit(units);
    final async = ref.watch(strengthCurveProvider(exerciseName));

    return async.when(
      loading: () => const ShimmerBox(
          width: double.infinity, height: 200, borderRadius: 8),
      error: (_, _) => ErrorCard(
        message: 'Could not load strength data.',
        onRetry: () =>
            ref.invalidate(strengthCurveProvider(exerciseName)),
      ),
      data: (points) {
        if (points.length < 2) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Need at least 2 sessions to chart.',
                style: FieldManual.body(color: FieldManual.mutedBone),
              ),
            ),
          );
        }

        double valueKgFor(({
          DateTime date,
          double oneRepMaxKg,
          double maxWeightKg,
          double volumeKg,
        }) p) {
          switch (metric) {
            case StrengthMetric.oneRepMax:
              return p.oneRepMaxKg;
            case StrengthMetric.maxWeight:
              return p.maxWeightKg;
            case StrengthMetric.volume:
              return p.volumeKg;
          }
        }

        final firstDate = points.first.date;
        final spanDays =
            points.last.date.difference(firstDate).inDays.toDouble();
        final spots = <FlSpot>[];
        for (final p in points) {
          final kg = valueKgFor(p);
          final display =
              UnitConverter.kgToDisplayWeight(kg, units);
          spots.add(FlSpot(
            p.date.difference(firstDate).inDays.toDouble(),
            display,
          ));
        }

        final values = spots.map((s) => s.y).toList();
        final rawMin = values.reduce((a, b) => a < b ? a : b);
        final rawMax = values.reduce((a, b) => a > b ? a : b);
        final range = niceRange(
          rawMin,
          rawMax == rawMin ? rawMax + 5 : rawMax,
          minHeadroomFactor: 1.10,
        );

        final caption = metric == StrengthMetric.volume
            ? 'VOLUME ($unitLabel)'
            : 'WEIGHT ($unitLabel)';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                caption.toUpperCase(),
                style: FieldManual.label(),
              ),
            ),
            Semantics(
              label: '$exerciseName $_metricLabel chart: '
                  '${points.length} sessions since '
                  '${formatShortDate(firstDate)}, latest '
                  '${spots.last.y.toStringAsFixed(0)} $unitLabel.',
              child: SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    minY: range.minY,
                    maxY: range.maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: range.interval,
                      getDrawingHorizontalLine: chartGridLine,
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
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
                            // No per-label unit suffix — the unit is shown
                            // once in the caption above the chart. Fractional
                            // intervals keep one decimal ("72.5" must not
                            // truncate to "72").
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                metric == StrengthMetric.volume
                                    ? shortenAxisLabel(value)
                                    : formatAxisValue(value, range.interval),
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
                        getTooltipItems: (spots) => spots
                            .map((s) => LineTooltipItem(
                                  metric == StrengthMetric.volume
                                      ? _formatVolume(s.y, unitLabel)
                                      : '${s.y.toStringAsFixed(1)} $unitLabel',
                                  chartTooltipTextStyle,
                                ))
                            .toList(),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.25,
                        color: palette.accent,
                        barWidth: 2,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                            radius: 3.5,
                            color: palette.accent,
                            strokeWidth: 0,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: palette.accent.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Volume tooltip label — keeps the unit suffix for the touch tooltip.
  static String _formatVolume(double value, String unitLabel) {
    if (value >= 10000) return '${(value / 1000).toStringAsFixed(0)}k';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return '${value.toStringAsFixed(0)} $unitLabel';
  }
}
