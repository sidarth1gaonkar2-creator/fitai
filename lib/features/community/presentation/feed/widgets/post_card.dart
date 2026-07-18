import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show CircleAvatar, Colors, Material, showDialog;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/field_manual.dart';
import '../../../../../core/utils/relative_time.dart';
import '../../../../../core/utils/unit_converter.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../providers/community_providers.dart';
import '../../../../../providers/unit_system_provider.dart';
import '../../../../ranks/domain/military_ranks.dart';
import '../../../../ranks/presentation/widgets/rank_badge.dart';
import '../../../data/post_repository.dart';
import '../../../domain/post.dart';

/// A community feed post card. Rank-first: the author's rank insignia leads the
/// header before the avatar, with the rank name in its rank colour. Designed to
/// be compact — tight spacing, a slim reaction bar (compact visuals over
/// 44pt hit targets), and a slim workout attachment.
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
    this.onReport,
    this.onBlock,
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

  /// Non-owner moderation actions (Guideline 1.2). When set, the header menu
  /// surfaces "Report post" / "Block @user" for posts the viewer doesn't own.
  final VoidCallback? onReport;
  final VoidCallback? onBlock;

  /// The five reaction emoji choices shown in the long-press picker.
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
    // Reduced motion: skip the heart-pop choreography entirely.
    if (!MediaQuery.disableAnimationsOf(context)) {
      _likeAnim.forward(from: 0);
    }
    widget.onLike();
  }

  /// Long-press handler — opens the emoji reaction picker as a small popup
  /// anchored to where the user pressed.
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
    ref.invalidate(postReactionsProvider(widget.post.postId));
    ref.invalidate(userReactionProvider(widget.post.postId));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final post = widget.post;

    return Container(
      // ~15% tighter than the old 16/8 + 14 padding. Field card on ink:
      // 8px corners, hairline border, no shadow (DESIGN.md §Cards).
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 9),
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
            onReport: widget.onReport,
            onBlock: widget.onBlock,
          ),
          if (post.caption.isNotEmpty) ...[
            const SizedBox(height: 9),
            // User content: Inter body, never uppercased (the Bark Budget Rule).
            Text(
              post.caption,
              style: FieldManual.body(fontSize: 14.5, color: palette.text),
            ),
          ],
          if (post.hasWorkout) ...[
            const SizedBox(height: 10),
            _WorkoutAttachment(post: post, palette: palette),
          ],
          const SizedBox(height: 8),
          _ReactionBar(
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

// ─── Header ────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  const _Header({
    required this.post,
    required this.palette,
    required this.onTapUser,
    required this.isOwner,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.onBlock,
  });

  final Post post;
  final Palette palette;
  final VoidCallback onTapUser;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Author rank for the leading badge. Prefer the value embedded on the post
    // (no extra fetch); fall back to the author's Firestore user doc for legacy
    // posts; finally default to Private (PVT) so every post shows a badge. The
    // `??` short-circuits, so the user-doc lookup only runs when the post has no
    // embedded rank.
    final rankIdx = post.rankIndex ??
        ref.watch(userByIdProvider(post.userId)).valueOrNull?.rankIndex ??
        0;
    final rank = rankFromIndex(rankIdx);

    return Row(
      children: [
        // 1. Rank badge first — the visual anchor.
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: rank.color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: RankInsignia(rank: rank, size: 22),
        ),
        const SizedBox(width: 8),
        // 2+3. Avatar + username/rank/time — one combined profile tap zone
        // (single semantics button, ≥44pt effective hit height).
        Expanded(
          child: Semantics(
            button: true,
            label: "View ${post.username}'s profile",
            child: ExcludeSemantics(
              child: GestureDetector(
                onTap: onTapUser,
                behavior: HitTestBehavior.opaque,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Row(
                    children: [
                      // Avatar — smaller (36px); the hit zone is the row.
                      _PostAvatar(
                        url: post.userProfilePic,
                        username: post.username,
                        palette: palette,
                      ),
                      const SizedBox(width: 10),
                      // Username + rank name, then time.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  // Username is user content: Inter, never
                                  // uppercased; w600 is the permitted
                                  // emphasis.
                                  child: Text(
                                    post.username,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: FieldManual.body(
                                      fontSize: 14,
                                      color: palette.text,
                                    ).copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontVariations: const [
                                        FontVariation('wght', 600),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Rank designation: mono stamp in the rank's
                                // AA-safe textColor — never the raw rank
                                // colour at small sizes.
                                Text(
                                  rank.displayName.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FieldManual.label(
                                    fontSize: 11,
                                    color: rank.textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              formatRelativeTime(post.createdAt),
                              style: FieldManual.label(
                                fontSize: 11,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_hasMenu)
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 44),
            onPressed: () => _openMenu(context),
            child: Icon(
              CupertinoIcons.ellipsis,
              size: 18,
              color: palette.textSecondary,
              semanticLabel: 'Post options',
            ),
          ),
      ],
    );
  }

  /// Owners get Edit/Delete; everyone else gets Report/Block (Guideline 1.2).
  bool get _hasMenu => isOwner
      ? (onEdit != null || onDelete != null)
      : (onReport != null || onBlock != null);

  void _openMenu(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          if (isOwner) ...[
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
          ] else ...[
            if (onReport != null)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onReport!();
                },
                child: const Text('Report post'),
              ),
            if (onBlock != null)
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onBlock!();
                },
                child: Text('Block @${post.username}'),
              ),
          ],
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
  static const double radius = 18; // 36px diameter

  @override
  Widget build(BuildContext context) {
    final letter = (username.isNotEmpty ? username[0] : '?').toUpperCase();
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
            placeholder: (_, _) => const CupertinoActivityIndicator(radius: 7),
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
          fontFamily: 'Inter',
          fontVariations: const [FontVariation('wght', 700)],
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.82,
          // Sits on the accent fill — never hardcoded ink/white.
          color: palette.onAccent,
        ),
      );
}

// ─── Compact workout attachment ──────────────────────────────────────────────

class _WorkoutAttachment extends ConsumerWidget {
  const _WorkoutAttachment({required this.post, required this.palette});

  final Post post;
  final Palette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitSystemProvider);
    final converted = units == UnitSystem.imperial
        ? UnitConverter.kgToLbs(post.totalVolume)
        : post.totalVolume;
    final unitLabel = UnitConverter.weightUnit(units);
    final volumeStr = converted >= 1000
        ? '${(converted / 1000).toStringAsFixed(1)}k $unitLabel'
        : '${converted.toStringAsFixed(0)} $unitLabel';
    final exerciseCount = post.exercises.length;

    final stats = <String>[
      '$exerciseCount ex',
      '${post.totalSets} sets',
      volumeStr,
      if ((post.duration ?? 0) > 0) '${post.duration}m',
    ];

    // Instrument-panel attachment: raised field ground, hairline border,
    // mono readout for the trained-against numbers.
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.flame_fill,
              size: 16,
              color: palette.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Workout title is user content — Inter, never uppercased.
                Text(
                  (post.workoutName?.isEmpty ?? true)
                      ? 'Workout'
                      : post.workoutName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FieldManual.body(
                    fontSize: 13.5,
                    color: palette.text,
                  ).copyWith(
                    fontWeight: FontWeight.w600,
                    fontVariations: const [FontVariation('wght', 600)],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stats.join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FieldManual.readout(
                    fontSize: 12,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reaction bar (compact visuals, 44pt hit targets) ────────────────────────

class _ReactionBar extends ConsumerWidget {
  const _ReactionBar({
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
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(postReactionsProvider(post.postId)).valueOrNull;
    final top = (counts == null || counts.isEmpty)
        ? const <MapEntry<String, int>>[]
        : (counts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(3)
            .toList();

    // The visuals stay a compact centered row; each tappable stretches to a
    // ≥44pt hit height inside it.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          // Left: emoji reaction pills (compact).
          for (final entry in top) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: palette.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text(
                    '${entry.value}',
                    style: FieldManual.readout(
                      fontSize: 11,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
          ],
          const Spacer(),
          // Right: like + comment counts, then share. The liked state wears
          // the live accent — alert red is for consequences, not affection
          // (the One Voice Rule).
          Semantics(
            button: true,
            selected: isLiked,
            label: isLiked
                ? 'Liked, ${post.likesCount} likes'
                : 'Like, ${post.likesCount} likes',
            child: ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onLike,
                onLongPressStart: (d) => onLongPressLike(d.globalPosition),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      ScaleTransition(
                        scale: likeScale,
                        child: Icon(
                          isLiked
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          size: 18,
                          color:
                              isLiked ? palette.accent : palette.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likesCount}',
                        style: FieldManual.readout(
                          fontSize: 12,
                          color:
                              isLiked ? palette.accent : palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Semantics(
            button: true,
            label: 'Comments, ${post.commentsCount}',
            child: ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onComment,
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.chat_bubble,
                        size: 17,
                        color: palette.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.commentsCount}',
                        style: FieldManual.readout(
                          fontSize: 12,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onShare != null) ...[
            const SizedBox(width: 14),
            Semantics(
              button: true,
              label: 'Share post',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onShare,
                child: SizedBox(
                  height: 44,
                  child: Center(
                    child: Icon(
                      CupertinoIcons.share,
                      size: 17,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
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

  /// Spoken names for the reaction emoji (VoiceOver reads "React: fire"
  /// instead of the raw glyph).
  static const _emojiNames = <String, String>{
    '💪': 'flex',
    '🔥': 'fire',
    '🏆': 'trophy',
    '👏': 'clap',
    '😤': 'determined',
  };

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final size = MediaQuery.of(context).size;
    final left = (anchor.dx - 135).clamp(12.0, size.width - 282.0);
    final top = (anchor.dy - 70).clamp(60.0, size.height - 60.0);
    return Stack(
      children: [
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              // Raised field panel over the scrim — hairline border, no
              // shadow (the Quiet Chrome rule); modality comes from the scrim.
              decoration: BoxDecoration(
                color: palette.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final emoji in choices)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Semantics(
                        button: true,
                        label: 'React: ${_emojiNames[emoji] ?? emoji}',
                        child: ExcludeSemantics(
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
