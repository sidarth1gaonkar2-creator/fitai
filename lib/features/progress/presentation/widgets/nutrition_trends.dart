import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../providers/progress_providers.dart';

class NutritionTrends extends ConsumerWidget {
  const NutritionTrends({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final range = ref.watch(selectedNutritionRangeProvider);
    final trendsAsync = ref.watch(nutritionTrendsProvider(range));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Range toggle
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 7, label: Text('7d')),
            ButtonSegment(value: 30, label: Text('30d')),
            ButtonSegment(value: 90, label: Text('90d')),
          ],
          selected: {range},
          onSelectionChanged: (selected) =>
              ref.read(selectedNutritionRangeProvider.notifier).state =
                  selected.first,
        ),
        const SizedBox(height: 16),
        trendsAsync.when(
          loading: () => const ShimmerBox(
              width: double.infinity, height: 160, borderRadius: 12),
          error: (_, _) => ErrorCard(
            message: 'Could not load nutrition trends.',
            onRetry: () => ref.invalidate(nutritionTrendsProvider(range)),
          ),
          data: (data) {
            if (data.dailyCalories.isEmpty) {
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
              children: [
                // 2x2 stat grid
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Avg Calories',
                        value: '${data.avgCalories.toInt()} kcal',
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'Avg Protein',
                        value: '${data.avgProtein.toInt()}g',
                        color: colorScheme.primary,
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
                        value: '${data.avgCarbs.toInt()}g',
                        color: colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'Avg Fat',
                        value: '${data.avgFat.toInt()}g',
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Sparkline
                if (data.dailyCalories.length >= 2)
                  SizedBox(
                    height: 80,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineTouchData:
                            const LineTouchData(enabled: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              data.dailyCalories.length,
                              (i) => FlSpot(
                                  i.toDouble(), data.dailyCalories[i]),
                            ),
                            isCurved: true,
                            curveSmoothness: 0.3,
                            color: colorScheme.primary,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: colorScheme.primary
                                  .withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
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
