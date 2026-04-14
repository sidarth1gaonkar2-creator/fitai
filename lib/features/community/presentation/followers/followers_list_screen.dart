import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../data/follow_repository.dart';

class FollowersListScreen extends ConsumerWidget {
  const FollowersListScreen({
    super.key,
    required this.userId,
    this.isFollowers = true,
  });

  final String userId;
  final bool isFollowers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final title = isFollowers ? 'Followers' : 'Following';

    // Pick the right list of user IDs based on mode.
    final idsAsync = isFollowers
        ? ref.watch(followerIdsProvider(userId))
        : ref.watch(followingIdsProvider);

    return CupertinoPageScaffold(
      backgroundColor: palette.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: palette.surface,
        border: Border(bottom: BorderSide(color: palette.border)),
        middle: Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: palette.text,
          ),
        ),
      ),
      child: SafeArea(
        child: idsAsync.when(
          data: (idsRaw) {
            final ids = idsRaw is Set<String>
                ? idsRaw.toList()
                : (idsRaw as List<String>);
            if (ids.isEmpty) {
              return Center(
                child: Text(
                  isFollowers
                      ? 'No followers yet'
                      : 'Not following anyone yet',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 15,
                    color: palette.textSecondary,
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: ids.length,
              itemBuilder: (context, index) {
                return _UserTile(
                  userId: ids[index],
                  palette: palette,
                );
              },
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (_, __) => Center(
            child: Text(
              'Failed to load list.',
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 15,
                color: palette.destructive,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({
    required this.userId,
    required this.palette,
  });

  final String userId;
  final Palette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(userId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final isFollowingAsync = ref.watch(isFollowingProvider(userId));

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        final isFollowing = isFollowingAsync.valueOrNull ?? false;
        final isSelf = currentUserId == userId;

        return GestureDetector(
          onTap: () => context.push('/profile/$userId'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: palette.border, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                _buildAvatar(user.profilePictureUrl, user.username),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: palette.text,
                        ),
                      ),
                      if (user.displayName.isNotEmpty &&
                          user.displayName != user.username)
                        Text(
                          user.displayName,
                          style: TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontSize: 13,
                            color: palette.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isSelf)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    minSize: 0,
                    color: isFollowing
                        ? palette.surfaceElevated
                        : palette.accent,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: () async {
                      if (currentUserId == null) return;
                      final followRepo =
                          ref.read(followRepositoryProvider);
                      if (isFollowing) {
                        await followRepo.unfollow(currentUserId, userId);
                      } else {
                        await followRepo.follow(currentUserId, userId);
                      }
                      ref.invalidate(isFollowingProvider(userId));
                      ref.invalidate(followingIdsProvider);
                      ref.invalidate(followerIdsProvider(userId));
                    },
                    child: Text(
                      isFollowing ? 'Unfollow' : 'Follow',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isFollowing
                            ? palette.text
                            : CupertinoColors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: CupertinoActivityIndicator(),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAvatar(String? profilePic, String username) {
    if (profilePic != null && profilePic.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: CachedNetworkImageProvider(profilePic),
        backgroundColor: palette.surfaceElevated,
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: palette.accent,
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: CupertinoColors.white,
        ),
      ),
    );
  }
}
