import '../../../data/exercise_library.dart';
import '../../../models/enums.dart';
import 'strength_calculator.dart';

/// The six muscle groups the ranking system aggregates into. Distinct from the
/// app's finer-grained [MuscleGroup] enum — these are the buckets the overall
/// rank is composed from.
enum RankGroup { chest, back, legs, shoulders, arms, core }

extension RankGroupLabel on RankGroup {
  String get label => switch (this) {
        RankGroup.chest => 'Chest',
        RankGroup.back => 'Back',
        RankGroup.legs => 'Legs',
        RankGroup.shoulders => 'Shoulders',
        RankGroup.arms => 'Arms',
        RankGroup.core => 'Core',
      };
}

/// Strength standard for one exercise: the 10 allometric rank thresholds plus
/// the metadata the aggregator needs.
class ExerciseStandard {
  const ExerciseStandard({
    required this.thresholds,
    required this.group,
    required this.isCompound,
    this.weightMultiplier = 1.0,
    this.rankable = true,
  });

  /// 10 allometric score cut-offs, one per [MilitaryRank].
  final List<double> thresholds;

  /// Which of the six ranking groups this exercise feeds.
  final RankGroup group;

  /// Compound lifts count 2× in a muscle group's weighted average; isolation
  /// movements count 1×.
  final bool isCompound;

  /// Converts a stored PR into total load moved. 2.0 for two-dumbbell
  /// movements (the app stores weight "per dumbbell"); 1.0 for barbell,
  /// machine, cable, and single-implement work.
  final double weightMultiplier;

  /// False for bodyweight / cardio / time-based movements that carry no
  /// external-load signal — these are skipped entirely by the calculator.
  final bool rankable;
}

// ─── Shared threshold sets (allometric scores) ──────────────────────────────
// The five primary compounds + secondary + isolation sets from the spec.
const _squat = [3.0, 4.5, 6.0, 7.0, 8.0, 9.5, 11.0, 12.5, 14.0, 16.0];
const _deadlift = [3.5, 5.0, 6.5, 7.5, 8.5, 10.0, 11.5, 13.0, 15.0, 17.0];
const _bench = [2.5, 3.5, 5.0, 6.0, 7.0, 8.0, 9.5, 11.0, 12.5, 14.0];
const _ohp = [1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 11.0];
const _row = [2.0, 3.0, 4.5, 5.5, 6.5, 7.5, 8.5, 10.0, 11.5, 13.0];
const _rdl = [2.5, 3.5, 5.0, 6.0, 7.0, 8.0, 9.0, 10.5, 12.0, 13.5];
const _legPress = [4.0, 6.0, 8.0, 9.5, 11.0, 12.5, 14.0, 16.0, 18.0, 20.0];
const _inclineDb = [1.5, 2.5, 3.5, 4.5, 5.0, 6.0, 7.0, 8.0, 9.0, 10.5];
const _latPulldown = [2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.5];
const _curl = [1.0, 1.5, 2.5, 3.0, 3.5, 4.5, 5.0, 6.0, 7.0, 8.0];
const _pushdown = [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.5, 5.0, 6.0, 7.0];
const _lateralRaise = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 5.0, 6.0];
const _calfRaise = [2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0];
const _facePull = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.5];

// Generic fallbacks for exercises without bespoke standards (spec §3):
// push = bench×0.7, pull = row×0.7, lower = squat×0.7, isolation = curl.
const _pushGeneric = [1.75, 2.45, 3.5, 4.2, 4.9, 5.6, 6.65, 7.7, 8.75, 9.8];
const _pullGeneric = [1.4, 2.1, 3.15, 3.85, 4.55, 5.25, 5.95, 7.0, 8.05, 9.1];
const _lowerGeneric = [2.1, 3.15, 4.2, 4.9, 5.6, 6.65, 7.7, 8.75, 9.8, 11.2];

// The threshold sets above were calibrated against RAW top-set weight. Scoring
// now runs on estimated 1RM, so every threshold is scaled by
// [kCalibrationE1rmFactor] (the 5-rep Epley factor) before use — this keeps a
// ~5-rep working lifter at the same rank as before. The raw numbers are kept
// literal above so the original calibration stays legible.
List<double> _cal(List<double> raw) =>
    [for (final v in raw) v * kCalibrationE1rmFactor];

// Convenience builders to keep the table readable.
ExerciseStandard _c(List<double> t, RankGroup g, {double mult = 1.0}) =>
    ExerciseStandard(thresholds: _cal(t), group: g, isCompound: true, weightMultiplier: mult);
ExerciseStandard _i(List<double> t, RankGroup g, {double mult = 1.0}) =>
    ExerciseStandard(thresholds: _cal(t), group: g, isCompound: false, weightMultiplier: mult);
ExerciseStandard _skip(RankGroup g) =>
    ExerciseStandard(thresholds: _cal(_curl), group: g, isCompound: false, rankable: false);

/// Per-exercise standards keyed by the library's exercise **id**. Covers every
/// exercise in [exerciseLibrary]; anything else resolves through the muscle-
/// group generic fallback in [standardForExercise].
final Map<String, ExerciseStandard> exerciseStandards = {
  // ── Chest ──────────────────────────────────────────────────────────────
  'barbell_bench_press': _c(_bench, RankGroup.chest),
  'incline_barbell_bench_press': _c(_bench, RankGroup.chest),
  'decline_barbell_bench_press': _c(_bench, RankGroup.chest),
  'dumbbell_bench_press': _c(_bench, RankGroup.chest, mult: 2.0),
  'incline_dumbbell_press': _c(_inclineDb, RankGroup.chest, mult: 2.0),
  'dumbbell_fly': _i(_curl, RankGroup.chest, mult: 2.0),
  'cable_crossover': _i(_curl, RankGroup.chest),
  'push_up': _skip(RankGroup.chest),
  'chest_dip': _skip(RankGroup.chest),
  'machine_chest_press': _c(_bench, RankGroup.chest),
  'incline_dumbbell_fly': _i(_curl, RankGroup.chest, mult: 2.0),

  // ── Back ───────────────────────────────────────────────────────────────
  'conventional_deadlift': _c(_deadlift, RankGroup.back),
  'barbell_bent_over_row': _c(_row, RankGroup.back),
  'pull_up': _skip(RankGroup.back),
  'chin_up': _skip(RankGroup.back),
  'lat_pulldown': _c(_latPulldown, RankGroup.back),
  'seated_cable_row': _c(_row, RankGroup.back),
  'single_arm_dumbbell_row': _c(_row, RankGroup.back), // single DB → ×1
  't_bar_row': _c(_row, RankGroup.back),
  'cable_pullover': _i(_curl, RankGroup.back),
  'barbell_shrug': _i(_row, RankGroup.back),
  'dumbbell_shrug': _i(_row, RankGroup.back, mult: 2.0),
  'sumo_deadlift': _c(_deadlift, RankGroup.back),
  'deficit_deadlift': _c(_deadlift, RankGroup.back),
  'pendlay_row': _c(_row, RankGroup.back),
  'meadows_row': _c(_row, RankGroup.back),
  'dumbbell_pullover': _i(_curl, RankGroup.back), // single DB → ×1
  'inverted_row': _skip(RankGroup.back),

  // ── Legs ───────────────────────────────────────────────────────────────
  'barbell_back_squat': _c(_squat, RankGroup.legs),
  'front_squat': _c(_squat, RankGroup.legs),
  'leg_press': _c(_legPress, RankGroup.legs),
  'romanian_deadlift': _c(_rdl, RankGroup.legs),
  'leg_curl': _i(_calfRaise, RankGroup.legs),
  'leg_extension': _i(_calfRaise, RankGroup.legs),
  'walking_lunge': _c(_lowerGeneric, RankGroup.legs, mult: 2.0),
  'bulgarian_split_squat': _c(_lowerGeneric, RankGroup.legs, mult: 2.0),
  'calf_raise': _i(_calfRaise, RankGroup.legs),
  'seated_calf_raise': _i(_calfRaise, RankGroup.legs),
  'hack_squat': _c(_squat, RankGroup.legs),
  'hip_thrust': _c(_legPress, RankGroup.legs),
  'goblet_squat': _c(_lowerGeneric, RankGroup.legs), // single DB/KB → ×1
  'kettlebell_goblet_squat': _c(_lowerGeneric, RankGroup.legs),
  'kettlebell_swing': _c(_lowerGeneric, RankGroup.legs),
  'good_morning': _c(_rdl, RankGroup.legs),
  'step_up': _c(_lowerGeneric, RankGroup.legs, mult: 2.0),
  'hip_thrust_machine': _c(_legPress, RankGroup.legs),
  'hip_adductor_machine': _i(_calfRaise, RankGroup.legs),
  'hip_abductor_machine': _i(_calfRaise, RankGroup.legs),
  'power_clean': _c(_lowerGeneric, RankGroup.legs),
  'snatch': _c(_lowerGeneric, RankGroup.legs),
  'thruster': _c(_lowerGeneric, RankGroup.legs),
  'sissy_squat': _skip(RankGroup.legs),
  'glute_ham_raise': _skip(RankGroup.legs),
  'box_jump': _skip(RankGroup.legs),

  // ── Shoulders ──────────────────────────────────────────────────────────
  'overhead_press': _c(_ohp, RankGroup.shoulders),
  'dumbbell_lateral_raise': _i(_lateralRaise, RankGroup.shoulders, mult: 2.0),
  'front_raise': _i(_lateralRaise, RankGroup.shoulders, mult: 2.0),
  'rear_delt_fly': _i(_lateralRaise, RankGroup.shoulders, mult: 2.0),
  'arnold_press': _c(_ohp, RankGroup.shoulders, mult: 2.0),
  'upright_row': _c(_ohp, RankGroup.shoulders),
  'face_pull': _i(_facePull, RankGroup.shoulders), // spec groups face pulls → shoulders
  'cable_lateral_raise': _i(_lateralRaise, RankGroup.shoulders),
  'landmine_press': _c(_ohp, RankGroup.shoulders),
  'seated_dumbbell_shoulder_press': _c(_ohp, RankGroup.shoulders, mult: 2.0),
  'reverse_fly_machine': _i(_lateralRaise, RankGroup.shoulders),
  'band_pull_apart': _skip(RankGroup.shoulders),

  // ── Arms (biceps + triceps + forearms) ─────────────────────────────────
  'barbell_curl': _i(_curl, RankGroup.arms),
  'dumbbell_curl': _i(_curl, RankGroup.arms, mult: 2.0),
  'hammer_curl': _i(_curl, RankGroup.arms, mult: 2.0),
  'preacher_curl': _i(_curl, RankGroup.arms),
  'concentration_curl': _i(_curl, RankGroup.arms), // single DB → ×1
  'cable_curl': _i(_curl, RankGroup.arms),
  'incline_dumbbell_curl': _i(_curl, RankGroup.arms, mult: 2.0),
  'spider_curl': _i(_curl, RankGroup.arms, mult: 2.0),
  'zottman_curl': _i(_curl, RankGroup.arms, mult: 2.0),
  'tricep_pushdown': _i(_pushdown, RankGroup.arms),
  'skull_crusher': _i(_pushdown, RankGroup.arms),
  'overhead_tricep_extension': _i(_pushdown, RankGroup.arms),
  'close_grip_bench_press': _c(_bench, RankGroup.arms),
  'tricep_dip': _skip(RankGroup.arms),
  'tricep_kickback': _i(_pushdown, RankGroup.arms),
  'cable_overhead_tricep_extension': _i(_pushdown, RankGroup.arms),
  'wrist_curl': _i(_pushdown, RankGroup.arms),
  'reverse_wrist_curl': _i(_pushdown, RankGroup.arms),
  'farmers_walk': _c(_row, RankGroup.arms, mult: 2.0),

  // ── Core ───────────────────────────────────────────────────────────────
  'cable_crunch': _i(_curl, RankGroup.core),
  'plank': _skip(RankGroup.core),
  'crunch': _skip(RankGroup.core),
  'hanging_leg_raise': _skip(RankGroup.core),
  'russian_twist': _skip(RankGroup.core),
  'ab_wheel_rollout': _skip(RankGroup.core),
  'mountain_climber': _skip(RankGroup.core),
  'dead_bug': _skip(RankGroup.core),
  'bicycle_crunch': _skip(RankGroup.core),
  'pallof_press': _skip(RankGroup.core),
  'dragon_flag': _skip(RankGroup.core),
  'turkish_get_up': _skip(RankGroup.core),

  // ── Cardio (never rankable) ────────────────────────────────────────────
  'running_treadmill': _skip(RankGroup.legs),
  'cycling_stationary': _skip(RankGroup.legs),
  'rowing_machine': _skip(RankGroup.back),
  'jump_rope': _skip(RankGroup.legs),
  'stair_climber': _skip(RankGroup.legs),
  'swimming': _skip(RankGroup.back),
  'elliptical': _skip(RankGroup.legs),
  'battle_ropes': _skip(RankGroup.shoulders),
  'burpee': _skip(RankGroup.legs),
};

/// Maps the app's fine-grained [MuscleGroup] onto a [RankGroup]. Returns null
/// for muscles that don't belong to a ranked group (cardio).
RankGroup? rankGroupForMuscle(MuscleGroup muscle) {
  switch (muscle) {
    case MuscleGroup.chest:
      return RankGroup.chest;
    case MuscleGroup.upperBack:
    case MuscleGroup.lats:
    case MuscleGroup.lowerBack:
      return RankGroup.back;
    case MuscleGroup.quads:
    case MuscleGroup.hamstrings:
    case MuscleGroup.glutes:
    case MuscleGroup.calves:
      return RankGroup.legs;
    case MuscleGroup.shoulders:
      return RankGroup.shoulders;
    case MuscleGroup.biceps:
    case MuscleGroup.triceps:
    case MuscleGroup.forearms:
      return RankGroup.arms;
    case MuscleGroup.abs:
    case MuscleGroup.obliques:
      return RankGroup.core;
    case MuscleGroup.cardio:
      return null;
  }
}

/// Generic standard for a [RankGroup] when no bespoke entry exists — used for
/// custom / off-library exercises (spec §3 fallback).
ExerciseStandard _genericForGroup(RankGroup group) {
  switch (group) {
    case RankGroup.chest:
      return _c(_pushGeneric, RankGroup.chest);
    case RankGroup.back:
      return _c(_pullGeneric, RankGroup.back);
    case RankGroup.legs:
      return _c(_lowerGeneric, RankGroup.legs);
    case RankGroup.shoulders:
      return _c(_pushGeneric, RankGroup.shoulders);
    case RankGroup.arms:
      return _i(_curl, RankGroup.arms);
    case RankGroup.core:
      return _i(_curl, RankGroup.core);
  }
}

/// Resolves a strength standard for a logged exercise. Tries the explicit
/// table by id, then by resolving the [name] through the library, then falls
/// back to a generic standard derived from [muscleGroup]. Returns null only
/// when nothing identifies a rankable group (e.g. a cardio-only PR).
ExerciseStandard? standardForExercise({
  String? id,
  String? name,
  MuscleGroup? muscleGroup,
}) {
  // 1. Direct id hit.
  if (id != null) {
    final direct = exerciseStandards[id];
    if (direct != null) return direct;
  }
  // 2. Resolve the name/id through the library, then look up by canonical id.
  final def = lookupExercise(id: id, name: name);
  if (def != null) {
    final byLibId = exerciseStandards[def.id];
    if (byLibId != null) return byLibId;
    // Library knows it but it's not in the table — derive a group from its
    // primary muscle and use the generic standard.
    final primary = def.primaryMuscles.isNotEmpty ? def.primaryMuscles.first : null;
    final group = primary != null ? rankGroupForMuscle(primary) : null;
    if (group != null) return _genericForGroup(group);
  }
  // 3. Last resort: the PR's stored muscle group.
  if (muscleGroup != null) {
    final group = rankGroupForMuscle(muscleGroup);
    if (group != null) return _genericForGroup(group);
  }
  return null;
}
