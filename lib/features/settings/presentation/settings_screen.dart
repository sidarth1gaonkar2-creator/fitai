import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../models/enums.dart';
import '../../../providers/isar_provider.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/user_profile_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: const Text('Settings'),
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
                  child: SwitchListTile(
                    secondary: _SettingsIconBadge(
                      icon: Icons.dark_mode_outlined,
                      color: AppColors.purple,
                    ),
                    title: Text(
                      'Dark Mode',
                      style: textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      themeMode == ThemeMode.system
                          ? 'System default'
                          : themeMode == ThemeMode.dark
                              ? 'On'
                              : 'Off',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    value: themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      ref.read(themeModeProvider.notifier).state =
                          value ? ThemeMode.dark : ThemeMode.light;
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Data section
                _SectionLabel(label: 'Data', textTheme: textTheme),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: ListTile(
                    leading: _SettingsIconBadge(
                      icon: Icons.delete_forever_outlined,
                      color: AppColors.error,
                    ),
                    title: Text(
                      'Reset All Data',
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Delete all workouts, nutrition, and chat history',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.error.withValues(alpha: 0.7),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.lime,
                    ),
                    onTap: () => _confirmReset(context, ref),
                  ),
                ),
                const SizedBox(height: 24),

                // About section
                _SectionLabel(label: 'About', textTheme: textTheme),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: ListTile(
                    leading: const _SettingsIconBadge(
                      icon: Icons.info_outline,
                      color: AppColors.purple,
                    ),
                    title: Text(
                      'FitAI',
                      style: textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Version 1.0.0',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
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

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'This will permanently delete all your workouts, nutrition logs, '
          'weight entries, chat history, and profile. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
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
        color: AppColors.purple,
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.purpleDark,
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
                      color: AppColors.purpleLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.lime,
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
        color: AppColors.purpleLight,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkSurfaceBorder),
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
