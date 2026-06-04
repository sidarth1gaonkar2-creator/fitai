import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/unit_converter.dart';
import '../../../../../providers/unit_system_provider.dart';
import '../../../../ranks/presentation/widgets/user_rank_badge.dart';
import '../../../domain/leaderboard_entry.dart';

class LeaderboardTile extends ConsumerWidget {
  const LeaderboardTile({
    super.key,
    required this.rank,
    required this.entry,
    required this.metricField,
    required this.isCurrentUser,
  });

  final int rank;
  final LeaderboardEntry entry;
  final String metricField;
  final bool isCurrentUser;

  static const _medals = ['\u{1F947}', '\u{1F948}', '\u{1F949}'];

  /// `totalVolume` is stored in kg server-side. Render it in the viewer's
  /// preferred unit. We collapse to tons (or "k lbs") past 1000 to keep
  /// long-haul lifters' rows from blowing out the layout.
  String _metricValue(UnitSystem units) {
    return switch (metricField) {
      'currentStreak' => '${entry.currentStreak}',
      'totalVolume' => _formatVolume(entry.totalVolume, units),
      'totalWorkouts' => '${entry.totalWorkouts}',
      _ => '',
    };
  }

  static String _formatVolume(double kg, UnitSystem units) {
    final value = units == UnitSystem.imperial
        ? UnitConverter.kgToLbs(kg)
        : kg;
    final unitLabel = UnitConverter.weightUnit(units);
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k $unitLabel';
    }
    return '${value.toStringAsFixed(0)} $unitLabel';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final units = ref.watch(unitSystemProvider);
    final bg = isCurrentUser ? palette.accent : palette.surface;
    final textColor = isCurrentUser ? CupertinoColors.white : palette.text;
    final secondaryTextColor = isCurrentUser
        ? CupertinoColors.white.withValues(alpha: 0.8)
        : palette.textSecondary;

    return GestureDetector(
      onTap: () => context.push('/profile/${entry.userId}'),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? null
            : Border.all(color: palette.border, width: 0.5),
      ),
      child: Row(
        children: [
          // ---- Rank ----
          SizedBox(
            width: 36,
            child: rank <= 3
                ? Text(
                    _medals[rank - 1],
                    style: const TextStyle(fontSize: 22),
                    textAlign: TextAlign.center,
                  )
                : Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
          ),

          const SizedBox(width: 10),

          // ---- Avatar ----
          CircleAvatar(
            radius: 20,
            backgroundColor: palette.surfaceElevated,
            backgroundImage: entry.avatarUrl != null
                ? CachedNetworkImageProvider(entry.avatarUrl!)
                : null,
            child: entry.avatarUrl == null
                ? Icon(
                    CupertinoIcons.person_fill,
                    size: 20,
                    color: secondaryTextColor,
                  )
                : null,
          ),

          const SizedBox(width: 12),

          // ---- Username + rank badge ----
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    entry.username,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                ),
                UserRankBadge(userId: entry.userId),
              ],
            ),
          ),

          // ---- Metric value ----
          Text(
            _metricValue(units),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textColor,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
