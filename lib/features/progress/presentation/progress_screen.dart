import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../providers/progress_providers.dart';
import 'widgets/milestone_badges.dart';
import 'widgets/nutrition_trends.dart';
import 'widgets/strength_chart.dart';
import 'widgets/weight_chart.dart';
import 'widgets/weight_entry_dialog.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    final milestonesAsync = ref.watch(milestonesProvider);
    final weightAsync = ref.watch(weightEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Milestones ---
            milestonesAsync.when(
              data: (milestones) =>
                  MilestoneBadges(milestones: milestones),
              loading: () => const ShimmerBox(width: double.infinity, height: 80, borderRadius: 12),
              error: (_, _) => const ErrorCard(message: 'Could not load milestones.'),
            ),
            const SizedBox(height: 24),

            // --- Body Weight ---
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Body Weight',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const WeightEntryDialog(),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Log Weight'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            weightAsync.when(
              data: (entries) => WeightChart(entries: entries),
              loading: () => const ShimmerBox(width: double.infinity, height: 220, borderRadius: 12),
              error: (_, _) => const ErrorCard(message: 'Could not load weight data.'),
            ),
            const SizedBox(height: 28),

            // --- Strength Progress ---
            Text(
              'Strength Progress',
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const StrengthChart(),
            const SizedBox(height: 28),

            // --- Nutrition Trends ---
            Text(
              'Nutrition Trends',
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const NutritionTrends(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
