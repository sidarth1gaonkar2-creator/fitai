import 'package:flutter_test/flutter_test.dart';

import 'package:fitai/features/workouts/domain/streak_rewards.dart';
import 'package:fitai/providers/training_schedule_provider.dart';

void main() {
  // 2024-01-01 was a Monday → Jan 2024 maps weekday cleanly (1=Mon..7=Sun).
  DateTime d(int day) => DateTime(2024, 1, day);
  int epoch(int day) => epochDayOf(d(day));

  // Mon/Wed/Fri schedule, deliberately configured.
  const mwf = TrainingSchedule(
    isConfigured: true,
    scheduledWeekdays: {1, 3, 5},
  );

  group('streakMultiplier', () {
    test('streak 0 → exactly 1.0', () {
      expect(streakMultiplier(0), 1.0);
    });

    test('streak 1 → ~1.07', () {
      expect(streakMultiplier(1), closeTo(1.069, 0.002));
    });

    test('ramps monotonically with streak length', () {
      expect(streakMultiplier(1), lessThan(streakMultiplier(7)));
      expect(streakMultiplier(7), lessThan(streakMultiplier(14)));
      expect(streakMultiplier(14), lessThan(streakMultiplier(30)));
    });

    test('day 14 ≈ 1.63 (≈ 1 + (1 - e^-1))', () {
      expect(streakMultiplier(14), closeTo(1.632, 0.002));
    });

    test('never exceeds the cap and clamps to 2.0 at large streaks', () {
      for (final s in [1, 14, 30, 100, 10000]) {
        expect(streakMultiplier(s), lessThanOrEqualTo(2.0));
      }
      expect(streakMultiplier(10000), 2.0);
    });
  });

  group('gymDayReward', () {
    test('base × multiplier, rounded', () {
      expect(gymDayReward(0), 20); // 20 × 1.0
      expect(gymDayReward(1), 21); // 20 × 1.069 = 21.4 → 21
      expect(gymDayReward(14), 33); // 20 × 1.632 = 32.6 → 33
      expect(gymDayReward(10000), 40); // 20 × 2.0 (cap)
    });

    test('is monotonic up to the cap', () {
      expect(gymDayReward(1), lessThanOrEqualTo(gymDayReward(7)));
      expect(gymDayReward(7), lessThanOrEqualTo(gymDayReward(30)));
      expect(gymDayReward(30), lessThanOrEqualTo(40));
    });
  });

  group('epoch-day helpers (local civil date)', () {
    test('round-trips a civil date through epoch-day', () {
      final date = DateTime(2024, 3, 15);
      expect(localMidnightFromEpochDay(epochDayOf(date)), DateTime(2024, 3, 15));
    });

    test('consecutive civil days differ by exactly 1', () {
      expect(epochDayOf(DateTime(2024, 1, 2)) - epochDayOf(DateTime(2024, 1, 1)),
          1);
    });

    test('DST-safe: spring-forward day is still 1 day apart and round-trips', () {
      // US DST began 2024-03-10. Date-only arithmetic must ignore the 23h day.
      expect(epochDayOf(DateTime(2024, 3, 11)) - epochDayOf(DateTime(2024, 3, 10)),
          1);
      expect(localMidnightFromEpochDay(epochDayOf(DateTime(2024, 3, 10))),
          DateTime(2024, 3, 10));
    });

    test('time-of-day does not affect the epoch-day', () {
      expect(epochDayOf(DateTime(2024, 1, 1, 23, 59)), epochDayOf(DateTime(2024, 1, 1)));
    });
  });

  group('recordGymDay — award gating', () {
    test('not configured → no award, state unchanged', () {
      final res = recordGymDay(
        data: GymStreakData.initial,
        schedule: TrainingSchedule.notConfigured,
        workoutDays: {d(1)},
        today: d(1), // Monday
      );
      expect(res.reward, 0);
      expect(res.data, GymStreakData.initial);
    });

    test('scheduled but no opt-in stays dormant even with workout data', () {
      // Same calendar, schedule simply not configured.
      final res = recordGymDay(
        data: const GymStreakData(currentStreak: 3, lastAwardedEpochDay: 100),
        schedule: const TrainingSchedule(
            isConfigured: false, scheduledWeekdays: {1, 3, 5}),
        workoutDays: {d(1)},
        today: d(1),
      );
      expect(res.reward, 0);
      expect(res.data.currentStreak, 3); // untouched
    });

    test('non-scheduled day → no award, no increment', () {
      final res = recordGymDay(
        data: GymStreakData.initial,
        schedule: mwf,
        workoutDays: {d(2)},
        today: d(2), // Tuesday — not in {Mon,Wed,Fri}
      );
      expect(res.reward, 0);
      expect(res.data, GymStreakData.initial);
    });

    test('second workout the same day awards once (lastAwarded==today)', () {
      final already = GymStreakData(currentStreak: 1, lastAwardedEpochDay: epoch(1));
      final res = recordGymDay(
        data: already,
        schedule: mwf,
        workoutDays: {d(1)},
        today: d(1), // Monday, already awarded today
      );
      expect(res.reward, 0);
      expect(res.data, already);
    });

    test('fresh scheduled day → awards and increments to 1', () {
      final res = recordGymDay(
        data: GymStreakData.initial,
        schedule: mwf,
        workoutDays: {d(1)},
        today: d(1), // Monday
      );
      expect(res.reward, gymDayReward(1)); // 21
      expect(res.data.currentStreak, 1);
      expect(res.data.lastAwardedEpochDay, epoch(1));
    });

    test('consecutive scheduled days increment the streak (rest days skipped)', () {
      // Mon hit → 1
      var state = recordGymDay(
        data: GymStreakData.initial,
        schedule: mwf,
        workoutDays: {d(1)},
        today: d(1),
      ).data;
      expect(state.currentStreak, 1);

      // Wed hit → 2 (Tue was a rest day, doesn't break)
      var step = recordGymDay(
        data: state,
        schedule: mwf,
        workoutDays: {d(1), d(3)},
        today: d(3),
      );
      expect(step.data.currentStreak, 2);
      expect(step.reward, gymDayReward(2));
      state = step.data;

      // Fri hit → 3 (Thu rest day)
      step = recordGymDay(
        data: state,
        schedule: mwf,
        workoutDays: {d(1), d(3), d(5)},
        today: d(5),
      );
      expect(step.data.currentStreak, 3);
      expect(step.reward, gymDayReward(3));
    });
  });

  group('reconcileGymStreak — break detection', () {
    test('not configured → unchanged', () {
      final state = GymStreakData(currentStreak: 4, lastAwardedEpochDay: epoch(1));
      expect(
        reconcileGymStreak(
          data: state,
          schedule: TrainingSchedule.notConfigured,
          workoutDays: const {},
          today: d(8),
        ),
        state,
      );
    });

    test('streak already 0 → no-op (bounds the scan)', () {
      const state = GymStreakData(currentStreak: 0, lastAwardedEpochDay: 1);
      expect(
        reconcileGymStreak(
          data: state,
          schedule: mwf,
          workoutDays: const {},
          today: d(30),
        ),
        state,
      );
    });

    test('missed scheduled day → reset to 0', () {
      // Awarded Mon(1), now it is Fri(5); Wed(3) was a scheduled day with no
      // workout → broken.
      final state = GymStreakData(currentStreak: 1, lastAwardedEpochDay: epoch(1));
      final res = reconcileGymStreak(
        data: state,
        schedule: mwf,
        workoutDays: {d(1)}, // Wed missing
        today: d(5),
      );
      expect(res.currentStreak, 0);
    });

    test('missed only a REST day → streak survives', () {
      // Awarded Mon(1), now Wed(3). Only Tue(2) sits between — a rest day.
      final state = GymStreakData(currentStreak: 1, lastAwardedEpochDay: epoch(1));
      final res = reconcileGymStreak(
        data: state,
        schedule: mwf,
        workoutDays: {d(1)},
        today: d(3),
      );
      expect(res.currentStreak, 1); // unchanged
    });

    test('away several days spanning a scheduled day → reset', () {
      // Awarded Mon(1), gone until next Mon(8): Wed(3) & Fri(5) were missed.
      final state = GymStreakData(currentStreak: 1, lastAwardedEpochDay: epoch(1));
      final res = reconcileGymStreak(
        data: state,
        schedule: mwf,
        workoutDays: {d(1)},
        today: d(8),
      );
      expect(res.currentStreak, 0);
    });

    test('today in progress is never counted as a miss', () {
      // Awarded Wed(3), today is Fri(5) — a scheduled day — with no workout yet.
      // Thu(4) between is a rest day. Fri (today) must NOT count → streak holds.
      final state = GymStreakData(currentStreak: 2, lastAwardedEpochDay: epoch(3));
      final res = reconcileGymStreak(
        data: state,
        schedule: mwf,
        workoutDays: {d(1), d(3)},
        today: d(5),
      );
      expect(res.currentStreak, 2);
    });
  });

  group('end-to-end: break then fresh restart on next scheduled day', () {
    test('Mon, Wed hit; Fri missed; next Mon restarts streak at 1', () {
      // Mon(1) → 1
      var state = recordGymDay(
        data: GymStreakData.initial,
        schedule: mwf,
        workoutDays: {d(1)},
        today: d(1),
      ).data;
      // Wed(3) → 2
      state = recordGymDay(
        data: state,
        schedule: mwf,
        workoutDays: {d(1), d(3)},
        today: d(3),
      ).data;
      expect(state.currentStreak, 2);

      // Fri(5) missed entirely (no workout, no record call).

      // Next Mon(8): finish path reconciles first (Fri missed → reset 0), then
      // increments → fresh streak of 1.
      final next = recordGymDay(
        data: state,
        schedule: mwf,
        workoutDays: {d(1), d(3), d(8)}, // Fri(5) absent
        today: d(8),
      );
      expect(next.data.currentStreak, 1);
      expect(next.reward, gymDayReward(1));
      expect(next.data.lastAwardedEpochDay, epoch(8));
    });
  });
}
