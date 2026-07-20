import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../data/post_repository.dart';
import '../../domain/post.dart';
import '../profile/mini_profile_sheet.dart';
import 'post_moderation.dart';
import 'widgets/post_card.dart';

// ─── Feed State ────────────────────────────────────────────────────────────

class FeedState {
  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDocument,
    this.error,
  });

  final List<Post> posts;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  /// Non-null when the most recent load threw. Drives the feed's error/retry
  /// state so a failed query is never silently rendered as an empty feed.
  final Object? error;

  bool get hasError => error != null;

  FeedState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    bool clearLastDocument = false,
    Object? error,
    bool clearError = false,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDocument:
          clearLastDocument ? null : (lastDocument ?? this.lastDocument),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Feed Controller ───────────────────────────────────────────────────────

class FeedController extends StateNotifier<FeedState> {
  FeedController({required this.postRepository}) : super(const FeedState()) {
    loadInitial();
  }

  final PostRepository postRepository;

  static const _pageSize = 20;

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final (posts, lastDoc) =
          await postRepository.getPublicFeed(limit: _pageSize);
      state = FeedState(
        posts: posts,
        isLoading: false,
        hasMore: posts.length >= _pageSize,
        lastDocument: lastDoc,
      );
    } catch (e, st) {
      AppLogger.error('Feed load failed', error: e, stack: st);
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      final (posts, lastDoc) = await postRepository.getPublicFeed(
        startAfter: state.lastDocument,
        limit: _pageSize,
      );
      state = state.copyWith(
        posts: [...state.posts, ...posts],
        isLoading: false,
        hasMore: posts.length >= _pageSize,
        clearError: true,
        lastDocument: lastDoc,
      );
    } catch (e, st) {
      AppLogger.error('Feed loadMore failed', error: e, stack: st);
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> refresh() async {
    state = const FeedState();
    await loadInitial();
  }
}

// ─── Provider ──────────────────────────────────────────────────────────────

/// Global public feed. Blocked authors and locally-reported posts are filtered
/// out in the widget layer (reactive to [blockedUserIdsProvider] /
/// [hiddenPostsProvider]) so no re-fetch is needed when the user reports/blocks.
final feedControllerProvider =
    StateNotifierProvider.autoDispose<FeedController, FeedState>((ref) {
  return FeedController(postRepository: ref.watch(postRepositoryProvider));
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

    // Client-side moderation filter layered on the global public query: drop
    // blocked authors and posts the viewer reported/hid. Reactive — reporting
    // or blocking updates these providers and the post disappears with no
    // re-fetch. (Filtering shrinks the visible list; pagination still walks the
    // raw query via lastDocument.)
    final blocked =
        ref.watch(blockedUserIdsProvider).valueOrNull ?? const <String>{};
    final hidden = ref.watch(hiddenPostsProvider);
    final visible = feedState.posts
        .where((p) =>
            !blocked.contains(p.userId) && !hidden.contains(p.postId))
        .toList();

    return Scaffold(
      backgroundColor: palette.scaffold,
      // Field Manual issue: accent fill, sharp 4px, condensed uppercase label
      // (same idiom as the workouts START WORKOUT action). One tap → composer.
      floatingActionButton: Semantics(
        label: 'New post',
        button: true,
        child: ExcludeSemantics(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: palette.accent,
            borderRadius: BorderRadius.circular(4),
            onPressed: _openComposer,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.add, color: palette.onAccent, size: 18),
                const SizedBox(width: 6),
                Text(
                  'NEW POST',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    fontVariations: const [FontVariation('wght', 600)],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.6,
                    color: palette.onAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: visible.isEmpty
          ? _buildPlaceholder(palette, feedState)
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
                        if (index >= visible.length) {
                          return feedState.hasMore
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(
                                    child: CupertinoActivityIndicator(),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }

                        return _PostCardWrapper(
                          post: visible[index],
                          currentUserId: currentUserId,
                        );
                      },
                      childCount: visible.length + (feedState.hasMore ? 1 : 0),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Opens the composer, then refreshes so a just-created public post lands at
  /// the top of the feed (otherwise the user posts and sees nothing change).
  Future<void> _openComposer() async {
    await context.push('/community/create-post');
    if (mounted) ref.read(feedControllerProvider.notifier).refresh();
  }

  /// No posts to show: spinner while loading, a retry-able error state if the
  /// load FAILED, or the friendly empty state only when the load genuinely
  /// succeeded with zero posts. Never conflate a failed query with "no posts".
  Widget _buildPlaceholder(Palette palette, FeedState feedState) {
    if (feedState.isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (feedState.hasError) {
      return _buildErrorState(palette);
    }
    return _buildEmptyState(palette);
  }

  Widget _buildErrorState(Palette palette) {
    // Mono eyebrow + sentence-case Inter guidance (DESIGN.md empty/error idiom).
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: palette.textSecondary,
            ),
            const SizedBox(height: 14),
            Text(
              'FEED UNREACHABLE',
              textAlign: TextAlign.center,
              style: FieldManual.label(
                fontSize: 12,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Something went wrong. Check your connection and try again.',
              textAlign: TextAlign.center,
              style: FieldManual.body(
                fontSize: 14,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            CupertinoPrimaryButton(
              label: 'Retry',
              expanded: false,
              onPressed: () =>
                  ref.read(feedControllerProvider.notifier).refresh(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Palette palette) {
    // Drill-sergeant eyebrow + sentence-case Inter guidance (DESIGN.md).
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
              'FALL IN, RECRUIT',
              textAlign: TextAlign.center,
              style: FieldManual.label(
                fontSize: 12,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to post — share a workout, ask a question, or '
              'introduce yourself to the platoon.',
              textAlign: TextAlign.center,
              style: FieldManual.body(
                fontSize: 14,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            CupertinoPrimaryButton(
              label: 'Create a post',
              expanded: false,
              onPressed: _openComposer,
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
      onReport: isOwner
          ? null
          : () => reportPostFlow(context, ref,
              postId: post.postId, reportedUserId: post.userId),
      onBlock: isOwner
          ? null
          : () => blockUserFlow(context, ref,
              targetUserId: post.userId, username: post.username),
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
