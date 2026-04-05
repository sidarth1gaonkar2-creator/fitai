import 'package:isar/isar.dart';
import 'meal.dart';

part 'nutrition_log.g.dart';

@collection
class NutritionLog {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late DateTime date;

  double totalCalories = 0;
  double totalProtein = 0;
  double totalCarbs = 0;
  double totalFat = 0;

  final meals = IsarLinks<Meal>();
}
