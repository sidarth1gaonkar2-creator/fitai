import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../providers/entitlement_providers.dart';
import '../../../ranks/domain/military_ranks.dart';
import '../../../ranks/presentation/widgets/rank_badge.dart';
import '../../../ranks/providers/rank_providers.dart';

/// Field Manual rank strip: insignia in tier color, rank name, and — new over
/// the old RankCard — visible promotion progress on the 0–900 rank-score
/// scale. Rank is sacred: this strip carries no purchase affordance, ever.
class RankStrip extends ConsumerWidget {
  const RankStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(rankCalculatorProvider);
    final calc = async.valueOrNull;
    final loading = async.isLoading && !async.hasValue;

    if (loading) return const _RankStripSkeleton();

    final hasData = calc != null && calc.exerciseScores.isNotEmpty;
    final rank = calc?.overall ?? MilitaryRank.private_e1;
    final points = calc?.overallPoints ?? 0;
    // Airborne subscribers see their OWN current rank brass-mounted. This strip
    // only ever shows the user's current earned rank, so the flag is safe here.
    final airborne = ref.watch(airborneActiveProvider);

    final isApex = rank == MilitaryRank.sgmArmy_e10;
    final progressFraction =
        isApex ? 1.0 : (points - points.floor()).clamp(0.0, 1.0).toDouble();
    final score = rankDisplayScore(points);

    final String progressLine;
    if (!hasData) {
      progressLine = 'Complete workouts to earn your rank.';
    } else if (isApex) {
      progressLine = 'RANK SCORE $score — APEX';
    } else {
      final next = rankFromIndex(rank.index + 1);
      progressLine = '$score → ${(rank.index + 1) * 100} ${next.abbreviation}';
    }

    return Semantics(
      button: true,
      label: hasData
          ? 'Rank ${rank.displayName}, score $score. View ranks.'
          : 'Rank Private. Complete workouts to earn your rank.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/ranks');
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: FieldManual.field,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FieldManual.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: FieldManual.hairlineStrong),
                    ),
                    child: RankInsignia(rank: rank, size: 32, airborne: airborne),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rank.displayName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FieldManual.title(),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          progressLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: hasData
                              ? FieldManual.label(fontSize: 10)
                              : FieldManual.body(
                                  color: FieldManual.mutedBone,
                                  fontSize: 12,
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: FieldManual.mutedBone,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Promotion progress — thin rule, live-accent fill (brass on
              // the default issue).
              ClipRRect(
                borderRadius: BorderRadius.circular(1.5),
                child: SizedBox(
                  height: 3,
                  child: Stack(
                    children: [
                      Container(color: FieldManual.hairline),
                      FractionallySizedBox(
                        widthFactor: hasData ? progressFraction : 0.0,
                        child:
                            Container(color: AppColors.of(context).accent),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankStripSkeleton extends StatelessWidget {
  const _RankStripSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: FieldManual.fieldRaised,
            borderRadius: BorderRadius.circular(3),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FieldManual.field,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FieldManual.hairline),
      ),
      child: Row(
        children: [
          block(46, 46),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [block(120, 14), const SizedBox(height: 8), block(80, 9)],
          ),
        ],
      ),
    );
  }
}
