import 'package:isar/isar.dart';

part 'saved_meal.g.dart';

/// A reusable named combination of food entries that a user has logged
/// before. Separate from [Meal] (which represents a single day's meal slot)
/// — saved meals are persistent templates the user can re-log with one tap.
@collection
class SavedMeal {
  Id id = Isar.autoIncrement;

  late String name;

  /// Optional emoji shown in the meal card (e.g. 🥗 🍳 🥤). Stored as a
  /// single grapheme string rather than a code-point int so we don't have
  /// to deal with surrogate pairs at the call sites.
  String? emoji;

  DateTime createdAt = DateTime.now();

  @Index()
  DateTime lastUsedAt = DateTime.now();

  /// Incremented every time the user logs this meal. Used by
  /// `frequentMealsProvider` to surface most-used meals first.
  @Index()
  int useCount = 0;

  // Cached aggregate macros so the list screen doesn't need to load
  // every item collection. Recomputed on save + on each log-use.
  double totalCalories = 0;
  double totalProtein = 0;
  double totalCarbs = 0;
  double totalFat = 0;
}
