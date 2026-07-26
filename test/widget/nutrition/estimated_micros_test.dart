import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitai/core/constants/micro_rdas.dart';
import 'package:fitai/data/restaurant_menus.dart';
import 'package:fitai/features/nutrition/presentation/widgets/micronutrient_section.dart';
import 'package:fitai/models/food_entry.dart';
import 'package:fitai/providers/nutrition_providers.dart';

/// The "est." marker contract: micronutrient values that came from the
/// hardcoded restaurant data are USDA estimates on exactly five fields
/// (Tier 2 — vitamin C, magnesium, zinc, B12, folate) and must render with
/// an estimate marker; the chain-published Tier 1 fields (sodium, fiber,
/// vitamin D, calcium, iron, potassium) and ALL fields of non-restaurant
/// foods must not. Restaurant provenance is carried by the servingUnit
/// sentinel [restaurantServingUnit] — no schema field.
void main() {
  /// Builds the FoodEntry the meal builder's log flow would produce for a
  /// single MenuItem (servingUnit = restaurant sentinel, fields copied 1:1).
  FoodEntry entryFromMenuItem(MenuItem m, {String? servingUnit}) {
    return FoodEntry()
      ..name = m.name
      ..calories = m.calories
      ..protein = m.protein
      ..carbs = m.carbs
      ..fat = m.fat
      ..servingSize = 1
      ..servingUnit = servingUnit ?? restaurantServingUnit
      ..fibre = m.fiber
      ..sodiumMg = m.sodium
      ..vitaminDMcg = m.vitaminDMcg
      ..ironMg = m.ironMg
      ..calciumMg = m.calciumMg
      ..vitaminCMg = m.vitaminCMg
      ..magnesiumMg = m.magnesiumMg
      ..potassiumMg = m.potassiumMg
      ..zincMg = m.zincMg
      ..vitaminB12Mcg = m.vitaminB12Mcg
      ..folateMcg = m.folateMcg;
  }

  MenuItem mcdItem(String name) {
    final menu = restaurantById('mcdonalds')!;
    for (final cats in menu.builders.values) {
      for (final cat in cats) {
        for (final item in cat.items) {
          if (item.name == name) return item;
        }
      }
    }
    fail('McDonald\'s item "$name" not found in restaurant data');
  }

  group('aggregateMicronutrients', () {
    test('logged McDonald\'s Big Mac marks exactly the five Tier 2 fields',
        () {
      final result =
          aggregateMicronutrients([entryFromMenuItem(mcdItem('Big Mac'))]);

      expect(result.estimatedKeys, estimatedRestaurantMicroKeys);
      // Tier 1 keys are never marked, even though the same entry carries
      // sodium/vitD/calcium/iron/potassium values.
      expect(result.totals['Sodium'], greaterThan(0));
      expect(result.totals['Iron'], greaterThan(0));
      for (final tier1 in ['Sodium', 'Vitamin D', 'Calcium', 'Iron', 'Potassium']) {
        expect(result.estimatedKeys, isNot(contains(tier1)),
            reason: '$tier1 is chain-published (Tier 1), must not be marked');
      }
    });

    test('identical micros from a non-restaurant source produce no markers',
        () {
      // Same nutrient values, but logged the way a USDA food would be
      // (gram serving unit) — provenance, not values, drives the marker.
      final usdaStyle =
          entryFromMenuItem(mcdItem('Big Mac'), servingUnit: 'g');
      final result = aggregateMicronutrients([usdaStyle]);

      expect(result.estimatedKeys, isEmpty);
      expect(result.totals['Vitamin C'], greaterThan(0));
    });

    test('restaurant item without Tier 2 data marks nothing', () {
      // McDouble has Tier 1 fields only (no USDA match in the data pass).
      final result =
          aggregateMicronutrients([entryFromMenuItem(mcdItem('McDouble'))]);

      expect(result.estimatedKeys, isEmpty);
      expect(result.totals['Sodium'], greaterThan(0));
    });
  });

  group('MicronutrientSection rendering', () {
    Widget host(Widget child) => CupertinoApp(
          home: CupertinoPageScaffold(
            child: SingleChildScrollView(child: child),
          ),
        );

    testWidgets('estimated keys render est. suffixes and one footnote',
        (tester) async {
      final data = aggregateMicronutrients(
          [entryFromMenuItem(mcdItem('Big Mac'))]);
      await tester.pumpWidget(host(MicronutrientSection(
        consumed: data.totals,
        estimatedKeys: data.estimatedKeys,
      )));

      // Expand the collapsed card.
      await tester.tap(find.text('MICRONUTRIENTS'));
      await tester.pumpAndSettle();

      expect(find.text(' est.'),
          findsNWidgets(estimatedRestaurantMicroKeys.length));
      expect(
        find.text('est. = includes estimated values for restaurant items'),
        findsOneWidget,
      );
    });

    testWidgets('no estimated keys → no suffixes, no footnote',
        (tester) async {
      final data = aggregateMicronutrients(
          [entryFromMenuItem(mcdItem('Big Mac'), servingUnit: 'g')]);
      await tester.pumpWidget(host(MicronutrientSection(
        consumed: data.totals,
        estimatedKeys: data.estimatedKeys,
      )));

      await tester.tap(find.text('MICRONUTRIENTS'));
      await tester.pumpAndSettle();

      expect(find.text(' est.'), findsNothing);
      expect(find.textContaining('includes estimated values'), findsNothing);
    });
  });
}
