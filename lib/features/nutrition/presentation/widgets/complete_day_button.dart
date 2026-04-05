import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/nutrition_providers.dart';

/// Shows a "Complete Day" button when the day is not yet completed,
/// or a locked banner when the day has been completed.
class CompleteDayButton extends ConsumerWidget {
  const CompleteDayButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedAsync = ref.watch(todayCompletedDayProvider);

    return completedAsync.when(
      loading: () => const SizedBox(
        height: 52,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => SizedBox(
        height: 52,
        child: Center(
          child: TextButton.icon(
            onPressed: () => ref.invalidate(todayCompletedDayProvider),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Could not load — tap to retry'),
          ),
        ),
      ),
      data: (completedDay) {
        if (completedDay == null) {
          return _CompleteButton(
            onComplete: () async {
              HapticFeedback.mediumImpact();
              final success = await completeDay(ref);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Could not complete day. Make sure nutrition data is loaded.',
                    ),
                  ),
                );
              }
            },
          );
        }

        return _LockedBanner(
          macrosHit: completedDay.macrosHit,
          onUnlock: () => _showUnlockDialog(context, ref),
        );
      },
    );
  }

  Future<void> _showUnlockDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_open_outlined),
        title: const Text('Unlock day?'),
        content: const Text(
          'This will allow you to edit your nutrition log for today. '
          'Your completion record will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      await uncompleteDay(ref);
    }
  }
}

class _CompleteButton extends StatelessWidget {
  const _CompleteButton({required this.onComplete});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onComplete,
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Complete Day'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _LockedBanner extends StatelessWidget {
  const _LockedBanner({
    required this.macrosHit,
    required this.onUnlock,
  });

  final bool macrosHit;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card.filled(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.lock_outlined,
              color: colorScheme.onSecondaryContainer,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Day Complete!',
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (macrosHit) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 18,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    macrosHit
                        ? 'All macros hit. Great work!'
                        : 'Nutrition logged for today.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onUnlock,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSecondaryContainer,
              ),
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}
