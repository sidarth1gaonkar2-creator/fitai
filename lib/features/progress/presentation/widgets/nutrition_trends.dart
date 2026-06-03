import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../providers/nutrition_providers.dart';
import '../../../../providers/progress_providers.dart';
import 'chart_axis.dart';

/// Which macro the nutrition-trends bar chart is currently showing.
enum _Macro { calories, protein, carbs, fat }

extension _MacroMeta on _Macro {
  String get label => switch (this) {
        _Macro.calories => 'Calories',
        _Macro.protein => 'Protein',
        _Macro.carbs => 'Carbs',
        _Macro.fat => 'Fat',
      };

  /// Dashboard macro colors: blue calories, red protein, orange carbs, green fat.
  Color color(Palette palette) => switch (this) {
        _Macro.calories => palette.accent,
        _Macro.protein => AppColors.macroProtein,
        _Macro.carbs => AppColors.macroCarbs,
        _Macro.fat => AppColors.macroFat,
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

class NutritionTrends extends ConsumerWidget {
  const NutritionTrends({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = AppColors.of(context);

    final range = ref.watch(selectedNutritionRangeProvider);
    final macro = ref.watch(_selectedMacroProvider);
    final trendsAsync = ref.watch(nutritionTrendsProvider(range));
    final targets = ref.watch(dailyTargetsProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Range toggle (7 / 30 / 90 days).
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 7, label: Text('7d')),
            ButtonSegment(value: 30, label: Text('30d')),
            ButtonSegment(value: 90, label: Text('90d')),
          ],
          selected: {range},
          showSelectedIcon: false,
          onSelectionChanged: (selected) =>
              ref.read(selectedNutritionRangeProvider.notifier).state =
                  selected.first,
        ),
        const SizedBox(height: 16),
        trendsAsync.when(
          loading: () => const ShimmerBox(
              width: double.infinity, height: 220, borderRadius: 12),
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
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2x2 summary cards, color-coded to the macro palette.
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Avg Calories',
                        value: '${data.avgCalories.round()} kcal',
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'Avg Protein',
                        value: '${data.avgProtein.round()}g',
                        color: AppColors.macroProtein,
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
                        value: '${data.avgCarbs.round()}g',
                        color: AppColors.macroCarbs,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'Avg Fat',
                        value: '${data.avgFat.round()}g',
                        color: AppColors.macroFat,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Macro selector.
                SegmentedButton<_Macro>(
                  segments: [
                    for (final m in _Macro.values)
                      ButtonSegment(value: m, label: Text(m.label)),
                  ],
                  selected: {macro},
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(textTheme.bodySmall),
                  ),
                  onSelectionChanged: (selected) => ref
                      .read(_selectedMacroProvider.notifier)
                      .state = selected.first,
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
/// target line, calendar-aware X-axis labels, and an "Avg:" caption.
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
    final textTheme = Theme.of(context).textTheme;
    final barColor = macro.color(palette);
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
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: barColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '${macro.label} · Avg: ${macro.format(macro.avg(data))}',
              style: textTheme.bodyMedium?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: axis.maxY,
              alignment: BarChartAlignment.spaceBetween,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: axis.interval,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: palette.border, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
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
                        shortenAxisLabel(value.round()),
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
                      final i = value.round();
                      if (i < 0 || i >= daily.length) {
                        return const SizedBox.shrink();
                      }
                      if (i % labelInterval != 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          bottomLabel(i),
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
                    macro.format(rod.toY),
                    TextStyle(color: palette.text, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              // Dashed target line for the selected macro.
              extraLinesData: (target != null && target! > 0)
                  ? ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: target!,
                          color: barColor.withValues(alpha: 0.8),
                          strokeWidth: 1.5,
                          dashArray: const [6, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(right: 4, bottom: 2),
                            style: textTheme.bodySmall?.copyWith(
                              color: barColor,
                              fontWeight: FontWeight.w600,
                            ),
                            labelResolver: (_) =>
                                'Target ${macro.format(target!)}',
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
                        borderRadius: BorderRadius.circular(3),
                        color: barColor,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.labelSmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
