/// A "zone" on the body silhouette where a muscle's highlight glow gets
/// painted. All coordinates are relative to the widget bounds (0..1).
///
/// `cx` and `cy` are the centre of the oval, `rx`/`ry` are the radii. When
/// `cx` differs from 0.5, the painter automatically mirrors the oval to
/// (1 - cx, cy) so paired muscles (biceps, quads, calves, etc.) render on
/// both sides.
class MuscleZone {
  const MuscleZone(this.cx, this.cy, this.rx, this.ry);

  final double cx;
  final double cy;
  final double rx;
  final double ry;

  /// Whether this zone should be mirrored to the opposite side of the
  /// silhouette. True when the zone is positioned off the centre line.
  bool get mirrored => (cx - 0.5).abs() > 0.05;
}

enum BodySide { front, back }

/// Maps normalised muscle names to drawing zones on either the front or
/// back silhouette. The two maps are intentionally separate so the painter
/// can pick the right view by side rather than juggling a tag per entry.
///
/// Coordinates were tuned against a vertically-tall silhouette (aspect ~ 1:2)
/// — the painter compresses to whatever box it's given.
abstract final class MuscleMap {
  static const Map<String, MuscleZone> frontZones = {
    // ── Upper body ────────────────────────────────────────────
    'pectorals':       MuscleZone(0.50, 0.22, 0.18, 0.06),
    'chest':           MuscleZone(0.50, 0.22, 0.18, 0.06),
    'deltoids':        MuscleZone(0.50, 0.18, 0.28, 0.03),
    'biceps':          MuscleZone(0.22, 0.30, 0.05, 0.06),
    'triceps':         MuscleZone(0.22, 0.32, 0.04, 0.06),
    'forearms':        MuscleZone(0.18, 0.40, 0.04, 0.06),
    // ── Core ──────────────────────────────────────────────────
    'abs':             MuscleZone(0.50, 0.34, 0.10, 0.10),
    'abdominals':      MuscleZone(0.50, 0.34, 0.10, 0.10),
    'obliques':        MuscleZone(0.50, 0.34, 0.14, 0.08),
    'serratus':        MuscleZone(0.50, 0.30, 0.16, 0.04),
    // ── Lower body ────────────────────────────────────────────
    'hip flexors':     MuscleZone(0.50, 0.46, 0.10, 0.04),
    'adductors':       MuscleZone(0.50, 0.52, 0.06, 0.08),
    'quadriceps':      MuscleZone(0.50, 0.56, 0.12, 0.12),
    'quads':           MuscleZone(0.50, 0.56, 0.12, 0.12),
    'calves':          MuscleZone(0.50, 0.76, 0.08, 0.08),
    'tibialis':        MuscleZone(0.50, 0.78, 0.06, 0.05),
  };

  static const Map<String, MuscleZone> backZones = {
    // ── Upper back ────────────────────────────────────────────
    'trapezius':       MuscleZone(0.50, 0.16, 0.14, 0.05),
    'traps':           MuscleZone(0.50, 0.16, 0.14, 0.05),
    'rear deltoids':   MuscleZone(0.50, 0.18, 0.28, 0.03),
    'rhomboids':       MuscleZone(0.50, 0.22, 0.08, 0.05),
    'lats':            MuscleZone(0.50, 0.28, 0.16, 0.08),
    'latissimus dorsi':MuscleZone(0.50, 0.28, 0.16, 0.08),
    'lower back':      MuscleZone(0.50, 0.38, 0.08, 0.05),
    'erector spinae':  MuscleZone(0.50, 0.36, 0.06, 0.08),
    // ── Arms (back view) ──────────────────────────────────────
    'triceps back':    MuscleZone(0.22, 0.32, 0.04, 0.06),
    // ── Glutes / hams / calves ────────────────────────────────
    'glutes':          MuscleZone(0.50, 0.46, 0.14, 0.06),
    'gluteus maximus': MuscleZone(0.50, 0.46, 0.14, 0.06),
    'hamstrings':      MuscleZone(0.50, 0.58, 0.10, 0.10),
    'calves':          MuscleZone(0.50, 0.76, 0.08, 0.08),
    'gastrocnemius':   MuscleZone(0.50, 0.76, 0.08, 0.08),
  };

  /// Lowercase → canonical zone key. Folds ExerciseDB's anatomical sub-
  /// divisions (e.g. "pectoralis major clavicular head") onto the simpler
  /// muscle-group buckets the silhouette has zones for.
  static const Map<String, String> _aliases = {
    'pectoralis major': 'pectorals',
    'pectoralis major clavicular head': 'pectorals',
    'pectoralis major sternal head': 'pectorals',
    'pec': 'pectorals',
    'pecs': 'pectorals',
    'deltoid anterior': 'deltoids',
    'deltoid lateral': 'deltoids',
    'deltoid posterior': 'rear deltoids',
    'rear delt': 'rear deltoids',
    'rear delts': 'rear deltoids',
    'front delt': 'deltoids',
    'front delts': 'deltoids',
    'side delt': 'deltoids',
    'side delts': 'deltoids',
    'shoulder': 'deltoids',
    'shoulders': 'deltoids',
    'biceps brachii': 'biceps',
    'bicep': 'biceps',
    'brachialis': 'biceps',
    'triceps brachii': 'triceps',
    'tricep': 'triceps',
    'rectus abdominis': 'abs',
    'abdominal': 'abs',
    'rectus femoris': 'quadriceps',
    'vastus lateralis': 'quadriceps',
    'vastus medialis': 'quadriceps',
    'vastus intermedius': 'quadriceps',
    'quad': 'quadriceps',
    'gluteus maximus': 'glutes',
    'gluteus medius': 'glutes',
    'glute': 'glutes',
    'latissimus dorsi': 'lats',
    'lat': 'lats',
    'erector spinae': 'lower back',
    'spinal erector': 'lower back',
    'gastrocnemius': 'calves',
    'soleus': 'calves',
    'calf': 'calves',
    'calve': 'calves',
    'brachioradialis': 'forearms',
    'wrist flexors': 'forearms',
    'wrist extensors': 'forearms',
    'forearm': 'forearms',
    'serratus anterior': 'serratus',
    'tensor fasciae latae': 'hip flexors',
    'iliopsoas': 'hip flexors',
    'hip flexor': 'hip flexors',
    'semitendinosus': 'hamstrings',
    'semimembranosus': 'hamstrings',
    'biceps femoris': 'hamstrings',
    'hamstring': 'hamstrings',
    'infraspinatus': 'rear deltoids',
    'teres major': 'lats',
    'teres minor': 'rear deltoids',
    'levator scapulae': 'traps',
    'upper back': 'traps',
    'trap': 'traps',
    'upper trap': 'traps',
    'mid trap': 'traps',
    'lower trap': 'traps',
    'oblique': 'obliques',
    'shin': 'tibialis',
    'tibialis anterior': 'tibialis',
    'core': 'abs',
  };

  /// Normalises an ExerciseDB-shaped muscle name to a zone key, lowercasing
  /// and folding aliases. Returns the lowercased input when no alias hits
  /// — that way the caller can still look it up in [frontZones] /
  /// [backZones] directly.
  static String normalize(String name) {
    final lower = name.toLowerCase().trim();
    return _aliases[lower] ?? lower;
  }

  /// Convenience — returns the zone for [name] on either body side. Front
  /// is tried first, then back.
  static (BodySide, MuscleZone)? zoneFor(String name) {
    final key = normalize(name);
    final f = frontZones[key];
    if (f != null) return (BodySide.front, f);
    final b = backZones[key];
    if (b != null) return (BodySide.back, b);
    return null;
  }

  /// Whether any of the supplied muscle names resolve to the given side.
  /// Lets the widget hide the back panel when there's nothing to draw on it.
  static bool hasMusclesOnSide(List<String> names, BodySide side) {
    for (final n in names) {
      final hit = zoneFor(n);
      if (hit != null && hit.$1 == side) return true;
    }
    return false;
  }
}
