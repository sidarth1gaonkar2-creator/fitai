import 'package:flutter_test/flutter_test.dart';

import 'package:fitai/models/saved_meal_item.dart';
import 'package:fitai/providers/saved_meal_providers.dart';

/// Regression pin for the saved-meal portion-scaling bug: macros were scaled
/// by quantity × portionMultiplier but micros by portionMultiplier only, so
/// logging a "Double" component (quantity 2) doubled calories while sodium,
/// iron, etc. stayed single. Every nutrient must scale by the SAME factor.
void main() {
  SavedMealItem item({double quantity = 1.0}) => SavedMealItem()
    ..foodName = 'Test Item'
    ..servingSize = 1
    ..servingUnit = 'serving'
    ..quantity = quantity
    ..calories = 250
    ..protein = 12
    ..carbs = 31
    ..fat = 9
    ..fiber = 2
    ..sugar = 6
    ..sodium = 510
    ..vitaminDMcg = 0.2
    ..ironMg = 2.5
    ..calciumMg = 110
    ..vitaminCMg = 1
    ..magnesiumMg = 22
    ..potassiumMg = 210
    ..zincMg = 2
    ..vitaminB12Mcg = 0.9
    ..folateMcg = 60;

  /// Every nutrient field of the built entry, in a fixed order, so the
  /// assertions below cannot silently skip one.
  List<double?> nutrients(SavedMealItem i, double portion) {
    final e = foodEntryFromSavedMealItem(i, portion);
    return [
      e.calories,
      e.protein,
      e.carbs,
      e.fat,
      e.fibre,
      e.sugar,
      e.sodiumMg,
      e.vitaminDMcg,
      e.ironMg,
      e.calciumMg,
      e.vitaminCMg,
      e.magnesiumMg,
      e.potassiumMg,
      e.zincMg,
      e.vitaminB12Mcg,
      e.folateMcg,
    ];
  }

  test('quantity 2 exactly doubles every nutrient — macro AND micro', () {
    final single = nutrients(item(), 1.0);
    final doubled = nutrients(item(quantity: 2.0), 1.0);
    expect(single.length, doubled.length);
    for (var i = 0; i < single.length; i++) {
      expect(
        doubled[i],
        moreOrLessEquals(single[i]! * 2, epsilon: 1e-9),
        reason: 'nutrient index $i did not double with quantity 2',
      );
    }
  });

  test('quantity and portionMultiplier compose into one shared factor', () {
    final base = nutrients(item(), 1.0);
    final scaled = nutrients(item(quantity: 2.0), 1.5);
    for (var i = 0; i < base.length; i++) {
      expect(
        scaled[i],
        moreOrLessEquals(base[i]! * 3.0, epsilon: 1e-9),
        reason: 'nutrient index $i did not scale by quantity × portion',
      );
    }
  });

  test('unknown micros stay null at any scale — never coerced to 0', () {
    final sparse = SavedMealItem()
      ..foodName = 'Macros Only'
      ..quantity = 2
      ..calories = 100
      ..protein = 5
      ..carbs = 10
      ..fat = 3;
    final e = foodEntryFromSavedMealItem(sparse, 2.0);
    expect(e.calories, 400);
    expect(e.fibre, isNull);
    expect(e.sodiumMg, isNull);
    expect(e.ironMg, isNull);
    expect(e.folateMcg, isNull);
  });
}
