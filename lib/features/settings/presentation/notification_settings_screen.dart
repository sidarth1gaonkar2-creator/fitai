import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/field_manual.dart';
import '../../../providers/gym_streak_provider.dart';
import '../../../providers/notification_providers.dart';
import '../../../providers/training_schedule_provider.dart';
import '../../../services/notification_service.dart';
import '../../workouts/presentation/widgets/training_days_picker.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);
    // Training schedule (drives the gym-streak coin economy) + current streak,
    // surfaced under the day picker below.
    final schedule = ref.watch(trainingScheduleProvider);
    final gymStreak = ref.watch(gymStreakProvider);

    final palette = AppColors.of(context);
    final authorized =
        ref.watch(notificationsAuthorizedProvider).valueOrNull ?? true;
    final anyEnabled = settings.workoutEnabled ||
        settings.breakfastEnabled ||
        settings.lunchEnabled ||
        settings.dinnerEnabled ||
        settings.waterEnabled ||
        settings.streakEnabled ||
        settings.supplementEnabled;
    return CupertinoPageScaffold(
      backgroundColor: palette.scaffold,
      navigationBar: CupertinoNavigationBar(
        // Field Manual nav: Oswald designation, hairline rule.
        middle: Text('NOTIFICATIONS', style: FieldManual.title()),
        backgroundColor: palette.background.withValues(alpha: 0.82),
        border: Border(bottom: BorderSide(color: palette.border, width: 0.5)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // OS permission off but notifications enabled in-app → never fail
            // silently; show a tappable prompt to enable.
            if (anyEnabled && !authorized) ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  await NotificationService.instance.requestPermission();
                  ref.invalidate(notificationsAuthorizedProvider);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  // Alert red is earned here — a real consequence callout.
                  decoration: BoxDecoration(
                    color: palette.destructive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: palette.destructive.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.bell_slash,
                          color: palette.destructive, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Notifications are off in iOS Settings. Tap to '
                          'enable, or turn them on in Settings › DrillFit.',
                          // Bone prose (AA on the tint); the icon + border carry
                          // the alert. destructive body text was 4.06:1 here.
                          style: FieldManual.body(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // ─── Training Schedule ──────────────────────────────────────
            // The day chips ARE the training schedule — they drive the
            // gym-streak coin economy, so they're ALWAYS editable: setting a
            // schedule must not require turning on reminders. The reminder
            // toggle + time picker below are an optional layer on these days.
            const _SectionHeader(title: 'Training Schedule'),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                'Pick your gym days to track your streak',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  height: 1.4,
                  color: palette.textSecondary,
                ),
              ),
            ),
            // Day chips — always visible (no longer gated behind reminders).
            // Shared widget: identical toggle + markConfigured behaviour as the
            // Workouts-tab Training Days card (single source of truth).
            const TrainingDaysPicker(),
            // Minimal confirmation the mechanic is live once the user opts in.
            // (A richer multiplier/coins display can land on the dashboard later.)
            if (schedule.isConfigured)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                // A live streak is an instrument readout — mono. The idle
                // hint stays sentence-case Inter.
                child: gymStreak.currentStreak > 0
                    ? Text(
                        '${gymStreak.currentStreak}-DAY GYM STREAK',
                        style: FieldManual.label(
                          fontSize: 11,
                          color: palette.accent,
                        ),
                      )
                    : Text(
                        'Streak tracking on — log a workout on a gym day',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          height: 1.4,
                          color: palette.textSecondary,
                        ),
                      ),
              ),
            const SizedBox(height: 12),
            // Optional reminders for the chosen days — independent of the
            // schedule itself.
            _ToggleRow(
              label: 'Remind me on these days',
              value: settings.workoutEnabled,
              onChanged: (v) =>
                  notifier.update((s) => s.copyWith(workoutEnabled: v)),
            ),
            if (settings.workoutEnabled) ...[
              const SizedBox(height: 8),
              _TimePickerRow(
                label: 'Time',
                hour: settings.workoutHour,
                minute: settings.workoutMinute,
                onChanged: (h, m) => notifier
                    .update((s) => s.copyWith(workoutHour: h, workoutMinute: m)),
              ),
            ],
            const SizedBox(height: 24),

            // ─── Meal Reminders ─────────────────────────────────────────
            const _SectionHeader(title: 'Meal Reminders'),
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
            const _SectionHeader(title: 'Hydration & Streaks'),
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
            const _SectionHeader(title: 'Achievements & Supplements'),
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
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    // FM mono eyebrow. Uppercase is visual only — VoiceOver gets the
    // sentence-case label.
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        header: true,
        label: title,
        child: ExcludeSemantics(
          child: Text(
            title.toUpperCase(),
            style: FieldManual.label(
              fontSize: 11,
              color: palette.textSecondary,
            ),
          ),
        ),
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
    // Field card, 8px, hairline — sentence-case Inter copy.
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
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
                    fontFamily: 'Inter',
                    fontVariations: const [FontVariation('wght', 600)],
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    height: 1.35,
                    color: palette.text,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      height: 1.4,
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
      child: Semantics(
        button: true,
        label: '$label, $_formatted',
        child: ExcludeSemantics(
          child: GestureDetector(
            onTap: () async {
              await showCupertinoModalPopup(
                context: context,
                builder: (pickerCtx) => Container(
                  height: 216,
                  // Field surface, 12px sheet radius (DESIGN.md §Cards).
                  decoration: BoxDecoration(
                    color: AppColors.of(pickerCtx).surface,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                  ),
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
                // FM input surface: field-raised, sharp 4px, hairline. The
                // time is an instrument readout — mono.
                return Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: palette.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: FieldManual.label(
                          fontSize: 11,
                          color: palette.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatted,
                        // Value reads in bone — accent mono on fieldRaised fell
                        // below 4.5:1 for 5 packs (1.5:1 on Stealth). The accent
                        // lives on the chevron affordance.
                        style: FieldManual.label(
                          fontSize: 12,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 14,
                        color: palette.accent,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
