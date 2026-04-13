import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/custom_meal_plan.dart';
import '../models/custom_meal_plan_food.dart';
import '../models/custom_meal_plan_meal.dart';
import '../models/enums.dart';
import '../models/food_entry.dart';
import '../models/meal.dart';
import '../models/nutrition_log.dart';
import 'dashboard_providers.dart';
import 'isar_provider.dart';
import 'nutrition_providers.dart';

// ---------------------------------------------------------------------------
// All saved custom meal plans
// ---------------------------------------------------------------------------

final allCustomMealPlansProvider =
    FutureProvider<List<CustomMealPlan>>((ref) async {
  final isar = ref.watch(isarProvider);
  return isar.customMealPlans.where().sortByCreatedAtDesc().findAll();
});

// ---------------------------------------------------------------------------
// Save a new custom meal plan
// ---------------------------------------------------------------------------

Future<bool> saveCustomMealPlan(
  WidgetRef ref, {
  required String name,
  required String? goal,
  required Map<MealType, List<PlanFood>> meals,
}) async {
  final isar = ref.read(isarProvider);

  try {
    await isar.writeTxn(() async {
      double totalCal = 0, totalPro = 0, totalCarb = 0, totalFat = 0;

      final plan = CustomMealPlan()
        ..name = name
        ..goal = goal
        ..createdAt = DateTime.now();
      await isar.customMealPlans.put(plan);

      for (final entry in meals.entries) {
        if (entry.value.isEmpty) continue;

        final meal = CustomMealPlanMeal()..mealType = entry.key;
        await isar.customMealPlanMeals.put(meal);

        for (final food in entry.value) {
          final f = CustomMealPlanFood()
            ..name = food.name
            ..calories = food.calories
            ..protein = food.protein
            ..carbs = food.carbs
            ..fat = food.fat
            ..servingSize = food.servingSize
            ..servingUnit = food.servingUnit;
          await isar.customMealPlanFoods.put(f);
          meal.foods.add(f);

          totalCal += food.calories;
          totalPro += food.protein;
          totalCarb += food.carbs;
          totalFat += food.fat;
        }
        await meal.foods.save();

        plan.meals.add(meal);
      }
      await plan.meals.save();

      plan
        ..totalCalories = totalCal
        ..totalProtein = totalPro
        ..totalCarbs = totalCarb
        ..totalFat = totalFat;
      await isar.customMealPlans.put(plan);
    });

    ref.invalidate(allCustomMealPlansProvider);
    return true;
  } catch (_) {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Delete a custom meal plan (cascade)
// ---------------------------------------------------------------------------

Future<bool> deleteCustomMealPlan(WidgetRef ref, int planId) async {
  final isar = ref.read(isarProvider);

  try {
    await isar.writeTxn(() async {
      final plan = await isar.customMealPlans.get(planId);
      if (plan == null) return;

      await plan.meals.load();
      for (final meal in plan.meals) {
        await meal.foods.load();
        for (final food in meal.foods) {
          await isar.customMealPlanFoods.delete(food.id);
        }
        await isar.customMealPlanMeals.delete(meal.id);
      }
      await isar.customMealPlans.delete(planId);
    });

    ref.invalidate(allCustomMealPlansProvider);
    return true;
  } catch (_) {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Import a custom meal plan into today's nutrition log
// ---------------------------------------------------------------------------

Future<bool> importCustomMealPlan(WidgetRef ref, int planId) async {
  final isar = ref.read(isarProvider);

  try {
    await isar.writeTxn(() async {
      final plan = await isar.customMealPlans.get(planId);
      if (plan == null) return;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      var log = await isar.nutritionLogs
          .where()
          .dateBetween(startOfDay, endOfDay, includeUpper: false)
          .findFirst();

      if (log == null) {
        log = NutritionLog()..date = startOfDay;
        await isar.nutritionLogs.put(log);
      }

      await log.meals.load();
      await plan.meals.load();

      for (final planMeal in plan.meals) {
        var meal = log.meals
            .toList()
            .where((m) => m.type == planMeal.mealType)
            .firstOrNull;

        if (meal == null) {
          meal = Meal()
            ..type = planMeal.mealType
            ..time = now;
          await isar.meals.put(meal);
          log.meals.add(meal);
          await log.meals.save();
        }

        await planMeal.foods.load();
        for (final food in planMeal.foods) {
          final entry = FoodEntry()
            ..name = food.name
            ..calories = food.calories
            ..protein = food.protein
            ..carbs = food.carbs
            ..fat = food.fat
            ..servingSize = food.servingSize
            ..servingUnit = food.servingUnit;
          await isar.foodEntrys.put(entry);
          meal.foodEntries.add(entry);
          await meal.foodEntries.save();
        }
      }

      // Recalculate totals
      await log.meals.load();
      double totalCal = 0, totalPro = 0, totalCarb = 0, totalFatV = 0;
      for (final m in log.meals) {
        await m.foodEntries.load();
        for (final e in m.foodEntries) {
          totalCal += e.calories;
          totalPro += e.protein;
          totalCarb += e.carbs;
          totalFatV += e.fat;
        }
      }
      log
        ..totalCalories = totalCal
        ..totalProtein = totalPro
        ..totalCarbs = totalCarb
        ..totalFat = totalFatV;
      await isar.nutritionLogs.put(log);
    });

    ref.invalidate(todayNutritionProvider);
    ref.invalidate(todayMealsProvider);
    ref.invalidate(streakProvider);
    ref.invalidate(todayMicronutrientsProvider);
    return true;
  } catch (_) {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Simple DTO used by the Create Plan screen
// ---------------------------------------------------------------------------

class PlanFood {
  const PlanFood({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.servingSize,
    this.servingUnit,
  });

  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? servingSize;
  final String? servingUnit;
}

