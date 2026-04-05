import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Profile section ---
          Text('Profile',
              style: textTheme.labelLarge
                  ?.copyWith(color: colorScheme.primary)),
          const SizedBox(height: 8),
          profileAsync.when(
            data: (profile) {
              if (profile == null) return const SizedBox.shrink();
              return Card.filled(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name[0].toUpperCase()
                          : '?',
                      style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer),
                    ),
                  ),
                  title: Text(profile.name),
                  subtitle: Text(
                    '${profile.goal.label} · ${profile.tdee.toInt()} kcal TDEE',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/settings/edit-profile'),
                ),
              );
            },
            loading: () => const ShimmerCard(height: 72),
            error: (_, _) => ErrorCard(
              message: 'Could not load profile.',
              onRetry: () => ref.invalidate(userProfileProvider),
            ),
          ),
          const SizedBox(height: 24),

          // --- Appearance section ---
          Text('Appearance',
              style: textTheme.labelLarge
                  ?.copyWith(color: colorScheme.primary)),
          const SizedBox(height: 8),
          Card.filled(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark Mode'),
              subtitle: Text(
                themeMode == ThemeMode.system
                    ? 'System default'
                    : themeMode == ThemeMode.dark
                        ? 'On'
                        : 'Off',
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

          // --- Data section ---
          Text('Data',
              style: textTheme.labelLarge
                  ?.copyWith(color: colorScheme.primary)),
          const SizedBox(height: 8),
          Card.filled(
            child: ListTile(
              leading: Icon(Icons.delete_forever, color: colorScheme.error),
              title: const Text('Reset All Data'),
              subtitle: const Text('Delete all workouts, nutrition, and chat history'),
              onTap: () => _confirmReset(context, ref),
            ),
          ),
          const SizedBox(height: 24),

          // --- About ---
          Text('About',
              style: textTheme.labelLarge
                  ?.copyWith(color: colorScheme.primary)),
          const SizedBox(height: 8),
          Card.filled(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('FitAI'),
              subtitle: const Text('Version 1.0.0'),
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
