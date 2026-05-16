import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../core/utils/logger.dart';
import '../features/nutrition/domain/food_search_result.dart';
import '../models/enums.dart';
import '../models/food_entry.dart';
import '../models/meal.dart';
import '../models/nutrition_log.dart';
import '../models/saved_meal.dart';
import '../models/saved_meal_item.dart';
import 'dashboard_providers.dart';
import 'isar_provider.dart';
import 'nutrition_providers.dart';

/// All saved meals, sorted by most recently used.
final savedMealsProvider = FutureProvider<List<SavedMeal>>((ref) async {
  final isar = ref.watch(isarProvider);
  return isar.savedMeals.where().sortByLastUsedAtDesc().findAll();
});

/// Top 5 most-used meals for the "Frequently Used" carousel. Falls back to
/// recently-saved if the user has no usage history yet.
final frequentMealsProvider = FutureProvider<List<SavedMeal>>((ref) async {
  final isar = ref.watch(isarProvider);
  final byUse =
      await isar.savedMeals.where().sortByUseCountDesc().limit(5).findAll();
  if (byUse.isNotEmpty && byUse.first.useCount > 0) return byUse;
  return isar.savedMeals.where().sortByCreatedAtDesc().limit(5).findAll();
});

/// Items belonging to a specific saved meal.
final savedMealItemsProvider =
    FutureProvider.family<List<SavedMealItem>, int>((ref, mealId) async {
  final isar = ref.watch(isarProvider);
  return isar.savedMealItems
      .where()
      .savedMealIdEqualTo(mealId)
      .findAll();
});

/// Saved meals filtered by a free-text query (case-insensitive substring).
final savedMealSearchProvider =
    FutureProvider.family<List<SavedMeal>, String>((ref, query) async {
  final all = await ref.watch(savedMealsProvider.future);
  if (query.trim().isEmpty) return all;
  final q = query.toLowerCase();
  return all.where((m) => m.name.toLowerCase().contains(q)).toList();
});

/// Saved meals where the meal name OR any item's food name matches [query].
/// Used by the food search screen's "Log entire saved meal?" suggestion.
final savedMealsMatchingProvider =
    FutureProvider.autoDispose.family<List<SavedMeal>, String>(
        (ref, query) async {
  final q = query.trim().toLowerCase();
  if (q.length < 2) return const <SavedMeal>[];
  final isar = ref.watch(isarProvider);
  final all = await isar.savedMeals.where().findAll();
  final matched = <SavedMeal>[];
  for (final meal in all) {
    if (meal.name.toLowerCase().contains(q)) {
      matched.add(meal);
      continue;
    }
    final items = await isar.savedMealItems
        .where()
        .savedMealIdEqualTo(meal.id)
        .findAll();
    if (items.any((it) => it.foodName.toLowerCase().contains(q))) {
      matched.add(meal);
    }
  }
  // Most-used first so the strongest candidate is most prominent.
  matched.sort((a, b) => b.useCount.compareTo(a.useCount));
  return matched.take(3).toList();
});

// ───────────────────────────────────────────────────────────────────────────
// Mutations
// ───────────────────────────────────────────────────────────────────────────

/// Creates a new saved meal in Isar. [items] should have their nutrition
/// already filled in — this function copies them and overrides their
/// `savedMealId` to the freshly-inserted parent's id.
///
/// Returns the new `SavedMeal.id`.
Future<int> saveMeal(
  WidgetRef ref, {
  required String name,
  String? emoji,
  required List<SavedMealItem> items,
}) async {
  final isar = ref.read(isarProvider);
  double totalCal = 0, totalPro = 0, totalCarb = 0, totalFat = 0;
  for (final item in items) {
    totalCal += item.calories * item.quantity;
    totalPro += item.protein * item.quantity;
    totalCarb += item.carbs * item.quantity;
    totalFat += item.fat * item.quantity;
  }

  final meal = SavedMeal()
    ..name = name.trim()
    ..emoji = emoji
    ..totalCalories = totalCal
    ..totalProtein = totalPro
    ..totalCarbs = totalCarb
    ..totalFat = totalFat;

  int mealId = 0;
  await isar.writeTxn(() async {
    mealId = await isar.savedMeals.put(meal);
    for (final item in items) {
      item.savedMealId = mealId;
      await isar.savedMealItems.put(item);
    }
  });

  ref.invalidate(savedMealsProvider);
  ref.invalidate(frequentMealsProvider);
  AppLogger.log('Saved meal "$name" (id=$mealId, ${items.length} items)');
  return mealId;
}

/// Soft helper to build a `SavedMealItem` from an existing [FoodEntry] —
/// used by the "Save as Meal" sheet that pre-populates from the current
/// nutrition log.
SavedMealItem savedMealItemFromFoodEntry(FoodEntry e) {
  return SavedMealItem()
    ..foodName = e.name
    ..servingSize = e.servingSize ?? 1.0
    ..servingUnit = e.servingUnit ?? 'serving'
    ..quantity = 1
    ..calories = e.calories
    ..protein = e.protein
    ..carbs = e.carbs
    ..fat = e.fat
    ..fiber = e.fibre
    ..sugar = e.sugar
    ..sodium = e.sodiumMg;
}

/// Logs a saved meal into today's nutrition log under [mealType]. Scales
/// every item by [portionMultiplier]. Updates `useCount` + `lastUsedAt`,
/// invalidates the nutrition dashboard, returns true on success.
Future<bool> logSavedMeal(
  WidgetRef ref, {
  required SavedMeal meal,
  required MealType mealType,
  double portionMultiplier = 1.0,
}) async {
  final isar = ref.read(isarProvider);
  try {
    final items = await isar.savedMealItems
        .where()
        .savedMealIdEqualTo(meal.id)
        .findAll();
    if (items.isEmpty) return false;

    await isar.writeTxn(() async {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      var log = await isar.nutritionLogs
          .where()
          .dateBetween(startOfDay, endOfDay, includeUpper: false)
          .findFirst();
      log ??= NutritionLog()..date = startOfDay;
      await isar.nutritionLogs.put(log);

      await log.meals.load();
      var mealSection =
          log.meals.toList().where((m) => m.type == mealType).firstOrNull;
      if (mealSection == null) {
        mealSection = Meal()
          ..type = mealType
          ..time = now;
        await isar.meals.put(mealSection);
        log.meals.add(mealSection);
        await log.meals.save();
      }

      for (final item in items) {
        final scaledQty = item.quantity * portionMultiplier;
        final entry = FoodEntry()
          ..name = item.foodName
          ..calories = item.calories * scaledQty
          ..protein = item.protein * scaledQty
          ..carbs = item.carbs * scaledQty
          ..fat = item.fat * scaledQty
          ..servingSize = item.servingSize
          ..servingUnit = item.servingUnit
          ..fibre = item.fiber == null ? null : item.fiber! * scaledQty
          ..sugar = item.sugar == null ? null : item.sugar! * scaledQty
          ..sodiumMg = item.sodium == null ? null : item.sodium! * scaledQty;
        await isar.foodEntrys.put(entry);
        mealSection.foodEntries.add(entry);
      }
      await mealSection.foodEntries.save();

      // Recalculate log totals — same pattern as addFoodEntry in
      // nutrition_providers.dart.
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

      // Bump usage stats on the saved meal itself.
      meal.useCount = meal.useCount + 1;
      meal.lastUsedAt = now;
      await isar.savedMeals.put(meal);
    });

    ref.invalidate(todayNutritionProvider);
    ref.invalidate(todayMealsProvider);
    ref.invalidate(savedMealsProvider);
    ref.invalidate(frequentMealsProvider);
    ref.invalidate(streakProvider);
    ref.invalidate(todayMicronutrientsProvider);
    return true;
  } catch (e, st) {
    AppLogger.error('logSavedMeal failed', error: e, stack: st);
    return false;
  }
}

/// Replaces a saved meal's name, emoji, and full item list. Used by the
/// "Edit Meal" flow — recomputes cached totals from the new items.
Future<bool> updateSavedMeal(
  WidgetRef ref, {
  required int mealId,
  required String name,
  String? emoji,
  required List<SavedMealItem> items,
}) async {
  final isar = ref.read(isarProvider);
  try {
    double totalCal = 0, totalPro = 0, totalCarb = 0, totalFat = 0;
    for (final item in items) {
      totalCal += item.calories * item.quantity;
      totalPro += item.protein * item.quantity;
      totalCarb += item.carbs * item.quantity;
      totalFat += item.fat * item.quantity;
    }

    await isar.writeTxn(() async {
      final meal = await isar.savedMeals.get(mealId);
      if (meal == null) return;

      meal
        ..name = name.trim()
        ..emoji = emoji
        ..totalCalories = totalCal
        ..totalProtein = totalPro
        ..totalCarbs = totalCarb
        ..totalFat = totalFat;
      await isar.savedMeals.put(meal);

      // Wipe existing items and re-insert (simpler than diffing — the lists
      // are at most a couple dozen entries).
      final oldItems = await isar.savedMealItems
          .where()
          .savedMealIdEqualTo(mealId)
          .findAll();
      for (final it in oldItems) {
        await isar.savedMealItems.delete(it.id);
      }
      for (final item in items) {
        item.savedMealId = mealId;
        item.id = Isar.autoIncrement;
        await isar.savedMealItems.put(item);
      }
    });

    ref.invalidate(savedMealsProvider);
    ref.invalidate(frequentMealsProvider);
    ref.invalidate(savedMealItemsProvider(mealId));
    return true;
  } catch (e, st) {
    AppLogger.error('updateSavedMeal failed', error: e, stack: st);
    return false;
  }
}

/// Returns a fresh [SavedMealItem] that copies every field from [src].
/// Used by the duplicate-meal action so the new meal owns its own rows
/// rather than sharing object identity with the source.
SavedMealItem cloneSavedMealItem(SavedMealItem src) {
  return SavedMealItem()
    ..foodName = src.foodName
    ..fdcId = src.fdcId
    ..barcode = src.barcode
    ..servingSize = src.servingSize
    ..servingUnit = src.servingUnit
    ..quantity = src.quantity
    ..calories = src.calories
    ..protein = src.protein
    ..carbs = src.carbs
    ..fat = src.fat
    ..fiber = src.fiber
    ..sugar = src.sugar
    ..sodium = src.sodium;
}

/// Builds a `SavedMealItem` from a [FoodSearchResult] using a chosen
/// serving size in grams. Used by the create/edit screen's food picker.
SavedMealItem savedMealItemFromSearchResult(
  FoodSearchResult food,
  double servingGrams,
) {
  return SavedMealItem()
    ..foodName = food.name
    ..fdcId = food.fdcId?.toString()
    ..barcode = food.barcode
    ..servingSize = servingGrams
    ..servingUnit = food.servingUnit
    ..quantity = 1
    ..calories = food.caloriesFor(servingGrams)
    ..protein = food.proteinFor(servingGrams)
    ..carbs = food.carbsFor(servingGrams)
    ..fat = food.fatFor(servingGrams)
    ..fiber = food.fibreFor(servingGrams)
    ..sugar = food.sugarFor(servingGrams)
    ..sodium = food.sodiumMgFor(servingGrams);
}

/// Deletes a saved meal and all its items. Used by the swipe-to-delete and
/// the long-press menu.
Future<bool> deleteSavedMeal(WidgetRef ref, int mealId) async {
  final isar = ref.read(isarProvider);
  try {
    await isar.writeTxn(() async {
      final items = await isar.savedMealItems
          .where()
          .savedMealIdEqualTo(mealId)
          .findAll();
      for (final it in items) {
        await isar.savedMealItems.delete(it.id);
      }
      await isar.savedMeals.delete(mealId);
    });
    ref.invalidate(savedMealsProvider);
    ref.invalidate(frequentMealsProvider);
    return true;
  } catch (e, st) {
    AppLogger.error('deleteSavedMeal failed', error: e, stack: st);
    return false;
  }
}
