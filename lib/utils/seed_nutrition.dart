import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../core/utils/logger.dart';
import '../models/completed_day.dart';
import '../models/enums.dart';
import '../models/food_entry.dart';
import '../models/meal.dart';
import '../models/nutrition_log.dart';
import '../models/supplement.dart';
import '../models/supplement_log.dart';

/// Result returned from [seedNutritionHistory] for the settings confirmation
/// dialog.
class SeedNutritionResult {
  const SeedNutritionResult({
    required this.days,
    required this.meals,
    required this.foodEntries,
    required this.completedDays,
    required this.supplements,
    required this.supplementLogs,
  });
  final int days;
  final int meals;
  final int foodEntries;
  final int completedDays;
  final int supplements;
  final int supplementLogs;
}

// ─── Seed data model ──────────────────────────────────────────────────────────

/// One logged food. When [group] is set, every food sharing the same group
/// within a meal is written with a common `mealGroupId` so the nutrition log
/// renders them as a single collapsible row (the restaurant-builder / saved-
/// meal affordance).
class _Food {
  const _Food(
    this.name,
    this.cal,
    this.p,
    this.c,
    this.f, {
    this.group,
    this.emoji,
  });
  final String name;
  final double cal;
  final double p;
  final double c;
  final double f;
  final String? group;
  final String? emoji;
}

class _MealSpec {
  const _MealSpec(this.type, this.hour, this.minute, this.foods);
  final MealType type;
  final int hour;
  final int minute;
  final List<_Food> foods;
}

class _DaySpec {
  const _DaySpec({required this.daysAgo, required this.meals, required this.completed});
  final int daysAgo;
  final List<_MealSpec> meals;
  final bool completed;
}

// ─── Reusable meals (macros from the FEATURE 1 spec where provided) ───────────

// Breakfasts (~480–560 cal).
const _eggsToastBanana = [
  _Food('Scrambled Eggs (3)', 210, 18, 1.5, 15),
  _Food('Whole Wheat Toast (2 slices)', 160, 8, 28, 2),
  _Food('Banana', 105, 1, 27, 0.4),
  _Food('Coffee with Milk', 30, 2, 3, 1),
];
const _proteinOatmeal = [
  _Food('Oatmeal', 300, 10, 54, 5),
  _Food('Whey Protein Scoop', 120, 25, 3, 1.5),
  _Food('Blueberries', 42, 0.5, 11, 0.2),
  _Food('Almond Butter', 98, 3, 3, 9),
];
const _greekYogurtBowl = [
  _Food('Greek Yogurt', 150, 25, 9, 0.4),
  _Food('Granola', 130, 3, 22, 4),
  _Food('Honey', 64, 0, 17, 0),
  _Food('Strawberries', 32, 0.7, 8, 0.3),
  _Food('Banana', 105, 1, 27, 0.4),
];

// Lunches (~665–690 cal).
const _chipotleBowl = [
  _Food('Chicken', 180, 32, 0, 5, group: 'Chipotle Chicken Bowl', emoji: '🌯'),
  _Food('White Rice', 210, 4, 40, 4, group: 'Chipotle Chicken Bowl', emoji: '🌯'),
  _Food('Black Beans', 130, 8, 22, 1, group: 'Chipotle Chicken Bowl', emoji: '🌯'),
  _Food('Fajita Veggies', 20, 1, 4, 0, group: 'Chipotle Chicken Bowl', emoji: '🌯'),
  _Food('Salsa', 25, 1, 5, 0, group: 'Chipotle Chicken Bowl', emoji: '🌯'),
  _Food('Cheese', 110, 6, 1, 9, group: 'Chipotle Chicken Bowl', emoji: '🌯'),
];
const _chickenSalad = [
  _Food('Grilled Chicken Salad', 450, 40, 15, 25),
  _Food('Whole Grain Pita', 170, 6, 34, 1.5),
  _Food('Hummus', 70, 2, 6, 5),
];
const _turkeySandwich = [
  _Food('Turkey Sandwich', 550, 35, 45, 20),
  _Food('Baby Carrots', 35, 1, 8, 0.2),
  _Food('String Cheese', 80, 7, 1, 6),
];

// Snacks (single items; some days log two).
const _proteinShake = _Food('Protein Shake', 160, 30, 5, 2);
const _apple = _Food('Apple', 95, 0.5, 25, 0.3);
const _yogurtGranola = _Food('Greek Yogurt with Granola', 250, 15, 30, 8);
const _beefJerky = _Food('Beef Jerky', 120, 20, 5, 2);
const _riceCakesPb = _Food('Rice Cakes with Peanut Butter', 200, 8, 22, 9);

// Dinners (~560–700 cal).
const _salmonDinner = [
  _Food('Grilled Salmon (6oz)', 350, 34, 0, 22, group: 'Grilled Salmon Dinner', emoji: '🐟'),
  _Food('Brown Rice', 215, 5, 45, 1.8, group: 'Grilled Salmon Dinner', emoji: '🐟'),
  _Food('Steamed Broccoli', 55, 4, 11, 0.6, group: 'Grilled Salmon Dinner', emoji: '🐟'),
];
const _chickenSweetPotato = [
  _Food('Grilled Chicken Breast', 300, 45, 0, 8, group: 'Chicken & Sweet Potato', emoji: '🍠'),
  _Food('Sweet Potato', 180, 4, 40, 0.3, group: 'Chicken & Sweet Potato', emoji: '🍠'),
  _Food('Asparagus', 40, 4, 8, 0.4, group: 'Chicken & Sweet Potato', emoji: '🍠'),
  _Food('Olive Oil', 40, 0, 0, 4.5, group: 'Chicken & Sweet Potato', emoji: '🍠'),
];
const _steakDinner = [
  _Food('Steak (6oz)', 420, 42, 0, 27, group: 'Steak Dinner', emoji: '🥩'),
  _Food('Mashed Potatoes', 210, 4, 30, 8, group: 'Steak Dinner', emoji: '🥩'),
  _Food('Green Beans', 35, 2, 8, 0.2, group: 'Steak Dinner', emoji: '🥩'),
  _Food('Butter', 35, 0, 0, 4, group: 'Steak Dinner', emoji: '🥩'),
];

_MealSpec _breakfast(List<_Food> foods) => _MealSpec(MealType.breakfast, 8, 0, foods);
_MealSpec _lunch(List<_Food> foods) => _MealSpec(MealType.lunch, 12, 30, foods);
_MealSpec _snack(List<_Food> foods) => _MealSpec(MealType.snack, 15, 30, foods);
_MealSpec _dinner(List<_Food> foods) => _MealSpec(MealType.dinner, 19, 0, foods);

/// 7 days (today + the previous 6), each a unique breakfast/lunch/snack/dinner
/// mix totalling ~2000–2600 kcal with a protein-forward macro split. Five of
/// the seven are marked completed (today and one mid-week day left open, which
/// reads more naturally than a perfect 7/7).
List<_DaySpec> _buildDays() => [
      _DaySpec(daysAgo: 0, completed: false, meals: [
        _breakfast(_eggsToastBanana),
        _lunch(_chipotleBowl),
        _snack([_proteinShake, _apple]),
        _dinner(_steakDinner),
      ]),
      _DaySpec(daysAgo: 1, completed: true, meals: [
        _breakfast(_proteinOatmeal),
        _lunch(_turkeySandwich),
        _snack([_yogurtGranola]),
        _dinner(_salmonDinner),
      ]),
      _DaySpec(daysAgo: 2, completed: true, meals: [
        _breakfast(_greekYogurtBowl),
        _lunch(_chickenSalad),
        _snack([_proteinShake, _beefJerky]),
        _dinner(_chickenSweetPotato),
      ]),
      _DaySpec(daysAgo: 3, completed: true, meals: [
        _breakfast(_eggsToastBanana),
        _lunch(_chipotleBowl),
        _snack([_yogurtGranola, _apple]),
        _dinner(_chickenSweetPotato),
      ]),
      _DaySpec(daysAgo: 4, completed: false, meals: [
        _breakfast(_proteinOatmeal),
        _lunch(_chickenSalad),
        _snack([_proteinShake]),
        _dinner(_steakDinner),
      ]),
      _DaySpec(daysAgo: 5, completed: true, meals: [
        _breakfast(_greekYogurtBowl),
        _lunch(_turkeySandwich),
        _snack([_proteinShake, _riceCakesPb]),
        _dinner(_salmonDinner),
      ]),
      _DaySpec(daysAgo: 6, completed: true, meals: [
        _breakfast(_eggsToastBanana),
        _lunch(_turkeySandwich),
        _snack([_yogurtGranola, _beefJerky]),
        _dinner(_steakDinner),
      ]),
    ];

// ─── Seed supplements ─────────────────────────────────────────────────────────

class _SuppDef {
  const _SuppDef(this.name, this.dosage, this.unit, this.timing);
  final String name;
  final String dosage;
  final String unit;
  final SupplementTiming timing;
}

const _seedSupplements = [
  _SuppDef('Multivitamin', '1', 'tablet', SupplementTiming.morning),
  _SuppDef('Whey Protein', '1', 'scoop', SupplementTiming.withMeal),
  _SuppDef('Creatine Monohydrate', '5', 'g', SupplementTiming.morning),
  _SuppDef('Fish Oil', '2', 'softgels', SupplementTiming.withMeal),
  _SuppDef('Vitamin D3', '2000', 'IU', SupplementTiming.morning),
];

// ─── Seeder ───────────────────────────────────────────────────────────────────

/// Populates the current user's nutrition log for the last 7 days with
/// realistic, varied meals, marks five days completed, ensures a default
/// supplement stack exists and logs it as taken every day, and reports the
/// counts written.
///
/// Idempotent: any existing [NutritionLog] / [CompletedDay] on the seeded
/// dates (and the seed supplements' logs in that window) are wiped before the
/// fresh batch is written, so re-running from Settings → Developer replaces
/// the seed in place instead of stacking duplicates.
///
/// [calorieTarget]/[proteinTarget]/[carbsTarget]/[fatTarget] stamp the
/// [CompletedDay] rows; pass the user's real targets when available, otherwise
/// the training-default fallbacks are used.
Future<SeedNutritionResult> seedNutritionHistory({
  required Isar isar,
  double calorieTarget = 2400,
  double proteinTarget = 180,
  double carbsTarget = 250,
  double fatTarget = 70,
}) async {
  final days = _buildDays();
  final now = DateTime.now();
  DateTime midnight(int daysAgo) {
    final d = now.subtract(Duration(days: daysAgo));
    return DateTime(d.year, d.month, d.day);
  }

  var mealsWritten = 0;
  var entriesWritten = 0;
  var completedWritten = 0;

  await isar.writeTxn(() async {
    for (final day in days) {
      final date = midnight(day.daysAgo);
      final dayEnd = date.add(const Duration(days: 1));

      // 1. Wipe any existing nutrition log (+ its meals & food entries) and
      //    completed-day row for this date so re-runs replace cleanly.
      final priorLogs = await isar.nutritionLogs
          .where()
          .dateBetween(date, dayEnd, includeUpper: false)
          .findAll();
      for (final log in priorLogs) {
        await log.meals.load();
        for (final meal in log.meals) {
          await meal.foodEntries.load();
          for (final entry in meal.foodEntries) {
            await isar.foodEntrys.delete(entry.id);
          }
          await isar.meals.delete(meal.id);
        }
        await isar.nutritionLogs.delete(log.id);
      }
      final priorCompleted =
          await isar.completedDays.where().dateEqualTo(date).findFirst();
      if (priorCompleted != null) {
        await isar.completedDays.delete(priorCompleted.id);
      }

      // 2. Fresh log for the day.
      final log = NutritionLog()..date = date;
      await isar.nutritionLogs.put(log);

      double dayCal = 0, dayPro = 0, dayCarb = 0, dayFat = 0;

      for (final mealSpec in day.meals) {
        if (mealSpec.foods.isEmpty) continue;
        final meal = Meal()
          ..type = mealSpec.type
          ..time = DateTime(
            date.year,
            date.month,
            date.day,
            mealSpec.hour,
            mealSpec.minute,
          );
        await isar.meals.put(meal);
        log.meals.add(meal);

        // Stable group ids per (day, meal) so combos collapse into one row.
        final groupIds = <String, String>{};

        for (final food in mealSpec.foods) {
          String? groupId;
          if (food.group != null) {
            groupId = groupIds.putIfAbsent(
              food.group!,
              () => 'seed-nutrition-${day.daysAgo}-${mealSpec.type.name}-'
                  '${food.group!.hashCode}',
            );
          }
          final entry = FoodEntry()
            ..name = food.name
            ..calories = food.cal
            ..protein = food.p
            ..carbs = food.c
            ..fat = food.f
            ..servingSize = 1
            ..servingUnit = 'serving'
            ..mealGroupId = groupId
            ..mealGroupName = food.group
            ..mealGroupEmoji = food.emoji;
          await isar.foodEntrys.put(entry);
          meal.foodEntries.add(entry);
          entriesWritten++;

          dayCal += food.cal;
          dayPro += food.p;
          dayCarb += food.c;
          dayFat += food.f;
        }
        await meal.foodEntries.save();
        mealsWritten++;
      }
      await log.meals.save();

      log
        ..totalCalories = dayCal
        ..totalProtein = dayPro
        ..totalCarbs = dayCarb
        ..totalFat = dayFat;
      await isar.nutritionLogs.put(log);

      // 3. Completed-day row.
      if (day.completed) {
        bool inRange(double consumed, double target) {
          if (target <= 0) return true;
          final ratio = consumed / target;
          return ratio >= 0.85 && ratio <= 1.15;
        }

        final completed = CompletedDay()
          ..date = date
          ..caloriesConsumed = dayCal
          ..proteinConsumed = dayPro
          ..carbsConsumed = dayCarb
          ..fatConsumed = dayFat
          ..calorieTarget = calorieTarget
          ..proteinTarget = proteinTarget
          ..carbsTarget = carbsTarget
          ..fatTarget = fatTarget
          ..macrosHit = inRange(dayPro, proteinTarget) &&
              inRange(dayCarb, carbsTarget) &&
              inRange(dayFat, fatTarget)
          ..completedAt = dayEnd.subtract(const Duration(hours: 3));
        await isar.completedDays.put(completed);
        completedWritten++;
      }
    }
  });

  // 4. Supplements — ensure the default stack exists (reuse by name), then log
  //    each as taken for every seeded day.
  final supplementIds = <int>[];
  await isar.writeTxn(() async {
    final existing = await isar.supplements.where().findAll();
    final byName = {for (final s in existing) s.name.toLowerCase(): s};
    for (final def in _seedSupplements) {
      final found = byName[def.name.toLowerCase()];
      if (found != null) {
        // Make sure it's active so it surfaces on the checklist.
        if (!found.isActive) {
          found.isActive = true;
          await isar.supplements.put(found);
        }
        supplementIds.add(found.id);
      } else {
        final supp = Supplement()
          ..name = def.name
          ..dosage = def.dosage
          ..unit = def.unit
          ..timing = def.timing
          ..isActive = true;
        await isar.supplements.put(supp);
        supplementIds.add(supp.id);
      }
    }
  });

  var logsWritten = 0;
  await isar.writeTxn(() async {
    // Wipe prior logs for these supplements within the 7-day window.
    final windowStart = midnight(days.length - 1);
    final allLogs = await isar.supplementLogs.where().findAll();
    for (final l in allLogs) {
      if (supplementIds.contains(l.supplementId) &&
          !l.date.isBefore(windowStart)) {
        await isar.supplementLogs.delete(l.id);
      }
    }
    for (final day in days) {
      final date = midnight(day.daysAgo);
      for (final id in supplementIds) {
        final log = SupplementLog()
          ..supplementId = id
          ..date = date
          ..taken = true
          ..timeTaken = DateTime(date.year, date.month, date.day, 8, 30);
        await isar.supplementLogs.put(log);
        logsWritten++;
      }
    }
  });

  if (kDebugMode) {
    debugPrint(
      '[SeedNutrition] ${days.length} days, $mealsWritten meals, '
      '$entriesWritten entries, $completedWritten completed, '
      '${supplementIds.length} supplements, $logsWritten supplement logs',
    );
  }
  AppLogger.log(
    'Nutrition seed: ${days.length} days / $entriesWritten food entries',
  );

  return SeedNutritionResult(
    days: days.length,
    meals: mealsWritten,
    foodEntries: entriesWritten,
    completedDays: completedWritten,
    supplements: supplementIds.length,
    supplementLogs: logsWritten,
  );
}
