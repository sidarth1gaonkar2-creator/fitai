import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar;
import 'package:timeago/timeago.dart' as timeago;

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/field_manual.dart';
import '../../../../ranks/presentation/widgets/user_rank_badge.dart';
import '../../../domain/comment.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comment,
    this.isOwn = false,
    this.onDelete,
  });

  final Comment comment;
  final bool isOwn;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(palette),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      // Username is user content: Inter, never uppercased;
                      // w600 is the permitted emphasis.
                      child: Text(
                        comment.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FieldManual.body(
                          fontSize: 13,
                          color: palette.text,
                        ).copyWith(
                          fontWeight: FontWeight.w600,
                          fontVariations: const [FontVariation('wght', 600)],
                        ),
                      ),
                    ),
                    UserRankBadge(userId: comment.userId, size: 11),
                    const SizedBox(width: 6),
                    Text(
                      comment.createdAt != null
                          ? timeago.format(comment.createdAt!)
                          : '',
                      style: FieldManual.label(
                        fontSize: 11,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Comment body is a human voice: Inter, sentence case.
                Text(
                  comment.text,
                  style: FieldManual.body(fontSize: 14, color: palette.text),
                ),
              ],
            ),
          ),
          if (isOwn && onDelete != null)
            // Quiet but discoverable — alert red belongs to the confirm
            // step, not the resting entry point.
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onDelete, minimumSize: Size(24, 24),
              child: Icon(
                CupertinoIcons.trash,
                size: 16,
                color: palette.textSecondary,
                semanticLabel: 'Delete comment',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Palette palette) {
    final pic = comment.userProfilePic;
    if (pic != null && pic.isNotEmpty) {
      return CircleAvatar(
        radius: 10,
        backgroundImage: CachedNetworkImageProvider(pic),
        backgroundColor: palette.surfaceElevated,
      );
    }
    return CircleAvatar(
      radius: 10,
      backgroundColor: palette.accent,
      child: Text(
        comment.username.isNotEmpty
            ? comment.username[0].toUpperCase()
            : '?',
        style: TextStyle(
          fontFamily: 'Inter',
          fontVariations: const [FontVariation('wght', 700)],
          fontWeight: FontWeight.bold,
          fontSize: 10,
          // Sits on the accent fill — never hardcoded ink/white.
          color: palette.onAccent,
        ),
      ),
    );
  }
}
