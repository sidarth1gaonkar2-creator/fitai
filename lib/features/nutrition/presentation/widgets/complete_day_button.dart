import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.refresh, size: 18),
                const SizedBox(width: 6),
                Text('Could not load — tap to retry',
                    style: FieldManual.body(fontSize: 14)),
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
          decoration: const BoxDecoration(
            // Sheets are ink by doctrine, 12pt top radius (DESIGN.md).
            color: FieldManual.ink,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The ceremony is earned only when the targets were HIT.
                // A merely-logged day gets a quiet, factual stamp — no
                // trophy for incomplete work (PRODUCT.md: praise only
                // completed work).
                Container(
                  width: 80,
                  height: 80,
                  decoration: macrosHit
                      ? BoxDecoration(
                          color: palette.accent,
                          shape: BoxShape.circle,
                        )
                      : BoxDecoration(
                          color: FieldManual.field,
                          shape: BoxShape.circle,
                          border: Border.all(color: FieldManual.hairlineStrong),
                        ),
                  child: Icon(
                    macrosHit
                        ? CupertinoIcons.rosette
                        : CupertinoIcons.checkmark_seal,
                    size: 44,
                    color: macrosHit ? palette.onAccent : FieldManual.mutedBone,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  // Ceremony headline — the sergeant shouts it (when earned).
                  macrosHit ? 'ALL MACROS HIT' : 'DAY LOGGED',
                  style: FieldManual.headline(),
                ),
                const SizedBox(height: 8),
                Text(
                  macrosHit
                      ? 'Solid work, soldier. Targets met. '
                          'Same standard tomorrow.'
                      : 'Log closed. Macros missed — the log doesn\'t lie. '
                          'Hit your numbers tomorrow.',
                  textAlign: TextAlign.center,
                  style: FieldManual.body(
                    fontSize: 14,
                    color: FieldManual.mutedBone,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CONTINUE',
                      style: FieldManual.title(color: palette.onAccent),
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
    // Completion ceremony CTA: accent fill carrying ink type (DESIGN.md).
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: palette.accent,
        borderRadius: BorderRadius.circular(4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        onPressed: onComplete,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.check_mark_circled,
                color: palette.onAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              'COMPLETE DAY',
              style: FieldManual.title(color: palette.onAccent),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              // Success tint stays: a completed day is earned work, so the
              // palette's success green marks the ceremony moment here.
              color: palette.success.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              macrosHit
                  ? CupertinoIcons.rosette
                  : CupertinoIcons.checkmark_seal,
              color: palette.success,
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
                      'DAY COMPLETE',
                      style: FieldManual.title().copyWith(fontSize: 14),
                    ),
                    if (macrosHit) ...[
                      const SizedBox(width: 6),
                      Icon(
                        CupertinoIcons.star_fill,
                        size: 16,
                        color: palette.accent,
                      ),
                    ],
                  ],
                ),
                Text(
                  macrosHit
                      ? 'All macros hit. Solid work, soldier.'
                      : 'Nutrition logged for today.',
                  style: FieldManual.body(
                    fontSize: 12,
                    color: FieldManual.mutedBone,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            onPressed: onUnlock,
            child: Text(
              'UNLOCK',
              style: FieldManual.label(
                fontSize: 11,
                color: palette.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
