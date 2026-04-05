import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WaterTracker extends StatelessWidget {
  const WaterTracker({
    super.key,
    required this.glasses,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int glasses;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  static const _goal = 8;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = (glasses / _goal).clamp(0.0, 1.0);

    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 28,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              '$glasses / $_goal',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'glasses',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: glasses > 0
                      ? () {
                          HapticFeedback.lightImpact();
                          onDecrement();
                        }
                      : null,
                  icon: const Icon(Icons.remove, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onIncrement();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
