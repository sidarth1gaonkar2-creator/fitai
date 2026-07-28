import '../data/retention_messages.dart';

/// Pure planning core for the drill-sergeant retention campaign
/// (feature/retention-notifications). NO Flutter / plugin imports — all
/// eligibility, the 2/day cap, quiet-hours clamping, drill de-dupe, and the
/// Recall hard-stop state machine live here so they are unit-testable without
/// a device. The reconciler gathers a [RetentionSnapshot] from providers,
/// calls [RetentionPlanner], and hands the result to NotificationService.

// ─── Notification ids (retention band 1000-1099; clear of all existing
//     bands — see report_notification_audit.txt F5) ────────────────────────
const int kRetStreakDefenseId = 1000;
const int kRetRankPushId = 1001;
const int kRetStandDownId = 1002;
const int kRetRecallDay3Id = 1010;
const int kRetRecallDay7Id = 1011;

/// Every retention id, for a clean cancel-all-retention sweep.
const List<int> kRetentionIds = [
  kRetStreakDefenseId,
  kRetRankPushId,
  kRetStandDownId,
  kRetRecallDay3Id,
  kRetRecallDay7Id,
];

// ─── Deep-link routes (shell sub-routes ONLY — the go_router cross-shell
//     safe pattern; see report_notification_audit.txt F3) ─────────────────
const String kRouteDashboard = '/dashboard';
const String kRouteWorkouts = '/workouts';

/// The only routes a notification tap may navigate to. Plain shell sub-routes
/// reached via context.go — never a standalone route, never a push from
/// outside the shell. The tap handler validates payloads against this set.
const Set<String> kRetentionAllowedRoutes = {
  kRouteDashboard,
  kRouteWorkouts,
  '/nutrition',
  '/progress',
};

// ─── Quiet hours 21:00–07:00 → allowed slot hours are [7, 20] ──────────────
const int kQuietStartHour = 21; // 21:00 and later is quiet
const int kQuietEndHour = 7; // before 07:00 is quiet

/// Clamp an (hour, minute) into the 07:00–21:00 window. Out-of-window times
/// move to the nearest boundary INSIDE the window (never silently into quiet
/// hours). All designed slots (10:00/17:00/18:00/19:30) already comply; this
/// exists as a guard and is unit-tested.
({int hour, int minute}) clampToQuietHours(int hour, int minute) {
  if (hour < kQuietEndHour) return (hour: kQuietEndHour, minute: 0); // → 07:00
  if (hour >= kQuietStartHour) return (hour: 20, minute: 59); // → 20:59
  return (hour: hour, minute: minute);
}

/// How close the user is to the next overall rank. DrillFit ranks are
/// strength-based: overallPoints is a continuous 0–9 value whose FLOOR is the
/// current rank index, so the fractional part is progress toward the next
/// rank. [fractionToNext] in [0,1); [atMax] true at the top rank.
class RankProximity {
  const RankProximity({
    required this.nextRankName,
    required this.fractionToNext,
    required this.atMax,
  });

  final String nextRankName;
  final double fractionToNext;
  final bool atMax;

  /// "Final stretch" to the next rank — the last 10% of the way. Chosen so
  /// Rank Push fires only when a promotion is genuinely within reach.
  static const double nearThreshold = 0.9;

  bool get isNear => !atMax && fractionToNext >= nearThreshold;
}

/// Everything the planner needs for TODAY's decision. Pure inputs, gathered
/// by the reconciler.
class RetentionSnapshot {
  const RetentionSnapshot({
    required this.drillEnabled,
    required this.intensity,
    required this.now,
    required this.streak,
    required this.workedOutToday,
    required this.trainingWeekdays,
    required this.restWeekdays,
    required this.drillSlotHours,
    this.rank,
  });

  /// Master gate: the existing Drill Sergeant switch. When false the campaign
  /// produces NOTHING (Decision 1: gate under the sergeant, no new toggle).
  final bool drillEnabled;

  /// DrillSergeantPrefs.intensity (1/2/3) — selects the copy tone tier.
  final int intensity;

  final DateTime now;
  final int streak;
  final bool workedOutToday;

  /// 1-based weekdays (1=Mon…7=Sun). trainingWeekdays = the user's scheduled
  /// gym days (NotificationSettings.workoutDays); restWeekdays =
  /// NotificationSettings.restDays.
  final Set<int> trainingWeekdays;
  final Set<int> restWeekdays;

  /// Hours the drill sergeant already occupies today (de-dupe target so a
  /// retention slot never stacks in the same hour as a roast).
  final List<int> drillSlotHours;

  final RankProximity? rank;

  bool get isTrainingDay => trainingWeekdays.contains(now.weekday);
  bool get isRestDay => restWeekdays.contains(now.weekday);
}

/// A fully-resolved notification the reconciler should schedule TODAY.
class RetentionPlanned {
  const RetentionPlanned({
    required this.id,
    required this.campaign,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
    required this.route,
  });

  final int id;
  final RetentionCampaign campaign;
  final int hour;
  final int minute;
  final String title;
  final String body;
  final String route;
}

/// Internal candidate before cap/clamp/de-dupe.
class _Candidate {
  const _Candidate(this.id, this.campaign, this.hour, this.minute, this.route);
  final int id;
  final RetentionCampaign campaign;
  final int hour;
  final int minute;
  final String route;
}

abstract final class RetentionPlanner {
  /// Max retention notifications per calendar day (HARD LIMIT).
  static const int maxPerDay = 2;

  /// TODAY's same-day campaigns (A Streak Defense, B Rank Push, C Stand-Down),
  /// in priority order, quiet-hours-clamped, de-duped against drill slots, and
  /// capped at [maxPerDay]. Recall (D1/D2) is future-dated and handled
  /// separately (see [recallDay3Fire]/[recallDay7Fire]). Returns [] when the
  /// Drill Sergeant is off.
  static List<RetentionPlanned> planToday(RetentionSnapshot s) {
    if (!s.drillEnabled) return const [];

    // Priority order: Streak Defense > Rank Push > Stand-Down.
    final candidates = <_Candidate>[];

    // A — Streak Defense: a live streak, no workout yet, on a scheduled gym
    // day that isn't a rest day. 19:30.
    if (s.streak >= 1 &&
        !s.workedOutToday &&
        s.isTrainingDay &&
        !s.isRestDay) {
      candidates.add(const _Candidate(kRetStreakDefenseId,
          RetentionCampaign.streakDefense, 19, 30, kRouteWorkouts));
    }

    // B — Rank Push: within the final stretch to the next rank, not trained
    // today. 17:00. Routes to /dashboard (rank card is there; /ranks is a
    // standalone route — Decision 3).
    if (s.rank != null && s.rank!.isNear && !s.workedOutToday) {
      candidates.add(const _Candidate(
          kRetRankPushId, RetentionCampaign.rankPush, 17, 0, kRouteDashboard));
    }

    // C — Stand-Down: rest-day positive reinforcement (the anti-nag balance).
    // Only when there's a streak worth protecting. 10:00.
    if (s.isRestDay && s.streak >= 1) {
      candidates.add(const _Candidate(kRetStandDownId,
          RetentionCampaign.standDown, 10, 0, kRouteDashboard));
    }

    final out = <RetentionPlanned>[];
    for (final c in candidates) {
      if (out.length >= maxPerDay) break; // 2/day cap
      final t = clampToQuietHours(c.hour, c.minute);
      // De-dupe: never stack a retention slot in a drill-roast hour.
      if (s.drillSlotHours.contains(t.hour)) continue;
      final copy = RetentionMessages.copyFor(
        c.campaign,
        s.intensity,
        streak: s.streak,
        nextRank: s.rank?.nextRankName ?? '',
      );
      out.add(RetentionPlanned(
        id: c.id,
        campaign: c.campaign,
        hour: t.hour,
        minute: t.minute,
        title: copy.title,
        body: copy.body,
        route: c.route,
      ));
    }
    return out;
  }

  /// Copy for a recall notification at the given intensity.
  static RetentionCopy recallCopy(RetentionCampaign campaign, int intensity) =>
      RetentionMessages.copyFor(campaign, intensity);

  /// Recall fire times, anchored to app-DARKNESS: [openBaseline] is the user's
  /// last app-open. D1 fires 3 days of darkness later at 18:00, D2 at 7 days.
  /// Anchoring to darkness (not days-since-workout) is deliberate — a user who
  /// opens daily but hasn't lifted isn't "lapsed" (that's Streak Defense's
  /// job); any app-open pushes these out, making "app-open resets" literal.
  static DateTime recallDay3Fire(DateTime openBaseline) =>
      _atSixPm(openBaseline, 3);
  static DateTime recallDay7Fire(DateTime openBaseline) =>
      _atSixPm(openBaseline, 7);

  static DateTime _atSixPm(DateTime base, int addDays) {
    final d = base.add(Duration(days: addDays));
    return DateTime(d.year, d.month, d.day, 18, 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Recall hard-stop state machine (lapsed re-engagement stops after 2 unanswered)
// ─────────────────────────────────────────────────────────────────────────

/// Persisted recall accounting. [unanswered] is 0/1/2; at 2, [exhausted] is
/// true and no further recall fires for this dark period.
class RetentionRecallState {
  const RetentionRecallState({this.unanswered = 0, this.exhausted = false});

  final int unanswered;
  final bool exhausted;

  static const RetentionRecallState initial = RetentionRecallState();

  @override
  bool operator ==(Object other) =>
      other is RetentionRecallState &&
      other.unanswered == unanswered &&
      other.exhausted == exhausted;

  @override
  int get hashCode => Object.hash(unanswered, exhausted);
}

abstract final class RetentionRecall {
  /// 72-hour answer window for the FINAL (D2) recall.
  static const Duration d2AnswerWindow = Duration(hours: 72);

  /// An app-open ENDS the lapse: it resets the counter AND the exhausted flag
  /// (Phase-3 required behavior). The reconciler re-baselines darkness to the
  /// open time separately.
  static RetentionRecallState onAppOpen() => RetentionRecallState.initial;

  /// Concrete "unanswered" definitions (Phase-3 required):
  ///   * D1 is unanswered if NO app-open occurred before D2's fire time —
  ///     determinable once [now] has reached d2Fire.
  ///   * D2 is unanswered if NO app-open occurred within 72h of D2 firing —
  ///     determinable once [now] is past d2Fire + 72h.
  /// exhausted ⇔ both D1 and D2 unanswered (count reaches 2).
  ///
  /// [lastAppOpenAt] is the most recent app-open (null = never since the dark
  /// period began). Times are compared in whatever zone the caller passes.
  static RetentionRecallState evaluate({
    required DateTime d1Fire,
    required DateTime d2Fire,
    required DateTime now,
    DateTime? lastAppOpenAt,
  }) {
    final d1Answered = lastAppOpenAt != null &&
        !lastAppOpenAt.isBefore(d1Fire) &&
        lastAppOpenAt.isBefore(d2Fire);

    final d2Deadline = d2Fire.add(d2AnswerWindow);
    final d2Answered = lastAppOpenAt != null &&
        !lastAppOpenAt.isBefore(d2Fire) &&
        !lastAppOpenAt.isAfter(d2Deadline);

    // D1 becomes judgeable at D2's fire time; D2 after its 72h window closes.
    final d1Unanswered = !now.isBefore(d2Fire) && !d1Answered;
    final d2Unanswered = now.isAfter(d2Deadline) && !d2Answered;

    final count = (d1Unanswered ? 1 : 0) + (d2Unanswered ? 1 : 0);
    return RetentionRecallState(
      unanswered: count,
      exhausted: d1Unanswered && d2Unanswered,
    );
  }
}
