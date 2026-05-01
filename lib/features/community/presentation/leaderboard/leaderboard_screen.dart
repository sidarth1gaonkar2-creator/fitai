import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../data/leaderboard_repository.dart';
import '../../domain/leaderboard_entry.dart';
import 'widgets/leaderboard_tile.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int _selectedTab = 0; // 0=streak, 1=volume, 2=workouts
  bool _isGlobal = true;

  static const _tabLabels = <int, String>{
    0: 'Streak \u{1F525}',
    1: 'Volume \u{1F4AA}',
    2: 'Workouts \u{1F4CA}',
  };

  static const _fieldNames = ['currentStreak', 'totalVolume', 'totalWorkouts'];

  String get _currentField => _fieldNames[_selectedTab];

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final userId = ref.watch(currentUserIdProvider);

    return Container(
      color: palette.background,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ---- Metric tabs ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _selectedTab,
                  thumbColor: palette.accent,
                  backgroundColor: palette.surface,
                  children: _tabLabels.map(
                    (key, label) => MapEntry(
                      key,
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedTab == key
                                ? CupertinoColors.white
                                : palette.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                  onValueChanged: (value) {
                    if (value != null) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTab = value);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ---- Global / Friends toggle ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 200,
                child: CupertinoSlidingSegmentedControl<bool>(
                  groupValue: _isGlobal,
                  backgroundColor: palette.surface,
                  children: {
                    true: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Text(
                        'Global',
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 13,
                          color: palette.text,
                        ),
                      ),
                    ),
                    false: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Text(
                        'Friends',
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 13,
                          color: palette.text,
                        ),
                      ),
                    ),
                  },
                  onValueChanged: (value) {
                    if (value != null) {
                      HapticFeedback.selectionClick();
                      setState(() => _isGlobal = value);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ---- Leaderboard list ----
            Expanded(child: _buildList(palette, userId)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(Palette palette, String? userId) {
    if (!_isGlobal) {
      return _buildFriendsList(palette, userId);
    }

    final asyncEntries = ref.watch(leaderboardByFieldProvider(_currentField));

    return asyncEntries.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (err, _) => Center(
        child: Text(
          'Something went wrong.',
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            fontSize: 14,
            color: palette.textSecondary,
          ),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return _buildEmptyState(palette);
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) => LeaderboardTile(
            rank: index + 1,
            entry: entries[index],
            metricField: _currentField,
            isCurrentUser: entries[index].userId == userId,
          ),
        );
      },
    );
  }

  Widget _buildFriendsList(Palette palette, String? userId) {
    final asyncFriendIds = ref.watch(followingIdsProvider);

    return asyncFriendIds.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (_, _) => Center(
        child: Text(
          'Something went wrong.',
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            fontSize: 14,
            color: palette.textSecondary,
          ),
        ),
      ),
      data: (friendIds) {
        if (userId != null) {
          friendIds = {...friendIds, userId};
        }

        final repo = ref.watch(leaderboardRepositoryProvider);
        return FutureBuilder<List<LeaderboardEntry>>(
          future: repo.getFriendsLeaderboard(friendIds, _currentField),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            }
            final entries = snapshot.data ?? [];
            if (entries.isEmpty) {
              return _buildEmptyState(palette);
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => LeaderboardTile(
                rank: index + 1,
                entry: entries[index],
                metricField: _currentField,
                isCurrentUser: entries[index].userId == userId,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(Palette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Complete a workout to appear on the leaderboard',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            fontSize: 15,
            color: palette.textSecondary,
          ),
        ),
      ),
    );
  }
}
