import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/unit_converter.dart';
import '../../../../../providers/unit_system_provider.dart';
import '../../../../ranks/domain/military_ranks.dart';
import '../../../../ranks/presentation/widgets/rank_badge.dart';
import '../../../domain/leaderboard_entry.dart';

/// One leaderboard row, ranked by strength rank score. Shows position, the
/// segment's rank badge + name, the username, and the rank score; the lifter's
/// big-3 best lifts sit on a secondary line. Top 3 get podium colours and the
/// signed-in user's own row gets an accent border.
class LeaderboardTile extends ConsumerWidget {
  const LeaderboardTile({
    super.key,
    required this.position,
    required this.entry,
    required this.field,
    required this.isCurrentUser,
  });

  final int position;
  final LeaderboardEntry entry;

  /// Segment field (see [LeaderboardSegments]) the board is sorted by.
  final String field;
  final bool isCurrentUser;

  static const _podium = [
    Color(0xFFFFD700), // gold
    Color(0xFFC0C0C0), // silver
    Color(0xFFCD7F32), // bronze
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final units = ref.watch(unitSystemProvider);

    // The segment's rank points → rank + 0–900 display score.
    final points = entry.scoreForField(field);
    final rank = rankFromPoints(points);
    final score = rankDisplayScore(points);
    final isPodium = position <= 3;

    return GestureDetector(
      onTap: () => context.push('/profile/${entry.userId}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? palette.accent.withValues(alpha: 0.10)
              : palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentUser
                ? palette.accent
                : (isPodium
                    ? _podium[position - 1].withValues(alpha: 0.55)
                    : palette.border),
            width: isCurrentUser ? 1.5 : (isPodium ? 1.0 : 0.5),
          ),
        ),
        child: Row(
          children: [
            // ── Position ──
            _PositionBadge(position: position, palette: palette),
            const SizedBox(width: 10),

            // ── Rank insignia disc ──
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: rank.color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: RankInsignia(rank: rank, size: 24),
            ),
            const SizedBox(width: 10),

            // ── Username + rank name + big-3 secondary ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.username,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: palette.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        rank.abbreviation,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                          color: rank.color,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _secondary(units),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 11.5,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Score ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: palette.text,
                  ),
                ),
                Text(
                  'pts',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 10,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Big-3 line in the viewer's units; falls back to activity stats when the
  /// lifter has no logged big-3 yet.
  String _secondary(UnitSystem units) {
    String v(double kg) {
      final value =
          units == UnitSystem.imperial ? UnitConverter.kgToLbs(kg) : kg;
      return value.round().toString();
    }

    final hasBig3 =
        entry.benchKg > 0 || entry.squatKg > 0 || entry.deadliftKg > 0;
    if (hasBig3) {
      final unit = UnitConverter.weightUnit(units);
      return 'B ${v(entry.benchKg)} · S ${v(entry.squatKg)} · '
          'D ${v(entry.deadliftKg)} $unit';
    }
    return '${entry.totalWorkouts} workouts · ${entry.currentStreak}🔥';
  }
}

class _PositionBadge extends StatelessWidget {
  const _PositionBadge({required this.position, required this.palette});

  final int position;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final isPodium = position <= 3;
    final color = isPodium ? LeaderboardTile._podium[position - 1] : null;

    if (isPodium) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color!.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.4),
        ),
        alignment: Alignment.center,
        child: Text(
          '$position',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: color,
          ),
        ),
      );
    }

    return SizedBox(
      width: 26,
      child: Text(
        '$position',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}
