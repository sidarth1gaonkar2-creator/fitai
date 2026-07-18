import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/field_manual.dart';
import '../../../../../core/utils/unit_converter.dart';
import '../../../../../providers/unit_system_provider.dart';
import '../../../../ranks/domain/military_ranks.dart';
import '../../../../ranks/presentation/widgets/rank_badge.dart';
import '../../../domain/leaderboard_entry.dart';

/// One leaderboard row, ranked by strength rank score. Shows position, the
/// segment's rank insignia, the username, and the rank score; the lifter's
/// big-3 best lifts sit on a secondary mono line. Top 3 wear a quiet accent
/// stamp on the position (One Voice Rule — no gold/silver/bronze soup) and
/// the signed-in user's own row gets an accent border.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final units = ref.watch(unitSystemProvider);

    // The segment's rank points → rank + 0–900 display score.
    final points = entry.scoreForField(field);
    final rank = rankFromPoints(points);
    final score = rankDisplayScore(points);

    return Semantics(
      button: true,
      label:
          'Position $position, ${entry.username}, ${rank.displayName}, '
          '$score points${isCurrentUser ? ', you' : ''}',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: () => context.push('/profile/${entry.userId}'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? palette.accent.withValues(alpha: 0.10)
                  : palette.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrentUser ? palette.accent : palette.border,
                width: isCurrentUser ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // ── Position ──
                _PositionBadge(position: position, palette: palette),
                const SizedBox(width: 10),

                // ── Rank insignia disc (canonical tier colour, always) ──
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

                // ── Username + rank abbreviation + big-3 secondary ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              // Usernames are user content — Inter, never
                              // uppercased, never Oswald.
                              entry.username,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontVariations: const [
                                  FontVariation('wght', 600),
                                ],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: palette.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            // Mono designation in the rank's AA-lifted text
                            // tone — never the raw rank colour at this size.
                            rank.abbreviation,
                            style: FieldManual.label(
                              fontSize: 11,
                              color: rank.textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              // Best lifts are trained-against numbers —
                              // mono.
                              _secondary(units),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: FieldManual.label(
                                fontSize: 11,
                                color: palette.textSecondary,
                              ),
                            ),
                          ),
                          if (!_hasBig3) ...[
                            const SizedBox(width: 2),
                            Icon(
                              CupertinoIcons.flame,
                              size: 12,
                              // Accent marks the viewer's own streak.
                              color: isCurrentUser
                                  ? palette.accent
                                  : palette.textSecondary,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // ── Score readout ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: FieldManual.readout(
                        fontSize: 17,
                        color: palette.text,
                      ),
                    ),
                    Text(
                      'PTS',
                      style: FieldManual.label(
                        fontSize: 10,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasBig3 =>
      entry.benchKg > 0 || entry.squatKg > 0 || entry.deadliftKg > 0;

  /// Big-3 line in the viewer's units; falls back to activity stats when the
  /// lifter has no logged big-3 yet (a flame icon follows the streak count).
  String _secondary(UnitSystem units) {
    String v(double kg) {
      final value =
          units == UnitSystem.imperial ? UnitConverter.kgToLbs(kg) : kg;
      return value.round().toString();
    }

    if (_hasBig3) {
      final unit = UnitConverter.weightUnit(units);
      return 'B ${v(entry.benchKg)} · S ${v(entry.squatKg)} · '
          'D ${v(entry.deadliftKg)} ${unit.toUpperCase()}';
    }
    return '${entry.totalWorkouts} WORKOUTS · ${entry.currentStreak}';
  }
}

class _PositionBadge extends StatelessWidget {
  const _PositionBadge({required this.position, required this.palette});

  final int position;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final isPodium = position <= 3;

    if (isPodium) {
      // Podium stamp: the live accent, quietly — earned, not gilded.
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: palette.accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: palette.accent),
        ),
        alignment: Alignment.center,
        child: Text(
          '$position',
          style: FieldManual.readout(fontSize: 12, color: palette.accent),
        ),
      );
    }

    return SizedBox(
      width: 26,
      child: Text(
        '$position',
        textAlign: TextAlign.center,
        style: FieldManual.readout(
          fontSize: 13,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}
