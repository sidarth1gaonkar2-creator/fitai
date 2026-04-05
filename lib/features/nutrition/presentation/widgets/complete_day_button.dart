import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
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
              if (!context.mounted) return;
              if (success) {
                _showTrophySheet(context, ref);
              } else {
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

  void _showTrophySheet(BuildContext context, WidgetRef ref) {
    final completedDay = ref.read(todayCompletedDayProvider).valueOrNull;
    final macrosHit = completedDay?.macrosHit ?? false;

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.purpleDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 44,
                color: AppColors.lime,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              macrosHit ? 'All Macros Hit!' : 'Day Complete!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: AppColors.lime,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              macrosHit
                  ? 'Amazing work! You nailed your nutrition targets today.'
                  : 'Great job logging your nutrition today. Keep it up!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
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

// ─── Complete Button ─────────────────────────────────────────────────────────

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
          backgroundColor: AppColors.lime,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// ─── Locked Banner ───────────────────────────────────────────────────────────

class _LockedBanner extends StatelessWidget {
  const _LockedBanner({
    required this.macrosHit,
    required this.onUnlock,
  });

  final bool macrosHit;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.purpleDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkSurfaceBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: AppColors.lime,
              size: 20,
            ),
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
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (macrosHit) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.lime,
                      ),
                    ],
                  ],
                ),
                Text(
                  macrosHit
                      ? 'All macros hit. Great work!'
                      : 'Nutrition logged for today.',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onUnlock,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.lime,
            ),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
}
