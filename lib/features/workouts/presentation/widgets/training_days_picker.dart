import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/notification_providers.dart';
import '../../../../providers/training_schedule_provider.dart';

/// Reusable gym-day picker: seven weekday chips (Mon=1..Sun=7) bound to
/// [notificationSettingsProvider]'s `workoutDays`.
///
/// A deliberate tap toggles the day AND opts the user into the gym-streak
/// mechanic via [TrainingScheduleConfiguredNotifier.markConfigured] — the
/// `[1,3,5]` notification default alone never flips that flag (preserves PR4a's
/// no-infer rule). The chips are ALWAYS editable: setting a training schedule
/// never requires turning on reminders.
///
/// This is the single source of truth for the day picker, embedded both in the
/// Workouts History tab ([TrainingDaysCard]) and the Notifications settings
/// screen — both read/write the same provider state, so they can't drift.
class TrainingDaysPicker extends ConsumerWidget {
  const TrainingDaysPicker({super.key});

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);
    final palette = AppColors.of(context);

    return Wrap(
      spacing: 6,
      children: List.generate(7, (i) {
        final day = i + 1;
        final isSelected = settings.workoutDays.contains(day);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            final days = List<int>.from(settings.workoutDays);
            if (isSelected) {
              days.remove(day);
            } else {
              days.add(day);
            }
            notifier.update((s) => s.copyWith(workoutDays: days));
            // Deliberate user edit → opt into the gym-streak mechanic. The
            // [1,3,5] default alone never sets this; only an active tap flips
            // isConfigured (preserves PR4a's no-infer rule).
            ref
                .read(trainingScheduleConfiguredProvider.notifier)
                .markConfigured();
          },
          child: Container(
            width: 42,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? palette.accent : palette.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? palette.accent : palette.border,
              ),
            ),
            child: Text(
              _dayLabels[i],
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? palette.text : palette.textSecondary,
              ),
            ),
          ),
        );
      }),
    );
  }
}
