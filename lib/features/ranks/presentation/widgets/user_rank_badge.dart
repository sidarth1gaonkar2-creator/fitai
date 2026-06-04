import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/community_providers.dart';
import '../../domain/military_ranks.dart';
import 'rank_badge.dart';

/// Compact rank badge shown next to a community username (posts, comments,
/// leaderboard). Reads the author's overall rank from their Firestore user doc
/// (mirrored there by the rank engine) and renders a small tinted pill with the
/// rank insignia + abbreviation. Renders nothing until the rank loads or if the
/// user has no rank yet — so it never blocks or shifts the surrounding layout.
class UserRankBadge extends ConsumerWidget {
  const UserRankBadge({super.key, required this.userId, this.size = 13});

  final String userId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = ref.watch(userByIdProvider(userId)).valueOrNull?.rankIndex;
    if (idx == null) return const SizedBox.shrink();
    final rank = rankFromIndex(idx);
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: rank.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: rank.color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RankInsignia(rank: rank, size: size),
          const SizedBox(width: 3),
          Text(
            rank.abbreviation,
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontWeight: FontWeight.w700,
              fontSize: size * 0.78,
              color: rank.color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
