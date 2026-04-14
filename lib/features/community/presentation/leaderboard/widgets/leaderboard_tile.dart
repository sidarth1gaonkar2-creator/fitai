import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar, Colors;

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/leaderboard_entry.dart';

class LeaderboardTile extends StatelessWidget {
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

  String get _metricValue {
    return switch (metricField) {
      'currentStreak' => '${entry.currentStreak}',
      'weeklyVolume' => '${entry.weeklyVolume.toStringAsFixed(0)} kg',
      'weeklyWorkouts' => '${entry.weeklyWorkouts}',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final bg = isCurrentUser ? palette.accent : palette.surface;
    final textColor = isCurrentUser ? CupertinoColors.white : palette.text;
    final secondaryTextColor =
        isCurrentUser ? CupertinoColors.white.withOpacity(0.8) : palette.textSecondary;

    return Container(
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
            backgroundImage: entry.profilePictureUrl != null
                ? CachedNetworkImageProvider(entry.profilePictureUrl!)
                : null,
            child: entry.profilePictureUrl == null
                ? Icon(
                    CupertinoIcons.person_fill,
                    size: 20,
                    color: secondaryTextColor,
                  )
                : null,
          ),

          const SizedBox(width: 12),

          // ---- Username ----
          Expanded(
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

          // ---- Metric value ----
          Text(
            _metricValue,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
