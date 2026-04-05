import 'package:flutter/material.dart';

class StreakCounter extends StatelessWidget {
  const StreakCounter({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card.filled(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Icon(
              Icons.local_fire_department,
              size: 32,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 4),
            Text(
              streak.toString(),
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            Text(
              'day streak',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
