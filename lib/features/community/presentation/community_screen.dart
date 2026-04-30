import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/community_providers.dart';
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NotificationsBell(palette: palette),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                HapticFeedback.selectionClick();
                context.push('/community/create-post');
              },
              child: Icon(
                CupertinoIcons.square_pencil,
                color: palette.accent,
              ),
            ),
          ],
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
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            softWrap: false,
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

class _NotificationsBell extends ConsumerWidget {
  const _NotificationsBell({required this.palette});

  final Palette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadNotificationCountProvider);
    final unread = unreadAsync.valueOrNull ?? 0;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        HapticFeedback.selectionClick();
        context.push('/community/notifications');
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(CupertinoIcons.bell, color: palette.accent),
          if (unread > 0)
            Positioned(
              top: -3,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16),
                decoration: BoxDecoration(
                  color: palette.destructive,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.surface, width: 1),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
