import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitai/core/utils/scoped_prefs.dart';
import 'package:fitai/providers/auth_provider.dart';
import 'package:fitai/providers/notification_providers.dart';
import 'package:fitai/providers/training_schedule_provider.dart';
import 'package:fitai/providers/unit_system_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 2024-01-01 was a Monday, so Jan 1..7 2024 map cleanly to weekday 1..7.
  DateTime dayOfWeek(int weekday) => DateTime(2024, 1, weekday);

  group('TrainingSchedule.isScheduledGymDay — weekday mapping', () {
    test('every weekday maps Mon=1..Sun=7 with no off-by-one', () {
      // Sanity-check the test fixtures themselves.
      expect(dayOfWeek(1).weekday, DateTime.monday); // 1
      expect(dayOfWeek(7).weekday, DateTime.sunday); // 7

      // A schedule of all seven days is "scheduled" on every weekday.
      const everyDay = TrainingSchedule(
        isConfigured: true,
        scheduledWeekdays: {1, 2, 3, 4, 5, 6, 7},
      );
      for (var wd = 1; wd <= 7; wd++) {
        expect(everyDay.isScheduledGymDay(dayOfWeek(wd)), isTrue,
            reason: 'weekday $wd should be scheduled');
      }
    });

    test('workoutDays [1,3,5] → Mon/Wed/Fri scheduled, others not', () {
      final schedule = TrainingSchedule(
        isConfigured: true,
        scheduledWeekdays: TrainingSchedule.sanitizeWeekdays(const [1, 3, 5]),
      );

      // Monday (1), Wednesday (3), Friday (5) are gym days.
      expect(schedule.isScheduledGymDay(dayOfWeek(1)), isTrue); // Mon
      expect(schedule.isScheduledGymDay(dayOfWeek(3)), isTrue); // Wed
      expect(schedule.isScheduledGymDay(dayOfWeek(5)), isTrue); // Fri

      // Tue (2), Thu (4), Sat (6), Sun (7) are not.
      expect(schedule.isScheduledGymDay(dayOfWeek(2)), isFalse); // Tue
      expect(schedule.isScheduledGymDay(dayOfWeek(4)), isFalse); // Thu
      expect(schedule.isScheduledGymDay(dayOfWeek(6)), isFalse); // Sat
      expect(schedule.isScheduledGymDay(dayOfWeek(7)), isFalse); // Sun
    });

    test('sanitizeWeekdays drops out-of-range values (0, 8, negatives)', () {
      expect(
        TrainingSchedule.sanitizeWeekdays(const [0, 1, 5, 7, 8, -1]),
        {1, 5, 7},
      );
    });
  });

  group('TrainingSchedule.notConfigured', () {
    test('reports no scheduled days for every weekday', () {
      for (var wd = 1; wd <= 7; wd++) {
        expect(TrainingSchedule.notConfigured.isScheduledGymDay(dayOfWeek(wd)),
            isFalse,
            reason: 'not-configured must never report a scheduled day');
      }
      expect(TrainingSchedule.notConfigured.isConfigured, isFalse);
      expect(TrainingSchedule.notConfigured.scheduledWeekdays, isEmpty);
    });

    test('even with gym days present, isConfigured=false yields no gym days', () {
      const sneaky = TrainingSchedule(
        isConfigured: false,
        scheduledWeekdays: {1, 2, 3, 4, 5, 6, 7},
      );
      // Defensive: the gate is isConfigured, not just an empty set.
      for (var wd = 1; wd <= 7; wd++) {
        expect(sneaky.isScheduledGymDay(dayOfWeek(wd)), isFalse);
      }
    });
  });

  group('restDaysToNotificationWeekdays — boundary adapter (1-based → 0-based)', () {
    test('Mon(1) and Sun(7) convert to 0 and 6', () {
      expect(restDaysToNotificationWeekdays({1, 7}), {0, 6});
    });

    test('full week 1..7 maps to 0..6', () {
      expect(
        restDaysToNotificationWeekdays({1, 2, 3, 4, 5, 6, 7}),
        {0, 1, 2, 3, 4, 5, 6},
      );
    });

    test('empty stays empty (the only value restDays ever holds today)', () {
      expect(restDaysToNotificationWeekdays(const <int>{}), isEmpty);
    });

    test('drops out-of-range values before converting', () {
      // 0 and 8 are not valid 1-based weekdays and must not leak through.
      expect(restDaysToNotificationWeekdays({0, 1, 8}), {0});
    });
  });

  group('trainingScheduleProvider — configured-flag gating', () {
    // Providers are uid-scoped (PR-B): pin a signed-in test uid.
    ProviderContainer makeContainer(SharedPreferences prefs) => ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentUserIdProvider.overrideWithValue('u1'),
          ],
        );

    test('not configured by default → notConfigured, no scheduled days', () async {
      SharedPreferences.setMockInitialValues({
        // The notification default exists, but the user never opted in.
        scopedKey('notif_workout_days', 'u1'): jsonEncode([1, 3, 5]),
      });
      final prefs = await SharedPreferences.getInstance();
      final container = makeContainer(prefs);
      addTearDown(container.dispose);

      final schedule = container.read(trainingScheduleProvider);
      expect(schedule.isConfigured, isFalse);
      expect(schedule.scheduledWeekdays, isEmpty);
      // Crucially, the [1,3,5] notification default is NOT inferred as a schedule.
      expect(schedule.isScheduledGymDay(dayOfWeek(1)), isFalse); // Mon
    });

    test('after markConfigured() → reflects workoutDays (Mon/Wed/Fri)', () async {
      SharedPreferences.setMockInitialValues({
        scopedKey('notif_workout_days', 'u1'): jsonEncode([1, 3, 5]),
      });
      final prefs = await SharedPreferences.getInstance();
      final container = makeContainer(prefs);
      addTearDown(container.dispose);

      await container
          .read(trainingScheduleConfiguredProvider.notifier)
          .markConfigured();

      final schedule = container.read(trainingScheduleProvider);
      expect(schedule.isConfigured, isTrue);
      expect(schedule.scheduledWeekdays, {1, 3, 5});
      expect(schedule.isScheduledGymDay(dayOfWeek(1)), isTrue); // Mon
      expect(schedule.isScheduledGymDay(dayOfWeek(2)), isFalse); // Tue
    });

    test('configured flag persists to prefs (uid-scoped) and reset() clears it',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = TrainingScheduleConfiguredNotifier(prefs, 'u1');

      expect(notifier.state, isFalse);
      await notifier.markConfigured();
      expect(notifier.state, isTrue);
      expect(
          prefs.getBool(scopedKey(trainingScheduleConfiguredKey, 'u1')), isTrue);
      // The global (unscoped) key is never written.
      expect(prefs.getBool(trainingScheduleConfiguredKey), isNull);

      // A fresh notifier over the same prefs reads the persisted opt-in —
      // but only for the same account.
      expect(TrainingScheduleConfiguredNotifier(prefs, 'u1').state, isTrue);
      expect(TrainingScheduleConfiguredNotifier(prefs, 'u2').state, isFalse);

      await notifier.reset();
      expect(notifier.state, isFalse);
      expect(prefs.getBool(scopedKey(trainingScheduleConfiguredKey, 'u1')),
          isNull);
    });

    test('signed out: flag is false and markConfigured writes nothing', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = TrainingScheduleConfiguredNotifier(prefs, null);

      expect(notifier.state, isFalse);
      await notifier.markConfigured();
      expect(notifier.state, isFalse);
      expect(prefs.getKeys(), isEmpty); // no anon keys
    });
  });
}
