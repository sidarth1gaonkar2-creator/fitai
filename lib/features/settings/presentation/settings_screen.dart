import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../models/enums.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/isar_provider.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/unit_system_provider.dart';
import '../../../providers/user_profile_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final units = ref.watch(unitSystemProvider);
    final textTheme = Theme.of(context).textTheme;
    final palette = AppColors.of(context);

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

                // About section
                _SectionLabel(label: 'About', textTheme: textTheme),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: CupertinoListTile(
                    leading: _SettingsIconBadge(
                      icon: CupertinoIcons.info,
                      color: palette.accent,
                    ),
                    title: Text(
                      'FitAI',
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
          'You will need to sign in again to access your data.',
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
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) context.go('/welcome');
    }
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
