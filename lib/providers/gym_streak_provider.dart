import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/logger.dart';
import '../features/themes/providers/theme_providers.dart';
import '../features/workouts/domain/streak_rewards.dart';
import 'training_schedule_provider.dart';
import 'unit_system_provider.dart';
import 'workout_providers.dart';

/// Schedule-aware, workout-only gym streak that drives the multiplier coin
/// economy. DISTINCT from [streakProvider] (the any-activity streak used by the
/// dashboard and notifications, which stays untouched).
///
/// State is SharedPreferences-backed (2 fields, no Isar change); it will be
/// uid-scoped together with the wallet (`UserThemeState.coins`) in the planned
/// migration batch. All decision logic lives in the pure functions in
/// streak_rewards.dart — this notifier only wires storage + providers + the
/// wallet to them.
class GymStreakNotifier extends StateNotifier<GymStreakData> {
  GymStreakNotifier(this._ref, this._prefs) : super(_load(_prefs));

  final Ref _ref;
  final SharedPreferences _prefs;

  static const _kStreak = 'gym_streak_current';
  static const _kLastAwarded = 'gym_streak_last_awarded_epoch_day';

  static GymStreakData _load(SharedPreferences prefs) => GymStreakData(
        currentStreak: prefs.getInt(_kStreak) ?? 0,
        lastAwardedEpochDay: prefs.getInt(_kLastAwarded),
      );

  Future<void> _persist(GymStreakData data) async {
    state = data;
    await _prefs.setInt(_kStreak, data.currentStreak);
    if (data.lastAwardedEpochDay == null) {
      await _prefs.remove(_kLastAwarded);
    } else {
      await _prefs.setInt(_kLastAwarded, data.lastAwardedEpochDay!);
    }
  }

  /// Break-detection only — runs on app launch / sign-in. NEVER awards coins
  /// (awards happen exclusively on the workout-finish path). Resets a streak
  /// that was broken by a missed scheduled gym day while the app was closed.
  Future<void> reconcile([DateTime? now]) async {
    final today = now ?? DateTime.now();
    final schedule = _ref.read(trainingScheduleProvider);
    if (!schedule.isConfigured || state.currentStreak == 0) return;
    try {
      final workoutDays = await _ref.read(workoutDatesProvider.future);
      final next = reconcileGymStreak(
        data: state,
        schedule: schedule,
        workoutDays: workoutDays,
        today: today,
      );
      if (next != state) await _persist(next);
    } catch (e, st) {
      AppLogger.error('Gym streak reconcile failed', error: e, stack: st);
    }
  }

  /// Finish path: gates (configured / scheduled-day / once-per-day), catches up
  /// any break, increments, persists, and awards the multiplier-scaled coins.
  /// Returns the coins awarded (0 when no award was due). Best-effort — a
  /// failure never blocks workout save.
  Future<int> recordCompletedWorkout([DateTime? now]) async {
    final today = now ?? DateTime.now();
    final schedule = _ref.read(trainingScheduleProvider);
    if (!schedule.isConfigured) return 0;
    try {
      final workoutDays = await _ref.read(workoutDatesProvider.future);
      final result = recordGymDay(
        data: state,
        schedule: schedule,
        workoutDays: workoutDays,
        today: today,
      );
      if (result.reward > 0) {
        await _persist(result.data);
        await _ref
            .read(userThemeStateProvider.notifier)
            .awardCoins(result.reward);
      }
      return result.reward;
    } catch (e, st) {
      AppLogger.error('Gym streak award failed', error: e, stack: st);
      return 0;
    }
  }
}

final gymStreakProvider =
    StateNotifierProvider<GymStreakNotifier, GymStreakData>((ref) {
  return GymStreakNotifier(ref, ref.watch(sharedPreferencesProvider));
});
