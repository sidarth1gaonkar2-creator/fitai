import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/utils/logger.dart';
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
        backgroundColor: palette.background.withValues(alpha: 0.82),
        border: Border(bottom: BorderSide(color: palette.border)),
        middle: Text(
          title.toUpperCase(),
          style: FieldManual.title(color: palette.text),
        ),
      ),
      child: SafeArea(
        child: idsAsync.when(
          data: (idsRaw) {
            final ids = idsRaw is Set<String>
                ? idsRaw.toList()
                : (idsRaw as List<String>);
            if (ids.isEmpty) {
              // Drill-sergeant eyebrow + sentence-case guidance (DESIGN.md).
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isFollowers
                            ? 'NO FOLLOWERS YET'
                            : 'NOT FOLLOWING ANYONE',
                        textAlign: TextAlign.center,
                        style: FieldManual.label(
                          fontSize: 12,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isFollowers
                            ? 'Soldiers who follow this account will report here.'
                            : 'Search for soldiers and follow them to build your unit.',
                        textAlign: TextAlign.center,
                        style: FieldManual.body(
                          fontSize: 14,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
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
          error: (_, _) => Center(
            child: Text(
              'Failed to load list.',
              style: FieldManual.body(
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

        // The row is one profile button; the nested follow button keeps its
        // own semantics node.
        return Semantics(
          button: true,
          label: "View ${user.username}'s profile",
          child: GestureDetector(
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
                ExcludeSemantics(
                  child: _buildAvatar(user.profilePictureUrl, user.username),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // Usernames are user content — Inter, never
                          // uppercased.
                          user.username,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontVariations: const [
                              FontVariation('wght', 600),
                            ],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: palette.text,
                          ),
                        ),
                        if (user.displayName.isNotEmpty &&
                            user.displayName != user.username)
                          Text(
                            user.displayName,
                            style: FieldManual.body(
                              fontSize: 13,
                              color: palette.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (!isSelf)
                  // Follow state is exposed to assistive tech, not carried
                  // by colour alone. Spoken label stays sentence case.
                  Semantics(
                    button: true,
                    toggled: isFollowing,
                    label: isFollowing
                        ? 'Following. Double tap to unfollow.'
                        : 'Follow',
                    child: ExcludeSemantics(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        color: isFollowing
                            ? palette.surfaceElevated
                            : palette.accent,
                        borderRadius: BorderRadius.circular(4),
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
                        // ≥44pt touch target.
                        minimumSize: const Size(44, 44),
                        child: Text(
                          isFollowing ? 'UNFOLLOW' : 'FOLLOW',
                          style: TextStyle(
                            fontFamily: 'Oswald',
                            fontVariations: const [
                              FontVariation('wght', 600),
                            ],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            letterSpacing: 0.6,
                            color: isFollowing
                                ? palette.text
                                : palette.onAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: CupertinoActivityIndicator(),
      ),
      error: (e, st) {
        AppLogger.error(
          'Followers list: user row load failed (userId=$userId)',
          error: e,
          stack: st,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(CupertinoIcons.exclamationmark_circle,
                  size: 16, color: palette.destructive),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Could not load this user.',
                  style: FieldManual.body(
                    fontSize: 13,
                    color: palette.textSecondary,
                  ),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(44, 44),
                onPressed: () => ref.invalidate(userByIdProvider(userId)),
                child: const Text('Retry',
                    style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        );
      },
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
        style: TextStyle(
          fontFamily: 'Inter',
          fontVariations: const [FontVariation('wght', 700)],
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: palette.onAccent,
        ),
      ),
    );
  }
}
