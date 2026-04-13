import 'package:isar/isar.dart';
import 'custom_meal_plan_meal.dart';

part 'custom_meal_plan.g.dart';

@collection
class CustomMealPlan {
  Id id = Isar.autoIncrement;

  late String name;
  String? goal;
  late DateTime createdAt;
  double totalCalories = 0;
  double totalProtein = 0;
  double totalCarbs = 0;
  double totalFat = 0;

  final meals = IsarLinks<CustomMealPlanMeal>();
}
