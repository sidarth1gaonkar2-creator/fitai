import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../providers/nutrition_providers.dart';
import '../../../../providers/progress_providers.dart';
import 'chart_axis.dart';
import '../../../../core/widgets/fm_segmented.dart';

/// Which macro the nutrition-trends bar chart is currently showing.
enum _Macro { calories, protein, carbs, fat }

extension _MacroMeta on _Macro {
  String get label => switch (this) {
        _Macro.calories => 'Calories',
        _Macro.protein => 'Protein',
        _Macro.carbs => 'Carbs',
        _Macro.fat => 'Fat',
      };

  double value(DailyNutrition d) => switch (this) {
        _Macro.calories => d.calories,
        _Macro.protein => d.protein,
        _Macro.carbs => d.carbs,
        _Macro.fat => d.fat,
      };

  double? target(DailyTargets? t) {
    if (t == null) return null;
    return switch (this) {
      _Macro.calories => t.calories,
      _Macro.protein => t.protein,
      _Macro.carbs => t.carbs,
      _Macro.fat => t.fat,
    };
  }

  double avg(NutritionTrendData d) => switch (this) {
        _Macro.calories => d.avgCalories,
        _Macro.protein => d.avgProtein,
        _Macro.carbs => d.avgCarbs,
        _Macro.fat => d.avgFat,
      };

  /// Formats a value with its unit — "2,150 kcal" for calories, "165g" else.
  String format(double v) =>
      this == _Macro.calories ? '${v.round()} kcal' : '${v.round()}g';
}

final _selectedMacroProvider = StateProvider<_Macro>((_) => _Macro.calories);

/// Nutrition trends — FM instrument: one macro at a time in the single live
/// accent, olive target line as structure. The legacy per-macro tints
/// (red/orange/green) are retired per the One Voice Rule.
class NutritionTrends extends ConsumerWidget {
  const NutritionTrends({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(selectedNutritionRangeProvider);
    final macro = ref.watch(_selectedMacroProvider);
    final trendsAsync = ref.watch(nutritionTrendsProvider(range));
    final targets = ref.watch(dailyTargetsProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Range toggle (7 / 30 / 90 days).
        FmSegmented<int>(
          segments: const [(7, '7 days'), (30, '30 days'), (90, '90 days')],
          selected: range,
          onChanged: (value) =>
              ref.read(selectedNutritionRangeProvider.notifier).state = value,
        ),
        const SizedBox(height: 16),
        trendsAsync.when(
          loading: () => const ShimmerBox(
              width: double.infinity, height: 220, borderRadius: 8),
          error: (_, _) => ErrorCard(
            message: 'Could not load nutrition trends.',
            onRetry: () => ref.invalidate(nutritionTrendsProvider(range)),
          ),
          data: (data) {
            if (!data.hasData) {
              return SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    'No nutrition data for this period.',
                    style: FieldManual.body(color: FieldManual.mutedBone),
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2x2 instrument row — mono readouts on field panels.
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Avg Calories',
                        value: '${data.avgCalories.round()} KCAL',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'Avg Protein',
                        value: '${data.avgProtein.round()}G',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Avg Carbs',
                        value: '${data.avgCarbs.round()}G',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'Avg Fat',
                        value: '${data.avgFat.round()}G',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Macro selector.
                FmSegmented<_Macro>(
                  segments: [
                    for (final m in _Macro.values) (m, m.label),
                  ],
                  selected: macro,
                  fontSize: 10,
                  onChanged: (value) => ref
                      .read(_selectedMacroProvider.notifier)
                      .state = value,
                ),
                const SizedBox(height: 12),
                _MacroBarChart(
                  data: data,
                  macro: macro,
                  range: range,
                  target: macro.target(targets),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Daily bar chart for a single macro over the selected range, with a dashed
/// olive target line, calendar-aware X-axis labels, and a mono legend row.
class _MacroBarChart extends StatelessWidget {
  const _MacroBarChart({
    required this.data,
    required this.macro,
    required this.range,
    required this.target,
  });

  final NutritionTrendData data;
  final _Macro macro;
  final int range;
  final double? target;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final barColor = palette.accent;
    final daily = data.daily;
    final values = daily.map(macro.value).toList();

    // Axis max must clear both the tallest bar and the target line.
    final maxBar = values.fold<double>(0, (m, v) => v > m ? v : m);
    final maxForAxis = (target != null && target! > maxBar) ? target! : maxBar;
    final axis = niceAxis(maxForAxis, minHeadroomFactor: 1.18);

    // Bar width + label density scale down as the range grows.
    final barWidth = range <= 7
        ? 16.0
        : range <= 30
            ? 6.0
            : 3.0;
    final labelInterval = range <= 7 ? 1 : (range / 6).ceil();

    String bottomLabel(int i) {
      final date = daily[i].date;
      if (range <= 7) {
        const weekday = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        return weekday[(date.weekday - 1).clamp(0, 6)];
      }
      return '${date.month}/${date.day}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend: mono label with a small square swatch.
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${macro.label} — avg ${macro.format(macro.avg(data))}'
                    .toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FieldManual.label(color: FieldManual.bone),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Semantics(
          label: '${macro.label} bar chart, last $range days: average '
              '${macro.format(macro.avg(data))}'
              '${target != null && target! > 0 ? ', target ${macro.format(target!)}' : ''}.',
          child: SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: axis.maxY,
                alignment: BarChartAlignment.spaceBetween,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: axis.interval,
                  getDrawingHorizontalLine: chartGridLine,
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
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
                          shortenAxisLabel(value.round()),
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
                        final i = value.round();
                        if (i < 0 || i >= daily.length) {
                          return const SizedBox.shrink();
                        }
                        if (i % labelInterval != 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            bottomLabel(i),
                            style: chartAxisLabelStyle,
                          ),
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
                      macro.format(rod.toY),
                      chartTooltipTextStyle,
                    ),
                  ),
                ),
                // Dashed target line — olive structure, never the accent.
                extraLinesData: (target != null && target! > 0)
                    ? ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: target!,
                            color: FieldManual.olive,
                            strokeWidth: 1.5,
                            dashArray: const [6, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              padding: const EdgeInsets.only(
                                  right: 4, bottom: 2),
                              style: FieldManual.label(fontSize: 11),
                              labelResolver: (_) =>
                                  'TARGET ${macro.format(target!).toUpperCase()}',
                            ),
                          ),
                        ],
                      )
                    : const ExtraLinesData(),
                barGroups: [
                  for (int i = 0; i < values.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          width: barWidth,
                          borderRadius: BorderRadius.circular(2),
                          color: barColor,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// FM stat readout card: mono eyebrow over a bone mono value on a field
/// panel (DESIGN.md §Stat Readout).
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FieldManual.field,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FieldManual.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: FieldManual.label(fontSize: 10)),
          const SizedBox(height: 6),
          Text(value, style: FieldManual.readout(fontSize: 16)),
        ],
      ),
    );
  }
}
