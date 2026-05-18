/// Maps the app's local exercise display names to the lowercase search term
/// that gives the best ExerciseDB v1 hit.
///
/// ExerciseDB convention: lowercase, "equipment first" (e.g. "barbell bench
/// press", "dumbbell incline bench press", "cable lat pulldown"). Where the
/// local name already matches that shape lowercased, no override is needed
/// — [searchTermFor] falls back to `localName.toLowerCase()`.
abstract final class ExerciseNameMap {
  static const Map<String, String> _overrides = {
    // ── Chest ─────────────────────────────────────────────────
    'Barbell Bench Press': 'barbell bench press',
    'Flat Barbell Bench Press': 'barbell bench press',
    'Incline Barbell Bench Press': 'barbell incline bench press',
    'Decline Barbell Bench Press': 'barbell decline bench press',
    'Dumbbell Bench Press': 'dumbbell bench press',
    'Incline Dumbbell Press': 'dumbbell incline bench press',
    'Incline Dumbbell Fly': 'dumbbell incline fly',
    'Dumbbell Fly': 'dumbbell fly',
    'Cable Crossover': 'cable crossover',
    'Cable Fly': 'cable crossover',
    'Machine Chest Press': 'machine chest press',
    'Chest Dip': 'chest dip',
    'Push Up': 'push up',
    'Dumbbell Pullover': 'dumbbell pullover',
    'Cable Pullover': 'cable pullover',
    'Close Grip Bench Press': 'barbell close grip bench press',

    // ── Back ──────────────────────────────────────────────────
    'Barbell Bent Over Row': 'barbell bent over row',
    'Barbell Row': 'barbell bent over row',
    'Pendlay Row': 'barbell pendlay row',
    'T-Bar Row': 't bar row',
    'Seated Cable Row': 'cable seated row',
    'Single Arm Dumbbell Row': 'dumbbell one arm row',
    'Meadows Row': 'landmine meadows row',
    'Lat Pulldown': 'cable lat pulldown',
    'Pull Up': 'pull up',
    'Chin Up': 'chin up',
    'Inverted Row': 'inverted row',
    'Face Pull': 'cable face pull',
    'Rear Delt Fly': 'dumbbell rear delt fly',
    'Reverse Fly Machine': 'machine rear delt fly',

    // ── Deadlifts ─────────────────────────────────────────────
    'Conventional Deadlift': 'barbell deadlift',
    'Romanian Deadlift': 'barbell romanian deadlift',
    'Sumo Deadlift': 'barbell sumo deadlift',
    'Deficit Deadlift': 'barbell deficit deadlift',

    // ── Shoulders ─────────────────────────────────────────────
    'Overhead Press': 'barbell overhead press',
    'Seated Dumbbell Shoulder Press': 'dumbbell seated shoulder press',
    'Dumbbell Shoulder Press': 'dumbbell shoulder press',
    'Arnold Press': 'dumbbell arnold press',
    'Landmine Press': 'barbell landmine press',
    'Lateral Raise': 'dumbbell lateral raise',
    'Dumbbell Lateral Raise': 'dumbbell lateral raise',
    'Cable Lateral Raise': 'cable lateral raise',
    'Front Raise': 'dumbbell front raise',
    'Upright Row': 'barbell upright row',
    'Band Pull Apart': 'band pull apart',
    'Barbell Shrug': 'barbell shrug',
    'Dumbbell Shrug': 'dumbbell shrug',

    // ── Biceps ────────────────────────────────────────────────
    'Barbell Curl': 'barbell curl',
    'Dumbbell Curl': 'dumbbell bicep curl',
    'Hammer Curl': 'dumbbell hammer curl',
    'Incline Dumbbell Curl': 'dumbbell incline curl',
    'Preacher Curl': 'barbell preacher curl',
    'Cable Curl': 'cable curl',
    'Concentration Curl': 'dumbbell concentration curl',
    'Spider Curl': 'dumbbell spider curl',
    'Zottman Curl': 'dumbbell zottman curl',
    'Bicep Curl': 'barbell curl',

    // ── Triceps ───────────────────────────────────────────────
    'Tricep Pushdown': 'cable pushdown',
    'Cable Overhead Tricep Extension': 'cable overhead triceps extension',
    'Overhead Tricep Extension': 'dumbbell overhead triceps extension',
    'Skull Crusher': 'barbell lying triceps extension',
    'Tricep Dip': 'triceps dip',
    'Tricep Kickback': 'dumbbell kickback',

    // ── Quads / legs ──────────────────────────────────────────
    'Barbell Back Squat': 'barbell full squat',
    'Barbell Squat': 'barbell full squat',
    'Front Squat': 'barbell front squat',
    'Hack Squat': 'machine hack squat',
    'Goblet Squat': 'dumbbell goblet squat',
    'Kettlebell Goblet Squat': 'kettlebell goblet squat',
    'Bulgarian Split Squat': 'dumbbell bulgarian split squat',
    'Sissy Squat': 'sissy squat',
    'Leg Press': 'sled leg press',
    'Leg Extension': 'lever leg extension',
    'Step Up': 'dumbbell step up',
    'Walking Lunge': 'dumbbell walking lunge',
    'Lunge': 'dumbbell lunge',

    // ── Hamstrings / glutes ───────────────────────────────────
    'Leg Curl': 'lever lying leg curl',
    'Glute Ham Raise': 'glute ham raise',
    'Hip Thrust': 'barbell hip thrust',
    'Good Morning': 'barbell good morning',
    'Hip Abductor Machine': 'machine hip abductor',
    'Hip Adductor Machine': 'machine hip adductor',

    // ── Calves ────────────────────────────────────────────────
    'Calf Raise': 'standing calf raise',
    'Seated Calf Raise': 'seated calf raise',

    // ── Forearms / wrists ─────────────────────────────────────
    'Wrist Curl': 'barbell wrist curl',
    'Reverse Wrist Curl': 'barbell reverse wrist curl',

    // ── Core ──────────────────────────────────────────────────
    'Plank': 'front plank',
    'Crunch': 'crunch',
    'Bicycle Crunch': 'bicycle crunch',
    'Cable Crunch': 'cable crunch',
    'Russian Twist': 'russian twist',
    'Hanging Leg Raise': 'hanging leg raise',
    'Ab Wheel Rollout': 'ab wheel rollout',
    'Pallof Press': 'cable pallof press',
    'Dead Bug': 'dead bug',
    'Dragon Flag': 'dragon flag',

    // ── Olympic / power / conditioning ────────────────────────
    'Power Clean': 'barbell power clean',
    'Snatch': 'barbell snatch',
    'Thruster': 'barbell thruster',
    'Turkish Get Up': 'kettlebell turkish get up',
    'Kettlebell Swing': 'kettlebell swing',
    'Box Jump': 'box jump',
    'Burpee': 'burpee',
    'Mountain Climber': 'mountain climber',
    'Jump Rope': 'jump rope',
    'Battle Ropes': 'battle ropes',
    'Running (Treadmill)': 'treadmill running',
    'Cycling (Stationary)': 'stationary bike',
    'Elliptical': 'elliptical machine',
    'Rowing Machine': 'rowing machine',
    'Stair Climber': 'stair mill',
    'Swimming': 'swimming',
  };

  /// Returns the ExerciseDB-friendly search term for [localName]. Falls
  /// back to a lowercased copy of the input when no explicit override is
  /// defined — works fine for many local names that already match the API
  /// convention after lowercasing.
  static String searchTermFor(String localName) {
    final override = _overrides[localName];
    if (override != null) return override;
    return localName.toLowerCase();
  }

  /// How many local exercises have an explicit override entry. Useful for
  /// reporting / test fixtures.
  static int get overrideCount => _overrides.length;
}
