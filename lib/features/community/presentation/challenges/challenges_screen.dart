import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/community_providers.dart';
import '../../domain/challenge.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  int _selectedTab = 0; // 0=Browse, 1=My Challenges

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return Container(
      color: palette.background,
      child: Column(
        children: [
          const SizedBox(height: 16),

          // ---- Tab toggle + Create button ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _selectedTab,
                    thumbColor: palette.accent,
                    backgroundColor: palette.surface,
                    children: {
                      0: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          'Browse',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedTab == 0
                                ? CupertinoColors.white
                                : palette.text,
                          ),
                        ),
                      ),
                      1: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          'My Challenges',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedTab == 1
                                ? CupertinoColors.white
                                : palette.text,
                          ),
                        ),
                      ),
                    },
                    onValueChanged: (value) {
                      if (value != null) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTab = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => context.push('/community/challenge/create'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Create',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ---- List ----
          Expanded(
            child: _selectedTab == 0
                ? _buildBrowseTab(palette)
                : _buildMyTab(palette),
          ),
        ],
      ),
    );
  }

  // ─── Browse tab ──────────────────────────────────────────────────────────

  Widget _buildBrowseTab(Palette palette) {
    final asyncChallenges = ref.watch(publicChallengesProvider);

    return asyncChallenges.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (_, __) => _buildError(palette),
      data: (challenges) {
        if (challenges.isEmpty) {
          return _buildEmpty(palette, 'No public challenges yet.');
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: challenges.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) =>
              _buildChallengeCard(palette, challenges[index]),
        );
      },
    );
  }

  // ─── My Challenges tab ───────────────────────────────────────────────────

  Widget _buildMyTab(Palette palette) {
    final asyncChallenges = ref.watch(myChallengesProvider);

    return asyncChallenges.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (_, __) => _buildError(palette),
      data: (challenges) {
        if (challenges.isEmpty) {
          return _buildEmpty(palette, 'You haven\'t joined any challenges yet.');
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: challenges.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) =>
              _buildChallengeCard(palette, challenges[index]),
        );
      },
    );
  }

  // ─── Shared card ─────────────────────────────────────────────────────────

  Widget _buildChallengeCard(Palette palette, Challenge challenge) {
    final daysRemaining = challenge.endDate != null
        ? challenge.endDate!.difference(DateTime.now()).inDays.clamp(0, 9999)
        : 0;
    final totalDays = challenge.durationDays;
    final elapsed = totalDays - daysRemaining;
    final progress = totalDays > 0 ? (elapsed / totalDays).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => context.push('/community/challenge/${challenge.challengeId}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + type badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    challenge.title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: palette.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: palette.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    challenge.typeLabel,
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.accent,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Participant count + days remaining
            Row(
              children: [
                Icon(
                  CupertinoIcons.person_2_fill,
                  size: 14,
                  color: palette.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${challenge.participantCount}',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 13,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  CupertinoIcons.clock,
                  size: 14,
                  color: palette.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$daysRemaining days left',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 13,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Progress bar (time-based)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: palette.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _buildEmpty(Palette palette, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
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

  Widget _buildError(Palette palette) {
    return Center(
      child: Text(
        'Something went wrong.',
        style: TextStyle(
          fontFamily: 'LeagueSpartan',
          fontSize: 14,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}

/// Needed for LinearProgressIndicator from Material.
class LinearProgressIndicator extends StatelessWidget {
  const LinearProgressIndicator({
    super.key,
    required this.value,
    required this.backgroundColor,
    required this.valueColor,
  });

  final double value;
  final Color backgroundColor;
  final Animation<Color> valueColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          children: [
            Container(
              width: width,
              height: 6,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Container(
              width: width * value.clamp(0.0, 1.0),
              height: 6,
              decoration: BoxDecoration(
                color: (valueColor as AlwaysStoppedAnimation<Color>).value,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        );
      },
    );
  }
}
