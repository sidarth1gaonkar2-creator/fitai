import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../providers/training_schedule_provider.dart';

/// Streak-multiplier coin economy — the single tuning point (like PR1's
/// recalibration factor). Coins are awarded ONCE per completed scheduled gym day
/// (not per workout — that was farmable), scaled by a smooth streak multiplier.
///
/// All logic here is PURE (no Riverpod/Isar/SharedPreferences) so the award
/// gating and break-detection state machine are exhaustively unit-testable; the
/// GymStreakNotifier is a thin wiring layer over these functions.

// ── Tunable constants (ONE place) ──────────────────────────────────────────
const int kStreakBaseCoins = 20;
const double kStreakTau = 14;
const double kStreakMultiplierCap = 2.0;

/// Smooth multiplier as a PURE function of the current gym-streak length:
/// `1 + (1 − e^(−streak/τ))`, clamped to [1.0, kStreakMultiplierCap].
/// Runs 1.0× (streak 0) → ~1.07× (day 1) → ~1.63× (day 14) → asymptotes to 2.0×.
double streakMultiplier(int streak) {
  final raw = 1 + (1 - exp(-streak / kStreakTau));
  return raw.clamp(1.0, kStreakMultiplierCap).toDouble();
}

/// Coins awarded for completing a gym day at the given streak length.
int gymDayReward(int streak) =>
    (kStreakBaseCoins * streakMultiplier(streak)).round();

// ── Local-civil-date helpers ────────────────────────────────────────────────
//
// DELIBERATE EXCEPTION to the store-everything-in-UTC rule: a gym streak is a
// LOCAL-CALENDAR question ("did a scheduled gym day pass without a workout?"),
// not an instant. We persist [GymStreakData.lastAwardedEpochDay] as a local
// civil-day ordinal, matching the existing local-midnight convention of
// streakProvider / workoutDatesProvider (which key off `DateTime(y, m, d)`).

/// Local civil date → days since 1970-01-01, computed via a UTC midnight built
/// from the LOCAL y/m/d so the arithmetic is DST-safe (UTC midnights are exactly
/// 24h apart; local midnights are not, around DST transitions).
int epochDayOf(DateTime localDate) =>
    DateTime.utc(localDate.year, localDate.month, localDate.day)
            .millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;

/// Inverse of [epochDayOf]: the local-midnight [DateTime] for a civil-day
/// ordinal. Matches the keys in `workoutDatesProvider`.
DateTime localMidnightFromEpochDay(int epochDay) {
  final utc = DateTime.fromMillisecondsSinceEpoch(
      epochDay * Duration.millisecondsPerDay,
      isUtc: true);
  return DateTime(utc.year, utc.month, utc.day);
}

/// The persisted gym-streak state (2 fields, SharedPreferences-backed).
@immutable
class GymStreakData {
  const GymStreakData({
    required this.currentStreak,
    required this.lastAwardedEpochDay,
  });

  /// Consecutive scheduled gym days hit.
  final int currentStreak;

  /// Local civil-day ordinal of the last day we awarded + incremented on, or
  /// null if we've never awarded. Doubles as the break-detection high-water mark
  /// (every awarded day is a worked-out scheduled day, so any scheduled day
  /// between this and today with no workout is a genuine miss).
  final int? lastAwardedEpochDay;

  static const GymStreakData initial =
      GymStreakData(currentStreak: 0, lastAwardedEpochDay: null);

  GymStreakData copyWith({int? currentStreak, int? lastAwardedEpochDay}) =>
      GymStreakData(
        currentStreak: currentStreak ?? this.currentStreak,
        lastAwardedEpochDay: lastAwardedEpochDay ?? this.lastAwardedEpochDay,
      );

  @override
  bool operator ==(Object other) =>
      other is GymStreakData &&
      other.currentStreak == currentStreak &&
      other.lastAwardedEpochDay == lastAwardedEpochDay;

  @override
  int get hashCode => Object.hash(currentStreak, lastAwardedEpochDay);
}

/// BREAK-DETECTION (pure). Resets the streak to 0 if any SCHEDULED gym day
/// strictly between [GymStreakData.lastAwardedEpochDay] and [today] had no
/// logged workout. Never awards, never increments. Rest (non-scheduled) days are
/// free. Today itself is never counted — it's still in progress.
///
/// No-ops when the schedule isn't configured or the streak is already 0 (which
/// bounds the scan: it only runs while there's a live streak to protect, and
/// returns on the first miss found).
GymStreakData reconcileGymStreak({
  required GymStreakData data,
  required TrainingSchedule schedule,
  required Set<DateTime> workoutDays,
  required DateTime today,
}) {
  if (!schedule.isConfigured) return data;
  if (data.currentStreak == 0) return data;
  final lastAwarded = data.lastAwardedEpochDay;
  if (lastAwarded == null) return data;

  final todayEpoch = epochDayOf(today);
  for (var e = lastAwarded + 1; e < todayEpoch; e++) {
    final day = localMidnightFromEpochDay(e);
    if (schedule.isScheduledGymDay(day) && !workoutDays.contains(day)) {
      // A committed gym day passed with no workout → streak broken.
      return data.copyWith(currentStreak: 0);
    }
  }
  return data;
}

/// FINISH-PATH award decision (pure). Returns the new state and the coins to
/// award (0 when no award is due). Mirrors the approved gating:
///   a. schedule not configured → no streak mechanic.
///   b. today isn't a scheduled gym day, or we already awarded today → skip
///      (kills the farm: a 2nd workout the same day awards nothing).
///   c. else catch up any break, then increment and award gymDayReward(streak).
({GymStreakData data, int reward}) recordGymDay({
  required GymStreakData data,
  required TrainingSchedule schedule,
  required Set<DateTime> workoutDays,
  required DateTime today,
}) {
  if (!schedule.isConfigured) return (data: data, reward: 0);

  final todayEpoch = epochDayOf(today);
  final todayMidnight = DateTime(today.year, today.month, today.day);

  if (!schedule.isScheduledGymDay(todayMidnight)) return (data: data, reward: 0);
  if (data.lastAwardedEpochDay == todayEpoch) return (data: data, reward: 0);

  final reconciled = reconcileGymStreak(
    data: data,
    schedule: schedule,
    workoutDays: workoutDays,
    today: today,
  );
  final newStreak = reconciled.currentStreak + 1;
  return (
    data: GymStreakData(
        currentStreak: newStreak, lastAwardedEpochDay: todayEpoch),
    reward: gymDayReward(newStreak),
  );
}
