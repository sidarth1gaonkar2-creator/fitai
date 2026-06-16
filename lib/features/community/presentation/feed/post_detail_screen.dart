import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../data/post_repository.dart';
import '../../domain/comment.dart';
import '../../domain/post.dart';
import 'post_moderation.dart';
import 'widgets/comment_tile.dart';
import 'widgets/post_card.dart';

final _postByIdProvider =
    FutureProvider.family.autoDispose<Post?, String>((ref, postId) async {
  return ref.watch(postRepositoryProvider).getPost(postId);
});

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _uuid = const Uuid();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final firestoreUser = ref.read(firestoreUserProvider).valueOrNull;

    setState(() => _isSending = true);

    try {
      final comment = Comment(
        commentId: _uuid.v4(),
        userId: userId,
        username: firestoreUser?.username ?? 'User',
        userProfilePic: firestoreUser?.profilePictureUrl,
        text: text,
        createdAt: DateTime.now(),
      );

      await ref
          .read(postRepositoryProvider)
          .addComment(widget.postId, comment);
      _commentController.clear();
      ref.invalidate(postCommentsProvider(widget.postId));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final likedAsync = ref.watch(isPostLikedProvider(widget.postId));
    final postAsync = ref.watch(_postByIdProvider(widget.postId));
    final isLiked = likedAsync.valueOrNull ?? false;
    final post = postAsync.valueOrNull;

    return CupertinoPageScaffold(
      backgroundColor: palette.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: palette.surface,
        border: Border(bottom: BorderSide(color: palette.border)),
        middle: Text(
          'Post',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: palette.text,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                children: [
                  if (post != null)
                    PostCard(
                      post: post,
                      isLiked: isLiked,
                      isOwner: post.userId == currentUserId,
                      onLike: () async {
                        if (currentUserId == null) return;
                        await ref
                            .read(postRepositoryProvider)
                            .toggleLike(widget.postId, currentUserId);
                        ref.invalidate(
                            isPostLikedProvider(widget.postId));
                        ref.invalidate(_postByIdProvider(widget.postId));
                      },
                      onComment: () {
                        // Already on detail screen; no-op
                      },
                      onTapUser: () {
                        context.push('/profile/${post.userId}');
                      },
                      onReport: post.userId == currentUserId
                          ? null
                          : () => reportPostFlow(context, ref,
                              postId: post.postId,
                              reportedUserId: post.userId),
                      onBlock: post.userId == currentUserId
                          ? null
                          : () => blockUserFlow(context, ref,
                              targetUserId: post.userId,
                              username: post.username),
                      onDelete: post.userId == currentUserId
                          ? () async {
                              final confirmed =
                                  await showCupertinoDialog<bool>(
                                context: context,
                                builder: (ctx) => CupertinoAlertDialog(
                                  title: const Text('Delete post?'),
                                  content: const Text(
                                      'This will permanently remove the post for everyone.'),
                                  actions: [
                                    CupertinoDialogAction(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    CupertinoDialogAction(
                                      isDestructiveAction: true,
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true && mounted) {
                                await ref
                                    .read(postRepositoryProvider)
                                    .deletePost(widget.postId);
                                if (mounted) context.pop();
                              }
                            }
                          : null,
                    ),
                  if (postAsync.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CupertinoActivityIndicator()),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Text(
                      'Comments',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: palette.text,
                      ),
                    ),
                  ),
                  commentsAsync.when(
                    data: (comments) {
                      if (comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No comments yet. Be the first!',
                            style: TextStyle(
                              fontFamily: 'LeagueSpartan',
                              fontSize: 14,
                              color: palette.textSecondary,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (final comment in comments)
                            CommentTile(
                              comment: comment,
                              isOwn: comment.userId == currentUserId,
                              onDelete: comment.userId == currentUserId
                                  ? () {
                                      // Delete not yet implemented in repo
                                    }
                                  : null,
                            ),
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CupertinoActivityIndicator()),
                    ),
                    error: (_, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Failed to load comments.',
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 14,
                          color: palette.destructive,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildCommentInput(palette),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput(Palette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _commentController,
              placeholder: 'Add a comment...',
              placeholderStyle: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 14,
                color: palette.textSecondary,
              ),
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 14,
                color: palette.text,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.border),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              maxLines: 3,
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isSending ? null : _sendComment, minimumSize: Size(36, 36),
            child: _isSending
                ? const CupertinoActivityIndicator()
                : Icon(
                    CupertinoIcons.arrow_up_circle_fill,
                    size: 32,
                    color: palette.accent,
                  ),
          ),
        ],
      ),
    );
  }
}
