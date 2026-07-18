import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/field_manual.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/scoped_prefs.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/fm_segmented.dart';
import '../../../core/widgets/jump_wings.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../data/motivator_messages.dart';
import '../../../models/enums.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/community_providers.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/drill_sergeant_providers.dart';
import '../../../providers/entitlement_providers.dart';
import '../../../providers/notification_providers.dart';
import '../../../providers/notification_reconciler.dart';
import '../../../providers/health_providers.dart';
import '../../../providers/isar_provider.dart';
import '../../../providers/onboarding_gate_provider.dart';
import '../../../providers/nutrition_providers.dart';
import '../../../providers/progress_providers.dart';
import '../../themes/providers/theme_providers.dart';
import '../../../providers/supplement_providers.dart';
import '../../../providers/unit_system_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../providers/workout_providers.dart';
import '../../../providers/firestore_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/health_service.dart';
import '../../../services/notification_service.dart';
import '../../../utils/seed_community.dart';
import '../../../utils/seed_nutrition.dart';
import '../../../utils/seed_workouts.dart';
import '../../community/data/leaderboard_repository.dart';
import '../../paywall/presentation/airborne_paywall.dart';
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
    final units = ref.watch(unitSystemProvider);
    final textTheme = Theme.of(context).textTheme;
    final palette = AppColors.of(context);
    final overallRank =
        ref.watch(overallRankProvider).valueOrNull ?? MilitaryRank.private_e1;
    // Airborne subscribers see their OWN current rank brass-mounted. The About
    // card is the user's own earned rank with no purchase affordance nearby —
    // guardrail-safe (same pattern as the My Ranks hero / rank strip).
    final airborne = ref.watch(airborneActiveProvider);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: CupertinoNavigationBar(
        // Field Manual nav: Oswald designation over ink, hairline rule.
        middle: Text('SETTINGS', style: FieldManual.title()),
        backgroundColor: palette.background.withValues(alpha: 0.82),
        border: Border(bottom: BorderSide(color: palette.border, width: 0.5)),
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
                _SectionLabel(label: 'Appearance'),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: Builder(builder: (context) {
                    final activeTheme = ref.watch(activeThemeProvider);
                    final coins = ref.watch(coinBalanceProvider);
                    return CupertinoListTile(
                      // Honest Accent Swap Rule swatch: ink→field ground with
                      // the equipped pack's accent. No gradient.
                      leading: Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: activeTheme.darkBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: palette.border),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: activeTheme.darkSurfaceElevated ??
                                activeTheme.darkSurface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: activeTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        'Theme Store',
                        style: textTheme.bodyLarge?.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text.rich(
                        TextSpan(
                          text: '${activeTheme.name} · ',
                          style: textTheme.bodySmall?.copyWith(
                            color: palette.textSecondary,
                          ),
                          children: [
                            // Coin count is an instrument readout — mono.
                            TextSpan(
                              text: '$coins',
                              style: FieldManual.label(
                                fontSize: 11,
                                color: palette.textSecondary,
                              ),
                            ),
                            const TextSpan(text: ' coins'),
                          ],
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
                // Light mode retired (batch #3): the Field Manual is dark by doctrine.
                // A first-class light look can return someday as a "Daylight Ops" theme
                // pack (Accent Swap Rule permitting a light chrome variant) — not as a
                // global brightness toggle.
                const SizedBox(height: 24),

                // Airborne section — subscription entry point + restore. No
                // launch nags anywhere; this row and the in-context prompts
                // (AI Coach limit, locked themes) are the only paywall doors.
                _SectionLabel(label: 'Airborne'),
                const SizedBox(height: 8),
                const _AirborneSection(),
                const SizedBox(height: 24),

                // Units section
                _SectionLabel(label: 'Units'),
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
                          width: 180,
                          child: FmSegmented<UnitSystem>(
                            segments: const [
                              (UnitSystem.metric, 'Metric'),
                              (UnitSystem.imperial, 'Imperial'),
                            ],
                            selected: units,
                            onChanged: (value) => ref
                                .read(unitSystemProvider.notifier)
                                .setUnit(value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Notifications section
                _SectionLabel(label: 'Notifications'),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: CupertinoListTile(
                    leading: _SettingsIconBadge(
                      // One accent voice — no gold/warning tint on chrome.
                      icon: CupertinoIcons.bell,
                      color: palette.accent,
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
                _SectionLabel(label: 'Motivation Style'),
                const SizedBox(height: 8),
                const _DrillSergeantSection(),
                const SizedBox(height: 24),

                // Apple Health section (iOS only, and only when the native
                // pre-flight in HealthService.canUseHealthKit() says we're
                // safe to talk to HealthKit at all).
                if (Platform.isIOS &&
                    (ref.watch(healthAvailableProvider).valueOrNull ??
                        false)) ...[
                  _SectionLabel(label: 'Apple Health'),
                  const SizedBox(height: 8),
                  const _AppleHealthSection(),
                  const SizedBox(height: 24),
                ],

                // Supplements section
                _SectionLabel(label: 'Supplements'),
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
                _SectionLabel(label: 'Ranks'),
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
                _SectionLabel(label: 'Account'),
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
                const SizedBox(height: 12),
                // Delete Account — the most severe destructive action. Given a
                // tinted card + destructive border so it reads distinctly from
                // "Reset All Data" below (which only wipes on-device data); this
                // permanently erases the account AND all data, server-side.
                Container(
                  decoration: BoxDecoration(
                    color: palette.destructive.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: palette.destructive.withValues(alpha: 0.4),
                    ),
                  ),
                  child: CupertinoListTile(
                    leading: _SettingsIconBadge(
                      icon: Icons.no_accounts,
                      color: palette.destructive,
                    ),
                    title: Text(
                      'Delete Account',
                      style: textTheme.bodyLarge?.copyWith(
                        color: palette.destructive,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Permanently delete your account and all data',
                      // Prose stays mutedBone (AA on the tint); the title, icon
                      // and border carry the destructive signal. destructive@0.7
                      // composited to 2.74:1 here — below the 4.5 floor.
                      style: textTheme.bodySmall?.copyWith(
                        color: FieldManual.mutedBone,
                      ),
                    ),
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      color: palette.text,
                      size: 18,
                    ),
                    onTap: () => _confirmDeleteAccount(context, ref),
                  ),
                ),
                const SizedBox(height: 24),

                // Data section
                _SectionLabel(label: 'Data'),
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
                        color: FieldManual.mutedBone,
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
                _SectionLabel(label: 'Help'),
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
                  _SectionLabel(label: 'Developer'),
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
                        // Dev tool, not a consequence — accent, not alert.
                        icon: CupertinoIcons.heart_circle,
                        color: palette.accent,
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
                _SectionLabel(label: 'About'),
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
                      child: RankInsignia(
                        rank: overallRank,
                        size: 26,
                        airborne: airborne,
                      ),
                    ),
                    title: Text(
                      overallRank.displayName,
                      style: textTheme.bodyLarge?.copyWith(
                        color: overallRank.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text.rich(
                      TextSpan(
                        text: 'Overall rank · ',
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                        children: [
                          // Rank abbreviation + tier are readouts — mono.
                          TextSpan(
                            text:
                                '${overallRank.abbreviation} (E${overallRank.tier})',
                            style: FieldManual.label(
                              fontSize: 11,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
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
                // Long-press the version row to open the hidden Notification
                // Diagnostics screen — the only way to inspect the local-
                // notification pipeline on a TestFlight device (no console).
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    context.push('/settings/diagnostics');
                  },
                  child: _SettingsCard(
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
                      subtitle: Semantics(
                        label: 'Version 1.0.0',
                        child: ExcludeSemantics(
                          child: Text(
                            'V1.0.0',
                            style: FieldManual.label(
                              fontSize: 11,
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
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
          'Your data stays saved to your account on this device. You will '
          'need to sign in again to continue.',
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
      // No local clearing here: per-account data lives in this account's OWN
      // Isar instance (uid-scoping batch). The session coordinator (app.dart)
      // reacts to the auth transition and swaps the active instance to the
      // anon scratch DB — nothing leaks to the next account, and this
      // account's data is restored on its next sign-in.
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) context.go('/welcome');
    }
  }

  /// Permanent account deletion (App Store Guideline 5.1.1(v)). Requires the
  /// user to type "DELETE" to confirm, then calls the server-side
  /// `deleteAccount` Cloud Function which tears down the account + ALL data and
  /// deletes the auth user. On success we clear on-device Isar + prefs (so the
  /// next account on this device inherits nothing), sign out, and route to
  /// /welcome. Failures show a friendly message; raw errors are logged.
  Future<void> _confirmDeleteAccount(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (confirmed != true || !context.mounted) return;

    HapticFeedback.heavyImpact();

    // Capture everything we need BEFORE the teardown: once we sign out and
    // navigate to /welcome this widget unmounts and `ref` becomes invalid.
    final authService = ref.read(authServiceProvider);
    final session = ref.read(isarSessionManagerProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final uid = ref.read(currentUserIdProvider);

    // Blocking progress dialog (dismissed via rootNavigator pop below).
    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CupertinoAlertDialog(
        title: Text('Deleting account…'),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: CupertinoActivityIndicator(),
        ),
      ),
    );

    // 1. Server-side teardown first. Only on success do we touch local state.
    try {
      await authService.deleteAccount();
    } catch (e) {
      // deleteAccount only throws AuthServiceException (user-safe message);
      // anything else was already logged inside the service.
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss progress
      final message = e is AuthServiceException
          ? e.message
          : "We couldn't delete your account. Please try again.";
      await _showInfoDialog(context, title: 'Deletion failed', message: message);
      return;
    }

    // 2. Account is gone server-side. Tear down THIS account's on-device
    //    data: its own Isar instance file (u_<uid>.isar) and its uid-keyed
    //    prefs. Device-level settings (theme, units, tutorial, caches,
    //    diagnostics) deliberately survive — they belong to the device, not
    //    the account (audit §4; the remaining per-uid pref keys are scoped in
    //    PR-B). Best-effort — a local-teardown failure must NOT be reported
    //    as "deletion failed", since the deletion already succeeded.
    try {
      if (uid != null) {
        // Swaps the active instance to the anon scratch DB, then deletes
        // u_<uid>.isar from disk.
        await session.deleteAccountData(uid);
        // Every uid-scoped pref the account owns (streak, schedule, notif_*,
        // quick-adds, custom exercises, drill sergeant, rank celebration) —
        // device-level settings deliberately survive (audit §4).
        await removeUidScopedPrefs(prefs, uid);
        await prefs.remove(hiddenPostsPrefsKey(uid));
      }
      // Legacy owner marker (retired fully in PR-C) — must not survive the
      // account it points to.
      await prefs.remove(localProfileOwnerKey);
    } catch (e, st) {
      AppLogger.error(
        'deleteAccount: clearing on-device data failed after server delete',
        error: e,
        stack: st,
      );
    }

    // Dismiss the progress dialog while this screen is still mounted. Once we
    // sign out below, the router's auth listener redirects to /welcome and
    // tears this screen down, after which `context` can't pop the dialog.
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    await authService.signOut();
    // signOut flips auth state → the router redirects to /welcome on its own;
    // this is a belt-and-suspenders for the rare case it hasn't yet.
    if (context.mounted) context.go('/welcome');
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
    final palette = AppColors.of(context);

    // Field surface with a hairline rule — no accent banner, no white text
    // (the Field Manual keeps chrome quiet; brass is for actions).
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border(bottom: BorderSide(color: palette.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontVariations: const [FontVariation('wght', 600)],
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: palette.text,
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
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontVariations: const [FontVariation('wght', 600)],
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        height: 1.3,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: '${goal.label} · ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          height: 1.4,
                          color: palette.textSecondary,
                        ),
                        children: [
                          // TDEE is a trained-against number — mono readout.
                          TextSpan(
                            text: '${tdee.toInt()} KCAL TDEE',
                            style: FieldManual.label(
                              fontSize: 11,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                color: palette.textSecondary,
                size: 18,
              ),
            ],
          ),
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
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    // FM mono eyebrow. Uppercase is visual only — VoiceOver gets the
    // sentence-case label.
    return Semantics(
      header: true,
      label: label,
      child: ExcludeSemantics(
        child: Text(
          label.toUpperCase(),
          style: FieldManual.label(
            fontSize: 11,
            color: AppColors.of(context).textSecondary,
          ),
        ),
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
        // Field Manual cards are 8px (DESIGN.md §Cards).
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );
  }
}

// ─── Airborne section ─────────────────────────────────────────────────────────

/// Subscription entry point (a "GO AIRBORNE" row that opens the RevenueCat
/// paywall) plus the App-Review-required Restore Purchases action. When the
/// entitlement is active the row flips to a quiet status tile — subscribers
/// never see an upsell.
class _AirborneSection extends ConsumerWidget {
  const _AirborneSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final airborne = ref.watch(airborneActiveProvider);

    return Column(
      children: [
        _SettingsCard(
          child: CupertinoListTile(
            // Airborne wears its own insignia and brass — the one accent the
            // equipped theme never swaps (DESIGN.md, Accent Swap Rule).
            leading: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: FieldManual.brass,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: JumpWings(width: 26, color: FieldManual.ink),
              ),
            ),
            title: Text(
              airborne ? 'AIRBORNE' : 'GO AIRBORNE',
              // A command wears Oswald, not uppercase Inter. Brass stays: the
              // one accent the equipped theme never swaps.
              style: FieldManual.title(
                color: airborne
                    ? palette.text
                    : FieldManual.brassOn(palette.background),
              ),
            ),
            subtitle: Text(
              airborne
                  ? 'Active · 100 coach messages a day + all standard themes'
                  : '100 AI Coach messages a day + every standard theme',
              style: textTheme.bodySmall?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            trailing: airborne
                ? Icon(
                    CupertinoIcons.checkmark_seal_fill,
                    color: palette.success,
                    size: 20,
                  )
                : Icon(
                    CupertinoIcons.chevron_right,
                    color: palette.text,
                    size: 18,
                  ),
            onTap: airborne
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    presentAirbornePaywall(context, ref);
                  },
          ),
        ),
        const SizedBox(height: 8),
        _SettingsCard(
          child: CupertinoListTile(
            leading: _SettingsIconBadge(
              icon: CupertinoIcons.arrow_clockwise,
              color: palette.accent,
            ),
            title: Text(
              'Restore Purchases',
              style: textTheme.bodyLarge?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Already subscribed? Bring it to this device',
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
              restoreAirbornePurchases(context, ref);
            },
          ),
        ),
      ],
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
    final palette = AppColors.of(context);
    // Quiet FM plate: field-raised ground, hairline edge, the icon carries
    // the voice (accent, or alert red for destructive rows).
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 20),
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
    // Enabling? Make sure we actually hold OS permission — the prompt the app
    // historically never requested — then refresh the banner state.
    if (prefs.enabled) {
      await NotificationService.instance.requestPermission();
      ref.invalidate(notificationsAuthorizedProvider);
    }
    // Delegate the actual (re)scheduling to the shared reconciler so this
    // toggle path and the launch path can never drift apart.
    await ref.read(notificationReconcilerProvider).reconcileDrill();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(drillSergeantProvider);
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    // Default true so the banner doesn't flash before the OS check resolves.
    final authorized =
        ref.watch(notificationsAuthorizedProvider).valueOrNull ?? true;

    return _SettingsCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main toggle row
            Row(
              children: [
                // One Voice Rule: the drill sergeant is loud in copy, not in
                // alert red — red is reserved for consequences.
                _SettingsIconBadge(
                  icon: CupertinoIcons.flame_fill,
                  color: palette.accent,
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
                  activeTrackColor: palette.accent,
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
            if (prefs.enabled && !authorized)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  await NotificationService.instance.requestPermission();
                  ref.invalidate(notificationsAuthorizedProvider);
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.destructive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: palette.destructive.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.bell_slash,
                          color: palette.destructive, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Notifications are off — the Drill Sergeant can't "
                          'reach you. Tap to enable, or turn them on in iOS '
                          'Settings › DrillFit.',
                          // Bone prose (AA on the tint); the bell-slash icon and
                          // border carry the alert. destructive text here was
                          // 4.06:1 — below the 4.5 floor for body copy.
                          style: textTheme.bodySmall
                              ?.copyWith(color: FieldManual.bone),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Sub-settings — only render when enabled
            if (prefs.enabled) ...[
              const SizedBox(height: 16),
              Divider(height: 1, color: palette.separator),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                label: 'Intensity',
                child: ExcludeSemantics(
                  child: Text(
                    'INTENSITY',
                    style: FieldManual.label(
                      fontSize: 11,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FmSegmented<int>(
                segments: const [
                  (1, 'Mild Roast'),
                  (2, 'Medium Roast'),
                  (3, 'Full Savage'),
                ],
                selected: prefs.intensity,
                onChanged: (v) async {
                  await ref
                      .read(drillSergeantProvider.notifier)
                      .setIntensity(v);
                  await _reschedule(ref);
                },
              ),
              // ── Full Metal Mode (explicit language) ──────────────────────
              // DORMANT: only renders while the kFullMetalEnabled gate (in
              // motivator_messages.dart) is open. Today it's closed, so this
              // toggle never appears and the shipping content stays 12+.
              // Enabling the gate requires bumping the App Store rating to 17+.
              if (kFullMetalEnabled) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Full Metal Mode',
                            style: textTheme.bodyLarge?.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            prefs.fullMetalEnabled
                                ? 'Explicit language ON (17+)'
                                : 'Unfiltered, explicit language. Opt-in.',
                            style: textTheme.bodySmall?.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoSwitch(
                      value: prefs.fullMetalEnabled,
                      activeTrackColor: palette.accent,
                      onChanged: (value) async {
                        HapticFeedback.selectionClick();
                        await ref
                            .read(drillSergeantProvider.notifier)
                            .setFullMetal(value);
                        await _reschedule(ref);
                      },
                    ),
                  ],
                ),
              ],
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
                    activeTrackColor: palette.accent,
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
        // Field surface, 12px sheet radius (DESIGN.md §Cards).
        decoration: BoxDecoration(
          color: AppColors.of(ctx).surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
        ),
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

// ─── Delete account confirmation dialog ─────────────────────────────────────

/// Type-to-confirm dialog for permanent account deletion. The destructive
/// "Delete" action is disabled until the user types DELETE exactly — a stronger
/// guard than a single tap for an irreversible action. Pops `true` only on an
/// explicit confirmed delete; `false`/null on cancel or dismiss.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  static const _confirmWord = 'DELETE';
  final _controller = TextEditingController();

  bool get _canDelete => _controller.text.trim() == _confirmWord;

  @override
  void initState() {
    super.initState();
    // Re-evaluate the button's enabled state as the user types.
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return CupertinoAlertDialog(
      title: const Text('Delete Account?'),
      content: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your account and ALL of your data — '
              'workouts, nutrition, progress, community posts, and profile. '
              'This is irreversible and cannot be undone.',
            ),
            const SizedBox(height: 14),
            const Text(
              'Type DELETE to confirm.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _controller,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              placeholder: _confirmWord,
              textInputAction: TextInputAction.done,
              style: TextStyle(color: palette.text),
              // FM input: field-raised fill, sharp 4px, hairline border.
              decoration: BoxDecoration(
                color: palette.surfaceElevated,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: palette.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              onSubmitted: (_) {
                if (_canDelete) Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: _canDelete ? () => Navigator.pop(context, true) : null,
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
