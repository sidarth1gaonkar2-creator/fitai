import '../../../models/enums.dart';

class FoodSearchResult {
  const FoodSearchResult({
    required this.name,
    this.brand,
    this.imageUrl,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.defaultServingSize = 100,
    this.servingUnit = 'g',
    this.barcode,
    this.fdcId,
    this.fibrePer100g,
    this.sugarPer100g,
    this.sodiumMgPer100g,
    this.servingDescription,
    this.source = FoodSource.openFoodFacts,
    this.vitaminDMcgPer100g,
    this.ironMgPer100g,
    this.calciumMgPer100g,
    this.vitaminCMgPer100g,
    this.magnesiumMgPer100g,
    this.potassiumMgPer100g,
    this.zincMgPer100g,
    this.vitaminB12McgPer100g,
    this.folateMcgPer100g,
  });

  final String name;
  final String? brand;
  final String? imageUrl;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double defaultServingSize;
  final String servingUnit;
  final String? barcode;
  final int? fdcId;
  final double? fibrePer100g;
  final double? sugarPer100g;
  final double? sodiumMgPer100g;
  final String? servingDescription;
  final FoodSource source;

  // Micronutrients per 100g
  final double? vitaminDMcgPer100g;
  final double? ironMgPer100g;
  final double? calciumMgPer100g;
  final double? vitaminCMgPer100g;
  final double? magnesiumMgPer100g;
  final double? potassiumMgPer100g;
  final double? zincMgPer100g;
  final double? vitaminB12McgPer100g;
  final double? folateMcgPer100g;

  bool get hasMicronutrients =>
      (ironMgPer100g ?? 0) > 0 ||
      (calciumMgPer100g ?? 0) > 0 ||
      (vitaminCMgPer100g ?? 0) > 0 ||
      (vitaminDMcgPer100g ?? 0) > 0 ||
      (magnesiumMgPer100g ?? 0) > 0 ||
      (potassiumMgPer100g ?? 0) > 0 ||
      (zincMgPer100g ?? 0) > 0 ||
      (vitaminB12McgPer100g ?? 0) > 0 ||
      (folateMcgPer100g ?? 0) > 0;

  double caloriesFor(double grams) => caloriesPer100g * grams / 100;
  double proteinFor(double grams) => proteinPer100g * grams / 100;
  double carbsFor(double grams) => carbsPer100g * grams / 100;
  double fatFor(double grams) => fatPer100g * grams / 100;

  double? _scaled(double? per100g, double grams) =>
      per100g != null ? per100g * grams / 100 : null;

  double? fibreFor(double grams) => _scaled(fibrePer100g, grams);
  double? sugarFor(double grams) => _scaled(sugarPer100g, grams);
  double? sodiumMgFor(double grams) => _scaled(sodiumMgPer100g, grams);
  double? vitaminDMcgFor(double grams) => _scaled(vitaminDMcgPer100g, grams);
  double? ironMgFor(double grams) => _scaled(ironMgPer100g, grams);
  double? calciumMgFor(double grams) => _scaled(calciumMgPer100g, grams);
  double? vitaminCMgFor(double grams) => _scaled(vitaminCMgPer100g, grams);
  double? magnesiumMgFor(double grams) => _scaled(magnesiumMgPer100g, grams);
  double? potassiumMgFor(double grams) => _scaled(potassiumMgPer100g, grams);
  double? zincMgFor(double grams) => _scaled(zincMgPer100g, grams);
  double? vitaminB12McgFor(double grams) =>
      _scaled(vitaminB12McgPer100g, grams);
  double? folateMcgFor(double grams) => _scaled(folateMcgPer100g, grams);

  factory FoodSearchResult.fromUsda(Map<String, dynamic> food) {
    final nutrients = food['foodNutrients'] as List<dynamic>? ?? [];

    // Branded foods report nutrients per `servingSize` (in `servingSizeUnit`),
    // every other data type reports per 100 g. We detect Branded and rescale
    // so the rest of the parser can assume per-100g uniformly.
    final dataType = (food['dataType'] as String?)?.toLowerCase() ?? '';
    final isBranded = dataType.contains('branded');
    final servingSize = (food['servingSize'] as num?)?.toDouble() ?? 0;
    final servingUnit =
        (food['servingSizeUnit'] as String?)?.toLowerCase() ?? '';
    final brandedScale = (isBranded &&
            servingSize > 0 &&
            (servingUnit == 'g' || servingUnit == 'ml'))
        ? 100.0 / servingSize
        : 1.0;

    // USDA uses different formats depending on endpoint/food type:
    //   Search: { nutrientId: 1003, value: 25.0 }
    //   Detail: { nutrient: { id: 1003, number: "203" }, amount: 25.0 }
    //   Branded: { nutrientNumber: "203", value: 25.0 }
    final byId = <int, double>{};
    final byNumber = <String, double>{};
    for (final raw in nutrients) {
      final n = raw as Map<String, dynamic>;
      // Try "value" (search) then "amount" (detail)
      final value = ((n['value'] as num?)?.toDouble() ??
              (n['amount'] as num?)?.toDouble() ??
              0) *
          brandedScale;
      // Try flat nutrientId (search)
      if (n.containsKey('nutrientId')) {
        byId[(n['nutrientId'] as num).toInt()] = value;
      }
      // Try nested nutrient.id (detail endpoint)
      if (n.containsKey('nutrient') && n['nutrient'] is Map) {
        final nested = n['nutrient'] as Map<String, dynamic>;
        if (nested.containsKey('id')) {
          byId[(nested['id'] as num).toInt()] = value;
        }
        if (nested.containsKey('number')) {
          byNumber[nested['number'].toString()] = value;
        }
      }
      // Try flat nutrientNumber (branded)
      if (n.containsKey('nutrientNumber')) {
        byNumber[n['nutrientNumber'].toString()] = value;
      }
    }

    // Nutrient ID → nutrient number string mapping
    double nutrient(int id, String number) =>
        byId[id] ?? byNumber[number] ?? 0;

    double? optNutrient(int id, String number) {
      final v = nutrient(id, number);
      return v > 0 ? v : null;
    }

    final desc = food['description'] as String? ?? 'Unknown Food';

    // Energy is reported under different IDs depending on data type:
    //   * 1008 / "208": Energy (kcal) — Atwater General  (SR Legacy, Branded)
    //   * 2047 / "957": Energy (Atwater General Factors) — Foundation
    //   * 2048 / "958": Energy (Atwater Specific Factors) — Foundation, dairy/eggs/fungi
    //   * 1062 / "268": Energy (kJ) — convert to kcal as last resort
    double resolveEnergy() {
      final kcal = nutrient(1008, '208');
      if (kcal > 0) return kcal;
      final atwaterGeneral = nutrient(2047, '957');
      if (atwaterGeneral > 0) return atwaterGeneral;
      final atwaterSpecific = nutrient(2048, '958');
      if (atwaterSpecific > 0) return atwaterSpecific;
      final kj = nutrient(1062, '268');
      if (kj > 0) return kj / 4.184; // kJ → kcal
      return 0;
    }

    return FoodSearchResult(
      name: desc.length > 80 ? '${desc.substring(0, 80)}…' : desc,
      brand: food['brandOwner'] as String?,
      fdcId: (food['fdcId'] as num?)?.toInt(),
      caloriesPer100g: resolveEnergy(),
      proteinPer100g: nutrient(1003, '203'),
      carbsPer100g: nutrient(1005, '205'),
      fatPer100g: nutrient(1004, '204'),
      fibrePer100g: optNutrient(1079, '291'),
      sugarPer100g: optNutrient(2000, '269'),
      sodiumMgPer100g: optNutrient(1093, '307'),
      vitaminDMcgPer100g: optNutrient(1114, '328'),
      ironMgPer100g: optNutrient(1089, '303'),
      calciumMgPer100g: optNutrient(1087, '301'),
      vitaminCMgPer100g: optNutrient(1162, '401'),
      magnesiumMgPer100g: optNutrient(1090, '304'),
      potassiumMgPer100g: optNutrient(1092, '306'),
      zincMgPer100g: optNutrient(1095, '309'),
      vitaminB12McgPer100g: optNutrient(1178, '418'),
      folateMcgPer100g: optNutrient(1177, '417'),
      source: FoodSource.usda,
    );
  }

  /// Spoonacular `/food/menuItems/{id}` and `/food/menuItems/search` items.
  /// Restaurant menu items typically expose nutrition per serving rather
  /// than per 100 g, so we use [weightPerServing] if present to normalise,
  /// otherwise fall back to treating the values as per-100g and clamping
  /// the default serving to the reported size.
  factory FoodSearchResult.fromSpoonacularMenuItem(
    Map<String, dynamic> item,
  ) {
    final nutrition = item['nutrition'] as Map<String, dynamic>?;
    return _fromSpoonacular(
      name: (item['title'] as String?) ?? 'Unknown Item',
      brand: item['restaurantChain'] as String?,
      imageUrl: item['image'] as String?,
      nutrition: nutrition,
      servings: item['servings'] as Map<String, dynamic>?,
    );
  }

  /// Spoonacular `/food/products/{id}`, `/food/products/search`, and
  /// `/food/products/upc/{upc}` items. Branded grocery products — preserves
  /// the barcode in [barcode] when present so the same row is dedupable
  /// against OpenFoodFacts results.
  factory FoodSearchResult.fromSpoonacularProduct(
    Map<String, dynamic> product,
  ) {
    final nutrition = product['nutrition'] as Map<String, dynamic>?;
    final brands = product['brand'] as String? ??
        (product['brands'] is List
            ? (product['brands'] as List).join(', ')
            : product['brands'] as String?);
    return _fromSpoonacular(
      name: (product['title'] as String?) ?? 'Unknown Product',
      brand: brands,
      imageUrl: product['image'] as String?,
      barcode: product['upc'] as String?,
      nutrition: nutrition,
      servings: product['servings'] as Map<String, dynamic>?,
    );
  }

  /// Shared parser for Spoonacular menu items and products. Both endpoints
  /// return the same nutrition envelope: `nutrients: [{name, amount, unit}]`
  /// plus an optional `weightPerServing`. We convert to the app's per-100 g
  /// canonical form by `(per_serving / grams_per_serving) * 100`.
  static FoodSearchResult _fromSpoonacular({
    required String name,
    String? brand,
    String? imageUrl,
    String? barcode,
    Map<String, dynamic>? nutrition,
    Map<String, dynamic>? servings,
  }) {
    final nutrients = (nutrition?['nutrients'] as List<dynamic>?) ?? const [];
    double valueOf(String displayName) {
      for (final raw in nutrients) {
        final n = raw as Map<String, dynamic>;
        if ((n['name'] as String?)?.toLowerCase() ==
            displayName.toLowerCase()) {
          return (n['amount'] as num?)?.toDouble() ?? 0;
        }
      }
      return 0;
    }

    double? optValueOf(String displayName) {
      final v = valueOf(displayName);
      return v > 0 ? v : null;
    }

    final weightPerServing =
        nutrition?['weightPerServing'] as Map<String, dynamic>?;
    final gramsPerServing =
        (weightPerServing?['amount'] as num?)?.toDouble() ?? 0;
    final servingGrams = gramsPerServing > 0 ? gramsPerServing : 100.0;
    final scale = 100.0 / servingGrams;

    return FoodSearchResult(
      name: name.length > 80 ? '${name.substring(0, 80)}…' : name,
      brand: brand,
      imageUrl: imageUrl,
      barcode: barcode,
      caloriesPer100g: valueOf('Calories') * scale,
      proteinPer100g: valueOf('Protein') * scale,
      carbsPer100g: valueOf('Carbohydrates') * scale,
      fatPer100g: valueOf('Fat') * scale,
      fibrePer100g: _scaleOpt(optValueOf('Fiber'), scale),
      sugarPer100g: _scaleOpt(optValueOf('Sugar'), scale),
      sodiumMgPer100g: _scaleOpt(optValueOf('Sodium'), scale),
      vitaminDMcgPer100g: _scaleOpt(optValueOf('Vitamin D'), scale),
      ironMgPer100g: _scaleOpt(optValueOf('Iron'), scale),
      calciumMgPer100g: _scaleOpt(optValueOf('Calcium'), scale),
      vitaminCMgPer100g: _scaleOpt(optValueOf('Vitamin C'), scale),
      magnesiumMgPer100g: _scaleOpt(optValueOf('Magnesium'), scale),
      potassiumMgPer100g: _scaleOpt(optValueOf('Potassium'), scale),
      zincMgPer100g: _scaleOpt(optValueOf('Zinc'), scale),
      vitaminB12McgPer100g: _scaleOpt(optValueOf('Vitamin B12'), scale),
      folateMcgPer100g: _scaleOpt(optValueOf('Folate'), scale),
      defaultServingSize: servingGrams,
      servingUnit: 'g',
      servingDescription: _describeServing(servings, gramsPerServing),
      source: FoodSource.spoonacular,
    );
  }

  static double? _scaleOpt(double? v, double scale) =>
      v == null ? null : v * scale;

  static String? _describeServing(
    Map<String, dynamic>? servings,
    double gramsPerServing,
  ) {
    if (servings == null) {
      return gramsPerServing > 0
          ? '${gramsPerServing.toInt()} g per serving'
          : null;
    }
    final number = (servings['number'] as num?)?.toDouble();
    final size = (servings['size'] as num?)?.toDouble();
    final unit = servings['unit'] as String?;
    if (number != null && size != null && unit != null && unit.isNotEmpty) {
      return '${number.toStringAsFixed(0)} × ${size.toStringAsFixed(0)} $unit';
    }
    if (gramsPerServing > 0) return '${gramsPerServing.toInt()} g per serving';
    return null;
  }

  factory FoodSearchResult.fromOpenFoodFacts(Map<String, dynamic> product) {
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};
    final name = (product['product_name'] as String?) ?? 'Unknown Product';
    final brand = product['brands'] as String?;
    final imageUrl = product['image_front_small_url'] as String?;
    final barcode = product['code'] as String?;

    return FoodSearchResult(
      name: name.isEmpty ? 'Unknown Product' : name,
      brand: brand,
      imageUrl: imageUrl,
      caloriesPer100g:
          (nutriments['energy-kcal_100g'] as num?)?.toDouble() ?? 0,
      proteinPer100g:
          (nutriments['proteins_100g'] as num?)?.toDouble() ?? 0,
      carbsPer100g:
          (nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 0,
      fatPer100g: (nutriments['fat_100g'] as num?)?.toDouble() ?? 0,
      barcode: barcode,
      fibrePer100g: (nutriments['fiber_100g'] as num?)?.toDouble(),
      sugarPer100g: (nutriments['sugars_100g'] as num?)?.toDouble(),
      sodiumMgPer100g: (nutriments['sodium_100g'] as num?)?.toDouble(),
      vitaminDMcgPer100g:
          (nutriments['vitamin-d_100g'] as num?)?.toDouble(),
      ironMgPer100g: (nutriments['iron_100g'] as num?)?.toDouble(),
      calciumMgPer100g: (nutriments['calcium_100g'] as num?)?.toDouble(),
      vitaminCMgPer100g:
          (nutriments['vitamin-c_100g'] as num?)?.toDouble(),
      magnesiumMgPer100g:
          (nutriments['magnesium_100g'] as num?)?.toDouble(),
      potassiumMgPer100g:
          (nutriments['potassium_100g'] as num?)?.toDouble(),
      zincMgPer100g: (nutriments['zinc_100g'] as num?)?.toDouble(),
      vitaminB12McgPer100g:
          (nutriments['vitamin-b12_100g'] as num?)?.toDouble(),
      folateMcgPer100g: (nutriments['folates_100g'] as num?)?.toDouble(),
      source: FoodSource.openFoodFacts,
    );
  }
}
