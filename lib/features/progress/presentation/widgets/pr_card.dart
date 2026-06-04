import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../models/enums.dart';
import '../../../../models/personal_record.dart';
import '../../../../providers/unit_system_provider.dart';
import '../../../ranks/presentation/widgets/rank_badge.dart';
import '../../../ranks/providers/rank_providers.dart';

class PRCard extends ConsumerWidget {
  const PRCard({super.key, required this.record});

  final PersonalRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitSystemProvider);
    final palette = AppColors.of(context);
    final dateStr =
        '${record.dateAchieved.day}/${record.dateAchieved.month}/${record.dateAchieved.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          // Trophy icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.emoji_events,
              color: palette.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.exerciseName,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: palette.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _StatChip(
                      label: UnitConverter.formatWeight(record.weightKg, units),
                      icon: CupertinoIcons.arrow_up,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: '${record.bestReps} reps',
                      icon: CupertinoIcons.repeat,
                    ),
                  ],
                ),
                _PRRankBadge(exerciseName: record.exerciseName),
              ],
            ),
          ),
          // Date + muscle group
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.muscleGroup.label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: palette.accent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontSize: 12,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ],
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

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: palette.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            fontSize: 13,
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }
}
