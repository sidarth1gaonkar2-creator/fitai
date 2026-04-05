import 'package:isar/isar.dart';
import 'workout_exercise.dart';

part 'workout.g.dart';

@collection
class Workout {
  Id id = Isar.autoIncrement;

  late String title;
  late DateTime date;
  int? durationMinutes;
  String? notes;

  final exercises = IsarLinks<WorkoutExercise>();
}
