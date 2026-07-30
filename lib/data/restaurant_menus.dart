import 'package:flutter/material.dart';

/// A single component a user can pick when assembling a custom meal —
/// rice, protein, sauce, side, etc. Per-item nutrition values come from each
/// chain's published nutrition data (see comment above each restaurant for
/// the source). Numbers are rounded to the nearest gram/calorie because the
/// chain calculators themselves publish rounded figures.
class MenuItem {
  const MenuItem({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sodium,
    this.vitaminDMcg,
    this.ironMg,
    this.calciumMg,
    this.vitaminCMg,
    this.magnesiumMg,
    this.potassiumMg,
    this.zincMg,
    this.vitaminB12Mcg,
    this.folateMcg,
  });

  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;

  /// Sodium in mg per serving. Chains publish this (FDA menu labeling
  /// requires it) — source it from the same nutrition sheet as the macros.
  final double? sodium;

  // Micronutrients per serving. Chains do NOT publish vitamins/minerals
  // (FDA menu labeling stops at sodium), so these are USDA
  // generic-equivalent estimates. Null means "unknown" and stays null all
  // the way into the log — never write 0 for a value we don't have.
  final double? vitaminDMcg;
  final double? ironMg;
  final double? calciumMg;
  final double? vitaminCMg;
  final double? magnesiumMg;
  final double? potassiumMg;
  final double? zincMg;
  final double? vitaminB12Mcg;
  final double? folateMcg;
}

enum SelectionMode { single, multiple }

/// A logical step in a meal builder — "pick a rice", "pick a protein",
/// "add toppings". A category can be optional (e.g. cheese on a sandwich)
/// or required (e.g. you must pick exactly one protein for a bowl).
///
/// When [allowDouble] is true the builder UI surfaces a "Double" toggle once
/// the user has picked an item — calories/macros for that line multiply by 2.
/// Use this for chains that publish a "double protein" upcharge (Chipotle,
/// Subway, sweetgreen, CAVA, etc.).
///
/// When [allowHalfHalf] is true (single-mode categories only — typically
/// protein at Chipotle) the user can pick TWO items at half portion each.
/// The builder UI splits the selection into a half-and-half row, and each
/// item's nutrition is multiplied by 0.5 when summing totals.
///
/// [maxSelections] caps a multiple-select category. Used for Panda Express
/// where Bowl = 1 entree, Plate = 2 entrees, Bigger Plate = 3 entrees.
/// `null` means unlimited.
class MenuCategory {
  const MenuCategory({
    required this.name,
    required this.mode,
    this.optional = false,
    this.allowDouble = false,
    this.allowHalfHalf = false,
    this.maxSelections,
    required this.items,
  });

  final String name;
  final SelectionMode mode;
  final bool optional;
  final bool allowDouble;
  final bool allowHalfHalf;
  final int? maxSelections;
  final List<MenuItem> items;
}

/// One restaurant. Holds shared branding (emoji, accent color) and a map of
/// meal-type → category list. Meal types are the high-level "what am I
/// building" choice (Burrito vs Bowl vs Tacos at Chipotle).
///
/// Sit-down / large-menu chains that aren't worth hand-modelling
/// (Cheesecake Factory's 250+ items, etc.) set [searchOnly] = true.
/// Tapping those routes to the Spoonacular-backed menu-item search instead
/// of the builder. [searchSeed] pre-fills the query; pass `''` for a
/// blank-start catch-all like "Other Restaurant".
class RestaurantMenu {
  const RestaurantMenu({
    required this.id,
    required this.name,
    required this.emoji,
    required this.accentColor,
    this.mealTypes = const [],
    this.builders = const {},
    this.searchOnly = false,
    this.searchSeed,
  });

  final String id;
  final String name;
  final String emoji;
  final Color accentColor;
  final List<String> mealTypes;
  final Map<String, List<MenuCategory>> builders;
  final bool searchOnly;
  final String? searchSeed;
}

// ─────────────────────────────────────────────────────────────────────
// Shared building-blocks reused across the Chipotle builders
// ─────────────────────────────────────────────────────────────────────
const _chipotleRice = MenuCategory(
  name: 'Rice',
  mode: SelectionMode.single,
  optional: true,
  items: [
    MenuItem(
      name: 'White Rice', calories: 210, protein: 4, carbs: 36, fat: 6,
      fiber: 1, sodium: 350, ironMg: 0.5, calciumMg: 10,
      vitaminCMg: 1.8, magnesiumMg: 13.6, zincMg: 0.6,
      vitaminB12Mcg: 0, folateMcg: 65.8,
    ),
    MenuItem(
      name: 'Brown Rice', calories: 210, protein: 4, carbs: 36, fat: 6,
      fiber: 2, sodium: 190, ironMg: 0.7, calciumMg: 10,
      vitaminCMg: 1.2, magnesiumMg: 44.2, zincMg: 0.8,
      vitaminB12Mcg: 0, folateMcg: 10.2,
    ),
    MenuItem(name: 'Cauliflower Rice', calories: 40, protein: 2, carbs: 4, fat: 2),
  ],
);

const _chipotleBeans = MenuCategory(
  name: 'Beans',
  mode: SelectionMode.single,
  optional: true,
  items: [
    MenuItem(
      name: 'Black Beans', calories: 130, protein: 8, carbs: 22, fat: 1,
      fiber: 7, sodium: 210, ironMg: 1.8, calciumMg: 40,
      vitaminCMg: 1.2, magnesiumMg: 79.4, zincMg: 1.3,
      vitaminB12Mcg: 0, folateMcg: 169,
    ),
    MenuItem(
      name: 'Pinto Beans', calories: 130, protein: 8, carbs: 22, fat: 1,
      fiber: 8, sodium: 210, ironMg: 1.8, calciumMg: 40,
      vitaminCMg: 1.2, magnesiumMg: 56.7, zincMg: 1.1,
      vitaminB12Mcg: 0, folateMcg: 195,
    ),
  ],
);

const _chipotleProtein = MenuCategory(
  name: 'Protein',
  mode: SelectionMode.single,
  allowDouble: true,
  allowHalfHalf: true,
  items: [
    MenuItem(
      name: 'Chicken', calories: 180, protein: 32, carbs: 0, fat: 7,
      fiber: 0, sodium: 310, ironMg: 1.4, calciumMg: 30,
      vitaminCMg: 1.2, magnesiumMg: 27.2, zincMg: 2.2,
      vitaminB12Mcg: 0.5, folateMcg: 5.7,
    ),
    MenuItem(
      name: 'Steak', calories: 150, protein: 21, carbs: 1, fat: 6,
      fiber: 1, sodium: 330, ironMg: 2.7, calciumMg: 20,
      vitaminCMg: 0, magnesiumMg: 29.5, zincMg: 6.5,
      vitaminB12Mcg: 1.9, folateMcg: 11.3,
    ),
    MenuItem(
      name: 'Barbacoa', calories: 170, protein: 24, carbs: 2, fat: 7,
      fiber: 1, sodium: 530, ironMg: 2.7, calciumMg: 20,
      vitaminCMg: 0, magnesiumMg: 24.9, zincMg: 8.8,
      vitaminB12Mcg: 2.9, folateMcg: 12.5,
    ),
    MenuItem(
      name: 'Carnitas', calories: 210, protein: 23, carbs: 0, fat: 12,
      fiber: 0, sodium: 450, ironMg: 1.1, calciumMg: 20,
      vitaminCMg: 0, magnesiumMg: 27.2, zincMg: 5.9,
      vitaminB12Mcg: 1, folateMcg: 0,
    ),
    MenuItem(
      name: 'Sofritas', calories: 150, protein: 8, carbs: 9, fat: 10,
      fiber: 3, sodium: 560, ironMg: 3.1, calciumMg: 170,
      vitaminCMg: 13.8, magnesiumMg: 39.7, zincMg: 1.2,
      vitaminB12Mcg: 0, folateMcg: 10.2,
    ),
    MenuItem(name: 'Chicken Al Pastor', calories: 210, protein: 31, carbs: 3, fat: 8),
    MenuItem(
      name: 'Veggie (no protein)', calories: 0, protein: 0, carbs: 0, fat: 0,
      fiber: 0, sodium: 0, ironMg: 0, calciumMg: 0, vitaminCMg: 0,
    ),
  ],
);

const _chipotleToppings = MenuCategory(
  name: 'Toppings',
  mode: SelectionMode.multiple,
  items: [
    MenuItem(
      name: 'Fajita Veggies', calories: 20, protein: 1, carbs: 4, fat: 0,
      fiber: 1, sodium: 150, ironMg: 0.4, calciumMg: 20,
      vitaminCMg: 36, magnesiumMg: 7.8, zincMg: 0.1,
      vitaminB12Mcg: 0, folateMcg: 16.3,
    ),
    MenuItem(
      name: 'Fresh Tomato Salsa', calories: 25, protein: 1, carbs: 4, fat: 0,
      fiber: 1, sodium: 550, ironMg: 0.9, calciumMg: 10,
      vitaminCMg: 8.4, magnesiumMg: 8.9, zincMg: 0.1,
      vitaminB12Mcg: 0, folateMcg: 11.9,
    ),
    MenuItem(
      name: 'Roasted Chili-Corn Salsa', calories: 80, protein: 3, carbs: 16, fat: 2,
      fiber: 3, sodium: 330, ironMg: 0.7, calciumMg: 0,
      vitaminCMg: 6, magnesiumMg: 25.8, zincMg: 0.6,
      vitaminB12Mcg: 0, folateMcg: 22.8,
    ),
    MenuItem(
      name: 'Tomatillo-Green Chili Salsa', calories: 15, protein: 1, carbs: 3, fat: 0,
      fiber: 0, sodium: 260, ironMg: 0.5, calciumMg: 30,
      vitaminCMg: 12, magnesiumMg: 10.8, zincMg: 0.1,
      vitaminB12Mcg: 0, folateMcg: 4.5,
    ),
    MenuItem(
      name: 'Tomatillo-Red Chili Salsa', calories: 30, protein: 1, carbs: 4, fat: 1,
      fiber: 1, sodium: 500, ironMg: 0.5, calciumMg: 0, vitaminCMg: 0,
    ),
    MenuItem(
      name: 'Sour Cream', calories: 110, protein: 2, carbs: 2, fat: 9,
      fiber: 0, sodium: 30, ironMg: 0, calciumMg: 60,
      vitaminCMg: 0, magnesiumMg: 5.7, zincMg: 0.2,
      vitaminB12Mcg: 0.1, folateMcg: 3.4,
    ),
    MenuItem(
      name: 'Cheese', calories: 110, protein: 6, carbs: 1, fat: 9,
      fiber: 0, sodium: 190, ironMg: 0, calciumMg: 200,
      vitaminCMg: 0, magnesiumMg: 7.7, zincMg: 0.9,
      vitaminB12Mcg: 0.2, folateMcg: 5.1,
    ),
    MenuItem(
      name: 'Guacamole', calories: 230, protein: 2, carbs: 8, fat: 22,
      fiber: 6, sodium: 370, ironMg: 1.3, calciumMg: 20,
      vitaminCMg: 4.2, magnesiumMg: 32.9, zincMg: 0.7,
      vitaminB12Mcg: 0, folateMcg: 91.9,
    ),
    MenuItem(
      name: 'Queso Blanco', calories: 120, protein: 5, carbs: 4, fat: 9,
      fiber: 0, sodium: 250, ironMg: 0, calciumMg: 100,
      vitaminCMg: 1.2, magnesiumMg: 5.1, zincMg: 0.6,
      vitaminB12Mcg: 0.1, folateMcg: 2.3,
    ),
    MenuItem(
      name: 'Romaine Lettuce', calories: 5, protein: 0, carbs: 1, fat: 0,
      fiber: 1, sodium: 0, ironMg: 0.4, calciumMg: 0,
      vitaminCMg: 6, magnesiumMg: 4, zincMg: 0.1,
      vitaminB12Mcg: 0, folateMcg: 38.6,
    ),
  ],
);

const _chipotleSides = MenuCategory(
  name: 'Side',
  mode: SelectionMode.single,
  optional: true,
  items: [
    MenuItem(
      name: 'Chips', calories: 540, protein: 7, carbs: 73, fat: 25,
      fiber: 7, sodium: 390, ironMg: 3.1, calciumMg: 400,
      vitaminCMg: 0, magnesiumMg: 95.3, zincMg: 1.6,
      vitaminB12Mcg: 0.4, folateMcg: 13.6,
    ),
    MenuItem(
      name: 'Chips & Guac', calories: 770, protein: 9, carbs: 81, fat: 47,
      fiber: 13, sodium: 760, ironMg: 4.3, calciumMg: 420,
      vitaminCMg: 4.2, magnesiumMg: 128.1, zincMg: 2.3,
      vitaminB12Mcg: 0.4, folateMcg: 105.5,
    ),
    MenuItem(
      name: 'Chips & Queso', calories: 660, protein: 12, carbs: 77, fat: 34,
      fiber: 7, sodium: 640, ironMg: 3.1, calciumMg: 500,
      vitaminCMg: 1.2, magnesiumMg: 100.4, zincMg: 2.1,
      vitaminB12Mcg: 0.5, folateMcg: 15.9,
    ),
    MenuItem(
      name: 'Chips & Salsa (Mild)', calories: 565, protein: 8, carbs: 77, fat: 25,
      fiber: 8, sodium: 940, ironMg: 4, calciumMg: 410,
      vitaminCMg: 8.4, magnesiumMg: 104.2, zincMg: 1.7,
      vitaminB12Mcg: 0.4, folateMcg: 25.5,
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────
// Subway shared building-blocks
// ─────────────────────────────────────────────────────────────────────
const _subwayBread6 = MenuCategory(
  name: 'Bread',
  mode: SelectionMode.single,
  items: [
    MenuItem(
      name: 'Italian White', calories: 200, protein: 8, carbs: 38, fat: 2,
      fiber: 1, sodium: 380, vitaminCMg: 0, magnesiumMg: 21.1, zincMg: 0.6,
      vitaminB12Mcg: 0, folateMcg: 82.7,
    ),
    MenuItem(name: '9-Grain Wheat', calories: 210, protein: 9, carbs: 39, fat: 3),
    MenuItem(name: 'Italian Herbs & Cheese', calories: 250, protein: 11, carbs: 39, fat: 6),
    MenuItem(
      name: 'Hearty Multigrain', calories: 220, protein: 9, carbs: 41, fat: 3,
      fiber: 3, sodium: 350, ironMg: 1.8, calciumMg: 26, vitaminCMg: 0.1,
      magnesiumMg: 58.9, zincMg: 1.3, vitaminB12Mcg: 0, folateMcg: 56.6,
    ),
    MenuItem(
      name: 'Flatbread', calories: 220, protein: 9, carbs: 40, fat: 5,
      fiber: 1, sodium: 360, ironMg: 2.7, calciumMg: 0,
    ),
  ],
);

const _subwayBread12 = MenuCategory(
  name: 'Bread',
  mode: SelectionMode.single,
  items: [
    MenuItem(
      name: 'Italian White', calories: 400, protein: 16, carbs: 76, fat: 4,
      fiber: 2, sodium: 760, vitaminCMg: 0, magnesiumMg: 42.2, zincMg: 1.3,
      vitaminB12Mcg: 0, folateMcg: 165.4,
    ),
    MenuItem(name: '9-Grain Wheat', calories: 420, protein: 18, carbs: 78, fat: 6),
    MenuItem(name: 'Italian Herbs & Cheese', calories: 500, protein: 22, carbs: 78, fat: 12),
    MenuItem(
      name: 'Hearty Multigrain', calories: 440, protein: 18, carbs: 82, fat: 6,
      fiber: 6, sodium: 700, ironMg: 3.6, calciumMg: 52, vitaminCMg: 0.2,
      magnesiumMg: 117.7, zincMg: 2.6, vitaminB12Mcg: 0, folateMcg: 113.2,
    ),
    MenuItem(
      name: 'Flatbread', calories: 440, protein: 18, carbs: 80, fat: 10,
      fiber: 2, sodium: 720, ironMg: 5.4, calciumMg: 0,
    ),
  ],
);

// Subway lets you stack proteins on the same sandwich (Turkey + Ham, Chicken
// + Bacon, etc.) — switch to multi-select. allowDouble still on so callers
// can double an individual protein's portion.
const _subwayProtein6 = MenuCategory(
  name: 'Protein',
  mode: SelectionMode.multiple,
  allowDouble: true,
  items: [
    MenuItem(
      name: 'Turkey Breast', calories: 60, protein: 12, carbs: 2, fat: 1,
      fiber: 0, sodium: 450, ironMg: 1.8, calciumMg: 0, vitaminCMg: 0,
      magnesiumMg: 10.8, zincMg: 0.5, vitaminB12Mcg: 0.2, folateMcg: 2.3,
    ),
    MenuItem(
      name: 'Black Forest Ham', calories: 60, protein: 11, carbs: 2, fat: 1,
      fiber: 0, sodium: 490, ironMg: 0.4, calciumMg: 0, vitaminCMg: 0,
      magnesiumMg: 12.4, zincMg: 1, vitaminB12Mcg: 0.2, folateMcg: 0,
    ),
    MenuItem(name: 'Rotisserie-Style Chicken', calories: 130, protein: 21, carbs: 2, fat: 4),
    MenuItem(
      name: 'Roast Beef', calories: 80, protein: 14, carbs: 2, fat: 2,
      fiber: 0, sodium: 420, ironMg: 0.4, calciumMg: 0, vitaminCMg: 0,
      magnesiumMg: 13.9, zincMg: 2.2, vitaminB12Mcg: 1.4, folateMcg: 3.5,
    ),
    MenuItem(
      name: 'Tuna', calories: 250, protein: 13, carbs: 0, fat: 21,
      fiber: 0, sodium: 310, ironMg: 0.4, calciumMg: 0,
    ),
    MenuItem(
      name: 'Steak', calories: 110, protein: 17, carbs: 4, fat: 3,
      fiber: 0, sodium: 450, ironMg: 1.1, calciumMg: 0, vitaminCMg: 0,
      magnesiumMg: 9.6, zincMg: 2.8, vitaminB12Mcg: 1.4, folateMcg: 3.2,
    ),
    MenuItem(
      name: 'Meatball Marinara', calories: 280, protein: 14, carbs: 22, fat: 14,
      fiber: 2, sodium: 720, ironMg: 1.4, calciumMg: 52, vitaminCMg: 13.5,
      magnesiumMg: 20.2, zincMg: 5.6, vitaminB12Mcg: 2.5, folateMcg: 16.1,
    ),
    MenuItem(
      name: 'Bacon Strips', calories: 80, protein: 6, carbs: 0, fat: 6,
      fiber: 0, sodium: 170, ironMg: 0.4, calciumMg: 0, vitaminCMg: 0,
      magnesiumMg: 5.3, zincMg: 0.5, vitaminB12Mcg: 0.2, folateMcg: 0,
    ),
    MenuItem(
      name: 'Pepperoni', calories: 80, protein: 4, carbs: 0, fat: 7,
      fiber: 0, sodium: 290, ironMg: 0.4, calciumMg: 0, vitaminCMg: 3.6,
      magnesiumMg: 2.9, zincMg: 0.4, vitaminB12Mcg: 0.2, folateMcg: 0.8,
    ),
    MenuItem(name: 'Veggie Patty', calories: 100, protein: 9, carbs: 12, fat: 3),
  ],
);

/// Footlong proteins are pre-doubled. Multi-select like the 6-inch so users
/// can stack Turkey + Ham + Bacon on a single sub.
const _subwayProtein12 = MenuCategory(
  name: 'Protein',
  mode: SelectionMode.multiple,
  allowDouble: true,
  items: [
    MenuItem(
      name: 'Turkey Breast', calories: 120, protein: 24, carbs: 4, fat: 2,
      fiber: 0, sodium: 900, ironMg: 3.6, calciumMg: 0, vitaminCMg: 0,
      magnesiumMg: 21.5, zincMg: 1.1, vitaminB12Mcg: 0.4, folateMcg: 4.5,
    ),
    MenuItem(
      name: 'Black Forest Ham', calories: 120, protein: 22, carbs: 4, fat: 2,
      fiber: 0, sodium: 980, ironMg: 0.7, calciumMg: 0, vitaminCMg: 0,
      magnesiumMg: 24.9, zincMg: 2, vitaminB12Mcg: 0.5, folateMcg: 0,
    ),
    MenuItem(name: 'Rotisserie-Style Chicken', calories: 260, protein: 42, carbs: 4, fat: 8),
    MenuItem(
      name: 'Roast Beef', calories: 160, protein: 28, carbs: 4, fat: 4,
      fiber: 0, sodium: 840, ironMg: 0.7, calciumMg: 0, vitaminCMg: 0,
      magnesiumMg: 27.8, zincMg: 4.5, vitaminB12Mcg: 2.8, folateMcg: 7,
    ),
    MenuItem(
      name: 'Tuna', calories: 500, protein: 26, carbs: 0, fat: 42,
      fiber: 0, sodium: 620, ironMg: 0.7, calciumMg: 0,
    ),
    MenuItem(
      name: 'Steak', calories: 220, protein: 34, carbs: 8, fat: 6,
      fiber: 0, sodium: 900, ironMg: 2.2, calciumMg: 0, vitaminCMg: 0,
      magnesiumMg: 19.3, zincMg: 5.6, vitaminB12Mcg: 2.7, folateMcg: 6.4,
    ),
    MenuItem(
      name: 'Meatball Marinara', calories: 560, protein: 28, carbs: 44, fat: 28,
      fiber: 4, sodium: 1440, ironMg: 2.9, calciumMg: 104, vitaminCMg: 27,
      magnesiumMg: 40.3, zincMg: 11.3, vitaminB12Mcg: 5, folateMcg: 32.3,
    ),
    MenuItem(
      name: 'Bacon Strips', calories: 160, protein: 12, carbs: 0, fat: 12,
      fiber: 0, sodium: 340, ironMg: 0.7, calciumMg: 0, vitaminCMg: 0,
      magnesiumMg: 10.6, zincMg: 1, vitaminB12Mcg: 0.4, folateMcg: 0,
    ),
    MenuItem(
      name: 'Pepperoni', calories: 160, protein: 8, carbs: 0, fat: 14,
      fiber: 0, sodium: 580, ironMg: 0.7, calciumMg: 0, vitaminCMg: 7.2,
      magnesiumMg: 5.7, zincMg: 0.8, vitaminB12Mcg: 0.4, folateMcg: 1.6,
    ),
  ],
);

const _subwayCheese = MenuCategory(
  name: 'Cheese',
  mode: SelectionMode.single,
  optional: true,
  items: [
    MenuItem(
      name: 'American', calories: 80, protein: 4, carbs: 1, fat: 7,
      fiber: 0, sodium: 420, ironMg: 0, calciumMg: 104, vitaminCMg: 0,
      magnesiumMg: 5.7, zincMg: 0.5, vitaminB12Mcg: 0.3, folateMcg: 1.7,
    ),
    MenuItem(
      name: 'Provolone', calories: 90, protein: 6, carbs: 1, fat: 7,
      fiber: 0, sodium: 220, ironMg: 0, calciumMg: 195, vitaminCMg: 0,
      magnesiumMg: 7.2, zincMg: 0.8, vitaminB12Mcg: 0.4, folateMcg: 2.6,
    ),
    MenuItem(
      name: 'Pepper Jack', calories: 100, protein: 5, carbs: 1, fat: 8,
      fiber: 0, sodium: 480, ironMg: 0, calciumMg: 130, vitaminCMg: 0,
      magnesiumMg: 7.2, zincMg: 0.8, vitaminB12Mcg: 0.2, folateMcg: 4.8,
    ),
    MenuItem(name: 'Swiss', calories: 50, protein: 4, carbs: 0, fat: 4),
    MenuItem(name: 'Shredded Mozzarella', calories: 45, protein: 4, carbs: 0, fat: 3),
    MenuItem(
      name: 'Monterey Cheddar (shredded)', calories: 110, protein: 7, carbs: 1, fat: 9,
      fiber: 0, sodium: 170, ironMg: 0, calciumMg: 195, vitaminCMg: 0,
      magnesiumMg: 8, zincMg: 0.9, vitaminB12Mcg: 0.2, folateMcg: 5.3,
    ),
  ],
);

const _subwayVeggies = MenuCategory(
  name: 'Vegetables',
  mode: SelectionMode.multiple,
  optional: true,
  items: [
    MenuItem(
      name: 'Lettuce', calories: 5, protein: 0, carbs: 1, fat: 0,
      fiber: 0, sodium: 0, ironMg: 0, calciumMg: 0, vitaminCMg: 0.6,
      magnesiumMg: 1.5, zincMg: 0, vitaminB12Mcg: 0, folateMcg: 6.1,
    ),
    MenuItem(
      name: 'Tomatoes', calories: 5, protein: 0, carbs: 1, fat: 0,
      fiber: 0, sodium: 0, ironMg: 0, calciumMg: 0, vitaminCMg: 4.8,
      magnesiumMg: 3.9, zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 5.3,
    ),
    MenuItem(
      name: 'Cucumbers', calories: 5, protein: 0, carbs: 1, fat: 0,
      fiber: 0, sodium: 0, ironMg: 0, calciumMg: 0, vitaminCMg: 0.4,
      magnesiumMg: 1.8, zincMg: 0, vitaminB12Mcg: 0, folateMcg: 1,
    ),
    MenuItem(
      name: 'Green Peppers', calories: 5, protein: 0, carbs: 1, fat: 0,
      fiber: 0, sodium: 0, ironMg: 0, calciumMg: 0, vitaminCMg: 5.6,
      magnesiumMg: 0.7, zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0.7,
    ),
    MenuItem(
      name: 'Red Onions', calories: 5, protein: 0, carbs: 1, fat: 0,
      fiber: 0, sodium: 0, ironMg: 0, calciumMg: 0, vitaminCMg: 0.5,
      magnesiumMg: 0.7, zincMg: 0, vitaminB12Mcg: 0, folateMcg: 1.3,
    ),
    MenuItem(
      name: 'Pickles', calories: 0, protein: 0, carbs: 0, fat: 0,
      fiber: 0, sodium: 160, ironMg: 0, calciumMg: 0, vitaminCMg: 0.3,
      magnesiumMg: 0.8, zincMg: 0, vitaminB12Mcg: 0, folateMcg: 1,
    ),
    MenuItem(
      name: 'Black Olives', calories: 5, protein: 0, carbs: 0, fat: 1,
      fiber: 0, sodium: 25, ironMg: 0, calciumMg: 0, vitaminCMg: 0,
      magnesiumMg: 0.1, zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0,
    ),
    MenuItem(
      name: 'Jalapeños', calories: 0, protein: 0, carbs: 0, fat: 0,
      fiber: 0, sodium: 70, ironMg: 0, calciumMg: 0, vitaminCMg: 0.4,
      magnesiumMg: 0.6, zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0.6,
    ),
    MenuItem(
      name: 'Banana Peppers', calories: 0, protein: 0, carbs: 0, fat: 0,
      fiber: 0, sodium: 65, ironMg: 0, calciumMg: 0, vitaminCMg: 3.3,
      magnesiumMg: 0.7, zincMg: 0, vitaminB12Mcg: 0, folateMcg: 1.2,
    ),
    MenuItem(
      name: 'Spinach', calories: 5, protein: 0, carbs: 1, fat: 0,
      fiber: 0, sodium: 5, ironMg: 0.4, calciumMg: 0, vitaminCMg: 2,
      magnesiumMg: 5.5, zincMg: 0, vitaminB12Mcg: 0, folateMcg: 13.6,
    ),
    MenuItem(
      name: 'Avocado', calories: 60, protein: 1, carbs: 3, fat: 5,
      fiber: 2, sodium: 0, ironMg: 0, calciumMg: 0, vitaminCMg: 2.8,
      magnesiumMg: 8.2, zincMg: 0.2, vitaminB12Mcg: 0, folateMcg: 22.8,
    ),
  ],
);

const _subwaySauces = MenuCategory(
  name: 'Sauces',
  mode: SelectionMode.multiple,
  optional: true,
  items: [
    MenuItem(
      name: 'Mayonnaise', calories: 110, protein: 0, carbs: 0, fat: 12,
      fiber: 0, sodium: 65, ironMg: 0, calciumMg: 0, vitaminCMg: 0,
      magnesiumMg: 0.1, zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0.7,
    ),
    MenuItem(name: 'Light Mayonnaise', calories: 50, protein: 0, carbs: 1, fat: 5),
    MenuItem(
      name: 'Mustard', calories: 5, protein: 0, carbs: 0, fat: 0,
      fiber: 0, sodium: 170, ironMg: 0.4, calciumMg: 0, vitaminCMg: 0,
      magnesiumMg: 6.7, zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 1,
    ),
    MenuItem(name: 'Honey Mustard', calories: 30, protein: 0, carbs: 7, fat: 0),
    MenuItem(name: 'Ranch', calories: 110, protein: 0, carbs: 2, fat: 11),
    MenuItem(name: 'Chipotle Southwest', calories: 100, protein: 0, carbs: 1, fat: 10),
    MenuItem(
      name: 'Sweet Onion Teriyaki', calories: 40, protein: 0, carbs: 9, fat: 0,
      fiber: 0, sodium: 130, ironMg: 0, calciumMg: 0,
    ),
    MenuItem(
      name: 'BBQ Sauce', calories: 35, protein: 0, carbs: 8, fat: 0,
      fiber: 0, sodium: 115, ironMg: 0, calciumMg: 0, vitaminCMg: 0.1,
      magnesiumMg: 1.9, zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0.3,
    ),
    MenuItem(
      name: 'Buffalo Sauce', calories: 10, protein: 0, carbs: 2, fat: 0,
      fiber: 0, sodium: 390, ironMg: 0, calciumMg: 0,
    ),
    MenuItem(
      name: 'Oil & Vinegar', calories: 45, protein: 0, carbs: 0, fat: 5,
      fiber: 0, sodium: 0, ironMg: 0, calciumMg: 0, vitaminCMg: 0,
      magnesiumMg: 0, zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0,
    ),
  ],
);

/// ─── Panda Express shared building-blocks ─────────────────────────
/// Panda lets users pick 1/2/3 entrees depending on the plate size — we
/// model this with the same MenuCategory list and `maxSelections` to cap
/// the picks. The builder UI greys-out unselected items once the cap is hit.
const _pandaSide = MenuCategory(
  name: 'Side',
  mode: SelectionMode.single,
  items: [
    MenuItem(
      name: 'Chow Mein', calories: 600, protein: 15, carbs: 94, fat: 23,
      fiber: 7, sodium: 1000, vitaminCMg: 30.8, magnesiumMg: 56.4,
      zincMg: 1.5, vitaminB12Mcg: 0, folateMcg: 282.1,
    ),
    MenuItem(
      name: 'Fried Rice', calories: 620, protein: 13, carbs: 101, fat: 19,
      fiber: 1, sodium: 1000, vitaminCMg: 13.5, magnesiumMg: 35.6,
      zincMg: 2.5, vitaminB12Mcg: 0, folateMcg: 21.4,
    ),
    MenuItem(
      name: 'White Steamed Rice', calories: 520, protein: 10, carbs: 118, fat: 0,
      fiber: 0, sodium: 0, vitaminCMg: 0, magnesiumMg: 48.4, zincMg: 2,
      vitaminB12Mcg: 0, folateMcg: 233.8,
    ),
    MenuItem(
      name: 'Brown Steamed Rice', calories: 420, protein: 9, carbs: 86, fat: 4,
      vitaminCMg: 0, magnesiumMg: 133.2, zincMg: 2.2, vitaminB12Mcg: 0,
      folateMcg: 17.1,
    ),
    MenuItem(
      name: 'Super Greens', calories: 130, protein: 9, carbs: 14, fat: 4,
      fiber: 7, sodium: 370,
    ),
    MenuItem(name: 'Half Chow Mein + Half Greens', calories: 300, protein: 10, carbs: 45, fat: 12),
  ],
);

const _pandaEntreeItems = [
  MenuItem(
    name: 'Orange Chicken', calories: 510, protein: 16, carbs: 53, fat: 24,
    fiber: 2, sodium: 850, vitaminCMg: 1.8, magnesiumMg: 38.9,
    zincMg: 2.2, vitaminB12Mcg: 0.4, folateMcg: 19.5,
  ),
  MenuItem(
    name: 'Beijing Beef', calories: 470, protein: 14, carbs: 46, fat: 27,
    fiber: 2, sodium: 600, vitaminCMg: 26.7, magnesiumMg: 33.4,
    zincMg: 3.6, vitaminB12Mcg: 1.1, folateMcg: 35.6,
  ),
  MenuItem(
    name: 'Honey Walnut Shrimp', calories: 430, protein: 13, carbs: 32, fat: 28,
    fiber: 1, sodium: 700,
  ),
  MenuItem(
    name: 'Kung Pao Chicken', calories: 320, protein: 17, carbs: 15, fat: 21,
    fiber: 2, sodium: 1050, vitaminCMg: 17.6, magnesiumMg: 59.5,
    zincMg: 1.8, vitaminB12Mcg: 0.3, folateMcg: 39.7,
  ),
  MenuItem(
    name: 'Mushroom Chicken', calories: 220, protein: 13, carbs: 10, fat: 14,
    fiber: 1, sodium: 840, vitaminCMg: 21.8, magnesiumMg: 31.4,
    zincMg: 1.3, vitaminB12Mcg: 0.2, folateMcg: 24.8,
  ),
  MenuItem(name: 'Black Pepper Angus Steak', calories: 210, protein: 19, carbs: 13, fat: 10),
  MenuItem(
    name: 'Broccoli Beef', calories: 150, protein: 15, carbs: 12, fat: 6,
    fiber: 2, sodium: 520, vitaminCMg: 37.5, magnesiumMg: 22.5,
    zincMg: 2.2, vitaminB12Mcg: 0.6, folateMcg: 31.9,
  ),
  MenuItem(
    name: 'Honey Sesame Chicken Breast', calories: 340, protein: 16, carbs: 35, fat: 15,
    fiber: 1, sodium: 540, vitaminCMg: 1.2, magnesiumMg: 25.5,
    zincMg: 1.1, vitaminB12Mcg: 0.3, folateMcg: 9.3,
  ),
  MenuItem(
    name: 'Grilled Teriyaki Chicken', calories: 275, protein: 33, carbs: 14, fat: 10,
    fiber: 0, sodium: 470, vitaminCMg: 0, magnesiumMg: 47.2,
    zincMg: 2.6, vitaminB12Mcg: 0.6, folateMcg: 16.9,
  ),
  MenuItem(
    name: 'String Bean Chicken Breast', calories: 210, protein: 12, carbs: 13, fat: 12,
    fiber: 5, sodium: 560, vitaminCMg: 20.8, magnesiumMg: 30,
    zincMg: 1.2, vitaminB12Mcg: 0.2, folateMcg: 23.7,
  ),
  MenuItem(
    name: 'Sweetfire Chicken Breast', calories: 360, protein: 15, carbs: 40, fat: 15,
    fiber: 2, sodium: 370, vitaminCMg: 3.5, magnesiumMg: 21.6,
    zincMg: 0.6, vitaminB12Mcg: 0.1, folateMcg: 15.8,
  ),
  MenuItem(
    name: 'Eggplant Tofu', calories: 340, protein: 7, carbs: 23, fat: 24,
    fiber: 3, sodium: 520, vitaminCMg: 43.9, magnesiumMg: 76.8,
    zincMg: 1.6, vitaminB12Mcg: 0, folateMcg: 109.7,
  ),
];

const _pandaEntreesPick1 = MenuCategory(
  name: 'Entree',
  mode: SelectionMode.multiple,
  maxSelections: 1,
  items: _pandaEntreeItems,
);
const _pandaEntreesPick2 = MenuCategory(
  name: 'Entrees',
  mode: SelectionMode.multiple,
  maxSelections: 2,
  items: _pandaEntreeItems,
);
const _pandaEntreesPick3 = MenuCategory(
  name: 'Entrees',
  mode: SelectionMode.multiple,
  maxSelections: 3,
  items: _pandaEntreeItems,
);

/// Chick-fil-A drinks — reused across Sandwich and Nuggets meals.
const _cfaDrink = MenuCategory(
  name: 'Drink',
  mode: SelectionMode.single,
  optional: true,
  items: [
    MenuItem(
      name: 'Lemonade (Small)', calories: 220, protein: 0, carbs: 55, fat: 0,
      fiber: 0, sodium: 0, vitaminCMg: 18.5, magnesiumMg: 9.5,
      zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 4.8,
    ),
    MenuItem(
      name: 'Lemonade (Medium)', calories: 320, protein: 0, carbs: 79, fat: 0,
      fiber: 0, sodium: 0, vitaminCMg: 25.4, magnesiumMg: 13,
      zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 6.5,
    ),
    MenuItem(
      name: 'Lemonade (Large)', calories: 420, protein: 0, carbs: 105, fat: 0,
      fiber: 1, sodium: 0, vitaminCMg: 37.1, magnesiumMg: 19,
      zincMg: 0.2, vitaminB12Mcg: 0, folateMcg: 9.5,
    ),
    MenuItem(
      name: 'Diet Lemonade (Medium)', calories: 35, protein: 0, carbs: 13, fat: 0,
      fiber: 0, sodium: 10,
    ),
    MenuItem(
      name: 'Sweet Tea (Medium)', calories: 160, protein: 0, carbs: 41, fat: 0,
      fiber: 0, sodium: 0, vitaminCMg: 0, magnesiumMg: 18.1,
      zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 30.2,
    ),
    MenuItem(
      name: 'Unsweet Tea', calories: 0, protein: 0, carbs: 0, fat: 0,
      fiber: 0, sodium: 0, vitaminCMg: 0, magnesiumMg: 18.1,
      zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 30.2,
    ),
    MenuItem(
      name: 'Coca-Cola (Medium)', calories: 290, protein: 0, carbs: 78, fat: 0,
      fiber: 0, sodium: 45, vitaminCMg: 0, magnesiumMg: 0, zincMg: 0.1,
      vitaminB12Mcg: 0, folateMcg: 0,
    ),
    MenuItem(name: 'Diet Coke (Medium)', calories: 0, protein: 0, carbs: 0, fat: 0),
    MenuItem(
      name: 'Water', calories: 0, protein: 0, carbs: 0, fat: 0,
      fiber: 0, sodium: 0,
    ),
    MenuItem(
      name: 'Milk (1%)', calories: 100, protein: 8, carbs: 12, fat: 3,
      fiber: 0, sodium: 105, vitaminCMg: 0, magnesiumMg: 23.6,
      zincMg: 0.9, vitaminB12Mcg: 1, folateMcg: 10.7,
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────
// Master list — 10 US fast-food chains
// ─────────────────────────────────────────────────────────────────────
final List<RestaurantMenu> restaurantMenus = [
  // 1. CHIPOTLE — published nutrition data from chipotle.com
  RestaurantMenu(
    id: 'chipotle',
    name: 'Chipotle',
    emoji: '🌯',
    accentColor: const Color(0xFFA81612),
    mealTypes: const ['Bowl', 'Burrito', 'Tacos', 'Salad', 'Quesadilla'],
    builders: {
      'Bowl': const [
        _chipotleRice,
        _chipotleBeans,
        _chipotleProtein,
        _chipotleToppings,
        _chipotleSides,
      ],
      'Burrito': const [
        MenuCategory(
          name: 'Tortilla',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Flour Tortilla', calories: 300, protein: 8, carbs: 50, fat: 8,
              fiber: 3, sodium: 600, ironMg: 1.1, calciumMg: 0,
              vitaminCMg: 0, magnesiumMg: 24.9, zincMg: 0.6,
              vitaminB12Mcg: 0, folateMcg: 106.6,
            ),
          ],
        ),
        _chipotleRice,
        _chipotleBeans,
        _chipotleProtein,
        _chipotleToppings,
        _chipotleSides,
      ],
      'Tacos': const [
        MenuCategory(
          name: 'Tortilla (3 tacos)',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Soft Flour (×3)', calories: 270, protein: 9, carbs: 45, fat: 6,
              fiber: 2, sodium: 480, ironMg: 1.1, calciumMg: 0,
              vitaminCMg: 0, magnesiumMg: 18.7, zincMg: 0.5,
              vitaminB12Mcg: 0, folateMcg: 79.9,
            ),
            MenuItem(
              name: 'Crispy Corn (×3)', calories: 210, protein: 3, carbs: 27, fat: 9,
              fiber: 3, sodium: 0, ironMg: 1.1, calciumMg: 170,
              vitaminCMg: 0, magnesiumMg: 35.3, zincMg: 0.7,
              vitaminB12Mcg: 0, folateMcg: 29.3,
            ),
          ],
        ),
        _chipotleProtein,
        _chipotleToppings,
        _chipotleSides,
      ],
      'Salad': const [
        MenuCategory(
          name: 'Base',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Romaine Lettuce', calories: 5, protein: 0, carbs: 1, fat: 0,
              fiber: 1, sodium: 0, ironMg: 0.4, calciumMg: 0,
              vitaminCMg: 6, magnesiumMg: 4, zincMg: 0.1,
              vitaminB12Mcg: 0, folateMcg: 38.6,
            ),
          ],
        ),
        _chipotleBeans,
        _chipotleProtein,
        _chipotleToppings,
        MenuCategory(
          name: 'Dressing',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(
              name: 'Chipotle-Honey Vinaigrette', calories: 220, protein: 1, carbs: 18, fat: 16,
              fiber: 1, sodium: 850, ironMg: 0, calciumMg: 0, vitaminCMg: 0,
            ),
          ],
        ),
      ],
      'Quesadilla': const [
        MenuCategory(
          name: 'Tortilla & Cheese',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Flour Tortilla + Cheese', calories: 530, protein: 22, carbs: 47, fat: 27,
              fiber: 3, sodium: 980, ironMg: 1.1, calciumMg: 400,
              vitaminCMg: 0, magnesiumMg: 40.3, zincMg: 2.3,
              vitaminB12Mcg: 0.5, folateMcg: 116.8,
            ),
          ],
        ),
        _chipotleProtein,
        MenuCategory(
          name: 'Side Salsa',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(
              name: 'Fresh Tomato Salsa', calories: 25, protein: 1, carbs: 4, fat: 0,
              fiber: 1, sodium: 550, ironMg: 0.9, calciumMg: 10,
              vitaminCMg: 8.4, magnesiumMg: 8.9, zincMg: 0.1,
              vitaminB12Mcg: 0, folateMcg: 11.9,
            ),
            MenuItem(
              name: 'Sour Cream', calories: 110, protein: 2, carbs: 2, fat: 9,
              fiber: 0, sodium: 30, ironMg: 0, calciumMg: 60,
              vitaminCMg: 0, magnesiumMg: 5.7, zincMg: 0.2,
              vitaminB12Mcg: 0.1, folateMcg: 3.4,
            ),
            MenuItem(
              name: 'Guacamole', calories: 230, protein: 2, carbs: 8, fat: 22,
              fiber: 6, sodium: 370, ironMg: 1.3, calciumMg: 20,
              vitaminCMg: 4.2, magnesiumMg: 32.9, zincMg: 0.7,
              vitaminB12Mcg: 0, folateMcg: 91.9,
            ),
          ],
        ),
      ],
    },
  ),

  // 2. SUBWAY — 6-inch and footlong values from subway.com nutrition guide.
  RestaurantMenu(
    id: 'subway',
    name: 'Subway',
    emoji: '🥪',
    accentColor: const Color(0xFF008C15),
    mealTypes: const ['6-inch Sub', 'Footlong Sub', 'Wrap', 'Salad'],
    builders: {
      '6-inch Sub': const [
        _subwayBread6,
        _subwayProtein6,
        _subwayCheese,
        _subwayVeggies,
        _subwaySauces,
      ],
      // Footlong = bread + protein doubled; cheese/veggies/sauces are shared
      // with the 6-inch entry — Subway publishes them as the same per-unit
      // calorie counts (a sandwich uses one helping of each topping no matter
      // the size).
      'Footlong Sub': const [
        _subwayBread12,
        _subwayProtein12,
        _subwayCheese,
        _subwayVeggies,
        _subwaySauces,
      ],
      'Wrap': const [
        MenuCategory(
          name: 'Wrap',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Tomato Basil Wrap', calories: 310, protein: 12, carbs: 50, fat: 7,
              fiber: 2, sodium: 580, ironMg: 2.7, calciumMg: 78,
              vitaminCMg: 0, magnesiumMg: 21.2, zincMg: 0.6, vitaminB12Mcg: 0,
              folateMcg: 119.2,
            ),
            MenuItem(
              name: 'Spinach Wrap', calories: 290, protein: 11, carbs: 49, fat: 6,
              fiber: 2, sodium: 580, ironMg: 2.7, calciumMg: 78,
              vitaminCMg: 0, magnesiumMg: 21.2, zincMg: 0.6, vitaminB12Mcg: 0,
              folateMcg: 119.2,
            ),
          ],
        ),
        _subwayProtein6,
        _subwayCheese,
        _subwayVeggies,
        _subwaySauces,
      ],
      'Salad': const [
        MenuCategory(
          name: 'Base',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Mixed Greens', calories: 50, protein: 3, carbs: 9, fat: 1),
          ],
        ),
        _subwayProtein6,
        _subwayCheese,
        _subwayVeggies,
        _subwaySauces,
      ],
    },
  ),

  // 3. McDONALD'S — based on mcdonalds.com nutrition explorer.
  //
  // MICRONUTRIENTS (added 2026-07-25, McDonald's-only pilot):
  //  * fiber, sodium, vitaminDMcg, calciumMg, ironMg, potassiumMg come from
  //    McDonald's own nutrition API (www.mcdonalds.com/dnaapp/itemDetails,
  //    the backend of their nutrition calculator) — authoritative label data.
  //  * vitaminCMg, magnesiumMg, zincMg, vitaminB12Mcg, folateMcg are USDA
  //    FoodData Central estimates (SR Legacy branded McDONALD'S entries or
  //    commodity equivalents), scaled to the serving via kcal ratio —
  //    ESTIMATED values, flagged in report_mcdonalds_micros.txt.
  //  * A null micro means "no sourced value found", never zero. Items with
  //    no current published source (Spicy McChicken, Ranch, Side Salad Tier 1,
  //    Sausage Patty, McFlurry snack sizes, Sprite/Hi-C medium) stay null.
  //  * Big Breakfast intentionally left null: the current menu item (1060
  //    kcal) no longer matches this row's macros (740) — refresh macros first.
  RestaurantMenu(
    id: 'mcdonalds',
    name: "McDonald's",
    emoji: '🍟',
    accentColor: const Color(0xFFFFC72C),
    mealTypes: const ['Burger Meal', 'Chicken Meal', 'Breakfast', 'A La Carte'],
    builders: {
      'Burger Meal': const [
        MenuCategory(
          name: 'Burger',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Hamburger', calories: 250, protein: 12, carbs: 31, fat: 9,
              fiber: 1, sodium: 510, vitaminDMcg: 0, ironMg: 2.5,
              calciumMg: 15, vitaminCMg: 0.6, magnesiumMg: 19.9,
              potassiumMg: 190, zincMg: 1.8, vitaminB12Mcg: 0.8,
              folateMcg: 60.6,
            ),
            MenuItem(
              name: 'Cheeseburger', calories: 300, protein: 15, carbs: 32, fat: 13,
              fiber: 2, sodium: 720, vitaminDMcg: 0, ironMg: 2.5,
              calciumMg: 90, vitaminCMg: 0.7, magnesiumMg: 22.8,
              potassiumMg: 210, zincMg: 2.2, vitaminB12Mcg: 1,
              folateMcg: 67.3,
            ),
            MenuItem(
              name: 'Double Cheeseburger', calories: 450, protein: 25, carbs: 34, fat: 24,
              fiber: 2, sodium: 1120, vitaminDMcg: 0, ironMg: 3.5,
              calciumMg: 180, vitaminCMg: 0.6, magnesiumMg: 32.8,
              potassiumMg: 350, zincMg: 4,
            ),
            MenuItem(
              name: 'McDouble', calories: 400, protein: 22, carbs: 33, fat: 20,
              fiber: 2, sodium: 920, vitaminDMcg: 0, ironMg: 3.5,
              calciumMg: 100, potassiumMg: 320,
            ),
            MenuItem(
              name: 'Quarter Pounder w/ Cheese', calories: 520, protein: 30, carbs: 42, fat: 26,
              fiber: 2, sodium: 1140, vitaminDMcg: 0, ironMg: 4,
              calciumMg: 190, vitaminCMg: 1.6, magnesiumMg: 44.3,
              potassiumMg: 420, zincMg: 5.3, vitaminB12Mcg: 2.5,
              folateMcg: 102.8,
            ),
            MenuItem(
              name: 'Double Quarter Pounder w/ Cheese', calories: 740, protein: 48, carbs: 43, fat: 42,
              fiber: 2, sodium: 1360, vitaminDMcg: 0, ironMg: 6,
              calciumMg: 200, vitaminCMg: 1.7, magnesiumMg: 59.3,
              potassiumMg: 660, zincMg: 9.4, vitaminB12Mcg: 4.7,
              folateMcg: 127.1,
            ),
            MenuItem(
              name: 'Big Mac', calories: 590, protein: 25, carbs: 46, fat: 34,
              fiber: 3, sodium: 1060, vitaminDMcg: 0, ironMg: 4,
              calciumMg: 120, vitaminCMg: 0.9, magnesiumMg: 45.1,
              potassiumMg: 370, zincMg: 4.3, vitaminB12Mcg: 2,
              folateMcg: 103.8,
            ),
            MenuItem(
              name: 'Filet-O-Fish', calories: 390, protein: 16, carbs: 39, fat: 19,
              fiber: 1, sodium: 580, vitaminDMcg: 0, ironMg: 2,
              calciumMg: 60, vitaminCMg: 0.4, magnesiumMg: 36.4,
              potassiumMg: 280, zincMg: 0.8, vitaminB12Mcg: 1.5,
              folateMcg: 28.3,
            ),
          ],
        ),
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Small Fries', calories: 230, protein: 3, carbs: 29, fat: 11,
              fiber: 3, sodium: 190, vitaminDMcg: 0, ironMg: 0.5,
              calciumMg: 10, vitaminCMg: 4, magnesiumMg: 26.3,
              potassiumMg: 470, zincMg: 0.4,
            ),
            MenuItem(
              name: 'Medium Fries', calories: 320, protein: 4, carbs: 43, fat: 15,
              fiber: 4, sodium: 260, vitaminDMcg: 0, ironMg: 1,
              calciumMg: 15, vitaminCMg: 5.5, magnesiumMg: 36.7,
              potassiumMg: 650, zincMg: 0.5,
            ),
            MenuItem(
              name: 'Large Fries', calories: 480, protein: 6, carbs: 63, fat: 23,
              fiber: 6, sodium: 400, vitaminDMcg: 0, ironMg: 1.5,
              calciumMg: 25, vitaminCMg: 8.3, magnesiumMg: 55,
              potassiumMg: 1000, zincMg: 0.8,
            ),
            MenuItem(
              name: 'Apple Slices', calories: 15, protein: 0, carbs: 4, fat: 0,
              fiber: 0, sodium: 0, vitaminDMcg: 0, ironMg: 0, calciumMg: 10,
              potassiumMg: 35,
            ),
            MenuItem(
              name: 'Side Salad', calories: 15, protein: 1, carbs: 3, fat: 0,
              vitaminCMg: 13.7, vitaminB12Mcg: 0, folateMcg: 49.6,
            ),
          ],
        ),
        MenuCategory(
          name: 'Drink',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(
              name: 'Small Coke', calories: 150, protein: 0, carbs: 39, fat: 0,
              fiber: 0, sodium: 40, vitaminDMcg: 0, ironMg: 0, calciumMg: 2,
              vitaminCMg: 0, magnesiumMg: 0, potassiumMg: 10, zincMg: 0.1,
              vitaminB12Mcg: 0, folateMcg: 0,
            ),
            MenuItem(
              name: 'Medium Coke', calories: 210, protein: 0, carbs: 56, fat: 0,
              fiber: 0, sodium: 55, vitaminDMcg: 0, ironMg: 0, calciumMg: 2,
              vitaminCMg: 0, magnesiumMg: 0, potassiumMg: 10, zincMg: 0.1,
              vitaminB12Mcg: 0, folateMcg: 0,
            ),
            MenuItem(
              name: 'Large Coke', calories: 290, protein: 0, carbs: 77, fat: 0,
              fiber: 0, sodium: 80, vitaminDMcg: 0, ironMg: 0, calciumMg: 4,
              vitaminCMg: 0, magnesiumMg: 0, potassiumMg: 15, zincMg: 0.2,
              vitaminB12Mcg: 0, folateMcg: 0,
            ),
            MenuItem(
              name: 'Diet Coke', calories: 0, protein: 0, carbs: 0, fat: 0,
              sodium: 15, vitaminDMcg: 0, ironMg: 0, calciumMg: 0,
              potassiumMg: 0,
            ),
            MenuItem(name: 'Sprite (Medium)', calories: 280, protein: 0, carbs: 77, fat: 0),
            MenuItem(name: 'Hi-C Orange (Medium)', calories: 240, protein: 0, carbs: 66, fat: 0),
            MenuItem(
              name: 'Iced Tea (Unsweet)', calories: 0, protein: 0, carbs: 0, fat: 0,
              sodium: 10, vitaminDMcg: 0, ironMg: 0, calciumMg: 10,
              vitaminCMg: 0, magnesiumMg: 15.8, potassiumMg: 45, zincMg: 0.1,
              vitaminB12Mcg: 0, folateMcg: 26.3,
            ),
            MenuItem(
              name: 'Water', calories: 0, protein: 0, carbs: 0, fat: 0,
              fiber: 0, sodium: 0, vitaminDMcg: 0, ironMg: 0, calciumMg: 0,
              potassiumMg: 0,
            ),
            MenuItem(
              name: 'Low-Fat Milk (1%)', calories: 100, protein: 8, carbs: 12, fat: 3,
              fiber: 0, sodium: 80, vitaminDMcg: 2, ironMg: 0,
              calciumMg: 260, vitaminCMg: 0, magnesiumMg: 26.2,
              potassiumMg: 350, zincMg: 1, vitaminB12Mcg: 1.1,
              folateMcg: 11.9,
            ),
            MenuItem(
              name: 'Chocolate Milk (1%)', calories: 130, protein: 9, carbs: 18, fat: 2.5,
              fiber: 0, sodium: 85, vitaminDMcg: 2, ironMg: 1,
              calciumMg: 270, vitaminCMg: 0, magnesiumMg: 23.9,
              potassiumMg: 390, zincMg: 0.7, vitaminB12Mcg: 0.6,
              folateMcg: 3.4,
            ),
            MenuItem(
              name: 'Coffee (Small)', calories: 0, protein: 0, carbs: 0, fat: 0,
              fiber: 0, sodium: 10, vitaminDMcg: 0, ironMg: 0, calciumMg: 6,
              vitaminCMg: 0, magnesiumMg: 15, potassiumMg: 160, zincMg: 0.1,
              vitaminB12Mcg: 0, folateMcg: 10,
            ),
          ],
        ),
      ],
      'Chicken Meal': const [
        MenuCategory(
          name: 'Entree',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'McChicken', calories: 400, protein: 14, carbs: 39, fat: 21,
              fiber: 1, sodium: 560, vitaminDMcg: 0, ironMg: 2,
              calciumMg: 20, magnesiumMg: 28.6, potassiumMg: 310,
              zincMg: 0.9, vitaminB12Mcg: 0.3,
            ),
            MenuItem(name: 'Spicy McChicken', calories: 410, protein: 14, carbs: 40, fat: 22),
            MenuItem(
              name: 'McCrispy', calories: 470, protein: 27, carbs: 46, fat: 20,
              fiber: 1, sodium: 1140, vitaminDMcg: 0, ironMg: 2,
              calciumMg: 30, potassiumMg: 420,
            ),
            MenuItem(
              name: 'Spicy McCrispy', calories: 530, protein: 27, carbs: 48, fat: 26,
              fiber: 2, sodium: 1320, vitaminDMcg: 0, ironMg: 2.5,
              calciumMg: 30, potassiumMg: 440,
            ),
            MenuItem(
              name: 'McNuggets (4 pc)', calories: 170, protein: 9, carbs: 11, fat: 10,
              fiber: 0, sodium: 340, vitaminDMcg: 0, ironMg: 0.5,
              calciumMg: 6, vitaminCMg: 0.7, magnesiumMg: 13.5,
              potassiumMg: 150, zincMg: 0.3, vitaminB12Mcg: 0.2,
            ),
            MenuItem(
              name: 'McNuggets (6 pc)', calories: 250, protein: 14, carbs: 16, fat: 15,
              sodium: 500, vitaminDMcg: 0, ironMg: 0.5, calciumMg: 10,
              vitaminCMg: 1, magnesiumMg: 19.9, potassiumMg: 220,
              zincMg: 0.5, vitaminB12Mcg: 0.3,
            ),
            MenuItem(
              name: 'McNuggets (10 pc)', calories: 410, protein: 23, carbs: 26, fat: 24,
              fiber: 1, sodium: 850, vitaminDMcg: 0, ironMg: 1,
              calciumMg: 15, vitaminCMg: 1.6, magnesiumMg: 32.6,
              potassiumMg: 360, zincMg: 0.8, vitaminB12Mcg: 0.4,
            ),
            MenuItem(
              name: 'McNuggets (20 pc)', calories: 830, protein: 47, carbs: 53, fat: 49,
              fiber: 2, sodium: 1700, vitaminDMcg: 0, ironMg: 2,
              calciumMg: 35, vitaminCMg: 3.3, magnesiumMg: 66,
              potassiumMg: 730, zincMg: 1.6, vitaminB12Mcg: 0.9,
            ),
          ],
        ),
        MenuCategory(
          name: 'Dipping Sauce',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(
              name: 'Tangy BBQ Sauce', calories: 45, protein: 0, carbs: 11, fat: 0,
              fiber: 0, sodium: 260, vitaminDMcg: 0, ironMg: 0, calciumMg: 4,
              potassiumMg: 55,
            ),
            MenuItem(
              name: 'Sweet ʼn Sour', calories: 50, protein: 0, carbs: 12, fat: 0,
              fiber: 0, sodium: 160, vitaminDMcg: 0, ironMg: 0, calciumMg: 2,
              potassiumMg: 35,
            ),
            MenuItem(
              name: 'Honey Mustard', calories: 60, protein: 0, carbs: 9, fat: 3,
              fiber: 1, sodium: 125, vitaminDMcg: 0, ironMg: 0, calciumMg: 6,
              potassiumMg: 10,
            ),
            MenuItem(name: 'Ranch', calories: 110, protein: 0, carbs: 2, fat: 12),
            MenuItem(
              name: 'Spicy Buffalo', calories: 30, protein: 0, carbs: 1, fat: 3,
              fiber: 0, sodium: 520, vitaminDMcg: 0, ironMg: 0, calciumMg: 0,
              potassiumMg: 20,
            ),
            MenuItem(
              name: 'Honey', calories: 50, protein: 0, carbs: 12, fat: 0,
              fiber: 0, sodium: 0, vitaminDMcg: 0, ironMg: 0, calciumMg: 0,
              potassiumMg: 5,
            ),
          ],
        ),
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(
              name: 'Small Fries', calories: 230, protein: 3, carbs: 29, fat: 11,
              fiber: 3, sodium: 190, vitaminDMcg: 0, ironMg: 0.5,
              calciumMg: 10, vitaminCMg: 4, magnesiumMg: 26.3,
              potassiumMg: 470, zincMg: 0.4,
            ),
            MenuItem(
              name: 'Medium Fries', calories: 320, protein: 4, carbs: 43, fat: 15,
              fiber: 4, sodium: 260, vitaminDMcg: 0, ironMg: 1,
              calciumMg: 15, vitaminCMg: 5.5, magnesiumMg: 36.7,
              potassiumMg: 650, zincMg: 0.5,
            ),
            MenuItem(
              name: 'Large Fries', calories: 480, protein: 6, carbs: 63, fat: 23,
              fiber: 6, sodium: 400, vitaminDMcg: 0, ironMg: 1.5,
              calciumMg: 25, vitaminCMg: 8.3, magnesiumMg: 55,
              potassiumMg: 1000, zincMg: 0.8,
            ),
          ],
        ),
      ],
      'Breakfast': const [
        MenuCategory(
          name: 'Entree',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Egg McMuffin', calories: 310, protein: 17, carbs: 30, fat: 13,
              fiber: 2, sodium: 770, vitaminDMcg: 2, ironMg: 3,
              calciumMg: 170, vitaminCMg: 1.6, magnesiumMg: 27.2,
              potassiumMg: 200, zincMg: 1.8, folateMcg: 107.4,
            ),
            MenuItem(
              name: 'Sausage McMuffin w/ Egg', calories: 480, protein: 21, carbs: 30, fat: 31,
              fiber: 2, sodium: 830, vitaminDMcg: 4, ironMg: 3,
              calciumMg: 170, vitaminCMg: 0, magnesiumMg: 31.5,
              potassiumMg: 260, zincMg: 2.1, vitaminB12Mcg: 1.2,
            ),
            MenuItem(
              name: 'Bacon, Egg & Cheese Biscuit', calories: 460, protein: 19, carbs: 38, fat: 26,
              fiber: 2, sodium: 1330, vitaminDMcg: 0, ironMg: 3,
              calciumMg: 180, vitaminCMg: 3.2, magnesiumMg: 18.2,
              potassiumMg: 240, zincMg: 1.4,
            ),
            MenuItem(
              name: 'Sausage Biscuit w/ Egg', calories: 530, protein: 18, carbs: 36, fat: 35,
              fiber: 2, sodium: 1190, vitaminDMcg: 0, ironMg: 3.5,
              calciumMg: 110, vitaminCMg: 0, magnesiumMg: 22.2,
              potassiumMg: 260, zincMg: 1.8, vitaminB12Mcg: 1,
              folateMcg: 144.9,
            ),
            MenuItem(name: 'Big Breakfast', calories: 740, protein: 28, carbs: 56, fat: 48),
            MenuItem(
              name: 'Hotcakes (3)', calories: 590, protein: 9, carbs: 105, fat: 14,
              fiber: 2, sodium: 530, vitaminDMcg: 0, ironMg: 3,
              calciumMg: 130, vitaminCMg: 0, magnesiumMg: 27.7,
              potassiumMg: 430, zincMg: 0.6, vitaminB12Mcg: 0,
              folateMcg: 138.6,
            ),
            MenuItem(
              name: 'Sausage Burrito', calories: 310, protein: 12, carbs: 26, fat: 17,
              fiber: 1, sodium: 800, vitaminDMcg: 0, ironMg: 2.5,
              calciumMg: 140, magnesiumMg: 20.1, potassiumMg: 170,
              zincMg: 1.2, vitaminB12Mcg: 0.8, folateMcg: 70.5,
            ),
          ],
        ),
        MenuCategory(
          name: 'Add-on',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(
              name: 'Hash Browns', calories: 150, protein: 1, carbs: 15, fat: 9,
              fiber: 2, sodium: 310, vitaminDMcg: 0, ironMg: 0.5,
              calciumMg: 8, vitaminCMg: 2.9, magnesiumMg: 10.3,
              potassiumMg: 240, zincMg: 0.2, folateMcg: 6.2,
            ),
            MenuItem(name: 'Sausage Patty', calories: 170, protein: 7, carbs: 1, fat: 16),
          ],
        ),
      ],
      'A La Carte': const [
        MenuCategory(
          name: 'Item',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(
              name: 'Apple Pie', calories: 230, protein: 2, carbs: 36, fat: 11,
              fiber: 1, sodium: 100, vitaminDMcg: 0, ironMg: 1, calciumMg: 6,
              potassiumMg: 70,
            ),
            MenuItem(name: 'McFlurry M&M (Snack)', calories: 430, protein: 9, carbs: 67, fat: 14),
            MenuItem(name: 'McFlurry Oreo (Snack)', calories: 340, protein: 8, carbs: 53, fat: 11),
            MenuItem(
              name: 'McFlurry M&M (Regular)', calories: 570, protein: 11, carbs: 85, fat: 19,
              fiber: 2, sodium: 170, vitaminDMcg: 0, ironMg: 0.5,
              calciumMg: 370, magnesiumMg: 54.7, potassiumMg: 570,
              zincMg: 1.7, vitaminB12Mcg: 1.9, folateMcg: 9.7,
            ),
            MenuItem(
              name: 'McFlurry Oreo (Regular)', calories: 410, protein: 10, carbs: 64, fat: 13,
              fiber: 1, sodium: 210, vitaminDMcg: 0, ironMg: 1,
              calciumMg: 310, magnesiumMg: 34.8, potassiumMg: 430,
              zincMg: 1.2, vitaminB12Mcg: 1.4, folateMcg: 12.4,
            ),
            MenuItem(
              name: 'Vanilla Cone', calories: 200, protein: 5, carbs: 32, fat: 5,
              fiber: 0, sodium: 80, vitaminDMcg: 0, ironMg: 0.5,
              calciumMg: 180, magnesiumMg: 16, potassiumMg: 240, zincMg: 0.6,
              vitaminB12Mcg: 0.7, folateMcg: 11.1,
            ),
            MenuItem(
              name: 'Hot Fudge Sundae', calories: 320, protein: 7, carbs: 50, fat: 9,
              fiber: 2, sodium: 170, vitaminDMcg: 0, ironMg: 0.5,
              calciumMg: 260, magnesiumMg: 33.7, potassiumMg: 420, zincMg: 1,
              vitaminB12Mcg: 1, folateMcg: 0,
            ),
            MenuItem(
              name: 'Chocolate Chip Cookie', calories: 170, protein: 2, carbs: 22, fat: 8,
              fiber: 1, sodium: 95, vitaminDMcg: 0, ironMg: 2, calciumMg: 10,
              potassiumMg: 60,
            ),
            MenuItem(
              name: 'Baked Apple Pie', calories: 230, protein: 2, carbs: 36, fat: 11,
              fiber: 1, sodium: 100, vitaminDMcg: 0, ironMg: 1, calciumMg: 6,
              potassiumMg: 70,
            ),
          ],
        ),
      ],
    },
  ),

  // 4. CHICK-FIL-A — published nutrition on chick-fil-a.com.
  RestaurantMenu(
    id: 'chickfila',
    name: 'Chick-fil-A',
    emoji: '🐔',
    accentColor: const Color(0xFFE51636),
    mealTypes: const ['Sandwich Meal', 'Nuggets Meal', 'Salad', 'Breakfast'],
    builders: {
      'Sandwich Meal': const [
        MenuCategory(
          name: 'Sandwich',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Original Chicken Sandwich', calories: 420, protein: 28, carbs: 41, fat: 17,
              fiber: 1, sodium: 1460, magnesiumMg: 40.5, zincMg: 1,
              vitaminB12Mcg: 0.2, folateMcg: 79.3,
            ),
            MenuItem(
              name: 'Deluxe Chicken Sandwich', calories: 490, protein: 31, carbs: 42, fat: 21,
              fiber: 1, sodium: 1700,
            ),
            MenuItem(
              name: 'Spicy Chicken Sandwich', calories: 450, protein: 28, carbs: 42, fat: 19,
              fiber: 1, sodium: 1730, magnesiumMg: 43.4, zincMg: 1.1,
              vitaminB12Mcg: 0.2, folateMcg: 84.9,
            ),
            MenuItem(
              name: 'Spicy Deluxe Sandwich', calories: 540, protein: 32, carbs: 44, fat: 26,
              fiber: 2, sodium: 1880,
            ),
            MenuItem(
              name: 'Grilled Chicken Sandwich', calories: 320, protein: 28, carbs: 41, fat: 6,
              fiber: 3, sodium: 765,
            ),
            MenuItem(
              name: 'Grilled Chicken Club', calories: 440, protein: 36, carbs: 42, fat: 13,
              fiber: 3, sodium: 1055,
            ),
            MenuItem(name: 'Chicken Club Sandwich', calories: 520, protein: 35, carbs: 41, fat: 23),
          ],
        ),
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Waffle Fries (Small)', calories: 320, protein: 4, carbs: 38, fat: 17,
              fiber: 4, sodium: 190, vitaminCMg: 4.8, magnesiumMg: 35.9,
              zincMg: 0.5, vitaminB12Mcg: 0, folateMcg: 30.8,
            ),
            MenuItem(
              name: 'Waffle Fries (Medium)', calories: 420, protein: 5, carbs: 49, fat: 24,
              fiber: 5, sodium: 240, vitaminCMg: 6.3, magnesiumMg: 47.1,
              zincMg: 0.7, vitaminB12Mcg: 0, folateMcg: 40.4,
            ),
            MenuItem(
              name: 'Waffle Fries (Large)', calories: 600, protein: 7, carbs: 70, fat: 33,
              fiber: 7, sodium: 340, vitaminCMg: 9, magnesiumMg: 67.3,
              zincMg: 1, vitaminB12Mcg: 0, folateMcg: 57.7,
            ),
            MenuItem(
              name: 'Mac & Cheese', calories: 270, protein: 12, carbs: 25, fat: 14,
              fiber: 2, sodium: 710,
            ),
            MenuItem(
              name: 'Fruit Cup', calories: 60, protein: 1, carbs: 16, fat: 0,
              fiber: 2, sodium: 0,
            ),
            MenuItem(name: 'Side Salad', calories: 160, protein: 8, carbs: 11, fat: 9),
            MenuItem(
              name: 'Chicken Noodle Soup', calories: 255, protein: 14, carbs: 27, fat: 9,
              fiber: 2, sodium: 1290,
            ),
          ],
        ),
        MenuCategory(
          name: 'Sauce',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(
              name: 'Chick-fil-A Sauce', calories: 140, protein: 0, carbs: 6, fat: 13,
              fiber: 0, sodium: 170,
            ),
            MenuItem(
              name: 'Polynesian Sauce', calories: 110, protein: 0, carbs: 17, fat: 5,
              fiber: 0, sodium: 210,
            ),
            MenuItem(
              name: 'Honey Mustard', calories: 45, protein: 0, carbs: 10, fat: 0,
              fiber: 0, sodium: 160,
            ),
            MenuItem(
              name: 'Garden Herb Ranch', calories: 140, protein: 0, carbs: 1, fat: 15,
              fiber: 0, sodium: 170,
            ),
            MenuItem(
              name: 'BBQ Sauce', calories: 45, protein: 0, carbs: 11, fat: 0,
              fiber: 0, sodium: 200,
            ),
            MenuItem(
              name: 'Buffalo Sauce', calories: 15, protein: 0, carbs: 1, fat: 1,
              fiber: 0, sodium: 570,
            ),
            MenuItem(
              name: 'Sriracha Sauce', calories: 70, protein: 0, carbs: 10, fat: 4,
              fiber: 0, sodium: 380,
            ),
          ],
        ),
        _cfaDrink,
      ],
      'Nuggets Meal': const [
        MenuCategory(
          name: 'Nuggets',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Nuggets (5 ct)', calories: 130, protein: 14, carbs: 6, fat: 6,
              fiber: 0, sodium: 760, vitaminCMg: 0.7, magnesiumMg: 21.1,
              zincMg: 0.5, vitaminB12Mcg: 0.1, folateMcg: 28.1,
            ),
            MenuItem(
              name: 'Nuggets (8 ct)', calories: 250, protein: 27, carbs: 11, fat: 11,
              fiber: 0, sodium: 1210, vitaminCMg: 1.1,
              magnesiumMg: 32.9, zincMg: 0.8, vitaminB12Mcg: 0.2,
              folateMcg: 43.9,
            ),
            MenuItem(
              name: 'Nuggets (12 ct)', calories: 380, protein: 40, carbs: 17, fat: 17,
              fiber: 0, sodium: 1820, vitaminCMg: 1.7, magnesiumMg: 50,
              zincMg: 1.2, vitaminB12Mcg: 0.3, folateMcg: 66.7,
            ),
            MenuItem(
              name: 'Nuggets (30 ct)', calories: 950, protein: 100, carbs: 42, fat: 42,
              fiber: 0, sodium: 4550, vitaminCMg: 4.2, magnesiumMg: 125,
              zincMg: 3, vitaminB12Mcg: 0.8, folateMcg: 166.7,
            ),
            MenuItem(
              name: 'Grilled Nuggets (8 ct)', calories: 130, protein: 25, carbs: 1, fat: 3,
              fiber: 0, sodium: 440, vitaminCMg: 0, magnesiumMg: 27.2,
              zincMg: 0.7, vitaminB12Mcg: 0.2,
            ),
            MenuItem(
              name: 'Grilled Nuggets (12 ct)', calories: 200, protein: 38, carbs: 2, fat: 4,
              fiber: 0, sodium: 660, vitaminCMg: 0, magnesiumMg: 41.9,
              zincMg: 1.1, vitaminB12Mcg: 0.3,
            ),
            MenuItem(
              name: 'Chicken Strips (3 ct)', calories: 350, protein: 28, carbs: 17, fat: 17,
              fiber: 0, sodium: 870, vitaminCMg: 1.4, magnesiumMg: 40.8,
              zincMg: 1, vitaminB12Mcg: 0.3, folateMcg: 54.4,
            ),
            MenuItem(
              name: 'Chicken Strips (4 ct)', calories: 470, protein: 38, carbs: 23, fat: 23,
              fiber: 0, sodium: 1150, vitaminCMg: 1.8,
              magnesiumMg: 53.9, zincMg: 1.3, vitaminB12Mcg: 0.3,
              folateMcg: 71.9,
            ),
          ],
        ),
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Waffle Fries (Medium)', calories: 420, protein: 5, carbs: 49, fat: 24,
              fiber: 5, sodium: 240, vitaminCMg: 6.3, magnesiumMg: 47.1,
              zincMg: 0.7, vitaminB12Mcg: 0, folateMcg: 40.4,
            ),
            MenuItem(
              name: 'Mac & Cheese', calories: 270, protein: 12, carbs: 25, fat: 14,
              fiber: 2, sodium: 710,
            ),
            MenuItem(
              name: 'Fruit Cup', calories: 60, protein: 1, carbs: 16, fat: 0,
              fiber: 2, sodium: 0,
            ),
          ],
        ),
        MenuCategory(
          name: 'Sauce',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(
              name: 'Chick-fil-A Sauce', calories: 140, protein: 0, carbs: 6, fat: 13,
              fiber: 0, sodium: 170,
            ),
            MenuItem(
              name: 'Polynesian Sauce', calories: 110, protein: 0, carbs: 17, fat: 5,
              fiber: 0, sodium: 210,
            ),
            MenuItem(
              name: 'Honey Mustard', calories: 45, protein: 0, carbs: 10, fat: 0,
              fiber: 0, sodium: 160,
            ),
            MenuItem(
              name: 'BBQ Sauce', calories: 45, protein: 0, carbs: 11, fat: 0,
              fiber: 0, sodium: 200,
            ),
            MenuItem(
              name: 'Sriracha Sauce', calories: 70, protein: 0, carbs: 10, fat: 4,
              fiber: 0, sodium: 380,
            ),
            MenuItem(
              name: 'Buffalo Sauce', calories: 15, protein: 0, carbs: 1, fat: 1,
              fiber: 0, sodium: 570,
            ),
          ],
        ),
        _cfaDrink,
      ],
      'Salad': const [
        MenuCategory(
          name: 'Salad',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Cobb Salad (Grilled)', calories: 420, protein: 40, carbs: 21, fat: 21),
            MenuItem(name: 'Cobb Salad (Spicy Filet)', calories: 510, protein: 33, carbs: 32, fat: 28),
            MenuItem(name: 'Market Salad (Grilled)', calories: 330, protein: 27, carbs: 22, fat: 14),
            MenuItem(name: 'Spicy Southwest Salad (Grilled)', calories: 450, protein: 33, carbs: 32, fat: 21),
          ],
        ),
        MenuCategory(
          name: 'Dressing',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(
              name: 'Avocado Lime Ranch', calories: 310, protein: 1, carbs: 4, fat: 32,
              fiber: 1, sodium: 520,
            ),
            MenuItem(
              name: 'Garlic & Herb Ranch', calories: 280, protein: 1, carbs: 2, fat: 30,
              fiber: 0, sodium: 440,
            ),
            MenuItem(
              name: 'Light Italian', calories: 25, protein: 0, carbs: 4, fat: 1,
              fiber: 0, sodium: 470,
            ),
            MenuItem(name: 'Zesty Apple Cider Vinaigrette', calories: 140, protein: 0, carbs: 16, fat: 9),
          ],
        ),
      ],
      'Breakfast': const [
        MenuCategory(
          name: 'Entree',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Chicken Biscuit', calories: 460, protein: 19, carbs: 47, fat: 23,
              fiber: 2, sodium: 1510,
            ),
            MenuItem(
              name: 'Spicy Chicken Biscuit', calories: 470, protein: 19, carbs: 49, fat: 23,
              fiber: 3, sodium: 1570,
            ),
            MenuItem(
              name: 'Chick-n-Minis (4 ct)', calories: 370, protein: 17, carbs: 38, fat: 16,
              fiber: 2, sodium: 1060,
            ),
            MenuItem(
              name: 'Hash Brown Scramble Burrito', calories: 700, protein: 30, carbs: 53, fat: 41,
              fiber: 3, sodium: 1770,
            ),
            MenuItem(
              name: 'Bacon Egg & Cheese Biscuit', calories: 460, protein: 20, carbs: 39, fat: 25,
              fiber: 2, sodium: 1220,
            ),
            MenuItem(
              name: 'Egg White Grill', calories: 290, protein: 26, carbs: 30, fat: 7,
              fiber: 1, sodium: 990,
            ),
          ],
        ),
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(
              name: 'Hash Browns', calories: 240, protein: 2, carbs: 26, fat: 15,
              fiber: 3, sodium: 440, vitaminCMg: 5.6, magnesiumMg: 22.4,
              zincMg: 0.4, folateMcg: 11.7,
            ),
            MenuItem(
              name: 'Fruit Cup', calories: 60, protein: 1, carbs: 16, fat: 0,
              fiber: 2, sodium: 0,
            ),
            MenuItem(
              name: 'Greek Yogurt Parfait', calories: 230, protein: 11, carbs: 37, fat: 5,
              fiber: 1, sodium: 85,
            ),
          ],
        ),
      ],
    },
  ),

  // 5. TACO BELL — from tacobell.com nutrition calculator.
  RestaurantMenu(
    id: 'tacobell',
    name: 'Taco Bell',
    emoji: '🌮',
    accentColor: const Color(0xFF702082),
    mealTypes: const ['Tacos', 'Burritos', 'Bowls', 'Quesadilla'],
    builders: {
      'Tacos': const [
        MenuCategory(
          name: 'Taco',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(
              name: 'Crunchy Taco', calories: 170, protein: 8, carbs: 13, fat: 9,
              fiber: 3.1, sodium: 309.7, vitaminDMcg: 0.1, ironMg: 1.1,
              calciumMg: 61.2, vitaminCMg: 0.9, magnesiumMg: 23.8,
              potassiumMg: 145.9, zincMg: 1.3, vitaminB12Mcg: 0.7,
              folateMcg: 14.1,
            ),
            MenuItem(
              name: 'Crunchy Taco Supreme', calories: 200, protein: 9, carbs: 15, fat: 12,
              fiber: 3.4, sodium: 323.1, vitaminDMcg: 0.1, ironMg: 1.1,
              calciumMg: 76.9, vitaminCMg: 4.3, potassiumMg: 203,
            ),
            MenuItem(
              name: 'Soft Taco (Beef)', calories: 180, protein: 9, carbs: 18, fat: 8,
              fiber: 2.7, sodium: 504.2, vitaminDMcg: 0.1, ironMg: 1.9,
              calciumMg: 104.2, vitaminCMg: 1.1, magnesiumMg: 16.6,
              potassiumMg: 137.4, zincMg: 1.2, vitaminB12Mcg: 0.7,
              folateMcg: 45.4,
            ),
            MenuItem(
              name: 'Soft Taco Supreme', calories: 210, protein: 10, carbs: 21, fat: 10,
              fiber: 2.9, sodium: 517.5, vitaminDMcg: 0.1, ironMg: 1.9,
              calciumMg: 119.9, vitaminCMg: 4.6, potassiumMg: 194.5,
            ),
            MenuItem(
              name: 'Doritos Locos Taco', calories: 170, protein: 8, carbs: 13, fat: 9,
              fiber: 3, sodium: 369.2, vitaminDMcg: 0.1, ironMg: 1.1,
              calciumMg: 69.4, vitaminCMg: 0.7, magnesiumMg: 23.8,
              potassiumMg: 148.9, zincMg: 1.3, vitaminB12Mcg: 0.7,
              folateMcg: 14.1,
            ),
            MenuItem(
              name: 'Doritos Locos Taco Supreme', calories: 200, protein: 9, carbs: 16, fat: 11,
              fiber: 3.3, sodium: 382.5, vitaminDMcg: 0.1, ironMg: 1.1,
              calciumMg: 85.2, vitaminCMg: 4.1, potassiumMg: 206,
            ),
            MenuItem(
              name: 'Spicy Potato Soft Taco', calories: 230, protein: 6, carbs: 28, fat: 11,
              fiber: 2.4, sodium: 471.7, vitaminDMcg: 0, ironMg: 1.2,
              calciumMg: 104.2, vitaminCMg: 1.2, potassiumMg: 268.2,
            ),
            MenuItem(
              name: 'Cheesy Gordita Crunch', calories: 500, protein: 20, carbs: 41, fat: 27,
              fiber: 5.6, sodium: 834.5, vitaminDMcg: 0.1, ironMg: 2.7,
              calciumMg: 300.2, vitaminCMg: 1.9, potassiumMg: 250.2,
            ),
            MenuItem(
              name: 'Chalupa Supreme (Beef)', calories: 360, protein: 13, carbs: 30, fat: 21,
              fiber: 4.4, sodium: 574.7, vitaminDMcg: 0.1, ironMg: 2.5,
              calciumMg: 122.6, vitaminCMg: 4.5, potassiumMg: 228.1,
            ),
          ],
        ),
        MenuCategory(
          name: 'Sauce Packets',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(
              name: 'Mild Sauce', calories: 0, protein: 0, carbs: 0, fat: 0,
              fiber: 0.1, sodium: 27.9, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 0.7, vitaminCMg: 0, potassiumMg: 10.2,
            ),
            MenuItem(
              name: 'Hot Sauce', calories: 0, protein: 0, carbs: 0, fat: 0,
              fiber: 0.1, sodium: 42.9, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 0.6, vitaminCMg: 0, potassiumMg: 10.9,
            ),
            MenuItem(
              name: 'Fire Sauce', calories: 0, protein: 0, carbs: 0, fat: 0,
              fiber: 0.1, sodium: 53.2, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 0.9, vitaminCMg: 0, potassiumMg: 15.8,
            ),
            MenuItem(
              name: 'Diablo Sauce', calories: 0, protein: 0, carbs: 0, fat: 0,
              fiber: 0.1, sodium: 34.1, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 1.1, vitaminCMg: 0.4, potassiumMg: 13.7,
            ),
          ],
        ),
      ],
      'Burritos': const [
        MenuCategory(
          name: 'Burrito',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Bean Burrito', calories: 350, protein: 13, carbs: 54, fat: 9,
              fiber: 8.5, sodium: 1084.4, vitaminDMcg: 3.1, ironMg: 3.8,
              calciumMg: 203.8, vitaminCMg: 3.2, magnesiumMg: 58.6,
              potassiumMg: 422.7, zincMg: 1.5, vitaminB12Mcg: 0.3,
              folateMcg: 86.1,
            ),
            MenuItem(
              name: 'Burrito Supreme (Beef)', calories: 390, protein: 16, carbs: 51, fat: 13,
              fiber: 7.5, sodium: 1164, vitaminDMcg: 1.6, ironMg: 4.1,
              calciumMg: 214.1, vitaminCMg: 7.2, magnesiumMg: 49,
              potassiumMg: 429.5, zincMg: 1.9, vitaminB12Mcg: 0.6,
              folateMcg: 95.9,
            ),
            MenuItem(name: 'Chicken Burrito (Cantina)', calories: 460, protein: 25, carbs: 57, fat: 14),
            MenuItem(
              name: '5-Layer Burrito', calories: 490, protein: 17, carbs: 65, fat: 18,
              fiber: 7.4, sodium: 1288.5, vitaminDMcg: 1.6, ironMg: 4.8,
              calciumMg: 264.2, vitaminCMg: 1.8, magnesiumMg: 55.9,
              potassiumMg: 469.2, zincMg: 4, vitaminB12Mcg: 1.3,
              folateMcg: 107.4,
            ),
            MenuItem(
              name: 'Grilled Cheese Burrito', calories: 720, protein: 27, carbs: 81, fat: 32,
              fiber: 7, sodium: 1484.3, vitaminDMcg: 0.2, ironMg: 3.7,
              calciumMg: 529.7, vitaminCMg: 1.5, potassiumMg: 420.3,
            ),
            MenuItem(
              name: 'Crunchwrap Supreme', calories: 530, protein: 16, carbs: 71, fat: 21,
              fiber: 5.9, sodium: 1214.6, vitaminDMcg: 0.1, ironMg: 5,
              calciumMg: 246.2, vitaminCMg: 6.5, potassiumMg: 531.9,
            ),
            MenuItem(name: 'Quesarito', calories: 650, protein: 21, carbs: 67, fat: 33),
          ],
        ),
        MenuCategory(
          name: 'Add-On',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(
              name: 'Add Guacamole', calories: 50, protein: 1, carbs: 3, fat: 5,
              vitaminCMg: 2.6, magnesiumMg: 7.2, zincMg: 0.2,
              vitaminB12Mcg: 0, folateMcg: 20.4,
            ),
            MenuItem(name: 'Add Sour Cream', calories: 70, protein: 1, carbs: 1, fat: 6),
            MenuItem(name: 'Add Jalapeño Sauce', calories: 50, protein: 0, carbs: 1, fat: 5),
          ],
        ),
      ],
      'Bowls': const [
        MenuCategory(
          name: 'Bowl',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Power Menu Bowl (Chicken)', calories: 470, protein: 27, carbs: 51, fat: 19),
            MenuItem(name: 'Power Menu Bowl (Steak)', calories: 470, protein: 24, carbs: 51, fat: 20),
            MenuItem(
              name: 'Power Menu Bowl (Veggie)', calories: 430, protein: 13, carbs: 56, fat: 18,
              fiber: 11.6, sodium: 861.7, vitaminDMcg: 0.1, ironMg: 2.5,
              calciumMg: 162.9, potassiumMg: 616.2,
            ),
            MenuItem(name: 'Black Bean Burrito Bowl', calories: 400, protein: 14, carbs: 65, fat: 11),
          ],
        ),
      ],
      'Quesadilla': const [
        MenuCategory(
          name: 'Quesadilla',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Cheese Quesadilla', calories: 470, protein: 19, carbs: 39, fat: 26,
              fiber: 3.8, sodium: 981, vitaminDMcg: 0, ironMg: 2.5,
              calciumMg: 489.5, vitaminCMg: 1.2, magnesiumMg: 32,
              potassiumMg: 159.6, zincMg: 2.4, vitaminB12Mcg: 0.6,
              folateMcg: 80.8,
            ),
            MenuItem(
              name: 'Chicken Quesadilla', calories: 520, protein: 28, carbs: 39, fat: 28,
              fiber: 4.1, sodium: 1244.5, vitaminDMcg: 0, ironMg: 2.6,
              calciumMg: 492, vitaminCMg: 1.8, magnesiumMg: 40.1,
              potassiumMg: 290.9, zincMg: 2, vitaminB12Mcg: 0.4,
              folateMcg: 94.1,
            ),
            MenuItem(
              name: 'Steak Quesadilla', calories: 520, protein: 26, carbs: 39, fat: 29,
              fiber: 3.9, sodium: 1255.7, vitaminDMcg: 0, ironMg: 3.1,
              calciumMg: 504.7, vitaminCMg: 1.2, magnesiumMg: 34.4,
              potassiumMg: 257.8, zincMg: 3.8, vitaminB12Mcg: 1.3,
              folateMcg: 90.2,
            ),
          ],
        ),
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(
              name: 'Cinnamon Twists', calories: 170, protein: 1, carbs: 27, fat: 6,
              fiber: 0.9, sodium: 151, vitaminDMcg: 0, ironMg: 0.4,
              calciumMg: 4.6, vitaminCMg: 0, potassiumMg: 29.2,
            ),
            MenuItem(
              name: 'Chips & Nacho Cheese', calories: 230, protein: 4, carbs: 28, fat: 11,
              fiber: 2, sodium: 283.3, vitaminDMcg: 0, ironMg: 0.2,
              calciumMg: 60.9, vitaminCMg: 0, magnesiumMg: 26.4,
              potassiumMg: 293.2, zincMg: 0.5, vitaminB12Mcg: 0,
              folateMcg: 6.3,
            ),
            MenuItem(
              name: 'Cheesy Fiesta Potatoes', calories: 220, protein: 4, carbs: 29, fat: 12,
              fiber: 2.6, sodium: 521.7, vitaminDMcg: 0, ironMg: 0.3,
              calciumMg: 35.5, vitaminCMg: 0.2, potassiumMg: 551.5,
            ),
          ],
        ),
      ],
    },
  ),

  // 6. STARBUCKS — drink-focused; grande default values from starbucks.com.
  RestaurantMenu(
    id: 'starbucks',
    name: 'Starbucks',
    emoji: '☕',
    accentColor: const Color(0xFF00704A),
    mealTypes: const ['Hot Drinks', 'Cold Drinks', 'Frappuccinos', 'Food'],
    builders: {
      'Hot Drinks': const [
        MenuCategory(
          name: 'Drink (Grande / 16 oz)',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Brewed Coffee', calories: 5, protein: 1, carbs: 0, fat: 0,
              fiber: 0, sodium: 10, vitaminCMg: 0, magnesiumMg: 14.2,
              zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 9.5,
            ),
            MenuItem(
              name: 'Caffè Americano', calories: 15, protein: 1, carbs: 3, fat: 0,
              fiber: 0, sodium: 10, vitaminCMg: 0.1, magnesiumMg: 53.2,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0.7,
            ),
            MenuItem(
              name: 'Caffè Latte (2% Milk)', calories: 190, protein: 13, carbs: 18, fat: 7,
              fiber: 0, sodium: 170, vitaminCMg: 0.8, magnesiumMg: 76.4,
              zincMg: 1.8, vitaminB12Mcg: 2, folateMcg: 19,
            ),
            MenuItem(
              name: 'Cappuccino (2% Milk)', calories: 140, protein: 9, carbs: 13, fat: 5,
              fiber: 0, sodium: 120, vitaminCMg: 0.6, magnesiumMg: 65.4,
              zincMg: 1.3, vitaminB12Mcg: 1.4, folateMcg: 14,
            ),
            MenuItem(
              name: 'Caffè Mocha (2% Milk)', calories: 360, protein: 14, carbs: 44, fat: 14,
              fiber: 4, sodium: 150,
            ),
            MenuItem(
              name: 'Caramel Macchiato (2% Milk)', calories: 250, protein: 10, carbs: 35, fat: 7,
              fiber: 0, sodium: 150,
            ),
            MenuItem(
              name: 'Pumpkin Spice Latte (2% Milk)', calories: 390, protein: 14, carbs: 52, fat: 14,
              fiber: 0, sodium: 230,
            ),
            MenuItem(
              name: 'Chai Tea Latte (2% Milk)', calories: 190, protein: 7, carbs: 31, fat: 4,
              fiber: 0, sodium: 105,
            ),
            MenuItem(
              name: 'White Chocolate Mocha (2%)', calories: 430, protein: 15, carbs: 53, fat: 18,
              fiber: 0, sodium: 220,
            ),
            MenuItem(
              name: 'Hot Chocolate (2% Milk)', calories: 370, protein: 14, carbs: 43, fat: 16,
              fiber: 4, sodium: 160,
            ),
          ],
        ),
        MenuCategory(
          name: 'Milk Swap',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'No Swap (default 2%)', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Skim Milk (–40 cal)', calories: -40, protein: 0, carbs: 0, fat: -7),
            MenuItem(name: 'Whole Milk (+30 cal)', calories: 30, protein: 0, carbs: 0, fat: 4),
            MenuItem(name: 'Almond Milk (–60 cal)', calories: -60, protein: -10, carbs: -10, fat: -4),
            MenuItem(name: 'Oat Milk (+20 cal)', calories: 20, protein: -6, carbs: 8, fat: 2),
            MenuItem(name: 'Coconut Milk (–50 cal)', calories: -50, protein: -11, carbs: -8, fat: 1),
          ],
        ),
        MenuCategory(
          name: 'Add-Ons',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(
              name: 'Extra Shot Espresso', calories: 5, protein: 1, carbs: 0, fat: 0,
              fiber: 0, sodium: 0, vitaminCMg: 0, magnesiumMg: 17.7,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0.2,
            ),
            MenuItem(name: 'Vanilla Syrup (pump)', calories: 20, protein: 0, carbs: 5, fat: 0),
            MenuItem(name: 'Caramel Syrup (pump)', calories: 20, protein: 0, carbs: 5, fat: 0),
            MenuItem(name: 'Hazelnut Syrup (pump)', calories: 20, protein: 0, carbs: 5, fat: 0),
            MenuItem(name: 'Sugar-Free Vanilla (pump)', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Whipped Cream', calories: 70, protein: 1, carbs: 4, fat: 7),
          ],
        ),
      ],
      'Cold Drinks': const [
        MenuCategory(
          name: 'Drink (Grande / 16 oz)',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Iced Coffee', calories: 80, protein: 0, carbs: 20, fat: 0),
            MenuItem(
              name: 'Iced Caffè Americano', calories: 15, protein: 1, carbs: 3, fat: 0,
              fiber: 0, sodium: 15, vitaminCMg: 0.1, magnesiumMg: 53.2,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0.7,
            ),
            MenuItem(
              name: 'Iced Caffè Latte (2%)', calories: 130, protein: 9, carbs: 13, fat: 5,
              fiber: 0, sodium: 115, vitaminCMg: 0.6, magnesiumMg: 63.2,
              zincMg: 1.2, vitaminB12Mcg: 1.3, folateMcg: 13,
            ),
            MenuItem(
              name: 'Iced Caramel Macchiato (2%)', calories: 250, protein: 10, carbs: 35, fat: 7,
              fiber: 0, sodium: 150,
            ),
            MenuItem(
              name: 'Iced Brown Sugar Oatmilk Shaken Espresso', calories: 150, protein: 2, carbs: 27, fat: 4.5,
              fiber: 2, sodium: 150,
            ),
            MenuItem(
              name: 'Iced Shaken Espresso', calories: 100, protein: 2, carbs: 14, fat: 4,
              fiber: 0, sodium: 50,
            ),
            MenuItem(
              name: 'Cold Brew (Black)', calories: 5, protein: 0, carbs: 0, fat: 0,
              fiber: 0, sodium: 15, vitaminCMg: 0, magnesiumMg: 14.2,
              zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 9.5,
            ),
            MenuItem(
              name: 'Vanilla Sweet Cream Cold Brew', calories: 110, protein: 1, carbs: 14, fat: 6,
              fiber: 0, sodium: 20,
            ),
            MenuItem(
              name: 'Pink Drink', calories: 140, protein: 1, carbs: 27, fat: 3,
              fiber: 1, sodium: 85,
            ),
            MenuItem(
              name: 'Mango Dragonfruit Refresher', calories: 90, protein: 0, carbs: 21, fat: 0,
              fiber: 0, sodium: 40,
            ),
          ],
        ),
      ],
      'Frappuccinos': const [
        MenuCategory(
          name: 'Frappuccino (Grande)',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Caramel Frappuccino', calories: 380, protein: 4, carbs: 54, fat: 16,
              fiber: 0, sodium: 230,
            ),
            MenuItem(
              name: 'Mocha Frappuccino', calories: 370, protein: 5, carbs: 54, fat: 15,
              fiber: 1, sodium: 220,
            ),
            MenuItem(
              name: 'Java Chip Frappuccino', calories: 440, protein: 6, carbs: 63, fat: 19,
              fiber: 2, sodium: 260,
            ),
            MenuItem(
              name: 'Vanilla Bean Crème Frappuccino', calories: 410, protein: 6, carbs: 64, fat: 14,
              fiber: 0, sodium: 250,
            ),
            MenuItem(
              name: 'Strawberry Crème Frappuccino', calories: 370, protein: 6, carbs: 60, fat: 12,
              fiber: 0, sodium: 240,
            ),
            MenuItem(
              name: 'Matcha Crème Frappuccino', calories: 320, protein: 5, carbs: 46, fat: 13,
              fiber: 1, sodium: 230,
            ),
          ],
        ),
      ],
      'Food': const [
        MenuCategory(
          name: 'Item',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(
              name: 'Butter Croissant', calories: 280, protein: 5, carbs: 31, fat: 14,
              fiber: 1, sodium: 300,
            ),
            MenuItem(
              name: 'Chocolate Croissant', calories: 310, protein: 6, carbs: 35, fat: 16,
              fiber: 2, sodium: 300,
            ),
            MenuItem(
              name: 'Banana Bread Slice', calories: 420, protein: 6, carbs: 56, fat: 19,
              fiber: 2, sodium: 300,
            ),
            MenuItem(
              name: 'Blueberry Muffin', calories: 380, protein: 6, carbs: 53, fat: 16,
              fiber: 1, sodium: 330,
            ),
            MenuItem(
              name: 'Bacon Gouda Sandwich', calories: 360, protein: 19, carbs: 33, fat: 18,
              fiber: 1, sodium: 710,
            ),
            MenuItem(
              name: 'Spinach Feta Wrap', calories: 290, protein: 19, carbs: 33, fat: 10,
              fiber: 3, sodium: 840,
            ),
            MenuItem(
              name: 'Sausage & Cheddar Sandwich', calories: 470, protein: 19, carbs: 41, fat: 25,
              fiber: 1, sodium: 890,
            ),
            MenuItem(
              name: 'Turkey Bacon Egg White Sandwich', calories: 230, protein: 17, carbs: 28, fat: 5,
              fiber: 2, sodium: 600,
            ),
          ],
        ),
      ],
    },
  ),

  // 7. PANDA EXPRESS — pandaexpress.com nutrition; combos add side carbs.
  RestaurantMenu(
    id: 'panda',
    name: 'Panda Express',
    emoji: '🐼',
    accentColor: const Color(0xFFD52B1E),
    mealTypes: const ['Bowl', 'Plate', 'Bigger Plate', 'A La Carte'],
    builders: {
      'Bowl': const [
        _pandaSide,
        _pandaEntreesPick1,
      ],
      'Plate': const [
        _pandaSide,
        // Plate = 1 side + 2 entrees. maxSelections enforced by the builder UI.
        _pandaEntreesPick2,
      ],
      'Bigger Plate': const [
        _pandaSide,
        _pandaEntreesPick3,
      ],
      'A La Carte': const [
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(
              name: 'Cream Cheese Rangoon (3 pcs)', calories: 190, protein: 5, carbs: 24, fat: 8,
              fiber: 2, sodium: 180, vitaminCMg: 0.3, magnesiumMg: 17.5,
              folateMcg: 27.8,
            ),
            MenuItem(
              name: 'Chicken Egg Roll', calories: 200, protein: 6, carbs: 20, fat: 10,
              fiber: 2, sodium: 340, vitaminCMg: 4.3, magnesiumMg: 16.5,
              zincMg: 0.4, vitaminB12Mcg: 0, folateMcg: 45.9,
            ),
            MenuItem(
              name: 'Veggie Spring Roll (2 pcs)', calories: 240, protein: 4, carbs: 24, fat: 14,
              fiber: 2, sodium: 560, vitaminCMg: 5.6, magnesiumMg: 19.6,
              zincMg: 0.4, vitaminB12Mcg: 0, folateMcg: 59.6,
            ),
            MenuItem(
              name: 'Chicken Potsticker (3 pcs)', calories: 160, protein: 6, carbs: 20, fat: 6,
              fiber: 1, sodium: 250, vitaminCMg: 7.3, magnesiumMg: 18.3,
              zincMg: 1.5, vitaminB12Mcg: 0.2, folateMcg: 15.8,
            ),
          ],
        ),
      ],
    },
  ),

  // 8. FIVE GUYS — fiveguys.com; toppings are all free so just bundle them.
  RestaurantMenu(
    id: 'fiveguys',
    name: 'Five Guys',
    emoji: '🍔',
    accentColor: const Color(0xFFED174C),
    mealTypes: const ['Burger', 'Hot Dog', 'Sandwich', 'Sides'],
    builders: {
      'Burger': const [
        MenuCategory(
          name: 'Burger',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Hamburger', calories: 700, protein: 39, carbs: 39, fat: 43),
            MenuItem(name: 'Cheeseburger', calories: 840, protein: 47, carbs: 40, fat: 55),
            MenuItem(name: 'Bacon Burger', calories: 780, protein: 43, carbs: 39, fat: 50),
            MenuItem(name: 'Bacon Cheeseburger', calories: 920, protein: 51, carbs: 40, fat: 62),
            MenuItem(name: 'Little Hamburger', calories: 470, protein: 25, carbs: 39, fat: 26),
            MenuItem(name: 'Little Cheeseburger', calories: 550, protein: 30, carbs: 40, fat: 32),
            MenuItem(name: 'Little Bacon Cheeseburger', calories: 630, protein: 35, carbs: 40, fat: 39),
          ],
        ),
        MenuCategory(
          name: 'Toppings (all free)',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Mayo', calories: 100, protein: 0, carbs: 0, fat: 11),
            MenuItem(name: 'Lettuce', calories: 4, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Pickles', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Tomato', calories: 10, protein: 1, carbs: 2, fat: 0),
            MenuItem(name: 'Grilled Onions', calories: 45, protein: 0, carbs: 4, fat: 3),
            MenuItem(name: 'Grilled Mushrooms', calories: 50, protein: 1, carbs: 3, fat: 4),
            MenuItem(name: 'Ketchup', calories: 20, protein: 0, carbs: 5, fat: 0),
            MenuItem(name: 'Mustard', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Relish', calories: 15, protein: 0, carbs: 4, fat: 0),
            MenuItem(name: 'Onions (raw)', calories: 10, protein: 0, carbs: 2, fat: 0),
            MenuItem(name: 'Jalapeños', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'BBQ Sauce', calories: 60, protein: 0, carbs: 15, fat: 0),
            MenuItem(name: 'Hot Sauce', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'A1 Sauce', calories: 25, protein: 0, carbs: 6, fat: 0),
          ],
        ),
        MenuCategory(
          name: 'Fries',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Little Fries', calories: 530, protein: 8, carbs: 72, fat: 23),
            MenuItem(name: 'Regular Fries', calories: 950, protein: 15, carbs: 131, fat: 41),
            MenuItem(name: 'Large Fries', calories: 1310, protein: 21, carbs: 180, fat: 57),
            MenuItem(name: 'Little Cajun Fries', calories: 540, protein: 8, carbs: 73, fat: 23),
            MenuItem(name: 'Regular Cajun Fries', calories: 970, protein: 16, carbs: 134, fat: 42),
          ],
        ),
      ],
      'Hot Dog': const [
        MenuCategory(
          name: 'Hot Dog',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Hot Dog', calories: 580, protein: 22, carbs: 39, fat: 35),
            MenuItem(name: 'Cheese Dog', calories: 660, protein: 25, carbs: 40, fat: 41),
            MenuItem(name: 'Bacon Dog', calories: 730, protein: 28, carbs: 40, fat: 49),
            MenuItem(name: 'Bacon Cheese Dog', calories: 820, protein: 32, carbs: 40, fat: 56),
          ],
        ),
      ],
      'Sandwich': const [
        MenuCategory(
          name: 'Sandwich',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Grilled Cheese', calories: 470, protein: 17, carbs: 41, fat: 26),
            MenuItem(name: 'Veggie Sandwich', calories: 440, protein: 13, carbs: 42, fat: 25),
            MenuItem(name: 'BLT', calories: 430, protein: 14, carbs: 40, fat: 24),
          ],
        ),
      ],
      'Sides': const [
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Little Fries', calories: 530, protein: 8, carbs: 72, fat: 23),
            MenuItem(name: 'Regular Fries', calories: 950, protein: 15, carbs: 131, fat: 41),
            MenuItem(name: 'Large Fries', calories: 1310, protein: 21, carbs: 180, fat: 57),
          ],
        ),
      ],
    },
  ),

  // 9. SWEETGREEN — sweetgreen.com nutrition info; bases are large mixed.
  RestaurantMenu(
    id: 'sweetgreen',
    name: 'Sweetgreen',
    emoji: '🥗',
    accentColor: const Color(0xFF003E1F),
    mealTypes: const ['Custom Salad', 'Custom Warm Bowl', 'Signature'],
    builders: {
      'Custom Salad': const [
        MenuCategory(
          name: 'Base',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Mixed Greens', calories: 25, protein: 2, carbs: 5, fat: 0),
            MenuItem(name: 'Chopped Romaine', calories: 20, protein: 1, carbs: 3, fat: 0),
            MenuItem(name: 'Arugula', calories: 25, protein: 3, carbs: 5, fat: 0),
            MenuItem(name: 'Shredded Kale', calories: 60, protein: 4, carbs: 10, fat: 1),
            MenuItem(name: 'Spinach', calories: 25, protein: 3, carbs: 4, fat: 0),
            MenuItem(name: 'Warm Quinoa', calories: 220, protein: 8, carbs: 39, fat: 4),
            MenuItem(name: 'Warm Wild Rice', calories: 240, protein: 8, carbs: 52, fat: 1),
            MenuItem(name: 'Spicy Broccoli + Greens', calories: 100, protein: 7, carbs: 16, fat: 3),
          ],
        ),
        // Sweetgreen lets you stack proteins (Chicken + Steak, Salmon +
        // Tofu, etc.). Cap at 3 to match the in-store add-on limit.
        MenuCategory(
          name: 'Protein',
          mode: SelectionMode.multiple,
          optional: true,
          maxSelections: 3,
          allowDouble: true,
          items: [
            MenuItem(name: 'Roasted Chicken', calories: 220, protein: 36, carbs: 1, fat: 7),
            MenuItem(name: 'Blackened Chicken', calories: 240, protein: 36, carbs: 3, fat: 9),
            MenuItem(name: 'Crispy Chicken', calories: 310, protein: 28, carbs: 16, fat: 16),
            MenuItem(name: 'Roasted Salmon', calories: 270, protein: 33, carbs: 1, fat: 14),
            MenuItem(name: 'Steelhead', calories: 270, protein: 33, carbs: 1, fat: 14),
            MenuItem(name: 'Falafel', calories: 360, protein: 12, carbs: 38, fat: 19),
            MenuItem(name: 'Spicy Sunflower Tofu', calories: 200, protein: 14, carbs: 11, fat: 12),
            MenuItem(name: 'Shrimp', calories: 150, protein: 27, carbs: 1, fat: 4),
            MenuItem(name: 'Caramelized Garlic Steak', calories: 240, protein: 32, carbs: 3, fat: 11),
          ],
        ),
        MenuCategory(
          name: 'Toppings',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Avocado', calories: 100, protein: 1, carbs: 5, fat: 9),
            MenuItem(name: 'Roasted Sweet Potato', calories: 130, protein: 2, carbs: 28, fat: 2),
            MenuItem(name: 'Roasted Tomato', calories: 50, protein: 1, carbs: 5, fat: 3),
            MenuItem(name: 'Cucumber', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Carrots', calories: 25, protein: 1, carbs: 6, fat: 0),
            MenuItem(name: 'Tomatoes', calories: 10, protein: 0, carbs: 2, fat: 0),
            MenuItem(name: 'Quinoa', calories: 110, protein: 4, carbs: 20, fat: 2),
            MenuItem(name: 'Wild Rice', calories: 120, protein: 4, carbs: 26, fat: 0),
            MenuItem(name: 'Goat Cheese', calories: 90, protein: 5, carbs: 1, fat: 8),
            MenuItem(name: 'Shredded Cabbage', calories: 10, protein: 0, carbs: 2, fat: 0),
            MenuItem(name: 'Spicy Broccoli', calories: 80, protein: 4, carbs: 9, fat: 4),
            MenuItem(name: 'Roasted Almonds', calories: 110, protein: 4, carbs: 4, fat: 9),
            MenuItem(name: 'Hot Chickpeas', calories: 100, protein: 5, carbs: 14, fat: 3),
            MenuItem(name: 'Apples', calories: 50, protein: 0, carbs: 13, fat: 0),
          ],
        ),
        MenuCategory(
          name: 'Dressing',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Lime Cilantro Jalapeño', calories: 180, protein: 1, carbs: 2, fat: 19),
            MenuItem(name: 'Miso Sesame Ginger', calories: 220, protein: 1, carbs: 4, fat: 22),
            MenuItem(name: 'Spicy Cashew', calories: 230, protein: 3, carbs: 10, fat: 20),
            MenuItem(name: 'Caesar (Vegan)', calories: 210, protein: 1, carbs: 1, fat: 22),
            MenuItem(name: 'Balsamic Vinaigrette', calories: 170, protein: 0, carbs: 6, fat: 16),
            MenuItem(name: 'Olive Oil + Lemon', calories: 180, protein: 0, carbs: 1, fat: 20),
            MenuItem(name: 'Pesto Vinaigrette', calories: 200, protein: 1, carbs: 2, fat: 21),
          ],
        ),
      ],
      'Custom Warm Bowl': const [
        MenuCategory(
          name: 'Base',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Wild Rice', calories: 240, protein: 8, carbs: 52, fat: 1),
            MenuItem(name: 'Warm Quinoa', calories: 220, protein: 8, carbs: 39, fat: 4),
            MenuItem(name: 'Spicy Broccoli', calories: 160, protein: 8, carbs: 18, fat: 8),
            MenuItem(name: 'Sweetpotato + Wild Rice', calories: 310, protein: 8, carbs: 64, fat: 2),
          ],
        ),
        MenuCategory(
          name: 'Protein',
          mode: SelectionMode.multiple,
          maxSelections: 3,
          allowDouble: true,
          items: [
            MenuItem(name: 'Roasted Chicken', calories: 220, protein: 36, carbs: 1, fat: 7),
            MenuItem(name: 'Blackened Chicken', calories: 240, protein: 36, carbs: 3, fat: 9),
            MenuItem(name: 'Crispy Chicken', calories: 310, protein: 28, carbs: 16, fat: 16),
            MenuItem(name: 'Steelhead', calories: 270, protein: 33, carbs: 1, fat: 14),
            MenuItem(name: 'Caramelized Garlic Steak', calories: 240, protein: 32, carbs: 3, fat: 11),
            MenuItem(name: 'Falafel', calories: 360, protein: 12, carbs: 38, fat: 19),
            MenuItem(name: 'Spicy Sunflower Tofu', calories: 200, protein: 14, carbs: 11, fat: 12),
          ],
        ),
        MenuCategory(
          name: 'Toppings',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Avocado', calories: 100, protein: 1, carbs: 5, fat: 9),
            MenuItem(name: 'Roasted Sweet Potato', calories: 130, protein: 2, carbs: 28, fat: 2),
            MenuItem(name: 'Hot Chickpeas', calories: 100, protein: 5, carbs: 14, fat: 3),
            MenuItem(name: 'Spicy Broccoli', calories: 80, protein: 4, carbs: 9, fat: 4),
            MenuItem(name: 'Goat Cheese', calories: 90, protein: 5, carbs: 1, fat: 8),
          ],
        ),
        MenuCategory(
          name: 'Dressing',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Miso Sesame Ginger', calories: 220, protein: 1, carbs: 4, fat: 22),
            MenuItem(name: 'Spicy Cashew', calories: 230, protein: 3, carbs: 10, fat: 20),
            MenuItem(name: 'Lime Cilantro Jalapeño', calories: 180, protein: 1, carbs: 2, fat: 19),
          ],
        ),
      ],
      'Signature': const [
        MenuCategory(
          name: 'Bowl',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Harvest Bowl', calories: 705, protein: 40, carbs: 71, fat: 28),
            MenuItem(name: 'Kale Caesar', calories: 510, protein: 38, carbs: 22, fat: 30),
            MenuItem(name: 'Chicken Pesto Parm', calories: 680, protein: 49, carbs: 34, fat: 39),
            MenuItem(name: "Shroomami", calories: 650, protein: 28, carbs: 56, fat: 36),
            MenuItem(name: 'Crispy Rice Bowl', calories: 750, protein: 19, carbs: 86, fat: 36),
            MenuItem(name: 'Spicy Thai Salad', calories: 660, protein: 39, carbs: 47, fat: 36),
            MenuItem(name: 'Buffalo Chicken Bowl', calories: 720, protein: 47, carbs: 51, fat: 36),
            MenuItem(name: 'Hummus Crunch Bowl', calories: 690, protein: 17, carbs: 76, fat: 36),
          ],
        ),
      ],
    },
  ),

  // 10. CAVA — cava.com nutrition; bowls use the build-your-own framework.
  RestaurantMenu(
    id: 'cava',
    name: 'CAVA',
    emoji: '🫒',
    accentColor: const Color(0xFFD96D2E),
    mealTypes: const ['Bowl', 'Pita', 'Salad'],
    builders: {
      'Bowl': const [
        MenuCategory(
          name: 'Base',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Saffron Rice', calories: 280, protein: 5, carbs: 51, fat: 6),
            MenuItem(name: 'Brown Rice', calories: 220, protein: 5, carbs: 46, fat: 2),
            MenuItem(name: 'SuperGreens', calories: 25, protein: 3, carbs: 4, fat: 0),
            MenuItem(name: 'RightRice', calories: 280, protein: 14, carbs: 36, fat: 8),
            MenuItem(name: 'Lentils', calories: 230, protein: 16, carbs: 36, fat: 4),
            MenuItem(name: 'Splendid Greens & Grains', calories: 200, protein: 9, carbs: 32, fat: 4),
          ],
        ),
        // CAVA lets guests stack up to three proteins on one bowl (the
        // "Mediterranean Trio" — Grilled Chicken + Falafel + Meatballs is
        // a popular combo). Multi-select with maxSelections: 3 enforces
        // the in-store cap; the running "(N of 3 max)" hint drives the UX.
        MenuCategory(
          name: 'Protein',
          mode: SelectionMode.multiple,
          maxSelections: 3,
          allowDouble: true,
          items: [
            MenuItem(name: 'Grilled Chicken', calories: 250, protein: 36, carbs: 1, fat: 11),
            MenuItem(name: 'Spicy Lamb Meatballs', calories: 350, protein: 22, carbs: 5, fat: 26),
            MenuItem(name: 'Braised Lamb', calories: 290, protein: 25, carbs: 4, fat: 18),
            MenuItem(name: 'Harissa Honey Chicken', calories: 310, protein: 35, carbs: 17, fat: 11),
            MenuItem(name: 'Falafel (4 pcs)', calories: 240, protein: 11, carbs: 25, fat: 11),
            MenuItem(name: 'Roasted Vegetables', calories: 110, protein: 3, carbs: 16, fat: 4),
            MenuItem(name: 'Grilled Steak', calories: 240, protein: 33, carbs: 1, fat: 12),
          ],
        ),
        MenuCategory(
          name: 'Dips & Spreads',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Hummus (Traditional)', calories: 110, protein: 4, carbs: 9, fat: 6),
            MenuItem(name: 'Roasted Red Pepper Hummus', calories: 120, protein: 4, carbs: 10, fat: 7),
            MenuItem(name: 'Crazy Feta', calories: 90, protein: 4, carbs: 2, fat: 8),
            MenuItem(name: 'Tzatziki', calories: 60, protein: 3, carbs: 3, fat: 4),
            MenuItem(name: 'Harissa', calories: 70, protein: 1, carbs: 4, fat: 7),
            MenuItem(name: 'Eggplant + Red Pepper Dip', calories: 90, protein: 1, carbs: 6, fat: 7),
          ],
        ),
        MenuCategory(
          name: 'Toppings',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Cabbage Slaw', calories: 15, protein: 0, carbs: 3, fat: 0),
            MenuItem(name: 'Tomato + Cucumber', calories: 10, protein: 0, carbs: 2, fat: 0),
            MenuItem(name: 'Pickled Onions', calories: 30, protein: 1, carbs: 7, fat: 0),
            MenuItem(name: 'Kalamata Olives', calories: 70, protein: 0, carbs: 2, fat: 7),
            MenuItem(name: 'Pickled Banana Peppers', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Crumbled Feta', calories: 80, protein: 5, carbs: 1, fat: 6),
            MenuItem(name: 'Pita Crisps', calories: 100, protein: 3, carbs: 14, fat: 4),
            MenuItem(name: 'Diced Cucumber', calories: 5, protein: 0, carbs: 1, fat: 0),
          ],
        ),
        MenuCategory(
          name: 'Dressing',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Yogurt Dill', calories: 60, protein: 2, carbs: 4, fat: 4),
            MenuItem(name: 'Greek Vinaigrette', calories: 180, protein: 0, carbs: 2, fat: 19),
            MenuItem(name: 'Lemon Herb Tahini', calories: 130, protein: 3, carbs: 6, fat: 11),
            MenuItem(name: 'Skhug', calories: 60, protein: 1, carbs: 3, fat: 5),
            MenuItem(name: 'Tahini Caesar', calories: 160, protein: 2, carbs: 5, fat: 15),
          ],
        ),
      ],
      'Pita': const [
        MenuCategory(
          name: 'Pita',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'White Pita', calories: 250, protein: 9, carbs: 47, fat: 3),
            MenuItem(name: 'Whole Wheat Pita', calories: 270, protein: 12, carbs: 48, fat: 4),
          ],
        ),
        MenuCategory(
          name: 'Protein',
          mode: SelectionMode.multiple,
          maxSelections: 3,
          allowDouble: true,
          items: [
            MenuItem(name: 'Grilled Chicken', calories: 250, protein: 36, carbs: 1, fat: 11),
            MenuItem(name: 'Falafel (4 pcs)', calories: 240, protein: 11, carbs: 25, fat: 11),
            MenuItem(name: 'Spicy Lamb Meatballs', calories: 350, protein: 22, carbs: 5, fat: 26),
            MenuItem(name: 'Harissa Honey Chicken', calories: 310, protein: 35, carbs: 17, fat: 11),
          ],
        ),
        MenuCategory(
          name: 'Toppings',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Hummus', calories: 110, protein: 4, carbs: 9, fat: 6),
            MenuItem(name: 'Tzatziki', calories: 60, protein: 3, carbs: 3, fat: 4),
            MenuItem(name: 'Pickled Onions', calories: 30, protein: 1, carbs: 7, fat: 0),
            MenuItem(name: 'Tomato + Cucumber', calories: 10, protein: 0, carbs: 2, fat: 0),
            MenuItem(name: 'Crumbled Feta', calories: 80, protein: 5, carbs: 1, fat: 6),
          ],
        ),
      ],
      'Salad': const [
        MenuCategory(
          name: 'Base',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'SuperGreens', calories: 25, protein: 3, carbs: 4, fat: 0),
            MenuItem(name: 'Splendid Greens & Grains', calories: 200, protein: 9, carbs: 32, fat: 4),
          ],
        ),
        MenuCategory(
          name: 'Protein',
          mode: SelectionMode.multiple,
          maxSelections: 3,
          allowDouble: true,
          items: [
            MenuItem(name: 'Grilled Chicken', calories: 250, protein: 36, carbs: 1, fat: 11),
            MenuItem(name: 'Harissa Honey Chicken', calories: 310, protein: 35, carbs: 17, fat: 11),
            MenuItem(name: 'Falafel (4 pcs)', calories: 240, protein: 11, carbs: 25, fat: 11),
          ],
        ),
        MenuCategory(
          name: 'Toppings',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Hummus', calories: 110, protein: 4, carbs: 9, fat: 6),
            MenuItem(name: 'Pickled Onions', calories: 30, protein: 1, carbs: 7, fat: 0),
            MenuItem(name: 'Kalamata Olives', calories: 70, protein: 0, carbs: 2, fat: 7),
            MenuItem(name: 'Pita Crisps', calories: 100, protein: 3, carbs: 14, fat: 4),
            MenuItem(name: 'Crumbled Feta', calories: 80, protein: 5, carbs: 1, fat: 6),
          ],
        ),
        MenuCategory(
          name: 'Dressing',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Lemon Herb Tahini', calories: 130, protein: 3, carbs: 6, fat: 11),
            MenuItem(name: 'Greek Vinaigrette', calories: 180, protein: 0, carbs: 2, fat: 19),
            MenuItem(name: 'Tahini Caesar', calories: 160, protein: 2, carbs: 5, fat: 15),
          ],
        ),
      ],
    },
  ),

  // 11. BURGER KING — bk.com nutrition explorer.
  RestaurantMenu(
    id: 'burgerking',
    name: 'Burger King',
    emoji: '🍔',
    accentColor: const Color(0xFFDA291C),
    mealTypes: const ['Burgers', 'Chicken & Fish', 'Nuggets', 'Sides', 'Breakfast', 'Drinks'],
    builders: {
      'Burgers': const [
        MenuCategory(
          name: 'Burger',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Whopper', calories: 710, protein: 34, carbs: 57, fat: 42,
              fiber: 4, sodium: 1250, vitaminCMg: 0.6, magnesiumMg: 54.8,
              zincMg: 8.6, folateMcg: 143.2,
            ),
            MenuItem(
              name: 'Whopper Jr', calories: 340, protein: 15, carbs: 30, fat: 19,
              fiber: 2, sodium: 630, vitaminCMg: 0.3, magnesiumMg: 26.3,
              zincMg: 4.1, folateMcg: 68.6,
            ),
            MenuItem(
              name: 'Double Whopper', calories: 980, protein: 56, carbs: 57, fat: 62,
              fiber: 5, sodium: 1320, vitaminCMg: 0.8, magnesiumMg: 70,
              zincMg: 11.7, folateMcg: 175,
            ),
            MenuItem(
              name: 'Bacon King', calories: 1260, protein: 69, carbs: 58, fat: 84,
              fiber: 4, sodium: 2330,
            ),
            MenuItem(
              name: 'Hamburger', calories: 260, protein: 14, carbs: 29, fat: 10,
              fiber: 2, sodium: 600, vitaminCMg: 0.2, magnesiumMg: 24.9,
              zincMg: 2.4, folateMcg: 63.8,
            ),
            MenuItem(
              name: 'Cheeseburger', calories: 300, protein: 16, carbs: 30, fat: 14,
              fiber: 2, sodium: 810, vitaminCMg: 0.2, magnesiumMg: 25.2,
              zincMg: 2.5,
            ),
          ],
        ),
        MenuCategory(
          name: 'Add-ons',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(
              name: 'Extra Cheese (slice)', calories: 42.2, protein: 1.9, carbs: 0.8, fat: 3.5,
              fiber: 0.1, sodium: 214.7, vitaminCMg: 0, magnesiumMg: 3,
              zincMg: 0.3, vitaminB12Mcg: 0.2, folateMcg: 0.9,
            ),
            MenuItem(
              name: 'Extra Bacon (2 strips)', calories: 63.2, protein: 4.5, carbs: 0.2, fat: 5,
              fiber: 0, sodium: 249.6, vitaminCMg: 0, magnesiumMg: 4.2,
              zincMg: 0.4, vitaminB12Mcg: 0.1, folateMcg: 0,
            ),
            MenuItem(
              name: 'Extra Patty', calories: 270, protein: 22, carbs: 0.4, fat: 20,
              fiber: 0.2, sodium: 70, vitaminCMg: 0, magnesiumMg: 20,
              zincMg: 6.3, vitaminB12Mcg: 2.7, folateMcg: 10,
            ),
          ],
        ),
        MenuCategory(
          name: 'Toppings',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(
              name: 'Lettuce', calories: 3, protein: 0.2, carbs: 0.6, fat: 0,
              fiber: 0.3, sodium: 2.5, vitaminCMg: 0.6, magnesiumMg: 1.5,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 6.2,
            ),
            MenuItem(
              name: 'Tomato', calories: 4, protein: 0.2, carbs: 1, fat: 0,
              fiber: 0.3, sodium: 1.3, vitaminCMg: 3, magnesiumMg: 2.4,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 3.3,
            ),
            MenuItem(
              name: 'Onion', calories: 3, protein: 0.1, carbs: 1, fat: 0,
              fiber: 0.3, sodium: 0.3, vitaminCMg: 0.6, magnesiumMg: 0.8,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 1.4,
            ),
            MenuItem(
              name: 'Pickles', calories: 1.1, protein: 0.1, carbs: 0.2, fat: 0,
              fiber: 0.1, sodium: 320, vitaminCMg: 0.2, magnesiumMg: 0.7,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0.7,
            ),
            MenuItem(
              name: 'Ketchup', calories: 9.6, protein: 0.1, carbs: 2.2, fat: 0,
              fiber: 0.1, sodium: 88.6, vitaminCMg: 0.4, magnesiumMg: 1.2,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0.9,
            ),
            MenuItem(
              name: 'Mustard', calories: 5, protein: 0.3, carbs: 0.3, fat: 0.3,
              fiber: 0.2, sodium: 65.8, vitaminCMg: 0, magnesiumMg: 4,
              zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 0.6,
            ),
            MenuItem(
              name: 'Mayo', calories: 87, protein: 0.1, carbs: 0.3, fat: 9.5,
              fiber: 0, sodium: 66.1, vitaminCMg: 0, magnesiumMg: 0.1,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0.6,
            ),
          ],
        ),
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(
              name: 'Small Fries', calories: 300, protein: 4, carbs: 40, fat: 13,
              fiber: 3, sodium: 270, vitaminCMg: 2.4, magnesiumMg: 28.9,
              zincMg: 0.5,
            ),
            MenuItem(
              name: 'Medium Fries', calories: 370, protein: 5, carbs: 50, fat: 17,
              fiber: 4, sodium: 330, vitaminCMg: 2.9, magnesiumMg: 35.7,
              zincMg: 0.6,
            ),
            MenuItem(
              name: 'Large Fries', calories: 440, protein: 6, carbs: 60, fat: 20,
              fiber: 5, sodium: 400, vitaminCMg: 3.5, magnesiumMg: 42.4,
              zincMg: 0.7,
            ),
            MenuItem(
              name: 'Onion Rings (S)', calories: 230, protein: 3, carbs: 31, fat: 11,
              fiber: 3, sodium: 410, vitaminCMg: 0.8, magnesiumMg: 10.5,
              zincMg: 0.3,
            ),
            MenuItem(
              name: 'Onion Rings (M)', calories: 290, protein: 4, carbs: 39, fat: 13,
              fiber: 4, sodium: 530, vitaminCMg: 1, magnesiumMg: 13.2,
              zincMg: 0.4,
            ),
            MenuItem(
              name: 'Mozzarella Sticks (4)', calories: 220, protein: 10, carbs: 24, fat: 12,
              fiber: 1, sodium: 790, vitaminCMg: 0, magnesiumMg: 14.2,
              zincMg: 1.4, vitaminB12Mcg: 0.6, folateMcg: 17.6,
            ),
            MenuItem(name: 'Side Salad', calories: 60, protein: 4, carbs: 7, fat: 2),
          ],
        ),
      ],
      'Chicken & Fish': const [
        MenuCategory(
          name: 'Entree',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Original Chicken Sandwich', calories: 680, protein: 23, carbs: 63, fat: 39,
              fiber: 3, sodium: 1380, vitaminCMg: 0.5, magnesiumMg: 54.7,
              zincMg: 1.5, folateMcg: 78.5,
            ),
            MenuItem(name: "Ch'King", calories: 880, protein: 36, carbs: 62, fat: 51),
            MenuItem(name: "Spicy Ch'King", calories: 880, protein: 36, carbs: 62, fat: 51),
            MenuItem(
              name: 'Chicken Fries (9 pc)', calories: 220, protein: 13, carbs: 16, fat: 12,
              fiber: 1, sodium: 680, vitaminCMg: 0.8, magnesiumMg: 20.3,
              zincMg: 0.5, vitaminB12Mcg: 0.1, folateMcg: 6.8,
            ),
            MenuItem(
              name: 'Big Fish Sandwich', calories: 570, protein: 19, carbs: 58, fat: 30,
              fiber: 3, sodium: 1270, vitaminCMg: 0.4, magnesiumMg: 54.8,
              zincMg: 1.1,
            ),
          ],
        ),
        MenuCategory(
          name: 'Sauce',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(
              name: 'BBQ', calories: 35, protein: 0, carbs: 8, fat: 0,
              fiber: 0, sodium: 220, vitaminCMg: 0.1, magnesiumMg: 2.6,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0.4,
            ),
            MenuItem(
              name: 'Ranch', calories: 110, protein: 0, carbs: 1, fat: 11,
              fiber: 0, sodium: 220, vitaminCMg: 0, magnesiumMg: 1.3,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 1,
            ),
            MenuItem(
              name: 'Buffalo', calories: 70, protein: 0, carbs: 2, fat: 7,
              fiber: 0, sodium: 330,
            ),
            MenuItem(
              name: 'Honey Mustard', calories: 70, protein: 0, carbs: 6, fat: 4.5,
              fiber: 0, sodium: 135, vitaminCMg: 0, magnesiumMg: 0.8,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0.8,
            ),
            MenuItem(
              name: 'Sweet & Sour', calories: 45, protein: 0, carbs: 11, fat: 0,
              fiber: 0, sodium: 50, vitaminCMg: 2.5, magnesiumMg: 2.3,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 2.3,
            ),
            MenuItem(
              name: 'Zesty Sauce', calories: 140, protein: 0, carbs: 3, fat: 14,
              fiber: 0, sodium: 210,
            ),
          ],
        ),
      ],
      'Nuggets': const [
        MenuCategory(
          name: 'Nuggets',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Nuggets (4 pc)', calories: 220, protein: 9, carbs: 12, fat: 15,
              fiber: 1, sodium: 400, vitaminCMg: 0.4, magnesiumMg: 17.2,
              zincMg: 0.4, vitaminB12Mcg: 0.2, folateMcg: 7.9,
            ),
            MenuItem(
              name: 'Nuggets (8 pc)', calories: 440, protein: 18, carbs: 23, fat: 30,
              fiber: 2, sodium: 790, vitaminCMg: 0.9, magnesiumMg: 34.4,
              zincMg: 0.8, vitaminB12Mcg: 0.5, folateMcg: 15.8,
            ),
            MenuItem(name: 'Nuggets (10 pc)', calories: 420, protein: 22, carbs: 27, fat: 27),
          ],
        ),
        MenuCategory(
          name: 'Sauce',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(
              name: 'BBQ', calories: 35, protein: 0, carbs: 8, fat: 0,
              fiber: 0, sodium: 220, vitaminCMg: 0.1, magnesiumMg: 2.6,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0.4,
            ),
            MenuItem(
              name: 'Ranch', calories: 110, protein: 0, carbs: 1, fat: 11,
              fiber: 0, sodium: 220, vitaminCMg: 0, magnesiumMg: 1.3,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 1,
            ),
            MenuItem(
              name: 'Buffalo', calories: 70, protein: 0, carbs: 2, fat: 7,
              fiber: 0, sodium: 330,
            ),
            MenuItem(
              name: 'Honey Mustard', calories: 70, protein: 0, carbs: 6, fat: 4.5,
              fiber: 0, sodium: 135, vitaminCMg: 0, magnesiumMg: 0.8,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0.8,
            ),
            MenuItem(
              name: 'Sweet & Sour', calories: 45, protein: 0, carbs: 11, fat: 0,
              fiber: 0, sodium: 50, vitaminCMg: 2.5, magnesiumMg: 2.3,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 2.3,
            ),
          ],
        ),
      ],
      'Sides': const [
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(
              name: 'Small Fries', calories: 300, protein: 4, carbs: 40, fat: 13,
              fiber: 3, sodium: 270, vitaminCMg: 2.4, magnesiumMg: 28.9,
              zincMg: 0.5,
            ),
            MenuItem(
              name: 'Medium Fries', calories: 370, protein: 5, carbs: 50, fat: 17,
              fiber: 4, sodium: 330, vitaminCMg: 2.9, magnesiumMg: 35.7,
              zincMg: 0.6,
            ),
            MenuItem(
              name: 'Large Fries', calories: 440, protein: 6, carbs: 60, fat: 20,
              fiber: 5, sodium: 400, vitaminCMg: 3.5, magnesiumMg: 42.4,
              zincMg: 0.7,
            ),
            MenuItem(
              name: 'Onion Rings (S)', calories: 230, protein: 3, carbs: 31, fat: 11,
              fiber: 3, sodium: 410, vitaminCMg: 0.8, magnesiumMg: 10.5,
              zincMg: 0.3,
            ),
            MenuItem(
              name: 'Onion Rings (M)', calories: 290, protein: 4, carbs: 39, fat: 13,
              fiber: 4, sodium: 530, vitaminCMg: 1, magnesiumMg: 13.2,
              zincMg: 0.4,
            ),
            MenuItem(
              name: 'Onion Rings (L)', calories: 430, protein: 5, carbs: 57, fat: 20,
              fiber: 6, sodium: 770, vitaminCMg: 1.4, magnesiumMg: 19.6,
              zincMg: 0.5,
            ),
            MenuItem(
              name: 'Mozzarella Sticks (4)', calories: 220, protein: 10, carbs: 24, fat: 12,
              fiber: 1, sodium: 790, vitaminCMg: 0, magnesiumMg: 14.2,
              zincMg: 1.4, vitaminB12Mcg: 0.6, folateMcg: 17.6,
            ),
            MenuItem(name: 'Side Salad', calories: 60, protein: 4, carbs: 7, fat: 2),
          ],
        ),
      ],
      'Breakfast': const [
        MenuCategory(
          name: 'Entree',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: "Croissan'wich (Sausage, Egg, Cheese)", calories: 500, protein: 19, carbs: 28, fat: 34,
              fiber: 3, sodium: 1040, vitaminCMg: 0, magnesiumMg: 27.6,
              zincMg: 1.9, vitaminB12Mcg: 0.8, folateMcg: 81.2,
            ),
            MenuItem(
              name: "Croissan'wich (Bacon, Egg, Cheese)", calories: 360, protein: 15, carbs: 28, fat: 21,
              fiber: 3, sodium: 810, vitaminCMg: 0.1, magnesiumMg: 21.2,
              zincMg: 1.6, vitaminB12Mcg: 0.8, folateMcg: 63.5,
            ),
            MenuItem(
              name: "Croissan'wich (Ham, Egg, Cheese)", calories: 350, protein: 18, carbs: 29, fat: 19,
              fiber: 3, sodium: 1000, vitaminCMg: 0.1, magnesiumMg: 22.8,
              zincMg: 1.9, vitaminB12Mcg: 0.9, folateMcg: 56.3,
            ),
            MenuItem(
              name: 'Pancakes (3 pc + syrup)', calories: 400, protein: 5, carbs: 74, fat: 9,
              fiber: 1, sodium: 690,
            ),
            MenuItem(
              name: 'French Toast Sticks (5 pc)', calories: 410, protein: 6, carbs: 47, fat: 21,
              fiber: 2, sodium: 315, vitaminCMg: 0, magnesiumMg: 22.3,
              zincMg: 0.6, vitaminB12Mcg: 0,
            ),
            MenuItem(
              name: 'Hash Browns (Small)', calories: 270, protein: 2, carbs: 29, fat: 16,
              fiber: 3, sodium: 570, vitaminCMg: 3.8, magnesiumMg: 17.9,
              zincMg: 0.3, folateMcg: 11.6,
            ),
          ],
        ),
      ],
      'Drinks': const [
        MenuCategory(
          name: 'Drink',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Small Coke', calories: 180, protein: 0, carbs: 50, fat: 0,
              fiber: 0, sodium: 45, vitaminCMg: 0, magnesiumMg: 0,
              zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 0,
            ),
            MenuItem(
              name: 'Medium Coke', calories: 270, protein: 0, carbs: 70, fat: 0,
              fiber: 0, sodium: 65, vitaminCMg: 0, magnesiumMg: 0,
              zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 0,
            ),
            MenuItem(
              name: 'Large Coke', calories: 320, protein: 0, carbs: 88, fat: 0,
              fiber: 0, sodium: 80, vitaminCMg: 0, magnesiumMg: 0,
              zincMg: 0.2, vitaminB12Mcg: 0, folateMcg: 0,
            ),
            MenuItem(
              name: 'Diet Coke', calories: 0, protein: 0, carbs: 0, fat: 0,
              fiber: 0, sodium: 70, vitaminCMg: 0, magnesiumMg: 8.6,
              zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 0,
            ),
            MenuItem(
              name: 'Sprite (M)', calories: 260, protein: 0, carbs: 68, fat: 0,
              fiber: 0, sodium: 70, vitaminCMg: 0, magnesiumMg: 6.3,
              zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 0,
            ),
            MenuItem(
              name: 'Iced Tea (Unsweet)', calories: 0, protein: 0, carbs: 0, fat: 0,
              fiber: 0, sodium: 0, vitaminCMg: 0, magnesiumMg: 25.7,
              zincMg: 0.2, vitaminB12Mcg: 0, folateMcg: 42.9,
            ),
            MenuItem(
              name: 'Water', calories: 0, protein: 0, carbs: 0, fat: 0,
              fiber: 0, sodium: 0,
            ),
            MenuItem(
              name: 'Coffee (S)', calories: 0, protein: 0, carbs: 0, fat: 0,
              fiber: 0, sodium: 0, vitaminCMg: 0, magnesiumMg: 10.8,
              zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 7.2,
            ),
            MenuItem(
              name: 'Chocolate Shake (M)', calories: 590, protein: 13, carbs: 103, fat: 14,
              fiber: 1, sodium: 420, vitaminCMg: 0, magnesiumMg: 90.5,
              zincMg: 2.8, vitaminB12Mcg: 0.9, folateMcg: 3.9,
            ),
            MenuItem(
              name: 'Vanilla Shake (M)', calories: 560, protein: 12, carbs: 96, fat: 14,
              fiber: 0, sodium: 400, vitaminCMg: 0, magnesiumMg: 40,
              zincMg: 2.2, vitaminB12Mcg: 1.2,
            ),
          ],
        ),
      ],
    },
  ),

  // 12. DUNKIN' — dunkindonuts.com nutrition guide (medium-size drinks).
  RestaurantMenu(
    id: 'dunkin',
    name: "Dunkin'",
    emoji: '🍩',
    accentColor: const Color(0xFFF37121),
    mealTypes: const ['Hot Coffee', 'Iced Coffee', 'Espresso', 'Donuts', 'Bagels', 'Sandwiches', 'Wraps', 'Munchkins'],
    builders: {
      'Hot Coffee': const [
        MenuCategory(
          name: 'Drink (Medium / 14oz)',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Original Blend Coffee', calories: 5, protein: 1,
              carbs: 0, fat: 0,
              fiber: 0, sodium: 10, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 8, vitaminCMg: 0, magnesiumMg: 12.7,
              potassiumMg: 207, zincMg: 0.1, vitaminB12Mcg: 0,
              folateMcg: 8.4,
            ),
            MenuItem(
              name: 'Decaf Coffee', calories: 5, protein: 0, carbs: 1,
              fat: 0,
              vitaminCMg: 0, magnesiumMg: 20.7, zincMg: 0.1,
              vitaminB12Mcg: 0, folateMcg: 0,
            ),
            MenuItem(
              name: 'Hot Latte (whole milk)', calories: 170, protein: 9,
              carbs: 14, fat: 9,
              fiber: 0, sodium: 125, vitaminDMcg: 4, ironMg: 0,
              calciumMg: 311, vitaminCMg: 0.1, magnesiumMg: 76.5,
              potassiumMg: 427, zincMg: 1, vitaminB12Mcg: 1.2,
              folateMcg: 14.1,
            ),
            MenuItem(
              name: 'Hot Cappuccino', calories: 120, protein: 6,
              carbs: 10, fat: 6,
              fiber: 0, sodium: 85, vitaminDMcg: 2, ironMg: 0,
              calciumMg: 208, vitaminCMg: 0.1, magnesiumMg: 57.8,
              potassiumMg: 306, zincMg: 0.7, vitaminB12Mcg: 0.9,
              folateMcg: 10,
            ),
            MenuItem(
              name: 'Hot Macchiato', calories: 120, protein: 6,
              carbs: 10, fat: 6,
              fiber: 0, sodium: 90, vitaminDMcg: 2, ironMg: 0,
              calciumMg: 209, vitaminCMg: 0.2, magnesiumMg: 95.6,
              potassiumMg: 352, zincMg: 0.7, vitaminB12Mcg: 0.8,
              folateMcg: 10.1,
            ),
            MenuItem(
              name: 'Hot Americano', calories: 10, protein: 0, carbs: 2,
              fat: 0,
              fiber: 0, sodium: 25, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 12, vitaminCMg: 0.2, magnesiumMg: 82.1,
              potassiumMg: 118, zincMg: 0.1, vitaminB12Mcg: 0,
              folateMcg: 1,
            ),
            MenuItem(
              name: 'Mocha Latte', calories: 330, protein: 10,
              carbs: 52, fat: 10,
              fiber: 2, sodium: 150, vitaminDMcg: 4, ironMg: 1,
              calciumMg: 319, potassiumMg: 690,
            ),
            MenuItem(
              name: 'Caramel Latte', calories: 340, protein: 11,
              carbs: 53, fat: 9,
              fiber: 0, sodium: 180, vitaminDMcg: 4, ironMg: 0,
              calciumMg: 389, potassiumMg: 687,
            ),
            MenuItem(
              name: 'Hot Chocolate', calories: 330, protein: 3,
              carbs: 59, fat: 10,
              fiber: 2, sodium: 320, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 50, potassiumMg: 220,
            ),
          ],
        ),
        // Add-milk options model the milk/cream ADDED to a black coffee (the
        // default drinks above — Original Blend, Decaf, Americano — are black).
        // Previously this was a "Milk Swap" with Whole Milk = +0 cal and
        // negative deltas, which under-counted every coffee with milk. Values
        // are Dunkin' medium (14 oz hot) milk/cream additions. Pick "Black /
        // No Milk" for drinks already made with milk (lattes/cappuccinos) so
        // the milk isn't double-counted.
        MenuCategory(
          name: 'Add Milk / Cream',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Black / No Milk', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(
              name: 'Whole Milk', calories: 70, protein: 4, carbs: 5,
              fat: 4,
              vitaminCMg: 0, magnesiumMg: 11.5, zincMg: 0.4,
              vitaminB12Mcg: 0.5, folateMcg: 5.7,
            ),
            MenuItem(
              name: 'Skim Milk', calories: 45, protein: 4, carbs: 7,
              fat: 0,
              vitaminCMg: 0, magnesiumMg: 14.6, zincMg: 0.6,
              vitaminB12Mcg: 0.7, folateMcg: 6.6,
            ),
            MenuItem(name: 'Oat Milk', calories: 65, protein: 1, carbs: 11, fat: 2),
            MenuItem(name: 'Almond Milk', calories: 25, protein: 1, carbs: 1, fat: 2),
            MenuItem(name: 'Coconut Milk', calories: 25, protein: 0, carbs: 2, fat: 2),
            MenuItem(
              name: 'Cream', calories: 110, protein: 2, carbs: 3,
              fat: 10,
              vitaminCMg: 0.5, magnesiumMg: 5.1, zincMg: 0.2,
              vitaminB12Mcg: 0.1, folateMcg: 1.1,
            ),
          ],
        ),
        MenuCategory(
          name: 'Sweetener',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Sugar (1 pkt)', calories: 20, protein: 0, carbs: 5, fat: 0),
            MenuItem(name: 'Liquid Sugar (1 pump)', calories: 25, protein: 0, carbs: 6, fat: 0),
            MenuItem(name: 'Splenda', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Equal', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
        MenuCategory(
          name: 'Flavor Shots & Swirls',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Caramel Shot', calories: 10, protein: 0, carbs: 3, fat: 0),
            MenuItem(name: 'Mocha Shot', calories: 10, protein: 0, carbs: 3, fat: 0),
            MenuItem(name: 'Vanilla Shot', calories: 10, protein: 0, carbs: 3, fat: 0),
            MenuItem(name: 'Hazelnut Shot', calories: 10, protein: 0, carbs: 3, fat: 0),
            MenuItem(name: 'French Vanilla Shot', calories: 10, protein: 0, carbs: 3, fat: 0),
            MenuItem(name: 'Caramel Swirl', calories: 60, protein: 0, carbs: 14, fat: 0),
            MenuItem(name: 'Mocha Swirl', calories: 60, protein: 0, carbs: 12, fat: 1),
            MenuItem(name: 'Vanilla Swirl', calories: 60, protein: 0, carbs: 14, fat: 0),
            MenuItem(name: 'Hazelnut Swirl', calories: 60, protein: 0, carbs: 14, fat: 0),
          ],
        ),
      ],
      'Iced Coffee': const [
        MenuCategory(
          name: 'Drink (Medium / 24oz)',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Iced Coffee (black)', calories: 5, protein: 0,
              carbs: 0, fat: 0,
              fiber: 0, sodium: 15, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 15, vitaminCMg: 0, magnesiumMg: 12.6,
              potassiumMg: 206, zincMg: 0.1, vitaminB12Mcg: 0,
              folateMcg: 8.4,
            ),
            MenuItem(
              name: 'Iced Latte', calories: 170, protein: 9, carbs: 14,
              fat: 9,
              fiber: 0, sodium: 135, vitaminDMcg: 4, ironMg: 0,
              calciumMg: 322, vitaminCMg: 0.1, magnesiumMg: 78.9,
              potassiumMg: 430, zincMg: 1, vitaminB12Mcg: 1.2,
              folateMcg: 14.1,
            ),
            MenuItem(
              name: 'Iced Cappuccino', calories: 120, protein: 6,
              carbs: 10, fat: 6,
              fiber: 0, sodium: 100, vitaminDMcg: 2, ironMg: 0,
              calciumMg: 219, vitaminCMg: 0.1, magnesiumMg: 61,
              potassiumMg: 310, zincMg: 0.7, vitaminB12Mcg: 0.9,
              folateMcg: 10,
            ),
            MenuItem(
              name: 'Iced Macchiato', calories: 120, protein: 6,
              carbs: 10, fat: 6,
              fiber: 0, sodium: 105, vitaminDMcg: 2, ironMg: 0,
              calciumMg: 220, vitaminCMg: 0.2, magnesiumMg: 98.9,
              potassiumMg: 356, zincMg: 0.7, vitaminB12Mcg: 0.8,
              folateMcg: 10.1,
            ),
            MenuItem(
              name: 'Iced Americano', calories: 10, protein: 0,
              carbs: 2, fat: 0,
              fiber: 0, sodium: 30, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 18, vitaminCMg: 0.2, magnesiumMg: 80.7,
              potassiumMg: 116, zincMg: 0.1, vitaminB12Mcg: 0,
              folateMcg: 1,
            ),
            MenuItem(
              name: 'Iced Mocha Latte', calories: 330, protein: 10,
              carbs: 52, fat: 10,
              fiber: 2, sodium: 160, vitaminDMcg: 4, ironMg: 1,
              calciumMg: 330, potassiumMg: 694,
            ),
            MenuItem(
              name: 'Iced Caramel Latte', calories: 340, protein: 11,
              carbs: 53, fat: 9,
              fiber: 0, sodium: 190, vitaminDMcg: 4, ironMg: 0,
              calciumMg: 400, potassiumMg: 690,
            ),
            MenuItem(
              name: 'Cold Brew', calories: 5, protein: 0, carbs: 0,
              fat: 0,
              fiber: 0, sodium: 15, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 15, vitaminCMg: 0, magnesiumMg: 12.6,
              potassiumMg: 206, zincMg: 0.1, vitaminB12Mcg: 0,
              folateMcg: 8.4,
            ),
            MenuItem(
              name: 'Refresher (Strawberry Dragonfruit)', calories: 130,
              protein: 1, carbs: 29, fat: 0,
              fiber: 0, sodium: 15, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 10, potassiumMg: 24,
            ),
            MenuItem(
              name: 'Iced Chai Latte', calories: 290, protein: 9,
              carbs: 43, fat: 9,
              fiber: 2, sodium: 160, vitaminDMcg: 4, ironMg: 0,
              calciumMg: 323, potassiumMg: 425,
            ),
          ],
        ),
        // Same add-milk model as Hot Coffee. Dunkin' medium iced is 24 oz; the
        // milk/cream values track the published medium additions. Pick "Black /
        // No Milk" for pre-milked drinks (Iced Latte, etc.) to avoid
        // double-counting.
        MenuCategory(
          name: 'Add Milk / Cream',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Black / No Milk', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(
              name: 'Whole Milk', calories: 70, protein: 4, carbs: 5,
              fat: 4,
              vitaminCMg: 0, magnesiumMg: 11.5, zincMg: 0.4,
              vitaminB12Mcg: 0.5, folateMcg: 5.7,
            ),
            MenuItem(
              name: 'Skim Milk', calories: 45, protein: 4, carbs: 7,
              fat: 0,
              vitaminCMg: 0, magnesiumMg: 14.6, zincMg: 0.6,
              vitaminB12Mcg: 0.7, folateMcg: 6.6,
            ),
            MenuItem(name: 'Oat Milk', calories: 65, protein: 1, carbs: 11, fat: 2),
            MenuItem(name: 'Almond Milk', calories: 25, protein: 1, carbs: 1, fat: 2),
            MenuItem(
              name: 'Cream', calories: 110, protein: 2, carbs: 3,
              fat: 10,
              vitaminCMg: 0.5, magnesiumMg: 5.1, zincMg: 0.2,
              vitaminB12Mcg: 0.1, folateMcg: 1.1,
            ),
          ],
        ),
        MenuCategory(
          name: 'Flavor Shots & Swirls',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Caramel Shot', calories: 10, protein: 0, carbs: 3, fat: 0),
            MenuItem(name: 'Mocha Shot', calories: 10, protein: 0, carbs: 3, fat: 0),
            MenuItem(name: 'Vanilla Shot', calories: 10, protein: 0, carbs: 3, fat: 0),
            MenuItem(name: 'Hazelnut Shot', calories: 10, protein: 0, carbs: 3, fat: 0),
            MenuItem(name: 'Caramel Swirl', calories: 60, protein: 0, carbs: 14, fat: 0),
            MenuItem(name: 'Mocha Swirl', calories: 60, protein: 0, carbs: 12, fat: 1),
            MenuItem(name: 'Vanilla Swirl', calories: 60, protein: 0, carbs: 14, fat: 0),
          ],
        ),
      ],
      'Espresso': const [
        MenuCategory(
          name: 'Shot',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Single Espresso', calories: 5, protein: 0,
              carbs: 1, fat: 0,
              fiber: 0, sodium: 5, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 1, vitaminCMg: 0.1, magnesiumMg: 32,
              potassiumMg: 46, zincMg: 0, vitaminB12Mcg: 0,
              folateMcg: 0.4,
            ),
            MenuItem(
              name: 'Double Espresso', calories: 10, protein: 0,
              carbs: 2, fat: 0,
              fiber: 0, sodium: 10, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 2, vitaminCMg: 0.2, magnesiumMg: 64,
              potassiumMg: 92, zincMg: 0, vitaminB12Mcg: 0,
              folateMcg: 0.8,
            ),
            MenuItem(name: 'Cortado', calories: 50, protein: 3, carbs: 5, fat: 2),
          ],
        ),
      ],
      'Donuts': const [
        MenuCategory(
          name: 'Donut',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(
              name: 'Glazed', calories: 240, protein: 4, carbs: 33,
              fat: 11,
              fiber: 1, sodium: 270, vitaminDMcg: 0, ironMg: 2,
              calciumMg: 12, vitaminCMg: 0.7, magnesiumMg: 9.7,
              potassiumMg: 56, zincMg: 0.3, vitaminB12Mcg: 0.1,
              folateMcg: 61.6,
            ),
            MenuItem(
              name: 'Chocolate Frosted', calories: 260, protein: 4,
              carbs: 34, fat: 11,
              fiber: 1, sodium: 290, vitaminDMcg: 0, ironMg: 2,
              calciumMg: 13, vitaminCMg: 0.7, magnesiumMg: 10.5,
              potassiumMg: 75, zincMg: 0.4, vitaminB12Mcg: 0.1,
              folateMcg: 66.7,
            ),
            MenuItem(
              name: 'Boston Kreme', calories: 270, protein: 5,
              carbs: 39, fat: 11,
              fiber: 1, sodium: 320, vitaminDMcg: 1, ironMg: 2,
              calciumMg: 33, vitaminCMg: 0, magnesiumMg: 15,
              potassiumMg: 81, zincMg: 0.6, vitaminB12Mcg: 0.1,
              folateMcg: 52.4,
            ),
            MenuItem(
              name: 'Jelly', calories: 250, protein: 4, carbs: 36,
              fat: 10,
              fiber: 1, sodium: 290, vitaminDMcg: 1, ironMg: 2,
              calciumMg: 13, vitaminCMg: 0, magnesiumMg: 14.7,
              potassiumMg: 58, zincMg: 0.6, vitaminB12Mcg: 0.2,
              folateMcg: 50,
            ),
            MenuItem(
              name: 'Old Fashioned', calories: 310, protein: 4,
              carbs: 30, fat: 19,
              fiber: 1, sodium: 320, vitaminDMcg: 0, ironMg: 2,
              calciumMg: 24, vitaminCMg: 0, magnesiumMg: 12.1,
              potassiumMg: 64, zincMg: 0.4, vitaminB12Mcg: 0,
              folateMcg: 65.7,
            ),
            MenuItem(
              name: 'Strawberry Frosted', calories: 260, protein: 4,
              carbs: 35, fat: 11,
              fiber: 1, sodium: 280, vitaminDMcg: 0, ironMg: 2,
              calciumMg: 12, vitaminCMg: 0.7, magnesiumMg: 10.5,
              potassiumMg: 59, zincMg: 0.4, vitaminB12Mcg: 0.1,
              folateMcg: 66.7,
            ),
            MenuItem(
              name: 'Powdered Sugar', calories: 330, protein: 4,
              carbs: 34, fat: 20,
              fiber: 1, sodium: 320, vitaminDMcg: 0, ironMg: 2,
              calciumMg: 24, vitaminCMg: 0.1, magnesiumMg: 13.2,
              potassiumMg: 64, zincMg: 0.3, vitaminB12Mcg: 0.2,
              folateMcg: 35.6,
            ),
            MenuItem(
              name: 'Chocolate Glazed', calories: 370, protein: 4,
              carbs: 41, fat: 23,
              fiber: 1, sodium: 420, vitaminDMcg: 0, ironMg: 1,
              calciumMg: 25, vitaminCMg: 0.1, magnesiumMg: 30.2,
              potassiumMg: 57, zincMg: 0.5, vitaminB12Mcg: 0.1,
              folateMcg: 39.9,
            ),
          ],
        ),
      ],
      'Bagels': const [
        MenuCategory(
          name: 'Bagel',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Plain Bagel', calories: 300, protein: 11,
              carbs: 64, fat: 1,
              fiber: 4, sodium: 620, vitaminDMcg: 0, ironMg: 4,
              calciumMg: 20, vitaminCMg: 0, magnesiumMg: 33,
              potassiumMg: 126, zincMg: 0.9, vitaminB12Mcg: 0,
              folateMcg: 120.5,
            ),
            MenuItem(
              name: 'Everything Bagel', calories: 340, protein: 12,
              carbs: 67, fat: 3,
              fiber: 5, sodium: 630, vitaminDMcg: 0, ironMg: 4,
              calciumMg: 57, vitaminCMg: 0, magnesiumMg: 37.3,
              potassiumMg: 182, zincMg: 1.1, vitaminB12Mcg: 0,
              folateMcg: 136.5,
            ),
            MenuItem(
              name: 'Cinnamon Raisin', calories: 320, protein: 11,
              carbs: 67, fat: 1,
              fiber: 4, sodium: 510, vitaminDMcg: 0, ironMg: 3,
              calciumMg: 38, vitaminCMg: 0.8, magnesiumMg: 32.7,
              potassiumMg: 160, zincMg: 1.3, vitaminB12Mcg: 0,
              folateMcg: 129.6,
            ),
            MenuItem(
              name: 'Sesame', calories: 350, protein: 12, carbs: 64,
              fat: 5,
              fiber: 5, sodium: 630, vitaminDMcg: 0, ironMg: 4,
              calciumMg: 24, vitaminCMg: 0, magnesiumMg: 38.4,
              potassiumMg: 152, zincMg: 1.1, vitaminB12Mcg: 0,
              folateMcg: 140.5,
            ),
          ],
        ),
        MenuCategory(
          name: 'Cream Cheese',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(
              name: 'Plain CC', calories: 120, protein: 2, carbs: 3,
              fat: 12,
              fiber: 0, sodium: 200, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 36, vitaminCMg: 0, magnesiumMg: 3.1,
              potassiumMg: 0, zincMg: 0.2, vitaminB12Mcg: 0.1,
              folateMcg: 3.1,
            ),
            MenuItem(
              name: 'Veggie CC', calories: 100, protein: 2, carbs: 2,
              fat: 10,
              fiber: 0, sodium: 200, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 33, vitaminCMg: 0, magnesiumMg: 2.6,
              potassiumMg: 0, zincMg: 0.1, vitaminB12Mcg: 0.1,
              folateMcg: 2.6,
            ),
            MenuItem(
              name: 'Strawberry CC', calories: 130, protein: 2,
              carbs: 9, fat: 10,
              fiber: 0, sodium: 100, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 32, vitaminCMg: 0, magnesiumMg: 3.3,
              potassiumMg: 0, zincMg: 0.2, vitaminB12Mcg: 0.1,
              folateMcg: 3.3,
            ),
          ],
        ),
      ],
      'Sandwiches': const [
        MenuCategory(
          name: 'Bread',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'English Muffin', calories: 190, protein: 6,
              carbs: 35, fat: 2,
              fiber: 1, sodium: 270, vitaminDMcg: 0, ironMg: 2,
              calciumMg: 10, vitaminCMg: 1.5, magnesiumMg: 20.1,
              potassiumMg: 56, zincMg: 0.9, vitaminB12Mcg: 0,
              folateMcg: 78.7,
            ),
            MenuItem(
              name: 'Croissant', calories: 280, protein: 6, carbs: 31,
              fat: 15,
              fiber: 1, sodium: 240, vitaminDMcg: 13, ironMg: 2,
              calciumMg: 16, vitaminCMg: 0.1, magnesiumMg: 11,
              potassiumMg: 77, zincMg: 0.5, vitaminB12Mcg: 0.1,
              folateMcg: 60.7,
            ),
            MenuItem(
              name: 'Bagel (Plain)', calories: 300, protein: 11,
              carbs: 64, fat: 1,
              fiber: 4, sodium: 620, vitaminDMcg: 0, ironMg: 4,
              calciumMg: 20, vitaminCMg: 0, magnesiumMg: 33,
              potassiumMg: 126, zincMg: 0.9, vitaminB12Mcg: 0,
              folateMcg: 120.5,
            ),
            MenuItem(name: 'Sourdough', calories: 230, protein: 9, carbs: 35, fat: 5),
          ],
        ),
        MenuCategory(
          name: 'Protein',
          mode: SelectionMode.multiple,
          maxSelections: 2,
          items: [
            MenuItem(
              name: 'Egg', calories: 80, protein: 6, carbs: 1, fat: 6,
              vitaminCMg: 0, magnesiumMg: 5.3, zincMg: 0.6,
              vitaminB12Mcg: 0.4, folateMcg: 20.8,
            ),
            MenuItem(
              name: 'Egg White', calories: 25, protein: 5, carbs: 1,
              fat: 0,
              vitaminCMg: 0, magnesiumMg: 5.3, zincMg: 0,
              vitaminB12Mcg: 0, folateMcg: 1.9,
            ),
            MenuItem(
              name: 'Bacon (2 strips)', calories: 60, protein: 4,
              carbs: 0, fat: 5,
              vitaminCMg: 0, magnesiumMg: 4, zincMg: 0.4,
              vitaminB12Mcg: 0.1, folateMcg: 0,
            ),
            MenuItem(
              name: 'Sausage', calories: 200, protein: 8, carbs: 1,
              fat: 18,
              vitaminCMg: 0, magnesiumMg: 9.8, zincMg: 1.5,
              vitaminB12Mcg: 0.6, folateMcg: 0.6,
            ),
            MenuItem(
              name: 'Turkey Sausage', calories: 90, protein: 9,
              carbs: 1, fat: 6,
              vitaminCMg: 0.3, magnesiumMg: 9.6, zincMg: 1.8,
              vitaminB12Mcg: 0.6, folateMcg: 2.8,
            ),
            MenuItem(
              name: 'Ham', calories: 50, protein: 8, carbs: 0, fat: 1,
              vitaminCMg: 1.2, magnesiumMg: 6.7, zincMg: 0.4,
              vitaminB12Mcg: 0.1, folateMcg: 2.1,
            ),
          ],
        ),
        MenuCategory(
          name: 'Cheese',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(
              name: 'American', calories: 50, protein: 3, carbs: 1,
              fat: 4,
              vitaminCMg: 0, magnesiumMg: 3.6, zincMg: 0.3,
              vitaminB12Mcg: 0.2, folateMcg: 1.1,
            ),
            MenuItem(
              name: 'Cheddar', calories: 60, protein: 4, carbs: 0,
              fat: 5,
              vitaminCMg: 0, magnesiumMg: 4, zincMg: 0.5,
              vitaminB12Mcg: 0.1, folateMcg: 4,
            ),
            MenuItem(
              name: 'Pepper Jack', calories: 50, protein: 3, carbs: 0,
              fat: 4,
              vitaminCMg: 0, magnesiumMg: 3.6, zincMg: 0.4,
              vitaminB12Mcg: 0.1, folateMcg: 2.4,
            ),
          ],
        ),
      ],
      'Wraps': const [
        MenuCategory(
          name: 'Wake-Up Wrap',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(
              name: 'Turkey Sausage Wake-Up Wrap', calories: 230,
              protein: 11, carbs: 15, fat: 15,
              fiber: 0, sodium: 660, vitaminDMcg: 1, ironMg: 2,
              calciumMg: 135, vitaminCMg: 0, magnesiumMg: 14.3,
              potassiumMg: 118, zincMg: 1, vitaminB12Mcg: 0.5,
              folateMcg: 53.7,
            ),
            MenuItem(
              name: 'Bacon Wake-Up Wrap', calories: 220, protein: 10,
              carbs: 15, fat: 13,
              fiber: 0, sodium: 590, vitaminDMcg: 1, ironMg: 1,
              calciumMg: 134, vitaminCMg: 0, magnesiumMg: 14.4,
              potassiumMg: 112, zincMg: 1, vitaminB12Mcg: 0.5,
              folateMcg: 51.6,
            ),
            MenuItem(
              name: 'Sausage Wake-Up Wrap', calories: 280, protein: 10,
              carbs: 15, fat: 20,
              fiber: 1, sodium: 690, vitaminDMcg: 1, ironMg: 2,
              calciumMg: 145, vitaminCMg: 0, magnesiumMg: 17.4,
              potassiumMg: 122, zincMg: 1.2, vitaminB12Mcg: 0.6,
              folateMcg: 65.4,
            ),
            MenuItem(
              name: 'Ham Wake-Up Wrap', calories: 170, protein: 11,
              carbs: 13, fat: 8,
              vitaminCMg: 0, magnesiumMg: 11.2, zincMg: 0.8,
              vitaminB12Mcg: 0.4, folateMcg: 42.9,
            ),
          ],
        ),
      ],
      'Munchkins': const [
        MenuCategory(
          name: 'Munchkins',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Glazed (5)', calories: 300, protein: 5, carbs: 35,
              fat: 15,
              fiber: 0, sodium: 300, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 10, vitaminCMg: 0.9, magnesiumMg: 12.1,
              potassiumMg: 55, zincMg: 0.4, vitaminB12Mcg: 0.1,
              folateMcg: 77,
            ),
            MenuItem(
              name: 'Glazed (10)', calories: 600, protein: 10,
              carbs: 70, fat: 30,
              fiber: 0, sodium: 600, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 20, vitaminCMg: 1.7, magnesiumMg: 24.2,
              potassiumMg: 110, zincMg: 0.9, vitaminB12Mcg: 0.2,
              folateMcg: 153.9,
            ),
            MenuItem(
              name: 'Chocolate Glazed (5)', calories: 300, protein: 5,
              carbs: 40, fat: 17.5,
              fiber: 0, sodium: 400, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 30, vitaminCMg: 0.1, magnesiumMg: 24.5,
              potassiumMg: 155, zincMg: 0.4, vitaminB12Mcg: 0.1,
              folateMcg: 32.4,
            ),
            MenuItem(
              name: 'Chocolate Glazed (10)', calories: 600, protein: 10,
              carbs: 80, fat: 35,
              fiber: 0, sodium: 800, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 60, vitaminCMg: 0.1, magnesiumMg: 48.9,
              potassiumMg: 310, zincMg: 0.8, vitaminB12Mcg: 0.1,
              folateMcg: 64.7,
            ),
            MenuItem(
              name: 'Cinnamon (5)', calories: 300, protein: 5,
              carbs: 30, fat: 17.5,
              fiber: 0, sodium: 325, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 20, vitaminCMg: 0.1, magnesiumMg: 12,
              potassiumMg: 35, zincMg: 0.3, vitaminB12Mcg: 0.2,
              folateMcg: 32.4,
            ),
            MenuItem(
              name: 'Cinnamon (10)', calories: 600, protein: 10,
              carbs: 60, fat: 35,
              fiber: 0, sodium: 650, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 40, vitaminCMg: 0.1, magnesiumMg: 23.9,
              potassiumMg: 70, zincMg: 0.6, vitaminB12Mcg: 0.3,
              folateMcg: 64.8,
            ),
            MenuItem(
              name: 'Jelly (5)', calories: 300, protein: 5, carbs: 40,
              fat: 15,
              fiber: 0, sodium: 325, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 15, vitaminCMg: 0, magnesiumMg: 17.6,
              potassiumMg: 55, zincMg: 0.7, vitaminB12Mcg: 0.2,
              folateMcg: 60,
            ),
            MenuItem(
              name: 'Jelly (10)', calories: 600, protein: 10, carbs: 80,
              fat: 30,
              fiber: 0, sodium: 650, vitaminDMcg: 0, ironMg: 0,
              calciumMg: 30, vitaminCMg: 0, magnesiumMg: 35.3,
              potassiumMg: 110, zincMg: 1.3, vitaminB12Mcg: 0.4,
              folateMcg: 120,
            ),
          ],
        ),
      ],
    },
  ),

  // 13. RAISING CANE'S — raisingcanes.com nutrition page.
  RestaurantMenu(
    id: 'canes',
    name: "Raising Cane's",
    emoji: '🐔',
    accentColor: const Color(0xFFDB0032),
    mealTypes: const ['Combos', 'A La Carte', 'Sides', 'Drinks'],
    builders: {
      'Combos': const [
        MenuCategory(
          name: 'Combo',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'The Box Combo (4 fingers, fries, slaw, toast, sauce, reg drink)', calories: 1330, protein: 53, carbs: 113, fat: 73),
            MenuItem(name: 'The 3 Finger Combo (3 fingers, fries, toast, sauce, reg drink)', calories: 1060, protein: 41, carbs: 95, fat: 56),
            MenuItem(name: 'The Caniac Combo (6 fingers, fries, slaw, 2 toast, 2 sauces, lrg drink)', calories: 1700, protein: 69, carbs: 132, fat: 102),
            MenuItem(name: 'Sandwich Combo (sandwich, fries, sauce, reg drink)', calories: 1290, protein: 34, carbs: 121, fat: 76),
            MenuItem(name: 'Kids Combo (2 fingers, fries, kids drink, sauce)', calories: 720, protein: 28, carbs: 71, fat: 40),
          ],
        ),
      ],
      'A La Carte': const [
        MenuCategory(
          name: 'Item',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Chicken Finger (each)', calories: 130, protein: 11, carbs: 8, fat: 6),
            MenuItem(name: 'Chicken Sandwich', calories: 670, protein: 28, carbs: 39, fat: 41),
            MenuItem(name: "Extra Cane's Sauce", calories: 180, protein: 1, carbs: 4, fat: 19),
          ],
        ),
      ],
      'Sides': const [
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Crinkle-Cut Fries (reg)', calories: 480, protein: 6, carbs: 65, fat: 22),
            MenuItem(name: 'Coleslaw', calories: 200, protein: 1, carbs: 19, fat: 14),
            MenuItem(name: 'Texas Toast', calories: 180, protein: 4, carbs: 21, fat: 9),
            MenuItem(name: 'Extra Dipping Sauce', calories: 180, protein: 1, carbs: 4, fat: 19),
          ],
        ),
      ],
      'Drinks': const [
        MenuCategory(
          name: 'Drink',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Sweet Tea (Reg)', calories: 230, protein: 0, carbs: 59, fat: 0),
            MenuItem(name: 'Lemonade (Reg)', calories: 220, protein: 0, carbs: 56, fat: 0),
            MenuItem(name: 'Sweet Tea (Lrg)', calories: 340, protein: 0, carbs: 88, fat: 0),
            MenuItem(name: 'Lemonade (Lrg)', calories: 330, protein: 0, carbs: 84, fat: 0),
            MenuItem(name: 'Coca-Cola (Reg)', calories: 220, protein: 0, carbs: 60, fat: 0),
            MenuItem(name: 'Diet Coke', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Dr Pepper (Reg)', calories: 220, protein: 0, carbs: 59, fat: 0),
            MenuItem(name: 'Water', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
      ],
    },
  ),

  // 14. POPEYES — popeyes.com nutrition guide.
  RestaurantMenu(
    id: 'popeyes',
    name: 'Popeyes',
    emoji: '🍗',
    accentColor: const Color(0xFFFF7E03),
    mealTypes: const ['Chicken', 'Tenders', 'Sandwiches', 'Seafood', 'Sides', 'Desserts'],
    builders: {
      'Chicken': const [
        MenuCategory(
          name: 'Piece',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Breast (Mild)', calories: 380, protein: 25, carbs: 16, fat: 23),
            MenuItem(name: 'Breast (Spicy)', calories: 390, protein: 25, carbs: 16, fat: 24),
            MenuItem(name: 'Thigh (Mild)', calories: 280, protein: 13, carbs: 8, fat: 21),
            MenuItem(name: 'Thigh (Spicy)', calories: 290, protein: 13, carbs: 9, fat: 22),
            MenuItem(name: 'Leg (Mild)', calories: 160, protein: 12, carbs: 5, fat: 10),
            MenuItem(name: 'Leg (Spicy)', calories: 170, protein: 12, carbs: 6, fat: 11),
            MenuItem(name: 'Wing (Mild)', calories: 180, protein: 9, carbs: 8, fat: 12),
            MenuItem(name: 'Wing (Spicy)', calories: 190, protein: 9, carbs: 9, fat: 13),
          ],
        ),
      ],
      'Tenders': const [
        MenuCategory(
          name: 'Tenders',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Tenders (3 pc, Mild)', calories: 350, protein: 28, carbs: 16, fat: 18),
            MenuItem(name: 'Tenders (3 pc, Spicy)', calories: 360, protein: 28, carbs: 17, fat: 19),
            MenuItem(name: 'Tenders (5 pc, Mild)', calories: 580, protein: 47, carbs: 27, fat: 30),
            MenuItem(name: 'Tenders (5 pc, Spicy)', calories: 600, protein: 47, carbs: 29, fat: 32),
          ],
        ),
        MenuCategory(
          name: 'Sauce',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Blackened Ranch', calories: 130, protein: 1, carbs: 1, fat: 14),
            MenuItem(name: 'BoldBQ', calories: 70, protein: 0, carbs: 16, fat: 0),
            MenuItem(name: 'Sweet Heat', calories: 80, protein: 0, carbs: 20, fat: 0),
            MenuItem(name: 'Buttermilk Ranch', calories: 140, protein: 1, carbs: 1, fat: 14),
            MenuItem(name: 'Mardi Gras Mustard', calories: 90, protein: 0, carbs: 5, fat: 8),
          ],
        ),
      ],
      'Sandwiches': const [
        MenuCategory(
          name: 'Sandwich',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Classic Chicken Sandwich', calories: 700, protein: 28, carbs: 50, fat: 42),
            MenuItem(name: 'Spicy Chicken Sandwich', calories: 700, protein: 28, carbs: 50, fat: 42),
            MenuItem(name: 'Bacon & Cheese Chicken Sandwich', calories: 810, protein: 33, carbs: 50, fat: 50),
          ],
        ),
      ],
      'Seafood': const [
        MenuCategory(
          name: 'Seafood',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Popcorn Shrimp (Reg)', calories: 410, protein: 13, carbs: 32, fat: 25),
            MenuItem(name: 'Butterfly Shrimp (8 pc)', calories: 350, protein: 14, carbs: 28, fat: 19),
          ],
        ),
      ],
      'Sides': const [
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Red Beans & Rice (Reg)', calories: 250, protein: 7, carbs: 30, fat: 11),
            MenuItem(name: 'Cajun Fries (Reg)', calories: 330, protein: 4, carbs: 41, fat: 16),
            MenuItem(name: 'Cajun Fries (Lrg)', calories: 700, protein: 8, carbs: 86, fat: 35),
            MenuItem(name: 'Mashed Potatoes w/ Cajun Gravy', calories: 110, protein: 3, carbs: 18, fat: 4),
            MenuItem(name: 'Mac & Cheese', calories: 220, protein: 7, carbs: 19, fat: 12),
            MenuItem(name: 'Coleslaw', calories: 220, protein: 1, carbs: 14, fat: 18),
            MenuItem(name: 'Biscuit', calories: 240, protein: 3, carbs: 26, fat: 13),
            MenuItem(name: 'Cajun Rice', calories: 170, protein: 4, carbs: 22, fat: 6),
            MenuItem(name: 'Corn on the Cob', calories: 190, protein: 5, carbs: 38, fat: 4),
            MenuItem(name: 'Green Beans', calories: 50, protein: 2, carbs: 7, fat: 1),
          ],
        ),
      ],
      'Desserts': const [
        MenuCategory(
          name: 'Dessert',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Cinnamon Apple Pie', calories: 200, protein: 1, carbs: 31, fat: 8),
            MenuItem(name: 'Hot Cinnamon Roll', calories: 330, protein: 4, carbs: 47, fat: 14),
          ],
        ),
      ],
    },
  ),

  // 15. WENDY'S — wendys.com nutrition explorer.
  RestaurantMenu(
    id: 'wendys',
    name: "Wendy's",
    emoji: '🟥',
    accentColor: const Color(0xFFC8102E),
    mealTypes: const ['Burgers', 'Chicken', 'Nuggets', 'Sides', 'Frosty', 'Breakfast', 'Drinks'],
    builders: {
      'Burgers': const [
        MenuCategory(
          name: 'Burger',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: "Dave's Single", calories: 560, protein: 30, carbs: 37, fat: 34,
              fiber: 2, sodium: 1130, ironMg: 4.5, calciumMg: 195,
              vitaminCMg: 2.3, magnesiumMg: 37.6, potassiumMg: 470,
              zincMg: 4.7, vitaminB12Mcg: 1.9,
            ),
            MenuItem(
              name: "Dave's Double", calories: 810, protein: 50, carbs: 37, fat: 52,
              fiber: 2, sodium: 1360, ironMg: 7.2, calciumMg: 195,
              vitaminCMg: 2.4, magnesiumMg: 63.9, potassiumMg: 705,
              zincMg: 10.3, vitaminB12Mcg: 6.5,
            ),
            MenuItem(
              name: "Dave's Triple", calories: 1090, protein: 72, carbs: 38, fat: 74,
              fiber: 2, sodium: 1790, ironMg: 9, calciumMg: 260,
              vitaminCMg: 3.2, magnesiumMg: 85.9, potassiumMg: 1175,
              zincMg: 13.8, vitaminB12Mcg: 8.7,
            ),
            MenuItem(
              name: 'Jr Bacon Cheeseburger', calories: 350, protein: 18, carbs: 24, fat: 21,
              fiber: 1, sodium: 650, ironMg: 2.7, calciumMg: 104,
              vitaminCMg: 0.8, magnesiumMg: 30.1, potassiumMg: 282,
              zincMg: 3, vitaminB12Mcg: 1.8,
            ),
            MenuItem(
              name: 'Jr Hamburger', calories: 230, protein: 12, carbs: 24, fat: 10,
              fiber: 1, sodium: 470, ironMg: 2.7, calciumMg: 52,
              vitaminCMg: 0.5, magnesiumMg: 19.9, potassiumMg: 188,
              zincMg: 2, vitaminB12Mcg: 1.2,
            ),
            MenuItem(
              name: 'Jr Cheeseburger', calories: 270, protein: 14, carbs: 25, fat: 13,
              fiber: 1, sodium: 660, ironMg: 2.7, calciumMg: 104,
              vitaminCMg: 0.6, magnesiumMg: 23.2, potassiumMg: 188,
              zincMg: 2.3, vitaminB12Mcg: 1.4,
            ),
            MenuItem(
              name: 'Baconator', calories: 890, protein: 59, carbs: 36, fat: 58,
              fiber: 1, sodium: 1580, ironMg: 7.2, calciumMg: 195,
              vitaminCMg: 2.6, magnesiumMg: 70.2, potassiumMg: 705,
              zincMg: 11.3, vitaminB12Mcg: 7.1,
            ),
            MenuItem(
              name: 'Son of Baconator', calories: 590, protein: 34, carbs: 35, fat: 36,
              fiber: 1, sodium: 1210, ironMg: 4.5, calciumMg: 195,
              magnesiumMg: 43.5, potassiumMg: 470, zincMg: 7,
            ),
          ],
        ),
        MenuCategory(
          name: 'Toppings',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(
              name: 'Lettuce', calories: 0, protein: 0, carbs: 1, fat: 0,
              fiber: 0, sodium: 0, ironMg: 0, calciumMg: 0,
              vitaminCMg: 0.5, magnesiumMg: 1.2, potassiumMg: 0,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 4.9,
            ),
            MenuItem(
              name: 'Tomato', calories: 5, protein: 0, carbs: 1, fat: 0,
              fiber: 0, sodium: 0, ironMg: 0, calciumMg: 0,
              vitaminCMg: 3.7, magnesiumMg: 3, potassiumMg: 94,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 4.1,
            ),
            MenuItem(
              name: 'Onion', calories: 0, protein: 0, carbs: 0, fat: 0,
              fiber: 0, sodium: 0, ironMg: 0, calciumMg: 0,
              vitaminCMg: 0.3, magnesiumMg: 0.5, potassiumMg: 0,
              zincMg: 0, folateMcg: 1.4,
            ),
            MenuItem(
              name: 'Pickles', calories: 0, protein: 0, carbs: 0, fat: 0,
              fiber: 0, sodium: 110, ironMg: 0, calciumMg: 0,
              vitaminCMg: 0.2, magnesiumMg: 0.6, potassiumMg: 0,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0.7,
            ),
            MenuItem(
              name: 'Ketchup', calories: 10, protein: 0, carbs: 2, fat: 0,
              fiber: 0, sodium: 65, ironMg: 0, calciumMg: 0,
              vitaminCMg: 0.3, magnesiumMg: 0.9, potassiumMg: 0,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0.6,
            ),
            MenuItem(
              name: 'Mustard', calories: 5, protein: 0, carbs: 0, fat: 0,
              fiber: 0, sodium: 40, ironMg: 0, calciumMg: 0,
              vitaminCMg: 0, magnesiumMg: 1.8, potassiumMg: 0,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0.3,
            ),
            MenuItem(
              name: 'Mayo', calories: 60, protein: 0, carbs: 0, fat: 6,
              fiber: 0, sodium: 50, ironMg: 0, calciumMg: 0,
              vitaminCMg: 0, magnesiumMg: 0.1, potassiumMg: 0,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0.4,
            ),
          ],
        ),
        MenuCategory(
          name: 'Add-ons',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(
              name: 'Extra Bacon', calories: 50, protein: 4, carbs: 0, fat: 3.5,
              fiber: 0, sodium: 170, ironMg: 0, calciumMg: 0,
              vitaminCMg: 0, magnesiumMg: 3, potassiumMg: 94,
              zincMg: 0.3, vitaminB12Mcg: 0.1, folateMcg: 0.2,
            ),
            MenuItem(
              name: 'Extra Cheese', calories: 80, protein: 4, carbs: 1, fat: 7,
              fiber: 0, sodium: 380, ironMg: 0, calciumMg: 130,
              vitaminCMg: 0, magnesiumMg: 5.9, potassiumMg: 0,
              zincMg: 0.6, vitaminB12Mcg: 0.3, folateMcg: 1.8,
            ),
          ],
        ),
      ],
      'Chicken': const [
        MenuCategory(
          name: 'Chicken',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Classic Chicken Sandwich', calories: 550, protein: 28, carbs: 55, fat: 25,
              fiber: 3, sodium: 1630, ironMg: 2.7, calciumMg: 78,
              vitaminCMg: 0.8, magnesiumMg: 61.7, potassiumMg: 470,
              zincMg: 1.6, vitaminB12Mcg: 0.8,
            ),
            MenuItem(
              name: 'Spicy Chicken Sandwich', calories: 560, protein: 28, carbs: 55, fat: 26,
              fiber: 3, sodium: 1500, ironMg: 2.7, calciumMg: 78,
              vitaminCMg: 0.8, magnesiumMg: 62.8, potassiumMg: 470,
              zincMg: 1.6, vitaminB12Mcg: 0.9,
            ),
            MenuItem(
              name: 'Grilled Chicken Sandwich', calories: 360, protein: 31, carbs: 35, fat: 10,
              vitaminCMg: 2.2, magnesiumMg: 48.3, zincMg: 1.1,
              vitaminB12Mcg: 0.7,
            ),
            MenuItem(
              name: 'Spicy Chicken Nuggets (6 pc)', calories: 280, protein: 15, carbs: 13, fat: 18,
              fiber: 1, sodium: 720, ironMg: 0.4, calciumMg: 0,
              vitaminCMg: 1.1, magnesiumMg: 18.9, potassiumMg: 188,
              zincMg: 0.5, vitaminB12Mcg: 0.3,
            ),
          ],
        ),
      ],
      'Nuggets': const [
        MenuCategory(
          name: 'Nuggets',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Nuggets (4 pc)', calories: 170, protein: 9, carbs: 10, fat: 11,
              fiber: 0, sodium: 360, ironMg: 0.4, calciumMg: 0,
              vitaminCMg: 0.7, magnesiumMg: 11.5, potassiumMg: 94,
              zincMg: 0.3, vitaminB12Mcg: 0.2,
            ),
            MenuItem(
              name: 'Nuggets (6 pc)', calories: 260, protein: 14, carbs: 13, fat: 16,
              fiber: 1, sodium: 540, ironMg: 0.4, calciumMg: 0,
              vitaminCMg: 1, magnesiumMg: 17.5, potassiumMg: 188,
              zincMg: 0.5, vitaminB12Mcg: 0.3,
            ),
            MenuItem(
              name: 'Nuggets (10 pc)', calories: 430, protein: 23, carbs: 22, fat: 27,
              fiber: 1, sodium: 900, ironMg: 0.7, calciumMg: 26,
              vitaminCMg: 1.7, magnesiumMg: 29, potassiumMg: 376,
              zincMg: 0.8, vitaminB12Mcg: 0.4,
            ),
          ],
        ),
        MenuCategory(
          name: 'Sauce',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'BBQ', calories: 45, protein: 0, carbs: 10, fat: 0),
            MenuItem(name: 'Ranch', calories: 100, protein: 0, carbs: 2, fat: 11),
            MenuItem(name: 'Sweet & Sour', calories: 50, protein: 0, carbs: 12, fat: 0),
            MenuItem(
              name: 'Honey Mustard', calories: 110, protein: 0, carbs: 7, fat: 9,
              fiber: 0, sodium: 210, ironMg: 0, calciumMg: 0,
              vitaminCMg: 0.1, magnesiumMg: 1.6, potassiumMg: 0,
              zincMg: 0, vitaminB12Mcg: 0, folateMcg: 1.6,
            ),
            MenuItem(name: 'Buttermilk Ranch', calories: 100, protein: 0, carbs: 2, fat: 11),
            MenuItem(name: "S'Awesome", calories: 100, protein: 0, carbs: 5, fat: 8),
            MenuItem(name: 'Creamy Sriracha', calories: 90, protein: 0, carbs: 1, fat: 10),
          ],
        ),
      ],
      'Sides': const [
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(
              name: 'Natural Cut Fries (S)', calories: 260, protein: 4, carbs: 35, fat: 12,
              fiber: 3, sodium: 420, ironMg: 1.1, calciumMg: 26,
              vitaminCMg: 3.3, magnesiumMg: 28.5, potassiumMg: 705,
              zincMg: 0.5,
            ),
            MenuItem(
              name: 'Natural Cut Fries (M)', calories: 350, protein: 5, carbs: 47, fat: 16,
              fiber: 4, sodium: 550, ironMg: 1.1, calciumMg: 26,
              vitaminCMg: 4.4, magnesiumMg: 38.4, potassiumMg: 705,
              zincMg: 0.6,
            ),
            MenuItem(
              name: 'Natural Cut Fries (L)', calories: 470, protein: 7, carbs: 63, fat: 21,
              fiber: 5, sodium: 740, ironMg: 1.8, calciumMg: 26,
              vitaminCMg: 5.9, magnesiumMg: 51.5, potassiumMg: 1175,
              zincMg: 0.8,
            ),
            MenuItem(
              name: 'Baked Potato (plain)', calories: 270, protein: 7, carbs: 61, fat: 0,
              fiber: 7, sodium: 40, ironMg: 2.7, calciumMg: 52,
              vitaminCMg: 27.9, magnesiumMg: 81.3, potassiumMg: 1645,
              zincMg: 1, vitaminB12Mcg: 0, folateMcg: 81.3,
            ),
            MenuItem(
              name: 'Baked Potato (sour cream & chive)', calories: 300, protein: 8, carbs: 63, fat: 2.5,
              fiber: 7, sodium: 55, ironMg: 2.7, calciumMg: 78,
              potassiumMg: 1645,
            ),
            MenuItem(
              name: 'Baked Potato (bacon cheese)', calories: 420, protein: 17, carbs: 64, fat: 12,
              fiber: 7, sodium: 570, ironMg: 3.6, calciumMg: 195,
              potassiumMg: 1645,
            ),
            MenuItem(
              name: 'Chili (S)', calories: 280, protein: 19, carbs: 24, fat: 12,
              fiber: 3, sodium: 1050, ironMg: 2.7, calciumMg: 52,
              vitaminCMg: 0.5, magnesiumMg: 73.3, potassiumMg: 470,
              zincMg: 2.3, vitaminB12Mcg: 0.7, folateMcg: 55,
            ),
            MenuItem(
              name: 'Chili (L)', calories: 370, protein: 25, carbs: 29, fat: 17,
              fiber: 4, sodium: 1390, ironMg: 3.6, calciumMg: 52,
              vitaminCMg: 0.7, magnesiumMg: 96.8, potassiumMg: 705,
              zincMg: 3.1, vitaminB12Mcg: 1, folateMcg: 72.6,
            ),
            MenuItem(name: 'Side Salad', calories: 70, protein: 4, carbs: 11, fat: 0),
            MenuItem(
              name: 'Apple Bites', calories: 35, protein: 0, carbs: 9, fat: 0,
              fiber: 1, sodium: 0, ironMg: 0, calciumMg: 26,
              potassiumMg: 94,
            ),
          ],
        ),
      ],
      'Frosty': const [
        MenuCategory(
          name: 'Frosty',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Chocolate Frosty (Jr)', calories: 190, protein: 6, carbs: 31, fat: 6,
              fiber: 0, sodium: 115, ironMg: 0.7, calciumMg: 195,
              vitaminCMg: 0, magnesiumMg: 28.8, potassiumMg: 282,
              zincMg: 0.6, vitaminB12Mcg: 0.8,
            ),
            MenuItem(
              name: 'Chocolate Frosty (S)', calories: 310, protein: 9, carbs: 49, fat: 9,
              fiber: 1, sodium: 180, ironMg: 1.1, calciumMg: 325,
              vitaminCMg: 0, magnesiumMg: 47, potassiumMg: 470,
              zincMg: 1, vitaminB12Mcg: 1.4,
            ),
            MenuItem(
              name: 'Chocolate Frosty (M)', calories: 390, protein: 12, carbs: 61, fat: 12,
              fiber: 1, sodium: 230, ironMg: 1.4, calciumMg: 390,
              vitaminCMg: 0, magnesiumMg: 59.1, potassiumMg: 705,
              zincMg: 1.3, vitaminB12Mcg: 1.7,
            ),
            MenuItem(
              name: 'Chocolate Frosty (L)', calories: 510, protein: 15, carbs: 80, fat: 15,
              fiber: 1, sodium: 290, ironMg: 1.8, calciumMg: 520,
              vitaminCMg: 0, magnesiumMg: 77.3, potassiumMg: 705,
              zincMg: 1.7, vitaminB12Mcg: 2.3,
            ),
            MenuItem(
              name: 'Vanilla Frosty (Jr)', calories: 190, protein: 6, carbs: 31, fat: 6,
              fiber: 0, sodium: 115, ironMg: 0, calciumMg: 195,
              vitaminCMg: 0, magnesiumMg: 28.8, potassiumMg: 282,
              zincMg: 0.6, vitaminB12Mcg: 0.8,
            ),
            MenuItem(
              name: 'Vanilla Frosty (S)', calories: 310, protein: 9, carbs: 49, fat: 9,
              fiber: 0, sodium: 180, ironMg: 0, calciumMg: 325,
              vitaminCMg: 0, magnesiumMg: 47, potassiumMg: 470,
              zincMg: 1, vitaminB12Mcg: 1.4,
            ),
            MenuItem(
              name: 'Vanilla Frosty (M)', calories: 390, protein: 12, carbs: 62, fat: 11,
              fiber: 0, sodium: 230, ironMg: 0.4, calciumMg: 390,
              vitaminCMg: 0, magnesiumMg: 59.1, potassiumMg: 470,
              zincMg: 1.3, vitaminB12Mcg: 1.7,
            ),
            MenuItem(
              name: 'Vanilla Frosty (L)', calories: 510, protein: 15, carbs: 81, fat: 15,
              fiber: 0, sodium: 300, ironMg: 0.4, calciumMg: 520,
              vitaminCMg: 0, magnesiumMg: 77.3, potassiumMg: 705,
              zincMg: 1.7, vitaminB12Mcg: 2.3,
            ),
          ],
        ),
      ],
      'Breakfast': const [
        MenuCategory(
          name: 'Entree',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Breakfast Baconator', calories: 630, protein: 30, carbs: 36, fat: 42,
              fiber: 1, sodium: 1410, ironMg: 3.6, calciumMg: 260,
              potassiumMg: 376,
            ),
            MenuItem(
              name: 'Honey Butter Chicken Biscuit', calories: 490, protein: 14, carbs: 48, fat: 27,
              fiber: 4, sodium: 1040, ironMg: 1.8, calciumMg: 52,
              potassiumMg: 188,
            ),
            MenuItem(
              name: 'Sausage Egg & Cheese Biscuit', calories: 590, protein: 21, carbs: 35, fat: 41,
              fiber: 2, sodium: 1350, ironMg: 2.7, calciumMg: 130,
              potassiumMg: 376,
            ),
            MenuItem(
              name: 'Maple Bacon Chicken Croissant', calories: 540, protein: 19, carbs: 48, fat: 30,
              fiber: 3, sodium: 880, ironMg: 2.7, calciumMg: 26,
              potassiumMg: 282,
            ),
            MenuItem(
              name: 'Bacon, Egg & Swiss Croissant', calories: 420, protein: 18, carbs: 34, fat: 23,
              fiber: 0, sodium: 800, ironMg: 3.6, calciumMg: 78,
              potassiumMg: 188,
            ),
            MenuItem(
              name: 'Seasoned Potatoes', calories: 280, protein: 3, carbs: 39, fat: 13,
              fiber: 4, sodium: 600, ironMg: 0.7, calciumMg: 26,
              potassiumMg: 470,
            ),
          ],
        ),
      ],
      'Drinks': const [
        MenuCategory(
          name: 'Drink',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Coca-Cola (S)', calories: 180, protein: 0, carbs: 48, fat: 0,
              fiber: 0, sodium: 50, ironMg: 0, calciumMg: 0,
              vitaminCMg: 0, magnesiumMg: 0, potassiumMg: 0,
              zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 0,
            ),
            MenuItem(
              name: 'Coca-Cola (M)', calories: 250, protein: 0, carbs: 69, fat: 0,
              fiber: 0, sodium: 70, ironMg: 0, calciumMg: 0,
              vitaminCMg: 0, magnesiumMg: 0, potassiumMg: 0,
              zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 0,
            ),
            MenuItem(
              name: 'Coca-Cola (L)', calories: 320, protein: 0, carbs: 88, fat: 0,
              fiber: 0, sodium: 90, ironMg: 0, calciumMg: 0,
              vitaminCMg: 0, magnesiumMg: 0, potassiumMg: 0,
              zincMg: 0.2, vitaminB12Mcg: 0, folateMcg: 0,
            ),
            MenuItem(
              name: 'Diet Coke', calories: 0, protein: 0, carbs: 0, fat: 0,
              fiber: 0, sodium: 85, ironMg: 0, calciumMg: 0,
              vitaminCMg: 0, magnesiumMg: 6.8, potassiumMg: 94,
              zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 0,
            ),
            MenuItem(
              name: 'Sprite (M)', calories: 240, protein: 0, carbs: 63, fat: 0,
              fiber: 0, sodium: 120, ironMg: 0, calciumMg: 0,
              vitaminCMg: 0, magnesiumMg: 6, potassiumMg: 0,
              zincMg: 0.2, vitaminB12Mcg: 0, folateMcg: 0,
            ),
            MenuItem(
              name: 'Dr Pepper (M)', calories: 250, protein: 0, carbs: 68, fat: 0,
              fiber: 0, sodium: 75, ironMg: 0, calciumMg: 0,
              vitaminCMg: 0, magnesiumMg: 0, potassiumMg: 0,
              zincMg: 0.2, vitaminB12Mcg: 0, folateMcg: 0,
            ),
            MenuItem(
              name: 'Lemonade (M)', calories: 280, protein: 0, carbs: 72, fat: 0,
              fiber: 0, sodium: 35, ironMg: 0, calciumMg: 0,
              potassiumMg: 94,
            ),
            MenuItem(
              name: 'Chocolate Milk', calories: 140, protein: 7, carbs: 23, fat: 2.5,
              fiber: 1, sodium: 160, ironMg: 1.1, calciumMg: 260,
              vitaminCMg: 0.9, magnesiumMg: 28.4, potassiumMg: 376,
              zincMg: 0.9, vitaminB12Mcg: 0.5, folateMcg: 6.6,
            ),
            MenuItem(name: 'Apple Juice', calories: 90, protein: 0, carbs: 21, fat: 0),
            MenuItem(
              name: 'Water', calories: 0, protein: 0, carbs: 0, fat: 0,
              fiber: 0, sodium: 0, ironMg: 0, calciumMg: 0,
              potassiumMg: 0,
            ),
          ],
        ),
      ],
    },
  ),

  // 16. WINGSTOP — wingstop.com nutrition; per-piece values for wings.
  RestaurantMenu(
    id: 'wingstop',
    name: 'Wingstop',
    emoji: '🍗',
    accentColor: const Color(0xFFED1C24),
    mealTypes: const ['Wings (Bone-In)', 'Wings (Boneless)', 'Tenders', 'Sides', 'Dips', 'Drinks'],
    builders: {
      'Wings (Bone-In)': const [
        MenuCategory(
          name: 'Wing Count (plain, per wing ≈ 100 cal)',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Classic Wings (6 pc)', calories: 600, protein: 54, carbs: 0, fat: 42),
            MenuItem(name: 'Classic Wings (8 pc)', calories: 800, protein: 72, carbs: 0, fat: 56),
            MenuItem(name: 'Classic Wings (10 pc)', calories: 1000, protein: 90, carbs: 0, fat: 70),
            MenuItem(name: 'Classic Wings (12 pc)', calories: 1200, protein: 108, carbs: 0, fat: 84),
            MenuItem(name: 'Classic Wings (15 pc)', calories: 1500, protein: 135, carbs: 0, fat: 105),
            MenuItem(name: 'Classic Wings (20 pc)', calories: 2000, protein: 180, carbs: 0, fat: 140),
          ],
        ),
        MenuCategory(
          name: 'Flavor (adds per 10-piece order)',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Plain', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Atomic', calories: 110, protein: 1, carbs: 3, fat: 11),
            MenuItem(name: 'Mango Habanero', calories: 200, protein: 1, carbs: 32, fat: 8),
            MenuItem(name: 'Cajun', calories: 50, protein: 0, carbs: 4, fat: 5),
            MenuItem(name: 'Original Hot', calories: 120, protein: 1, carbs: 2, fat: 12),
            MenuItem(name: 'Mild', calories: 130, protein: 1, carbs: 3, fat: 13),
            MenuItem(name: 'Lemon Pepper', calories: 220, protein: 0, carbs: 1, fat: 24),
            MenuItem(name: 'Garlic Parmesan', calories: 250, protein: 3, carbs: 3, fat: 25),
            MenuItem(name: 'Hickory Smoked BBQ', calories: 180, protein: 1, carbs: 36, fat: 4),
            MenuItem(name: 'Louisiana Rub', calories: 30, protein: 1, carbs: 4, fat: 1),
          ],
        ),
      ],
      'Wings (Boneless)': const [
        MenuCategory(
          name: 'Wing Count (plain, per wing ≈ 60 cal)',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Boneless Wings (6 pc)', calories: 360, protein: 24, carbs: 18, fat: 18),
            MenuItem(name: 'Boneless Wings (8 pc)', calories: 480, protein: 32, carbs: 24, fat: 24),
            MenuItem(name: 'Boneless Wings (10 pc)', calories: 600, protein: 40, carbs: 30, fat: 30),
            MenuItem(name: 'Boneless Wings (12 pc)', calories: 720, protein: 48, carbs: 36, fat: 36),
            MenuItem(name: 'Boneless Wings (15 pc)', calories: 900, protein: 60, carbs: 45, fat: 45),
            MenuItem(name: 'Boneless Wings (20 pc)', calories: 1200, protein: 80, carbs: 60, fat: 60),
          ],
        ),
        MenuCategory(
          name: 'Flavor',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Plain', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Atomic', calories: 110, protein: 1, carbs: 3, fat: 11),
            MenuItem(name: 'Mango Habanero', calories: 200, protein: 1, carbs: 32, fat: 8),
            MenuItem(name: 'Cajun', calories: 50, protein: 0, carbs: 4, fat: 5),
            MenuItem(name: 'Original Hot', calories: 120, protein: 1, carbs: 2, fat: 12),
            MenuItem(name: 'Mild', calories: 130, protein: 1, carbs: 3, fat: 13),
            MenuItem(name: 'Lemon Pepper', calories: 220, protein: 0, carbs: 1, fat: 24),
            MenuItem(name: 'Garlic Parmesan', calories: 250, protein: 3, carbs: 3, fat: 25),
            MenuItem(name: 'Hickory Smoked BBQ', calories: 180, protein: 1, carbs: 36, fat: 4),
            MenuItem(name: 'Louisiana Rub', calories: 30, protein: 1, carbs: 4, fat: 1),
          ],
        ),
      ],
      'Tenders': const [
        MenuCategory(
          name: 'Tenders',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Chicken Tenders (3 pc, plain)', calories: 300, protein: 24, carbs: 6, fat: 18),
            MenuItem(name: 'Chicken Tenders (5 pc, plain)', calories: 500, protein: 40, carbs: 10, fat: 30),
          ],
        ),
        MenuCategory(
          name: 'Flavor',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Plain', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Lemon Pepper', calories: 100, protein: 0, carbs: 1, fat: 10),
            MenuItem(name: 'Garlic Parmesan', calories: 120, protein: 2, carbs: 2, fat: 12),
            MenuItem(name: 'Mango Habanero', calories: 100, protein: 0, carbs: 16, fat: 4),
            MenuItem(name: 'Hickory BBQ', calories: 90, protein: 0, carbs: 18, fat: 2),
            MenuItem(name: 'Original Hot', calories: 60, protein: 0, carbs: 1, fat: 6),
            MenuItem(name: 'Louisiana Rub', calories: 15, protein: 0, carbs: 2, fat: 1),
          ],
        ),
      ],
      'Sides': const [
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Cajun Fried Corn (2 cobs)', calories: 290, protein: 5, carbs: 36, fat: 14),
            MenuItem(name: 'Coleslaw', calories: 320, protein: 1, carbs: 25, fat: 25),
            MenuItem(name: 'Veggie Sticks (carrots/celery)', calories: 30, protein: 1, carbs: 7, fat: 0),
            MenuItem(name: 'Seasoned Fries (Reg)', calories: 530, protein: 6, carbs: 73, fat: 24),
            MenuItem(name: 'Seasoned Fries (Lrg)', calories: 770, protein: 9, carbs: 105, fat: 35),
            MenuItem(name: 'Cheese Fries', calories: 720, protein: 14, carbs: 76, fat: 39),
            MenuItem(name: 'Louisiana Voodoo Fries', calories: 890, protein: 19, carbs: 80, fat: 56),
          ],
        ),
      ],
      'Dips': const [
        MenuCategory(
          name: 'Dip',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Ranch', calories: 160, protein: 1, carbs: 2, fat: 17),
            MenuItem(name: 'Blue Cheese', calories: 160, protein: 1, carbs: 1, fat: 17),
            MenuItem(name: 'Honey Mustard', calories: 160, protein: 0, carbs: 8, fat: 14),
            MenuItem(name: 'Henny BBQ', calories: 90, protein: 0, carbs: 19, fat: 1),
          ],
        ),
      ],
      'Drinks': const [
        MenuCategory(
          name: 'Drink',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Coca-Cola (M)', calories: 260, protein: 0, carbs: 70, fat: 0),
            MenuItem(name: 'Diet Coke', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Sprite (M)', calories: 250, protein: 0, carbs: 68, fat: 0),
            MenuItem(name: 'Sweet Tea (M)', calories: 180, protein: 0, carbs: 46, fat: 0),
            MenuItem(name: 'Lemonade (M)', calories: 160, protein: 0, carbs: 42, fat: 0),
            MenuItem(name: 'Water', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
      ],
    },
  ),

  // 17. JERSEY MIKE'S — jerseymikes.com nutrition info; regular size = 7".
  RestaurantMenu(
    id: 'jerseymikes',
    name: "Jersey Mike's",
    emoji: '🥖',
    accentColor: const Color(0xFF003B73),
    mealTypes: const ['Cold Subs', 'Hot Subs', 'Wraps', 'Sides', 'Drinks'],
    builders: {
      'Cold Subs': const [
        MenuCategory(
          name: 'Size',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Mini (5")', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Regular (7")', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Giant (15")', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
        MenuCategory(
          name: 'Bread',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'White (Regular)', calories: 320, protein: 11, carbs: 60, fat: 4),
            MenuItem(name: 'Wheat (Regular)', calories: 290, protein: 11, carbs: 56, fat: 4),
            MenuItem(name: 'Rosemary Parmesan (Regular)', calories: 360, protein: 12, carbs: 62, fat: 7),
          ],
        ),
        MenuCategory(
          name: 'Sub (Regular, fillings)',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Turkey & Provolone (#7)', calories: 470, protein: 30, carbs: 60, fat: 11),
            MenuItem(name: 'Ham & Provolone (#5)', calories: 590, protein: 27, carbs: 60, fat: 26),
            MenuItem(name: 'Roast Beef & Provolone (#6)', calories: 540, protein: 32, carbs: 60, fat: 17),
            MenuItem(name: 'Original Italian (#13)', calories: 770, protein: 36, carbs: 60, fat: 41),
            MenuItem(name: "Club Sub (#9)", calories: 700, protein: 38, carbs: 60, fat: 32),
            MenuItem(name: 'Tuna (#3)', calories: 660, protein: 24, carbs: 60, fat: 33),
            MenuItem(name: 'BLT (#2)', calories: 530, protein: 17, carbs: 60, fat: 25),
            MenuItem(name: 'Veggie (#14)', calories: 490, protein: 19, carbs: 60, fat: 19),
          ],
        ),
        MenuCategory(
          name: 'Cheese (extra)',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Provolone', calories: 50, protein: 4, carbs: 0, fat: 4),
            MenuItem(name: 'American', calories: 50, protein: 3, carbs: 1, fat: 4),
            MenuItem(name: 'Swiss', calories: 50, protein: 4, carbs: 0, fat: 4),
          ],
        ),
        MenuCategory(
          name: 'Toppings',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Lettuce', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Tomato', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Onion', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Cherry Pepper Relish', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Sweet Pepper', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Mushroom', calories: 5, protein: 1, carbs: 1, fat: 0),
            MenuItem(name: 'Jalapeño', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Banana Pepper', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
        MenuCategory(
          name: 'Condiments',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: "Mike's Way (oil/vinegar + oregano + S/P)", calories: 90, protein: 0, carbs: 0, fat: 10),
            MenuItem(name: 'Mayo', calories: 90, protein: 0, carbs: 0, fat: 10),
            MenuItem(name: 'Mustard', calories: 5, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Hot Peppers', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Oregano', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
      ],
      'Hot Subs': const [
        MenuCategory(
          name: 'Size',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Mini (5")', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Regular (7")', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Giant (15")', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
        MenuCategory(
          name: 'Hot Sub',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Philly Cheesesteak (#17)', calories: 810, protein: 41, carbs: 65, fat: 39),
            MenuItem(name: 'Chicken Philly (#43)', calories: 770, protein: 47, carbs: 65, fat: 32),
            MenuItem(name: 'Grilled Chicken', calories: 600, protein: 41, carbs: 60, fat: 18),
            MenuItem(name: 'Meatball & Cheese (#26)', calories: 770, protein: 32, carbs: 65, fat: 41),
            MenuItem(name: 'Big Kahuna Cheesesteak', calories: 1060, protein: 47, carbs: 70, fat: 60),
          ],
        ),
        MenuCategory(
          name: 'Toppings',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Grilled Onion', calories: 30, protein: 0, carbs: 3, fat: 2),
            MenuItem(name: 'Grilled Pepper', calories: 25, protein: 0, carbs: 2, fat: 2),
            MenuItem(name: 'Grilled Mushroom', calories: 25, protein: 1, carbs: 2, fat: 2),
            MenuItem(name: 'Jalapeño', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
      ],
      'Wraps': const [
        MenuCategory(
          name: 'Wrap',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Wheat Tortilla Wrap', calories: 290, protein: 9, carbs: 49, fat: 7),
          ],
        ),
        MenuCategory(
          name: 'Filling',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Turkey & Provolone', calories: 420, protein: 28, carbs: 0, fat: 18),
            MenuItem(name: 'Chicken Caesar', calories: 380, protein: 30, carbs: 4, fat: 18),
            MenuItem(name: 'Ham & Provolone', calories: 450, protein: 24, carbs: 0, fat: 25),
            MenuItem(name: 'Veggie', calories: 250, protein: 11, carbs: 8, fat: 15),
          ],
        ),
      ],
      'Sides': const [
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: "Chips (Cape Cod)", calories: 150, protein: 2, carbs: 18, fat: 8),
            MenuItem(name: "Pickle Spear", calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: "Cookie (Chocolate Chunk)", calories: 350, protein: 4, carbs: 47, fat: 16),
            MenuItem(name: "Brownie", calories: 410, protein: 5, carbs: 53, fat: 21),
          ],
        ),
      ],
      'Drinks': const [
        MenuCategory(
          name: 'Drink',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Bottled Water', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Coca-Cola (M)', calories: 280, protein: 0, carbs: 78, fat: 0),
            MenuItem(name: 'Diet Coke', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Lemonade (M)', calories: 250, protein: 0, carbs: 60, fat: 0),
            MenuItem(name: 'Iced Tea (Unsweet)', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
      ],
    },
  ),

  // 18. PANERA BREAD — panerabread.com nutrition explorer.
  RestaurantMenu(
    id: 'panera',
    name: 'Panera Bread',
    emoji: '🥖',
    accentColor: const Color(0xFF6D7E1C),
    mealTypes: const ['Soups', 'Salads', 'Sandwiches', 'Mac & Cheese', 'Flatbreads', 'Bakery', 'Coffee', 'Smoothies'],
    builders: {
      'Soups': const [
        MenuCategory(
          name: 'Soup',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Broccoli Cheddar (Cup)', calories: 280, protein: 8, carbs: 17, fat: 20,
              fiber: 1, sodium: 1010,
            ),
            MenuItem(
              name: 'Broccoli Cheddar (Bowl)', calories: 420, protein: 12, carbs: 25, fat: 31,
              fiber: 1, sodium: 1520,
            ),
            MenuItem(
              name: 'Broccoli Cheddar (Bread Bowl)', calories: 930, protein: 29, carbs: 152, fat: 23,
              fiber: 6, sodium: 2350,
            ),
            MenuItem(
              name: 'Creamy Tomato (Cup)', calories: 240, protein: 3, carbs: 21, fat: 16,
              fiber: 1, sodium: 760,
            ),
            MenuItem(
              name: 'Creamy Tomato (Bowl)', calories: 340, protein: 4, carbs: 30, fat: 23,
              fiber: 1, sodium: 1110,
            ),
            MenuItem(
              name: 'Chicken Noodle (Cup)', calories: 120, protein: 10, carbs: 14, fat: 3,
              fiber: 0, sodium: 1050, vitaminCMg: 8.4,
              magnesiumMg: 24.9, zincMg: 0.7, vitaminB12Mcg: 0.1,
              folateMcg: 43,
            ),
            MenuItem(
              name: 'Chicken Noodle (Bowl)', calories: 180, protein: 14, carbs: 21, fat: 4.5,
              fiber: 0, sodium: 1570, vitaminCMg: 12.6,
              magnesiumMg: 37.4, zincMg: 1.1, vitaminB12Mcg: 0.1,
              folateMcg: 64.5,
            ),
            MenuItem(name: 'Baked Potato (Cup)', calories: 230, protein: 5, carbs: 22, fat: 13),
            MenuItem(name: 'Baked Potato (Bowl)', calories: 360, protein: 8, carbs: 34, fat: 21),
            MenuItem(name: 'Ten Vegetable (Cup)', calories: 90, protein: 4, carbs: 17, fat: 1),
            MenuItem(name: 'Ten Vegetable (Bowl)', calories: 150, protein: 6, carbs: 27, fat: 2),
          ],
        ),
      ],
      'Salads': const [
        MenuCategory(
          name: 'Salad',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Caesar (Whole)', calories: 530, protein: 14, carbs: 22, fat: 44,
              fiber: 4, sodium: 1390,
            ),
            MenuItem(
              name: 'Caesar (Half)', calories: 270, protein: 7, carbs: 11, fat: 22,
              fiber: 2, sodium: 700,
            ),
            MenuItem(
              name: 'Greek (Whole)', calories: 630, protein: 8, carbs: 17, fat: 59,
              fiber: 5, sodium: 1400,
            ),
            MenuItem(
              name: 'Greek (Half)', calories: 310, protein: 4, carbs: 9, fat: 30,
              fiber: 2, sodium: 700,
            ),
            MenuItem(
              name: 'Fuji Apple (Whole)', calories: 710, protein: 28, carbs: 49, fat: 44,
              fiber: 5, sodium: 1770,
            ),
            MenuItem(
              name: 'Fuji Apple (Half)', calories: 350, protein: 14, carbs: 24, fat: 22,
              fiber: 3, sodium: 890,
            ),
            MenuItem(
              name: 'Asian Sesame Chicken (Whole)', calories: 530, protein: 29, carbs: 35, fat: 31,
              fiber: 6, sodium: 1900,
            ),
            MenuItem(
              name: 'Asian Sesame Chicken (Half)', calories: 260, protein: 15, carbs: 17, fat: 15,
              fiber: 3, sodium: 950,
            ),
            MenuItem(name: 'BBQ Chicken (Whole)', calories: 580, protein: 33, carbs: 53, fat: 26),
            MenuItem(name: 'BBQ Chicken (Half)', calories: 290, protein: 17, carbs: 27, fat: 13),
          ],
        ),
      ],
      'Sandwiches': const [
        MenuCategory(
          name: 'Bread',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Sourdough (Whole)', calories: 270, protein: 11, carbs: 53, fat: 2),
            MenuItem(name: 'Country White (Whole)', calories: 260, protein: 10, carbs: 52, fat: 2),
            MenuItem(name: 'Whole Grain (Whole)', calories: 250, protein: 10, carbs: 47, fat: 4),
            MenuItem(name: 'Ciabatta (Whole)', calories: 280, protein: 11, carbs: 53, fat: 3),
            MenuItem(name: 'French Baguette (Whole)', calories: 290, protein: 11, carbs: 56, fat: 2),
          ],
        ),
        MenuCategory(
          name: 'Sandwich (filling)',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Turkey Bravo (Whole)', calories: 770, protein: 39, carbs: 87, fat: 28),
            MenuItem(name: 'Napa Almond Chicken (Whole)', calories: 740, protein: 32, carbs: 91, fat: 27),
            MenuItem(
              name: 'Bacon Turkey Bravo (Whole)', calories: 860, protein: 47, carbs: 80, fat: 39,
              fiber: 6, sodium: 2430,
            ),
            MenuItem(name: 'Chipotle Chicken Avocado (Whole)', calories: 820, protein: 41, carbs: 67, fat: 41),
            MenuItem(name: 'Italian (Whole)', calories: 990, protein: 43, carbs: 90, fat: 47),
            MenuItem(
              name: 'Tuna (Whole)', calories: 590, protein: 24, carbs: 60, fat: 29,
              fiber: 4, sodium: 1200,
            ),
          ],
        ),
      ],
      'Mac & Cheese': const [
        MenuCategory(
          name: 'Mac',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Mac & Cheese (Cup)', calories: 490, protein: 16, carbs: 34, fat: 32,
              fiber: 0, sodium: 1150, vitaminCMg: 0, magnesiumMg: 43.9,
              zincMg: 2.4, vitaminB12Mcg: 0.6, folateMcg: 76.9,
            ),
            MenuItem(
              name: 'Mac & Cheese (Bowl)', calories: 980, protein: 32, carbs: 68, fat: 64,
              fiber: 0, sodium: 2300, vitaminCMg: 0, magnesiumMg: 87.9,
              zincMg: 4.7, vitaminB12Mcg: 1.2, folateMcg: 153.8,
            ),
            MenuItem(name: 'Broccoli Cheddar Mac (Cup)', calories: 510, protein: 22, carbs: 48, fat: 26),
            MenuItem(name: 'Broccoli Cheddar Mac (Bowl)', calories: 1020, protein: 44, carbs: 96, fat: 52),
          ],
        ),
      ],
      'Flatbreads': const [
        MenuCategory(
          name: 'Flatbread',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Chipotle Chicken & Bacon Flatbread', calories: 840, protein: 46, carbs: 88, fat: 36),
            MenuItem(name: 'Margherita Flatbread', calories: 700, protein: 28, carbs: 86, fat: 28),
            MenuItem(name: 'Mediterranean Veggie Flatbread', calories: 730, protein: 28, carbs: 100, fat: 26),
          ],
        ),
      ],
      'Bakery': const [
        MenuCategory(
          name: 'Item',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(
              name: 'Cinnamon Crunch Bagel', calories: 430, protein: 13, carbs: 78, fat: 7,
              fiber: 3, sodium: 460,
            ),
            MenuItem(
              name: 'Everything Bagel', calories: 300, protein: 8, carbs: 61, fat: 2.5,
              fiber: 3, sodium: 720, vitaminCMg: 0, magnesiumMg: 33,
              zincMg: 0.9, vitaminB12Mcg: 0, folateMcg: 120.5,
            ),
            MenuItem(
              name: 'Plain Bagel', calories: 280, protein: 7, carbs: 59, fat: 1,
              fiber: 3, sodium: 590, vitaminCMg: 0, magnesiumMg: 30.8,
              zincMg: 0.9, vitaminB12Mcg: 0, folateMcg: 112.4,
            ),
            MenuItem(
              name: 'Kitchen Sink Cookie', calories: 810, protein: 7, carbs: 100, fat: 42,
              fiber: 3, sodium: 840,
            ),
            MenuItem(
              name: 'Chocolate Chipper Cookie', calories: 390, protein: 4, carbs: 52, fat: 18,
              fiber: 1, sodium: 330, vitaminCMg: 0, magnesiumMg: 32.5,
              zincMg: 0.6, vitaminB12Mcg: 0, folateMcg: 57.1,
            ),
            MenuItem(name: 'Pumpkin Muffin', calories: 470, protein: 5, carbs: 64, fat: 22),
            MenuItem(
              name: 'Cinnamon Roll', calories: 580, protein: 7, carbs: 97, fat: 18,
              fiber: 2, sodium: 420, vitaminCMg: 0.4, magnesiumMg: 18,
              zincMg: 0.7, vitaminB12Mcg: 0.2, folateMcg: 92.4,
            ),
          ],
        ),
      ],
      'Coffee': const [
        MenuCategory(
          name: 'Drink (Medium)',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Hot Coffee', calories: 5, protein: 1, carbs: 0, fat: 0,
              fiber: 0, sodium: 10, vitaminCMg: 0, magnesiumMg: 14.2,
              zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 9.5,
            ),
            MenuItem(
              name: 'Iced Coffee', calories: 5, protein: 0, carbs: 0, fat: 0,
              fiber: 0, sodium: 10, vitaminCMg: 0, magnesiumMg: 8.8,
              zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 5.8,
            ),
            MenuItem(
              name: 'Latte', calories: 130, protein: 8, carbs: 12, fat: 5,
              fiber: 0, sodium: 110, vitaminCMg: 0.6, magnesiumMg: 69.5,
              zincMg: 1.1, vitaminB12Mcg: 1.1, folateMcg: 6,
            ),
            MenuItem(
              name: 'Mocha', calories: 340, protein: 10, carbs: 54, fat: 10,
              fiber: 2, sodium: 170,
            ),
            MenuItem(
              name: 'Caramel Latte', calories: 320, protein: 9, carbs: 50, fat: 9,
              fiber: 0, sodium: 250,
            ),
            MenuItem(name: 'Cold Brew', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(
              name: 'Unlimited Sip Club Iced Tea', calories: 5, protein: 0, carbs: 2, fat: 0,
              fiber: 0, sodium: 20, vitaminCMg: 0, magnesiumMg: 17.7,
              zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 29.6,
            ),
          ],
        ),
      ],
      'Smoothies': const [
        MenuCategory(
          name: 'Smoothie',
          mode: SelectionMode.single,
          items: [
            MenuItem(
              name: 'Strawberry Banana Smoothie', calories: 250, protein: 7, carbs: 51, fat: 2.5,
              fiber: 4, sodium: 40,
            ),
            MenuItem(
              name: 'Mango Smoothie', calories: 300, protein: 13, carbs: 51, fat: 5,
              fiber: 1, sodium: 75,
            ),
            MenuItem(name: 'Green Passion Smoothie', calories: 270, protein: 4, carbs: 64, fat: 2),
            MenuItem(name: 'Peach & Blueberry Smoothie', calories: 320, protein: 9, carbs: 67, fat: 2),
          ],
        ),
      ],
    },
  ),

  // 19. IN-N-OUT — in-n-out.com nutrition page; secret menu items included.
  RestaurantMenu(
    id: 'innout',
    name: 'In-N-Out',
    emoji: '🌴',
    accentColor: const Color(0xFFFE001C),
    mealTypes: const ['Burgers', 'Fries', 'Shakes', 'Drinks'],
    builders: {
      'Burgers': const [
        MenuCategory(
          name: 'Burger',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Hamburger (w/ spread)', calories: 390, protein: 16, carbs: 39, fat: 19),
            MenuItem(name: 'Cheeseburger (w/ spread)', calories: 480, protein: 22, carbs: 39, fat: 27),
            MenuItem(name: 'Double-Double (w/ spread)', calories: 670, protein: 37, carbs: 39, fat: 41),
            MenuItem(name: '3x3 (Secret)', calories: 860, protein: 53, carbs: 40, fat: 56),
            MenuItem(name: '4x4 (Secret)', calories: 1050, protein: 68, carbs: 41, fat: 70),
            MenuItem(name: 'Flying Dutchman (Secret — 2 patties + 2 cheese, no bun)', calories: 380, protein: 33, carbs: 1, fat: 27),
            MenuItem(name: 'Grilled Cheese (no patty)', calories: 380, protein: 13, carbs: 41, fat: 18),
            MenuItem(name: 'Veggie Burger (Secret)', calories: 260, protein: 7, carbs: 38, fat: 10),
          ],
        ),
        MenuCategory(
          name: 'Style',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Animal Style (mustard-grill, extra spread, pickle, grilled onion)', calories: 110, protein: 1, carbs: 5, fat: 9),
            MenuItem(name: 'Protein Style (lettuce wrap, no bun) — subtracts bun', calories: -130, protein: -4, carbs: -27, fat: -2),
          ],
        ),
        MenuCategory(
          name: 'Add-ons',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Extra Spread', calories: 80, protein: 0, carbs: 2, fat: 9),
            MenuItem(name: 'Grilled Onions', calories: 25, protein: 0, carbs: 2, fat: 2),
            MenuItem(name: 'Chopped Chilis', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Extra Toast', calories: 30, protein: 1, carbs: 6, fat: 0),
            MenuItem(name: 'Extra Patty', calories: 130, protein: 13, carbs: 0, fat: 8),
          ],
        ),
        MenuCategory(
          name: 'Toppings',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Lettuce', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Tomato', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Onion (raw)', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Pickles', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Ketchup', calories: 10, protein: 0, carbs: 2, fat: 0),
            MenuItem(name: 'Mustard', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Extra Salt', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
      ],
      'Fries': const [
        MenuCategory(
          name: 'Fries',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Fries', calories: 370, protein: 7, carbs: 54, fat: 17),
            MenuItem(name: 'Well-Done Fries', calories: 410, protein: 7, carbs: 54, fat: 21),
            MenuItem(name: 'Light Fries', calories: 330, protein: 6, carbs: 50, fat: 14),
            MenuItem(name: 'Animal Style Fries (w/ cheese, spread, grilled onion)', calories: 750, protein: 18, carbs: 60, fat: 49),
            MenuItem(name: 'Cheese Fries', calories: 550, protein: 13, carbs: 55, fat: 30),
          ],
        ),
      ],
      'Shakes': const [
        MenuCategory(
          name: 'Shake (Regular 15oz)',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Chocolate Shake', calories: 590, protein: 9, carbs: 83, fat: 25),
            MenuItem(name: 'Vanilla Shake', calories: 590, protein: 9, carbs: 78, fat: 27),
            MenuItem(name: 'Strawberry Shake', calories: 590, protein: 8, carbs: 90, fat: 25),
            MenuItem(name: 'Neapolitan (Secret — all 3)', calories: 590, protein: 9, carbs: 84, fat: 26),
            MenuItem(name: 'Black & White (Secret — choc + vanilla)', calories: 590, protein: 9, carbs: 81, fat: 26),
          ],
        ),
      ],
      'Drinks': const [
        MenuCategory(
          name: 'Drink',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Coca-Cola (M)', calories: 240, protein: 0, carbs: 64, fat: 0),
            MenuItem(name: 'Diet Coke', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Dr Pepper (M)', calories: 240, protein: 0, carbs: 62, fat: 0),
            MenuItem(name: 'Sprite (M)', calories: 240, protein: 0, carbs: 60, fat: 0),
            MenuItem(name: 'Lemonade (M)', calories: 180, protein: 0, carbs: 49, fat: 0),
            MenuItem(name: 'Iced Tea (M)', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Milk', calories: 180, protein: 13, carbs: 17, fat: 7),
            MenuItem(name: 'Coffee', calories: 5, protein: 0, carbs: 1, fat: 0),
          ],
        ),
      ],
    },
  ),

  // 20. SHAKE SHACK — shakeshack.com nutrition guide.
  RestaurantMenu(
    id: 'shakeshack',
    name: 'Shake Shack',
    emoji: '🍔',
    accentColor: const Color(0xFF38A057),
    mealTypes: const ['Burgers', 'Chicken', 'Flat-Top Dogs', 'Fries', 'Shakes & Frozen', 'Drinks'],
    builders: {
      'Burgers': const [
        MenuCategory(
          name: 'Burger',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'ShackBurger (single)', calories: 530, protein: 27, carbs: 26, fat: 33),
            MenuItem(name: 'ShackBurger (double)', calories: 770, protein: 47, carbs: 27, fat: 51),
            MenuItem(name: 'SmokeShack (single)', calories: 600, protein: 30, carbs: 27, fat: 37),
            MenuItem(name: 'SmokeShack (double)', calories: 840, protein: 50, carbs: 28, fat: 55),
            MenuItem(name: 'Shack Stack (cheeseburger + Shroom)', calories: 870, protein: 42, carbs: 43, fat: 54),
            MenuItem(name: 'Hamburger (single)', calories: 440, protein: 24, carbs: 25, fat: 25),
            MenuItem(name: 'Cheeseburger (single)', calories: 500, protein: 26, carbs: 26, fat: 30),
            MenuItem(name: "'Shroom Burger (Veggie)", calories: 530, protein: 17, carbs: 51, fat: 31),
          ],
        ),
        MenuCategory(
          name: 'Toppings',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Lettuce', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Tomato', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'ShackSauce', calories: 50, protein: 0, carbs: 1, fat: 5),
            MenuItem(name: 'Pickles', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Onion', calories: 5, protein: 0, carbs: 1, fat: 0),
          ],
        ),
        MenuCategory(
          name: 'Add-ons',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Add Bacon', calories: 80, protein: 4, carbs: 0, fat: 7),
            MenuItem(name: 'Add Cherry Peppers', calories: 10, protein: 0, carbs: 2, fat: 0),
            MenuItem(name: 'Extra Cheese', calories: 60, protein: 3, carbs: 1, fat: 5),
          ],
        ),
      ],
      'Chicken': const [
        MenuCategory(
          name: 'Item',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Chicken Shack (crispy)', calories: 550, protein: 35, carbs: 50, fat: 24),
            MenuItem(name: 'Chicken Shack (grilled)', calories: 360, protein: 33, carbs: 32, fat: 11),
            MenuItem(name: 'Chicken Bites (6 pc)', calories: 290, protein: 24, carbs: 16, fat: 14),
            MenuItem(name: 'Chicken Bites (10 pc)', calories: 480, protein: 40, carbs: 27, fat: 23),
          ],
        ),
        MenuCategory(
          name: 'Sauce',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'BBQ', calories: 35, protein: 0, carbs: 8, fat: 0),
            MenuItem(name: 'Honey Mustard', calories: 80, protein: 0, carbs: 10, fat: 5),
            MenuItem(name: 'Buttermilk Herb Mayo', calories: 120, protein: 0, carbs: 1, fat: 13),
            MenuItem(name: 'Chipotle BBQ', calories: 50, protein: 0, carbs: 12, fat: 0),
          ],
        ),
      ],
      'Flat-Top Dogs': const [
        MenuCategory(
          name: 'Dog',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Shack Dog', calories: 230, protein: 11, carbs: 19, fat: 12),
            MenuItem(name: 'Smoke Dog', calories: 280, protein: 14, carbs: 21, fat: 16),
          ],
        ),
      ],
      'Fries': const [
        MenuCategory(
          name: 'Fries',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Fries', calories: 420, protein: 5, carbs: 53, fat: 22),
            MenuItem(name: 'Cheese Fries', calories: 600, protein: 12, carbs: 56, fat: 36),
            MenuItem(name: 'Bacon Cheese Fries', calories: 700, protein: 17, carbs: 56, fat: 44),
          ],
        ),
      ],
      'Shakes & Frozen': const [
        MenuCategory(
          name: 'Shake / Custard',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Vanilla Shake', calories: 690, protein: 11, carbs: 75, fat: 37),
            MenuItem(name: 'Chocolate Shake', calories: 730, protein: 12, carbs: 84, fat: 38),
            MenuItem(name: 'Strawberry Shake', calories: 660, protein: 11, carbs: 70, fat: 36),
            MenuItem(name: 'Peanut Butter Shake', calories: 780, protein: 17, carbs: 71, fat: 47),
            MenuItem(name: 'Cookies & Cream Shake', calories: 770, protein: 13, carbs: 84, fat: 42),
            MenuItem(name: 'Black & White Shake', calories: 710, protein: 12, carbs: 80, fat: 37),
            MenuItem(name: 'Vanilla Custard (Cup)', calories: 290, protein: 5, carbs: 28, fat: 17),
            MenuItem(name: 'Chocolate Custard (Cup)', calories: 320, protein: 5, carbs: 32, fat: 19),
            MenuItem(name: 'Vanilla Custard (Cone)', calories: 320, protein: 6, carbs: 34, fat: 17),
            MenuItem(name: 'Chocolate Custard (Cone)', calories: 360, protein: 6, carbs: 38, fat: 19),
          ],
        ),
      ],
      'Drinks': const [
        MenuCategory(
          name: 'Drink',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Lemonade', calories: 290, protein: 0, carbs: 73, fat: 0),
            MenuItem(name: 'Fifty/Fifty (Lemonade + Iced Tea)', calories: 140, protein: 0, carbs: 36, fat: 0),
            MenuItem(name: 'Iced Tea (Unsweet)', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Fresh Brewed Coffee', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Bottled Water', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Fountain Soda (M)', calories: 220, protein: 0, carbs: 58, fat: 0),
          ],
        ),
      ],
    },
  ),

  // 21. SONIC — sonicdrivein.com nutrition guide.
  RestaurantMenu(
    id: 'sonic',
    name: 'Sonic',
    emoji: '🥤',
    accentColor: const Color(0xFF1A3683),
    mealTypes: const ['Burgers', 'Chicken', 'Hot Dogs', 'Tots & Fries', 'Shakes & Slushes', 'Breakfast', 'Drinks'],
    builders: {
      'Burgers': const [
        MenuCategory(
          name: 'Burger',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Sonic Cheeseburger (single)', calories: 640, protein: 26, carbs: 53, fat: 36),
            MenuItem(name: 'Sonic Cheeseburger (double)', calories: 940, protein: 49, carbs: 54, fat: 57),
            MenuItem(name: 'SuperSONIC Bacon Double Cheeseburger', calories: 1070, protein: 56, carbs: 55, fat: 67),
            MenuItem(name: 'Jr Burger', calories: 320, protein: 13, carbs: 31, fat: 16),
            MenuItem(name: 'Quarter Pound Double Cheeseburger', calories: 760, protein: 37, carbs: 53, fat: 44),
          ],
        ),
        MenuCategory(
          name: 'Toppings',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Lettuce', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Tomato', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Pickles', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Onion', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Mayo', calories: 90, protein: 0, carbs: 1, fat: 10),
            MenuItem(name: 'Mustard', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Ketchup', calories: 10, protein: 0, carbs: 2, fat: 0),
          ],
        ),
      ],
      'Chicken': const [
        MenuCategory(
          name: 'Item',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Classic Crispy Chicken Sandwich', calories: 620, protein: 28, carbs: 60, fat: 32),
            MenuItem(name: 'Jumbo Popcorn Chicken (Reg)', calories: 510, protein: 26, carbs: 30, fat: 32),
            MenuItem(name: 'Jumbo Popcorn Chicken (Lrg)', calories: 770, protein: 39, carbs: 46, fat: 48),
            MenuItem(name: 'Chicken Strips (3 pc)', calories: 380, protein: 20, carbs: 19, fat: 25),
            MenuItem(name: 'Chicken Strips (5 pc)', calories: 640, protein: 33, carbs: 32, fat: 41),
          ],
        ),
      ],
      'Hot Dogs': const [
        MenuCategory(
          name: 'Dog',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'All-American Dog', calories: 350, protein: 11, carbs: 31, fat: 20),
            MenuItem(name: 'Chili Cheese Coney', calories: 460, protein: 16, carbs: 34, fat: 29),
            MenuItem(name: 'New York Dog', calories: 450, protein: 13, carbs: 35, fat: 27),
            MenuItem(name: 'Chicago Dog', calories: 480, protein: 14, carbs: 41, fat: 28),
          ],
        ),
      ],
      'Tots & Fries': const [
        MenuCategory(
          name: 'Item',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Tots (Reg)', calories: 280, protein: 3, carbs: 35, fat: 14),
            MenuItem(name: 'Tots (Lrg)', calories: 470, protein: 5, carbs: 58, fat: 23),
            MenuItem(name: 'Cheese Tots (Reg)', calories: 390, protein: 8, carbs: 38, fat: 23),
            MenuItem(name: 'Chili Cheese Tots (Reg)', calories: 460, protein: 13, carbs: 41, fat: 27),
            MenuItem(name: 'Fries (Reg)', calories: 320, protein: 4, carbs: 44, fat: 14),
            MenuItem(name: 'Fries (Lrg)', calories: 540, protein: 6, carbs: 73, fat: 24),
            MenuItem(name: 'Mozzarella Sticks (4)', calories: 440, protein: 17, carbs: 40, fat: 22),
            MenuItem(name: 'Onion Rings (Reg)', calories: 330, protein: 5, carbs: 47, fat: 13),
          ],
        ),
      ],
      'Shakes & Slushes': const [
        MenuCategory(
          name: 'Shake or Slush',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Vanilla Shake (Reg)', calories: 540, protein: 9, carbs: 75, fat: 23),
            MenuItem(name: 'Chocolate Shake (Reg)', calories: 590, protein: 9, carbs: 89, fat: 22),
            MenuItem(name: 'Strawberry Shake (Reg)', calories: 550, protein: 9, carbs: 81, fat: 22),
            MenuItem(name: 'Peanut Butter Shake (Reg)', calories: 720, protein: 16, carbs: 75, fat: 41),
            MenuItem(name: 'Oreo Shake (Reg)', calories: 690, protein: 11, carbs: 90, fat: 31),
            MenuItem(name: "Reese's Shake (Reg)", calories: 750, protein: 14, carbs: 88, fat: 39),
            MenuItem(name: 'Cherry Slush (Reg)', calories: 220, protein: 0, carbs: 60, fat: 0),
            MenuItem(name: 'Blue Raspberry Slush (Reg)', calories: 230, protein: 0, carbs: 63, fat: 0),
            MenuItem(name: 'Grape Slush (Reg)', calories: 230, protein: 0, carbs: 62, fat: 0),
            MenuItem(name: 'Lemon-Berry Slush (Reg)', calories: 230, protein: 0, carbs: 64, fat: 0),
            MenuItem(name: 'Orange Slush (Reg)', calories: 230, protein: 0, carbs: 62, fat: 0),
            MenuItem(name: 'Slush (RT44 / 44oz)', calories: 460, protein: 0, carbs: 125, fat: 0),
          ],
        ),
      ],
      'Breakfast': const [
        MenuCategory(
          name: 'Entree',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Breakfast Burrito', calories: 580, protein: 18, carbs: 49, fat: 35),
            MenuItem(name: 'Breakfast Toaster (Sausage)', calories: 670, protein: 23, carbs: 47, fat: 43),
            MenuItem(name: 'Breakfast Toaster (Bacon)', calories: 560, protein: 21, carbs: 47, fat: 32),
            MenuItem(name: 'CinnaSnacks (5 pc)', calories: 530, protein: 7, carbs: 81, fat: 20),
            MenuItem(name: 'French Toast Sticks (4 pc)', calories: 480, protein: 6, carbs: 64, fat: 22),
          ],
        ),
      ],
      'Drinks': const [
        MenuCategory(
          name: 'Drink',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Coca-Cola (Reg)', calories: 220, protein: 0, carbs: 61, fat: 0),
            MenuItem(name: 'Diet Coke', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Cherry Limeade (Reg)', calories: 220, protein: 0, carbs: 60, fat: 0),
            MenuItem(name: 'Limeade (Reg)', calories: 200, protein: 0, carbs: 55, fat: 0),
            MenuItem(name: 'Iced Tea (Sweet, Reg)', calories: 140, protein: 0, carbs: 36, fat: 0),
            MenuItem(name: 'Iced Tea (Unsweet, Reg)', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Water', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
      ],
    },
  ),

  // 22. QDOBA — qdoba.com nutrition (queso/guac are FREE add-ons on entrees).
  RestaurantMenu(
    id: 'qdoba',
    name: 'Qdoba',
    emoji: '🌯',
    accentColor: const Color(0xFF94081E),
    mealTypes: const ['Burrito', 'Bowl', 'Tacos', 'Quesadilla', 'Nachos', 'Salad'],
    builders: {
      'Burrito': const [
        MenuCategory(
          name: 'Tortilla',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Flour Tortilla', calories: 300, protein: 8, carbs: 50, fat: 8),
            MenuItem(name: 'Whole Wheat Tortilla', calories: 290, protein: 9, carbs: 48, fat: 8),
          ],
        ),
        MenuCategory(
          name: 'Rice',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Cilantro Lime Rice', calories: 170, protein: 4, carbs: 36, fat: 2),
            MenuItem(name: 'Brown Rice', calories: 180, protein: 4, carbs: 35, fat: 2),
          ],
        ),
        MenuCategory(
          name: 'Beans',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Black Beans', calories: 110, protein: 7, carbs: 22, fat: 1),
            MenuItem(name: 'Pinto Beans', calories: 120, protein: 7, carbs: 22, fat: 1),
          ],
        ),
        MenuCategory(
          name: 'Protein',
          mode: SelectionMode.single,
          allowDouble: true,
          allowHalfHalf: true,
          items: [
            MenuItem(name: 'Grilled Chicken', calories: 190, protein: 32, carbs: 1, fat: 7),
            MenuItem(name: 'Steak', calories: 220, protein: 26, carbs: 1, fat: 12),
            MenuItem(name: 'Ground Beef', calories: 200, protein: 19, carbs: 3, fat: 12),
            MenuItem(name: 'Pulled Pork', calories: 230, protein: 21, carbs: 8, fat: 13),
            MenuItem(name: 'Brisket', calories: 260, protein: 22, carbs: 6, fat: 16),
            MenuItem(name: 'Plant-Based Impossible', calories: 200, protein: 16, carbs: 9, fat: 12),
            MenuItem(name: 'No Protein', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
        MenuCategory(
          name: 'Queso (FREE w/ entree)',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: '3-Cheese Queso', calories: 130, protein: 6, carbs: 5, fat: 10),
            MenuItem(name: 'Queso Diablo', calories: 130, protein: 6, carbs: 5, fat: 10),
          ],
        ),
        MenuCategory(
          name: 'Toppings',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Fajita Veggies', calories: 25, protein: 1, carbs: 5, fat: 0),
            MenuItem(name: 'Pico de Gallo', calories: 10, protein: 0, carbs: 2, fat: 0),
            MenuItem(name: 'Corn Salsa', calories: 70, protein: 2, carbs: 16, fat: 0),
            MenuItem(name: 'Roasted Tomato Salsa', calories: 20, protein: 1, carbs: 4, fat: 0),
            MenuItem(name: 'Salsa Verde', calories: 15, protein: 0, carbs: 3, fat: 0),
            MenuItem(name: 'Sour Cream', calories: 110, protein: 2, carbs: 2, fat: 11),
            MenuItem(name: 'Guacamole (FREE w/ entree)', calories: 140, protein: 2, carbs: 8, fat: 12),
            MenuItem(name: 'Cheese', calories: 110, protein: 7, carbs: 1, fat: 9),
            MenuItem(name: 'Lettuce', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Jalapeños', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
        MenuCategory(
          name: 'Extras',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Tortilla Chips (side)', calories: 220, protein: 3, carbs: 28, fat: 10),
            MenuItem(name: 'Chips & 3-Cheese Queso', calories: 350, protein: 9, carbs: 33, fat: 20),
            MenuItem(name: 'Chips & Guacamole', calories: 360, protein: 5, carbs: 36, fat: 22),
          ],
        ),
      ],
      'Bowl': const [
        MenuCategory(
          name: 'Rice',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Cilantro Lime Rice', calories: 170, protein: 4, carbs: 36, fat: 2),
            MenuItem(name: 'Brown Rice', calories: 180, protein: 4, carbs: 35, fat: 2),
          ],
        ),
        MenuCategory(
          name: 'Beans',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Black Beans', calories: 110, protein: 7, carbs: 22, fat: 1),
            MenuItem(name: 'Pinto Beans', calories: 120, protein: 7, carbs: 22, fat: 1),
          ],
        ),
        MenuCategory(
          name: 'Protein',
          mode: SelectionMode.single,
          allowDouble: true,
          allowHalfHalf: true,
          items: [
            MenuItem(name: 'Grilled Chicken', calories: 190, protein: 32, carbs: 1, fat: 7),
            MenuItem(name: 'Steak', calories: 220, protein: 26, carbs: 1, fat: 12),
            MenuItem(name: 'Ground Beef', calories: 200, protein: 19, carbs: 3, fat: 12),
            MenuItem(name: 'Pulled Pork', calories: 230, protein: 21, carbs: 8, fat: 13),
            MenuItem(name: 'Brisket', calories: 260, protein: 22, carbs: 6, fat: 16),
            MenuItem(name: 'Plant-Based Impossible', calories: 200, protein: 16, carbs: 9, fat: 12),
            MenuItem(name: 'No Protein', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
        MenuCategory(
          name: 'Toppings',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Fajita Veggies', calories: 25, protein: 1, carbs: 5, fat: 0),
            MenuItem(name: 'Pico de Gallo', calories: 10, protein: 0, carbs: 2, fat: 0),
            MenuItem(name: 'Corn Salsa', calories: 70, protein: 2, carbs: 16, fat: 0),
            MenuItem(name: 'Salsa Verde', calories: 15, protein: 0, carbs: 3, fat: 0),
            MenuItem(name: 'Sour Cream', calories: 110, protein: 2, carbs: 2, fat: 11),
            MenuItem(name: 'Guacamole (FREE w/ entree)', calories: 140, protein: 2, carbs: 8, fat: 12),
            MenuItem(name: '3-Cheese Queso (FREE w/ entree)', calories: 130, protein: 6, carbs: 5, fat: 10),
            MenuItem(name: 'Cheese', calories: 110, protein: 7, carbs: 1, fat: 9),
            MenuItem(name: 'Lettuce', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Jalapeños', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
      ],
      'Tacos': const [
        MenuCategory(
          name: 'Tortilla (3 tacos)',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Soft Flour (×3)', calories: 270, protein: 9, carbs: 45, fat: 6),
            MenuItem(name: 'Crispy Corn (×3)', calories: 210, protein: 3, carbs: 27, fat: 9),
          ],
        ),
        MenuCategory(
          name: 'Protein',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Grilled Chicken', calories: 190, protein: 32, carbs: 1, fat: 7),
            MenuItem(name: 'Steak', calories: 220, protein: 26, carbs: 1, fat: 12),
            MenuItem(name: 'Ground Beef', calories: 200, protein: 19, carbs: 3, fat: 12),
            MenuItem(name: 'Pulled Pork', calories: 230, protein: 21, carbs: 8, fat: 13),
            MenuItem(name: 'Plant-Based Impossible', calories: 200, protein: 16, carbs: 9, fat: 12),
          ],
        ),
        MenuCategory(
          name: 'Toppings',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Pico de Gallo', calories: 10, protein: 0, carbs: 2, fat: 0),
            MenuItem(name: 'Sour Cream', calories: 110, protein: 2, carbs: 2, fat: 11),
            MenuItem(name: 'Guacamole', calories: 140, protein: 2, carbs: 8, fat: 12),
            MenuItem(name: 'Cheese', calories: 110, protein: 7, carbs: 1, fat: 9),
            MenuItem(name: 'Lettuce', calories: 5, protein: 0, carbs: 1, fat: 0),
          ],
        ),
      ],
      'Quesadilla': const [
        MenuCategory(
          name: 'Tortilla + Cheese',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Flour Tortilla + Cheese', calories: 540, protein: 22, carbs: 47, fat: 27),
          ],
        ),
        MenuCategory(
          name: 'Protein',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Grilled Chicken', calories: 190, protein: 32, carbs: 1, fat: 7),
            MenuItem(name: 'Steak', calories: 220, protein: 26, carbs: 1, fat: 12),
            MenuItem(name: 'Pulled Pork', calories: 230, protein: 21, carbs: 8, fat: 13),
            MenuItem(name: 'No Protein', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
      ],
      'Nachos': const [
        MenuCategory(
          name: 'Chips',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Tortilla Chips (Loaded Nachos Base)', calories: 400, protein: 6, carbs: 51, fat: 18),
          ],
        ),
        MenuCategory(
          name: 'Protein',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Grilled Chicken', calories: 190, protein: 32, carbs: 1, fat: 7),
            MenuItem(name: 'Steak', calories: 220, protein: 26, carbs: 1, fat: 12),
            MenuItem(name: 'Pulled Pork', calories: 230, protein: 21, carbs: 8, fat: 13),
          ],
        ),
        MenuCategory(
          name: 'Toppings',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: '3-Cheese Queso', calories: 130, protein: 6, carbs: 5, fat: 10),
            MenuItem(name: 'Cheese', calories: 110, protein: 7, carbs: 1, fat: 9),
            MenuItem(name: 'Pico de Gallo', calories: 10, protein: 0, carbs: 2, fat: 0),
            MenuItem(name: 'Sour Cream', calories: 110, protein: 2, carbs: 2, fat: 11),
            MenuItem(name: 'Guacamole', calories: 140, protein: 2, carbs: 8, fat: 12),
            MenuItem(name: 'Jalapeños', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
      ],
      'Salad': const [
        MenuCategory(
          name: 'Base',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Romaine Lettuce', calories: 10, protein: 1, carbs: 2, fat: 0),
          ],
        ),
        MenuCategory(
          name: 'Protein',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Grilled Chicken', calories: 190, protein: 32, carbs: 1, fat: 7),
            MenuItem(name: 'Steak', calories: 220, protein: 26, carbs: 1, fat: 12),
            MenuItem(name: 'Plant-Based Impossible', calories: 200, protein: 16, carbs: 9, fat: 12),
          ],
        ),
        MenuCategory(
          name: 'Dressing',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Lime Cilantro Vinaigrette', calories: 170, protein: 0, carbs: 6, fat: 17),
            MenuItem(name: 'Ancho Chile Ranch', calories: 230, protein: 1, carbs: 2, fat: 24),
            MenuItem(name: 'Avocado Salsa Verde', calories: 220, protein: 1, carbs: 3, fat: 22),
            MenuItem(name: 'Picante Ranch', calories: 240, protein: 1, carbs: 2, fat: 25),
          ],
        ),
      ],
    },
  ),

  // 23. TROPICAL SMOOTHIE CAFE — tropicalsmoothiecafe.com nutrition (24oz default).
  RestaurantMenu(
    id: 'tropicalsmoothie',
    name: 'Tropical Smoothie Cafe',
    emoji: '🥤',
    accentColor: const Color(0xFF008A6A),
    mealTypes: const ['Smoothies', 'Flatbreads', 'Wraps', 'Bowls', 'Sandwiches', 'Sides'],
    builders: {
      'Smoothies': const [
        MenuCategory(
          name: 'Smoothie (24oz)',
          mode: SelectionMode.single,
          items: [
            // Fruit / Classic
            MenuItem(name: 'Island Green', calories: 220, protein: 2, carbs: 53, fat: 1),
            MenuItem(name: 'Sunrise Sunset', calories: 320, protein: 2, carbs: 79, fat: 1),
            MenuItem(name: 'Bahama Mama', calories: 460, protein: 4, carbs: 112, fat: 2),
            MenuItem(name: 'Mango Magic', calories: 340, protein: 2, carbs: 81, fat: 1),
            MenuItem(name: 'Pomegranate Plunge', calories: 320, protein: 2, carbs: 78, fat: 1),
            // Indulgent
            MenuItem(name: 'Peanut Butter Cup', calories: 800, protein: 22, carbs: 86, fat: 41),
            MenuItem(name: 'Mocha Madness', calories: 580, protein: 14, carbs: 78, fat: 23),
            MenuItem(name: 'Chocolate Banana', calories: 650, protein: 12, carbs: 92, fat: 26),
            // Balanced
            MenuItem(name: 'Detox Island Green', calories: 290, protein: 3, carbs: 71, fat: 1),
            MenuItem(name: 'Avocolada', calories: 480, protein: 5, carbs: 78, fat: 18),
            MenuItem(name: 'Beach Bum', calories: 450, protein: 6, carbs: 95, fat: 8),
          ],
        ),
        MenuCategory(
          name: 'Size Adjustment',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: '24oz (default)', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: '32oz (+33% cal)', calories: 110, protein: 1, carbs: 25, fat: 1),
            MenuItem(name: '44oz (+83% cal)', calories: 260, protein: 2, carbs: 60, fat: 2),
          ],
        ),
        MenuCategory(
          name: 'Boosts',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Whey Protein (per scoop)', calories: 90, protein: 18, carbs: 3, fat: 1),
            MenuItem(name: 'Plant Protein (per scoop)', calories: 90, protein: 15, carbs: 6, fat: 2),
            MenuItem(name: 'Fat Burner Boost', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Energy Boost', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Immunity Boost', calories: 30, protein: 0, carbs: 7, fat: 0),
            MenuItem(name: 'Multi-Vitamin Boost', calories: 25, protein: 0, carbs: 6, fat: 0),
            MenuItem(name: 'Chia Seeds', calories: 60, protein: 2, carbs: 5, fat: 4),
          ],
        ),
      ],
      'Flatbreads': const [
        MenuCategory(
          name: 'Flatbread',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Chipotle Chicken Club Flatbread', calories: 620, protein: 28, carbs: 56, fat: 31),
            MenuItem(name: 'Buffalo Chicken Flatbread', calories: 660, protein: 26, carbs: 55, fat: 36),
            MenuItem(name: 'Turkey Bacon Ranch Flatbread', calories: 600, protein: 31, carbs: 53, fat: 28),
            MenuItem(name: 'Pesto Veggie Flatbread', calories: 580, protein: 22, carbs: 60, fat: 28),
          ],
        ),
      ],
      'Wraps': const [
        MenuCategory(
          name: 'Wrap',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Thai Chicken Wrap', calories: 660, protein: 32, carbs: 67, fat: 28),
            MenuItem(name: 'Baja Chicken Wrap', calories: 680, protein: 32, carbs: 64, fat: 30),
            MenuItem(name: 'Hummus Veggie Wrap', calories: 560, protein: 18, carbs: 73, fat: 22),
            MenuItem(name: 'Buffalo Chicken Wrap', calories: 700, protein: 30, carbs: 65, fat: 33),
          ],
        ),
      ],
      'Bowls': const [
        MenuCategory(
          name: 'Bowl',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Açaí Primo Bowl', calories: 470, protein: 8, carbs: 88, fat: 11),
            MenuItem(name: 'Chia Banana Pudding Bowl', calories: 360, protein: 9, carbs: 64, fat: 9),
            MenuItem(name: 'Sunrise Smoothie Bowl', calories: 410, protein: 7, carbs: 85, fat: 6),
          ],
        ),
      ],
      'Sandwiches': const [
        MenuCategory(
          name: 'Sandwich',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Chicken Caesar Sandwich', calories: 570, protein: 30, carbs: 50, fat: 28),
            MenuItem(name: 'Turkey Avocado Sandwich', calories: 530, protein: 28, carbs: 52, fat: 24),
          ],
        ),
      ],
      'Sides': const [
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Sun Chips', calories: 210, protein: 4, carbs: 28, fat: 10),
            MenuItem(name: 'Pickle Spear', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Apple', calories: 80, protein: 0, carbs: 21, fat: 0),
          ],
        ),
      ],
    },
  ),

  // 24. JAMBA — jamba.com nutrition (medium 22oz default).
  RestaurantMenu(
    id: 'jamba',
    name: 'Jamba',
    emoji: '🧃',
    accentColor: const Color(0xFFFA9326),
    mealTypes: const ['Smoothies', 'Bowls', 'Shots', 'Bites', 'Juices'],
    builders: {
      'Smoothies': const [
        MenuCategory(
          name: 'Smoothie (Medium / 22oz)',
          mode: SelectionMode.single,
          items: [
            // Classics
            MenuItem(name: 'Caribbean Passion', calories: 320, protein: 3, carbs: 76, fat: 1),
            MenuItem(name: 'Mango-a-Go-Go', calories: 350, protein: 3, carbs: 81, fat: 1),
            MenuItem(name: 'Razzmatazz', calories: 320, protein: 3, carbs: 74, fat: 1),
            MenuItem(name: 'Aloha Pineapple', calories: 350, protein: 6, carbs: 78, fat: 2),
            MenuItem(name: 'Orange Dream Machine', calories: 380, protein: 11, carbs: 79, fat: 2),
            // Protein
            MenuItem(name: 'PB Banana Protein', calories: 490, protein: 28, carbs: 64, fat: 14),
            MenuItem(name: 'Chocolate Protein', calories: 380, protein: 22, carbs: 61, fat: 7),
            MenuItem(name: 'Vanilla Protein', calories: 400, protein: 22, carbs: 65, fat: 7),
            // Plant-Based
            MenuItem(name: "Greens 'n Ginger", calories: 220, protein: 3, carbs: 53, fat: 1),
            MenuItem(name: 'PB&J Protein (plant)', calories: 470, protein: 24, carbs: 65, fat: 14),
            MenuItem(name: 'Mega Mango', calories: 270, protein: 2, carbs: 67, fat: 1),
          ],
        ),
        MenuCategory(
          name: 'Size Adjustment',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Small 16oz (–25% cal)', calories: -90, protein: -2, carbs: -20, fat: -1),
            MenuItem(name: 'Medium 22oz (default)', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Large 28oz (+25% cal)', calories: 90, protein: 2, carbs: 20, fat: 1),
          ],
        ),
        MenuCategory(
          name: 'Boosts',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Whey Protein Boost', calories: 80, protein: 18, carbs: 1, fat: 1),
            MenuItem(name: 'Plant Protein Boost', calories: 80, protein: 14, carbs: 5, fat: 1),
            MenuItem(name: 'Immunity Boost', calories: 35, protein: 0, carbs: 9, fat: 0),
            MenuItem(name: 'Energy Boost', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Daily Vitamin Boost', calories: 25, protein: 0, carbs: 6, fat: 0),
          ],
        ),
      ],
      'Bowls': const [
        MenuCategory(
          name: 'Bowl',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Açaí Primo Bowl', calories: 490, protein: 10, carbs: 95, fat: 9),
            MenuItem(name: 'Island Pitaya Bowl', calories: 470, protein: 9, carbs: 95, fat: 7),
            MenuItem(name: 'Chunky Strawberry Bowl', calories: 470, protein: 9, carbs: 95, fat: 8),
            MenuItem(name: 'Vanilla Blue Sky Bowl', calories: 490, protein: 8, carbs: 100, fat: 7),
          ],
        ),
      ],
      'Shots': const [
        MenuCategory(
          name: 'Shot',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Ginger Shot (2oz)', calories: 50, protein: 0, carbs: 13, fat: 0),
            MenuItem(name: 'Wheatgrass Shot (1oz)', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Immunity Shot', calories: 50, protein: 0, carbs: 12, fat: 0),
            MenuItem(name: 'Turmeric Shot', calories: 25, protein: 0, carbs: 6, fat: 0),
          ],
        ),
      ],
      'Bites': const [
        MenuCategory(
          name: 'Bite',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Peanut Butter Vibe', calories: 220, protein: 6, carbs: 26, fat: 11),
            MenuItem(name: 'Chocolate Chip Cookie', calories: 290, protein: 4, carbs: 39, fat: 14),
          ],
        ),
      ],
      'Juices': const [
        MenuCategory(
          name: 'Juice',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Fresh Orange Juice (16oz)', calories: 220, protein: 4, carbs: 51, fat: 1),
            MenuItem(name: 'Apple Juice (16oz)', calories: 230, protein: 0, carbs: 56, fat: 0),
            MenuItem(name: 'Carrot Juice (16oz)', calories: 130, protein: 4, carbs: 30, fat: 1),
            MenuItem(name: 'Mighty Veggie Juice (16oz)', calories: 170, protein: 5, carbs: 38, fat: 1),
          ],
        ),
      ],
    },
  ),

  // 25. WAWA — wawa.com nutrition (built-to-order hoagies).
  RestaurantMenu(
    id: 'wawa',
    name: 'Wawa',
    emoji: '🦆',
    accentColor: const Color(0xFFC8102E),
    mealTypes: const ['Hoagies', 'Breakfast', 'Bowls', 'Sides', 'Drinks', 'Bakery'],
    builders: {
      'Hoagies': const [
        MenuCategory(
          name: 'Size',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Junior (4")', calories: 200, protein: 7, carbs: 39, fat: 2),
            MenuItem(name: 'Shorti (6")', calories: 280, protein: 10, carbs: 54, fat: 3),
            MenuItem(name: 'Classic (10")', calories: 460, protein: 16, carbs: 89, fat: 5),
          ],
        ),
        MenuCategory(
          name: 'Style',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Cold', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Hot (Toasted)', calories: 30, protein: 0, carbs: 0, fat: 3),
          ],
        ),
        MenuCategory(
          name: 'Meat (Shorti portion)',
          mode: SelectionMode.multiple,
          maxSelections: 2,
          items: [
            MenuItem(name: 'Turkey', calories: 80, protein: 14, carbs: 2, fat: 2),
            MenuItem(name: 'Ham', calories: 80, protein: 14, carbs: 2, fat: 2),
            MenuItem(name: 'Roast Beef', calories: 100, protein: 17, carbs: 2, fat: 3),
            MenuItem(name: 'Italian (Capicola/Salami/Pepperoni)', calories: 200, protein: 12, carbs: 1, fat: 16),
            MenuItem(name: 'Meatball', calories: 280, protein: 16, carbs: 18, fat: 17),
            MenuItem(name: 'Cheesesteak', calories: 270, protein: 22, carbs: 4, fat: 18),
            MenuItem(name: 'Chicken Cheesesteak', calories: 220, protein: 28, carbs: 3, fat: 11),
            MenuItem(name: 'Buffalo Chicken', calories: 250, protein: 28, carbs: 7, fat: 13),
            MenuItem(name: 'Tuna', calories: 200, protein: 10, carbs: 0, fat: 17),
          ],
        ),
        MenuCategory(
          name: 'Cheese',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'American', calories: 60, protein: 4, carbs: 1, fat: 5),
            MenuItem(name: 'Provolone', calories: 60, protein: 5, carbs: 0, fat: 5),
            MenuItem(name: 'Swiss', calories: 60, protein: 5, carbs: 0, fat: 5),
            MenuItem(name: 'Pepper Jack', calories: 60, protein: 4, carbs: 0, fat: 5),
          ],
        ),
        MenuCategory(
          name: 'Toppings',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Lettuce', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Tomato', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Onion', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Pickles', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Sweet Peppers', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Hot Peppers', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
        MenuCategory(
          name: 'Condiments',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Oil', calories: 90, protein: 0, carbs: 0, fat: 10),
            MenuItem(name: 'Vinegar', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Oregano', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Salt', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Pepper', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Mayo', calories: 90, protein: 0, carbs: 1, fat: 10),
            MenuItem(name: 'Mustard', calories: 5, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Honey Mustard', calories: 30, protein: 0, carbs: 7, fat: 0),
          ],
        ),
      ],
      'Breakfast': const [
        MenuCategory(
          name: 'Bread',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'English Muffin', calories: 130, protein: 5, carbs: 25, fat: 2),
            MenuItem(name: 'Croissant', calories: 320, protein: 6, carbs: 33, fat: 18),
            MenuItem(name: 'Bagel (Plain)', calories: 280, protein: 11, carbs: 56, fat: 1),
          ],
        ),
        MenuCategory(
          name: 'Protein (Sizzli)',
          mode: SelectionMode.multiple,
          maxSelections: 2,
          items: [
            MenuItem(name: 'Egg', calories: 80, protein: 6, carbs: 1, fat: 6),
            MenuItem(name: 'Sausage', calories: 200, protein: 8, carbs: 1, fat: 18),
            MenuItem(name: 'Bacon (2 strips)', calories: 60, protein: 4, carbs: 0, fat: 5),
            MenuItem(name: 'Turkey Sausage', calories: 90, protein: 9, carbs: 1, fat: 6),
            MenuItem(name: 'Ham', calories: 50, protein: 8, carbs: 0, fat: 1),
          ],
        ),
        MenuCategory(
          name: 'Cheese',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'American', calories: 60, protein: 4, carbs: 1, fat: 5),
            MenuItem(name: 'Cheddar', calories: 60, protein: 4, carbs: 0, fat: 5),
          ],
        ),
        MenuCategory(
          name: 'Extras',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Breakfast Burrito (Sausage Egg Cheese)', calories: 540, protein: 22, carbs: 47, fat: 28),
            MenuItem(name: 'Breakfast Burrito (Bacon Egg Cheese)', calories: 470, protein: 20, carbs: 47, fat: 22),
            MenuItem(name: 'Oatmeal (Apple Cinnamon)', calories: 280, protein: 6, carbs: 60, fat: 3),
            MenuItem(name: 'Oatmeal (Brown Sugar)', calories: 290, protein: 6, carbs: 63, fat: 3),
            MenuItem(name: 'Hash Browns', calories: 230, protein: 2, carbs: 25, fat: 14),
          ],
        ),
      ],
      'Bowls': const [
        MenuCategory(
          name: 'Bowl',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Mac & Cheese (Side)', calories: 320, protein: 13, carbs: 38, fat: 13),
            MenuItem(name: 'Mac & Cheese (Bowl)', calories: 640, protein: 26, carbs: 76, fat: 26),
            MenuItem(name: 'Chicken Noodle Soup (Cup)', calories: 110, protein: 6, carbs: 16, fat: 2),
            MenuItem(name: 'Chicken Noodle Soup (Bowl)', calories: 170, protein: 9, carbs: 24, fat: 4),
            MenuItem(name: 'Mashed Potato Bowl (Chicken)', calories: 590, protein: 32, carbs: 70, fat: 21),
          ],
        ),
      ],
      'Sides': const [
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Pretzel (Soft)', calories: 380, protein: 11, carbs: 78, fat: 4),
            MenuItem(name: 'Bag of Chips', calories: 160, protein: 2, carbs: 15, fat: 10),
            MenuItem(name: 'Mozzarella Sticks (5)', calories: 410, protein: 17, carbs: 31, fat: 23),
            MenuItem(name: 'Apple Sauce Pouch', calories: 60, protein: 0, carbs: 15, fat: 0),
          ],
        ),
      ],
      'Drinks': const [
        MenuCategory(
          name: 'Smoothie (24oz built-to-order)',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Strawberry Banana Smoothie', calories: 360, protein: 5, carbs: 79, fat: 3),
            MenuItem(name: 'Tropical Fruit Smoothie', calories: 380, protein: 4, carbs: 86, fat: 2),
            MenuItem(name: 'Peanut Butter Banana Smoothie', calories: 520, protein: 11, carbs: 83, fat: 18),
          ],
        ),
        MenuCategory(
          name: 'Coffee (M / 16oz)',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Original Coffee', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Latte (Whole Milk)', calories: 160, protein: 8, carbs: 14, fat: 8),
            MenuItem(name: 'Cappuccino', calories: 90, protein: 5, carbs: 8, fat: 5),
            MenuItem(name: 'Mocha Latte', calories: 290, protein: 9, carbs: 41, fat: 11),
            MenuItem(name: 'Iced Coffee', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Cold Brew', calories: 5, protein: 0, carbs: 1, fat: 0),
          ],
        ),
        // Add-milk options model the milk/cream ADDED to a black coffee (the
        // default coffees above — Original, Iced, Cold Brew — are black).
        // Previously milk was a negative "swap" delta mixed into the add-ins,
        // which under-counted every coffee with milk. Values are Wawa medium
        // (16 oz) milk/cream additions, matching the Dunkin' builder. Pick
        // "Black / No Milk" for drinks already made with milk (Latte,
        // Cappuccino) so the milk isn't double-counted.
        MenuCategory(
          name: 'Add Milk / Cream',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Black / No Milk', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Whole Milk', calories: 70, protein: 4, carbs: 5, fat: 4),
            MenuItem(name: 'Skim Milk', calories: 45, protein: 4, carbs: 7, fat: 0),
            MenuItem(name: 'Oat Milk', calories: 65, protein: 1, carbs: 11, fat: 2),
            MenuItem(name: 'Almond Milk', calories: 25, protein: 1, carbs: 1, fat: 2),
            MenuItem(name: 'Coconut Milk', calories: 25, protein: 0, carbs: 2, fat: 2),
            MenuItem(name: 'Cream', calories: 110, protein: 2, carbs: 3, fat: 10),
          ],
        ),
        MenuCategory(
          name: 'Coffee Add-ins',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Vanilla Syrup', calories: 40, protein: 0, carbs: 10, fat: 0),
            MenuItem(name: 'Caramel Syrup', calories: 40, protein: 0, carbs: 10, fat: 0),
            MenuItem(name: 'Hazelnut Syrup', calories: 40, protein: 0, carbs: 10, fat: 0),
          ],
        ),
      ],
      'Bakery': const [
        MenuCategory(
          name: 'Item',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Chocolate Chip Cookie', calories: 320, protein: 3, carbs: 45, fat: 14),
            MenuItem(name: 'Sticky Bun', calories: 460, protein: 5, carbs: 68, fat: 18),
            MenuItem(name: 'Brownie', calories: 360, protein: 4, carbs: 47, fat: 18),
            MenuItem(name: 'Apple Fritter', calories: 540, protein: 6, carbs: 76, fat: 23),
          ],
        ),
      ],
    },
  ),

  // ──────────────────────────────────────────────────────────────────
  // API-search restaurants (Spoonacular-backed). These chains have
  // 200+ items / heavily-seasonal menus where hand-modelling is more
  // brittle than letting users search by item name. Tapping any of
  // these in the browser opens the menu-item search screen with the
  // restaurant name pre-filled in the query.
  // ──────────────────────────────────────────────────────────────────
  RestaurantMenu(
    id: 'applebees',
    name: "Applebee's",
    emoji: '🍎',
    accentColor: const Color(0xFF339933),
    searchOnly: true,
  ),
  RestaurantMenu(
    id: 'buffalowildwings',
    name: 'Buffalo Wild Wings',
    emoji: '🦬',
    accentColor: const Color(0xFFFFC400),
    searchOnly: true,
  ),
  RestaurantMenu(
    id: 'cheesecakefactory',
    name: 'Cheesecake Factory',
    emoji: '🍰',
    accentColor: const Color(0xFF6B4423),
    searchOnly: true,
  ),
  RestaurantMenu(
    id: 'chilis',
    name: "Chili's",
    emoji: '🌶️',
    accentColor: const Color(0xFFE4002B),
    searchOnly: true,
  ),
  RestaurantMenu(
    id: 'crackerbarrel',
    name: 'Cracker Barrel',
    emoji: '🪵',
    accentColor: const Color(0xFFC5942A),
    searchOnly: true,
  ),
  RestaurantMenu(
    id: 'dennys',
    name: "Denny's",
    emoji: '☕',
    accentColor: const Color(0xFFFFCD00),
    searchOnly: true,
  ),
  RestaurantMenu(
    id: 'ihop',
    name: 'IHOP',
    emoji: '🥞',
    accentColor: const Color(0xFF003DA5),
    searchOnly: true,
  ),
  RestaurantMenu(
    id: 'olivegarden',
    name: 'Olive Garden',
    emoji: '🫒',
    accentColor: const Color(0xFF8B0000),
    searchOnly: true,
  ),
  RestaurantMenu(
    id: 'outback',
    name: 'Outback Steakhouse',
    emoji: '🥩',
    accentColor: const Color(0xFF841B2D),
    searchOnly: true,
  ),
  RestaurantMenu(
    id: 'pfchangs',
    name: "P.F. Chang's",
    emoji: '🥡',
    accentColor: const Color(0xFF8B0000),
    searchOnly: true,
  ),
  RestaurantMenu(
    id: 'redlobster',
    name: 'Red Lobster',
    emoji: '🦞',
    accentColor: const Color(0xFFC40824),
    searchOnly: true,
  ),
  RestaurantMenu(
    id: 'tgifridays',
    name: "TGI Friday's",
    emoji: '🍹',
    accentColor: const Color(0xFFC8102E),
    searchOnly: true,
  ),
  // Generic catch-all — empty searchSeed so the user starts with a
  // blank query and can search any restaurant or food item.
  RestaurantMenu(
    id: 'other',
    name: 'Other Restaurant',
    emoji: '🔍',
    accentColor: const Color(0xFF6B6B6B),
    searchOnly: true,
    searchSeed: '',
  ),
];

/// Lookup helper — returns null if no restaurant matches the id.
RestaurantMenu? restaurantById(String id) {
  for (final r in restaurantMenus) {
    if (r.id == id) return r;
  }
  return null;
}
