import 'package:isar/isar.dart';

part 'completed_day.g.dart';

@collection
class CompletedDay {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late DateTime date;

  late double caloriesConsumed;
  late double proteinConsumed;
  late double carbsConsumed;
  late double fatConsumed;
  late double calorieTarget;
  late double proteinTarget;
  late double carbsTarget;
  late double fatTarget;

  bool macrosHit = false;

  DateTime completedAt = DateTime.now();
}
