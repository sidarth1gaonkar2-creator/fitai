import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar, Colors;
import 'package:timeago/timeago.dart' as timeago;

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/post.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.isLiked,
    required this.onLike,
    required this.onComment,
    required this.onTapUser,
  });

  final Post post;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onTapUser;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(palette),
          const SizedBox(height: 12),
          _buildWorkoutName(palette),
          const SizedBox(height: 8),
          _buildExerciseList(palette),
          const SizedBox(height: 8),
          _buildStatsRow(palette),
          if (post.caption.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildCaption(palette),
          ],
          const SizedBox(height: 12),
          _buildBottomRow(palette),
        ],
      ),
    );
  }

  Widget _buildHeader(Palette palette) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTapUser,
          child: _buildAvatar(palette),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: onTapUser,
            child: Text(
              post.username,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: palette.text,
              ),
            ),
          ),
        ),
        Text(
          post.createdAt != null
              ? timeago.format(post.createdAt!)
              : '',
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            fontSize: 12,
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(Palette palette) {
    final pic = post.userProfilePic;
    if (pic != null && pic.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: CachedNetworkImageProvider(pic),
        backgroundColor: palette.surfaceElevated,
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: palette.accent,
      child: Text(
        post.username.isNotEmpty ? post.username[0].toUpperCase() : '?',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: CupertinoColors.white,
        ),
      ),
    );
  }

  Widget _buildWorkoutName(Palette palette) {
    return Text(
      post.workoutName,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: palette.text,
      ),
    );
  }

  Widget _buildExerciseList(Palette palette) {
    final exercises = post.exercises;
    if (exercises.isEmpty) return const SizedBox.shrink();

    final visible = exercises.take(3).toList();
    final remaining = exercises.length - 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final ex in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '${ex.name} \u00b7 ${ex.sets} sets \u00b7 ${ex.bestWeight.toStringAsFixed(ex.bestWeight.truncateToDouble() == ex.bestWeight ? 0 : 1)}kg',
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 13,
                color: palette.textSecondary,
              ),
            ),
          ),
        if (remaining > 0)
          Text(
            '+$remaining more',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 13,
              color: palette.accent,
            ),
          ),
      ],
    );
  }

  Widget _buildStatsRow(Palette palette) {
    final volumeStr = post.totalVolume >= 1000
        ? '${(post.totalVolume / 1000).toStringAsFixed(1)}t'
        : '${post.totalVolume.toStringAsFixed(1)}kg';

    return Text(
      '${post.totalSets} sets \u00b7 $volumeStr volume \u00b7 ${post.duration}min',
      style: TextStyle(
        fontFamily: 'LeagueSpartan',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: palette.text,
      ),
    );
  }

  Widget _buildCaption(Palette palette) {
    return Text(
      post.caption,
      style: TextStyle(
        fontFamily: 'LeagueSpartan',
        fontSize: 14,
        color: palette.text,
      ),
    );
  }

  Widget _buildBottomRow(Palette palette) {
    return Row(
      children: [
        GestureDetector(
          onTap: onLike,
          child: Row(
            children: [
              Icon(
                isLiked
                    ? CupertinoIcons.heart_fill
                    : CupertinoIcons.heart,
                size: 20,
                color: isLiked ? palette.accent : palette.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${post.likesCount}',
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontSize: 13,
                  color: isLiked ? palette.accent : palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: onComment,
          child: Row(
            children: [
              Icon(
                CupertinoIcons.chat_bubble,
                size: 20,
                color: palette.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${post.commentsCount}',
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontSize: 13,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
