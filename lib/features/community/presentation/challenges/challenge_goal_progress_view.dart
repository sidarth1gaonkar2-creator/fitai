import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../ranks/domain/military_ranks.dart';
import '../../../ranks/presentation/widgets/rank_badge.dart';
import '../../../ranks/providers/rank_providers.dart';
import '../../domain/challenge.dart';
import '../../domain/challenge_goal.dart';

/// The target rank badge for a rank-goal [challenge]. Renders the rank insignia
/// + name for rank-targeted goals; for pure-weight goals (no rank) it shows a
/// tinted "goal" pill with the challenge icon instead.
class ChallengeTargetBadge extends StatelessWidget {
  const ChallengeTargetBadge({
    super.key,
    required this.challenge,
    this.size = 22,
  });

  final Challenge challenge;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final idx = challenge.targetRankIndex;
    final isRankTarget = challenge.rankGoalType == RankGoalType.overallRank ||
        challenge.rankGoalType == RankGoalType.exerciseRank ||
        challenge.rankGoalType == RankGoalType.allMuscleGroups;

    if (isRankTarget && idx != null) {
      final rank = rankFromIndex(idx);
      // Insignia + abbreviation render in canonical tier colours (RankBadge
      // sets the small text in rank.textColor, the AA-lifted tone).
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: rank.color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: rank.color.withValues(alpha: 0.5), width: 0.8),
        ),
        child: RankBadge(rank: rank, compact: true, size: size),
      );
    }

    // Weight goal — a quiet mono designation stamp in the live accent.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${challenge.icon ?? '🎯'} GOAL',
        style: FieldManual.label(fontSize: 10, color: palette.accent),
      ),
    );
  }
}

/// The signed-in user's progress toward a rank-goal [challenge], as a bar plus a
/// "current → target" caption. Renders nothing for non-rank challenges (callers
/// fall back to the legacy day-count bar).
class ChallengeGoalProgressView extends ConsumerWidget {
  const ChallengeGoalProgressView({
    super.key,
    required this.challenge,
    this.dense = false,
  });

  final Challenge challenge;

  /// Tighter typography for use inside a card.
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    if (!challenge.isRankGoal) return const SizedBox.shrink();

    final calc = ref.watch(rankCalculatorProvider).valueOrNull;
    if (calc == null) {
      return _bar(palette, 0, 'Calculating your rank…', '');
    }

    final p = computeChallengeGoalProgress(
      challenge: challenge,
      overallPoints: calc.overallPoints,
      muscleGroupPoints: calc.muscleGroupPoints,
      exerciseScores: calc.exerciseScores,
      exerciseBestWeightKg: calc.exerciseBestWeightKg,
      bodyWeightKg: calc.bodyWeightKg,
    );
    if (p == null) return const SizedBox.shrink();

    final caption = p.isComplete
        ? 'Complete ✓ · ${p.currentLabel}'
        : '${p.currentLabel} → ${p.targetLabel}';
    return _bar(
      palette,
      p.progress,
      caption,
      '${(p.progress * 100).round()}%',
      complete: p.isComplete,
    );
  }

  Widget _bar(
    Palette palette,
    double progress,
    String caption,
    String percent, {
    bool complete = false,
  }) {
    // Progress is an instrument: accent fill on a hairline track. A completed
    // goal celebrates quietly in the same accent — no confetti, no green.
    final fill = palette.accent;
    final captionSize = dense ? 11.5 : 13.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: complete
              ? 'Challenge goal complete'
              : 'Progress toward challenge goal',
          value: '${(progress.clamp(0.0, 1.0) * 100).round()}%',
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: dense ? 6 : 8,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          width: constraints.maxWidth,
                          color: palette.surfaceElevated,
                        ),
                        Container(
                          width:
                              constraints.maxWidth * progress.clamp(0.0, 1.0),
                          color: fill,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                // '{current} → {target}' carries weights/scores — mono.
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FieldManual.label(
                  fontSize: 11,
                  color: FieldManual.mutedBone,
                ),
              ),
            ),
            if (percent.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                // The percentage is a trained-against number — mono readout.
                percent,
                style: FieldManual.readout(
                  fontSize: captionSize < 12 ? 12 : captionSize,
                  color: complete ? palette.accent : palette.text,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
