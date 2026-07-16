import 'dart:math';

import 'exercise_standards.dart';
import 'military_ranks.dart';

/// Drill-sergeant flavour copy. Personality lives in MESSAGES only — no fonts,
/// colours, or layout change anywhere. Centralised so the voice stays
/// consistent across the dashboard, workout-completion, streaks, and ranks.

/// Random praise shown after a workout is saved.
const List<String> kWorkoutPraiseLines = [
  "SOLID WORK, SOLDIER! That's how it's done.",
  "NOT BAD, RECRUIT. But there's always tomorrow.",
  'OUTSTANDING! The drill sergeant approves.',
  'MISSION ACCOMPLISHED. Rest up and report back.',
  "THAT'S WHAT I LIKE TO SEE! Dismissed.",
];

final Random _rng = Random();

String randomWorkoutPraise() =>
    kWorkoutPraiseLines[_rng.nextInt(kWorkoutPraiseLines.length)];

/// Celebration shown when a workout earns a promotion to a higher rank.
String promotionMessage(MilitaryRank rank) =>
    "ATTENTION! You've been promoted to ${rank.displayName}!";

/// Drill-sergeant line on the full-screen rank-up celebration overlay.
String promotionCelebrationLine() =>
    "Outstanding work, soldier! You've earned your stripes.";

/// Push-notification text prepared (but NOT yet sent) on a rank-up — a scaffold
/// for the future notifications implementation. Format mirrors the spec, e.g.
/// "ATTENTION! You've been promoted to Sergeant (E5). Report for duty, soldier!"
String rankUpNotificationText(MilitaryRank rank) =>
    "ATTENTION! You've been promoted to ${rank.displayName} (E${rank.tier}). "
    'Report for duty, soldier!';

/// Time-of-day greeting that addresses the soldier by their rank.
///
/// [compact] (for the dashboard nav bar, which is tight on width) uses the
/// rank ABBREVIATION and drops the trailing motivational clause so it fits on
/// one line; pass a first name only to keep it short.
String drillGreeting({
  required int hour,
  required MilitaryRank rank,
  required String name,
  bool compact = false,
}) {
  if (compact) {
    final who = '${rank.abbreviation} $name';
    if (hour < 12) return 'Rise and shine, $who';
    if (hour < 17) return 'Get after it, $who';
    return 'One more set, $who';
  }
  final title = rank.displayName;
  if (hour < 12) return 'Rise and shine, $title $name! Time to earn your rank.';
  if (hour < 17) return 'No slacking off, $title $name. Get after it.';
  return "Day's not over yet, $title $name. One more set.";
}

/// First name only — keeps the dashboard greeting from overflowing with long
/// full names. Falls back to the whole string if there's no whitespace.
String firstNameOf(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed.split(RegExp(r'\s+')).first;
}

/// Streak milestone line for the highest threshold reached (7 / 14 / 30 days),
/// or null below 7 days.
String? streakMilestone(int streak) {
  if (streak >= 30) return '30 days! The drill sergeant salutes you.';
  if (streak >= 14) return "Two weeks! You're earning respect, soldier.";
  if (streak >= 7) return "One week strong! Don't break formation!";
  return null;
}

const Map<RankGroup, String> _weakPointLines = {
  RankGroup.legs:
      'Your legs are lagging behind, soldier! Time to hit the squat rack!',
  RankGroup.arms: 'Arms need work, recruit. Drop and give me 20 curls!',
  RankGroup.chest: 'Chest is falling behind your back. More bench press!',
  RankGroup.back:
      'Your back is slacking, soldier. Get on those rows and pull-ups!',
  RankGroup.shoulders: "Weak shoulders won't cut it, recruit. Press overhead!",
  RankGroup.core: 'A soldier needs a rock-solid core. Lock it in!',
};

/// "Drill Sergeant Says" assessment of the weakest muscle group. Balanced when
/// every trained group is within one rank of the others; prompts for more data
/// when fewer than two groups have been trained.
String weakPointMessage(Map<RankGroup, double> groupPoints) {
  if (groupPoints.length < 2) {
    return 'Log more lifts so I can size you up, recruit.';
  }
  final sorted = groupPoints.values.toList()..sort();
  final spread = sorted.last - sorted.first;
  if (spread <= 1.0) {
    return 'Balanced physique, soldier. Keep it up!';
  }
  RankGroup weakest = groupPoints.keys.first;
  var lowest = double.infinity;
  groupPoints.forEach((group, points) {
    if (points < lowest) {
      lowest = points;
      weakest = group;
    }
  });
  return _weakPointLines[weakest] ?? 'Keep grinding, soldier.';
}
