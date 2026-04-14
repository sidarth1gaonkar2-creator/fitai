import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../data/post_repository.dart';
import '../../domain/post.dart';
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

    return CupertinoPageScaffold(
      backgroundColor: palette.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: palette.surface,
        border: Border(bottom: BorderSide(color: palette.border)),
        middle: Text(
          'Feed',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: palette.text,
          ),
        ),
      ),
      child: feedState.posts.isEmpty && !feedState.isLoading
          ? _buildEmptyState(palette)
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () =>
                      ref.read(feedControllerProvider.notifier).refresh(),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.person_2,
            size: 48,
            color: palette.accent,
          ),
          const SizedBox(height: 16),
          Text(
            'Follow users to see their\nworkouts here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 16,
              color: palette.textSecondary,
            ),
          ),
        ],
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

    return PostCard(
      post: post,
      isLiked: isLiked,
      onLike: () async {
        if (currentUserId == null) return;
        await ref
            .read(postRepositoryProvider)
            .toggleLike(post.postId, currentUserId!);
        ref.invalidate(isPostLikedProvider(post.postId));
        ref.read(feedControllerProvider.notifier).refresh();
      },
      onComment: () {
        context.push('/feed/post/${post.postId}');
      },
      onTapUser: () {
        context.push('/profile/${post.userId}');
      },
    );
  }
}
