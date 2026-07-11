import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/scoped_prefs.dart';
import 'auth_provider.dart';
import 'notification_providers.dart';
import 'unit_system_provider.dart';

/// CANONICAL WEEKDAY CONVENTION for all schedule logic: **1 = Monday … 7 =
/// Sunday**, identical to [DateTime.weekday]. This matches
/// [NotificationSettings.workoutDays] and Dart's native weekday, so the model is
/// compared against [DateTime]/[DateTime.now] with no conversion. The
/// notification schedulers' legacy 0-based form (Mon = 0) is confined behind
/// [restDaysToNotificationWeekdays] and never enters this model.

/// The user's training schedule: which weekdays are gym days, plus whether the
/// user has DELIBERATELY chosen a schedule at all.
@immutable
class TrainingSchedule {
  const TrainingSchedule({
    required this.isConfigured,
    required this.scheduledWeekdays,
  });

  /// True only once the user has deliberately set up a training schedule.
  ///
  /// Deliberately distinct from "the `[1, 3, 5]` workout-notification default
  /// exists": a user who never configured a schedule reports `false`, so the
  /// streak mechanic (PR4b) stays dormant — no scheduled days ⇒ no streak and
  /// nothing to break. The notification default is NEVER treated as a choice.
  final bool isConfigured;

  /// Gym weekdays in the canonical 1=Mon..7=Sun convention. ALWAYS empty when
  /// [isConfigured] is false.
  final Set<int> scheduledWeekdays;

  /// Whether [date] falls on a scheduled gym day. Always false when the schedule
  /// isn't configured. Compares against [DateTime.weekday] directly (same
  /// convention — no off-by-one).
  bool isScheduledGymDay(DateTime date) =>
      isConfigured && scheduledWeekdays.contains(date.weekday);

  /// Canonical "user has not chosen a schedule" value.
  static const TrainingSchedule notConfigured =
      TrainingSchedule(isConfigured: false, scheduledWeekdays: <int>{});

  /// Drops anything outside 1..7 (defensive against malformed stored prefs).
  static Set<int> sanitizeWeekdays(Iterable<int> days) =>
      {for (final d in days) if (d >= 1 && d <= 7) d};

  @override
  bool operator ==(Object other) =>
      other is TrainingSchedule &&
      other.isConfigured == isConfigured &&
      setEquals(other.scheduledWeekdays, scheduledWeekdays);

  @override
  int get hashCode =>
      Object.hash(isConfigured, Object.hashAllUnordered(scheduledWeekdays));
}

/// BASE SharedPreferences key (stored uid-scoped as `<key>_<uid>`, PR-B)
/// recording that the user deliberately chose a training schedule. Stored
/// separately from [NotificationSettings] so the mere existence of the
/// `[1, 3, 5]` notification default is never mistaken for an opt-in.
const String trainingScheduleConfiguredKey = 'training_schedule_configured';

/// Owns the "has the user chosen a schedule?" flag, per account. The provider
/// watches [currentUserIdProvider], so an account switch rebuilds this over
/// the incoming account's key; signed out the flag is false and nothing is
/// persisted — the streak mechanic stays dormant.
class TrainingScheduleConfiguredNotifier extends StateNotifier<bool> {
  TrainingScheduleConfiguredNotifier(this._prefs, this._uid)
      : super(_uid != null &&
            (_prefs.getBool(scopedKey(trainingScheduleConfiguredKey, _uid)) ??
                false));

  final SharedPreferences _prefs;
  final String? _uid;

  /// Marks the schedule as deliberately configured. PR4b's setup UI calls this
  /// after persisting the chosen days (which back onto
  /// [NotificationSettings.workoutDays]).
  Future<void> markConfigured() async {
    final uid = _uid;
    if (uid == null) return; // signed out: nothing user-scoped to arm
    await _prefs.setBool(scopedKey(trainingScheduleConfiguredKey, uid), true);
    state = true;
  }

  /// Clears the opt-in (account switch / sign-out / tests).
  Future<void> reset() async {
    final uid = _uid;
    if (uid != null) {
      await _prefs.remove(scopedKey(trainingScheduleConfiguredKey, uid));
    }
    state = false;
  }
}

final trainingScheduleConfiguredProvider =
    StateNotifierProvider<TrainingScheduleConfiguredNotifier, bool>((ref) {
  return TrainingScheduleConfiguredNotifier(
    ref.watch(sharedPreferencesProvider),
    ref.watch(currentUserIdProvider),
  );
});

/// THE single source of truth for "is weekday W a scheduled gym day."
///
/// Days are read from [notificationSettingsProvider]
/// ([NotificationSettings.workoutDays], 1=Mon..7=Sun) — PR4a backs the schedule
/// with the existing SharedPreferences value so consumers never depend on the
/// storage location; the later Isar move changes only this provider's internals.
/// Whether those days COUNT is gated by [trainingScheduleConfiguredProvider]:
/// until the user opts in this returns [TrainingSchedule.notConfigured]
/// regardless of the notification default.
final trainingScheduleProvider = Provider<TrainingSchedule>((ref) {
  final configured = ref.watch(trainingScheduleConfiguredProvider);
  if (!configured) return TrainingSchedule.notConfigured;
  final workoutDays =
      ref.watch(notificationSettingsProvider.select((s) => s.workoutDays));
  return TrainingSchedule(
    isConfigured: true,
    scheduledWeekdays: TrainingSchedule.sanitizeWeekdays(workoutDays),
  );
});
