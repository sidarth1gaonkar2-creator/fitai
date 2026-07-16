import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/gym_streak_provider.dart';
import '../../../../providers/training_schedule_provider.dart';
import '../../domain/streak_rewards.dart';
import 'training_days_picker.dart';

/// Workout-area entry point for setting gym days. Wraps the reusable
/// [TrainingDaysPicker] with a header and a one-line streak/multiplier status,
/// so "gym days" is editable where it lives mentally (the Workouts tab) without
/// a detour through Notifications settings.
///
/// Read-only status — it reflects existing `gymStreakProvider` /
/// `trainingScheduleProvider` state; the picker itself owns the writes.
class TrainingDaysCard extends ConsumerWidget {
  const TrainingDaysCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final schedule = ref.watch(trainingScheduleProvider);
    final gymStreak = ref.watch(gymStreakProvider);

    final String status;
    if (!schedule.isConfigured) {
      status = 'Pick your gym days to start a streak';
    } else if (gymStreak.currentStreak > 0) {
      // A mono stamp, not an emoji — the streak is a readout.
      status = 'STREAK DAY ${gymStreak.currentStreak} · '
          '×${streakMultiplier(gymStreak.currentStreak).toStringAsFixed(1)}';
    } else {
      status = 'Streak tracking on — log a workout on a gym day';
    }

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, size: 16, color: palette.accent),
              const SizedBox(width: 8),
              Text(
                'TRAINING DAYS',
                style: TextStyle(
                  fontFamily: 'Oswald',
                  fontVariations: const [FontVariation('wght', 600)],
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: palette.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const TrainingDaysPicker(),
          const SizedBox(height: 10),
          Text(
            // Streak + multiplier are trained-against numbers → mono when a
            // streak is live; quiet Inter otherwise.
            gymStreak.currentStreak > 0 && schedule.isConfigured
                ? status.toUpperCase()
                : status,
            style: gymStreak.currentStreak > 0 && schedule.isConfigured
                ? TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontVariations: const [FontVariation('wght', 700)],
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: palette.accent,
                  )
                : TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: schedule.isConfigured
                        ? palette.accent
                        : palette.textSecondary,
                  ),
          ),
        ],
      ),
    );
  }
}
