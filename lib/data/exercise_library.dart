import 'package:flutter/foundation.dart' show debugPrint;

import '../models/enums.dart';

/// Look up an exercise in [exerciseLibrary] by id or name, with several
/// fallbacks. Returns `null` and logs a `[muscle-lookup]` warning when none
/// of the strategies match — that warning is the user-facing signal when
/// the muscle diagram looks empty/wrong for a specific exercise.
///
/// Strategies, in order:
///   1. Exact id match (e.g. `'barbell_bench_press'`)
///   2. Case-insensitive name match (e.g. `'Barbell Bench Press'`)
///   3. Slugified-name fallback — strips spaces/punct and lowercases, so
///      stored values like `'Barbell-Bench-Press'` or `'barbell bench press'`
///      still resolve when the canonical id is `'barbell_bench_press'`
///
/// The slugified fallback catches the edge case where a workout was logged
/// from a template a long time ago, the name in Isar drifted from the
/// library's display name, and an id wasn't stored alongside it.
ExerciseDefinition? lookupExercise({String? id, String? name}) {
  if (id != null && id.isNotEmpty) {
    for (final e in exerciseLibrary) {
      if (e.id == id) return e;
    }
  }
  if (name != null && name.isNotEmpty) {
    final lower = name.toLowerCase().trim();
    for (final e in exerciseLibrary) {
      if (e.name.toLowerCase() == lower) return e;
    }
    final slug = _slug(lower);
    for (final e in exerciseLibrary) {
      if (_slug(e.name.toLowerCase()) == slug) return e;
      if (_slug(e.id) == slug) return e;
    }
  }
  debugPrint(
    '[muscle-lookup] no library match for id=$id name=$name '
    '— diagram will skip this exercise',
  );
  return null;
}

String _slug(String s) {
  final buf = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    if (RegExp(r'[a-z0-9]').hasMatch(ch)) buf.write(ch);
  }
  return buf.toString();
}

class ExerciseDefinition {
  const ExerciseDefinition({
    required this.id,
    required this.name,
    required this.primaryMuscles,
    this.secondaryMuscles = const [],
    required this.equipment,
    required this.instructions,
    required this.difficulty,
  });

  final String id;
  final String name;
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final ExerciseEquipment equipment;
  final List<String> instructions;
  final ExerciseDifficulty difficulty;
}

List<ExerciseDefinition> filterExercises({
  String query = '',
  MuscleGroup? muscleGroup,
  ExerciseEquipment? equipment,
  ExerciseDifficulty? difficulty,
}) {
  final q = query.toLowerCase();
  return exerciseLibrary.where((e) {
    final matchesQuery = q.isEmpty || e.name.toLowerCase().contains(q);
    final matchesMuscle = muscleGroup == null ||
        e.primaryMuscles.contains(muscleGroup) ||
        e.secondaryMuscles.contains(muscleGroup);
    final matchesEquipment = equipment == null || e.equipment == equipment;
    final matchesDifficulty = difficulty == null || e.difficulty == difficulty;
    return matchesQuery && matchesMuscle && matchesEquipment && matchesDifficulty;
  }).toList();
}

const List<ExerciseDefinition> exerciseLibrary = [
  // ---------------------------------------------------------------------------
  // CHEST (10)
  // ---------------------------------------------------------------------------
  ExerciseDefinition(
    id: 'barbell_bench_press',
    name: 'Barbell Bench Press',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.shoulders, MuscleGroup.triceps],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Lie flat on a bench with your eyes under the bar.',
      'Grip the bar slightly wider than shoulder width.',
      'Unrack the bar and lower it to your mid-chest with control.',
      'Press the bar back up until your arms are fully extended.',
      'Keep your feet flat on the floor and maintain a slight arch in your lower back.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'incline_barbell_bench_press',
    name: 'Incline Barbell Bench Press',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.shoulders, MuscleGroup.triceps],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Set the bench to a 30-45 degree incline.',
      'Grip the bar slightly wider than shoulder width.',
      'Unrack and lower the bar to your upper chest.',
      'Press the bar back up to full lockout.',
      'Keep your shoulder blades pinched together throughout.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'decline_barbell_bench_press',
    name: 'Decline Barbell Bench Press',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.triceps],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Set the bench to a 15-30 degree decline and secure your legs.',
      'Grip the bar slightly wider than shoulder width.',
      'Unrack and lower the bar to your lower chest.',
      'Press the bar back up to full extension.',
      'Keep your core braced throughout the movement.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'dumbbell_bench_press',
    name: 'Dumbbell Bench Press',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.shoulders, MuscleGroup.triceps],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Sit on a flat bench with dumbbells on your thighs, then lie back.',
      'Hold the dumbbells at chest level with palms facing forward.',
      'Press the dumbbells up until your arms are fully extended.',
      'Lower them back slowly to chest level with control.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'incline_dumbbell_press',
    name: 'Incline Dumbbell Press',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.shoulders, MuscleGroup.triceps],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Set the bench to a 30-45 degree incline.',
      'Hold dumbbells at shoulder level with palms facing forward.',
      'Press the dumbbells up and slightly inward until arms are extended.',
      'Lower the dumbbells back to shoulder level under control.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'dumbbell_fly',
    name: 'Dumbbell Fly',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.shoulders],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Lie flat on a bench holding dumbbells above your chest with a slight bend in your elbows.',
      'Lower the dumbbells out to the sides in a wide arc.',
      'Feel a deep stretch across your chest at the bottom.',
      'Squeeze your chest to bring the dumbbells back together at the top.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'cable_crossover',
    name: 'Cable Crossover',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.shoulders],
    equipment: ExerciseEquipment.cable,
    instructions: [
      'Set both cable pulleys to the highest position.',
      'Stand in the centre with a slight forward lean and staggered stance.',
      'Pull the handles down and together in front of your chest.',
      'Squeeze your chest hard at the bottom, then return slowly.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'push_up',
    name: 'Push Up',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.shoulders, MuscleGroup.triceps, MuscleGroup.abs],
    equipment: ExerciseEquipment.bodyweight,
    instructions: [
      'Start in a high plank position with hands slightly wider than shoulders.',
      'Keep your body in a straight line from head to heels.',
      'Lower your chest to the floor by bending your elbows.',
      'Push back up to the starting position.',
      'Avoid flaring your elbows excessively; keep them at roughly 45 degrees.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'chest_dip',
    name: 'Chest Dip',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
    equipment: ExerciseEquipment.bodyweight,
    instructions: [
      'Grip the parallel bars and lift yourself to a straight-arm position.',
      'Lean your torso forward about 30 degrees.',
      'Lower yourself until your upper arms are parallel to the floor.',
      'Press back up to full lockout while maintaining the forward lean.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'machine_chest_press',
    name: 'Machine Chest Press',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.shoulders, MuscleGroup.triceps],
    equipment: ExerciseEquipment.machine,
    instructions: [
      'Adjust the seat so the handles align with your mid-chest.',
      'Sit back with your feet flat on the floor.',
      'Press the handles forward until your arms are fully extended.',
      'Return slowly to the starting position with control.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),

  // ---------------------------------------------------------------------------
  // BACK (10)
  // ---------------------------------------------------------------------------
  ExerciseDefinition(
    id: 'conventional_deadlift',
    name: 'Conventional Deadlift',
    // Deadlift is a posterior-chain lift driven by the lower back / spinal
    // erectors plus hamstrings and glutes. Lats / upper back are stabilisers,
    // not prime movers — they belong in secondary.
    primaryMuscles: [MuscleGroup.lowerBack, MuscleGroup.hamstrings, MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.upperBack, MuscleGroup.lats, MuscleGroup.quads, MuscleGroup.forearms],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Stand with feet hip-width apart and the bar over your mid-foot.',
      'Hinge at the hips and grip the bar just outside your knees.',
      'Brace your core, flatten your back, and drive through your heels.',
      'Stand up fully, locking out your hips and knees at the top.',
      'Lower the bar back to the floor in a controlled reverse movement.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'barbell_bent_over_row',
    name: 'Barbell Bent Over Row',
    primaryMuscles: [MuscleGroup.upperBack, MuscleGroup.lats],
    secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.forearms],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Hold the barbell with an overhand grip, hands shoulder-width apart.',
      'Hinge forward at the hips until your torso is roughly 45 degrees.',
      'Pull the bar to your lower ribcage, squeezing your shoulder blades.',
      'Lower the bar under control and repeat.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'pull_up',
    name: 'Pull Up',
    primaryMuscles: [MuscleGroup.lats],
    secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.upperBack, MuscleGroup.forearms],
    equipment: ExerciseEquipment.bodyweight,
    instructions: [
      'Hang from a bar with an overhand grip, hands slightly wider than shoulder width.',
      'Engage your lats and pull your chest toward the bar.',
      'Aim to get your chin over the bar at the top.',
      'Lower yourself slowly to a full dead hang and repeat.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'chin_up',
    name: 'Chin Up',
    primaryMuscles: [MuscleGroup.lats, MuscleGroup.biceps],
    secondaryMuscles: [MuscleGroup.upperBack, MuscleGroup.forearms],
    equipment: ExerciseEquipment.bodyweight,
    instructions: [
      'Hang from a bar with an underhand (supinated) grip, hands shoulder-width apart.',
      'Pull yourself up until your chin clears the bar.',
      'Squeeze your biceps and lats at the top.',
      'Lower yourself under control to a full hang.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'lat_pulldown',
    name: 'Lat Pulldown',
    primaryMuscles: [MuscleGroup.lats],
    secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.upperBack],
    equipment: ExerciseEquipment.cable,
    instructions: [
      'Sit at the lat pulldown machine with thighs secured under the pad.',
      'Grip the bar wider than shoulder width with an overhand grip.',
      'Pull the bar down to your upper chest, leading with your elbows.',
      'Slowly return the bar to the top with arms fully extended.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'seated_cable_row',
    name: 'Seated Cable Row',
    primaryMuscles: [MuscleGroup.upperBack, MuscleGroup.lats],
    secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.forearms],
    equipment: ExerciseEquipment.cable,
    instructions: [
      'Sit at the cable row station with feet on the foot plate and knees slightly bent.',
      'Grab the handle and sit up tall with arms extended.',
      'Pull the handle to your abdomen, squeezing your shoulder blades.',
      'Extend your arms back slowly without rounding your back.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'single_arm_dumbbell_row',
    name: 'Single Arm Dumbbell Row',
    primaryMuscles: [MuscleGroup.lats, MuscleGroup.upperBack],
    secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.forearms],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Place one knee and hand on a flat bench for support.',
      'Hold a dumbbell in the free hand with arm extended.',
      'Row the dumbbell up to your hip, keeping your elbow close to your body.',
      'Lower the dumbbell under control and repeat.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 't_bar_row',
    name: 'T-Bar Row',
    primaryMuscles: [MuscleGroup.upperBack, MuscleGroup.lats],
    secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.forearms],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Straddle the T-bar or landmine attachment with feet shoulder-width apart.',
      'Hinge at the hips and grip the handle with both hands.',
      'Pull the weight toward your chest, driving your elbows back.',
      'Lower the weight under control and maintain a flat back throughout.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'face_pull',
    name: 'Face Pull',
    primaryMuscles: [MuscleGroup.upperBack, MuscleGroup.shoulders],
    secondaryMuscles: [MuscleGroup.biceps],
    equipment: ExerciseEquipment.cable,
    instructions: [
      'Set the cable pulley to upper-chest or face height with a rope attachment.',
      'Grip the rope with both hands, palms facing inward.',
      'Pull the rope toward your face, flaring your elbows out and back.',
      'Squeeze your rear delts and upper back at the end position.',
      'Return slowly to the start.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'cable_pullover',
    name: 'Cable Pullover',
    primaryMuscles: [MuscleGroup.lats],
    secondaryMuscles: [MuscleGroup.chest, MuscleGroup.triceps],
    equipment: ExerciseEquipment.cable,
    instructions: [
      'Set a cable pulley to the highest position with a straight bar attachment.',
      'Stand facing the machine with a slight forward lean.',
      'Keep your arms nearly straight and pull the bar down in an arc to your thighs.',
      'Squeeze your lats at the bottom, then return slowly.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),

  // ---------------------------------------------------------------------------
  // SHOULDERS (8)
  // ---------------------------------------------------------------------------
  ExerciseDefinition(
    id: 'overhead_press',
    name: 'Overhead Press',
    primaryMuscles: [MuscleGroup.shoulders],
    secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.upperBack],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Stand with feet shoulder-width apart and the bar resting on your front delts.',
      'Brace your core and squeeze your glutes.',
      'Press the bar straight overhead until your arms are locked out.',
      'Lower the bar back to the front of your shoulders with control.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'dumbbell_lateral_raise',
    name: 'Dumbbell Lateral Raise',
    primaryMuscles: [MuscleGroup.shoulders],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Stand with dumbbells at your sides, palms facing inward.',
      'Raise the dumbbells out to the sides until your arms are parallel to the floor.',
      'Keep a slight bend in your elbows throughout.',
      'Lower the dumbbells slowly back to your sides.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'front_raise',
    name: 'Front Raise',
    primaryMuscles: [MuscleGroup.shoulders],
    secondaryMuscles: [MuscleGroup.chest],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Stand with dumbbells in front of your thighs, palms facing your body.',
      'Raise one or both dumbbells forward to shoulder height.',
      'Keep your arms nearly straight with a slight elbow bend.',
      'Lower back down under control.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'rear_delt_fly',
    name: 'Rear Delt Fly',
    primaryMuscles: [MuscleGroup.shoulders, MuscleGroup.upperBack],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Hinge at the hips with a flat back, holding dumbbells beneath your chest.',
      'Raise the dumbbells out to the sides, squeezing your rear delts.',
      'Keep a slight bend in your elbows and avoid using momentum.',
      'Lower the dumbbells back to the starting position slowly.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'arnold_press',
    name: 'Arnold Press',
    primaryMuscles: [MuscleGroup.shoulders],
    secondaryMuscles: [MuscleGroup.triceps],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Sit or stand with dumbbells at shoulder height, palms facing you.',
      'Press the dumbbells overhead while rotating your palms to face forward.',
      'Fully extend your arms at the top.',
      'Reverse the rotation as you lower the dumbbells back to the start.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'barbell_shrug',
    name: 'Barbell Shrug',
    primaryMuscles: [MuscleGroup.upperBack],
    secondaryMuscles: [MuscleGroup.forearms],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Stand holding a barbell at arm\'s length with an overhand grip.',
      'Shrug your shoulders straight up toward your ears.',
      'Hold the peak contraction for a moment.',
      'Lower your shoulders back down under control.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'dumbbell_shrug',
    name: 'Dumbbell Shrug',
    primaryMuscles: [MuscleGroup.upperBack],
    secondaryMuscles: [MuscleGroup.forearms],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Stand holding dumbbells at your sides with a neutral grip.',
      'Shrug your shoulders straight up toward your ears.',
      'Squeeze at the top for a brief hold.',
      'Lower your shoulders back down slowly.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'upright_row',
    name: 'Upright Row',
    primaryMuscles: [MuscleGroup.shoulders, MuscleGroup.upperBack],
    secondaryMuscles: [MuscleGroup.biceps],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Stand holding a barbell with a narrow overhand grip.',
      'Pull the bar straight up along your body to chin height.',
      'Lead with your elbows, keeping them above your hands.',
      'Lower the bar back to the starting position with control.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),

  // ---------------------------------------------------------------------------
  // LEGS (12)
  // ---------------------------------------------------------------------------
  ExerciseDefinition(
    id: 'barbell_back_squat',
    name: 'Barbell Back Squat',
    // Squat is quad-dominant; glutes, hams, and lower-back erectors are
    // significant assistors but not the prime mover.
    primaryMuscles: [MuscleGroup.quads],
    secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.hamstrings, MuscleGroup.lowerBack, MuscleGroup.abs],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Position the bar on your upper traps and step back from the rack.',
      'Stand with feet shoulder-width apart, toes slightly turned out.',
      'Brace your core and squat down until your thighs are at least parallel.',
      'Drive through your feet to stand back up.',
      'Keep your chest up and knees tracking over your toes.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'front_squat',
    name: 'Front Squat',
    primaryMuscles: [MuscleGroup.quads],
    secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.abs],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Rest the barbell on the front of your shoulders in a clean grip or cross-arm grip.',
      'Keep your elbows high and your torso upright.',
      'Squat down until your thighs are at least parallel to the floor.',
      'Drive back up through your heels while keeping your chest tall.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'leg_press',
    name: 'Leg Press',
    primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.hamstrings],
    equipment: ExerciseEquipment.machine,
    instructions: [
      'Sit in the leg press machine with your back flat against the pad.',
      'Place your feet shoulder-width apart on the platform.',
      'Release the safety handles and lower the platform by bending your knees.',
      'Push the platform back up without locking your knees completely.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'romanian_deadlift',
    name: 'Romanian Deadlift',
    // RDL hits the full posterior chain — hams, glutes, AND the lower-back
    // erectors holding the hinged position. Lats / upper back stabilise.
    primaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.glutes, MuscleGroup.lowerBack],
    secondaryMuscles: [MuscleGroup.upperBack, MuscleGroup.forearms],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Hold a barbell at hip height with an overhand grip.',
      'Push your hips back and lower the bar along your legs.',
      'Keep a slight bend in your knees and a flat back.',
      'Lower until you feel a strong stretch in your hamstrings.',
      'Drive your hips forward to return to standing.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'leg_curl',
    name: 'Leg Curl',
    primaryMuscles: [MuscleGroup.hamstrings],
    secondaryMuscles: [MuscleGroup.calves],
    equipment: ExerciseEquipment.machine,
    instructions: [
      'Lie face down on the leg curl machine with the pad on your lower calves.',
      'Curl the weight up by bending your knees.',
      'Squeeze your hamstrings at the top of the movement.',
      'Lower the weight slowly back to the starting position.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'leg_extension',
    name: 'Leg Extension',
    primaryMuscles: [MuscleGroup.quads],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.machine,
    instructions: [
      'Sit on the leg extension machine with the pad on your shins.',
      'Extend your legs until they are straight.',
      'Squeeze your quads at the top.',
      'Lower the weight slowly back to the starting position.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'walking_lunge',
    name: 'Walking Lunge',
    primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.hamstrings],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Hold dumbbells at your sides and stand tall.',
      'Step forward with one leg and lower your back knee toward the floor.',
      'Both knees should bend to roughly 90 degrees.',
      'Push off your front foot and step through to the next lunge.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'bulgarian_split_squat',
    name: 'Bulgarian Split Squat',
    primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.hamstrings],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Stand about two feet in front of a bench and place one foot on it behind you.',
      'Hold dumbbells at your sides.',
      'Lower your body until your front thigh is parallel to the floor.',
      'Drive through your front heel to return to the starting position.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'calf_raise',
    name: 'Calf Raise',
    primaryMuscles: [MuscleGroup.calves],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.machine,
    instructions: [
      'Stand on the edge of a step or calf raise machine with the balls of your feet.',
      'Lower your heels below the step for a full stretch.',
      'Rise up onto your toes as high as possible.',
      'Hold the top briefly, then lower under control.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'hack_squat',
    name: 'Hack Squat',
    primaryMuscles: [MuscleGroup.quads],
    secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.hamstrings],
    equipment: ExerciseEquipment.machine,
    instructions: [
      'Position yourself in the hack squat machine with your back against the pad.',
      'Place your feet shoulder-width apart on the platform.',
      'Release the safety handles and lower yourself by bending your knees.',
      'Push back up through your feet without fully locking your knees.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'hip_thrust',
    name: 'Hip Thrust',
    primaryMuscles: [MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.hamstrings],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Sit on the floor with your upper back against a bench and a barbell across your hips.',
      'Plant your feet flat on the floor, hip-width apart.',
      'Drive your hips up by squeezing your glutes until your body forms a straight line from shoulders to knees.',
      'Lower your hips back down with control.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'goblet_squat',
    name: 'Goblet Squat',
    // Quad-dominant squat variant — glutes assist but the loading pattern
    // (front-loaded, upright torso) emphasises the quads.
    primaryMuscles: [MuscleGroup.quads],
    secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.abs],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Hold a dumbbell vertically at your chest with both hands.',
      'Stand with feet slightly wider than shoulder width.',
      'Squat down while keeping your torso upright and elbows inside your knees.',
      'Drive back up through your heels to the starting position.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),

  // ---------------------------------------------------------------------------
  // BICEPS (6)
  // ---------------------------------------------------------------------------
  ExerciseDefinition(
    id: 'barbell_curl',
    name: 'Barbell Curl',
    primaryMuscles: [MuscleGroup.biceps],
    secondaryMuscles: [MuscleGroup.forearms],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Stand with feet shoulder-width apart holding a barbell with an underhand grip.',
      'Keep your elbows pinned to your sides.',
      'Curl the bar up toward your shoulders by contracting your biceps.',
      'Lower the bar back down under control without swinging.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'dumbbell_curl',
    name: 'Dumbbell Curl',
    primaryMuscles: [MuscleGroup.biceps],
    secondaryMuscles: [MuscleGroup.forearms],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Stand holding dumbbells at your sides with palms facing forward.',
      'Curl both dumbbells up toward your shoulders.',
      'Squeeze your biceps at the top of the movement.',
      'Lower the dumbbells slowly to full extension.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'hammer_curl',
    name: 'Hammer Curl',
    primaryMuscles: [MuscleGroup.biceps],
    secondaryMuscles: [MuscleGroup.forearms],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Stand holding dumbbells with a neutral (hammer) grip, palms facing each other.',
      'Curl the dumbbells up toward your shoulders without rotating your wrists.',
      'Squeeze at the top and lower slowly.',
      'Keep your elbows close to your body throughout.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'preacher_curl',
    name: 'Preacher Curl',
    primaryMuscles: [MuscleGroup.biceps],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Sit at the preacher bench with your upper arms resting on the pad.',
      'Hold a barbell or EZ-bar with an underhand grip.',
      'Curl the bar up toward your shoulders.',
      'Lower it slowly, fully extending your arms at the bottom.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'concentration_curl',
    name: 'Concentration Curl',
    primaryMuscles: [MuscleGroup.biceps],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Sit on a bench with your legs spread and a dumbbell in one hand.',
      'Brace the back of your working arm against your inner thigh.',
      'Curl the dumbbell up toward your shoulder, focusing on the bicep contraction.',
      'Lower it back down slowly and repeat.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'cable_curl',
    name: 'Cable Curl',
    primaryMuscles: [MuscleGroup.biceps],
    secondaryMuscles: [MuscleGroup.forearms],
    equipment: ExerciseEquipment.cable,
    instructions: [
      'Stand facing a low cable pulley with a straight bar or EZ-bar attachment.',
      'Grip the bar with an underhand grip and stand upright.',
      'Curl the bar up toward your shoulders, keeping elbows at your sides.',
      'Lower the bar back down slowly with constant tension.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),

  // ---------------------------------------------------------------------------
  // TRICEPS (6)
  // ---------------------------------------------------------------------------
  ExerciseDefinition(
    id: 'tricep_pushdown',
    name: 'Tricep Pushdown',
    primaryMuscles: [MuscleGroup.triceps],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.cable,
    instructions: [
      'Stand facing a high cable pulley with a straight bar or rope attachment.',
      'Grip the attachment with palms facing down.',
      'Push the bar down by extending your elbows until your arms are straight.',
      'Slowly return to the starting position without letting your elbows drift forward.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'skull_crusher',
    name: 'Skull Crusher',
    primaryMuscles: [MuscleGroup.triceps],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Lie on a flat bench holding a barbell or EZ-bar with arms extended above your chest.',
      'Bend your elbows to lower the bar toward your forehead.',
      'Keep your upper arms stationary throughout.',
      'Extend your elbows to press the bar back to the starting position.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'overhead_tricep_extension',
    name: 'Overhead Tricep Extension',
    primaryMuscles: [MuscleGroup.triceps],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Hold a dumbbell overhead with both hands, arms fully extended.',
      'Lower the dumbbell behind your head by bending your elbows.',
      'Keep your upper arms close to your ears throughout.',
      'Extend your elbows to press the dumbbell back overhead.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'close_grip_bench_press',
    name: 'Close Grip Bench Press',
    primaryMuscles: [MuscleGroup.triceps],
    secondaryMuscles: [MuscleGroup.chest, MuscleGroup.shoulders],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Lie on a flat bench and grip the bar with hands about shoulder-width apart.',
      'Unrack the bar and lower it to your lower chest.',
      'Keep your elbows tucked close to your body.',
      'Press the bar back up to full lockout.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'tricep_dip',
    name: 'Tricep Dip',
    primaryMuscles: [MuscleGroup.triceps],
    secondaryMuscles: [MuscleGroup.chest, MuscleGroup.shoulders],
    equipment: ExerciseEquipment.bodyweight,
    instructions: [
      'Grip the parallel bars and lift yourself to a straight-arm position.',
      'Keep your torso upright (do not lean forward).',
      'Lower yourself by bending your elbows until upper arms are parallel to the floor.',
      'Press back up to full lockout.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'tricep_kickback',
    name: 'Tricep Kickback',
    primaryMuscles: [MuscleGroup.triceps],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Hinge forward at the hips with a dumbbell in one hand.',
      'Pin your upper arm to your side with your elbow at 90 degrees.',
      'Extend your arm backward until it is fully straight.',
      'Squeeze your tricep at the top, then lower slowly.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),

  // ---------------------------------------------------------------------------
  // CORE (8)
  // ---------------------------------------------------------------------------
  ExerciseDefinition(
    id: 'plank',
    name: 'Plank',
    primaryMuscles: [MuscleGroup.abs],
    secondaryMuscles: [MuscleGroup.obliques, MuscleGroup.shoulders],
    equipment: ExerciseEquipment.bodyweight,
    instructions: [
      'Start in a forearm plank position with elbows directly under your shoulders.',
      'Keep your body in a straight line from head to heels.',
      'Engage your core and glutes to prevent your hips from sagging.',
      'Hold the position for the prescribed time.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'crunch',
    name: 'Crunch',
    primaryMuscles: [MuscleGroup.abs],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.bodyweight,
    instructions: [
      'Lie on your back with knees bent and feet flat on the floor.',
      'Place your hands behind your head or across your chest.',
      'Curl your upper body toward your knees by contracting your abs.',
      'Lower back down under control without fully resting your shoulders.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'hanging_leg_raise',
    name: 'Hanging Leg Raise',
    primaryMuscles: [MuscleGroup.abs],
    secondaryMuscles: [MuscleGroup.obliques, MuscleGroup.forearms],
    equipment: ExerciseEquipment.bodyweight,
    instructions: [
      'Hang from a pull-up bar with arms fully extended.',
      'Keep your legs straight and raise them until they are parallel to the floor or higher.',
      'Avoid swinging or using momentum.',
      'Lower your legs slowly back to the starting position.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'russian_twist',
    name: 'Russian Twist',
    primaryMuscles: [MuscleGroup.obliques],
    secondaryMuscles: [MuscleGroup.abs],
    equipment: ExerciseEquipment.bodyweight,
    instructions: [
      'Sit on the floor with knees bent and lean back slightly.',
      'Lift your feet off the floor if possible for added difficulty.',
      'Rotate your torso to one side, then the other, tapping the floor beside your hip.',
      'Keep your core tight and move with control.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'cable_crunch',
    name: 'Cable Crunch',
    primaryMuscles: [MuscleGroup.abs],
    secondaryMuscles: [MuscleGroup.obliques],
    equipment: ExerciseEquipment.cable,
    instructions: [
      'Kneel in front of a high cable pulley with a rope attachment.',
      'Hold the rope behind your head.',
      'Crunch downward by flexing your spine, bringing your elbows toward your knees.',
      'Return slowly to the upright position.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'ab_wheel_rollout',
    name: 'Ab Wheel Rollout',
    primaryMuscles: [MuscleGroup.abs],
    secondaryMuscles: [MuscleGroup.shoulders, MuscleGroup.lats],
    equipment: ExerciseEquipment.bodyweight,
    instructions: [
      'Kneel on the floor holding an ab wheel with both hands.',
      'Roll the wheel forward, extending your body as far as you can.',
      'Keep your core tight and avoid letting your lower back sag.',
      'Pull yourself back to the starting position using your abs.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'mountain_climber',
    name: 'Mountain Climber',
    primaryMuscles: [MuscleGroup.abs],
    secondaryMuscles: [MuscleGroup.shoulders, MuscleGroup.quads, MuscleGroup.cardio],
    equipment: ExerciseEquipment.bodyweight,
    instructions: [
      'Start in a high plank position with arms straight.',
      'Drive one knee toward your chest, then quickly switch legs.',
      'Maintain a flat back and keep your hips level.',
      'Continue alternating at a brisk pace.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'dead_bug',
    name: 'Dead Bug',
    primaryMuscles: [MuscleGroup.abs],
    secondaryMuscles: [MuscleGroup.obliques],
    equipment: ExerciseEquipment.bodyweight,
    instructions: [
      'Lie on your back with arms extended toward the ceiling and knees bent at 90 degrees.',
      'Press your lower back into the floor.',
      'Slowly extend one arm overhead and the opposite leg straight out.',
      'Return to the starting position and repeat on the other side.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),

  // ---------------------------------------------------------------------------
  // CARDIO (8)
  // ---------------------------------------------------------------------------
  ExerciseDefinition(
    id: 'running_treadmill',
    name: 'Running (Treadmill)',
    primaryMuscles: [MuscleGroup.cardio],
    secondaryMuscles: [MuscleGroup.quads, MuscleGroup.hamstrings, MuscleGroup.calves],
    equipment: ExerciseEquipment.cardioMachine,
    instructions: [
      'Set the treadmill to your desired speed and incline.',
      'Start with a brisk walk and gradually increase to a run.',
      'Maintain an upright posture and a natural stride.',
      'Use the handrails only for balance, not to support your weight.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'cycling_stationary',
    name: 'Cycling (Stationary)',
    primaryMuscles: [MuscleGroup.cardio],
    secondaryMuscles: [MuscleGroup.quads, MuscleGroup.hamstrings, MuscleGroup.calves],
    equipment: ExerciseEquipment.cardioMachine,
    instructions: [
      'Adjust the seat height so your legs have a slight bend at the bottom of the pedal stroke.',
      'Start pedalling at a moderate pace.',
      'Increase resistance or speed for higher intensity.',
      'Keep your core engaged and avoid rounding your back.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'rowing_machine',
    name: 'Rowing Machine',
    primaryMuscles: [MuscleGroup.cardio],
    secondaryMuscles: [MuscleGroup.lats, MuscleGroup.upperBack, MuscleGroup.quads, MuscleGroup.hamstrings],
    equipment: ExerciseEquipment.cardioMachine,
    instructions: [
      'Sit on the rower with feet secured on the foot plates.',
      'Grab the handle with an overhand grip.',
      'Drive with your legs first, then lean back slightly and pull the handle to your chest.',
      'Reverse the sequence: extend arms, hinge forward, then bend knees.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'jump_rope',
    name: 'Jump Rope',
    primaryMuscles: [MuscleGroup.cardio],
    secondaryMuscles: [MuscleGroup.calves, MuscleGroup.shoulders, MuscleGroup.forearms],
    equipment: ExerciseEquipment.none,
    instructions: [
      'Hold the rope handles at your sides with elbows close to your body.',
      'Swing the rope over your head using your wrists, not your arms.',
      'Jump just high enough to clear the rope.',
      'Land softly on the balls of your feet and maintain a steady rhythm.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'stair_climber',
    name: 'Stair Climber',
    primaryMuscles: [MuscleGroup.cardio],
    secondaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes, MuscleGroup.calves],
    equipment: ExerciseEquipment.cardioMachine,
    instructions: [
      'Step onto the stair climber and select your desired speed.',
      'Stand upright and step rhythmically on the pedals.',
      'Avoid leaning heavily on the handrails.',
      'Maintain a steady pace and keep your core engaged.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'swimming',
    name: 'Swimming',
    primaryMuscles: [MuscleGroup.cardio],
    secondaryMuscles: [MuscleGroup.lats, MuscleGroup.shoulders, MuscleGroup.abs],
    equipment: ExerciseEquipment.none,
    instructions: [
      'Choose a stroke (freestyle, backstroke, breaststroke, or butterfly).',
      'Maintain a streamlined body position in the water.',
      'Coordinate your arm pulls and kicks with rhythmic breathing.',
      'Swim laps at a steady pace or alternate fast and recovery laps.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'elliptical',
    name: 'Elliptical',
    primaryMuscles: [MuscleGroup.cardio],
    secondaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes, MuscleGroup.hamstrings],
    equipment: ExerciseEquipment.cardioMachine,
    instructions: [
      'Step onto the elliptical and grip the handles.',
      'Start with a moderate stride, pushing and pulling the handles.',
      'Increase resistance or speed for greater intensity.',
      'Keep your back straight and core engaged throughout.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'battle_ropes',
    name: 'Battle Ropes',
    primaryMuscles: [MuscleGroup.cardio],
    secondaryMuscles: [MuscleGroup.shoulders, MuscleGroup.abs, MuscleGroup.forearms],
    equipment: ExerciseEquipment.none,
    instructions: [
      'Stand with feet shoulder-width apart, holding one end of the rope in each hand.',
      'Bend your knees slightly and brace your core.',
      'Alternate raising and lowering each arm to create waves in the rope.',
      'Maintain a fast, rhythmic pace for the prescribed duration.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),

  // ---------------------------------------------------------------------------
  // FOREARMS (3)
  // ---------------------------------------------------------------------------
  ExerciseDefinition(
    id: 'wrist_curl',
    name: 'Wrist Curl',
    primaryMuscles: [MuscleGroup.forearms],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Sit on a bench and rest your forearms on your thighs with wrists hanging off the edge.',
      'Hold a barbell with an underhand grip.',
      'Curl your wrists upward, squeezing your forearm flexors.',
      'Lower the bar back down slowly.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'reverse_wrist_curl',
    name: 'Reverse Wrist Curl',
    primaryMuscles: [MuscleGroup.forearms],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Sit on a bench and rest your forearms on your thighs with wrists hanging off the edge.',
      'Hold a barbell with an overhand grip.',
      'Extend your wrists upward by contracting your forearm extensors.',
      'Lower the bar back down slowly.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'farmers_walk',
    name: "Farmer's Walk",
    primaryMuscles: [MuscleGroup.forearms],
    secondaryMuscles: [MuscleGroup.upperBack, MuscleGroup.abs, MuscleGroup.quads],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Pick up a heavy dumbbell or kettlebell in each hand.',
      'Stand tall with your shoulders back and core engaged.',
      'Walk forward with controlled, even steps.',
      'Maintain your grip throughout the prescribed distance or time.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),

  // ---------------------------------------------------------------------------
  // COMPOUND EXTRAS (5)
  // ---------------------------------------------------------------------------
  ExerciseDefinition(
    id: 'sumo_deadlift',
    name: 'Sumo Deadlift',
    // Sumo shifts emphasis to glutes + quads vs conventional, but the
    // lower-back erectors still hold the spine — keep them in primary.
    primaryMuscles: [MuscleGroup.glutes, MuscleGroup.quads, MuscleGroup.hamstrings, MuscleGroup.lowerBack],
    secondaryMuscles: [MuscleGroup.upperBack, MuscleGroup.forearms],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Stand with a very wide stance and toes pointed out 30-45 degrees.',
      'Grip the bar inside your knees with arms straight.',
      'Brace your core, open your hips, and drive through your heels.',
      'Stand up fully, locking out your hips and knees.',
      'Lower the bar back to the floor with control.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'power_clean',
    name: 'Power Clean',
    primaryMuscles: [MuscleGroup.glutes, MuscleGroup.hamstrings, MuscleGroup.quads],
    secondaryMuscles: [MuscleGroup.upperBack, MuscleGroup.shoulders, MuscleGroup.forearms],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Start with the bar on the floor, feet hip-width apart, hands just outside the knees.',
      'Lift the bar off the floor by extending your knees, keeping your back flat.',
      'As the bar passes your knees, explosively extend your hips and shrug.',
      'Pull yourself under the bar and catch it on your front delts in a quarter squat.',
      'Stand up to complete the lift.',
    ],
    difficulty: ExerciseDifficulty.advanced,
  ),
  ExerciseDefinition(
    id: 'snatch',
    name: 'Snatch',
    primaryMuscles: [MuscleGroup.glutes, MuscleGroup.hamstrings, MuscleGroup.quads, MuscleGroup.shoulders],
    secondaryMuscles: [MuscleGroup.upperBack, MuscleGroup.forearms, MuscleGroup.abs],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Start with the bar on the floor and a wide overhand grip.',
      'Lift the bar by extending your legs, keeping it close to your body.',
      'Explosively extend your hips and shrug to accelerate the bar upward.',
      'Pull yourself under the bar and catch it overhead with arms locked.',
      'Stand up to full extension with the bar overhead.',
    ],
    difficulty: ExerciseDifficulty.advanced,
  ),
  ExerciseDefinition(
    id: 'thruster',
    name: 'Thruster',
    primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes, MuscleGroup.shoulders],
    secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.abs],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Hold a barbell in the front rack position at your shoulders.',
      'Squat down until your thighs are parallel to the floor.',
      'Drive up explosively and use the momentum to press the bar overhead.',
      'Lock out your arms fully at the top.',
      'Lower the bar back to the front rack and descend into the next squat.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'burpee',
    name: 'Burpee',
    primaryMuscles: [MuscleGroup.cardio],
    secondaryMuscles: [MuscleGroup.chest, MuscleGroup.quads, MuscleGroup.shoulders, MuscleGroup.abs],
    equipment: ExerciseEquipment.bodyweight,
    instructions: [
      'Stand with feet shoulder-width apart.',
      'Drop into a squat and place your hands on the floor.',
      'Jump your feet back into a plank and perform a push-up.',
      'Jump your feet forward to your hands.',
      'Explosively jump into the air with your arms overhead.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),

  // ---------------------------------------------------------------------------
  // ADDITIONAL EXERCISES (22 more to exceed 105 total)
  // ---------------------------------------------------------------------------
  ExerciseDefinition(
    id: 'incline_dumbbell_fly',
    name: 'Incline Dumbbell Fly',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.shoulders],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Set a bench to a 30-45 degree incline and lie back with dumbbells above your chest.',
      'Lower the dumbbells out to the sides in a wide arc with a slight elbow bend.',
      'Feel a stretch across your upper chest.',
      'Squeeze your chest to bring the dumbbells back together overhead.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'cable_lateral_raise',
    name: 'Cable Lateral Raise',
    primaryMuscles: [MuscleGroup.shoulders],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.cable,
    instructions: [
      'Stand sideways to a low cable pulley and grab the handle with the far hand.',
      'Raise your arm out to the side until it is parallel to the floor.',
      'Keep a slight bend in your elbow throughout.',
      'Lower the handle back down slowly.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'landmine_press',
    name: 'Landmine Press',
    primaryMuscles: [MuscleGroup.shoulders, MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.abs],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Stand facing the landmine with one end of the barbell at shoulder height.',
      'Press the bar up and away from your shoulder at a diagonal angle.',
      'Lock out your arm at the top.',
      'Lower the bar back to your shoulder with control.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'dumbbell_pullover',
    name: 'Dumbbell Pullover',
    primaryMuscles: [MuscleGroup.lats, MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.triceps],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Lie across a bench with your upper back supported and hips low.',
      'Hold a dumbbell overhead with both hands, arms nearly straight.',
      'Lower the dumbbell behind your head in an arc until you feel a stretch.',
      'Pull the dumbbell back over your chest using your lats and chest.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'pendlay_row',
    name: 'Pendlay Row',
    primaryMuscles: [MuscleGroup.upperBack, MuscleGroup.lats],
    secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.forearms],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Stand over the barbell with a hip-width stance and hinge until your torso is parallel to the floor.',
      'Grip the bar slightly wider than shoulder width.',
      'Row the bar explosively to your lower chest while keeping your torso still.',
      'Lower the bar back to the floor and reset before each rep.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'meadows_row',
    name: 'Meadows Row',
    primaryMuscles: [MuscleGroup.lats, MuscleGroup.upperBack],
    secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.forearms],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Stand perpendicular to a landmine attachment with a staggered stance.',
      'Grab the end of the barbell with an overhand grip.',
      'Row the bar up toward your hip, driving your elbow back.',
      'Lower the bar under control and repeat.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'good_morning',
    name: 'Good Morning',
    primaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.upperBack],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Place a barbell on your upper traps as you would for a squat.',
      'Stand with feet shoulder-width apart and a slight knee bend.',
      'Hinge at the hips, pushing them back and lowering your torso toward parallel.',
      'Drive your hips forward to return to standing.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'sissy_squat',
    name: 'Sissy Squat',
    primaryMuscles: [MuscleGroup.quads],
    secondaryMuscles: [MuscleGroup.abs],
    equipment: ExerciseEquipment.bodyweight,
    instructions: [
      'Stand upright and hold onto a support for balance.',
      'Rise onto the balls of your feet.',
      'Lean your torso back and bend your knees, lowering your body backward.',
      'Push through the balls of your feet to return to the starting position.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'step_up',
    name: 'Step Up',
    primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.hamstrings],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Stand in front of a sturdy bench or box holding dumbbells at your sides.',
      'Step onto the box with one foot and drive through your heel to stand up.',
      'Bring your trailing leg up to stand on top of the box.',
      'Step back down with control and alternate legs.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'glute_ham_raise',
    name: 'Glute Ham Raise',
    primaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.calves],
    equipment: ExerciseEquipment.machine,
    instructions: [
      'Position yourself on the GHD machine with your feet secured.',
      'Start with your torso upright and knees on the pad.',
      'Lower your body forward by extending your knees under control.',
      'Curl yourself back up using your hamstrings.',
    ],
    difficulty: ExerciseDifficulty.advanced,
  ),
  ExerciseDefinition(
    id: 'kettlebell_swing',
    name: 'Kettlebell Swing',
    primaryMuscles: [MuscleGroup.glutes, MuscleGroup.hamstrings],
    secondaryMuscles: [MuscleGroup.abs, MuscleGroup.shoulders, MuscleGroup.cardio],
    equipment: ExerciseEquipment.kettlebell,
    instructions: [
      'Stand with feet shoulder-width apart and a kettlebell on the floor between your feet.',
      'Hinge at the hips and grip the kettlebell with both hands.',
      'Hike the kettlebell back between your legs, then snap your hips forward.',
      'Let the kettlebell swing to chest height, keeping your arms relaxed.',
      'Control the swing back down and repeat.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'kettlebell_goblet_squat',
    name: 'Kettlebell Goblet Squat',
    primaryMuscles: [MuscleGroup.quads],
    secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.abs],
    equipment: ExerciseEquipment.kettlebell,
    instructions: [
      'Hold a kettlebell by the horns at chest height.',
      'Stand with feet slightly wider than shoulder width.',
      'Squat down, keeping your chest tall and elbows inside your knees.',
      'Drive back up through your heels.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'turkish_get_up',
    name: 'Turkish Get Up',
    primaryMuscles: [MuscleGroup.shoulders, MuscleGroup.abs],
    secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.quads, MuscleGroup.obliques],
    equipment: ExerciseEquipment.kettlebell,
    instructions: [
      'Lie on your back holding a kettlebell in one hand with arm extended toward the ceiling.',
      'Roll onto your opposite elbow, then onto your hand.',
      'Lift your hips and sweep your back leg under you to a kneeling position.',
      'Stand up fully while keeping the kettlebell overhead.',
      'Reverse the steps to return to the floor.',
    ],
    difficulty: ExerciseDifficulty.advanced,
  ),
  ExerciseDefinition(
    id: 'seated_dumbbell_shoulder_press',
    name: 'Seated Dumbbell Shoulder Press',
    primaryMuscles: [MuscleGroup.shoulders],
    secondaryMuscles: [MuscleGroup.triceps],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Sit on a bench with back support, holding dumbbells at shoulder height.',
      'Press the dumbbells overhead until your arms are fully extended.',
      'Lower the dumbbells back to shoulder level with control.',
      'Keep your core braced and avoid excessive arching.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'reverse_fly_machine',
    name: 'Reverse Fly Machine',
    primaryMuscles: [MuscleGroup.shoulders, MuscleGroup.upperBack],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.machine,
    instructions: [
      'Sit facing the machine with your chest against the pad.',
      'Grip the handles with arms extended in front of you.',
      'Pull the handles apart by squeezing your rear delts.',
      'Return to the starting position slowly.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'incline_dumbbell_curl',
    name: 'Incline Dumbbell Curl',
    primaryMuscles: [MuscleGroup.biceps],
    secondaryMuscles: [MuscleGroup.forearms],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Set a bench to about 45 degrees and sit back with dumbbells at your sides.',
      'Let your arms hang straight down.',
      'Curl both dumbbells up toward your shoulders.',
      'Lower them slowly, getting a deep stretch at the bottom.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'spider_curl',
    name: 'Spider Curl',
    primaryMuscles: [MuscleGroup.biceps],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Lie face down on an incline bench with your arms hanging straight down.',
      'Hold dumbbells with an underhand grip.',
      'Curl the dumbbells up toward your shoulders without moving your upper arms.',
      'Lower the dumbbells slowly to a full extension.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'cable_overhead_tricep_extension',
    name: 'Cable Overhead Tricep Extension',
    primaryMuscles: [MuscleGroup.triceps],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.cable,
    instructions: [
      'Attach a rope to a low cable pulley and face away from the machine.',
      'Hold the rope behind your head with elbows bent.',
      'Extend your arms overhead until they are straight.',
      'Lower the rope behind your head slowly and repeat.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'bicycle_crunch',
    name: 'Bicycle Crunch',
    primaryMuscles: [MuscleGroup.abs, MuscleGroup.obliques],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.bodyweight,
    instructions: [
      'Lie on your back with hands behind your head and legs raised.',
      'Bring one knee toward your chest while rotating your opposite elbow toward it.',
      'Switch sides in a pedalling motion.',
      'Keep your lower back pressed into the floor throughout.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'pallof_press',
    name: 'Pallof Press',
    primaryMuscles: [MuscleGroup.abs, MuscleGroup.obliques],
    secondaryMuscles: [MuscleGroup.shoulders],
    equipment: ExerciseEquipment.cable,
    instructions: [
      'Stand sideways to a cable machine at chest height with the handle at your sternum.',
      'Press the handle straight out in front of you with both hands.',
      'Hold the extended position, resisting the rotational pull.',
      'Bring the handle back to your chest and repeat.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'box_jump',
    name: 'Box Jump',
    primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes, MuscleGroup.cardio],
    secondaryMuscles: [MuscleGroup.calves, MuscleGroup.hamstrings],
    equipment: ExerciseEquipment.bodyweight,
    instructions: [
      'Stand facing a sturdy box or platform at an appropriate height.',
      'Swing your arms back, bend your knees, and jump explosively onto the box.',
      'Land softly with both feet fully on top of the box.',
      'Stand up fully, then step back down and repeat.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'band_pull_apart',
    name: 'Band Pull Apart',
    primaryMuscles: [MuscleGroup.upperBack, MuscleGroup.shoulders],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.bands,
    instructions: [
      'Hold a resistance band in front of you at shoulder height with arms extended.',
      'Pull the band apart by squeezing your shoulder blades together.',
      'Bring the band to your chest with arms out to the sides.',
      'Return to the starting position with control.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'deficit_deadlift',
    name: 'Deficit Deadlift',
    primaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.glutes, MuscleGroup.upperBack],
    secondaryMuscles: [MuscleGroup.quads, MuscleGroup.forearms, MuscleGroup.lats],
    equipment: ExerciseEquipment.barbell,
    instructions: [
      'Stand on a low platform (1-3 inches) with feet hip-width apart.',
      'Set up as you would for a conventional deadlift with the bar over mid-foot.',
      'Grip the bar and brace your core, then drive through your heels.',
      'Stand up fully, locking out hips and knees.',
      'Lower the bar back down with control.',
    ],
    difficulty: ExerciseDifficulty.advanced,
  ),
  ExerciseDefinition(
    id: 'hip_adductor_machine',
    name: 'Hip Adductor Machine',
    primaryMuscles: [MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.quads],
    equipment: ExerciseEquipment.machine,
    instructions: [
      'Sit in the adductor machine with pads against your inner thighs.',
      'Select an appropriate weight.',
      'Squeeze your legs together against the resistance.',
      'Return to the starting position slowly.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'hip_abductor_machine',
    name: 'Hip Abductor Machine',
    primaryMuscles: [MuscleGroup.glutes],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.machine,
    instructions: [
      'Sit in the abductor machine with pads against your outer thighs.',
      'Select an appropriate weight.',
      'Push your legs apart against the resistance.',
      'Return to the starting position slowly.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'zottman_curl',
    name: 'Zottman Curl',
    primaryMuscles: [MuscleGroup.biceps, MuscleGroup.forearms],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.dumbbell,
    instructions: [
      'Stand with dumbbells at your sides, palms facing forward.',
      'Curl the dumbbells up with a supinated (palms-up) grip.',
      'At the top, rotate your wrists to a pronated (palms-down) grip.',
      'Lower the dumbbells slowly with the pronated grip.',
      'Rotate back to supinated at the bottom and repeat.',
    ],
    difficulty: ExerciseDifficulty.intermediate,
  ),
  ExerciseDefinition(
    id: 'dragon_flag',
    name: 'Dragon Flag',
    primaryMuscles: [MuscleGroup.abs],
    secondaryMuscles: [MuscleGroup.obliques, MuscleGroup.glutes],
    equipment: ExerciseEquipment.bodyweight,
    instructions: [
      'Lie on a bench and grip the edges behind your head.',
      'Lift your entire body off the bench, pivoting on your upper back.',
      'Keep your body in a straight line from shoulders to toes.',
      'Lower your body slowly toward the bench without touching it.',
      'Raise back up and repeat.',
    ],
    difficulty: ExerciseDifficulty.advanced,
  ),
  ExerciseDefinition(
    id: 'seated_calf_raise',
    name: 'Seated Calf Raise',
    primaryMuscles: [MuscleGroup.calves],
    secondaryMuscles: [],
    equipment: ExerciseEquipment.machine,
    instructions: [
      'Sit at the seated calf raise machine with the pad on your lower thighs.',
      'Place the balls of your feet on the platform with heels hanging off.',
      'Lower your heels for a full stretch.',
      'Press up onto your toes as high as possible and squeeze.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
  ExerciseDefinition(
    id: 'inverted_row',
    name: 'Inverted Row',
    primaryMuscles: [MuscleGroup.upperBack, MuscleGroup.lats],
    secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.abs],
    equipment: ExerciseEquipment.bodyweight,
    instructions: [
      'Set a bar at about waist height on a squat rack or Smith machine.',
      'Hang underneath the bar with an overhand grip, body in a straight line.',
      'Pull your chest up to the bar by squeezing your shoulder blades together.',
      'Lower yourself back down with control.',
    ],
    difficulty: ExerciseDifficulty.beginner,
  ),
];
