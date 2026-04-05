import 'package:isar/isar.dart';
import 'enums.dart';
import 'food_entry.dart';
import 'nutrition_log.dart';

part 'meal.g.dart';

@collection
class Meal {
  Id id = Isar.autoIncrement;

  @enumerated
  late MealType type;

  DateTime? time;

  final foodEntries = IsarLinks<FoodEntry>();

  @Backlink(to: 'meals')
  final nutritionLog = IsarLinks<NutritionLog>();
}
