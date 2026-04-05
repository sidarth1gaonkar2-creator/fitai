import 'package:isar/isar.dart';
import 'enums.dart';

part 'user_profile.g.dart';

@collection
class UserProfile {
  Id id = Isar.autoIncrement;

  late String name;
  late int age;

  @enumerated
  late Sex sex;

  late double weight; // kg
  late double height; // cm

  @enumerated
  late Goal goal;

  @enumerated
  late ActivityLevel activityLevel;

  late double tdee;

  DateTime createdAt = DateTime.now();
}
