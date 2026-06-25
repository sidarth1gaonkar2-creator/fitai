import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../workouts/domain/streak_rewards.dart';

/// Dashboard half-width card surfacing the schedule-aware GYM streak (PR4b) and
/// its current coin multiplier. Shown in place of the any-activity
/// [StreakCounter] once the user has configured a training schedule.
///
/// Read-only: it reflects existing `gymStreakProvider` state and does no
/// awarding/break-detection (that all lives in the engine). Tapping routes to
/// the Workouts History tab, where the Training Days picker lives — so the card
/// doubles as a path to editing the schedule.
class GymStreakCard extends StatelessWidget {
  const GymStreakCard({super.key, required this.streak});

  /// Current gym streak length (`gymStreakProvider.currentStreak`).
  final int streak;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = AppColors.of(context);
    final multiplier = streakMultiplier(streak);
    // streak 0 = configured but not yet started → nudge; >0 = active streak.
    final subtitle =
        streak > 0 ? 'day gym streak' : 'log a workout on a gym day';

    return Semantics(
      button: true,
      label: streak > 0
          ? '$streak day gym streak, '
              '${multiplier.toStringAsFixed(1)} times coin multiplier'
          : 'Gym streak not started yet',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go('/workouts'),
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
                subtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
              // ×multiplier badge — the motivating number: coins earned per
              // completed gym day scale by this (clamped to [1.0, 2.0]).
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '×${multiplier.toStringAsFixed(1)}',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
