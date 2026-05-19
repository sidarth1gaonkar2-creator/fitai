import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show CircleAvatar, Colors, Material, showDialog;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/relative_time.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../providers/community_providers.dart';
import '../../../data/post_repository.dart';
import '../../../domain/post.dart';

class PostCard extends ConsumerStatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.isLiked,
    required this.onLike,
    required this.onComment,
    required this.onTapUser,
    this.onShare,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
  });

  final Post post;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onTapUser;
  final VoidCallback? onShare;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// The five reaction emoji choices shown in the long-press picker. Ordered
  /// from "expected default" (muscle) to "savage" (beast-mode-face).
  static const reactionChoices = ['💪', '🔥', '🏆', '👏', '😤'];

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _likeAnim;
  late final Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1,
    );
    _likeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _likeAnim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _likeAnim.dispose();
    super.dispose();
  }

  void _handleLike() {
    HapticFeedback.lightImpact();
    _likeAnim.forward(from: 0);
    widget.onLike();
  }

  /// Long-press handler — opens the emoji reaction picker as a small popup
  /// anchored to where the user pressed. Falls back to a centered modal if
  /// the tap coordinates aren't usable.
  Future<void> _openReactionPicker(Offset globalPosition) async {
    HapticFeedback.mediumImpact();
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final repo = ref.read(postRepositoryProvider);
    final picked = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      builder: (ctx) => _ReactionPickerOverlay(
        anchor: globalPosition,
        choices: PostCard.reactionChoices,
      ),
    );
    if (picked == null) return;
    await repo.setReaction(widget.post.postId, userId, picked);
    // Invalidate so the row recomputes from Firestore.
    ref.invalidate(postReactionsProvider(widget.post.postId));
    ref.invalidate(userReactionProvider(widget.post.postId));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final post = widget.post;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            post: post,
            palette: palette,
            onTapUser: widget.onTapUser,
            isOwner: widget.isOwner,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
          ),
          if (post.caption.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              post.caption,
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 14.5,
                color: palette.text,
                height: 1.35,
              ),
            ),
          ],
          if (post.workoutId != null || post.workoutName.isNotEmpty) ...[
            const SizedBox(height: 12),
            _WorkoutAttachment(post: post, palette: palette),
          ],
          const SizedBox(height: 8),
          _ReactionSummaryRow(postId: post.postId),
          const SizedBox(height: 4),
          _ActionsRow(
            post: post,
            palette: palette,
            isLiked: widget.isLiked,
            likeScale: _likeScale,
            onLike: _handleLike,
            onLongPressLike: _openReactionPicker,
            onComment: () {
              HapticFeedback.selectionClick();
              widget.onComment();
            },
            onShare: widget.onShare == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    widget.onShare!.call();
                  },
          ),
        ],
      ),
    );
  }
}

// ─── Reaction summary row ──────────────────────────────────────────────────

class _ReactionSummaryRow extends ConsumerWidget {
  const _ReactionSummaryRow({required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(postReactionsProvider(postId));
    final counts = async.valueOrNull;
    if (counts == null || counts.isEmpty) return const SizedBox.shrink();
    // Sort by count desc, take top 3 so the row never overflows.
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();
    final palette = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Row(
        children: [
          for (final entry in top) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: palette.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

// ─── Reaction picker overlay ───────────────────────────────────────────────

class _ReactionPickerOverlay extends StatelessWidget {
  const _ReactionPickerOverlay({
    required this.anchor,
    required this.choices,
  });

  final Offset anchor;
  final List<String> choices;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final size = MediaQuery.of(context).size;
    // Position the picker near the anchor but keep it on-screen. The picker
    // is roughly 270×52; nudge it leftwards if needed.
    final left = (anchor.dx - 135).clamp(12.0, size.width - 282.0);
    final top = (anchor.dy - 70).clamp(60.0, size.height - 60.0);
    return Stack(
      children: [
        // Tap-outside dismiss
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: palette.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final emoji in choices)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop(emoji);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.post,
    required this.palette,
    required this.onTapUser,
    required this.isOwner,
    this.onEdit,
    this.onDelete,
  });

  final Post post;
  final Palette palette;
  final VoidCallback onTapUser;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTapUser,
          child: _PostAvatar(
            url: post.userProfilePic,
            username: post.username,
            palette: palette,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: onTapUser,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  post.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatRelativeTime(post.createdAt),
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 12,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isOwner && (onEdit != null || onDelete != null))
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _openMenu(context), minimumSize: Size(32, 32),
            child: Icon(
              CupertinoIcons.ellipsis,
              size: 20,
              color: palette.textSecondary,
            ),
          ),
      ],
    );
  }

  void _openMenu(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          if (onEdit != null)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                onEdit!();
              },
              child: const Text('Edit post'),
            ),
          if (onDelete != null)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                onDelete!();
              },
              child: const Text('Delete post'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

class _PostAvatar extends StatelessWidget {
  const _PostAvatar({
    required this.url,
    required this.username,
    required this.palette,
  });

  final String? url;
  final String username;
  final Palette palette;
  static const double radius = 20;

  @override
  Widget build(BuildContext context) {
    final letter =
        (username.isNotEmpty ? username[0] : '?').toUpperCase();
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: palette.surfaceElevated,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (_, _) => const CupertinoActivityIndicator(radius: 8),
            errorWidget: (_, _, _) => _avatarFallback(letter),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: palette.accent,
      child: _avatarFallback(letter),
    );
  }

  Widget _avatarFallback(String letter) => Text(
        letter,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.85,
          color: CupertinoColors.white,
        ),
      );
}

// ─── Workout attachment card ───────────────────────────────────────────────

class _WorkoutAttachment extends StatelessWidget {
  const _WorkoutAttachment({required this.post, required this.palette});

  final Post post;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final volumeStr = post.totalVolume >= 1000
        ? '${(post.totalVolume / 1000).toStringAsFixed(1)}t'
        : '${post.totalVolume.toStringAsFixed(0)}kg';
    final date = formatRelativeTime(post.createdAt);
    final exerciseCount = post.exercises.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.flame_fill,
                  size: 18,
                  color: palette.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.workoutName.isEmpty ? 'Workout' : post.workoutName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: palette.text,
                      ),
                    ),
                    if (date.isNotEmpty)
                      Text(
                        date,
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 12,
                          color: palette.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _stat(palette, '$exerciseCount', 'exercises'),
              _sep(palette),
              _stat(palette, '${post.totalSets}', 'sets'),
              _sep(palette),
              _stat(palette, volumeStr, 'volume'),
              if (post.duration > 0) ...[
                _sep(palette),
                _stat(palette, '${post.duration}m', 'time'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(Palette palette, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 11,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sep(Palette palette) => Container(
        width: 1,
        height: 22,
        color: palette.border,
      );
}

// ─── Actions row ───────────────────────────────────────────────────────────

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.post,
    required this.palette,
    required this.isLiked,
    required this.likeScale,
    required this.onLike,
    required this.onLongPressLike,
    required this.onComment,
    this.onShare,
  });

  final Post post;
  final Palette palette;
  final bool isLiked;
  final Animation<double> likeScale;
  final VoidCallback onLike;
  final void Function(Offset globalPosition) onLongPressLike;
  final VoidCallback onComment;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Wrap the like action in a GestureDetector for long-press → emoji
        // reaction picker. Short tap still goes to the existing like flow.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPressStart: (details) =>
              onLongPressLike(details.globalPosition),
          child: _action(
            icon: ScaleTransition(
              scale: likeScale,
              child: Icon(
                isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                size: 22,
                color: isLiked ? palette.destructive : palette.textSecondary,
              ),
            ),
            label: '${post.likesCount}',
            active: isLiked,
            onTap: onLike,
          ),
        ),
        const SizedBox(width: 20),
        _action(
          icon: Icon(
            CupertinoIcons.chat_bubble,
            size: 20,
            color: palette.textSecondary,
          ),
          label: '${post.commentsCount}',
          onTap: onComment,
        ),
        const Spacer(),
        if (onShare != null)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onShare, minimumSize: Size(32, 32),
            child: Icon(
              CupertinoIcons.share,
              size: 20,
              color: palette.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _action({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          icon,
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: active ? palette.destructive : palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
