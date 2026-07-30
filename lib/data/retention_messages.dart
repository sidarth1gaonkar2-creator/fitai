/// Copy for the drill-sergeant RETENTION campaigns (feature/retention-
/// notifications). Separate from [MotivatorMessages] (motivator_messages.dart)
/// on purpose: the existing drill pools have NO per-intensity tone variants —
/// intensity there controls frequency only. Retention copy is authored as
/// three tone tiers (Mild / Medium / Full Savage) selected by the SAME
/// DrillSergeantPrefs.intensity dial. Stays in the shipping 12+ register; the
/// gated 17+ "Full Metal" pool is never touched here.
///
/// Pure Dart, no Flutter imports — imported directly by the planner and its
/// unit tests.
library;

/// The retention campaigns. IDs live in NotificationService (1000-band).
enum RetentionCampaign {
  streakDefense, // A — streak dies tonight on a scheduled training day
  rankPush, // B — one push from the next rank
  standDown, // C — rest-day positive reinforcement (anti-nag balance)
  recallDay3, // D1 — 3 days dark
  recallDay7, // D2 — 7 days dark (final; hard-stops the recall sequence)
}

/// One resolved line: a glanceable title (<35 chars) and a compact body
/// (<90 chars), already personalized.
class RetentionCopy {
  const RetentionCopy(this.title, this.body);
  final String title;
  final String body;
}

/// One authored tier before personalization (placeholders intact).
class _Tier {
  const _Tier(this.title, this.body);
  final String title;
  final String body;
}

/// Message library. Each campaign carries exactly three tiers, index
/// 0 = Mild Roast, 1 = Medium Roast, 2 = Full Savage — matching intensity
/// 1/2/3. Placeholders: {streak} (current streak), {nextRank} (next rank
/// display name). Recall lines bake the day count into the wording, so no
/// {days} placeholder is needed.
abstract final class RetentionMessages {
  static const Map<RetentionCampaign, List<_Tier>> _pool = {
    RetentionCampaign.streakDefense: [
      _Tier('Streak on the line',
          'Day {streak} is still standing. Log a workout tonight to keep it alive.'),
      _Tier("Don't break formation",
          "{streak} days, soldier. Skip tonight and it's gone. Get one in."),
      _Tier('Streak dies at midnight',
          '{streak} days — gone unless you move. MOVE, soldier.'),
    ],
    RetentionCampaign.rankPush: [
      _Tier('Almost there',
          'One good session and {nextRank} is yours. Go earn the stripe.'),
      _Tier('{nextRank} is in range',
          "You're one workout from {nextRank}, soldier. Don't stall now."),
      _Tier('Earn it or don\'t',
          '{nextRank} is RIGHT THERE. One session. Quit stalling and take it.'),
    ],
    RetentionCampaign.standDown: [
      _Tier('Stand down, soldier',
          "Rest day. Recovery is training too — you've earned it. Back at it tomorrow."),
      _Tier('Recovery is orders',
          'Rest day, soldier. Muscle is built resting. Refuel and report back tomorrow.'),
      _Tier('Rest is an order',
          'Rest day means REST, soldier. Recover hard, come back HARDER. Dismissed.'),
    ],
    RetentionCampaign.recallDay3: [
      _Tier("Where'd you go, soldier?",
          "3 days dark. The gym misses you. Fall back in when you're ready."),
      _Tier('3 days AWOL',
          'Three days off the grid, soldier. Time to report back for duty.'),
      _Tier('AWOL: 3 days',
          "3 days GONE, soldier. This unit doesn't quit. Get back on the line."),
    ],
    RetentionCampaign.recallDay7: [
      _Tier('Last call, soldier',
          "A week out. My last shout — the door's still open when you are."),
      _Tier('Final recall',
          '7 days AWOL. Last time I call your name, soldier. Make it count.'),
      _Tier('Final recall — 7 days',
          'A week GONE. Last call, soldier. Answer it or I stand down for good.'),
    ],
  };

  /// Resolve copy for [campaign] at [intensity] (1/2/3, clamped), filling
  /// {streak} and {nextRank}. Tone tier = intensity - 1.
  static RetentionCopy copyFor(
    RetentionCampaign campaign,
    int intensity, {
    int streak = 0,
    String nextRank = '',
  }) {
    final tiers = _pool[campaign]!;
    final idx = (intensity.clamp(1, 3)) - 1;
    final t = tiers[idx];
    String fill(String s) => s
        .replaceAll('{streak}', '$streak')
        .replaceAll('{nextRank}', nextRank);
    return RetentionCopy(fill(t.title), fill(t.body));
  }
}
