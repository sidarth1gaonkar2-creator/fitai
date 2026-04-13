import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/notification_providers.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    final palette = AppColors.of(context);
    return CupertinoPageScaffold(
      backgroundColor: palette.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Notifications'),
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── Workout Reminders ──────────────────────────────────────
            _SectionHeader(title: 'Workout Reminders', icon: Icons.fitness_center),
            _ToggleRow(
              label: 'Workout Days',
              value: settings.workoutEnabled,
              onChanged: (v) => notifier.update((s) => s.copyWith(workoutEnabled: v)),
            ),
            if (settings.workoutEnabled) ...[
              const SizedBox(height: 8),
              // Day chips
              Wrap(
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
                          color: isSelected
                              ? palette.text
                              : palette.textSecondary,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              _TimePickerRow(
                label: 'Time',
                hour: settings.workoutHour,
                minute: settings.workoutMinute,
                onChanged: (h, m) =>
                    notifier.update((s) => s.copyWith(workoutHour: h, workoutMinute: m)),
              ),
            ],
            const SizedBox(height: 24),

            // ─── Meal Reminders ─────────────────────────────────────────
            _SectionHeader(title: 'Meal Reminders', icon: CupertinoIcons.square_favorites_alt),
            _ToggleRow(
              label: 'Breakfast',
              value: settings.breakfastEnabled,
              onChanged: (v) => notifier.update((s) => s.copyWith(breakfastEnabled: v)),
            ),
            if (settings.breakfastEnabled)
              _TimePickerRow(
                label: 'Time',
                hour: settings.breakfastHour,
                minute: settings.breakfastMinute,
                onChanged: (h, m) => notifier.update(
                    (s) => s.copyWith(breakfastHour: h, breakfastMinute: m)),
              ),
            const SizedBox(height: 6),
            _ToggleRow(
              label: 'Lunch',
              value: settings.lunchEnabled,
              onChanged: (v) => notifier.update((s) => s.copyWith(lunchEnabled: v)),
            ),
            if (settings.lunchEnabled)
              _TimePickerRow(
                label: 'Time',
                hour: settings.lunchHour,
                minute: settings.lunchMinute,
                onChanged: (h, m) =>
                    notifier.update((s) => s.copyWith(lunchHour: h, lunchMinute: m)),
              ),
            const SizedBox(height: 6),
            _ToggleRow(
              label: 'Dinner',
              value: settings.dinnerEnabled,
              onChanged: (v) => notifier.update((s) => s.copyWith(dinnerEnabled: v)),
            ),
            if (settings.dinnerEnabled)
              _TimePickerRow(
                label: 'Time',
                hour: settings.dinnerHour,
                minute: settings.dinnerMinute,
                onChanged: (h, m) =>
                    notifier.update((s) => s.copyWith(dinnerHour: h, dinnerMinute: m)),
              ),
            const SizedBox(height: 24),

            // ─── Water & Streak ─────────────────────────────────────────
            _SectionHeader(title: 'Hydration & Streaks', icon: CupertinoIcons.drop),
            _ToggleRow(
              label: 'Hourly Water Reminder',
              subtitle: '8am - 10pm',
              value: settings.waterEnabled,
              onChanged: (v) => notifier.update((s) => s.copyWith(waterEnabled: v)),
            ),
            const SizedBox(height: 6),
            _ToggleRow(
              label: 'Streak Protection',
              subtitle: 'Daily at 8pm if nothing logged',
              value: settings.streakEnabled,
              onChanged: (v) => notifier.update((s) => s.copyWith(streakEnabled: v)),
            ),
            const SizedBox(height: 24),

            // ─── PR & Supplements ───────────────────────────────────────
            _SectionHeader(title: 'Achievements & Supplements', icon: Icons.emoji_events),
            _ToggleRow(
              label: 'PR Celebration',
              subtitle: 'Notification when new PR is set',
              value: settings.prEnabled,
              onChanged: (v) => notifier.update((s) => s.copyWith(prEnabled: v)),
            ),
            const SizedBox(height: 6),
            _ToggleRow(
              label: 'Supplement Reminders',
              subtitle: 'Based on supplement timing',
              value: settings.supplementEnabled,
              onChanged: (v) => notifier.update((s) => s.copyWith(supplementEnabled: v)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: palette.accent, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: palette.text,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 12,
                      color: palette.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: palette.accent,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  const _TimePickerRow({
    required this.label,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  final String label;
  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  String get _formatted {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final ampm = hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: GestureDetector(
        onTap: () async {
          await showCupertinoModalPopup(
            context: context,
            builder: (pickerCtx) => Container(
              height: 216,
              color: AppColors.of(pickerCtx).surface,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(2024, 1, 1, hour, minute),
                onDateTimeChanged: (dt) => onChanged(dt.hour, dt.minute),
              ),
            ),
          );
        },
        child: Builder(
          builder: (context) {
            final palette = AppColors.of(context);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 13,
                      color: palette.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatted,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: palette.textSecondary,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
