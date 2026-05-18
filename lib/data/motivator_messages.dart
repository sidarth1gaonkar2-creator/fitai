import 'dart:math';

/// Categories of motivational notifications.
///
/// Day-based "missed workout" categories are picked based on how long it's
/// been since the user's last logged session. Intensity is controlled via the
/// number of notifications scheduled (in [NotificationService]) rather than
/// per-message — every message in a category is roughly the same heat level.
enum MotivatorCategory {
  missedWorkoutDay1,
  missedWorkoutDay2,
  missedWorkoutDay3Plus,
  morningMotivation,
  streakCelebration,
  prCelebration,
  weightNotLogged,
  nutritionNotLogged,
}

/// Hardcoded message library used by the "Drill Sergeant" notification
/// personality. Messages are deliberately a little aggressive but stay shy of
/// the line — punching up at laziness, not at the user as a person.
///
/// Use [MotivatorMessages.random] to pull a message; `%d` tokens in
/// [streakCelebration] are replaced with the current streak count.
abstract final class MotivatorMessages {
  static final Map<MotivatorCategory, List<String>> _messages = {
    MotivatorCategory.missedWorkoutDay1: const [
      'The gym misses you more than your ex does. Get up.',
      'Your muscles are literally shrinking while you read this.',
      'Rest day? You had one yesterday. And the day before.',
      "That couch isn't going to give you abs.",
      'Your future self is judging you right now. Hard.',
      'Netflix will still be there after your workout. Your gains won\'t wait.',
      'Skipping legs again? Bold strategy.',
      "The weights aren't going to lift themselves. Unfortunately.",
      'You opened this app instead of working out. Bold of you.',
    ],
    MotivatorCategory.missedWorkoutDay2: const [
      'Two days without a workout? Your gym membership is crying.',
      'At this rate, your muscles are filing for divorce.',
      'Remember that goal you set? Yeah, it remembers you too. Awkwardly.',
      "The only thing you're building right now is a Netflix watchlist.",
      "Your pre-workout is collecting dust. It's starting to feel abandoned.",
      'Day 2 of rest. Your gains are packing their bags.',
      "Plot twist: the gym didn't close. You just stopped going.",
      'Two days off. Your protein shaker just sighed.',
    ],
    MotivatorCategory.missedWorkoutDay3Plus: const [
      'Three days. THREE. Your muscles have officially ghosted you.',
      'At this point your gym shoes are a decorative item.',
      "Your streak didn't die of natural causes. You murdered it.",
      'The iron is cold. Your excuses are not.',
      'Somewhere, someone weaker than you is working out right now.',
      'Your body is a temple. Right now it\'s a temple of laziness.',
      "Fun fact: champions don't take 3-day breaks. Get. Up.",
      'Your barbell called. It wants to file a missing-persons report.',
    ],
    MotivatorCategory.morningMotivation: const [
      'Rise and grind. Literally. The gym opens in 30 minutes.',
      'Your alarm went off for a reason. That reason is gains.',
      'Good morning! Your muscles are hungry. Feed them iron.',
      'The early bird gets the gains. The late bird gets nothing.',
      "Coffee is step 1. The gym is step 2. Excuses aren't a step.",
      'Today is leg day. Or push day. Or any day. Just go.',
    ],
    MotivatorCategory.streakCelebration: const [
      "Alright fine, I'll admit it — you're kind of impressive. %d days straight.",
      '%d days in a row? OK maybe you\'re not completely hopeless after all.',
      'Streak: %d days. Your consistency is almost annoying. Keep going.',
      '%d-day streak! Even I\'m a little proud. Don\'t let it go to your head.',
      '%d days. Look at you. Not quitting. Weird new behaviour from you.',
    ],
    MotivatorCategory.prCelebration: const [
      'NEW PR! See what happens when you actually show up?',
      'PR CRUSHED. Remember this feeling next time you want to skip.',
      'Look at you, breaking records like you break excuses.',
      'New PR. Proof that effort beats vibes every single time.',
    ],
    MotivatorCategory.weightNotLogged: const [
      'Step on the scale. Knowledge is power. Avoiding it is weakness.',
      "The scale won't bite. Your excuses will though.",
      "Weigh-in time. The number doesn't define you, but tracking it does.",
      'Skipping the scale again? The data gap is doing you no favours.',
    ],
    MotivatorCategory.nutritionNotLogged: const [
      "You ate today but didn't log it? Suspicious.",
      "Untracked calories still count. Your body doesn't have a cheat code.",
      'Log your food. Your macros are waiting. Impatiently.',
      "Mystery meal? Your spreadsheet wants answers.",
    ],
  };

  /// Random message from [category]. `%d` tokens (currently only in
  /// [MotivatorCategory.streakCelebration]) are replaced with [streakCount].
  ///
  /// Falls back to a benign message if the category is somehow empty, which
  /// shouldn't happen but keeps the runtime safe.
  static String random(
    MotivatorCategory category, {
    int streakCount = 0,
  }) {
    final pool = _messages[category];
    if (pool == null || pool.isEmpty) return 'Time to move. Get up.';
    final pick = pool[Random().nextInt(pool.length)];
    return pick.replaceAll('%d', '$streakCount');
  }

  /// Picks the appropriate "missed workout" message category for the number
  /// of days since the last session. 0 means "worked out today" — callers
  /// should not invoke this; they get a generic morning message instead.
  static MotivatorCategory missedCategoryFor(int daysSinceWorkout) {
    if (daysSinceWorkout <= 1) return MotivatorCategory.missedWorkoutDay1;
    if (daysSinceWorkout == 2) return MotivatorCategory.missedWorkoutDay2;
    return MotivatorCategory.missedWorkoutDay3Plus;
  }
}
