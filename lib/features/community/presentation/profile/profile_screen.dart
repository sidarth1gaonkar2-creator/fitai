import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar, Colors;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../data/follow_repository.dart';
import '../feed/widgets/post_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwnProfile = currentUserId == userId;
    final userAsync = ref.watch(userByIdProvider(userId));

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        middle: userAsync.whenOrNull(
          data: (user) => Text(
            user?.username ?? '',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
        ),
        trailing: isOwnProfile
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text(
                  'Edit',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    color: colors.accent,
                    fontSize: 16,
                  ),
                ),
                onPressed: () => context.push('/profile/edit'),
              )
            : null,
        backgroundColor: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border, width: 0.5),
        ),
      ),
      child: userAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Could not load profile.',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              color: colors.textSecondary,
            ),
          ),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Text(
                'User not found.',
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  color: colors.textSecondary,
                ),
              ),
            );
          }

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _ProfileHeader(
                    user: user,
                    isOwnProfile: isOwnProfile,
                    currentUserId: currentUserId,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text(
                      'Posts',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: colors.text,
                      ),
                    ),
                  ),
                ),
                _PostsList(userId: userId),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Profile header ──────────────────────────────────────────────────────────

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({
    required this.user,
    required this.isOwnProfile,
    required this.currentUserId,
  });

  final dynamic user; // FirestoreUser
  final bool isOwnProfile;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // --- Avatar ---
          _buildAvatar(colors),
          const SizedBox(height: 14),

          // --- Username ---
          Text(
            '@${user.username}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: colors.text,
            ),
          ),
          if (user.displayName.isNotEmpty &&
              user.displayName != user.username) ...[
            const SizedBox(height: 2),
            Text(
              user.displayName,
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 15,
                color: colors.textSecondary,
              ),
            ),
          ],

          // --- Bio ---
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              user.bio,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 15,
                color: colors.text,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // --- Stats row ---
          _StatsRow(
            user: user,
            colors: colors,
          ),

          // --- Follow button ---
          if (!isOwnProfile && currentUserId != null) ...[
            const SizedBox(height: 16),
            _FollowButton(
              currentUserId: currentUserId!,
              targetUserId: user.userId,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(Palette colors) {
    final url = user.profilePictureUrl;
    final fallbackLetter =
        (user.username.isNotEmpty ? user.username[0] : '?').toUpperCase();

    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: colors.surfaceElevated,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            placeholder: (_, __) => const CupertinoActivityIndicator(),
            errorWidget: (_, __, ___) => Text(
              fallbackLetter,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 36,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 50,
      backgroundColor: colors.surfaceElevated,
      child: Text(
        fallbackLetter,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

// ─── Stats row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user, required this.colors});

  final dynamic user; // FirestoreUser
  final Palette colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCell(
          count: user.workoutsCount,
          label: 'Workouts',
          colors: colors,
        ),
        _divider(),
        _StatCell(
          count: user.followersCount,
          label: 'Followers',
          colors: colors,
          onTap: () =>
              context.push('/profile/${user.userId}/followers'),
        ),
        _divider(),
        _StatCell(
          count: user.followingCount,
          label: 'Following',
          colors: colors,
          onTap: () =>
              context.push('/profile/${user.userId}/following'),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 36,
      color: colors.border,
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.count,
    required this.label,
    required this.colors,
    this.onTap,
  });

  final int count;
  final String label;
  final Palette colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            fontSize: 13,
            color: colors.textSecondary,
          ),
        ),
      ],
    );

    return Expanded(
      child: onTap != null
          ? GestureDetector(onTap: onTap, child: child)
          : child,
    );
  }
}

// ─── Follow / Unfollow button ────────────────────────────────────────────────

class _FollowButton extends ConsumerStatefulWidget {
  const _FollowButton({
    required this.currentUserId,
    required this.targetUserId,
  });

  final String currentUserId;
  final String targetUserId;

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool _isLoading = false;

  Future<void> _toggle(bool currentlyFollowing) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(followRepositoryProvider);
      if (currentlyFollowing) {
        await repo.unfollow(widget.currentUserId, widget.targetUserId);
      } else {
        await repo.follow(widget.currentUserId, widget.targetUserId);
      }
      ref.invalidate(isFollowingProvider(widget.targetUserId));
      ref.invalidate(userByIdProvider(widget.targetUserId));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final followAsync = ref.watch(isFollowingProvider(widget.targetUserId));
    final isFollowing = followAsync.valueOrNull ?? false;

    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: isFollowing ? null : colors.accent,
        borderRadius: BorderRadius.circular(12),
        onPressed:
            _isLoading ? null : () => _toggle(isFollowing),
        child: _isLoading
            ? CupertinoActivityIndicator(
                color: isFollowing ? colors.accent : Colors.white,
              )
            : Container(
                decoration: isFollowing
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.accent),
                      )
                    : null,
                padding: isFollowing
                    ? const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10)
                    : null,
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isFollowing ? colors.accent : Colors.white,
                  ),
                ),
              ),
      ),
    );
  }
}

// ─── Posts list ──────────────────────────────────────────────────────────────

class _PostsList extends ConsumerWidget {
  const _PostsList({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final postsAsync = ref.watch(userPostsProvider(userId));

    return postsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: CupertinoActivityIndicator(),
        ),
      ),
      error: (_, __) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Center(
            child: Text(
              'Could not load posts.',
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'No posts yet.',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 15,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }

        return SliverList.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) => PostCard(post: posts[index]),
        );
      },
    );
  }
}
