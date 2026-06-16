import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show CircleAvatar, Colors, showModalBottomSheet;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../../../providers/unit_system_provider.dart';
import '../../../ranks/domain/military_ranks.dart';
import '../../../ranks/presentation/widgets/rank_badge.dart';
import '../../data/follow_repository.dart';
import '../../domain/firestore_user.dart';
import '../../domain/leaderboard_entry.dart';
import '../feed/post_moderation.dart';

/// Shows a compact rank-showcase profile for [userId] as a bottom sheet — the
/// quick-look you get by tapping a username in the feed.
Future<void> showMiniProfileSheet(BuildContext context, String userId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MiniProfileSheet(userId: userId),
  );
}

class _MiniProfileSheet extends ConsumerWidget {
  const _MiniProfileSheet({required this.userId});

  final String userId;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final userAsync = ref.watch(userByIdProvider(userId));

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: palette.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              userAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CupertinoActivityIndicator(),
                ),
                error: (_, _) => _message(palette, 'Could not load profile.'),
                data: (user) {
                  if (user == null) {
                    return _message(palette, 'User not found.');
                  }
                  return _Content(user: user, palette: palette);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _message(Palette palette, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            fontSize: 14,
            color: palette.textSecondary,
          ),
        ),
      );
}

class _Content extends ConsumerWidget {
  const _Content({required this.user, required this.palette});

  final FirestoreUser user;
  final Palette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(leaderboardEntryProvider(user.userId)).valueOrNull;

    final points = entry?.scoreOverall ?? (user.rankIndex?.toDouble() ?? 0);
    final rank = rankFromPoints(points);
    final score = rankDisplayScore(points);
    final progress = (points - points.floorToDouble()).clamp(0.0, 1.0);
    final isMax = rank.index >= MilitaryRank.values.length - 1;
    final nextRank = isMax ? null : rankFromIndex(rank.index + 1);

    final currentUserId = ref.watch(currentUserIdProvider);
    final isSelf = currentUserId == user.userId;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar + large rank insignia.
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            _Avatar(user: user, palette: palette),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rank.color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: palette.surface, width: 2),
              ),
              alignment: Alignment.center,
              child: RankInsignia(rank: rank, size: 26),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '@${user.username}',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: palette.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          rank.displayName,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: rank.color,
          ),
        ),
        if (user.createdAt != null) ...[
          const SizedBox(height: 4),
          Text(
            'Enlisted ${_MiniProfileSheet._months[user.createdAt!.month - 1]} '
            '${user.createdAt!.year}',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 13,
              color: palette.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Overall score + progress to next rank.
        _ScoreBar(
          score: score,
          progress: progress,
          caption: nextRank == null
              ? 'Max rank reached'
              : '${(progress * 100).round()}% to ${nextRank.displayName}',
          rankColor: rank.color,
          palette: palette,
        ),
        const SizedBox(height: 16),

        // Top lifts with their muscle-group rank badges.
        _TopLifts(entry: entry, palette: palette),
        const SizedBox(height: 18),

        // Actions.
        Row(
          children: [
            if (!isSelf && currentUserId != null)
              Expanded(
                child: _MiniFollowButton(
                  currentUserId: currentUserId,
                  targetUserId: user.userId,
                  palette: palette,
                ),
              ),
            if (!isSelf && currentUserId != null) const SizedBox(width: 10),
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: palette.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/profile/${user.userId}');
                },
                child: Text(
                  'View Profile',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: palette.text,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Block (Guideline 1.2) — only for other users.
        if (!isSelf && currentUserId != null) ...[
          const SizedBox(height: 4),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 8),
            onPressed: () async {
              final blocked = await blockUserFlow(
                context,
                ref,
                targetUserId: user.userId,
                username: user.username,
              );
              if (blocked && context.mounted) Navigator.of(context).pop();
            },
            child: Text(
              'Block @${user.username}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: CupertinoColors.systemRed,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.palette});

  final FirestoreUser user;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final url = user.profilePictureUrl;
    final letter =
        (user.username.isNotEmpty ? user.username[0] : '?').toUpperCase();
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 38,
        backgroundColor: palette.surfaceElevated,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            width: 76,
            height: 76,
            fit: BoxFit.cover,
            placeholder: (_, _) => const CupertinoActivityIndicator(),
            errorWidget: (_, _, _) => _fallback(letter),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 38,
      backgroundColor: palette.accent,
      child: _fallback(letter, onAccent: true),
    );
  }

  Widget _fallback(String letter, {bool onAccent = false}) => Text(
        letter,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 30,
          color: onAccent ? CupertinoColors.white : palette.textSecondary,
        ),
      );
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.score,
    required this.progress,
    required this.caption,
    required this.rankColor,
    required this.palette,
  });

  final int score;
  final double progress;
  final String caption;
  final Color rankColor;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overall Rank Score',
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 13,
                color: palette.textSecondary,
              ),
            ),
            Text(
              '$score pts',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: palette.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      width: constraints.maxWidth,
                      color: palette.surfaceElevated,
                    ),
                    Container(
                      width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        color: rankColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          caption,
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            fontSize: 12,
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TopLifts extends ConsumerWidget {
  const _TopLifts({required this.entry, required this.palette});

  final LeaderboardEntry? entry;
  final Palette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitSystemProvider);
    final e = entry;
    final hasData =
        e != null && (e.benchKg > 0 || e.squatKg > 0 || e.deadliftKg > 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Lifts',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 10),
          if (!hasData)
            Text(
              'No big-3 lifts logged yet.',
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 13,
                color: palette.textSecondary,
              ),
            )
          else ...[
            _liftRow('Bench', e.benchKg, e.scoreChest, units),
            const SizedBox(height: 8),
            _liftRow('Squat', e.squatKg, e.scoreLegs, units),
            const SizedBox(height: 8),
            _liftRow('Deadlift', e.deadliftKg, e.scoreBack, units),
          ],
        ],
      ),
    );
  }

  Widget _liftRow(String label, double kg, double groupPoints, UnitSystem units) {
    final rank = rankFromPoints(groupPoints);
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 13.5,
              color: palette.text,
            ),
          ),
        ),
        Expanded(
          child: Text(
            UnitConverter.formatWeight(kg, units),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: palette.text,
            ),
          ),
        ),
        RankInsignia(rank: rank, size: 16),
        const SizedBox(width: 4),
        Text(
          rank.abbreviation,
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: rank.color,
          ),
        ),
      ],
    );
  }
}

class _MiniFollowButton extends ConsumerStatefulWidget {
  const _MiniFollowButton({
    required this.currentUserId,
    required this.targetUserId,
    required this.palette,
  });

  final String currentUserId;
  final String targetUserId;
  final Palette palette;

  @override
  ConsumerState<_MiniFollowButton> createState() => _MiniFollowButtonState();
}

class _MiniFollowButtonState extends ConsumerState<_MiniFollowButton> {
  bool _loading = false;

  Future<void> _toggle(bool following) async {
    HapticFeedback.selectionClick();
    setState(() => _loading = true);
    try {
      final repo = ref.read(followRepositoryProvider);
      if (following) {
        await repo.unfollow(widget.currentUserId, widget.targetUserId);
      } else {
        await repo.follow(widget.currentUserId, widget.targetUserId);
      }
      ref.invalidate(isFollowingProvider(widget.targetUserId));
      ref.invalidate(userByIdProvider(widget.targetUserId));
      ref.invalidate(followingIdsProvider);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final following =
        ref.watch(isFollowingProvider(widget.targetUserId)).valueOrNull ?? false;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: following ? palette.surfaceElevated : palette.accent,
      borderRadius: BorderRadius.circular(12),
      onPressed: _loading ? null : () => _toggle(following),
      child: _loading
          ? CupertinoActivityIndicator(
              color: following ? palette.accent : CupertinoColors.white,
            )
          : Text(
              following ? 'Following' : 'Follow',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: following ? palette.text : CupertinoColors.white,
              ),
            ),
    );
  }
}
