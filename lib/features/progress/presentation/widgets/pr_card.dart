import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../models/enums.dart';
import '../../../../models/personal_record.dart';
import '../../../../providers/unit_system_provider.dart';
import '../../../ranks/presentation/widgets/rank_badge.dart';
import '../../../ranks/providers/rank_providers.dart';
import 'chart_axis.dart';

/// One trophy-room row: quiet field chrome, the mono PR readout carries it.
/// Exercise name in Oswald title (as typed — user content is never
/// uppercased), weight × reps as instrument readouts, date in mono label.
class PRCard extends ConsumerWidget {
  const PRCard({super.key, required this.record});

  final PersonalRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitSystemProvider);
    // App-wide "MMM d" date convention; the year appears only when it isn't
    // the current one.
    final achieved = record.dateAchieved;
    final dateStr = achieved.year == DateTime.now().year
        ? formatShortDate(achieved)
        : '${formatShortDate(achieved)}, ${achieved.year}';
    final weightValue = UnitConverter.formatWeightValue(record.weightKg, units);
    final unitLabel = UnitConverter.weightUnit(units).toUpperCase();

    return Semantics(
      label: '${record.exerciseName}: personal record '
          '${UnitConverter.formatWeight(record.weightKg, units)} for '
          '${record.bestReps} reps, ${record.muscleGroup.label}, '
          'achieved $dateStr.',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FieldManual.field,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FieldManual.hairline),
        ),
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Designation column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.exerciseName,
                      style: FieldManual.title(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.muscleGroup.label.toUpperCase(),
                      style: FieldManual.label(fontSize: 10),
                    ),
                    _PRRankBadge(exerciseName: record.exerciseName),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Instrument column — the numbers carry the room.
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$weightValue $unitLabel',
                    style: FieldManual.readout(fontSize: 20),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '×${record.bestReps} REPS',
                    style: FieldManual.readout(
                      fontSize: 12,
                      color: FieldManual.mutedBone,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(dateStr, style: FieldManual.label(fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact rank badge under a PR's stats. Collapses to nothing when the
/// exercise isn't rankable or has no usable data.
class _PRRankBadge extends ConsumerWidget {
  const _PRRankBadge({required this.exerciseName});

  final String exerciseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail =
        ref.watch(exerciseRankDetailProvider(exerciseName)).valueOrNull;
    if (detail == null || !detail.hasData) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: RankBadge(rank: detail.rank, compact: true, size: 18),
    );
  }
}
