import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/enums.dart';

/// Centralised icon + colour definitions for macros, micronutrients,
/// and food categories used throughout the nutrition UI.
class NutrientIcons {
  const NutrientIcons._();

  // --- Macros ---
  static const IconData caloriesIcon = CupertinoIcons.flame_fill;
  static const Color caloriesColor = Color(0xFF0A84FF);

  static const IconData proteinIcon = Icons.lunch_dining;
  static const Color proteinColor = Color(0xFF0A84FF);

  static const IconData carbsIcon = Icons.breakfast_dining;
  static const Color carbsColor = Color(0xFF32D74B);

  static const IconData fatIcon = Icons.opacity;
  static const Color fatColor = Color(0xFFFF9F0A);

  // --- Micronutrients keyed by display name (matches microRdaTargets keys) ---
  static const Map<String, (IconData, Color)> _micros = {
    'Vitamin D': (CupertinoIcons.sun_max_fill, Color(0xFFFFC107)),
    'Iron': (Icons.hardware, Color(0xFF808080)),
    'Calcium': (Icons.egg_alt, Color(0xFFE3F2FD)),
    'Vitamin C': (Icons.circle, Color(0xFFFF8C42)),
    'Magnesium': (Icons.bolt, Color(0xFF673AB7)),
    'Sodium': (CupertinoIcons.drop_fill, Color(0xFF4FC3F7)),
    'Potassium': (Icons.energy_savings_leaf, Color(0xFFFFEB3B)),
    'Zinc': (Icons.shield_outlined, Color(0xFFB0BEC5)),
    'Vitamin B12': (Icons.biotech, Color(0xFFE53935)),
    'Folate': (Icons.local_florist, Color(0xFFE91E63)),
  };

  static (IconData, Color) forMicro(String name) =>
      _micros[name] ?? (CupertinoIcons.lab_flask, CupertinoColors.systemPurple);

  // --- Food categories ---
  static IconData forFoodCategory(FoodCategory category) => switch (category) {
        FoodCategory.eggs => Icons.egg_alt,
        FoodCategory.dairy => Icons.icecream,
        FoodCategory.meat => Icons.lunch_dining,
        FoodCategory.poultry => Icons.egg,
        FoodCategory.fish => Icons.set_meal,
        FoodCategory.grains => Icons.grain,
        FoodCategory.legumes => Icons.grass,
        FoodCategory.vegetables => Icons.eco,
        FoodCategory.fruits => Icons.apple,
        FoodCategory.nuts => Icons.park,
        FoodCategory.oils => Icons.opacity,
        FoodCategory.beverages => Icons.local_bar,
        FoodCategory.condiments => Icons.soup_kitchen,
        FoodCategory.snacks => Icons.cookie,
        FoodCategory.frozen => Icons.ac_unit,
        FoodCategory.fastFood => Icons.fastfood,
      };

  static Color forFoodCategoryColor(FoodCategory category) =>
      switch (category) {
        FoodCategory.eggs => const Color(0xFFFFD93D),
        FoodCategory.dairy => const Color(0xFFE3F2FD),
        FoodCategory.meat => const Color(0xFF8B2E2E),
        FoodCategory.poultry => const Color(0xFFE8B86D),
        FoodCategory.fish => const Color(0xFF4FC3F7),
        FoodCategory.grains => const Color(0xFFDAA520),
        FoodCategory.legumes => const Color(0xFF8B4513),
        FoodCategory.vegetables => const Color(0xFF4CAF50),
        FoodCategory.fruits => const Color(0xFF66BB6A),
        FoodCategory.nuts => const Color(0xFF8B5A2B),
        FoodCategory.oils => const Color(0xFFFFD93D),
        FoodCategory.beverages => const Color(0xFF9C27B0),
        FoodCategory.condiments => Colors.deepOrange,
        FoodCategory.snacks => const Color(0xFFC97B4F),
        FoodCategory.frozen => const Color(0xFF81D4FA),
        FoodCategory.fastFood => const Color(0xFFFF8C42),
      };

  /// Heuristic name → category mapping for foods that don't carry a category.
  static FoodCategory categoryFromName(String name) {
    final n = name.toLowerCase();
    bool has(List<String> kws) => kws.any(n.contains);

    // Fast food brands first (highest specificity)
    if (has([
      'burger king',
      'mcdonald',
      'chipotle',
      'subway',
      'kfc',
      'wendy',
      'taco bell',
      'pizza hut',
      "domino",
      'starbucks',
    ])) {
      return FoodCategory.fastFood;
    }

    // Protein supplements
    if (has(['protein powder', 'whey', 'protein shake', 'protein bar'])) {
      return FoodCategory.snacks;
    }

    if (has(['egg white', 'egg ', 'eggs'])) return FoodCategory.eggs;

    if (has(['milk', 'yogurt', 'cheese', 'butter', 'cream', 'cottage', 'dairy'])) {
      return FoodCategory.dairy;
    }

    if (has(['chicken', 'turkey', 'duck', 'poultry'])) {
      return FoodCategory.poultry;
    }

    if (has([
      'beef',
      'steak',
      'ground beef',
      'burger',
      'pork',
      'lamb',
      'bacon',
      'sausage',
      'ham',
      'meat',
    ])) {
      return FoodCategory.meat;
    }

    if (has([
      'salmon',
      'tuna',
      'fish',
      'tilapia',
      'cod',
      'shrimp',
      'crab',
      'lobster',
      'sardine',
    ])) {
      return FoodCategory.fish;
    }

    if (has([
      'rice',
      'bread',
      'pasta',
      'oat',
      'cereal',
      'wheat',
      'quinoa',
      'grain',
      'bagel',
      'tortilla',
    ])) {
      return FoodCategory.grains;
    }

    if (has(['bean', 'lentil', 'chickpea', 'pea', 'tofu', 'tempeh'])) {
      return FoodCategory.legumes;
    }

    if (has([
      'apple',
      'banana',
      'orange',
      'berry',
      'grape',
      'melon',
      'peach',
      'pear',
      'mango',
      'pineapple',
      'strawberry',
      'blueberry',
      'fruit',
    ])) {
      return FoodCategory.fruits;
    }

    if (has([
      'almond',
      'walnut',
      'peanut',
      'cashew',
      'pistachio',
      'pecan',
      'nut ',
      'nuts',
      'seed',
    ])) {
      return FoodCategory.nuts;
    }

    if (has(['oil', 'lard', 'ghee'])) return FoodCategory.oils;

    if (has([
      'juice',
      'smoothie',
      'water',
      'tea',
      'coffee',
      'soda',
      'drink',
      'beverage',
    ])) {
      return FoodCategory.beverages;
    }

    if (has(['sauce', 'ketchup', 'mustard', 'mayo', 'dressing', 'syrup'])) {
      return FoodCategory.condiments;
    }

    if (has(['chip', 'cookie', 'chocolate', 'candy', 'cracker', 'snack', 'bar'])) {
      return FoodCategory.snacks;
    }

    if (has(['frozen', 'ice cream'])) return FoodCategory.frozen;

    if (has(['pizza', 'fries', 'nugget', 'taco', 'burrito', 'fast food'])) {
      return FoodCategory.fastFood;
    }

    if (has([
      'broccoli',
      'carrot',
      'spinach',
      'tomato',
      'potato',
      'lettuce',
      'vegetable',
      'kale',
      'onion',
      'pepper',
      'cucumber',
    ])) {
      return FoodCategory.vegetables;
    }

    return FoodCategory.grains;
  }
}
