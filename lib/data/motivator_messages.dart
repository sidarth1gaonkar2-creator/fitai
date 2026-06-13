import 'dart:math';

/// Categories of motivational notifications.
///
/// Day-based "missed workout" categories are picked based on how long it's
/// been since the user's last logged session. Intensity (in [NotificationService])
/// controls the FREQUENCY of notifications, not their tone — tone/heat is the
/// same within a category regardless of the Mild/Medium/Savage setting.
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

/// ───────────────────────────────────────────────────────────────────────────
/// FULL METAL gate.
///
/// THE single flip-point for the explicit-language "Full Metal" pool below.
/// While this is `false` the profane pool is UNREACHABLE: [MotivatorMessages
/// .setFullMetal] can never turn it on, the Settings toggle never renders, and
/// the app's effective notification content stays App Store **12+**.
///
/// Flipping this to `true` makes the "Full Metal Mode" toggle appear in
/// Settings and the profane pool selectable per-user. DO NOT flip it without
/// first raising the App Store age rating to **17+** — the Full Metal pool
/// contains hard profanity. No rating config is changed by this file.
///
/// Intentionally a runtime `final` (not `const`): a `const false` would make
/// the `if (kFullMetalEnabled)` guards in the UI provably-dead and trip the
/// analyzer's `dead_code` warning. This is still a single, obvious switch.
/// ───────────────────────────────────────────────────────────────────────────
final bool kFullMetalEnabled = false;

/// A complete notification pool: per-category titles + message bodies.
class _MessagePool {
  const _MessagePool({required this.titles, required this.messages});

  final Map<MotivatorCategory, String> titles;
  final Map<MotivatorCategory, List<String>> messages;
}

/// Message library for the "Drill Sergeant" notification personality.
///
/// Two pools exist: the [_defaultPool] (App Store 12+ safe — aggressive
/// drill-sergeant voice with creative insults but no real profanity) which
/// always ships, and the dormant [_fullMetalPool] (hard profanity, 17+) gated
/// behind [kFullMetalEnabled]. [random] and [titleFor] read whichever pool is
/// active; the active pool is the default unless [setFullMetal] has been called
/// with `true` AND [kFullMetalEnabled] is `true`.
abstract final class MotivatorMessages {
  // ── DEFAULT pool (12+, always shipping) ───────────────────────────────────
  static const _defaultPool = _MessagePool(
    titles: {
      MotivatorCategory.morningMotivation: 'REVEILLE 🎖️',
      MotivatorCategory.missedWorkoutDay1: 'DRILL SGT. 🎖️',
      MotivatorCategory.missedWorkoutDay2: 'DRILL SGT: TWO DAYS',
      MotivatorCategory.missedWorkoutDay3Plus: 'FALL IN — NOW',
      MotivatorCategory.streakCelebration: 'ACCEPTABLE, SOLDIER',
      MotivatorCategory.prCelebration: 'NEW PR, SOLDIER 🎖️',
      MotivatorCategory.weightNotLogged: 'WEIGH-IN, RECRUIT',
      MotivatorCategory.nutritionNotLogged: 'SGT: LOG YOUR CHOW',
    },
    messages: {
      MotivatorCategory.morningMotivation: [
        'ON YOUR FEET, RECRUIT. Daylight is BURNING. MOVE.',
        'OUT OF THE RACK, PRIVATE. Beds are for the WEAK.',
        'REVEILLE, SOLDIER. Eyes open, boots ON. NOW.',
        'RISE AND SHINE, you GLORIFIED throw pillow. MOVE.',
        'DROP THE BLANKET, PRIVATE. Generals do NOT sleep in.',
        'SNOOZE AND LOSE, PRIVATE. Slackers stay PRIVATES forever.',
        'FEET ON THE FLOOR, SOLDIER. VERTICAL in ten. GO.',
        'WAKE UP, SOLDIER, you DECORATIVE house plant. MOVE.',
        'RISE, RECRUIT. The mattress is the ENEMY. ON YOUR FEET.',
        'STAND TALL, PRIVATE. Sleep is for civilians. UP.',
        'DAWN PATROL, you absolute COUCH ORNAMENT. UP. NOW.',
        'EYES OPEN, SOLDIER. Champions are UP. CATCH UP.',
      ],
      MotivatorCategory.missedWorkoutDay1: [
        "BACK ON THE LINE, RECRUIT. One day off and you're RUSTING.",
        'ONE DAY DOWN, PRIVATE. Do NOT make it two. MOVE.',
        'ATTENTION, SOLDIER. Training was TODAY. GET UP and report.',
        'DROP THE EXCUSES, RECRUIT. Back to work. RIGHT NOW.',
        'EYES UP, PRIVATE. One missed day is how PRIVATES stay PRIVATES.',
        'OFF THAT COUCH, you DECORATIVE house plant. TRAIN. NOW.',
        'REPORT FOR DUTY, RECRUIT. The mission did NOT cancel. MOVE.',
        'STAND UP, you GLORIFIED throw pillow. We march TODAY, PRIVATE.',
        'GET MOVING, PRIVATE. Generals do NOT take days off. NOW.',
        'RECLAIM IT, SOLDIER. One day slipped. EARN it back TODAY.',
        "ON THE LINE, RECRUIT. I've seen WET PAPER with more spine.",
        'NO REST GRANTED, PRIVATE. You missed one. EARN it back. NOW.',
      ],
      MotivatorCategory.missedWorkoutDay2: [
        'TWO DAYS AWOL, RECRUIT. On your FEET. MOVE.',
        'SECOND DAY GONE, PRIVATE. UP, you COUCH ORNAMENT.',
        'GET UP, SOLDIER. That couch is NOT your bunk.',
        'MOVE IT, you DECORATIVE house plant. Day two of NOTHING.',
        'DROP AND TRAIN, RECRUIT. Stay a PRIVATE forever? MOVE.',
        'TWO DAYS WASTED, you GLORIFIED throw pillow. STAND UP.',
        'EYES UP, PRIVATE. Generals do NOT skip two days straight.',
        'REPORT TO THE FLOOR, SOLDIER. Two days of pure RUST.',
        "MARCH NOW, RECRUIT. Keep this up, you'll NEVER make CORPORAL.",
        'OFF THAT SOFA, you PATHETIC sack of EXCUSES. Day TWO.',
        'FIX THIS, PRIVATE. Two missed days is a PATTERN. NOW.',
        "TWICE now, PRIVATE? That's a PATTERN. Break it. MOVE.",
      ],
      MotivatorCategory.missedWorkoutDay3Plus: [
        'THREE DAYS AWOL, RECRUIT. This is a DISGRACE. MOVE.',
        'WASHING OUT, PRIVATE. You are THIS close. MOVE IT.',
        'REPORT FOR DUTY, SOLDIER. I will STRIP your rank to ZERO.',
        'THE BARRACKS REEKS of quit, you DECORATIVE house plant. UP.',
        'DROP AND TRAIN, RECRUIT. Three days. You DISGUST this unit.',
        'FALL IN NOW, PRIVATE. Generals do NOT hide under blankets.',
        'ATTENTION, SOLDIER. You\'ll wash OUT before you make CORPORAL.',
        'MARCH, you GLORIFIED throw pillow. Three days of pure SHAME.',
        'OUT OF THE RACK, RECRUIT. WET PAPER has more SPINE than you.',
        'TRAIN. NOW. PRIVATE. You want to ROT at the bottom FOREVER?',
        'ON THE LINE, SOLDIER. Three days gone — you are a DISGRACE. 🎖️',
        'ONE MORE DAY AND YOU\'RE DONE, you COUCH ORNAMENT. MOVE, PRIVATE.',
      ],
      MotivatorCategory.streakCelebration: [
        '%d days. ACCEPTABLE, SOLDIER. Now do NOT get soft on me.',
        '%d DAYS straight. Barely passing, RECRUIT. STAY on the grind.',
        '%d days. I\'ll allow it, PRIVATE. Now KILL the comfort. MOVE.',
        '%d-day streak. Decent, SOLDIER. Now go EARN day %n.',
        '%d days logged. Acceptable, RECRUIT. Tomorrow you EARN it again.',
        '%d days. Surprised me, PRIVATE. Now WIPE that grin and MOVE.',
        '%d straight. A flicker of SPINE, RECRUIT. Keep it BURNING.',
        '%d days. Hold the line, SOLDIER. Generals do NOT coast. MOVE.',
        '%d-day run. You\'re earning that stripe, PRIVATE. Don\'t QUIT now.',
        '%d days. Respect, RECRUIT. Slack tomorrow, stay a PRIVATE forever.',
        '%d days standing. Good, SOLDIER. Now PROVE it wasn\'t luck.',
        '%d days. Almost impressive, RECRUIT. ALMOST. ON YOUR FEET. MOVE.',
      ],
      MotivatorCategory.prCelebration: [
        'OUTSTANDING, SOLDIER. New record on the books. NOW do it AGAIN.',
        'LOG IT, RECRUIT. New PR. The iron BOWED. Don\'t get COMFORTABLE.',
        'HEAVIEST lift yet, PRIVATE. Good. CORPORALS do NOT coast.',
        'RECORD SMASHED. Finally some SPINE in you, SOLDIER. MORE.',
        'STAY hungry, RECRUIT. New max logged. Do NOT go soft on me, SOLDIER.',
        'KEEP that bar SCARED, SOLDIER. New best. It FEARED you. Again tomorrow.',
        'ATTACK it again, PRIVATE. New PR. That\'s how a future GENERAL lifts.',
        'OUTSTANDING work, RECRUIT. You moved REAL weight. Now MOVE more.',
        'EARN it again tomorrow, SOLDIER. New record. Pride is EARNED, not given.',
        'HEAVIER than ever, PRIVATE. The COUCH ORNAMENT is GONE. STAY gone.',
        'GET BACK to it, RECRUIT. PR crushed. One rep does NOT make a CORPORAL.',
        'RECOVER and ATTACK again, SOLDIER. New max. RESPECT earned. More tomorrow.',
      ],
      MotivatorCategory.weightNotLogged: [
        'STEP ON THAT SCALE, RECRUIT. NOW. The numbers do not lie and neither do I.',
        'LOG YOUR WEIGHT, PRIVATE. You HIDING from a scale? Pathetic.',
        'ON THE SCALE, SOLDIER. MOVE. Discipline is DATA. Log it.',
        'WEIGH IN OR FALL OUT, RECRUIT. No weight, no rank. Simple math.',
        'REPORT YOUR WEIGHT, PRIVATE. Scared of a NUMBER, you GLORIFIED throw pillow?',
        'FEET ON THE SCALE, SOLDIER. Generals do NOT dodge the weigh-in.',
        'GET ON THAT SCALE, RECRUIT. Only spineless civilians fear the scale.',
        'LOG THE NUMBER, PRIVATE. NOW. Hiding from it won\'t shrink it.',
        'WEIGH-IN, RECRUIT. Keep ducking it and you\'ll stay a PRIVATE forever.',
        'MOUNT THE SCALE, SOLDIER. NOW. You do NOT get to fear your own data.',
        'STEP UP AND WEIGH IN, RECRUIT. Only a COUCH ORNAMENT skips the scale. MOVE.',
        'WEIGHT. LOGGED. TODAY, PRIVATE. The mission tracks numbers, not EXCUSES.',
      ],
      MotivatorCategory.nutritionNotLogged: [
        'LOG YOUR CHOW, RECRUIT. Every calorie gets reported. NOW.',
        'REPORT YOUR RATIONS, PRIVATE. A blank log is a discipline FAILURE.',
        'EYES ON THAT LOG, SOLDIER. You ate. PROVE IT. NOW.',
        'TRACK IT OR DROP, RECRUIT. Mystery meals do NOT make CORPORAL.',
        'OPEN THE LOG, PRIVATE. Every bite ACCOUNTED for. MOVE.',
        'NAME WHAT YOU ATE, SOLDIER. I want it in the LOG. MOVE IT.',
        'LOG THE CHOW NOW, RECRUIT, you GLORIFIED snack drawer.',
        'ACCOUNT FOR EVERY BITE, PRIVATE. Privates who hide food STAY privates.',
        'INTO THE LOG, SOLDIER. I will NOT track your rations FOR you.',
        'REPORT THAT MEAL, RECRUIT, you DECORATIVE chair filler. MOVE IT.',
        'LOG THAT CHOW, PRIVATE. Generals do NOT eat in the SHADOWS.',
        'FILL THAT FOOD LOG, SOLDIER. Empty log, empty EXCUSE. NOW. 🎖️',
      ],
    },
  );

  // ── FULL METAL pool (17+, DORMANT behind [kFullMetalEnabled]) ─────────────
  // Hard profanity in the same drill-sergeant cadence. Guardrails held: NO
  // slurs, NO sexual/gendered degradation — aggression is aimed at laziness and
  // excuses, never at the person. Enabling this REQUIRES a 17+ App Store rating.
  static const _fullMetalPool = _MessagePool(
    titles: {
      MotivatorCategory.morningMotivation: 'REVEILLE 🎖️',
      MotivatorCategory.missedWorkoutDay1: 'DRILL SGT. 🎖️',
      MotivatorCategory.missedWorkoutDay2: 'DRILL SGT. 🎖️',
      MotivatorCategory.missedWorkoutDay3Plus: 'DRILL SGT: FALL IN NOW',
      MotivatorCategory.streakCelebration: 'ACCEPTABLE, SOLDIER',
      MotivatorCategory.prCelebration: 'OUTSTANDING, SOLDIER 🎖️',
      MotivatorCategory.weightNotLogged: 'WEIGH-IN, RECRUIT',
      MotivatorCategory.nutritionNotLogged: 'SGT: LOG YOUR CHOW',
    },
    messages: {
      MotivatorCategory.morningMotivation: [
        'ON YOUR FEET, RECRUIT. NOW. The sun beat you up.',
        'OUT OF THE RACK, PRIVATE. NOW. Generals don\'t sleep in.',
        'REVEILLE, SOLDIER. Feet on the floor in THREE. TWO.',
        'DROP THE PILLOW, RECRUIT. You absolute COUCH ORNAMENT.',
        'UP. UP. UP, PRIVATE. The day STARTED without your lazy ass.',
        'EYES OPEN, SOLDIER. Sleeping in won\'t earn you CORPORAL.',
        'MOVE IT, RECRUIT. I\'ve seen WET PAPER get up faster.',
        'GET UP, PRIVATE. NOW. Or stay a PRIVATE forever.',
        'BOOTS ON, SOLDIER. Morning don\'t wait for HOUSE PLANTS.',
        'GET VERTICAL, RECRUIT. NOW. This is not a damn spa.',
        'WAKE UP, PRIVATE. That mattress won\'t earn your STRIPES.',
        'STAND TO, SOLDIER. Daylight\'s burning and so are your EXCUSES.',
      ],
      MotivatorCategory.missedWorkoutDay1: [
        'ON YOUR FEET, RECRUIT. You skipped a day. Get your ass UP. MOVE.',
        'BACK TO TRAINING, PRIVATE. One day off is one too MANY. NOW.',
        'EYES UP, SOLDIER. You missed yesterday. Fix it TODAY. MOVE OUT.',
        'DROP THE EXCUSES, RECRUIT. You absolute COUCH ORNAMENT. Train. NOW.',
        'MOVE IT, PRIVATE. You want to stay a PRIVATE forever? Get UP.',
        'GET UP, RECRUIT. One skipped day already? Bullshit. Train. NOW.',
        'OFF THAT COUCH, SOLDIER, you GLORIFIED throw pillow. NOW.',
        'REPORT FOR DUTY, PRIVATE. Yesterday was a MISS. Today is NOT optional.',
        'QUIT STALLING, RECRUIT. I\'ve seen DOORMATS with more drive. MOVE.',
        'NO DAY OFF, SOLDIER. Skip again and you\'ll never make CORPORAL. TRAIN.',
        'MOVE, PRIVATE. One missed day is a CRACK in the wall. SEAL IT today.',
        'FALL IN, RECRUIT. You PATHETIC sack of EXCUSES. Back to training. NOW.',
      ],
      MotivatorCategory.missedWorkoutDay2: [
        'TWO DAYS DOWN, RECRUIT. On your damn FEET. This is a PATTERN now.',
        'DAY TWO of nothing, PRIVATE. You LUMP of laundry. MOVE.',
        'UP. NOW. SOLDIER. Two days of EXCUSES and zero damn reps.',
        'STILL ROTTING, RECRUIT? Two days. I can SMELL the laziness.',
        'GET VERTICAL, PRIVATE. Two days down, you GLORIFIED throw pillow.',
        'MOVE IT, you sack of EXCUSES. DAY TWO. Stay a PRIVATE forever, will you?',
        'TWO DAYS GONE, MAGGOT. Generals do NOT skip leg day. ON YOUR FEET.',
        'MOVE, RECRUIT. Keep this shit up and you\'ll NEVER make CORPORAL.',
        'DROP the remote, PRIVATE. Two days of NOTHING. DISGUSTING.',
        'GET UP, you DECORATIVE house plant. DAY TWO. MOVE those boots.',
        'STAND TO, SOLDIER. Two days AWOL from your own damn body. MOVE.',
        'BOOTS ON, RECRUIT. This rot ends NOW. NO more damn bullshit.',
      ],
      MotivatorCategory.missedWorkoutDay3Plus: [
        'THREE DAYS AWOL, RECRUIT. You are a DISGRACE. DROP and TRAIN. NOW.',
        'WASH OUT INCOMING, PRIVATE. Three days of NOTHING. MOVE before I strip your rank.',
        'DESERTER. On your feet, SOLDIER. Three days gone is a damn DISGRACE. GET UP.',
        'THREE DAYS, RECRUIT? You absolute SLUG. PATHETIC. MOVE that body.',
        'MOVE IT, PRIVATE — three days down the SHITTER. You are THIS CLOSE to washing out.',
        'GET OFF THAT COUCH, you DECORATIVE house plant. Three days is a DISGRACE, RECRUIT.',
        'FALL IN, PRIVATE — generals do NOT skip three days. Want to rot a MAGGOT forever?',
        'DROP NOW, SOLDIER — I\'ve seen WET PAPER with more spine. Three days? PATHETIC.',
        'RANK STRIPPED if you blink, RECRUIT. Three days of EXCUSES ends TODAY. FALL IN.',
        'MOVE, you GLORIFIED throw pillow. Three days OUT. LAST warning, PRIVATE.',
        'BOOTS ON NOW, RECRUIT — three days AWOL is a damn DISGRACE. No more bullshit. TRAIN.',
        'ON YOUR FEET, SOLDIER — cut the bullshit. Three days OUT, you WASH OUT at DAY FOUR.',
      ],
      MotivatorCategory.streakCelebration: [
        '%d DAYS straight, SOLDIER. Acceptable. Do NOT go soft on me now.',
        '%d days logged, RECRUIT. Decent. PRIVATES quit at three. Not you.',
        '%d-day streak, PRIVATE. I\'ll allow it. CORPORALS do NOT coast.',
        '%d days, SOLDIER. Barely passing. KEEP MARCHING, do not stop.',
        '%d days, RECRUIT. Fine. Soft is exactly how streaks DIE. Hold the line.',
        '%d straight days, PRIVATE. Noted. Now EARN tomorrow. MOVE.',
        '%d days, SOLDIER. Grudging respect. Generals NEVER skip. Neither do you.',
        '%d days, RECRUIT. Take ONE breath. Now BACK to work. MOVE.',
        '%d-day run, PRIVATE. Not garbage. That\'s a CORPORAL\'s habit. HOLD it.',
        '%d days, SOLDIER. Respect. Break it now and you\'re a RECRUIT again.',
        '%d DAYS, RECRUIT. Unimpressed-ish. Do NOT go soft on me now.',
        '%d days, PRIVATE. Acceptable. COUCH ORNAMENTS never make it this far.',
      ],
      MotivatorCategory.prCelebration: [
        'NEW PR, SOLDIER. That\'s how a RECRUIT earns a damn stripe. AGAIN.',
        'OUTSTANDING, PRIVATE. Heaviest iron you ever moved. NOW do it AGAIN.',
        'HEAVIEST LIFT YET, SOLDIER. THAT is the standard. Don\'t you DARE drop it.',
        'PR SMASHED, RECRUIT. NOW outlift it. The COUCH ORNAMENT you were is DEAD.',
        'RECORD BROKEN, PRIVATE. For ONE rep you weren\'t a LAZY ass. MORE.',
        'HOOAH, SOLDIER. New PR. THAT\'S the spine I been screaming for. Load it HEAVIER.',
        'PERSONAL BEST, RECRUIT. You earned that with SWEAT, not EXCUSES. Earn it TWICE.',
        'NEW MAX, PRIVATE. The old you was a house plant. NOW go BEAT this one.',
        'PR LOGGED, SOLDIER. Best damn lift of your sorry life. NOW go BEAT it tomorrow.',
        'OUTSTANDING WORK, RECRUIT. Generals don\'t stop at ONE record. MOVE, soldier.',
        'RECORD CRUSHED, PRIVATE. Proud? GOOD. NOW bury that number and CHASE the next.',
        'NEW PR, SOLDIER. No shit, that was strong. CHASE CORPORAL. Don\'t go soft now.',
      ],
      MotivatorCategory.weightNotLogged: [
        'ON THE SCALE, RECRUIT. NOW. The numbers do NOT care about your feelings.',
        'STEP ON THAT SCALE, PRIVATE. You hiding from the data, you GLORIFIED throw pillow?',
        'WEIGH IN, SOLDIER. MOVE. Logging the damn number IS the discipline.',
        'LOG YOUR WEIGHT, RECRUIT. NOW. No scale, no progress, you DECORATIVE house plant.',
        'GET ON THE SCALE, PRIVATE. NOW. You scared of one little number? PATHETIC.',
        'REPORT YOUR WEIGHT, SOLDIER. NOW. Generals do NOT dodge the scale.',
        'STEP UP AND WEIGH IN, RECRUIT. Skip it again, you stay a PRIVATE forever.',
        'ON THE SCALE, MAGGOT. MOVE. WET PAPER tracks its weight better than you.',
        'LOG THE NUMBER, PRIVATE. NOW. Hiding from the data is how COWARDS train.',
        'WEIGH IN, RECRUIT. NOW. No bullshit, no hiding. Step on the damn scale.',
        'GET YOUR ASS ON THE SCALE, SOLDIER. The numbers ARE the mission. LOG THEM.',
        'REPORT TO THE SCALE, PRIVATE. NOW. Log your weight, you absolute COUCH ORNAMENT.',
      ],
      MotivatorCategory.nutritionNotLogged: [
        'LOG YOUR CHOW, RECRUIT. Every damn bite gets tracked. No excuses.',
        'EYES ON THE LOG, PRIVATE. Untracked calories are a DISCIPLINE FAILURE. Fix it NOW.',
        'REPORT YOUR RATIONS, SOLDIER. You ate. I want it ON THE BOOKS. MOVE.',
        'WHERE\'S YOUR FOOD LOG, RECRUIT? Empty. PATHETIC. Fill it, double time.',
        'TRACK THAT CHOW, PRIVATE. You think GENERALS guess their macros? LOG IT.',
        'MOVE IT, you DECORATIVE house plant. Your meals are UNLOGGED, RECRUIT. NOW.',
        'ON THE LOG, SOLDIER. Blank entries don\'t build muscle. WRITE IT DOWN. MOVE.',
        'LOG IT, you GLORIFIED throw pillow. Count every calorie or you stay a PRIVATE.',
        'ACCOUNT FOR YOUR CHOW, RECRUIT. No log, no progress. You want CORPORAL or NOT?',
        'QUIT STUFFING YOUR FACE IN THE DARK, PRIVATE. LOG that shit. Right NOW.',
        'TRACK YOUR FUEL, SOLDIER. LOG every bite or stay the LAZY ass you are. MOVE.',
        'FILL THAT FOOD LOG, you absolute COUCH ORNAMENT. Discipline starts on the PLATE. 🎖️',
      ],
    },
  );

  /// Whether the explicit Full Metal pool is currently selected. Only ever true
  /// when BOTH the user opted in AND [kFullMetalEnabled] is true — so while the
  /// gate is closed this stays false and the 12+ pool is always used.
  static bool _fullMetalActive = false;

  /// Select the active pool. The explicit pool can ONLY be activated while
  /// [kFullMetalEnabled] is true (the gate); otherwise this is a no-op and the
  /// 12+ pool stays in force. Called from the drill-sergeant settings layer.
  static void setFullMetal(bool enabled) {
    _fullMetalActive = enabled && kFullMetalEnabled;
  }

  /// Whether the explicit pool is currently the active one (for UI/debug).
  static bool get isFullMetalActive => _fullMetalActive;

  static _MessagePool get _active =>
      _fullMetalActive ? _fullMetalPool : _defaultPool;

  /// Random message from [category]. In [streakCelebration] lines, `%d` is
  /// replaced with [streakCount] (the current streak) and `%n` with
  /// [streakCount] + 1 (the next day to earn). Falls back to a benign command
  /// if a category is somehow empty — keeps the runtime safe.
  static String random(
    MotivatorCategory category, {
    int streakCount = 0,
  }) {
    final pool = _active.messages[category];
    if (pool == null || pool.isEmpty) return 'ON YOUR FEET, RECRUIT. MOVE.';
    final pick = pool[Random().nextInt(pool.length)];
    return pick
        .replaceAll('%d', '$streakCount')
        .replaceAll('%n', '${streakCount + 1}');
  }

  /// Notification title for [category] from the active pool — identifies the
  /// Drill Sergeant character with urgency (never the app name).
  static String titleFor(MotivatorCategory category) {
    return _active.titles[category] ?? 'DRILL SGT. 🎖️';
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
