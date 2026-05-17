import 'dart:developer' as dev;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/micro_rdas.dart';
import '../core/utils/macro_targets.dart';
import '../data/curated_meal_plans.dart';
import '../data/us_food_database.dart';
import '../features/nutrition/domain/food_search_result.dart';
import '../models/completed_day.dart';
import '../models/enums.dart';
import '../models/food_entry.dart';
import '../models/meal.dart';
import '../models/nutrition_log.dart';
import '../services/open_food_facts_service.dart';
import '../services/spoonacular_service.dart';
import '../services/usda_service.dart';
import '../core/utils/logger.dart';
import 'dashboard_providers.dart';
import 'health_providers.dart';
import 'isar_provider.dart';
import 'user_profile_provider.dart';

/// Singleton service provider (kept for barcode lookups).
final openFoodFactsServiceProvider = Provider<OpenFoodFactsService>((ref) {
  return OpenFoodFactsService();
});

/// USDA FoodData Central service provider.
final usdaServiceProvider = Provider<UsdaService>((ref) {
  final apiKey = dotenv.env['USDA_API_KEY'] ?? '';
  return UsdaService(apiKey);
});

/// Spoonacular service — SECONDARY source. Primary food data comes from
/// USDA + the hardcoded restaurant builders; this provider is consumed
/// only as a fallback for branded products, barcode lookups that miss in
/// OpenFoodFacts, and restaurant items absent from our hardcoded catalogue.
final spoonacularServiceProvider = Provider<SpoonacularService>((ref) {
  final apiKey = dotenv.env['SPOONACULAR_API_KEY'] ?? '';
  return SpoonacularService(apiKey);
});

/// Which tab is selected on the Nutrition screen (0 = Meal Plans, 1 = Food Log).
final nutritionTabProvider = StateProvider<int>((ref) => 1);

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
            ironMgPer100g: item.ironMgPer100g > 0 ? item.ironMgPer100g : null,
            calciumMgPer100g: item.calciumMgPer100g > 0 ? item.calciumMgPer100g : null,
            vitaminCMgPer100g: item.vitaminCMgPer100g > 0 ? item.vitaminCMgPer100g : null,
            vitaminDMcgPer100g: item.vitaminDMcgPer100g > 0 ? item.vitaminDMcgPer100g : null,
            magnesiumMgPer100g: item.magnesiumMgPer100g > 0 ? item.magnesiumMgPer100g : null,
            potassiumMgPer100g: item.potassiumMgPer100g > 0 ? item.potassiumMgPer100g : null,
            zincMgPer100g: item.zincMgPer100g > 0 ? item.zincMgPer100g : null,
            vitaminB12McgPer100g: item.vitaminB12McgPer100g > 0 ? item.vitaminB12McgPer100g : null,
            folateMcgPer100g: item.folateMcgPer100g > 0 ? item.folateMcgPer100g : null,
          ))
      .toList();
});

/// Remote USDA FoodData Central search — async, network-dependent.
///
/// When USDA returns fewer than 3 hits we also query Spoonacular for branded
/// products and restaurant menu items, merging the two streams. USDA stays
/// first so generic foods are still preferred — Spoonacular fills the gaps.
final foodRemoteSearchProvider =
    FutureProvider.family<List<FoodSearchResult>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final usdaService = ref.read(usdaServiceProvider);
  final spoon = ref.read(spoonacularServiceProvider);

  final usdaResults = await usdaService.search(query);
  // Deduplicate against local results
  final localNames = ref
      .read(foodLocalSearchProvider(query))
      .map((r) => r.name.toLowerCase().trim())
      .toSet();
  final usdaFiltered = usdaResults
      .where((r) => !localNames.contains(r.name.toLowerCase().trim()))
      .toList();

  if (usdaFiltered.length >= 3) return usdaFiltered;

  // USDA was thin — supplement with Spoonacular branded/restaurant items.
  // Both calls are best-effort: any failure returns empty so the search
  // result list still surfaces whatever USDA produced.
  final results = await Future.wait([
    spoon.searchMenuItems(query).catchError((_) => <FoodSearchResult>[]),
    spoon.searchProducts(query).catchError((_) => <FoodSearchResult>[]),
  ]);
  final usdaNames = usdaFiltered
      .map((r) => r.name.toLowerCase().trim())
      .toSet();
  final spoonFiltered = [...results[0], ...results[1]]
      .where((r) =>
          !localNames.contains(r.name.toLowerCase().trim()) &&
          !usdaNames.contains(r.name.toLowerCase().trim()))
      .toList();
  return [...usdaFiltered, ...spoonFiltered];
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

/// Negative-cache key for barcodes we've already failed to resolve.
/// Stored as a SharedPreferences string list with `barcode|expiryMs` entries.
/// 24-hour TTL — long enough to skip the API hit on repeated scans, short
/// enough that newly-indexed products eventually become visible.
const _barcodeNegativeCacheKey = 'barcode_negative_cache';
const _barcodeNegativeCacheTtl = Duration(hours: 24);

Future<bool> _isInNegativeCache(String barcode) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_barcodeNegativeCacheKey) ?? const <String>[];
  final now = DateTime.now().millisecondsSinceEpoch;
  for (final entry in raw) {
    final parts = entry.split('|');
    if (parts.length != 2) continue;
    final expiry = int.tryParse(parts[1]) ?? 0;
    if (expiry > now && parts[0] == barcode) return true;
  }
  return false;
}

Future<void> _addToNegativeCache(String barcode) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_barcodeNegativeCacheKey) ?? const <String>[];
  final now = DateTime.now().millisecondsSinceEpoch;
  // Prune expired and the matching barcode (in case of duplicates).
  final kept = raw.where((e) {
    final parts = e.split('|');
    if (parts.length != 2) return false;
    final expiry = int.tryParse(parts[1]) ?? 0;
    return expiry > now && parts[0] != barcode;
  }).toList();
  final expiry = now + _barcodeNegativeCacheTtl.inMilliseconds;
  kept.add('$barcode|$expiry');
  await prefs.setStringList(_barcodeNegativeCacheKey, kept);
}

/// Look up a product by barcode. Tries OpenFoodFacts first (free), then
/// falls back to Spoonacular. Misses are recorded in a 24h negative cache
/// to avoid burning the Spoonacular quota on repeated dud scans.
final barcodeLookupProvider =
    FutureProvider.family<FoodSearchResult?, String>((ref, barcode) async {
  if (barcode.trim().isEmpty) return null;
  // Negative cache short-circuit — confirmed-not-found in the last 24h.
  if (await _isInNegativeCache(barcode)) return null;

  final off = ref.read(openFoodFactsServiceProvider);
  try {
    final fromOff = await off.getByBarcode(barcode);
    if (fromOff != null) return fromOff;
  } catch (_) {/* fall through to Spoonacular */}

  final spoon = ref.read(spoonacularServiceProvider);
  try {
    final fromSpoon = await spoon.getProductByBarcode(barcode);
    if (fromSpoon != null) return fromSpoon;
  } catch (_) {/* fall through to negative cache */}

  await _addToNegativeCache(barcode);
  return null;
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

    // Fire-and-forget: sync daily nutrition totals to Apple Health.
    if (ref.read(healthConnectedProvider) &&
        ref.read(healthPrefsProvider).syncNutrition) {
      ref
          .read(healthServiceProvider)
          .writeNutrition(calories: cal, protein: pro, carbs: carb, fat: fat)
          .catchError((Object e, StackTrace st) {
        AppLogger.error('Apple Health nutrition sync failed',
            error: e, stack: st);
        return false;
      });
    }
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

      // Debug: verify micronutrients were saved
      final saved = await isar.foodEntrys.get(entry.id);
      dev.log(
        '[addFoodEntry] "$name" id=${entry.id} '
        'iron=${saved?.ironMg} calcium=${saved?.calciumMg} '
        'vitC=${saved?.vitaminCMg} vitD=${saved?.vitaminDMcg} '
        'mag=${saved?.magnesiumMg} potassium=${saved?.potassiumMg} '
        'zinc=${saved?.zincMg} b12=${saved?.vitaminB12Mcg} '
        'folate=${saved?.folateMcg} sodium=${saved?.sodiumMg}',
        name: 'FitAI.Nutrition',
      );

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

// ---------------------------------------------------------------------------
// Import a curated meal plan into today's nutrition log
// ---------------------------------------------------------------------------

Future<bool> importMealPlan(
  WidgetRef ref, {
  required CuratedMealPlan plan,
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

      for (final planMeal in plan.meals) {
        var meal = log.meals
            .toList()
            .where((m) => m.type == planMeal.type)
            .firstOrNull;

        if (meal == null) {
          meal = Meal()
            ..type = planMeal.type
            ..time = now;
          await isar.meals.put(meal);
          log.meals.add(meal);
          await log.meals.save();
        }

        for (final food in planMeal.foods) {
          final entry = FoodEntry()
            ..name = food.name
            ..calories = food.calories
            ..protein = food.protein
            ..carbs = food.carbs
            ..fat = food.fat
            ..servingSize = food.servingSize
            ..servingUnit = food.servingUnit
            ..ironMg = food.ironMg > 0 ? food.ironMg : null
            ..calciumMg = food.calciumMg > 0 ? food.calciumMg : null
            ..vitaminCMg = food.vitaminCMg > 0 ? food.vitaminCMg : null
            ..vitaminDMcg = food.vitaminDMcg > 0 ? food.vitaminDMcg : null
            ..magnesiumMg = food.magnesiumMg > 0 ? food.magnesiumMg : null
            ..potassiumMg = food.potassiumMg > 0 ? food.potassiumMg : null
            ..zincMg = food.zincMg > 0 ? food.zincMg : null
            ..vitaminB12Mcg = food.vitaminB12Mcg > 0 ? food.vitaminB12Mcg : null
            ..folateMcg = food.folateMcg > 0 ? food.folateMcg : null
            ..sodiumMg = food.sodiumMg > 0 ? food.sodiumMg : null;
          await isar.foodEntrys.put(entry);
          meal.foodEntries.add(entry);
          await meal.foodEntries.save();
        }
      }

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
