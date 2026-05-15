import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
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
  /// 0 = Monday … 6 = Sunday. Empty = remind every day.
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
  NotificationSettingsNotifier(this._prefs)
      : super(const NotificationSettings()) {
    _load();
  }

  final SharedPreferences _prefs;

  void _load() {
    state = NotificationSettings(
      workoutEnabled: _prefs.getBool('notif_workout_enabled') ?? false,
      workoutDays: _loadIntList('notif_workout_days') ?? [1, 3, 5],
      workoutHour: _prefs.getInt('notif_workout_hour') ?? 7,
      workoutMinute: _prefs.getInt('notif_workout_minute') ?? 0,
      breakfastEnabled: _prefs.getBool('notif_breakfast_enabled') ?? false,
      breakfastHour: _prefs.getInt('notif_breakfast_hour') ?? 8,
      breakfastMinute: _prefs.getInt('notif_breakfast_minute') ?? 0,
      lunchEnabled: _prefs.getBool('notif_lunch_enabled') ?? false,
      lunchHour: _prefs.getInt('notif_lunch_hour') ?? 12,
      lunchMinute: _prefs.getInt('notif_lunch_minute') ?? 0,
      dinnerEnabled: _prefs.getBool('notif_dinner_enabled') ?? false,
      dinnerHour: _prefs.getInt('notif_dinner_hour') ?? 18,
      dinnerMinute: _prefs.getInt('notif_dinner_minute') ?? 0,
      waterEnabled: _prefs.getBool('notif_water_enabled') ?? false,
      streakEnabled: _prefs.getBool('notif_streak_enabled') ?? false,
      prEnabled: _prefs.getBool('notif_pr_enabled') ?? true,
      supplementEnabled: _prefs.getBool('notif_supplement_enabled') ?? false,
      restDays: (_loadIntList('notif_rest_days') ?? const <int>[]).toSet(),
      challengeRemindersEnabled:
          _prefs.getBool('notif_challenge_enabled') ?? true,
    );
  }

  List<int>? _loadIntList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return (jsonDecode(raw) as List).cast<int>();
  }

  Future<void> _save() async {
    await _prefs.setBool('notif_workout_enabled', state.workoutEnabled);
    await _prefs.setString(
        'notif_workout_days', jsonEncode(state.workoutDays));
    await _prefs.setInt('notif_workout_hour', state.workoutHour);
    await _prefs.setInt('notif_workout_minute', state.workoutMinute);
    await _prefs.setBool('notif_breakfast_enabled', state.breakfastEnabled);
    await _prefs.setInt('notif_breakfast_hour', state.breakfastHour);
    await _prefs.setInt('notif_breakfast_minute', state.breakfastMinute);
    await _prefs.setBool('notif_lunch_enabled', state.lunchEnabled);
    await _prefs.setInt('notif_lunch_hour', state.lunchHour);
    await _prefs.setInt('notif_lunch_minute', state.lunchMinute);
    await _prefs.setBool('notif_dinner_enabled', state.dinnerEnabled);
    await _prefs.setInt('notif_dinner_hour', state.dinnerHour);
    await _prefs.setInt('notif_dinner_minute', state.dinnerMinute);
    await _prefs.setBool('notif_water_enabled', state.waterEnabled);
    await _prefs.setBool('notif_streak_enabled', state.streakEnabled);
    await _prefs.setBool('notif_pr_enabled', state.prEnabled);
    await _prefs.setBool('notif_supplement_enabled', state.supplementEnabled);
    await _prefs.setString(
      'notif_rest_days',
      jsonEncode(state.restDays.toList()..sort()),
    );
    await _prefs.setBool(
      'notif_challenge_enabled',
      state.challengeRemindersEnabled,
    );
  }

  Future<void> _syncSchedules() async {
    final ns = NotificationService.instance;

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
    await _syncSchedules();
  }
}

final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsNotifier, NotificationSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationSettingsNotifier(prefs);
});

final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  return NotificationService.instance.requestPermission();
});
