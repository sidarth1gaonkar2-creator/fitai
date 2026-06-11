import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/onboarding_gate_provider.dart';

/// Shown when we can't reach Firestore to determine whether the signed-in user
/// has completed onboarding.
///
/// We deliberately do NOT fall through to onboarding here — re-completing it
/// could overwrite an existing profile — so the user retries instead.
class ProfileErrorScreen extends ConsumerWidget {
  const ProfileErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final gate = ref.watch(onboardingGateProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 56,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 20),
                Text(
                  "Couldn't load your profile",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Check your connection and try again. Your data is safe — '
                  "we won't reset anything.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                if (gate.isLoading)
                  const CircularProgressIndicator()
                else
                  FilledButton(
                    onPressed: () => ref.invalidate(onboardingGateProvider),
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
