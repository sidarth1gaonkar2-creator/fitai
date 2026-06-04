import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ranks/domain/drill_sergeant.dart';

class StreakCounter extends StatelessWidget {
  const StreakCounter({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = AppColors.of(context);
    final milestone = streakMilestone(streak);

    return Semantics(
      label: '$streak day streak',
      child: Container(
        decoration: BoxDecoration(
          color: palette.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            const Icon(
              Icons.local_fire_department,
              size: 32,
              color: Colors.white,
            ),
            const SizedBox(height: 4),
            Text(
              streak.toString(),
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              'day streak',
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            // Drill-sergeant milestone at 7 / 14 / 30 days.
            if (milestone != null) ...[
              const SizedBox(height: 6),
              Text(
                milestone,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.95),
                  height: 1.25,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
