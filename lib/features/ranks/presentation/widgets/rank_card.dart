import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/military_ranks.dart';
import '../../providers/rank_providers.dart';
import 'rank_badge.dart';

/// Dashboard card showing the user's overall military rank. Tapping opens the
/// full Ranks screen (muscle-group breakdown, heat map, per-exercise ranks).
/// Falls back to an encouraging Private empty state before any rankable PRs.
class RankCard extends ConsumerWidget {
  const RankCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final async = ref.watch(rankCalculatorProvider);
    final calc = async.valueOrNull;
    final loading = async.isLoading && !async.hasValue;

    final hasData = calc != null && calc.exerciseScores.isNotEmpty;
    final rank = calc?.overall ?? MilitaryRank.private_e1;

    final title = hasData ? rank.displayName : 'Private';
    // Only show the "earn your rank" CTA once we KNOW the user has no rankable
    // data — not during the first calculation (avoids a flash for returning
    // users).
    final subtitle = (hasData || loading)
        ? 'Overall Strength Rank'
        : 'Complete workouts to earn your rank';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/ranks');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: rank.color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            // Large insignia in a tinted disc.
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: rank.color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: RankInsignia(rank: rank, size: 40),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: rank.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasData
                        ? '${rank.abbreviation} · tier E${rank.tier} · View Ranks'
                        : 'View Ranks',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 12,
                      color: palette.accent,
                    ),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right,
                size: 18, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}
