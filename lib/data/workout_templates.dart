import '../models/enums.dart';
import 'exercise_library.dart';

enum WorkoutTemplateCategory {
  splits,
  strength,
  cardio,
  beginner,
}

extension WorkoutTemplateCategoryLabel on WorkoutTemplateCategory {
  String get label => switch (this) {
        WorkoutTemplateCategory.splits => 'Splits',
        WorkoutTemplateCategory.strength => 'Strength',
        WorkoutTemplateCategory.cardio => 'Cardio',
        WorkoutTemplateCategory.beginner => 'Beginner',
      };
}

class TemplateExercise {
  const TemplateExercise({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.restSeconds = 90,
    this.notes,
  });

  final String exerciseId;
  final int sets;
  final int reps;
  final int restSeconds;
  final String? notes;
}

class WorkoutTemplate {
  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.exercises,
  });

  final String id;
  final String name;
  final String description;
  final WorkoutTemplateCategory category;
  final ExerciseDifficulty difficulty;
  final int estimatedMinutes;
  final List<TemplateExercise> exercises;

  /// Aggregated primary + secondary muscle groups for this template,
  /// derived live from [exerciseLibrary] via each [TemplateExercise]'s id.
  ///
  /// Previously this was a hand-maintained list stored on every template
  /// definition. That copy went stale every time an exercise's muscle data
  /// was corrected (e.g., when Deadlift moved from `upperBack` to
  /// `lowerBack`). Computing it on read means template chips, summaries,
  /// and any other consumer always reflect the current library — no
  /// per-template babysitting required.
  ///
  /// Preserves insertion order via [LinkedHashSet] semantics so callers
  /// that show the first N muscles get the most prominent groups first
  /// (the order matches the order exercises appear in the template).
  List<MuscleGroup> get muscleGroups {
    final out = <MuscleGroup>{};
    for (final te in exercises) {
      final def = exerciseLibrary
          .where((d) => d.id == te.exerciseId)
          .firstOrNull;
      if (def == null) continue;
      out.addAll(def.primaryMuscles);
      out.addAll(def.secondaryMuscles);
    }
    return out.toList();
  }
}

const List<WorkoutTemplate> workoutTemplates = [
  // ---------------------------------------------------------------------------
  // Category: Splits (8 templates)
  // ---------------------------------------------------------------------------

  // 1. Push Day
  WorkoutTemplate(
    id: 'push_day',
    name: 'Push Day',
    description:
        'Chest, shoulders, and triceps focused push workout with compound and isolation movements.',
    category: WorkoutTemplateCategory.splits,
    difficulty: ExerciseDifficulty.intermediate,
    estimatedMinutes: 55,
    exercises: [
      TemplateExercise(exerciseId: 'barbell_bench_press', sets: 4, reps: 8),
      TemplateExercise(exerciseId: 'incline_dumbbell_press', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'dumbbell_lateral_raise', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'overhead_press', sets: 3, reps: 8),
      TemplateExercise(exerciseId: 'tricep_pushdown', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'cable_crossover', sets: 3, reps: 12),
    ],
  ),

  // 2. Pull Day
  WorkoutTemplate(
    id: 'pull_day',
    name: 'Pull Day',
    description:
        'Back and biceps focused pull workout hitting lats, upper back, and arms.',
    category: WorkoutTemplateCategory.splits,
    difficulty: ExerciseDifficulty.intermediate,
    estimatedMinutes: 50,
    exercises: [
      TemplateExercise(exerciseId: 'conventional_deadlift', sets: 3, reps: 5),
      TemplateExercise(exerciseId: 'barbell_bent_over_row', sets: 4, reps: 8),
      TemplateExercise(exerciseId: 'lat_pulldown', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'seated_cable_row', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'barbell_curl', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'face_pull', sets: 3, reps: 15),
    ],
  ),

  // 3. Leg Day
  WorkoutTemplate(
    id: 'leg_day',
    name: 'Leg Day',
    description:
        'Complete lower body workout targeting quads, hamstrings, glutes, and calves.',
    category: WorkoutTemplateCategory.splits,
    difficulty: ExerciseDifficulty.intermediate,
    estimatedMinutes: 60,
    exercises: [
      TemplateExercise(exerciseId: 'barbell_back_squat', sets: 4, reps: 8),
      TemplateExercise(exerciseId: 'romanian_deadlift', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'leg_press', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'leg_curl', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'leg_extension', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'calf_raise', sets: 4, reps: 15),
    ],
  ),

  // 4. Upper Body
  WorkoutTemplate(
    id: 'upper_body',
    name: 'Upper Body',
    description:
        'Balanced upper body session hitting chest, back, shoulders, and arms.',
    category: WorkoutTemplateCategory.splits,
    difficulty: ExerciseDifficulty.intermediate,
    estimatedMinutes: 60,
    exercises: [
      TemplateExercise(exerciseId: 'barbell_bench_press', sets: 4, reps: 8),
      TemplateExercise(exerciseId: 'barbell_bent_over_row', sets: 4, reps: 8),
      TemplateExercise(exerciseId: 'overhead_press', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'lat_pulldown', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'dumbbell_curl', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'tricep_pushdown', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'dumbbell_lateral_raise', sets: 3, reps: 15),
    ],
  ),

  // 5. Lower Body
  WorkoutTemplate(
    id: 'lower_body',
    name: 'Lower Body',
    description:
        'Lower body workout with compound lifts and accessory work for quads, hamstrings, glutes, and calves.',
    category: WorkoutTemplateCategory.splits,
    difficulty: ExerciseDifficulty.intermediate,
    estimatedMinutes: 55,
    exercises: [
      TemplateExercise(exerciseId: 'barbell_back_squat', sets: 4, reps: 8),
      TemplateExercise(exerciseId: 'romanian_deadlift', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'leg_press', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'walking_lunge', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'leg_curl', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'calf_raise', sets: 4, reps: 15),
    ],
  ),

  // 6. PPL Day 1 (Push)
  WorkoutTemplate(
    id: 'ppl_push',
    name: 'PPL Day 1 (Push)',
    description:
        'Push day variant for a Push/Pull/Legs rotation with an added chest dip.',
    category: WorkoutTemplateCategory.splits,
    difficulty: ExerciseDifficulty.intermediate,
    estimatedMinutes: 60,
    exercises: [
      TemplateExercise(exerciseId: 'barbell_bench_press', sets: 4, reps: 8),
      TemplateExercise(exerciseId: 'incline_dumbbell_press', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'dumbbell_lateral_raise', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'overhead_press', sets: 3, reps: 8),
      TemplateExercise(exerciseId: 'tricep_pushdown', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'cable_crossover', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'chest_dip', sets: 3, reps: 10),
    ],
  ),

  // 7. PPL Day 2 (Pull)
  WorkoutTemplate(
    id: 'ppl_pull',
    name: 'PPL Day 2 (Pull)',
    description:
        'Pull day variant for a Push/Pull/Legs rotation with an added chin up.',
    category: WorkoutTemplateCategory.splits,
    difficulty: ExerciseDifficulty.intermediate,
    estimatedMinutes: 55,
    exercises: [
      TemplateExercise(exerciseId: 'conventional_deadlift', sets: 3, reps: 5),
      TemplateExercise(exerciseId: 'barbell_bent_over_row', sets: 4, reps: 8),
      TemplateExercise(exerciseId: 'lat_pulldown', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'seated_cable_row', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'barbell_curl', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'face_pull', sets: 3, reps: 15),
      TemplateExercise(exerciseId: 'chin_up', sets: 3, reps: 8),
    ],
  ),

  // 8. PPL Day 3 (Legs)
  WorkoutTemplate(
    id: 'ppl_legs',
    name: 'PPL Day 3 (Legs)',
    description:
        'Legs day variant for a Push/Pull/Legs rotation with an added hip thrust.',
    category: WorkoutTemplateCategory.splits,
    difficulty: ExerciseDifficulty.intermediate,
    estimatedMinutes: 65,
    exercises: [
      TemplateExercise(exerciseId: 'barbell_back_squat', sets: 4, reps: 8),
      TemplateExercise(exerciseId: 'romanian_deadlift', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'leg_press', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'leg_curl', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'leg_extension', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'calf_raise', sets: 4, reps: 15),
      TemplateExercise(exerciseId: 'hip_thrust', sets: 3, reps: 12),
    ],
  ),

  // ---------------------------------------------------------------------------
  // Category: Splits continued — Arnold Split (3 templates)
  // ---------------------------------------------------------------------------

  // 9. Arnold Split Day 1 (Chest & Back)
  WorkoutTemplate(
    id: 'arnold_chest_back',
    name: 'Arnold Split Day 1 (Chest & Back)',
    description:
        'Arnold-style superset workout pairing chest and back movements for maximum pump.',
    category: WorkoutTemplateCategory.splits,
    difficulty: ExerciseDifficulty.advanced,
    estimatedMinutes: 60,
    exercises: [
      TemplateExercise(exerciseId: 'barbell_bench_press', sets: 4, reps: 8),
      TemplateExercise(exerciseId: 'incline_dumbbell_press', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'dumbbell_fly', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'pull_up', sets: 4, reps: 8),
      TemplateExercise(exerciseId: 'barbell_bent_over_row', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'seated_cable_row', sets: 3, reps: 10),
    ],
  ),

  // 10. Arnold Split Day 2 (Shoulders & Arms)
  WorkoutTemplate(
    id: 'arnold_shoulders_arms',
    name: 'Arnold Split Day 2 (Shoulders & Arms)',
    description:
        'Arnold-style shoulder and arm workout with presses, raises, curls, and extensions.',
    category: WorkoutTemplateCategory.splits,
    difficulty: ExerciseDifficulty.advanced,
    estimatedMinutes: 55,
    exercises: [
      TemplateExercise(exerciseId: 'overhead_press', sets: 4, reps: 8),
      TemplateExercise(exerciseId: 'dumbbell_lateral_raise', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'rear_delt_fly', sets: 3, reps: 15),
      TemplateExercise(exerciseId: 'barbell_curl', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'hammer_curl', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'skull_crusher', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'tricep_pushdown', sets: 3, reps: 12),
    ],
  ),

  // 11. Arnold Split Day 3 (Legs)
  WorkoutTemplate(
    id: 'arnold_legs',
    name: 'Arnold Split Day 3 (Legs)',
    description:
        'Arnold-style leg workout with front squats, back squats, and full accessory work.',
    category: WorkoutTemplateCategory.splits,
    difficulty: ExerciseDifficulty.advanced,
    estimatedMinutes: 60,
    exercises: [
      TemplateExercise(exerciseId: 'barbell_back_squat', sets: 4, reps: 8),
      TemplateExercise(exerciseId: 'front_squat', sets: 3, reps: 8),
      TemplateExercise(exerciseId: 'romanian_deadlift', sets: 3, reps: 10),
      TemplateExercise(exerciseId: 'leg_extension', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'leg_curl', sets: 3, reps: 12),
      TemplateExercise(exerciseId: 'calf_raise', sets: 4, reps: 15),
    ],
  ),

  // ---------------------------------------------------------------------------
  // Category: Strength (2 templates)
  // ---------------------------------------------------------------------------

  // 12. 5x5 Strength A
  WorkoutTemplate(
    id: '5x5_strength_a',
    name: '5x5 Strength A',
    description:
        'Classic 5x5 strength program Day A: squat, bench, and row with heavy loads and long rest.',
    category: WorkoutTemplateCategory.strength,
    difficulty: ExerciseDifficulty.intermediate,
    estimatedMinutes: 45,
    exercises: [
      TemplateExercise(
        exerciseId: 'barbell_back_squat',
        sets: 5,
        reps: 5,
        restSeconds: 180,
      ),
      TemplateExercise(
        exerciseId: 'barbell_bench_press',
        sets: 5,
        reps: 5,
        restSeconds: 180,
      ),
      TemplateExercise(
        exerciseId: 'barbell_bent_over_row',
        sets: 5,
        reps: 5,
        restSeconds: 180,
      ),
    ],
  ),

  // 13. 5x5 Strength B
  WorkoutTemplate(
    id: '5x5_strength_b',
    name: '5x5 Strength B',
    description:
        'Classic 5x5 strength program Day B: squat, overhead press, and deadlift with heavy loads and long rest.',
    category: WorkoutTemplateCategory.strength,
    difficulty: ExerciseDifficulty.intermediate,
    estimatedMinutes: 40,
    exercises: [
      TemplateExercise(
        exerciseId: 'barbell_back_squat',
        sets: 5,
        reps: 5,
        restSeconds: 180,
      ),
      TemplateExercise(
        exerciseId: 'overhead_press',
        sets: 5,
        reps: 5,
        restSeconds: 180,
      ),
      TemplateExercise(
        exerciseId: 'conventional_deadlift',
        sets: 1,
        reps: 5,
        restSeconds: 180,
      ),
    ],
  ),

  // ---------------------------------------------------------------------------
  // Category: Cardio (3 templates)
  // ---------------------------------------------------------------------------

  // 14. HIIT 20 Min
  WorkoutTemplate(
    id: 'hiit_20_min',
    name: 'HIIT 20 Min',
    description:
        'High intensity interval training with burpees, jump rope, and mountain climbers in a Tabata-style format.',
    category: WorkoutTemplateCategory.cardio,
    difficulty: ExerciseDifficulty.intermediate,
    estimatedMinutes: 20,
    exercises: [
      TemplateExercise(
        exerciseId: 'burpee',
        sets: 8,
        reps: 1,
        restSeconds: 10,
        notes: '20 seconds on / 10 seconds off',
      ),
      TemplateExercise(
        exerciseId: 'jump_rope',
        sets: 8,
        reps: 1,
        restSeconds: 10,
        notes: '20 seconds on / 10 seconds off',
      ),
      TemplateExercise(
        exerciseId: 'mountain_climber',
        sets: 8,
        reps: 1,
        restSeconds: 10,
        notes: '20 seconds on / 10 seconds off',
      ),
    ],
  ),

  // 15. Steady State Cardio
  WorkoutTemplate(
    id: 'steady_state_cardio',
    name: 'Steady State Cardio',
    description:
        'Low-impact steady state cardio session with treadmill running and optional stationary cycling cooldown.',
    category: WorkoutTemplateCategory.cardio,
    difficulty: ExerciseDifficulty.beginner,
    estimatedMinutes: 45,
    exercises: [
      TemplateExercise(
        exerciseId: 'running_treadmill',
        sets: 1,
        reps: 1,
        restSeconds: 0,
        notes: '30-45 minutes at moderate pace',
      ),
      TemplateExercise(
        exerciseId: 'cycling_stationary',
        sets: 1,
        reps: 1,
        restSeconds: 0,
        notes: 'Optional 15 min cooldown',
      ),
    ],
  ),

  // 16. Interval Run
  WorkoutTemplate(
    id: 'interval_run',
    name: 'Interval Run',
    description:
        'Treadmill interval run alternating between fast 400m efforts and walking recovery.',
    category: WorkoutTemplateCategory.cardio,
    difficulty: ExerciseDifficulty.intermediate,
    estimatedMinutes: 30,
    exercises: [
      TemplateExercise(
        exerciseId: 'running_treadmill',
        sets: 6,
        reps: 1,
        restSeconds: 90,
        notes: '400m fast / 90s walk recovery',
      ),
    ],
  ),

  // ---------------------------------------------------------------------------
  // Category: Beginner (4 templates)
  // ---------------------------------------------------------------------------

  // 17. Full Body A
  WorkoutTemplate(
    id: 'full_body_a',
    name: 'Full Body A',
    description:
        'Beginner-friendly full body workout with core barbell compound movements.',
    category: WorkoutTemplateCategory.beginner,
    difficulty: ExerciseDifficulty.beginner,
    estimatedMinutes: 40,
    exercises: [
      TemplateExercise(
        exerciseId: 'barbell_back_squat',
        sets: 3,
        reps: 8,
        restSeconds: 120,
      ),
      TemplateExercise(
        exerciseId: 'barbell_bench_press',
        sets: 3,
        reps: 8,
        restSeconds: 120,
      ),
      TemplateExercise(
        exerciseId: 'barbell_bent_over_row',
        sets: 3,
        reps: 8,
        restSeconds: 120,
      ),
      TemplateExercise(
        exerciseId: 'overhead_press',
        sets: 2,
        reps: 8,
        restSeconds: 120,
      ),
      TemplateExercise(
        exerciseId: 'barbell_curl',
        sets: 2,
        reps: 10,
        restSeconds: 120,
      ),
    ],
  ),

  // 18. Full Body B
  WorkoutTemplate(
    id: 'full_body_b',
    name: 'Full Body B',
    description:
        'Beginner-friendly full body workout alternating with Full Body A for balanced weekly programming.',
    category: WorkoutTemplateCategory.beginner,
    difficulty: ExerciseDifficulty.beginner,
    estimatedMinutes: 40,
    exercises: [
      TemplateExercise(
        exerciseId: 'barbell_back_squat',
        sets: 3,
        reps: 8,
        restSeconds: 120,
      ),
      TemplateExercise(
        exerciseId: 'overhead_press',
        sets: 3,
        reps: 8,
        restSeconds: 120,
      ),
      TemplateExercise(
        exerciseId: 'conventional_deadlift',
        sets: 3,
        reps: 5,
        restSeconds: 120,
      ),
      TemplateExercise(
        exerciseId: 'lat_pulldown',
        sets: 3,
        reps: 10,
        restSeconds: 120,
      ),
      TemplateExercise(
        exerciseId: 'dumbbell_curl',
        sets: 2,
        reps: 10,
        restSeconds: 120,
      ),
    ],
  ),

  // 19. Full Body C (Dumbbell Only)
  WorkoutTemplate(
    id: 'full_body_c_dumbbell',
    name: 'Full Body C (Dumbbell Only)',
    description:
        'Dumbbell-only full body workout ideal for home gyms or beginners without barbell access.',
    category: WorkoutTemplateCategory.beginner,
    difficulty: ExerciseDifficulty.beginner,
    estimatedMinutes: 35,
    exercises: [
      TemplateExercise(
        exerciseId: 'goblet_squat',
        sets: 3,
        reps: 12,
        restSeconds: 60,
      ),
      TemplateExercise(
        exerciseId: 'dumbbell_bench_press',
        sets: 3,
        reps: 10,
        restSeconds: 60,
      ),
      TemplateExercise(
        exerciseId: 'single_arm_dumbbell_row',
        sets: 3,
        reps: 10,
        restSeconds: 60,
      ),
      TemplateExercise(
        exerciseId: 'dumbbell_lateral_raise',
        sets: 3,
        reps: 12,
        restSeconds: 60,
      ),
      TemplateExercise(
        exerciseId: 'dumbbell_curl',
        sets: 3,
        reps: 12,
        restSeconds: 60,
      ),
      TemplateExercise(
        exerciseId: 'overhead_tricep_extension',
        sets: 3,
        reps: 12,
        restSeconds: 60,
      ),
    ],
  ),

  // 20. Bodyweight Basics
  WorkoutTemplate(
    id: 'bodyweight_basics',
    name: 'Bodyweight Basics',
    description:
        'No-equipment bodyweight workout covering push, pull, legs, and core for absolute beginners.',
    category: WorkoutTemplateCategory.beginner,
    difficulty: ExerciseDifficulty.beginner,
    estimatedMinutes: 25,
    exercises: [
      TemplateExercise(
        exerciseId: 'push_up',
        sets: 3,
        reps: 15,
        restSeconds: 60,
      ),
      TemplateExercise(
        exerciseId: 'pull_up',
        sets: 3,
        reps: 8,
        restSeconds: 60,
      ),
      TemplateExercise(
        exerciseId: 'walking_lunge',
        sets: 3,
        reps: 12,
        restSeconds: 60,
      ),
      TemplateExercise(
        exerciseId: 'plank',
        sets: 3,
        reps: 1,
        restSeconds: 60,
        notes: 'Hold 30-60 seconds',
      ),
      TemplateExercise(
        exerciseId: 'mountain_climber',
        sets: 3,
        reps: 1,
        restSeconds: 60,
        notes: '30 seconds',
      ),
      TemplateExercise(
        exerciseId: 'crunch',
        sets: 3,
        reps: 15,
        restSeconds: 60,
      ),
    ],
  ),
];
