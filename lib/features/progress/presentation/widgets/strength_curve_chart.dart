import 'package:fl_chart/fl_chart.dart';
import 'chart_axis.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../providers/progress_providers.dart';
import '../../../../providers/unit_system_provider.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              );
            }
            return DropdownMenu<String>(
              hintText: 'Select exercise',
              initialSelection: selected,
              dropdownMenuEntries: names
                  .map((n) => DropdownMenuEntry(value: n, label: n))
                  .toList(),
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
        _MetricTabs(metric: metric),
        const SizedBox(height: 12),
        if (selected != null)
          _CurveChart(exerciseName: selected, metric: metric)
        else
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Select an exercise above.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricTabs extends ConsumerWidget {
  const _MetricTabs({required this.metric});

  final StrengthMetric metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _tab(ref, palette, StrengthMetric.oneRepMax, 'Est. 1RM'),
          _tab(ref, palette, StrengthMetric.maxWeight, 'Max Weight'),
          _tab(ref, palette, StrengthMetric.volume, 'Volume'),
        ],
      ),
    );
  }

  Widget _tab(
    WidgetRef ref,
    Palette palette,
    StrengthMetric value,
    String label,
  ) {
    final active = metric == value;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(strengthMetricProvider.notifier).state = value;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? palette.accent : null,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: active ? Colors.white : palette.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _CurveChart extends ConsumerWidget {
  const _CurveChart({required this.exerciseName, required this.metric});

  final String exerciseName;
  final StrengthMetric metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final units = ref.watch(unitSystemProvider);
    final unitLabel = UnitConverter.weightUnit(units);
    final async = ref.watch(strengthCurveProvider(exerciseName));

    return async.when(
      loading: () => const ShimmerBox(
          width: double.infinity, height: 200, borderRadius: 12),
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
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
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

        final color = switch (metric) {
          StrengthMetric.oneRepMax => colorScheme.primary,
          StrengthMetric.maxWeight => colorScheme.tertiary,
          StrengthMetric.volume => colorScheme.secondary,
        };

        final caption = metric == StrengthMetric.volume
            ? 'Volume ($unitLabel)'
            : 'Weight ($unitLabel)';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                caption,
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            SizedBox(
              height: 200,
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
                bottomTitles: dateAxisTitles(
                  firstDate: firstDate,
                  spanDays: spanDays,
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    interval: range.interval,
                    getTitlesWidget: (value, meta) {
                      if (value > range.maxY - range.interval * 0.01) {
                        return const SizedBox.shrink();
                      }
                      // Whole numbers only, no per-label unit suffix — the
                      // unit is shown once in the caption above the chart so
                      // the labels never wrap ("220.5 lbs" → "220").
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          metric == StrengthMetric.volume
                              ? _volumeAxisLabel(value)
                              : value.toStringAsFixed(0),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
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
                            metric == StrengthMetric.volume
                                ? _formatVolume(s.y, unitLabel)
                                : '${s.y.toStringAsFixed(1)} $unitLabel',
                            TextStyle(
                              color: colorScheme.onSurface,
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
                  curveSmoothness: 0.25,
                  color: color,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 3.5,
                      color: color,
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
          ),
            ),
          ],
        );
      },
    );
  }

  /// Volume Y-axis label — abbreviated and unit-less (the unit lives in the
  /// caption above the chart): "12k", "8.5k", "850".
  static String _volumeAxisLabel(double value) {
    if (value >= 1000) {
      final v = value / 1000;
      return v == v.truncateToDouble()
          ? '${v.toInt()}k'
          : '${v.toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  /// Volume tooltip label — keeps the unit suffix for the touch tooltip.
  static String _formatVolume(double value, String unitLabel) {
    if (value >= 10000) return '${(value / 1000).toStringAsFixed(0)}k';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return '${value.toStringAsFixed(0)} $unitLabel';
  }
}
