import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar, Colors, Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../data/follow_repository.dart';
import '../../domain/firestore_user.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Search Users',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: colors.text,
          ),
        ),
        backgroundColor: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // --- Search field ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: CupertinoSearchTextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                placeholder: 'Search by username',
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  color: colors.text,
                ),
                backgroundColor: colors.surfaceElevated,
              ),
            ),

            // --- Results ---
            Expanded(
              child: _query.length < 2
                  ? _EmptyState(colors: colors)
                  : _SearchResults(query: _query),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors});
  final Palette colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.search,
            size: 48,
            color: colors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'Search for users by username',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 15,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Results list ────────────────────────────────────────────────────────────

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final resultsAsync = ref.watch(userSearchResultsProvider(query));

    return resultsAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (_, __) => Center(
        child: Text(
          'Something went wrong.',
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            color: colors.textSecondary,
          ),
        ),
      ),
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Text(
              'No users found.',
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 15,
                color: colors.textSecondary,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: users.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: colors.border,
          ),
          itemBuilder: (context, index) => _UserRow(user: users[index]),
        );
      },
    );
  }
}

// ─── Single user row ─────────────────────────────────────────────────────────

class _UserRow extends ConsumerWidget {
  const _UserRow({required this.user});
  final FirestoreUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwnProfile = currentUserId == user.userId;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/profile/${user.userId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // --- Avatar ---
            _buildAvatar(colors),
            const SizedBox(width: 12),

            // --- Name column ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${user.username}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: colors.text,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.displayName.isNotEmpty &&
                      user.displayName != user.username)
                    Text(
                      user.displayName,
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    '${user.followersCount} followers',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // --- Follow button ---
            if (!isOwnProfile) _RowFollowButton(user: user),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Palette colors) {
    final url = user.profilePictureUrl;
    final letter =
        (user.username.isNotEmpty ? user.username[0] : '?').toUpperCase();

    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: colors.surfaceElevated,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            placeholder: (_, __) => const CupertinoActivityIndicator(),
            errorWidget: (_, __, ___) => Text(
              letter,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: colors.surfaceElevated,
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

// ─── Inline follow / unfollow button for each row ────────────────────────────

class _RowFollowButton extends ConsumerStatefulWidget {
  const _RowFollowButton({required this.user});
  final FirestoreUser user;

  @override
  ConsumerState<_RowFollowButton> createState() => _RowFollowButtonState();
}

class _RowFollowButtonState extends ConsumerState<_RowFollowButton> {
  bool _isLoading = false;

  Future<void> _toggle(bool currentlyFollowing) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(followRepositoryProvider);
      if (currentlyFollowing) {
        await repo.unfollow(currentUserId, widget.user.userId);
      } else {
        await repo.follow(currentUserId, widget.user.userId);
      }
      ref.invalidate(isFollowingProvider(widget.user.userId));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final followAsync =
        ref.watch(isFollowingProvider(widget.user.userId));
    final isFollowing = followAsync.valueOrNull ?? false;

    if (_isLoading) {
      return const SizedBox(
        width: 80,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return SizedBox(
      width: 96,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 6),
        minSize: 0,
        color: isFollowing ? null : colors.accent,
        borderRadius: BorderRadius.circular(8),
        onPressed: () => _toggle(isFollowing),
        child: Container(
          alignment: Alignment.center,
          decoration: isFollowing
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.accent),
                )
              : null,
          padding: isFollowing
              ? const EdgeInsets.symmetric(vertical: 6)
              : null,
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isFollowing ? colors.accent : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
