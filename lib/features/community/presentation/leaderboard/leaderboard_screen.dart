import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/widgets/fm_segmented.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../data/leaderboard_repository.dart';
import '../../domain/leaderboard_entry.dart';
import 'widgets/leaderboard_tile.dart';

/// One selectable leaderboard segment — the overall composite board plus a
/// board per muscle group, each sorted by that segment's rank score.
class _Segment {
  const _Segment(this.label, this.field);
  final String label;
  final String field;
}

const _segments = <_Segment>[
  _Segment('Overall', LeaderboardSegments.overall),
  _Segment('Chest', LeaderboardSegments.chest),
  _Segment('Back', LeaderboardSegments.back),
  _Segment('Legs', LeaderboardSegments.legs),
  _Segment('Shoulders', LeaderboardSegments.shoulders),
  _Segment('Arms', LeaderboardSegments.arms),
];

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int _segmentIndex = 0;
  bool _isGlobal = true;

  String get _field => _segments[_segmentIndex].field;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final userId = ref.watch(currentUserIdProvider);

    return Container(
      color: palette.background,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ── Segment chips ──
            SizedBox(
              // ≥44pt touch targets; scales with Dynamic Type.
              height: MediaQuery.textScalerOf(context).scale(44),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _segments.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = index == _segmentIndex;
                  return _SegmentChip(
                    label: _segments[index].label,
                    selected: selected,
                    palette: palette,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _segmentIndex = index);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ── Global / Friends toggle ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 220,
                child: FmSegmented<bool>(
                  segments: const [(true, 'Global'), (false, 'Friends')],
                  selected: _isGlobal,
                  onChanged: (value) => setState(() => _isGlobal = value),
                ),
              ),
            ),

            const SizedBox(height: 12),

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

    final asyncEntries = ref.watch(leaderboardByFieldProvider(_field));

    return asyncEntries.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (_, _) => _buildError(palette),
      data: (entries) {
        if (entries.isEmpty) return _buildEmptyState(palette);
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) => LeaderboardTile(
            position: index + 1,
            entry: entries[index],
            field: _field,
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
      error: (_, _) => _buildError(palette),
      data: (friendIds) {
        final ids = userId != null ? {...friendIds, userId} : friendIds;
        final repo = ref.watch(leaderboardRepositoryProvider);
        return FutureBuilder<List<LeaderboardEntry>>(
          future: repo.getFriendsLeaderboard(ids, _field),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            }
            final entries = snapshot.data ?? [];
            if (entries.isEmpty) return _buildEmptyState(palette);
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => LeaderboardTile(
                position: index + 1,
                entry: entries[index],
                field: _field,
                isCurrentUser: entries[index].userId == userId,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildError(Palette palette) => Center(
        child: Text(
          'Something went wrong.',
          style: FieldManual.body(
            fontSize: 14,
            color: palette.textSecondary,
          ),
        ),
      );

  Widget _buildEmptyState(Palette palette) {
    // Drill-sergeant eyebrow + sentence-case guidance (DESIGN.md).
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BOARD UNCLAIMED',
              textAlign: TextAlign.center,
              style: FieldManual.label(
                fontSize: 12,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log a rankable lift to claim your spot on the board, soldier.',
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
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Palette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Spoken label stays sentence case; uppercase is visual only.
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: selected ? palette.accent : palette.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: selected ? palette.accent : palette.border,
              ),
            ),
            child: Text(
              label.toUpperCase(),
              style: FieldManual.label(
                fontSize: 11,
                color: selected ? palette.onAccent : palette.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
