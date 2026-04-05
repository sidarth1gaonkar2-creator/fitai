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
