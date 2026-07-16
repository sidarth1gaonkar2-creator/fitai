import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../workouts_controller.dart';

class RestTimerSheet extends ConsumerStatefulWidget {
  const RestTimerSheet({super.key});

  @override
  ConsumerState<RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends ConsumerState<RestTimerSheet> {
  int? _lastSeconds;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeWorkoutProvider);
    final seconds = state.restTimerSeconds;
    final colorScheme = Theme.of(context).colorScheme;

    if (seconds == null) {
      _lastSeconds = null;
      return const SizedBox.shrink();
    }

    // Haptic exactly once, when the countdown crosses zero — not on every
    // rebuild while it sits at 0.
    if (seconds <= 0 && (_lastSeconds == null || _lastSeconds! > 0)) {
      HapticFeedback.heavyImpact();
    }
    _lastSeconds = seconds;

    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final display =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final palette = AppColors.of(context);
    // Rest is an instrument panel: mono eyebrow, huge mono countdown legible
    // at arm's length, ±15s / skip at full 44pt targets. Same taps as before.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'REST',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontVariations: const [FontVariation('wght', 700)],
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 1.3,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              display,
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontVariations: const [FontVariation('wght', 700)],
                fontWeight: FontWeight.w700,
                fontSize: 44,
                height: 1.1,
                letterSpacing: 1,
                color: seconds <= 5
                    ? palette.destructive
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  color: palette.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                  onPressed: () => ref
                      .read(activeWorkoutProvider.notifier)
                      .adjustRestTimer(-15),
                  child: Text(
                    '-15s',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontVariations: const [FontVariation('wght', 700)],
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: palette.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  color: palette.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                  onPressed: () => ref
                      .read(activeWorkoutProvider.notifier)
                      .adjustRestTimer(15),
                  child: Text(
                    '+15s',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontVariations: const [FontVariation('wght', 700)],
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: palette.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  color: palette.accent,
                  borderRadius: BorderRadius.circular(4),
                  onPressed: () => ref
                      .read(activeWorkoutProvider.notifier)
                      .skipRestTimer(),
                  child: Text(
                    'SKIP',
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      fontVariations: const [FontVariation('wght', 600)],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.6,
                      color: const Color(0xFF1A1C1A), // ink on accent
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
