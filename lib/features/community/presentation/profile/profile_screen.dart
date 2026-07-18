import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../core/widgets/fm_segmented.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../models/personal_record.dart';
import '../../../../models/workout.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../../../providers/personal_records_hall_providers.dart';
import '../../../../providers/unit_system_provider.dart';
import '../../../../providers/workout_providers.dart';
import '../../data/follow_repository.dart';
import '../../data/post_repository.dart';
import '../../domain/firestore_user.dart';
import '../../domain/post.dart';
import '../feed/post_moderation.dart';
import '../feed/widgets/post_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _tab = 0; // 0 Posts, 1 Workouts, 2 PRs

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwnProfile = currentUserId == widget.userId;
    final userAsync = ref.watch(userByIdProvider(widget.userId));

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        middle: userAsync.whenOrNull(
          data: (user) => Text(
            // Usernames are user content — Inter, never uppercased.
            user?.username ?? '',
            style: TextStyle(
              fontFamily: 'Inter',
              fontVariations: const [FontVariation('wght', 600)],
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: colors.text,
            ),
          ),
        ),
        trailing: isOwnProfile
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text(
                  'Edit',
                  style: FieldManual.body(fontSize: 16, color: colors.accent)
                      .copyWith(
                    fontVariations: const [FontVariation('wght', 600)],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => context.push('/profile/edit'),
              )
            : null,
        backgroundColor: colors.background.withValues(alpha: 0.82),
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: userAsync.when(
        loading: () => const _ProfileShimmer(),
        error: (e, _) => Center(
          child: Text(
            'Could not load profile.',
            style: FieldManual.body(color: colors.textSecondary),
          ),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Text(
                'User not found.',
                style: FieldManual.body(color: colors.textSecondary),
              ),
            );
          }

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _ProfileHeader(
                    user: user,
                    isOwnProfile: isOwnProfile,
                    currentUserId: currentUserId,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _ProfileTabs(
                    selected: _tab,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _tab = v);
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 4, bottom: 32),
                  sliver: _tabSliver(isOwnProfile),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tabSliver(bool isOwnProfile) {
    switch (_tab) {
      case 0:
        return _PostsTab(userId: widget.userId);
      case 1:
        return _WorkoutsTab(userId: widget.userId, isOwnProfile: isOwnProfile);
      case 2:
      default:
        return _PRsTab(userId: widget.userId, isOwnProfile: isOwnProfile);
    }
  }
}

// ─── Profile header ──────────────────────────────────────────────────────────

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({
    required this.user,
    required this.isOwnProfile,
    required this.currentUserId,
  });

  final FirestoreUser user;
  final bool isOwnProfile;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          _Avatar(
            url: user.profilePictureUrl,
            username: user.username,
            colors: colors,
          ),
          const SizedBox(height: 14),
          Text(
            // Usernames are user content — Inter (may be w600+), never
            // uppercased, never the display face.
            '@${user.username}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontVariations: const [FontVariation('wght', 700)],
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: colors.text,
            ),
          ),
          if (user.displayName.isNotEmpty &&
              user.displayName != user.username) ...[
            const SizedBox(height: 2),
            Text(
              user.displayName,
              style: FieldManual.body(
                fontSize: 15,
                color: colors.textSecondary,
              ),
            ),
          ],
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              user.bio,
              textAlign: TextAlign.center,
              style: FieldManual.body(fontSize: 15, color: colors.text),
            ),
          ],
          const SizedBox(height: 20),
          _StatsRow(user: user, colors: colors),
          const SizedBox(height: 16),
          if (isOwnProfile)
            _EditProfileButton(colors: colors)
          else if (currentUserId != null)
            _FollowButton(
              currentUserId: currentUserId!,
              targetUserId: user.userId,
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.username,
    required this.colors,
  });

  final String? url;
  final String username;
  final Palette colors;

  @override
  Widget build(BuildContext context) {
    final fallbackLetter =
        (username.isNotEmpty ? username[0] : '?').toUpperCase();

    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: colors.surfaceElevated,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url!,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            placeholder: (_, _) => const CupertinoActivityIndicator(),
            errorWidget: (_, _, _) => _fallback(fallbackLetter),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 40,
      backgroundColor: colors.accent,
      child: _fallback(fallbackLetter, onAccent: true),
    );
  }

  Widget _fallback(String letter, {bool onAccent = false}) => Text(
        letter,
        style: TextStyle(
          fontFamily: 'Inter',
          fontVariations: const [FontVariation('wght', 600)],
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: onAccent ? colors.onAccent : colors.textSecondary,
        ),
      );
}

// ─── Stats row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user, required this.colors});

  final FirestoreUser user;
  final Palette colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCell(
          count: user.workoutsCount,
          label: 'Posts',
          colors: colors,
        ),
        _divider(),
        _StatCell(
          count: user.followersCount,
          label: 'Followers',
          colors: colors,
          onTap: () => context.push('/profile/${user.userId}/followers'),
        ),
        _divider(),
        _StatCell(
          count: user.followingCount,
          label: 'Following',
          colors: colors,
          onTap: () => context.push('/profile/${user.userId}/following'),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 36, color: colors.border);
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.count,
    required this.label,
    required this.colors,
    this.onTap,
  });

  final int count;
  final String label;
  final Palette colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Stat readout: mono figure over a mono eyebrow (Instrument Panel Rule).
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: FieldManual.readout(fontSize: 18, color: colors.text),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: FieldManual.label(
            fontSize: 11,
            color: colors.textSecondary,
          ),
        ),
      ],
    );

    return Expanded(
      child: onTap != null
          ? Semantics(
              button: true,
              label: '$count $label',
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: child,
                ),
              ),
            )
          : child,
    );
  }
}

// ─── Edit profile button ─────────────────────────────────────────────────────

class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton({required this.colors});

  final Palette colors;

  @override
  Widget build(BuildContext context) {
    // Secondary button: transparent, hairline border, sharp 4px corners.
    // Spoken label stays sentence case; uppercase is visual only.
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        label: 'Edit profile',
        button: true,
        child: ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('/profile/edit');
            },
            child: Container(
              alignment: Alignment.center,
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                'EDIT PROFILE',
                style: _buttonLabelStyle(colors.text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Field Manual button label: condensed uppercase Oswald.
TextStyle _buttonLabelStyle(Color color, {double fontSize = 15}) => TextStyle(
      fontFamily: 'Oswald',
      fontVariations: const [FontVariation('wght', 600)],
      fontWeight: FontWeight.w600,
      fontSize: fontSize,
      letterSpacing: 0.6,
      color: color,
    );

// ─── Follow / Unfollow button ────────────────────────────────────────────────

class _FollowButton extends ConsumerStatefulWidget {
  const _FollowButton({
    required this.currentUserId,
    required this.targetUserId,
  });

  final String currentUserId;
  final String targetUserId;

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool _isLoading = false;

  Future<void> _toggle(bool currentlyFollowing) async {
    HapticFeedback.selectionClick();
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(followRepositoryProvider);
      if (currentlyFollowing) {
        await repo.unfollow(widget.currentUserId, widget.targetUserId);
      } else {
        await repo.follow(widget.currentUserId, widget.targetUserId);
      }
      ref.invalidate(isFollowingProvider(widget.targetUserId));
      ref.invalidate(userByIdProvider(widget.targetUserId));
      ref.invalidate(followingIdsProvider);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final followAsync = ref.watch(isFollowingProvider(widget.targetUserId));
    final isFollowing = followAsync.valueOrNull ?? false;

    // Follow = primary accent fill; Following = quiet raised surface. The
    // follow state is exposed to assistive tech, not carried by colour alone.
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        button: true,
        toggled: isFollowing,
        label: isFollowing
            ? 'Following. Double tap to unfollow.'
            : 'Follow',
        child: ExcludeSemantics(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: isFollowing ? colors.surfaceElevated : colors.accent,
            borderRadius: BorderRadius.circular(4),
            onPressed: _isLoading ? null : () => _toggle(isFollowing),
            child: _isLoading
                ? CupertinoActivityIndicator(
                    color: isFollowing ? colors.accent : colors.onAccent,
                  )
                : Text(
                    isFollowing ? 'FOLLOWING' : 'FOLLOW',
                    style: _buttonLabelStyle(
                      isFollowing ? colors.text : colors.onAccent,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Tab bar ────────────────────────────────────────────────────────────────

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  static const _segments = <(int, String)>[
    (0, 'Posts'),
    (1, 'Workouts'),
    (2, 'PRs'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FmSegmented<int>(
        segments: _segments,
        selected: selected,
        onChanged: onChanged,
      ),
    );
  }
}

// ─── Posts tab ──────────────────────────────────────────────────────────────

class _PostsTab extends ConsumerWidget {
  const _PostsTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final postsAsync = ref.watch(userPostsProvider(userId));

    return postsAsync.when(
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(
              2,
              (_) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: ShimmerCard(height: 180),
              ),
            ),
          ),
        ),
      ),
      error: (_, _) => SliverToBoxAdapter(
        child: _TabEmpty(
          icon: CupertinoIcons.exclamationmark_triangle,
          title: 'Could not load posts',
          subtitle: 'Pull to try again.',
          colors: colors,
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return SliverToBoxAdapter(
            child: _TabEmpty(
              icon: CupertinoIcons.square_list,
              title: 'No posts yet',
              subtitle: 'Shared workouts will show up here.',
              colors: colors,
            ),
          );
        }
        return SliverList.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) => _PostCardWrapper(
            post: posts[index],
            currentUserId: ref.read(currentUserIdProvider),
          ),
        );
      },
    );
  }
}

// ─── Workouts tab ───────────────────────────────────────────────────────────

class _WorkoutsTab extends ConsumerWidget {
  const _WorkoutsTab({required this.userId, required this.isOwnProfile});

  final String userId;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    if (isOwnProfile) {
      final workoutsAsync = ref.watch(allWorkoutsProvider);
      return workoutsAsync.when(
        loading: () => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: const ShimmerList(itemCount: 4),
          ),
        ),
        error: (_, _) => SliverToBoxAdapter(
          child: _TabEmpty(
            icon: CupertinoIcons.exclamationmark_triangle,
            title: 'Could not load workouts',
            subtitle: '',
            colors: colors,
          ),
        ),
        data: (workouts) {
          if (workouts.isEmpty) {
            return SliverToBoxAdapter(
              child: _TabEmpty(
                icon: CupertinoIcons.flame,
                title: 'No workouts yet',
                subtitle: 'Log your first workout to see it here.',
                colors: colors,
                ctaLabel: 'Start Workout',
                // `go`, not `push`: this profile route is standalone (outside
                // the shell), so push-ing the shell-nested /workouts/new from
                // here clones a second StatefulShellRoute and black-screens.
                // See exercise_detail_screen.dart:355 for the same fix.
                onCta: () => context.go('/workouts/new'),
              ),
            );
          }
          return SliverList.builder(
            itemCount: workouts.length,
            itemBuilder: (context, index) =>
                _WorkoutTile(workout: workouts[index]),
          );
        },
      );
    }

    // Other users: posts carry their shared workouts — direct them there.
    return SliverToBoxAdapter(
      child: _TabEmpty(
        icon: CupertinoIcons.lock,
        title: 'Private workouts',
        subtitle:
            'Workout history is only visible on the user\'s own profile. Check the Posts tab for shared workouts.',
        colors: colors,
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  const _WorkoutTile({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final exerciseCount = workout.exercises.length;
    final duration = workout.durationMinutes ?? 0;

    return Semantics(
      button: true,
      label: '${workout.title}, ${formatRelativeTime(workout.date)}, '
          '$exerciseCount exercises, $duration minutes',
      child: GestureDetector(
        // KNOWN LATENT BUG — documented for a follow-up, intentionally NOT
        // fixed in this PR. This profile route is standalone (outside the
        // shell), so push-ing the shell-nested /workouts/:id clones a second
        // StatefulShellRoute → duplicate _shellStateKey GlobalKey → black
        // screen in release (same crash class as the coach "Start now" bug).
        // A plain `go` would fix the crash but regress back-nav (back would
        // land on the Workouts tab instead of returning to this profile).
        // Proper fix: host /workouts/:id on a ROOT-navigator route
        // (parentNavigatorKey: rootNavigatorKey) so it stacks on top of this
        // standalone route and preserves back-to-profile.
        onTap: () => context.push('/workouts/${workout.id}'),
        child: ExcludeSemantics(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(CupertinoIcons.flame_fill,
                      color: colors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // Workout titles are user content — Inter.
                        workout.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontVariations: const [FontVariation('wght', 600)],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        // Timestamp + counts are readouts — quiet mono.
                        '${formatRelativeTime(workout.date)} · '
                        '$exerciseCount ex · ${duration}m',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontVariations: const [FontVariation('wght', 500)],
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                          letterSpacing: 0.2,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(CupertinoIcons.chevron_right,
                    size: 16, color: colors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── PRs tab ────────────────────────────────────────────────────────────────

class _PRsTab extends ConsumerWidget {
  const _PRsTab({required this.userId, required this.isOwnProfile});

  final String userId;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    if (!isOwnProfile) {
      return SliverToBoxAdapter(
        child: _TabEmpty(
          icon: CupertinoIcons.lock,
          title: 'Private PRs',
          subtitle: 'Personal records are only visible on your own profile.',
          colors: colors,
        ),
      );
    }

    final prsAsync = ref.watch(allPersonalRecordsProvider);
    return prsAsync.when(
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: const ShimmerList(itemCount: 4),
        ),
      ),
      error: (_, _) => SliverToBoxAdapter(
        child: _TabEmpty(
          icon: CupertinoIcons.exclamationmark_triangle,
          title: 'Could not load PRs',
          subtitle: '',
          colors: colors,
        ),
      ),
      data: (prs) {
        if (prs.isEmpty) {
          return SliverToBoxAdapter(
            child: _TabEmpty(
              icon: CupertinoIcons.rosette,
              title: 'No PRs yet',
              subtitle: 'Complete a set heavier than your best to set one.',
              colors: colors,
              ctaLabel: 'Log Workout',
              // `go`, not `push` — same reason as the Workouts-tab CTA above:
              // a cross-shell push of /workouts/new from this standalone
              // profile route clones a second StatefulShellRoute → black screen.
              onCta: () => context.go('/workouts/new'),
            ),
          );
        }
        return SliverList.builder(
          itemCount: prs.length,
          itemBuilder: (context, index) => _PRTile(pr: prs[index]),
        );
      },
    );
  }
}

class _PRTile extends ConsumerWidget {
  const _PRTile({required this.pr});

  final PersonalRecord pr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final units = ref.watch(unitSystemProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              // PRs are earned brass, not a warning.
              color: colors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(CupertinoIcons.rosette,
                color: colors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pr.exerciseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontVariations: const [FontVariation('wght', 600)],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // Timestamps set in quiet mono.
                  formatRelativeTime(pr.dateAchieved),
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontVariations: const [FontVariation('wght', 500)],
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    letterSpacing: 0.2,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            // A best lift is a trained-against number — mono readout.
            UnitConverter.formatWeight(pr.weightKg, units),
            style: FieldManual.readout(fontSize: 16, color: colors.accent),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────

class _TabEmpty extends StatelessWidget {
  const _TabEmpty({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    this.ctaLabel,
    this.onCta,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Palette colors;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    // Drill-sergeant eyebrow + sentence-case guidance (DESIGN.md).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        children: [
          Icon(icon, size: 42, color: colors.textSecondary),
          const SizedBox(height: 12),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: FieldManual.label(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: FieldManual.body(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
          ],
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: 16),
            Semantics(
              label: ctaLabel,
              button: true,
              child: ExcludeSemantics(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onCta!();
                  },
                  child: Container(
                    constraints:
                        const BoxConstraints(minHeight: 44, minWidth: 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ctaLabel!.toUpperCase(),
                      style: _buttonLabelStyle(colors.onAccent, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Profile shimmer ───────────────────────────────────────────────────────

class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const ShimmerBox(width: 80, height: 80, borderRadius: 40),
            const SizedBox(height: 12),
            const ShimmerBox(width: 140, height: 18),
            const SizedBox(height: 8),
            const ShimmerBox(width: 220, height: 14),
            const SizedBox(height: 24),
            Row(
              children: const [
                Expanded(child: ShimmerBox(width: 60, height: 36)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBox(width: 60, height: 36)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBox(width: 60, height: 36)),
              ],
            ),
            const SizedBox(height: 24),
            const ShimmerList(itemCount: 3),
          ],
        ),
      ),
    );
  }
}

// ─── Post card wrapper ─────────────────────────────────────────────────────

class _PostCardWrapper extends ConsumerWidget {
  const _PostCardWrapper({
    required this.post,
    required this.currentUserId,
  });

  final Post post;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedAsync = ref.watch(isPostLikedProvider(post.postId));
    final isLiked = likedAsync.valueOrNull ?? false;
    final isOwner = currentUserId == post.userId;

    return PostCard(
      post: post,
      isLiked: isLiked,
      isOwner: isOwner,
      onLike: () async {
        if (currentUserId == null) return;
        await ref
            .read(postRepositoryProvider)
            .toggleLike(post.postId, currentUserId!);
        ref.invalidate(isPostLikedProvider(post.postId));
        ref.invalidate(userPostsProvider(post.userId));
      },
      onComment: () {
        context.push('/community/post/${post.postId}');
      },
      onTapUser: () {
        context.push('/profile/${post.userId}');
      },
      onReport: isOwner
          ? null
          : () => reportPostFlow(context, ref,
              postId: post.postId, reportedUserId: post.userId),
      onBlock: isOwner
          ? null
          : () => blockUserFlow(context, ref,
              targetUserId: post.userId, username: post.username),
      onDelete: isOwner
          ? () async {
              final confirmed = await showCupertinoDialog<bool>(
                context: context,
                builder: (ctx) => CupertinoAlertDialog(
                  title: const Text('Delete post?'),
                  content: const Text(
                      'This will permanently remove the post for everyone.'),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref
                    .read(postRepositoryProvider)
                    .deletePost(post.postId);
                ref.invalidate(userPostsProvider(post.userId));
              }
            }
          : null,
    );
  }
}
