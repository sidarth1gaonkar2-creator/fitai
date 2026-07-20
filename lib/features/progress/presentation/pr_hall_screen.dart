import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/field_manual.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../models/enums.dart';
import '../../../providers/personal_records_hall_providers.dart';
import '../../../core/widgets/fm_segmented.dart';
import 'widgets/pr_card.dart';

/// The trophy room — an instrument surface. Quiet FM chrome; the mono PR
/// readouts on each card carry the room.
class PRHallScreen extends ConsumerWidget {
  const PRHallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPRs = ref.watch(filteredPRsProvider);
    final sortMode = ref.watch(prSortModeProvider);
    final muscleFilter = ref.watch(prFilterMuscleProvider);

    return CupertinoPageScaffold(
      backgroundColor: FieldManual.scaffold,
      navigationBar: CupertinoNavigationBar(
        middle: Text('PERSONAL RECORDS', style: FieldManual.title()),
        backgroundColor: FieldManual.ink.withValues(alpha: 0.82),
        border: const Border(bottom: BorderSide(color: FieldManual.hairline)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Sort control
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: FmSegmented<PRSortMode>(
                segments: const [
                  (PRSortMode.byRank, 'Rank'),
                  (PRSortMode.byDate, 'Recent'),
                  (PRSortMode.byMuscleGroup, 'Muscle'),
                  (PRSortMode.alphabetical, 'A-Z'),
                ],
                selected: sortMode,
                fontSize: 10,
                onChanged: (mode) =>
                    ref.read(prSortModeProvider.notifier).state = mode,
              ),
            ),

            // Muscle group filter chips
            SizedBox(
              height: MediaQuery.textScalerOf(context).scale(44),
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
                          const Icon(Icons.emoji_events,
                              size: 56, color: FieldManual.olive),
                          const SizedBox(height: 16),
                          Text('NO RECORDS YET', style: FieldManual.title()),
                          const SizedBox(height: 6),
                          Text(
                            'Complete workouts to set your first PR!',
                            textAlign: TextAlign.center,
                            style: FieldManual.body(
                              fontSize: 14,
                              color: FieldManual.mutedBone,
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
                          borderRadius: 8,
                        ),
                      ),
                    ),
                  ),
                ),
                error: (_, _) => Center(
                  child: Text(
                    'Failed to load personal records.',
                    style: FieldManual.body(color: FieldManual.mutedBone),
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

/// FM filter chip: sharp 4px, field ground with hairline border; selected
/// fills with the live accent carrying on-accent mono type.
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
    // Spoken label stays sentence case; the uppercase is visual only.
    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? palette.accent : FieldManual.field,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? palette.accent : FieldManual.hairline,
              ),
            ),
            child: Text(
              label.toUpperCase(),
              style: FieldManual.label(
                fontSize: 10,
                color:
                    isSelected ? palette.onAccent : FieldManual.mutedBone,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
