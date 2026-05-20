import 'package:isar/isar.dart';
import 'meal.dart';

part 'food_entry.g.dart';

@collection
class FoodEntry {
  Id id = Isar.autoIncrement;

  late String name;
  late double calories;
  late double protein;
  late double carbs;
  late double fat;
  double? servingSize;
  String? servingUnit;

  // Micronutrients (nullable — most entries won't have full data)
  double? vitaminDMcg;
  double? ironMg;
  double? calciumMg;
  double? vitaminCMg;
  double? magnesiumMg;
  double? sodiumMg;
  double? potassiumMg;
  double? zincMg;
  double? vitaminB12Mcg;
  double? folateMcg;

  // Extended macros
  double? fibre;
  double? sugar;

  // Grouping — set when this entry was logged as part of a saved meal or a
  // restaurant builder. Entries that share a [mealGroupId] render as a
  // single collapsible row in the nutrition log. Existing entries without
  // a group id continue to display as standalone rows.
  String? mealGroupId;
  String? mealGroupName;
  String? mealGroupEmoji;

  @Backlink(to: 'foodEntries')
  final meal = IsarLinks<Meal>();
}
