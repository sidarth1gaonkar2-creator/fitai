import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../core/constants/micro_rdas.dart';
import '../core/utils/macro_targets.dart';
import '../data/us_food_database.dart';
import '../features/nutrition/domain/food_search_result.dart';
import '../models/completed_day.dart';
import '../models/enums.dart';
import '../models/food_entry.dart';
import '../models/meal.dart';
import '../models/nutrition_log.dart';
import '../services/open_food_facts_service.dart';
import 'dashboard_providers.dart';
import 'isar_provider.dart';
import 'user_profile_provider.dart';

/// Singleton service provider.
final openFoodFactsServiceProvider = Provider<OpenFoodFactsService>((ref) {
  return OpenFoodFactsService();
});

/// Today's meals grouped by MealType, with their food entries loaded.
final todayMealsProvider =
    FutureProvider<Map<MealType, List<FoodEntry>>>((ref) async {
  final isar = ref.watch(isarProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final log = await isar.nutritionLogs
      .where()
      .dateBetween(startOfDay, endOfDay, includeUpper: false)
      .findFirst();

  final result = <MealType, List<FoodEntry>>{
    MealType.breakfast: [],
    MealType.lunch: [],
    MealType.dinner: [],
    MealType.snack: [],
  };

  if (log == null) return result;

  await log.meals.load();
  for (final meal in log.meals) {
    await meal.foodEntries.load();
    result[meal.type] = meal.foodEntries.toList();
  }

  return result;
});

// ---------------------------------------------------------------------------
// Food search — dual provider (local instant + remote async)
// ---------------------------------------------------------------------------

/// Local food database search — synchronous, instant results.
final foodLocalSearchProvider =
    Provider.family<List<FoodSearchResult>, String>((ref, query) {
  if (query.trim().isEmpty) return [];
  final localItems = searchLocalFoods(query);
  return localItems
      .map((item) => FoodSearchResult(
            name: item.name,
            brand: item.brand,
            caloriesPer100g: item.caloriesPer100g,
            proteinPer100g: item.proteinPer100g,
            carbsPer100g: item.carbsPer100g,
            fatPer100g: item.fatPer100g,
            defaultServingSize: item.servingGrams,
            servingUnit: 'g',
            fibrePer100g: item.fibrePer100g,
            sugarPer100g: item.sugarPer100g,
            sodiumMgPer100g: item.sodiumMgPer100g,
            servingDescription: item.servingDescription,
            source: FoodSource.localDb,
          ))
      .toList();
});

/// Remote Open Food Facts search — async, network-dependent.
final foodRemoteSearchProvider =
    FutureProvider.family<List<FoodSearchResult>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final service = ref.read(openFoodFactsServiceProvider);
  final results = await service.search(query);
  // Deduplicate against local results
  final localNames = ref
      .read(foodLocalSearchProvider(query))
      .map((r) => r.name.toLowerCase().trim())
      .toSet();
  return results
      .where((r) => !localNames.contains(r.name.toLowerCase().trim()))
      .toList();
});

/// Legacy provider kept for backward compatibility (barcode lookup etc.)
final foodSearchProvider =
    FutureProvider.family<List<FoodSearchResult>, String>((ref, query) async {
  final local = ref.read(foodLocalSearchProvider(query));
  List<FoodSearchResult> remote;
  try {
    remote = await ref.watch(foodRemoteSearchProvider(query).future);
  } catch (_) {
    remote = [];
  }
  return [...local, ...remote];
});

/// Look up a product by barcode.
final barcodeLookupProvider =
    FutureProvider.family<FoodSearchResult?, String>((ref, barcode) async {
  final service = ref.read(openFoodFactsServiceProvider);
  return service.getByBarcode(barcode);
});

// ---------------------------------------------------------------------------
// Daily targets
// ---------------------------------------------------------------------------

class DailyTargets {
  const DailyTargets({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
}

final dailyTargetsProvider = FutureProvider<DailyTargets?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null) return null;
  final macros = macroTargetsFor(tdee: profile.tdee, goal: profile.goal);
  return DailyTargets(
    calories: profile.tdee,
    protein: macros.protein,
    carbs: macros.carbs,
    fat: macros.fat,
  );
});

// ---------------------------------------------------------------------------
// Micronutrient aggregation
// ---------------------------------------------------------------------------

final todayMicronutrientsProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final meals = await ref.watch(todayMealsProvider.future);
  final totals = <String, double>{};
  for (final key in microRdaTargets.keys) {
    totals[key] = 0;
  }

  for (final entries in meals.values) {
    for (final e in entries) {
      totals['Vitamin D'] = totals['Vitamin D']! + (e.vitaminDMcg ?? 0);
      totals['Iron'] = totals['Iron']! + (e.ironMg ?? 0);
      totals['Calcium'] = totals['Calcium']! + (e.calciumMg ?? 0);
      totals['Vitamin C'] = totals['Vitamin C']! + (e.vitaminCMg ?? 0);
      totals['Magnesium'] = totals['Magnesium']! + (e.magnesiumMg ?? 0);
      totals['Sodium'] = totals['Sodium']! + (e.sodiumMg ?? 0);
      totals['Potassium'] = totals['Potassium']! + (e.potassiumMg ?? 0);
      totals['Zinc'] = totals['Zinc']! + (e.zincMg ?? 0);
      totals['Vitamin B12'] =
          totals['Vitamin B12']! + (e.vitaminB12Mcg ?? 0);
      totals['Folate'] = totals['Folate']! + (e.folateMcg ?? 0);
    }
  }

  return totals;
});

// ---------------------------------------------------------------------------
// Completed day
// ---------------------------------------------------------------------------

final todayCompletedDayProvider =
    FutureProvider<CompletedDay?>((ref) async {
  final isar = ref.watch(isarProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return isar.completedDays.where().dateEqualTo(today).findFirst();
});

Future<bool> completeDay(WidgetRef ref) async {
  final isar = ref.read(isarProvider);
  final targets = await ref.read(dailyTargetsProvider.future);
  final nutrition = ref.read(todayNutritionProvider).valueOrNull;
  if (targets == null || nutrition == null) return false;

  final cal = nutrition.totalCalories;
  final pro = nutrition.totalProtein;
  final carb = nutrition.totalCarbs;
  final fat = nutrition.totalFat;

  bool inRange(double consumed, double target) {
    if (target <= 0) return true;
    final ratio = consumed / target;
    return ratio >= 0.90 && ratio <= 1.10;
  }

  final macrosHit = inRange(pro, targets.protein) &&
      inRange(carb, targets.carbs) &&
      inRange(fat, targets.fat);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  try {
    await isar.writeTxn(() async {
      // Check for existing record
      final existing =
          await isar.completedDays.where().dateEqualTo(today).findFirst();
      if (existing != null) return; // Already completed

      final day = CompletedDay()
        ..date = today
        ..caloriesConsumed = cal
        ..proteinConsumed = pro
        ..carbsConsumed = carb
        ..fatConsumed = fat
        ..calorieTarget = targets.calories
        ..proteinTarget = targets.protein
        ..carbsTarget = targets.carbs
        ..fatTarget = targets.fat
        ..macrosHit = macrosHit
        ..completedAt = now;
      await isar.completedDays.put(day);
    });

    ref.invalidate(todayCompletedDayProvider);
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> uncompleteDay(WidgetRef ref) async {
  final isar = ref.read(isarProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  try {
    await isar.writeTxn(() async {
      final existing =
          await isar.completedDays.where().dateEqualTo(today).findFirst();
      if (existing != null) {
        await isar.completedDays.delete(existing.id);
      }
    });

    ref.invalidate(todayCompletedDayProvider);
    return true;
  } catch (_) {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Add / delete food entry
// ---------------------------------------------------------------------------

Future<bool> addFoodEntry(
  WidgetRef ref, {
  required MealType mealType,
  required String name,
  required double calories,
  required double protein,
  required double carbs,
  required double fat,
  required double servingSize,
  required String servingUnit,
  double? fibre,
  double? sugar,
  double? sodiumMg,
  double? vitaminDMcg,
  double? ironMg,
  double? calciumMg,
  double? vitaminCMg,
  double? magnesiumMg,
  double? potassiumMg,
  double? zincMg,
  double? vitaminB12Mcg,
  double? folateMcg,
}) async {
  final isar = ref.read(isarProvider);

  try {
    await isar.writeTxn(() async {
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
      var meal =
          log.meals.toList().where((m) => m.type == mealType).firstOrNull;

      if (meal == null) {
        meal = Meal()
          ..type = mealType
          ..time = now;
        await isar.meals.put(meal);
        log.meals.add(meal);
        await log.meals.save();
      }

      final entry = FoodEntry()
        ..name = name
        ..calories = calories
        ..protein = protein
        ..carbs = carbs
        ..fat = fat
        ..servingSize = servingSize
        ..servingUnit = servingUnit
        ..fibre = fibre
        ..sugar = sugar
        ..sodiumMg = sodiumMg
        ..vitaminDMcg = vitaminDMcg
        ..ironMg = ironMg
        ..calciumMg = calciumMg
        ..vitaminCMg = vitaminCMg
        ..magnesiumMg = magnesiumMg
        ..potassiumMg = potassiumMg
        ..zincMg = zincMg
        ..vitaminB12Mcg = vitaminB12Mcg
        ..folateMcg = folateMcg;
      await isar.foodEntrys.put(entry);
      meal.foodEntries.add(entry);
      await meal.foodEntries.save();

      // Recalculate totals
      await log.meals.load();
      double totalCal = 0, totalPro = 0, totalCarb = 0, totalFat = 0;
      for (final m in log.meals) {
        await m.foodEntries.load();
        for (final e in m.foodEntries) {
          totalCal += e.calories;
          totalPro += e.protein;
          totalCarb += e.carbs;
          totalFat += e.fat;
        }
      }
      log.totalCalories = totalCal;
      log.totalProtein = totalPro;
      log.totalCarbs = totalCarb;
      log.totalFat = totalFat;
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

Future<bool> deleteFoodEntry(WidgetRef ref, int entryId) async {
  final isar = ref.read(isarProvider);

  try {
    await isar.writeTxn(() async {
      await isar.foodEntrys.delete(entryId);

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final log = await isar.nutritionLogs
          .where()
          .dateBetween(startOfDay, endOfDay, includeUpper: false)
          .findFirst();

      if (log != null) {
        await log.meals.load();
        double totalCal = 0, totalPro = 0, totalCarb = 0, totalFat = 0;
        for (final m in log.meals) {
          await m.foodEntries.load();
          for (final e in m.foodEntries) {
            totalCal += e.calories;
            totalPro += e.protein;
            totalCarb += e.carbs;
            totalFat += e.fat;
          }
        }
        log.totalCalories = totalCal;
        log.totalProtein = totalPro;
        log.totalCarbs = totalCarb;
        log.totalFat = totalFat;
        await isar.nutritionLogs.put(log);
      }
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
