import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
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
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (_, _) => SizedBox(
        height: 52,
        child: Center(
          child: CupertinoButton(
            onPressed: () => ref.invalidate(todayCompletedDayProvider),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.refresh, size: 18),
                SizedBox(width: 6),
                Text('Could not load — tap to retry'),
              ],
            ),
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
                showCupertinoToast(
                  context,
                  'Could not complete day. Make sure nutrition data is loaded.',
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

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        final palette = AppColors.of(context);
        return Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    size: 44,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  macrosHit ? 'All Macros Hit!' : 'Day Complete!',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  macrosHit
                      ? 'Amazing work! You nailed your nutrition targets today.'
                      : 'Great job logging your nutrition today. Keep it up!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.text.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showUnlockDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Unlock day?'),
        content: const Text(
          'This will allow you to edit your nutrition log for today. '
          'Your completion record will be removed.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
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
    final palette = AppColors.of(context);
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: palette.accent,
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.symmetric(vertical: 14),
        onPressed: onComplete,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.check_mark_circled,
                color: Colors.black, size: 20),
            SizedBox(width: 8),
            Text(
              'Complete Day',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
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
    final palette = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events,
              color: palette.accent,
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
                      style: TextStyle(
                        color: palette.text,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (macrosHit) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: palette.accent,
                      ),
                    ],
                  ],
                ),
                Text(
                  macrosHit
                      ? 'All macros hit. Great work!'
                      : 'Nutrition logged for today.',
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            onPressed: onUnlock,
            child: Text(
              'Unlock',
              style: TextStyle(color: palette.accent),
            ),
          ),
        ],
      ),
    );
  }
}
