import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../providers/progress_providers.dart';
import '../../../../providers/unit_system_provider.dart';
import 'chart_axis.dart';

class StrengthChart extends ConsumerWidget {
  const StrengthChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final exerciseNamesAsync = ref.watch(exerciseNamesProvider);
    final selected = ref.watch(selectedExerciseProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exercise picker
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
        const SizedBox(height: 12),
        // Chart
        if (selected != null)
          _StrengthLineChart(exerciseName: selected)
        else
          SizedBox(
            height: 180,
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

class _StrengthLineChart extends ConsumerWidget {
  const _StrengthLineChart({required this.exerciseName});

  final String exerciseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final historyAsync = ref.watch(strengthHistoryProvider(exerciseName));
    final units = ref.watch(unitSystemProvider);

    return historyAsync.when(
      loading: () =>
          const ShimmerBox(width: double.infinity, height: 200, borderRadius: 12),
      error: (_, _) => ErrorCard(
        message: 'Could not load strength data.',
        onRetry: () => ref.invalidate(strengthHistoryProvider(exerciseName)),
      ),
      data: (points) {
        if (points.length < 2) {
          return SizedBox(
            height: 180,
            child: Center(
              child: Text(
                'Need at least 2 sessions to chart.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
          );
        }

        final firstDate = points.first.date;
        final spanDays =
            points.last.date.difference(firstDate).inDays.toDouble();
        // Convert to the user's display unit BEFORE computing the axis so the
        // gridline steps land on round numbers in lbs/kg. Computing the range
        // in kg and formatting in lbs produced ugly labels like "220.5 lbs".
        final unitLabel = UnitConverter.weightUnit(units);
        final spots = points
            .map((p) => FlSpot(
                  p.date.difference(firstDate).inDays.toDouble(),
                  UnitConverter.kgToDisplayWeight(p.weight, units),
                ))
            .toList();

        final weights = spots.map((s) => s.y).toList();
        final rawMin = weights.reduce((a, b) => a < b ? a : b);
        final rawMax = weights.reduce((a, b) => a > b ? a : b);
        final range = niceRange(
          rawMin,
          rawMax == rawMin ? rawMax + 5 : rawMax,
          minHeadroomFactor: 1.10,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                'Weight ($unitLabel)',
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
                    reservedSize: 44,
                    interval: range.interval,
                    getTitlesWidget: (value, meta) {
                      if (value > range.maxY - range.interval * 0.01) {
                        return const SizedBox.shrink();
                      }
                      // Whole numbers only, no per-label unit suffix — the
                      // unit is shown once in the caption above the chart.
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          value.toStringAsFixed(0),
                          style: textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
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
                            '${s.y.toStringAsFixed(0)} $unitLabel',
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
                  color: colorScheme.tertiary,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 3.5,
                      color: colorScheme.tertiary,
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: colorScheme.tertiary.withValues(alpha: 0.08),
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
}
