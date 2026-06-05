import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show FloatingActionButton, Icons, Scaffold;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../data/post_repository.dart';
import '../../domain/post.dart';
import '../profile/mini_profile_sheet.dart';
import 'widgets/post_card.dart';

// ─── Feed State ────────────────────────────────────────────────────────────

class FeedState {
  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDocument,
  });

  final List<Post> posts;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  FeedState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    bool clearLastDocument = false,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDocument:
          clearLastDocument ? null : (lastDocument ?? this.lastDocument),
    );
  }
}

// ─── Feed Controller ───────────────────────────────────────────────────────

class FeedController extends StateNotifier<FeedState> {
  FeedController({
    required this.postRepository,
    required this.userId,
    required this.followingIds,
  }) : super(const FeedState()) {
    loadInitial();
  }

  final PostRepository postRepository;
  final String userId;
  final Set<String> followingIds;

  static const _pageSize = 20;

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    try {
      final (posts, lastDoc) = await postRepository.getFeedPosts(
        userId: userId,
        followingIds: followingIds,
        limit: _pageSize,
      );
      state = FeedState(
        posts: posts,
        isLoading: false,
        hasMore: posts.length >= _pageSize,
        lastDocument: lastDoc,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      final (posts, lastDoc) = await postRepository.getFeedPosts(
        userId: userId,
        followingIds: followingIds,
        startAfter: state.lastDocument,
        limit: _pageSize,
      );
      state = state.copyWith(
        posts: [...state.posts, ...posts],
        isLoading: false,
        hasMore: posts.length >= _pageSize,
        lastDocument: lastDoc,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    state = const FeedState();
    await loadInitial();
  }
}

// ─── Provider ──────────────────────────────────────────────────────────────

final feedControllerProvider =
    StateNotifierProvider.autoDispose<FeedController, FeedState>((ref) {
  final userId = ref.watch(currentUserIdProvider) ?? '';
  final followingIds =
      ref.watch(followingIdsProvider).valueOrNull ?? const <String>{};
  final postRepo = ref.watch(postRepositoryProvider);

  return FeedController(
    postRepository: postRepo,
    userId: userId,
    followingIds: followingIds,
  );
});

// ─── Feed Screen ───────────────────────────────────────────────────────────

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      ref.read(feedControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final feedState = ref.watch(feedControllerProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: palette.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: palette.accent,
        foregroundColor: CupertinoColors.white,
        onPressed: () => context.push('/community/create-post'),
        tooltip: 'New post',
        child: const Icon(Icons.add),
      ),
      body: feedState.posts.isEmpty && !feedState.isLoading
          ? _buildEmptyState(palette)
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () =>
                      ref.read(feedControllerProvider.notifier).refresh(),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 8, bottom: 96),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= feedState.posts.length) {
                          return feedState.hasMore
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(
                                    child: CupertinoActivityIndicator(),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }

                        final post = feedState.posts[index];

                        return _PostCardWrapper(
                          post: post,
                          currentUserId: currentUserId,
                        );
                      },
                      childCount: feedState.posts.length +
                          (feedState.hasMore ? 1 : 0),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(Palette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.person_2,
              size: 48,
              color: palette.textSecondary,
            ),
            const SizedBox(height: 14),
            Text(
              'Fall in with the platoon, recruit',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Follow other soldiers to see their posts, or post your first workout.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 14,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              color: palette.accent,
              borderRadius: BorderRadius.circular(10),
              onPressed: () => context.push('/community/create-post'),
              child: const Text(
                'Share a workout',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Wrapper widget that handles like state per-post via Riverpod
class _PostCardWrapper extends ConsumerWidget {
  const _PostCardWrapper({
    required this.post,
    required this.currentUserId,
  });

  final Post post;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedAsync = ref.watch(isPostLikedProvider(post.postId));
    final isLiked = likedAsync.valueOrNull ?? false;
    final isOwner = currentUserId == post.userId;

    return PostCard(
      post: post,
      isLiked: isLiked,
      isOwner: isOwner,
      onLike: () async {
        if (currentUserId == null) return;
        await ref
            .read(postRepositoryProvider)
            .toggleLike(post.postId, currentUserId!);
        ref.invalidate(isPostLikedProvider(post.postId));
        ref.read(feedControllerProvider.notifier).refresh();
      },
      onComment: () {
        context.push('/community/post/${post.postId}');
      },
      onTapUser: () => showMiniProfileSheet(context, post.userId),
      onDelete: isOwner
          ? () async {
              final confirmed = await showCupertinoDialog<bool>(
                context: context,
                builder: (ctx) => CupertinoAlertDialog(
                  title: const Text('Delete post?'),
                  content: const Text(
                      'This will permanently remove the post for everyone.'),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref
                    .read(postRepositoryProvider)
                    .deletePost(post.postId);
                ref.read(feedControllerProvider.notifier).refresh();
              }
            }
          : null,
    );
  }
}
