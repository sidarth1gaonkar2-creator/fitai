import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import 'feed/feed_screen.dart';
import 'leaderboard/leaderboard_screen.dart';
import 'challenges/challenges_screen.dart';
import 'search/user_search_screen.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  int _selectedSegment = 0;

  static const _segmentLabels = <int, String>{
    0: 'Feed',
    1: 'Leaderboard',
    2: 'Challenges',
    3: 'Search',
  };

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return CupertinoPageScaffold(
      backgroundColor: palette.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: palette.surface,
        border: Border(
          bottom: BorderSide(color: palette.border, width: 0.5),
        ),
        middle: Text(
          'Community',
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
            const SizedBox(height: 12),

            // ─── Segment control ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _selectedSegment,
                  thumbColor: palette.accent,
                  backgroundColor: palette.surface,
                  children: _segmentLabels.map(
                    (key, label) => MapEntry(
                      key,
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _selectedSegment == key
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
                      setState(() => _selectedSegment = value);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ─── Body ──────────────────────────────────────────────────
            Expanded(
              child: IndexedStack(
                index: _selectedSegment,
                children: const [
                  FeedScreen(),
                  LeaderboardScreen(),
                  ChallengesScreen(),
                  UserSearchScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
