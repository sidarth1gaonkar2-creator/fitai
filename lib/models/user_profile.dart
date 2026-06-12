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

  // --- Custom nutrition-goal overrides (Build 75) ---------------------------
  // When non-null these OVERRIDE the goal-derived daily targets; null means
  // "use the value derived from tdee + goal". Set by the AI Coach goal card;
  // cleared when the user changes goal type in the manual editor. Always read
  // through resolveDailyTargets() so every surface (and the AI context) agrees.
  double? calorieGoal;
  double? proteinGoalG;
  double? carbsGoalG;
  double? fatGoalG;

  DateTime createdAt = DateTime.now();
}
