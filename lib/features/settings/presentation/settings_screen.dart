import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../models/enums.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/community_providers.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/drill_sergeant_providers.dart';
import '../../../providers/health_providers.dart';
import '../../../providers/isar_provider.dart';
import '../../../providers/nutrition_providers.dart';
import '../../../providers/progress_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../themes/providers/theme_providers.dart';
import '../../../providers/supplement_providers.dart';
import '../../../providers/unit_system_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../providers/workout_providers.dart';
import '../../../providers/firestore_provider.dart';
import '../../../services/health_service.dart';
import '../../../services/notification_service.dart';
import '../../../utils/seed_community.dart';
import '../../../utils/seed_nutrition.dart';
import '../../../utils/seed_workouts.dart';
import '../../community/data/leaderboard_repository.dart';
import '../../ranks/domain/military_ranks.dart';
import '../../ranks/presentation/widgets/rank_badge.dart';
import '../../ranks/providers/rank_providers.dart';
import '../../tutorial/providers/tutorial_providers.dart';

/// Accounts allowed to see the Developer section (seed buttons). Email-based
/// so it works in every build mode — TestFlight and the public App Store
/// alike — without a `kDebugMode` guard. The Apple review account and all
/// regular users fall outside this list and never see the section.
const _adminEmails = [
  'sidarthgaonkar@gmail.com',
  'sidarth1gaonkar2@gmail.com',
];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final currentEmail = ref.watch(firebaseAuthProvider).currentUser?.email;
    final isAdmin = _adminEmails.contains(currentEmail?.toLowerCase());
    final themeMode = ref.watch(themeModeProvider);
    final units = ref.watch(unitSystemProvider);
    final textTheme = Theme.of(context).textTheme;
    final palette = AppColors.of(context);
    final overallRank =
        ref.watch(overallRankProvider).valueOrNull ?? MilitaryRank.private_e1;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: CupertinoNavigationBar(
        middle: const Text('Settings'),
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
      ),
      body: ListView(
        children: [
          // --- Profile header ---
          profileAsync.when(
            data: (profile) {
              if (profile == null) return const SizedBox.shrink();
              return _ProfileHeader(
                name: profile.name,
                goal: profile.goal,
                tdee: profile.tdee,
                onTap: () => context.push('/settings/edit-profile'),
              );
            },
            loading: () => const _ProfileHeaderShimmer(),
            error: (_, _) => ErrorCard(
              message: 'Could not load profile.',
              onRetry: () => ref.invalidate(userProfileProvider),
            ),
          ),

          // --- Settings list ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appearance section
                _SectionLabel(label: 'Appearance', textTheme: textTheme),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: Builder(builder: (context) {
                    final activeTheme = ref.watch(activeThemeProvider);
                    final coins = ref.watch(coinBalanceProvider);
                    return CupertinoListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              activeTheme.darkBackground,
                              activeTheme.accent,
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: activeTheme.accentLight
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.paintbrush,
                          color: CupertinoColors.white,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        'Theme Store',
                        style: textTheme.bodyLarge?.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${activeTheme.name} · $coins coins',
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        color: palette.text,
                        size: 18,
                      ),
                      onTap: () => context.push('/theme-store'),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        _SettingsIconBadge(
                          icon: Icons.dark_mode_outlined,
                          color: palette.accent,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dark Mode',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                themeMode == ThemeMode.system
                                    ? 'System default'
                                    : themeMode == ThemeMode.dark
                                        ? 'On'
                                        : 'Off',
                                style: textTheme.bodySmall?.copyWith(
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoSwitch(
                          value: themeMode == ThemeMode.dark,
                          activeTrackColor: palette.accent,
                          onChanged: (value) {
                            HapticFeedback.selectionClick();
                            ref
                                .read(themeModeProvider.notifier)
                                .toggle(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Units section
                _SectionLabel(label: 'Units', textTheme: textTheme),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        _SettingsIconBadge(
                          icon: CupertinoIcons.arrow_right_arrow_left,
                          color: palette.accent,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Units',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                units == UnitSystem.metric
                                    ? 'kg / cm'
                                    : 'lbs / ft',
                                style: textTheme.bodySmall?.copyWith(
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          child: CupertinoSegmentedControl<UnitSystem>(
                            groupValue: units,
                            onValueChanged: (value) {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(unitSystemProvider.notifier)
                                  .setUnit(value);
                            },
                            children: const {
                              UnitSystem.metric: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('Metric',
                                    style: TextStyle(fontSize: 13)),
                              ),
                              UnitSystem.imperial: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('Imperial',
                                    style: TextStyle(fontSize: 13)),
                              ),
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Notifications section
                _SectionLabel(label: 'Notifications', textTheme: textTheme),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: CupertinoListTile(
                    leading: _SettingsIconBadge(
                      icon: CupertinoIcons.bell,
                      color: palette.warning,
                    ),
                    title: Text(
                      'Notifications',
                      style: textTheme.bodyLarge?.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Workout, meal, water, and streak reminders',
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      color: palette.text,
                      size: 18,
                    ),
                    onTap: () => context.push('/settings/notifications'),
                  ),
                ),
                const SizedBox(height: 24),

                // Motivation Style section (Toxic Motivator / Drill Sergeant)
                _SectionLabel(label: 'Motivation Style', textTheme: textTheme),
                const SizedBox(height: 8),
                const _DrillSergeantSection(),
                const SizedBox(height: 24),

                // Apple Health section (iOS only, and only when the native
                // pre-flight in HealthService.canUseHealthKit() says we're
                // safe to talk to HealthKit at all).
                if (Platform.isIOS &&
                    (ref.watch(healthAvailableProvider).valueOrNull ??
                        false)) ...[
                  _SectionLabel(label: 'Apple Health', textTheme: textTheme),
                  const SizedBox(height: 8),
                  const _AppleHealthSection(),
                  const SizedBox(height: 24),
                ],

                // Supplements section
                _SectionLabel(label: 'Supplements', textTheme: textTheme),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: CupertinoListTile(
                    leading: _SettingsIconBadge(
                      icon: CupertinoIcons.capsule,
                      color: palette.accent,
                    ),
                    title: Text(
                      'Manage Supplements',
                      style: textTheme.bodyLarge?.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Add, remove, or configure supplements',
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      color: palette.text,
                      size: 18,
                    ),
                    onTap: () => context.push('/supplements'),
                  ),
                ),
                const SizedBox(height: 24),

                // My Ranks section
                _SectionLabel(label: 'Ranks', textTheme: textTheme),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: CupertinoListTile(
                    leading: _SettingsIconBadge(
                      icon: CupertinoIcons.rosette,
                      color: palette.accent,
                    ),
                    title: Text(
                      'My Ranks',
                      style: textTheme.bodyLarge?.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Overall, muscle-group, and per-exercise ranks',
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      color: palette.text,
                      size: 18,
                    ),
                    onTap: () => context.push('/ranks'),
                  ),
                ),
                const SizedBox(height: 24),

                // Account section
                _SectionLabel(label: 'Account', textTheme: textTheme),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: CupertinoListTile(
                    leading: _SettingsIconBadge(
                      icon: Icons.logout,
                      color: palette.destructive,
                    ),
                    title: Text(
                      'Sign Out',
                      style: textTheme.bodyLarge?.copyWith(
                        color: palette.destructive,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      color: palette.text,
                      size: 18,
                    ),
                    onTap: () => _confirmSignOut(context, ref),
                  ),
                ),
                const SizedBox(height: 24),

                // Data section
                _SectionLabel(label: 'Data', textTheme: textTheme),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: CupertinoListTile(
                    leading: _SettingsIconBadge(
                      icon: Icons.delete_forever_outlined,
                      color: palette.destructive,
                    ),
                    title: Text(
                      'Reset All Data',
                      style: textTheme.bodyLarge?.copyWith(
                        color: palette.destructive,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Delete all workouts, nutrition, and chat history',
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.destructive.withValues(alpha: 0.7),
                      ),
                    ),
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      color: palette.text,
                      size: 18,
                    ),
                    onTap: () => _confirmReset(context, ref),
                  ),
                ),
                const SizedBox(height: 24),

                // Help section
                _SectionLabel(label: 'Help', textTheme: textTheme),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: CupertinoListTile(
                    leading: _SettingsIconBadge(
                      icon: CupertinoIcons.question_circle,
                      color: palette.accent,
                    ),
                    title: Text(
                      'App Tour',
                      style: textTheme.bodyLarge?.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Replay the feature walkthrough',
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      color: palette.text,
                      size: 18,
                    ),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      // Replay path: bypass the `tutorial_completed` pref
                      // check entirely (that's first-launch gating only).
                      // Call start() synchronously while this widget is
                      // still mounted — `ref` would be invalid by the time
                      // a Future.delayed fires, because going to /dashboard
                      // pops Settings and tears down its WidgetRef.
                      //
                      // start() itself calls onNavigate('/dashboard') for
                      // step 1, so we don't issue our own context.go. The
                      // overlay host's retry loop waits for the dashboard
                      // to mount before measuring the calorie ring.
                      ref.read(tutorialControllerProvider).start();
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Developer section — gated behind the admin email allowlist
                // (see [_adminEmails]). Visible to admin accounts in every
                // build mode (TestFlight and release); never shown to the
                // Apple review account or regular users.
                if (isAdmin) ...[
                  _SectionLabel(label: 'Developer', textTheme: textTheme),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    child: CupertinoListTile(
                      leading: _SettingsIconBadge(
                        icon: CupertinoIcons.wand_stars,
                        color: palette.accent,
                      ),
                      title: Text(
                        'Seed Community',
                        style: textTheme.bodyLarge?.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Write 10 demo posts + reactions + comments to Firestore',
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        color: palette.text,
                        size: 18,
                      ),
                      onTap: () => _runSeed(context, ref),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    child: CupertinoListTile(
                      leading: _SettingsIconBadge(
                        icon: CupertinoIcons.chart_bar_alt_fill,
                        color: palette.accent,
                      ),
                      title: Text(
                        'Seed Leaderboard',
                        style: textTheme.bodyLarge?.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Write 10 weekly leaderboard entries — you land 4th',
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        color: palette.text,
                        size: 18,
                      ),
                      onTap: () => _runSeedLeaderboard(context, ref),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    child: CupertinoListTile(
                      leading: _SettingsIconBadge(
                        icon: CupertinoIcons.flag_fill,
                        color: palette.accent,
                      ),
                      title: Text(
                        'Seed Challenges',
                        style: textTheme.bodyLarge?.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Write 3 active challenges + bot participants; you join 2',
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        color: palette.text,
                        size: 18,
                      ),
                      onTap: () => _runSeedChallenges(context, ref),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    child: CupertinoListTile(
                      leading: _SettingsIconBadge(
                        icon: Icons.fitness_center,
                        color: palette.accent,
                      ),
                      title: Text(
                        'Seed Workouts',
                        style: textTheme.bodyLarge?.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Write 12 PPL sessions + PRs across the last 30 days',
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        color: palette.text,
                        size: 18,
                      ),
                      onTap: () => _runSeedWorkouts(context, ref),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    child: CupertinoListTile(
                      leading: _SettingsIconBadge(
                        icon: CupertinoIcons.flame,
                        color: palette.accent,
                      ),
                      title: Text(
                        'Seed Nutrition',
                        style: textTheme.bodyLarge?.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '7 days of meals, completed days, and supplements',
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        color: palette.text,
                        size: 18,
                      ),
                      onTap: () => _runSeedNutrition(context, ref),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    child: CupertinoListTile(
                      leading: _SettingsIconBadge(
                        icon: CupertinoIcons.heart_circle,
                        color: palette.destructive,
                      ),
                      title: Text(
                        'HealthKit Debug',
                        style: textTheme.bodyLarge?.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Compare every active-calorie read path on-device',
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        color: palette.text,
                        size: 18,
                      ),
                      onTap: () => _runHealthKitDebug(context, ref),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // About section
                _SectionLabel(label: 'About', textTheme: textTheme),
                const SizedBox(height: 8),
                // Current overall rank with full insignia — taps through to the
                // dedicated Ranks screen.
                _SettingsCard(
                  child: CupertinoListTile(
                    onTap: () => context.push('/ranks'),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: overallRank.color.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: RankInsignia(rank: overallRank, size: 26),
                    ),
                    title: Text(
                      overallRank.displayName,
                      style: textTheme.bodyLarge?.copyWith(
                        color: overallRank.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Overall rank · ${overallRank.abbreviation} (E${overallRank.tier})',
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      size: 18,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: CupertinoListTile(
                    leading: _SettingsIconBadge(
                      icon: CupertinoIcons.info,
                      color: palette.accent,
                    ),
                    title: Text(
                      'DrillFit',
                      style: textTheme.bodyLarge?.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Version 1.0.0',
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
          'Local data on this device will be cleared. You will need to sign '
          'in again to continue.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      HapticFeedback.mediumImpact();
      // Clear local data before sign-out so the next account that signs in
      // on this device doesn't inherit this user's profile/workouts/etc.
      // The router uses userProfileProvider (Isar) to gate onboarding —
      // leaving stale data here causes a new account to skip onboarding
      // and land in profile-setup with the previous user's stats.
      final isar = ref.read(isarProvider);
      await isar.writeTxn(() => isar.clear());
      ref.invalidate(userProfileProvider);
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) context.go('/welcome');
    }
  }

  /// Debug-only — kicks off the community-feed seeder and surfaces the
  /// result (or any error) in a CupertinoAlertDialog. Bails out gracefully
  /// if the user isn't signed in (we need their UID to wire up follow rows).
  Future<void> _runSeed(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      await _showInfoDialog(
        context,
        title: 'Sign in first',
        message:
            'The seeder needs a current Firebase user to wire up follow '
            'rows. Sign in and try again.',
      );
      return;
    }
    final firestore = ref.read(firestoreProvider);
    final progress = showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CupertinoAlertDialog(
        title: Text('Seeding…'),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: CupertinoActivityIndicator(),
        ),
      ),
    );
    try {
      final result = await seedCommunityFeed(
        firestore: firestore,
        currentUserId: userId,
      );
      // Dismiss the progress dialog.
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!context.mounted) return;
      await _showInfoDialog(
        context,
        title: 'Community seeded',
        message:
            'Added ${result.posts} posts from ${result.users} users, '
            '${result.reactions} reactions, and ${result.comments} comments. '
            'Pull-to-refresh the feed to see them.',
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!context.mounted) return;
      await _showInfoDialog(
        context,
        title: 'Seeding failed',
        message: '$e',
      );
    }
    // Silence the unawaited-future lint — the dialog is awaited above via
    // the explicit Navigator.pop call.
    await progress;
  }

  /// Debug-only — populates the leaderboard collection with 10 entries
  /// (current user at rank 4) for App Store screenshots.
  Future<void> _runSeedLeaderboard(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      await _showInfoDialog(
        context,
        title: 'Sign in first',
        message: 'Need a Firebase user to seed.',
      );
      return;
    }
    final firestore = ref.read(firestoreProvider);
    final username = ref.read(firestoreUserProvider).valueOrNull?.username;
    final progress = showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CupertinoAlertDialog(
        title: Text('Seeding…'),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: CupertinoActivityIndicator(),
        ),
      ),
    );
    try {
      final result = await seedLeaderboard(
        firestore: firestore,
        currentUserId: userId,
        currentUsername: username ?? 'you',
      );
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!context.mounted) return;
      await _showInfoDialog(
        context,
        title: 'Leaderboard seeded',
        message:
            'Wrote ${result.entries} entries. Pull-to-refresh the leaderboard.',
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!context.mounted) return;
      await _showInfoDialog(
        context,
        title: 'Seeding failed',
        message: '$e',
      );
    }
    await progress;
  }

  /// Debug-only — seeds 3 active challenges with bot participants and
  /// enrolls the current user in all three at mid-range progress.
  Future<void> _runSeedChallenges(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      await _showInfoDialog(
        context,
        title: 'Sign in first',
        message: 'Need a Firebase user to seed.',
      );
      return;
    }
    final firestore = ref.read(firestoreProvider);
    final username = ref.read(firestoreUserProvider).valueOrNull?.username;
    final progress = showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CupertinoAlertDialog(
        title: Text('Seeding…'),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: CupertinoActivityIndicator(),
        ),
      ),
    );
    try {
      final result = await seedChallenges(
        firestore: firestore,
        currentUserId: userId,
        currentUsername: username ?? 'you',
      );
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!context.mounted) return;
      await _showInfoDialog(
        context,
        title: 'Challenges seeded',
        message:
            'Added ${result.challenges} challenges with ${result.participants} participants. '
            'You\'re enrolled in all three.',
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!context.mounted) return;
      await _showInfoDialog(
        context,
        title: 'Seeding failed',
        message: '$e',
      );
    }
    await progress;
  }

  /// Debug-only — populates the CURRENT user's Isar workout history with
  /// 12 PPL sessions spread across the last 30 days, plus matching PRs.
  /// Best-effort Firestore sync for workoutsCount + leaderboard entry.
  Future<void> _runSeedWorkouts(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    final userId = ref.read(currentUserIdProvider);
    final firestore = ref.read(firestoreProvider);
    final isar = ref.read(isarProvider);
    final username = ref.read(firestoreUserProvider).valueOrNull?.username;
    final leaderboard = ref.read(leaderboardRepositoryProvider);
    final progress = showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CupertinoAlertDialog(
        title: Text('Seeding workouts…'),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: CupertinoActivityIndicator(),
        ),
      ),
    );
    try {
      final result = await seedWorkoutHistory(
        isar: isar,
        firestore: firestore,
        currentUserId: userId,
        currentUsername: username,
        leaderboardRepository: leaderboard,
      );
      // Refresh anything that derives from Isar workouts so the
      // Dashboard / Progress / PR Hall pick up the seeded data on the
      // next frame instead of waiting for the next provider lifecycle.
      ref.invalidate(allWorkoutsProvider);
      ref.invalidate(workoutDatesProvider);
      ref.invalidate(todayWorkoutProvider);
      ref.invalidate(streakProvider);
      ref.invalidate(personalRecordsProvider);
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!context.mounted) return;
      await _showInfoDialog(
        context,
        title: 'Workouts seeded',
        message:
            'Wrote ${result.workouts} workouts (${result.totalSets} sets) '
            'and ${result.prs} personal records. Pull-to-refresh the '
            'Progress screen.',
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!context.mounted) return;
      await _showInfoDialog(
        context,
        title: 'Seeding failed',
        message: '$e',
      );
    }
    await progress;
  }

  /// Debug-only — populates the current user's Isar nutrition log with 7 days
  /// of realistic meals, marks five days completed, ensures a default
  /// supplement stack exists + logs it as taken, and tops up today's water for
  /// App Store screenshots.
  Future<void> _runSeedNutrition(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    final isar = ref.read(isarProvider);
    // Stamp CompletedDay rows with the user's real macro targets when we have
    // them; the seeder falls back to training defaults otherwise.
    final targets = await ref.read(dailyTargetsProvider.future);
    if (!context.mounted) return;
    final progress = showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CupertinoAlertDialog(
        title: Text('Seeding nutrition…'),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: CupertinoActivityIndicator(),
        ),
      ),
    );
    try {
      final result = await seedNutritionHistory(
        isar: isar,
        calorieTarget: targets?.calories ?? 2400,
        proteinTarget: targets?.protein ?? 180,
        carbsTarget: targets?.carbs ?? 250,
        fatTarget: targets?.fat ?? 70,
      );
      // Water is in-memory only (resets per session) — top up today's glasses
      // so the dashboard's hydration ring isn't empty in screenshots.
      ref.read(waterIntakeProvider.notifier).state = 8;
      // Refresh everything that derives from the seeded nutrition/supplement
      // data so the Dashboard / Nutrition / Progress screens update next frame.
      ref.invalidate(todayNutritionProvider);
      ref.invalidate(todayMealsProvider);
      ref.invalidate(todayMicronutrientsProvider);
      ref.invalidate(todayCompletedDayProvider);
      ref.invalidate(streakProvider);
      ref.invalidate(nutritionTrendsProvider);
      ref.invalidate(activeSupplementsProvider);
      ref.invalidate(allSupplementsProvider);
      ref.invalidate(todaySupplementLogsProvider);
      ref.invalidate(supplementChecklistProvider);
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!context.mounted) return;
      await _showInfoDialog(
        context,
        title: 'Nutrition seeded',
        message:
            'Wrote ${result.foodEntries} food entries across ${result.days} '
            'days (${result.meals} meals, ${result.completedDays} completed). '
            'Logged ${result.supplements} supplements over the week. '
            'Pull-to-refresh the Nutrition screen.',
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!context.mounted) return;
      await _showInfoDialog(
        context,
        title: 'Seeding failed',
        message: '$e',
      );
    }
    await progress;
  }

  /// Admin-only — runs every active-energy read path side by side and shows
  /// the results on-screen. We can't read TestFlight console logs, so this is
  /// how we see which HealthKit path returns data and which returns 0.
  Future<void> _runHealthKitDebug(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    final service = ref.read(healthServiceProvider);
    final progress = showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CupertinoAlertDialog(
        title: Text('Reading HealthKit…'),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: CupertinoActivityIndicator(),
        ),
      ),
    );
    Map<String, Object?> d;
    try {
      d = await service.collectDiagnostics();
    } catch (e) {
      d = {'error': '$e'};
    }
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (!context.mounted) return;

    String fmtNum(Object? v) {
      if (v == null) return 'null';
      if (v is double) return v.toStringAsFixed(1);
      return '$v';
    }

    final message = d.containsKey('error')
        ? 'Diagnostics failed: ${d['error']}'
        : 'Can use HealthKit: ${d['canUseHealthKit']}\n'
            'Steps (plugin): ${fmtNum(d['steps'])}\n'
            'Active — native HKStatistics: ${fmtNum(d['nativeActive'])} kcal\n'
            'Active — plugin stats: ${fmtNum(d['pluginStatsActive'])} kcal\n'
            'Active — plugin raw: ${fmtNum(d['pluginRawActive'])} kcal\n'
            'Move goal: ${fmtNum(d['moveGoal'])} kcal\n'
            'Auth (share-only): ${d['authStatus']}\n\n'
            'A value of -1 means that path threw. null native means the '
            'bridge returned nothing. Read auth is hidden by iOS, so '
            '"notDetermined" here is expected even when reads work.';

    await _showInfoDialog(
      context,
      title: 'HealthKit Debug',
      message: message,
    );
    await progress;
  }

  Future<void> _showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'This will permanently delete all your workouts, nutrition logs, '
          'weight entries, chat history, and profile. This cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      HapticFeedback.heavyImpact();
      final isar = ref.read(isarProvider);
      await isar.writeTxn(() async {
        await isar.clear();
      });
      ref.invalidate(userProfileProvider);
      if (context.mounted) context.go('/onboarding');
    }
  }
}

// ─── Profile header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.goal,
    required this.tdee,
    required this.onTap,
  });

  final String name;
  final Goal goal;
  final double tdee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        color: AppColors.of(context).accent,
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${goal.label} · ${tdee.toInt()} kcal TDEE',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeaderShimmer extends StatelessWidget {
  const _ProfileHeaderShimmer();

  @override
  Widget build(BuildContext context) {
    return const ShimmerCard(height: 96);
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.textTheme});

  final String label;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: textTheme.labelLarge?.copyWith(
        color: AppColors.of(context).accent,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─── Settings card wrapper ────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );
  }
}

// ─── Apple Health section ─────────────────────────────────────────────────────

class _AppleHealthSection extends ConsumerWidget {
  const _AppleHealthSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final prefs = ref.watch(healthPrefsProvider);
    final availableAsync = ref.watch(healthAvailableProvider);
    final available = availableAsync.valueOrNull ?? false;

    return _SettingsCard(
      child: Column(
        children: [
          // Connect toggle
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _SettingsIconBadge(
                  icon: Icons.favorite,
                  color: palette.destructive,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect Apple Health',
                        style: textTheme.bodyLarge?.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        !available
                            ? 'Not available on this device'
                            : prefs.connected
                                ? 'Connected'
                                : 'Not connected',
                        style: textTheme.bodySmall?.copyWith(
                          color: prefs.connected
                              ? palette.success
                              : palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: prefs.connected,
                  activeTrackColor: palette.accent,
                  onChanged: !available
                      ? null
                      : (value) async {
                          HapticFeedback.selectionClick();
                          if (value) {
                            bool granted = false;
                            try {
                              granted = await ref
                                  .read(healthServiceProvider)
                                  .requestPermissions();
                            } catch (e) {
                              if (context.mounted) {
                                _showHealthError(context);
                              }
                              return;
                            }
                            final notifier =
                                ref.read(healthPrefsProvider.notifier);
                            await notifier.setConnected(granted);
                            if (granted) {
                              await notifier.markAuthorizedAt(
                                HealthService.permissionsSchemaVersion,
                              );
                            }
                            if (!context.mounted) return;
                            if (granted) {
                              ref.invalidate(dailyHealthSummaryProvider);
                              showCupertinoToast(
                                context,
                                'Apple Health connected',
                              );
                            } else {
                              showCupertinoToast(
                                context,
                                'Permission denied. Enable it in iOS '
                                'Settings → Health.',
                              );
                            }
                          } else {
                            await ref
                                .read(healthPrefsProvider.notifier)
                                .setConnected(false);
                          }
                        },
                ),
              ],
            ),
          ),
          if (prefs.connected) ...[
            _SettingsDivider(),
            _RefreshPermissionsTile(
              stale: ref.watch(healthPermissionsStaleProvider),
            ),
            _SettingsDivider(),
            _HealthSwitchTile(
              label: 'Show on Dashboard',
              subtitle: 'Burned-calorie ring overlay and activity row',
              value: prefs.showOnDashboard,
              onChanged: (v) => ref
                  .read(healthPrefsProvider.notifier)
                  .setShowOnDashboard(v),
            ),
            _SettingsDivider(),
            _HealthSwitchTile(
              label: 'Sync Workouts',
              subtitle: 'Write completed workouts to Apple Health',
              value: prefs.syncWorkouts,
              onChanged: (v) =>
                  ref.read(healthPrefsProvider.notifier).setSyncWorkouts(v),
            ),
            _SettingsDivider(),
            _HealthSwitchTile(
              label: 'Sync Nutrition',
              subtitle: 'Write daily totals when completing a day',
              value: prefs.syncNutrition,
              onChanged: (v) =>
                  ref.read(healthPrefsProvider.notifier).setSyncNutrition(v),
            ),
            _SettingsDivider(),
            _HealthSwitchTile(
              label: 'Sync Weight',
              subtitle: 'Write weight entries',
              value: prefs.syncWeight,
              onChanged: (v) =>
                  ref.read(healthPrefsProvider.notifier).setSyncWeight(v),
            ),
            _SettingsDivider(),
            _HealthSwitchTile(
              label: 'Sync Water',
              subtitle: 'Write water intake (debounced)',
              value: prefs.syncWater,
              onChanged: (v) =>
                  ref.read(healthPrefsProvider.notifier).setSyncWater(v),
            ),
          ],
        ],
      ),
    );
  }
}

void _showHealthError(BuildContext context) {
  showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: const Text('Apple Health'),
      content: const Text(
        'Unable to connect to Apple Health. Open the iOS Settings app and '
        'check Privacy → Health → DrillFit.',
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Tile inside the Apple Health section that lets the user re-run
/// `requestAuthorization` against the current full type set. When [stale] is
/// true (the app now requests more types than the user last authorized) we
/// show an inline hint and color the row in the warning palette.
class _RefreshPermissionsTile extends ConsumerWidget {
  const _RefreshPermissionsTile({required this.stale});

  final bool stale;

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    bool granted = false;
    try {
      granted =
          await ref.read(healthServiceProvider).requestPermissions();
    } catch (e) {
      if (context.mounted) _showHealthError(context);
      return;
    }
    if (granted) {
      await ref
          .read(healthPrefsProvider.notifier)
          .markAuthorizedAt(HealthService.permissionsSchemaVersion);
      ref.invalidate(dailyHealthSummaryProvider);
      ref.invalidate(weeklyStepsProvider);
      ref.invalidate(weeklyActiveCaloriesProvider);
    }
    if (!context.mounted) return;
    showCupertinoToast(
      context,
      granted
          ? 'Permissions refreshed'
          : 'Could not refresh permissions. Open iOS Settings → Health.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final color = stale ? palette.warning : palette.accent;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTap(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(CupertinoIcons.refresh, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stale
                        ? 'New permissions available'
                        : 'Refresh permissions',
                    style: textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    stale
                        ? 'Tap to grant access to newly added health stats'
                        : 'Re-prompt iOS for any new HealthKit types',
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: palette.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthSwitchTile extends StatelessWidget {
  const _HealthSwitchTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: palette.accent,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: AppColors.of(context).separator,
    );
  }
}

// ─── Icon badge ───────────────────────────────────────────────────────────────

class _SettingsIconBadge extends StatelessWidget {
  const _SettingsIconBadge({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

// ─── Drill Sergeant settings section ────────────────────────────────

class _DrillSergeantSection extends ConsumerWidget {
  const _DrillSergeantSection();

  /// Re-applies the user's current settings to the notification scheduler.
  /// Called any time the prefs change so the in-flight schedule matches what
  /// the user just toggled. Reads streak + lastWorkout from existing
  /// providers — neither requires async work in the common path.
  Future<void> _reschedule(WidgetRef ref) async {
    final prefs = ref.read(drillSergeantProvider);
    final service = NotificationService.instance;
    if (!prefs.enabled) {
      await service.cancelDrillSergeantReminders();
      await service.cancelMorningMotivation();
      return;
    }
    // Use whatever's currently in the streak/workout providers — schedule
    // is approximate; recalibrates on next app launch anyway.
    final streak = ref.read(streakProvider).valueOrNull ?? 0;
    final workouts = ref.read(allWorkoutsProvider).valueOrNull ?? const [];
    final lastWorkoutDate = workouts.isNotEmpty ? workouts.first.date : null;
    await service.scheduleDrillSergeantReminders(
      currentStreak: streak,
      lastWorkoutDate: lastWorkoutDate,
      // Rest-day awareness isn't wired to a user-facing pref yet; treat
      // every day as a workout day. When the rest-day setting lands, swap
      // the empty set for the configured value.
      restDays: const <int>{},
      intensity: prefs.intensity,
    );
    if (prefs.morningEnabled) {
      await service.scheduleMorningMotivation(
        hour: prefs.morningHour,
        minute: prefs.morningMinute,
      );
    } else {
      await service.cancelMorningMotivation();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(drillSergeantProvider);
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return _SettingsCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main toggle row
            Row(
              children: [
                _SettingsIconBadge(
                  icon: CupertinoIcons.flame_fill,
                  color: palette.destructive,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Drill Sergeant Mode',
                            style: textTheme.bodyLarge?.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('🪖', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      Text(
                        prefs.enabled
                            ? 'Active · ${prefs.intensityLabel}'
                            : 'Aggressive workout reminders. Opt-in.',
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: prefs.enabled,
                  activeTrackColor: palette.destructive,
                  onChanged: (value) async {
                    HapticFeedback.selectionClick();
                    if (value) {
                      final confirmed =
                          await _confirmEnable(context, palette) ?? false;
                      if (!confirmed) return;
                    }
                    await ref
                        .read(drillSergeantProvider.notifier)
                        .setEnabled(value);
                    await _reschedule(ref);
                  },
                ),
              ],
            ),
            // Sub-settings — only render when enabled
            if (prefs.enabled) ...[
              const SizedBox(height: 16),
              Divider(height: 1, color: palette.separator),
              const SizedBox(height: 12),
              Text(
                'Intensity',
                style: textTheme.labelLarge?.copyWith(color: palette.text),
              ),
              const SizedBox(height: 8),
              _IntensityPicker(
                intensity: prefs.intensity,
                onChanged: (v) async {
                  await ref
                      .read(drillSergeantProvider.notifier)
                      .setIntensity(v);
                  await _reschedule(ref);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Morning Motivation',
                          style: textTheme.bodyLarge?.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          prefs.morningEnabled
                              ? 'Daily at ${prefs.morningTimeLabel}'
                              : 'Wake-up pep talk',
                          style: textTheme.bodySmall?.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: prefs.morningEnabled,
                    activeTrackColor: palette.destructive,
                    onChanged: (value) async {
                      await ref
                          .read(drillSergeantProvider.notifier)
                          .setMorningEnabled(value);
                      await _reschedule(ref);
                    },
                  ),
                ],
              ),
              if (prefs.morningEnabled) ...[
                const SizedBox(height: 8),
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                  onPressed: () async {
                    final picked = await _pickTime(
                      context,
                      prefs.morningHour,
                      prefs.morningMinute,
                    );
                    if (picked == null) return;
                    await ref
                        .read(drillSergeantProvider.notifier)
                        .setMorningTime(picked.$1, picked.$2);
                    await _reschedule(ref);
                  },
                  child: Text(
                    'Change time',
                    style: TextStyle(color: palette.accent),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Opt-in confirmation. Returns true on "Bring it on".
  Future<bool?> _confirmEnable(BuildContext context, Palette palette) async {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Are you sure?'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'These notifications will NOT be gentle. You asked for this.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Nevermind'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Bring it on'),
          ),
        ],
      ),
    );
  }

  Future<(int, int)?> _pickTime(
      BuildContext context, int initialHour, int initialMinute) async {
    var pickedHour = initialHour;
    var pickedMinute = initialMinute;
    final ok = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    2024,
                    1,
                    1,
                    initialHour,
                    initialMinute,
                  ),
                  use24hFormat: false,
                  onDateTimeChanged: (dt) {
                    pickedHour = dt.hour;
                    pickedMinute = dt.minute;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) return (pickedHour, pickedMinute);
    return null;
  }
}

class _IntensityPicker extends StatelessWidget {
  const _IntensityPicker({required this.intensity, required this.onChanged});

  final int intensity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _seg('Mild Roast', 1, palette),
          _seg('Medium Roast', 2, palette),
          _seg('Full Savage', 3, palette),
        ],
      ),
    );
  }

  Widget _seg(String label, int value, Palette palette) {
    final active = intensity == value;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? palette.destructive : null,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: active ? Colors.white : palette.text,
            ),
          ),
        ),
      ),
    );
  }
}
