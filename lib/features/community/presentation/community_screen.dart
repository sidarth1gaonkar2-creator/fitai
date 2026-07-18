import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/field_manual.dart';
import '../../../core/widgets/fm_segmented.dart';
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

  static const _segments = <(int, String)>[
    (0, 'Feed'),
    (1, 'Leaderboard'),
    (2, 'Challenges'),
    (3, 'Search'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return CupertinoPageScaffold(
      backgroundColor: palette.background,
      navigationBar: CupertinoNavigationBar(
        // Field Manual chrome: ink ground over a hairline (DESIGN.md §Nav).
        backgroundColor: palette.background.withValues(alpha: 0.82),
        border: Border(bottom: BorderSide(color: palette.border)),
        middle: Text('COMMUNITY', style: FieldManual.title(color: palette.text)),
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
                semanticLabel: 'New post',
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
              child: FmSegmented<int>(
                segments: _segments,
                selected: _selectedSegment,
                onChanged: (value) =>
                    setState(() => _selectedSegment = value),
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
          Icon(
            CupertinoIcons.bell,
            color: palette.accent,
            semanticLabel:
                unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
          ),
          if (unread > 0)
            Positioned(
              top: -3,
              right: -6,
              // Unread count wears the live accent, not alert red — red is
              // for consequences, not decoration (the One Voice Rule).
              child: ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: BoxDecoration(
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.surface, width: 1),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    textAlign: TextAlign.center,
                    style: FieldManual.readout(
                      fontSize: 11,
                      color: palette.onAccent,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
