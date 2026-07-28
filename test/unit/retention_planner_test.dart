import 'package:flutter_test/flutter_test.dart';

import 'package:fitai/data/retention_messages.dart';
import 'package:fitai/providers/retention_planner.dart';

/// A Monday (weekday == 1) at 09:00 — the fixed "now" for eligibility tests.
final _monday = DateTime(2026, 1, 5, 9, 0);

RetentionSnapshot _snap({
  bool drillEnabled = true,
  int intensity = 3,
  int streak = 5,
  bool workedOutToday = false,
  Set<int> trainingWeekdays = const {1}, // Monday
  Set<int> restWeekdays = const {},
  List<int> drillSlotHours = const [],
  RankProximity? rank,
  DateTime? now,
}) {
  return RetentionSnapshot(
    drillEnabled: drillEnabled,
    intensity: intensity,
    now: now ?? _monday,
    streak: streak,
    workedOutToday: workedOutToday,
    trainingWeekdays: trainingWeekdays,
    restWeekdays: restWeekdays,
    drillSlotHours: drillSlotHours,
    rank: rank,
  );
}

const _nearRank =
    RankProximity(nextRankName: 'Corporal', fractionToNext: 0.95, atMax: false);

void main() {
  group('gate', () {
    test('Drill Sergeant off → nothing scheduled', () {
      final out = RetentionPlanner.planToday(_snap(drillEnabled: false));
      expect(out, isEmpty);
    });
  });

  group('Streak Defense (A)', () {
    test('eligible: streak>0, no workout today, training day, not rest day', () {
      final out = RetentionPlanner.planToday(_snap());
      expect(out, hasLength(1));
      final n = out.single;
      expect(n.campaign, RetentionCampaign.streakDefense);
      expect(n.id, kRetStreakDefenseId);
      expect(n.hour, 19);
      expect(n.minute, 30);
      expect(n.route, kRouteWorkouts); // deep-links to /workouts
    });

    test('not scheduled if worked out today', () {
      expect(RetentionPlanner.planToday(_snap(workedOutToday: true)), isEmpty);
    });

    test('not scheduled with no streak', () {
      expect(RetentionPlanner.planToday(_snap(streak: 0)), isEmpty);
    });

    test('not scheduled off a scheduled training day', () {
      // Monday now, but user trains only Fridays.
      expect(
          RetentionPlanner.planToday(_snap(trainingWeekdays: const {5})),
          isEmpty);
    });

    test('suppressed if the day is also a rest day', () {
      final out = RetentionPlanner.planToday(
          _snap(trainingWeekdays: const {1}, restWeekdays: const {1}));
      expect(out.where((n) => n.campaign == RetentionCampaign.streakDefense),
          isEmpty);
    });
  });

  group('Rank Push (B)', () {
    test('eligible only in the final stretch and routes to /dashboard', () {
      // Not a training day (avoid Streak Defense), rank near.
      final out = RetentionPlanner.planToday(
          _snap(trainingWeekdays: const {5}, rank: _nearRank));
      expect(out, hasLength(1));
      expect(out.single.campaign, RetentionCampaign.rankPush);
      expect(out.single.hour, 17);
      expect(out.single.route, kRouteDashboard); // /ranks is standalone → /dashboard
    });

    test('not near enough → not scheduled', () {
      const notNear = RankProximity(
          nextRankName: 'Corporal', fractionToNext: 0.5, atMax: false);
      expect(
          RetentionPlanner.planToday(
              _snap(trainingWeekdays: const {5}, rank: notNear)),
          isEmpty);
    });

    test('at max rank → never scheduled even at fraction 0', () {
      const maxed = RankProximity(
          nextRankName: '', fractionToNext: 0.99, atMax: true);
      expect(
          RetentionPlanner.planToday(
              _snap(trainingWeekdays: const {5}, rank: maxed)),
          isEmpty);
    });
  });

  group('Stand-Down (C) — rest-day positive, not a roast', () {
    test('fires on a rest day with a streak, positive copy, /dashboard', () {
      final out = RetentionPlanner.planToday(
          _snap(trainingWeekdays: const {5}, restWeekdays: const {1}));
      expect(out, hasLength(1));
      final n = out.single;
      expect(n.campaign, RetentionCampaign.standDown);
      expect(n.hour, 10);
      expect(n.route, kRouteDashboard);
      // Positive reinforcement, not an aggressive roast.
      expect(n.body.toLowerCase(), contains('rest day'));
      expect(n.body, isNot(contains('AWOL')));
    });
  });

  group('HARD LIMITS', () {
    test('2/day cap — Streak Defense + Rank Push both eligible = exactly 2', () {
      final out = RetentionPlanner.planToday(_snap(rank: _nearRank));
      expect(out.length, lessThanOrEqualTo(RetentionPlanner.maxPerDay));
      expect(out.length, 2);
      expect(out.map((n) => n.campaign),
          containsAll([
            RetentionCampaign.streakDefense,
            RetentionCampaign.rankPush
          ]));
    });

    test('quiet-hours clamp keeps every slot inside 07:00–21:00', () {
      expect(clampToQuietHours(6, 0), (hour: 7, minute: 0));
      expect(clampToQuietHours(22, 15), (hour: 20, minute: 59));
      expect(clampToQuietHours(10, 0), (hour: 10, minute: 0));
      expect(clampToQuietHours(19, 30), (hour: 19, minute: 30));
    });

    test('de-dupe: a retention slot in a drill-roast hour is dropped', () {
      // Streak Defense is 19:30; block hour 19 with a drill roast.
      final out = RetentionPlanner.planToday(_snap(drillSlotHours: const [19]));
      expect(out, isEmpty);
    });
  });

  group('intensity → copy tone tier', () {
    test('planToday selects the tier from intensity', () {
      final mild = RetentionPlanner.planToday(_snap(intensity: 1)).single;
      final savage = RetentionPlanner.planToday(_snap(intensity: 3)).single;
      expect(mild.title, 'Streak on the line');
      expect(savage.title, 'Streak dies at midnight');
    });

    test('{streak} is personalized and the two approved edits are present', () {
      final savage =
          RetentionPlanner.planToday(_snap(intensity: 3, streak: 12)).single;
      // A-Savage body edit.
      expect(savage.body, '12 days — gone unless you move. MOVE, soldier.');
      // B-Savage title edit.
      final b = RetentionMessages.copyFor(RetentionCampaign.rankPush, 3);
      expect(b.title, "Earn it or don't");
    });
  });

  group('deep-link routes are shell-safe', () {
    test('every planned route is in the allowed shell sub-route set', () {
      final out = RetentionPlanner.planToday(_snap(rank: _nearRank));
      for (final n in out) {
        expect(kRetentionAllowedRoutes, contains(n.route));
      }
    });
  });
}
