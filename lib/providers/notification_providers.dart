import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/logger.dart';
import '../core/utils/scoped_prefs.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';
import 'unit_system_provider.dart';

class NotificationSettings {
  const NotificationSettings({
    this.workoutEnabled = false,
    this.workoutDays = const [1, 3, 5], // Mon, Wed, Fri
    this.workoutHour = 7,
    this.workoutMinute = 0,
    this.breakfastEnabled = false,
    this.breakfastHour = 8,
    this.breakfastMinute = 0,
    this.lunchEnabled = false,
    this.lunchHour = 12,
    this.lunchMinute = 0,
    this.dinnerEnabled = false,
    this.dinnerHour = 18,
    this.dinnerMinute = 0,
    this.waterEnabled = false,
    this.streakEnabled = false,
    this.prEnabled = true,
    this.supplementEnabled = false,
    this.restDays = const <int>{},
    this.challengeRemindersEnabled = true,
  });

  final bool workoutEnabled;
  final List<int> workoutDays;
  final int workoutHour;
  final int workoutMinute;
  final bool breakfastEnabled;
  final int breakfastHour;
  final int breakfastMinute;
  final bool lunchEnabled;
  final int lunchHour;
  final int lunchMinute;
  final bool dinnerEnabled;
  final int dinnerHour;
  final int dinnerMinute;
  final bool waterEnabled;
  final bool streakEnabled;
  final bool prEnabled;
  final bool supplementEnabled;

  /// Weekdays the user wants left alone — no workout or streak reminders.
  ///
  /// Canonical **1 = Monday … 7 = Sunday** convention (matches [workoutDays] and
  /// [DateTime.weekday]); empty = remind every day. The low-level notification
  /// schedulers compare in a 0-based form, so this is converted at that edge via
  /// [restDaysToNotificationWeekdays] — the 0-based form never lives in state.
  ///
  /// No migration is needed for the 0-based→1-based convention change: no UI
  /// populates this set today, so the stored value (`notif_rest_days`) is only
  /// ever empty, which is identical in both encodings.
  final Set<int> restDays;

  /// Master toggle for challenge-related notifications (daily check-ins,
  /// goal-reached, completion).
  final bool challengeRemindersEnabled;

  NotificationSettings copyWith({
    bool? workoutEnabled,
    List<int>? workoutDays,
    int? workoutHour,
    int? workoutMinute,
    bool? breakfastEnabled,
    int? breakfastHour,
    int? breakfastMinute,
    bool? lunchEnabled,
    int? lunchHour,
    int? lunchMinute,
    bool? dinnerEnabled,
    int? dinnerHour,
    int? dinnerMinute,
    bool? waterEnabled,
    bool? streakEnabled,
    bool? prEnabled,
    bool? supplementEnabled,
    Set<int>? restDays,
    bool? challengeRemindersEnabled,
  }) {
    return NotificationSettings(
      workoutEnabled: workoutEnabled ?? this.workoutEnabled,
      workoutDays: workoutDays ?? this.workoutDays,
      workoutHour: workoutHour ?? this.workoutHour,
      workoutMinute: workoutMinute ?? this.workoutMinute,
      breakfastEnabled: breakfastEnabled ?? this.breakfastEnabled,
      breakfastHour: breakfastHour ?? this.breakfastHour,
      breakfastMinute: breakfastMinute ?? this.breakfastMinute,
      lunchEnabled: lunchEnabled ?? this.lunchEnabled,
      lunchHour: lunchHour ?? this.lunchHour,
      lunchMinute: lunchMinute ?? this.lunchMinute,
      dinnerEnabled: dinnerEnabled ?? this.dinnerEnabled,
      dinnerHour: dinnerHour ?? this.dinnerHour,
      dinnerMinute: dinnerMinute ?? this.dinnerMinute,
      waterEnabled: waterEnabled ?? this.waterEnabled,
      streakEnabled: streakEnabled ?? this.streakEnabled,
      prEnabled: prEnabled ?? this.prEnabled,
      supplementEnabled: supplementEnabled ?? this.supplementEnabled,
      restDays: restDays ?? this.restDays,
      challengeRemindersEnabled:
          challengeRemindersEnabled ?? this.challengeRemindersEnabled,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier(this._prefs, this._uid)
      : super(const NotificationSettings()) {
    _load();
  }

  final SharedPreferences _prefs;

  /// The account whose `notif_*_<uid>` keys back this notifier (PR-B). The
  /// provider watches [currentUserIdProvider], so an account switch rebuilds
  /// this notifier and the session coordinator's reconcile() then reads the
  /// INCOMING account's settings. Null (signed out) = defaults, no persistence.
  final String? _uid;

  String _k(String base) => scopedKey(base, _uid!);

  void _load() {
    if (_uid == null) {
      // Signed out: defaults only — nothing user-scoped is read or written.
      state = const NotificationSettings();
      return;
    }
    state = NotificationSettings(
      workoutEnabled: _prefs.getBool(_k('notif_workout_enabled')) ?? false,
      workoutDays: _loadIntList(_k('notif_workout_days')) ?? [1, 3, 5],
      workoutHour: _prefs.getInt(_k('notif_workout_hour')) ?? 7,
      workoutMinute: _prefs.getInt(_k('notif_workout_minute')) ?? 0,
      breakfastEnabled: _prefs.getBool(_k('notif_breakfast_enabled')) ?? false,
      breakfastHour: _prefs.getInt(_k('notif_breakfast_hour')) ?? 8,
      breakfastMinute: _prefs.getInt(_k('notif_breakfast_minute')) ?? 0,
      lunchEnabled: _prefs.getBool(_k('notif_lunch_enabled')) ?? false,
      lunchHour: _prefs.getInt(_k('notif_lunch_hour')) ?? 12,
      lunchMinute: _prefs.getInt(_k('notif_lunch_minute')) ?? 0,
      dinnerEnabled: _prefs.getBool(_k('notif_dinner_enabled')) ?? false,
      dinnerHour: _prefs.getInt(_k('notif_dinner_hour')) ?? 18,
      dinnerMinute: _prefs.getInt(_k('notif_dinner_minute')) ?? 0,
      waterEnabled: _prefs.getBool(_k('notif_water_enabled')) ?? false,
      streakEnabled: _prefs.getBool(_k('notif_streak_enabled')) ?? false,
      prEnabled: _prefs.getBool(_k('notif_pr_enabled')) ?? true,
      supplementEnabled:
          _prefs.getBool(_k('notif_supplement_enabled')) ?? false,
      restDays: (_loadIntList(_k('notif_rest_days')) ?? const <int>[]).toSet(),
      challengeRemindersEnabled:
          _prefs.getBool(_k('notif_challenge_enabled')) ?? true,
    );
  }

  List<int>? _loadIntList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return (jsonDecode(raw) as List).cast<int>();
  }

  Future<void> _save() async {
    if (_uid == null) return; // signed out: dormant — no anon keys
    await _prefs.setBool(_k('notif_workout_enabled'), state.workoutEnabled);
    await _prefs.setString(
        _k('notif_workout_days'), jsonEncode(state.workoutDays));
    await _prefs.setInt(_k('notif_workout_hour'), state.workoutHour);
    await _prefs.setInt(_k('notif_workout_minute'), state.workoutMinute);
    await _prefs.setBool(
        _k('notif_breakfast_enabled'), state.breakfastEnabled);
    await _prefs.setInt(_k('notif_breakfast_hour'), state.breakfastHour);
    await _prefs.setInt(_k('notif_breakfast_minute'), state.breakfastMinute);
    await _prefs.setBool(_k('notif_lunch_enabled'), state.lunchEnabled);
    await _prefs.setInt(_k('notif_lunch_hour'), state.lunchHour);
    await _prefs.setInt(_k('notif_lunch_minute'), state.lunchMinute);
    await _prefs.setBool(_k('notif_dinner_enabled'), state.dinnerEnabled);
    await _prefs.setInt(_k('notif_dinner_hour'), state.dinnerHour);
    await _prefs.setInt(_k('notif_dinner_minute'), state.dinnerMinute);
    await _prefs.setBool(_k('notif_water_enabled'), state.waterEnabled);
    await _prefs.setBool(_k('notif_streak_enabled'), state.streakEnabled);
    await _prefs.setBool(_k('notif_pr_enabled'), state.prEnabled);
    await _prefs.setBool(
        _k('notif_supplement_enabled'), state.supplementEnabled);
    await _prefs.setString(
      _k('notif_rest_days'),
      jsonEncode(state.restDays.toList()..sort()),
    );
    await _prefs.setBool(
      _k('notif_challenge_enabled'),
      state.challengeRemindersEnabled,
    );
  }

  /// Re-applies the current notif_* settings to the scheduler: schedules the
  /// enabled families, cancels the disabled ones. Requests OS permission first
  /// when anything is enabled — the prompt the app previously never showed.
  /// Public so the launch/sign-in reconciler can call it too.
  Future<void> syncSchedules() async {
    final ns = NotificationService.instance;

    final anyEnabled = state.workoutEnabled ||
        state.breakfastEnabled ||
        state.lunchEnabled ||
        state.dinnerEnabled ||
        state.waterEnabled ||
        state.streakEnabled;
    if (anyEnabled) {
      final granted = await ns.requestPermission();
      AppLogger.log('[notif] settings sync: permission granted=$granted');
    }

    // Workout
    if (state.workoutEnabled) {
      await ns.scheduleWorkoutReminder(
        days: state.workoutDays,
        hour: state.workoutHour,
        minute: state.workoutMinute,
      );
    } else {
      await ns.cancelWorkoutReminders();
    }

    // Meals
    if (state.breakfastEnabled) {
      await ns.scheduleMealReminder(
          mealIndex: 0,
          hour: state.breakfastHour,
          minute: state.breakfastMinute);
    } else {
      await ns.cancelMealReminder(0);
    }
    if (state.lunchEnabled) {
      await ns.scheduleMealReminder(
          mealIndex: 1, hour: state.lunchHour, minute: state.lunchMinute);
    } else {
      await ns.cancelMealReminder(1);
    }
    if (state.dinnerEnabled) {
      await ns.scheduleMealReminder(
          mealIndex: 2, hour: state.dinnerHour, minute: state.dinnerMinute);
    } else {
      await ns.cancelMealReminder(2);
    }

    // Water
    if (state.waterEnabled) {
      await ns.scheduleWaterReminders();
    } else {
      await ns.cancelWaterReminders();
    }

    // Streak
    if (state.streakEnabled) {
      await ns.scheduleStreakReminder();
    } else {
      await ns.cancelStreakReminder();
    }
  }

  Future<void> update(NotificationSettings Function(NotificationSettings) updater) async {
    state = updater(state);
    await _save();
    await syncSchedules();
  }
}

final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsNotifier, NotificationSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationSettingsNotifier(prefs, ref.watch(currentUserIdProvider));
});

final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  return NotificationService.instance.requestPermission();
});

/// Check-only OS notification authorization. autoDispose so it re-checks when a
/// settings screen re-subscribes (e.g. after the user returns from iOS
/// Settings). Drives the "enable in Settings" banner — never a silent failure.
final notificationsAuthorizedProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  return NotificationService.instance.hasPermission();
});

/// Converts rest-day weekdays from the app's canonical 1-based convention
/// (1=Mon..7=Sun — see [NotificationSettings.restDays] and TrainingSchedule) to
/// the 0-based form (Mon = 0 … Sun = 6) that the low-level notification
/// schedulers compare against (`DateTime.now().weekday - 1` in
/// [NotificationService.scheduleDrillSergeantReminders] and
/// [NotificationService.scheduleStreakReminderSmart]).
///
/// This is the ONLY sanctioned bridge between the two conventions: pass model
/// rest-days through here AT the notification call site so the 0-based form
/// never escapes the notification API edge. Out-of-range values are dropped.
Set<int> restDaysToNotificationWeekdays(Iterable<int> oneBasedRestDays) =>
    {for (final d in oneBasedRestDays) if (d >= 1 && d <= 7) d - 1};
