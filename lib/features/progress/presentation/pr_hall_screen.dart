import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../models/enums.dart';
import '../../../providers/personal_records_hall_providers.dart';
import 'widgets/pr_card.dart';

class PRHallScreen extends ConsumerWidget {
  const PRHallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPRs = ref.watch(filteredPRsProvider);
    final sortMode = ref.watch(prSortModeProvider);
    final muscleFilter = ref.watch(prFilterMuscleProvider);

    final palette = AppColors.of(context);
    return CupertinoPageScaffold(
      backgroundColor: palette.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Personal Records'),
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Sort control
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: CupertinoSlidingSegmentedControl<PRSortMode>(
                groupValue: sortMode,
                backgroundColor: palette.surface,
                thumbColor: palette.accent,
                children: const {
                  PRSortMode.byRank: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('Rank',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                  ),
                  PRSortMode.byDate: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('Recent',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                  ),
                  PRSortMode.byMuscleGroup: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('Muscle',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                  ),
                  PRSortMode.alphabetical: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('A-Z',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                  ),
                },
                onValueChanged: (mode) {
                  if (mode != null) {
                    HapticFeedback.selectionClick();
                    ref.read(prSortModeProvider.notifier).state = mode;
                  }
                },
              ),
            ),

            // Muscle group filter chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: muscleFilter == null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(prFilterMuscleProvider.notifier).state = null;
                    },
                  ),
                  ...MuscleGroup.values.map((mg) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _FilterChip(
                          label: mg.label,
                          isSelected: muscleFilter == mg,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(prFilterMuscleProvider.notifier).state = mg;
                          },
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // PR list
            Expanded(
              child: asyncPRs.when(
                data: (prs) {
                  if (prs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events,
                              size: 64,
                              color: palette.warning.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'No personal records yet',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              color: palette.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Complete workouts to set your first PR!',
                            style: TextStyle(
                              fontFamily: 'LeagueSpartan',
                              fontSize: 14,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: prs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        PRCard(record: prs[index]),
                  );
                },
                loading: () => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: List.generate(
                      5,
                      (_) => const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: ShimmerBox(
                          width: double.infinity,
                          height: 80,
                          borderRadius: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                error: (_, _) => Center(
                  child: Text(
                    'Failed to load personal records.',
                    style: TextStyle(color: palette.text),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? palette.accent : palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? palette.accent : palette.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: isSelected ? Colors.white : palette.textSecondary,
          ),
        ),
      ),
    );
  }
}
