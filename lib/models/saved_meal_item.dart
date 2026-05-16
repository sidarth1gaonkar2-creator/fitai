import 'package:isar/isar.dart';

part 'saved_meal_item.g.dart';

/// One food item inside a [SavedMeal]. We store the full nutritional row
/// alongside the FDC/barcode identifiers so re-logging a meal doesn't need
/// a network round-trip — the user gets the same totals they saw when they
/// saved it, even if the upstream USDA data has changed.
@collection
class SavedMealItem {
  Id id = Isar.autoIncrement;

  /// Foreign key — points at `SavedMeal.id`. Indexed so we can query items
  /// for a meal in O(log n).
  @Index()
  int savedMealId = 0;

  late String foodName;
  String? fdcId; // USDA FoodData Central ID
  String? barcode; // OpenFoodFacts barcode

  /// Serving size in grams (or the natural unit when [servingUnit] != 'g').
  double servingSize = 1.0;
  String servingUnit = 'serving';

  /// Number of servings the user logged. Total contribution to the meal is
  /// `<macro> * quantity`.
  double quantity = 1.0;

  // Per-serving nutrition snapshot.
  double calories = 0;
  double protein = 0;
  double carbs = 0;
  double fat = 0;

  // Optional micronutrients we surface in nutrition detail views.
  double? fiber;
  double? sugar;
  double? sodium;
}
