import 'package:isar/isar.dart';
import 'custom_meal_plan_meal.dart';

part 'custom_meal_plan_food.g.dart';

@collection
class CustomMealPlanFood {
  Id id = Isar.autoIncrement;

  late String name;
  late double calories;
  late double protein;
  late double carbs;
  late double fat;
  double? servingSize;
  String? servingUnit;

  double? fibre;
  double? sugar;
  double? sodiumMg;
  double? vitaminDMcg;
  double? ironMg;
  double? calciumMg;
  double? vitaminCMg;
  double? magnesiumMg;
  double? potassiumMg;
  double? zincMg;
  double? vitaminB12Mcg;
  double? folateMcg;

  @Backlink(to: 'foods')
  final meal = IsarLinks<CustomMealPlanMeal>();
}
