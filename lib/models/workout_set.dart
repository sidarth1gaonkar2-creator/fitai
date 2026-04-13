import 'package:isar/isar.dart';
import 'workout_exercise.dart';

part 'workout_set.g.dart';

@collection
class WorkoutSet {
  Id id = Isar.autoIncrement;

  late int reps;
  late double weight;
  bool isCompleted = false;
  late int order;

  @Index()
  String? exerciseName;

  @Backlink(to: 'sets')
  final exercise = IsarLinks<WorkoutExercise>();
}
