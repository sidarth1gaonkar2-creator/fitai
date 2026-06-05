import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar, Colors, Divider;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../../ranks/domain/military_ranks.dart';
import '../../../ranks/presentation/widgets/rank_badge.dart';
import '../../data/follow_repository.dart';
import '../../domain/firestore_user.dart';
import '../profile/mini_profile_sheet.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  /// Selected rank ordinal filter, or null for "All ranks".
  int? _rankFilter;

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
          'Search Soldiers',
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

            // ── Rank filter chips ──
            _RankFilterRow(
              selected: _rankFilter,
              colors: colors,
              onSelect: (idx) {
                HapticFeedback.selectionClick();
                setState(() => _rankFilter = idx);
              },
            ),
            const SizedBox(height: 4),

            Expanded(
              child: _Results(query: _query, rankFilter: _rankFilter),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Rank filter chip row ────────────────────────────────────────────────────

class _RankFilterRow extends StatelessWidget {
  const _RankFilterRow({
    required this.selected,
    required this.colors,
    required this.onSelect,
  });

  final int? selected;
  final Palette colors;
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(label: 'All', active: selected == null, onTap: () => onSelect(null)),
          for (final rank in MilitaryRank.values)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _chip(
                label: rank.abbreviation,
                color: rank.color,
                active: selected == rank.index,
                onTap: () => onSelect(rank.index),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool active,
    required VoidCallback onTap,
    Color? color,
  }) {
    final tint = color ?? colors.accent;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? tint : colors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: active ? tint : colors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: active ? CupertinoColors.white : colors.text,
          ),
        ),
      ),
    );
  }
}

// ─── Results ─────────────────────────────────────────────────────────────────

class _Results extends ConsumerWidget {
  const _Results({required this.query, required this.rankFilter});

  final String query;
  final int? rankFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    // Browse-by-rank with no text query.
    if (query.length < 2) {
      if (rankFilter == null) return _EmptyPrompt(colors: colors);
      final byRank = ref.watch(usersByRankProvider(rankFilter!));
      return _list(byRank, colors, rankFilter);
    }

    // Text search, optionally narrowed to the selected rank.
    final results = ref.watch(userSearchResultsProvider(query));
    return _list(results, colors, rankFilter);
  }

  Widget _list(
    AsyncValue<List<FirestoreUser>> async,
    Palette colors,
    int? rankFilter,
  ) {
    return async.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (_, _) => Center(
        child: Text(
          'Something went wrong.',
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            color: colors.textSecondary,
          ),
        ),
      ),
      data: (all) {
        final users = rankFilter == null
            ? all
            : all.where((u) => u.rankIndex == rankFilter).toList();
        if (users.isEmpty) {
          return Center(
            child: Text(
              'No soldiers found.',
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
          separatorBuilder: (_, _) => Divider(height: 1, color: colors.border),
          itemBuilder: (context, index) => _UserRow(user: users[index]),
        );
      },
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt({required this.colors});
  final Palette colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.search, size: 48, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Search by username, or tap a rank to see who holds it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 15,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
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
    final rank = user.rankIndex == null ? null : rankFromIndex(user.rankIndex!);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showMiniProfileSheet(context, user.userId),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _buildAvatar(colors),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '@${user.username}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: colors.text,
                          ),
                        ),
                      ),
                      if (rank != null) ...[
                        const SizedBox(width: 6),
                        RankInsignia(rank: rank, size: 15),
                        const SizedBox(width: 3),
                        Text(
                          rank.abbreviation,
                          style: TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: rank.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (rank != null)
                    Text(
                      rank.displayName,
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    )
                  else if (user.displayName.isNotEmpty &&
                      user.displayName != user.username)
                    Text(
                      user.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
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
            placeholder: (_, _) => const CupertinoActivityIndicator(),
            errorWidget: (_, _, _) => Text(
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
    final followAsync = ref.watch(isFollowingProvider(widget.user.userId));
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
        color: isFollowing ? null : colors.accent,
        borderRadius: BorderRadius.circular(8),
        onPressed: () => _toggle(isFollowing),
        minimumSize: const Size(0, 0),
        child: Container(
          alignment: Alignment.center,
          decoration: isFollowing
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.accent),
                )
              : null,
          padding:
              isFollowing ? const EdgeInsets.symmetric(vertical: 6) : null,
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
