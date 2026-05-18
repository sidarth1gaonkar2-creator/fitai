import 'package:fl_chart/fl_chart.dart';
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

final strengthMetricProvider =
    StateProvider<StrengthMetric>((_) => StrengthMetric.oneRepMax);

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
        final minY = values.reduce((a, b) => a < b ? a : b);
        final maxY = values.reduce((a, b) => a > b ? a : b);
        final pad = (maxY - minY) * 0.1;
        final lowerY = (minY - (pad == 0 ? 5 : pad)).clamp(0, double.infinity);

        final color = switch (metric) {
          StrengthMetric.oneRepMax => colorScheme.primary,
          StrengthMetric.maxWeight => colorScheme.tertiary,
          StrengthMetric.volume => colorScheme.secondary,
        };

        return SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: lowerY.toDouble(),
              maxY: maxY + (pad == 0 ? 5 : pad),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
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
                    reservedSize: 52,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        metric == StrengthMetric.volume
                            ? _formatVolume(value, unitLabel)
                            : '${value.toStringAsFixed(0)} $unitLabel',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
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
        );
      },
    );
  }

  /// Volume axis can blow up into the thousands; abbreviate so labels fit.
  static String _formatVolume(double value, String unitLabel) {
    if (value >= 10000) return '${(value / 1000).toStringAsFixed(0)}k';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return '${value.toStringAsFixed(0)} $unitLabel';
  }
}
