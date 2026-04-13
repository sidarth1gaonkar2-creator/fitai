class ActiveWorkoutState {
  const ActiveWorkoutState({
    this.title = '',
    this.exercises = const [],
    required this.startTime,
    this.isSaving = false,
    this.restTimerSeconds,
    this.prExerciseName,
    this.editingWorkoutId,
    this.newPRs = const [],
  });

  final String title;
  final List<ActiveExercise> exercises;
  final DateTime startTime;
  final bool isSaving;
  final int? restTimerSeconds;
  final String? prExerciseName;
  final int? editingWorkoutId;
  final List<String> newPRs;

  ActiveWorkoutState copyWith({
    String? title,
    List<ActiveExercise>? exercises,
    DateTime? startTime,
    bool? isSaving,
    int? Function()? restTimerSeconds,
    String? Function()? prExerciseName,
    int? Function()? editingWorkoutId,
    List<String>? newPRs,
  }) {
    return ActiveWorkoutState(
      title: title ?? this.title,
      exercises: exercises ?? this.exercises,
      startTime: startTime ?? this.startTime,
      isSaving: isSaving ?? this.isSaving,
      restTimerSeconds:
          restTimerSeconds != null ? restTimerSeconds() : this.restTimerSeconds,
      prExerciseName:
          prExerciseName != null ? prExerciseName() : this.prExerciseName,
      editingWorkoutId:
          editingWorkoutId != null ? editingWorkoutId() : this.editingWorkoutId,
      newPRs: newPRs ?? this.newPRs,
    );
  }
}

class ActiveExercise {
  const ActiveExercise({
    required this.name,
    required this.order,
    this.sets = const [],
  });

  final String name;
  final int order;
  final List<ActiveSet> sets;

  ActiveExercise copyWith({
    String? name,
    int? order,
    List<ActiveSet>? sets,
  }) {
    return ActiveExercise(
      name: name ?? this.name,
      order: order ?? this.order,
      sets: sets ?? this.sets,
    );
  }
}

class ActiveSet {
  const ActiveSet({
    this.reps = 0,
    this.weight = 0,
    this.isCompleted = false,
    required this.order,
    this.previousReps,
    this.previousWeight,
  });

  final int reps;
  final double weight;
  final bool isCompleted;
  final int order;
  final int? previousReps;
  final double? previousWeight;

  ActiveSet copyWith({
    int? reps,
    double? weight,
    bool? isCompleted,
    int? order,
    int? Function()? previousReps,
    double? Function()? previousWeight,
  }) {
    return ActiveSet(
      reps: reps ?? this.reps,
      order: order ?? this.order,
      weight: weight ?? this.weight,
      isCompleted: isCompleted ?? this.isCompleted,
      previousReps:
          previousReps != null ? previousReps() : this.previousReps,
      previousWeight:
          previousWeight != null ? previousWeight() : this.previousWeight,
    );
  }
}
