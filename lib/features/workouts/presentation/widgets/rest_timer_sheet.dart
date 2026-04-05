import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../workouts_controller.dart';

class RestTimerSheet extends ConsumerWidget {
  const RestTimerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeWorkoutProvider);
    final seconds = state.restTimerSeconds;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (seconds == null) return const SizedBox.shrink();

    // Trigger haptic feedback when timer reaches 0
    if (seconds <= 0) {
      HapticFeedback.heavyImpact();
    }

    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final display =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rest Timer',
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              display,
              style: textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: seconds <= 5 ? colorScheme.error : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonal(
                  onPressed: () => ref
                      .read(activeWorkoutProvider.notifier)
                      .adjustRestTimer(-15),
                  child: const Text('-15s'),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: () => ref
                      .read(activeWorkoutProvider.notifier)
                      .adjustRestTimer(15),
                  child: const Text('+15s'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => ref
                      .read(activeWorkoutProvider.notifier)
                      .skipRestTimer(),
                  child: const Text('Skip'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
