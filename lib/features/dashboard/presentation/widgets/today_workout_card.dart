import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Icons, Theme;
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../models/workout.dart';

class TodayWorkoutCard extends StatelessWidget {
  const TodayWorkoutCard({super.key, this.workout});

  final Workout? workout;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = AppColors.of(context);

    return CupertinoCard(
      color: palette.accent,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, color: palette.text),
              const SizedBox(width: 8),
              Text(
                "Today's Workout",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: palette.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (workout != null) ...[
            Text(
              workout!.title,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (workout!.durationMinutes != null) ...[
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: palette.text.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${workout!.durationMinutes} min',
                    style: textTheme.bodyMedium?.copyWith(
                      color: palette.text.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: palette.text,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'No workout logged yet today.',
              style: textTheme.bodyMedium?.copyWith(
                color: palette.text.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: palette.text,
                borderRadius: BorderRadius.circular(10),
                onPressed: () => context.go('/workouts'),
                child: Text(
                  'Log Workout',
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
