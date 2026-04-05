import 'package:isar/isar.dart';
import 'workout.dart';
import 'workout_set.dart';

part 'workout_exercise.g.dart';

@collection
class WorkoutExercise {
  Id id = Isar.autoIncrement;

  late String name;
  late int order;

  final sets = IsarLinks<WorkoutSet>();

  @Backlink(to: 'exercises')
  final workout = IsarLinks<Workout>();
}
