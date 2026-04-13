import 'package:isar/isar.dart';
import 'enums.dart';

part 'personal_record.g.dart';

@collection
class PersonalRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late String exerciseName;

  late double weightKg;

  late int bestReps;

  late DateTime dateAchieved;

  @Enumerated(EnumType.ordinal)
  late MuscleGroup muscleGroup;
}
