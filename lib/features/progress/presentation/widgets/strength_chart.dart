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

/// Field Manual exercise picker — the stock Material [DropdownMenu] restyled
/// onto FM chrome (raised-field input, hairline border, 4px radius, accent
/// focus). Behavior and tap count are unchanged; shared by [StrengthChart]
/// and the strength curve chart.
class ExercisePickerDropdown extends StatelessWidget {
  const ExercisePickerDropdown({
    super.key,
    required this.names,
    required this.selected,
    required this.onSelected,
  });

  final List<String> names;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: color),
        );
    return DropdownMenu<String>(
      hintText: 'Select exercise',
      initialSelection: selected,
      textStyle: FieldManual.body(),
      trailingIcon: const Icon(Icons.arrow_drop_down,
          color: FieldManual.mutedBone),
      selectedTrailingIcon: const Icon(Icons.arrow_drop_up,
          color: FieldManual.mutedBone),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FieldManual.fieldRaised,
        hintStyle: FieldManual.body(color: FieldManual.mutedBone),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: border(FieldManual.hairline),
        focusedBorder: border(palette.accent),
        border: border(FieldManual.hairline),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(FieldManual.field),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: FieldManual.hairline),
          ),
        ),
      ),
      dropdownMenuEntries: names
          .map((n) => DropdownMenuEntry(
                value: n,
                label: n,
                style: MenuItemButton.styleFrom(
                  foregroundColor: FieldManual.bone,
                  textStyle: FieldManual.body(fontSize: 14),
                ),
              ))
          .toList(),
      onSelected: onSelected,
    );
  }
}

class StrengthChart extends ConsumerWidget {
  const StrengthChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                style: FieldManual.body(color: FieldManual.mutedBone),
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
    final palette = AppColors.of(context);
    final historyAsync = ref.watch(strengthHistoryProvider(exerciseName));
    final units = ref.watch(unitSystemProvider);

    return historyAsync.when(
      loading: () =>
          const ShimmerBox(width: double.infinity, height: 200, borderRadius: 8),
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
                style: FieldManual.body(color: FieldManual.mutedBone),
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
                'WEIGHT ($unitLabel)'.toUpperCase(),
                style: FieldManual.label(),
              ),
            ),
            Semantics(
              label: '$exerciseName strength chart: ${points.length} sessions '
                  'since ${formatShortDate(firstDate)}, latest '
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
                            // once in the caption above. Fractional
                            // intervals keep one decimal.
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
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
                        getTooltipItems: (spots) => spots
                            .map((s) => LineTooltipItem(
                                  '${s.y.toStringAsFixed(0)} $unitLabel',
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
}
