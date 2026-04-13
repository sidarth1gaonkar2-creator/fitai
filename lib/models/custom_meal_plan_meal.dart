import 'package:isar/isar.dart';
import 'custom_meal_plan.dart';
import 'custom_meal_plan_food.dart';
import 'enums.dart';

part 'custom_meal_plan_meal.g.dart';

@collection
class CustomMealPlanMeal {
  Id id = Isar.autoIncrement;

  @enumerated
  late MealType mealType;

  final foods = IsarLinks<CustomMealPlanFood>();

  @Backlink(to: 'meals')
  final plan = IsarLinks<CustomMealPlan>();
}
