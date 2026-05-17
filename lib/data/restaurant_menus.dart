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
  });

  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sodium;
}

enum SelectionMode { single, multiple }

/// A logical step in a meal builder — "pick a rice", "pick a protein",
/// "add toppings". A category can be optional (e.g. cheese on a sandwich)
/// or required (e.g. you must pick exactly one protein for a bowl).
class MenuCategory {
  const MenuCategory({
    required this.name,
    required this.mode,
    this.optional = false,
    required this.items,
  });

  final String name;
  final SelectionMode mode;
  final bool optional;
  final List<MenuItem> items;
}

/// One restaurant. Holds shared branding (emoji, accent color) and a map of
/// meal-type → category list. Meal types are the high-level "what am I
/// building" choice (Burrito vs Bowl vs Tacos at Chipotle).
class RestaurantMenu {
  const RestaurantMenu({
    required this.id,
    required this.name,
    required this.emoji,
    required this.accentColor,
    required this.mealTypes,
    required this.builders,
  });

  final String id;
  final String name;
  final String emoji;
  final Color accentColor;
  final List<String> mealTypes;
  final Map<String, List<MenuCategory>> builders;
}

// ─────────────────────────────────────────────────────────────────────
// Shared building-blocks reused across the Chipotle builders
// ─────────────────────────────────────────────────────────────────────
const _chipotleRice = MenuCategory(
  name: 'Rice',
  mode: SelectionMode.single,
  optional: true,
  items: [
    MenuItem(name: 'White Rice', calories: 210, protein: 4, carbs: 36, fat: 6),
    MenuItem(name: 'Brown Rice', calories: 210, protein: 4, carbs: 36, fat: 6),
    MenuItem(name: 'Cauliflower Rice', calories: 40, protein: 2, carbs: 4, fat: 2),
  ],
);

const _chipotleBeans = MenuCategory(
  name: 'Beans',
  mode: SelectionMode.single,
  optional: true,
  items: [
    MenuItem(name: 'Black Beans', calories: 130, protein: 8, carbs: 22, fat: 1),
    MenuItem(name: 'Pinto Beans', calories: 130, protein: 8, carbs: 22, fat: 1),
  ],
);

const _chipotleProtein = MenuCategory(
  name: 'Protein',
  mode: SelectionMode.single,
  items: [
    MenuItem(name: 'Chicken', calories: 180, protein: 32, carbs: 0, fat: 7),
    MenuItem(name: 'Steak', calories: 150, protein: 21, carbs: 1, fat: 6),
    MenuItem(name: 'Barbacoa', calories: 170, protein: 24, carbs: 2, fat: 7),
    MenuItem(name: 'Carnitas', calories: 210, protein: 23, carbs: 0, fat: 12),
    MenuItem(name: 'Sofritas', calories: 150, protein: 8, carbs: 9, fat: 10),
    MenuItem(name: 'Chicken Al Pastor', calories: 210, protein: 31, carbs: 3, fat: 8),
    MenuItem(name: 'Veggie (no protein)', calories: 0, protein: 0, carbs: 0, fat: 0),
  ],
);

const _chipotleToppings = MenuCategory(
  name: 'Toppings',
  mode: SelectionMode.multiple,
  items: [
    MenuItem(name: 'Fajita Veggies', calories: 20, protein: 1, carbs: 4, fat: 0),
    MenuItem(name: 'Fresh Tomato Salsa', calories: 25, protein: 1, carbs: 4, fat: 0),
    MenuItem(name: 'Roasted Chili-Corn Salsa', calories: 80, protein: 3, carbs: 16, fat: 2),
    MenuItem(name: 'Tomatillo-Green Chili Salsa', calories: 15, protein: 1, carbs: 3, fat: 0),
    MenuItem(name: 'Tomatillo-Red Chili Salsa', calories: 30, protein: 1, carbs: 4, fat: 1),
    MenuItem(name: 'Sour Cream', calories: 110, protein: 2, carbs: 2, fat: 9),
    MenuItem(name: 'Cheese', calories: 110, protein: 6, carbs: 1, fat: 9),
    MenuItem(name: 'Guacamole', calories: 230, protein: 2, carbs: 8, fat: 22),
    MenuItem(name: 'Queso Blanco', calories: 120, protein: 5, carbs: 4, fat: 9),
    MenuItem(name: 'Romaine Lettuce', calories: 5, protein: 0, carbs: 1, fat: 0),
  ],
);

const _chipotleSides = MenuCategory(
  name: 'Side',
  mode: SelectionMode.single,
  optional: true,
  items: [
    MenuItem(name: 'Chips', calories: 540, protein: 7, carbs: 73, fat: 25),
    MenuItem(name: 'Chips & Guac', calories: 770, protein: 9, carbs: 81, fat: 47),
    MenuItem(name: 'Chips & Queso', calories: 660, protein: 12, carbs: 77, fat: 34),
    MenuItem(name: 'Chips & Salsa (Mild)', calories: 565, protein: 8, carbs: 77, fat: 25),
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
            MenuItem(name: 'Flour Tortilla', calories: 300, protein: 8, carbs: 50, fat: 8),
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
            MenuItem(name: 'Soft Flour (×3)', calories: 270, protein: 9, carbs: 45, fat: 6),
            MenuItem(name: 'Crispy Corn (×3)', calories: 210, protein: 3, carbs: 27, fat: 9),
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
            MenuItem(name: 'Romaine Lettuce', calories: 5, protein: 0, carbs: 1, fat: 0),
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
            MenuItem(name: 'Chipotle-Honey Vinaigrette', calories: 220, protein: 1, carbs: 18, fat: 16),
          ],
        ),
      ],
      'Quesadilla': const [
        MenuCategory(
          name: 'Tortilla & Cheese',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Flour Tortilla + Cheese', calories: 530, protein: 22, carbs: 47, fat: 27),
          ],
        ),
        _chipotleProtein,
        MenuCategory(
          name: 'Side Salsa',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Fresh Tomato Salsa', calories: 25, protein: 1, carbs: 4, fat: 0),
            MenuItem(name: 'Sour Cream', calories: 110, protein: 2, carbs: 2, fat: 9),
            MenuItem(name: 'Guacamole', calories: 230, protein: 2, carbs: 8, fat: 22),
          ],
        ),
      ],
    },
  ),

  // 2. SUBWAY — 6-inch sandwich values from subway.com; footlong = ×2.
  RestaurantMenu(
    id: 'subway',
    name: 'Subway',
    emoji: '🥪',
    accentColor: const Color(0xFF008C15),
    mealTypes: const ['6-inch Sub', 'Footlong Sub', 'Wrap', 'Salad'],
    builders: {
      '6-inch Sub': const [
        MenuCategory(
          name: 'Bread',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Italian White', calories: 200, protein: 8, carbs: 38, fat: 2),
            MenuItem(name: '9-Grain Wheat', calories: 210, protein: 9, carbs: 39, fat: 3),
            MenuItem(name: 'Italian Herbs & Cheese', calories: 250, protein: 11, carbs: 39, fat: 6),
            MenuItem(name: 'Hearty Multigrain', calories: 220, protein: 9, carbs: 41, fat: 3),
          ],
        ),
        MenuCategory(
          name: 'Protein',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Turkey Breast', calories: 60, protein: 12, carbs: 2, fat: 1),
            MenuItem(name: 'Black Forest Ham', calories: 60, protein: 11, carbs: 2, fat: 1),
            MenuItem(name: 'Rotisserie-Style Chicken', calories: 130, protein: 21, carbs: 2, fat: 4),
            MenuItem(name: 'Roast Beef', calories: 80, protein: 14, carbs: 2, fat: 2),
            MenuItem(name: 'Tuna', calories: 250, protein: 13, carbs: 0, fat: 21),
            MenuItem(name: 'Steak', calories: 110, protein: 17, carbs: 4, fat: 3),
            MenuItem(name: 'Meatball Marinara', calories: 280, protein: 14, carbs: 22, fat: 14),
            MenuItem(name: 'Veggie Patty', calories: 100, protein: 9, carbs: 12, fat: 3),
          ],
        ),
        MenuCategory(
          name: 'Cheese',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'American', calories: 40, protein: 2, carbs: 1, fat: 4),
            MenuItem(name: 'Provolone', calories: 50, protein: 4, carbs: 0, fat: 4),
            MenuItem(name: 'Pepper Jack', calories: 50, protein: 4, carbs: 0, fat: 4),
            MenuItem(name: 'Swiss', calories: 50, protein: 4, carbs: 0, fat: 4),
            MenuItem(name: 'Shredded Monterey Cheddar', calories: 50, protein: 4, carbs: 0, fat: 4),
          ],
        ),
        MenuCategory(
          name: 'Veggies',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Lettuce', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Tomato', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Onion', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Bell Peppers', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Cucumber', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Spinach', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Pickles', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Banana Peppers', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Jalapeños', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Olives', calories: 10, protein: 0, carbs: 1, fat: 1),
            MenuItem(name: 'Avocado', calories: 60, protein: 1, carbs: 3, fat: 5),
          ],
        ),
        MenuCategory(
          name: 'Sauce',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Mayonnaise', calories: 100, protein: 0, carbs: 0, fat: 11),
            MenuItem(name: 'Light Mayonnaise', calories: 50, protein: 0, carbs: 1, fat: 5),
            MenuItem(name: 'Honey Mustard', calories: 30, protein: 0, carbs: 7, fat: 0),
            MenuItem(name: 'Mustard', calories: 5, protein: 0, carbs: 1, fat: 0),
            MenuItem(name: 'Sweet Onion', calories: 35, protein: 0, carbs: 8, fat: 0),
            MenuItem(name: 'Chipotle Southwest', calories: 90, protein: 0, carbs: 1, fat: 10),
            MenuItem(name: 'Ranch', calories: 110, protein: 1, carbs: 1, fat: 11),
            MenuItem(name: 'Buffalo Sauce', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Oil & Vinegar', calories: 45, protein: 0, carbs: 0, fat: 5),
          ],
        ),
      ],
      'Footlong Sub': const [
        // Same as 6-inch but doubled; the data here is the per-foot serving.
        MenuCategory(
          name: 'Bread',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Italian White', calories: 400, protein: 16, carbs: 76, fat: 4),
            MenuItem(name: '9-Grain Wheat', calories: 420, protein: 18, carbs: 78, fat: 6),
            MenuItem(name: 'Italian Herbs & Cheese', calories: 500, protein: 22, carbs: 78, fat: 12),
          ],
        ),
        MenuCategory(
          name: 'Protein (×2)',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Turkey Breast', calories: 120, protein: 24, carbs: 4, fat: 2),
            MenuItem(name: 'Black Forest Ham', calories: 120, protein: 22, carbs: 4, fat: 2),
            MenuItem(name: 'Rotisserie-Style Chicken', calories: 260, protein: 42, carbs: 4, fat: 8),
            MenuItem(name: 'Tuna', calories: 500, protein: 26, carbs: 0, fat: 42),
            MenuItem(name: 'Steak', calories: 220, protein: 34, carbs: 8, fat: 6),
          ],
        ),
      ],
      'Wrap': const [
        MenuCategory(
          name: 'Wrap',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Tomato Basil Wrap', calories: 310, protein: 12, carbs: 50, fat: 7),
            MenuItem(name: 'Spinach Wrap', calories: 290, protein: 11, carbs: 49, fat: 6),
          ],
        ),
        MenuCategory(
          name: 'Protein',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Rotisserie Chicken', calories: 130, protein: 21, carbs: 2, fat: 4),
            MenuItem(name: 'Turkey Breast', calories: 60, protein: 12, carbs: 2, fat: 1),
            MenuItem(name: 'Steak', calories: 110, protein: 17, carbs: 4, fat: 3),
          ],
        ),
      ],
      'Salad': const [
        MenuCategory(
          name: 'Base',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Mixed Greens', calories: 50, protein: 3, carbs: 9, fat: 1),
          ],
        ),
        MenuCategory(
          name: 'Protein',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Rotisserie Chicken', calories: 130, protein: 21, carbs: 2, fat: 4),
            MenuItem(name: 'Turkey Breast', calories: 60, protein: 12, carbs: 2, fat: 1),
            MenuItem(name: 'Tuna', calories: 250, protein: 13, carbs: 0, fat: 21),
          ],
        ),
      ],
    },
  ),

  // 3. McDONALD'S — based on mcdonalds.com nutrition explorer.
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
            MenuItem(name: 'Hamburger', calories: 250, protein: 12, carbs: 31, fat: 9),
            MenuItem(name: 'Cheeseburger', calories: 300, protein: 15, carbs: 32, fat: 13),
            MenuItem(name: 'Double Cheeseburger', calories: 450, protein: 25, carbs: 34, fat: 24),
            MenuItem(name: 'McDouble', calories: 400, protein: 22, carbs: 33, fat: 20),
            MenuItem(name: 'Quarter Pounder w/ Cheese', calories: 520, protein: 30, carbs: 42, fat: 26),
            MenuItem(name: 'Double Quarter Pounder w/ Cheese', calories: 740, protein: 48, carbs: 43, fat: 42),
            MenuItem(name: 'Big Mac', calories: 590, protein: 25, carbs: 46, fat: 34),
          ],
        ),
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Small Fries', calories: 230, protein: 3, carbs: 29, fat: 11),
            MenuItem(name: 'Medium Fries', calories: 320, protein: 4, carbs: 43, fat: 15),
            MenuItem(name: 'Large Fries', calories: 480, protein: 6, carbs: 63, fat: 23),
            MenuItem(name: 'Apple Slices', calories: 15, protein: 0, carbs: 4, fat: 0),
            MenuItem(name: 'Side Salad', calories: 15, protein: 1, carbs: 3, fat: 0),
          ],
        ),
        MenuCategory(
          name: 'Drink',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Small Coke', calories: 200, protein: 0, carbs: 55, fat: 0),
            MenuItem(name: 'Medium Coke', calories: 290, protein: 0, carbs: 78, fat: 0),
            MenuItem(name: 'Large Coke', calories: 380, protein: 0, carbs: 100, fat: 0),
            MenuItem(name: 'Diet Coke', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Sprite (Medium)', calories: 280, protein: 0, carbs: 77, fat: 0),
            MenuItem(name: 'Iced Tea (Unsweet)', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Water', calories: 0, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Coffee (Small)', calories: 0, protein: 0, carbs: 0, fat: 0),
          ],
        ),
      ],
      'Chicken Meal': const [
        MenuCategory(
          name: 'Entree',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'McChicken', calories: 400, protein: 14, carbs: 39, fat: 21),
            MenuItem(name: 'Spicy McChicken', calories: 410, protein: 14, carbs: 40, fat: 22),
            MenuItem(name: 'McCrispy', calories: 470, protein: 27, carbs: 46, fat: 20),
            MenuItem(name: 'Spicy McCrispy', calories: 480, protein: 27, carbs: 46, fat: 21),
            MenuItem(name: 'McNuggets (4 pc)', calories: 170, protein: 9, carbs: 11, fat: 10),
            MenuItem(name: 'McNuggets (6 pc)', calories: 250, protein: 14, carbs: 16, fat: 15),
            MenuItem(name: 'McNuggets (10 pc)', calories: 410, protein: 23, carbs: 26, fat: 24),
            MenuItem(name: 'McNuggets (20 pc)', calories: 830, protein: 47, carbs: 53, fat: 49),
          ],
        ),
        MenuCategory(
          name: 'Dipping Sauce',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Tangy BBQ Sauce', calories: 45, protein: 0, carbs: 11, fat: 0),
            MenuItem(name: 'Sweet ʼn Sour', calories: 50, protein: 0, carbs: 12, fat: 0),
            MenuItem(name: 'Honey Mustard', calories: 60, protein: 0, carbs: 9, fat: 3),
            MenuItem(name: 'Ranch', calories: 110, protein: 0, carbs: 2, fat: 12),
            MenuItem(name: 'Spicy Buffalo', calories: 30, protein: 0, carbs: 1, fat: 3),
            MenuItem(name: 'Honey', calories: 50, protein: 0, carbs: 12, fat: 0),
          ],
        ),
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Small Fries', calories: 230, protein: 3, carbs: 29, fat: 11),
            MenuItem(name: 'Medium Fries', calories: 320, protein: 4, carbs: 43, fat: 15),
            MenuItem(name: 'Large Fries', calories: 480, protein: 6, carbs: 63, fat: 23),
          ],
        ),
      ],
      'Breakfast': const [
        MenuCategory(
          name: 'Entree',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Egg McMuffin', calories: 310, protein: 17, carbs: 30, fat: 13),
            MenuItem(name: 'Sausage McMuffin w/ Egg', calories: 480, protein: 21, carbs: 30, fat: 31),
            MenuItem(name: 'Bacon, Egg & Cheese Biscuit', calories: 460, protein: 19, carbs: 38, fat: 26),
            MenuItem(name: 'Sausage Biscuit w/ Egg', calories: 530, protein: 18, carbs: 36, fat: 35),
            MenuItem(name: 'Big Breakfast', calories: 740, protein: 28, carbs: 56, fat: 48),
            MenuItem(name: 'Hotcakes (3)', calories: 590, protein: 9, carbs: 105, fat: 14),
            MenuItem(name: 'Sausage Burrito', calories: 310, protein: 12, carbs: 26, fat: 17),
          ],
        ),
        MenuCategory(
          name: 'Add-on',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Hash Browns', calories: 150, protein: 1, carbs: 15, fat: 9),
            MenuItem(name: 'Sausage Patty', calories: 170, protein: 7, carbs: 1, fat: 16),
          ],
        ),
      ],
      'A La Carte': const [
        MenuCategory(
          name: 'Item',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Apple Pie', calories: 230, protein: 2, carbs: 36, fat: 11),
            MenuItem(name: 'McFlurry M&M (Snack)', calories: 430, protein: 9, carbs: 67, fat: 14),
            MenuItem(name: 'Vanilla Cone', calories: 200, protein: 5, carbs: 32, fat: 5),
            MenuItem(name: 'Hot Fudge Sundae', calories: 320, protein: 7, carbs: 50, fat: 9),
            MenuItem(name: 'Chocolate Chip Cookie', calories: 170, protein: 2, carbs: 22, fat: 8),
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
            MenuItem(name: 'Original Chicken Sandwich', calories: 420, protein: 28, carbs: 41, fat: 17),
            MenuItem(name: 'Deluxe Chicken Sandwich', calories: 490, protein: 31, carbs: 42, fat: 21),
            MenuItem(name: 'Spicy Chicken Sandwich', calories: 450, protein: 28, carbs: 42, fat: 19),
            MenuItem(name: 'Spicy Deluxe Sandwich', calories: 540, protein: 32, carbs: 44, fat: 26),
            MenuItem(name: 'Grilled Chicken Sandwich', calories: 320, protein: 28, carbs: 41, fat: 6),
            MenuItem(name: 'Chicken Club Sandwich', calories: 520, protein: 35, carbs: 41, fat: 23),
          ],
        ),
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Waffle Fries (Small)', calories: 320, protein: 4, carbs: 38, fat: 17),
            MenuItem(name: 'Waffle Fries (Medium)', calories: 420, protein: 5, carbs: 49, fat: 24),
            MenuItem(name: 'Waffle Fries (Large)', calories: 600, protein: 7, carbs: 70, fat: 33),
            MenuItem(name: 'Mac & Cheese', calories: 270, protein: 12, carbs: 25, fat: 14),
            MenuItem(name: 'Fruit Cup', calories: 60, protein: 1, carbs: 16, fat: 0),
            MenuItem(name: 'Side Salad', calories: 160, protein: 8, carbs: 11, fat: 9),
            MenuItem(name: 'Chicken Noodle Soup', calories: 255, protein: 14, carbs: 27, fat: 9),
          ],
        ),
        MenuCategory(
          name: 'Sauce',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Chick-fil-A Sauce', calories: 140, protein: 0, carbs: 6, fat: 13),
            MenuItem(name: 'Polynesian Sauce', calories: 110, protein: 0, carbs: 17, fat: 5),
            MenuItem(name: 'Honey Mustard', calories: 45, protein: 0, carbs: 10, fat: 0),
            MenuItem(name: 'Garden Herb Ranch', calories: 140, protein: 0, carbs: 1, fat: 15),
            MenuItem(name: 'BBQ Sauce', calories: 45, protein: 0, carbs: 11, fat: 0),
            MenuItem(name: 'Buffalo Sauce', calories: 15, protein: 0, carbs: 1, fat: 1),
            MenuItem(name: 'Sriracha Sauce', calories: 70, protein: 0, carbs: 10, fat: 4),
          ],
        ),
      ],
      'Nuggets Meal': const [
        MenuCategory(
          name: 'Nuggets',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Nuggets (5 ct)', calories: 130, protein: 14, carbs: 6, fat: 6),
            MenuItem(name: 'Nuggets (8 ct)', calories: 250, protein: 27, carbs: 11, fat: 11),
            MenuItem(name: 'Nuggets (12 ct)', calories: 380, protein: 40, carbs: 17, fat: 17),
            MenuItem(name: 'Nuggets (30 ct)', calories: 950, protein: 100, carbs: 42, fat: 42),
            MenuItem(name: 'Grilled Nuggets (8 ct)', calories: 130, protein: 25, carbs: 1, fat: 3),
            MenuItem(name: 'Grilled Nuggets (12 ct)', calories: 200, protein: 38, carbs: 2, fat: 4),
          ],
        ),
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Waffle Fries (Medium)', calories: 420, protein: 5, carbs: 49, fat: 24),
            MenuItem(name: 'Mac & Cheese', calories: 270, protein: 12, carbs: 25, fat: 14),
            MenuItem(name: 'Fruit Cup', calories: 60, protein: 1, carbs: 16, fat: 0),
          ],
        ),
        MenuCategory(
          name: 'Sauce',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Chick-fil-A Sauce', calories: 140, protein: 0, carbs: 6, fat: 13),
            MenuItem(name: 'Polynesian Sauce', calories: 110, protein: 0, carbs: 17, fat: 5),
            MenuItem(name: 'Honey Mustard', calories: 45, protein: 0, carbs: 10, fat: 0),
            MenuItem(name: 'BBQ Sauce', calories: 45, protein: 0, carbs: 11, fat: 0),
          ],
        ),
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
            MenuItem(name: 'Avocado Lime Ranch', calories: 310, protein: 1, carbs: 4, fat: 32),
            MenuItem(name: 'Garlic & Herb Ranch', calories: 280, protein: 1, carbs: 2, fat: 30),
            MenuItem(name: 'Light Italian', calories: 25, protein: 0, carbs: 4, fat: 1),
            MenuItem(name: 'Zesty Apple Cider Vinaigrette', calories: 140, protein: 0, carbs: 16, fat: 9),
          ],
        ),
      ],
      'Breakfast': const [
        MenuCategory(
          name: 'Entree',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Chicken Biscuit', calories: 460, protein: 19, carbs: 47, fat: 23),
            MenuItem(name: 'Spicy Chicken Biscuit', calories: 470, protein: 19, carbs: 49, fat: 23),
            MenuItem(name: 'Chick-n-Minis (4 ct)', calories: 370, protein: 17, carbs: 38, fat: 16),
            MenuItem(name: 'Hash Brown Scramble Burrito', calories: 700, protein: 30, carbs: 53, fat: 41),
            MenuItem(name: 'Bacon Egg & Cheese Biscuit', calories: 460, protein: 20, carbs: 39, fat: 25),
            MenuItem(name: 'Egg White Grill', calories: 290, protein: 26, carbs: 30, fat: 7),
          ],
        ),
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Hash Browns', calories: 240, protein: 2, carbs: 26, fat: 15),
            MenuItem(name: 'Fruit Cup', calories: 60, protein: 1, carbs: 16, fat: 0),
            MenuItem(name: 'Greek Yogurt Parfait', calories: 230, protein: 11, carbs: 37, fat: 5),
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
            MenuItem(name: 'Crunchy Taco', calories: 170, protein: 8, carbs: 13, fat: 9),
            MenuItem(name: 'Crunchy Taco Supreme', calories: 200, protein: 9, carbs: 15, fat: 12),
            MenuItem(name: 'Soft Taco (Beef)', calories: 180, protein: 9, carbs: 18, fat: 8),
            MenuItem(name: 'Soft Taco Supreme', calories: 210, protein: 10, carbs: 21, fat: 10),
            MenuItem(name: 'Doritos Locos Taco', calories: 170, protein: 8, carbs: 13, fat: 9),
            MenuItem(name: 'Doritos Locos Taco Supreme', calories: 200, protein: 9, carbs: 16, fat: 11),
            MenuItem(name: 'Spicy Potato Soft Taco', calories: 230, protein: 6, carbs: 28, fat: 11),
          ],
        ),
      ],
      'Burritos': const [
        MenuCategory(
          name: 'Burrito',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Bean Burrito', calories: 350, protein: 13, carbs: 54, fat: 9),
            MenuItem(name: 'Burrito Supreme (Beef)', calories: 390, protein: 16, carbs: 51, fat: 13),
            MenuItem(name: 'Chicken Burrito (Cantina)', calories: 460, protein: 25, carbs: 57, fat: 14),
            MenuItem(name: '5-Layer Burrito', calories: 490, protein: 17, carbs: 65, fat: 18),
            MenuItem(name: 'Grilled Cheese Burrito', calories: 720, protein: 27, carbs: 81, fat: 32),
            MenuItem(name: 'Crunchwrap Supreme', calories: 530, protein: 16, carbs: 71, fat: 21),
            MenuItem(name: 'Quesarito', calories: 650, protein: 21, carbs: 67, fat: 33),
          ],
        ),
        MenuCategory(
          name: 'Add-On',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Add Guacamole', calories: 50, protein: 1, carbs: 3, fat: 5),
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
            MenuItem(name: 'Power Menu Bowl (Veggie)', calories: 430, protein: 13, carbs: 56, fat: 18),
            MenuItem(name: 'Black Bean Burrito Bowl', calories: 400, protein: 14, carbs: 65, fat: 11),
          ],
        ),
      ],
      'Quesadilla': const [
        MenuCategory(
          name: 'Quesadilla',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Cheese Quesadilla', calories: 470, protein: 19, carbs: 39, fat: 26),
            MenuItem(name: 'Chicken Quesadilla', calories: 520, protein: 28, carbs: 39, fat: 28),
            MenuItem(name: 'Steak Quesadilla', calories: 520, protein: 26, carbs: 39, fat: 29),
          ],
        ),
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Cinnamon Twists', calories: 170, protein: 1, carbs: 27, fat: 6),
            MenuItem(name: 'Chips & Nacho Cheese', calories: 230, protein: 4, carbs: 28, fat: 11),
            MenuItem(name: 'Cheesy Fiesta Potatoes', calories: 220, protein: 4, carbs: 29, fat: 12),
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
            MenuItem(name: 'Brewed Coffee', calories: 5, protein: 1, carbs: 0, fat: 0),
            MenuItem(name: 'Caffè Americano', calories: 15, protein: 1, carbs: 3, fat: 0),
            MenuItem(name: 'Caffè Latte (2% Milk)', calories: 190, protein: 13, carbs: 18, fat: 7),
            MenuItem(name: 'Cappuccino (2% Milk)', calories: 140, protein: 9, carbs: 13, fat: 5),
            MenuItem(name: 'Caffè Mocha (2% Milk)', calories: 360, protein: 14, carbs: 44, fat: 14),
            MenuItem(name: 'Caramel Macchiato (2% Milk)', calories: 250, protein: 10, carbs: 35, fat: 7),
            MenuItem(name: 'Pumpkin Spice Latte (2% Milk)', calories: 390, protein: 14, carbs: 52, fat: 14),
            MenuItem(name: 'Chai Tea Latte (2% Milk)', calories: 240, protein: 8, carbs: 45, fat: 4),
            MenuItem(name: 'White Chocolate Mocha (2%)', calories: 430, protein: 15, carbs: 53, fat: 18),
            MenuItem(name: 'Hot Chocolate (2% Milk)', calories: 370, protein: 14, carbs: 43, fat: 16),
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
            MenuItem(name: 'Extra Shot Espresso', calories: 5, protein: 1, carbs: 0, fat: 0),
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
            MenuItem(name: 'Iced Caffè Americano', calories: 15, protein: 1, carbs: 3, fat: 0),
            MenuItem(name: 'Iced Caffè Latte (2%)', calories: 130, protein: 9, carbs: 13, fat: 5),
            MenuItem(name: 'Iced Caramel Macchiato (2%)', calories: 250, protein: 10, carbs: 35, fat: 7),
            MenuItem(name: 'Iced Brown Sugar Oatmilk Shaken Espresso', calories: 120, protein: 1, carbs: 24, fat: 3),
            MenuItem(name: 'Iced Shaken Espresso', calories: 100, protein: 2, carbs: 14, fat: 4),
            MenuItem(name: 'Cold Brew (Black)', calories: 5, protein: 0, carbs: 0, fat: 0),
            MenuItem(name: 'Vanilla Sweet Cream Cold Brew', calories: 110, protein: 1, carbs: 14, fat: 6),
            MenuItem(name: 'Pink Drink', calories: 140, protein: 1, carbs: 27, fat: 3),
            MenuItem(name: 'Mango Dragonfruit Refresher', calories: 90, protein: 0, carbs: 21, fat: 0),
          ],
        ),
      ],
      'Frappuccinos': const [
        MenuCategory(
          name: 'Frappuccino (Grande)',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Caramel Frappuccino', calories: 380, protein: 4, carbs: 54, fat: 16),
            MenuItem(name: 'Mocha Frappuccino', calories: 370, protein: 5, carbs: 54, fat: 15),
            MenuItem(name: 'Java Chip Frappuccino', calories: 440, protein: 6, carbs: 63, fat: 19),
            MenuItem(name: 'Vanilla Bean Crème Frappuccino', calories: 410, protein: 6, carbs: 64, fat: 14),
            MenuItem(name: 'Strawberry Crème Frappuccino', calories: 370, protein: 6, carbs: 60, fat: 12),
            MenuItem(name: 'Matcha Crème Frappuccino', calories: 420, protein: 7, carbs: 64, fat: 14),
          ],
        ),
      ],
      'Food': const [
        MenuCategory(
          name: 'Item',
          mode: SelectionMode.multiple,
          items: [
            MenuItem(name: 'Butter Croissant', calories: 280, protein: 5, carbs: 31, fat: 14),
            MenuItem(name: 'Chocolate Croissant', calories: 310, protein: 6, carbs: 35, fat: 16),
            MenuItem(name: 'Banana Bread Slice', calories: 420, protein: 6, carbs: 56, fat: 19),
            MenuItem(name: 'Blueberry Muffin', calories: 380, protein: 6, carbs: 53, fat: 16),
            MenuItem(name: 'Bacon Gouda Sandwich', calories: 360, protein: 19, carbs: 33, fat: 18),
            MenuItem(name: 'Spinach Feta Wrap', calories: 290, protein: 19, carbs: 33, fat: 10),
            MenuItem(name: 'Sausage & Cheddar Sandwich', calories: 470, protein: 19, carbs: 41, fat: 25),
            MenuItem(name: 'Turkey Bacon Egg White Sandwich', calories: 230, protein: 17, carbs: 28, fat: 5),
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
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Chow Mein', calories: 510, protein: 13, carbs: 80, fat: 20),
            MenuItem(name: 'Fried Rice', calories: 520, protein: 11, carbs: 85, fat: 16),
            MenuItem(name: 'White Steamed Rice', calories: 380, protein: 7, carbs: 87, fat: 0),
            MenuItem(name: 'Brown Steamed Rice', calories: 420, protein: 9, carbs: 86, fat: 4),
            MenuItem(name: 'Super Greens', calories: 90, protein: 6, carbs: 10, fat: 3),
            MenuItem(name: 'Half Chow Mein + Half Greens', calories: 300, protein: 10, carbs: 45, fat: 12),
          ],
        ),
        MenuCategory(
          name: 'Entree',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Orange Chicken', calories: 510, protein: 25, carbs: 51, fat: 23),
            MenuItem(name: 'Beijing Beef', calories: 480, protein: 14, carbs: 47, fat: 27),
            MenuItem(name: 'Honey Walnut Shrimp', calories: 360, protein: 13, carbs: 35, fat: 19),
            MenuItem(name: 'Kung Pao Chicken', calories: 290, protein: 16, carbs: 14, fat: 19),
            MenuItem(name: 'Mushroom Chicken', calories: 220, protein: 14, carbs: 10, fat: 14),
            MenuItem(name: 'Black Pepper Angus Steak', calories: 210, protein: 19, carbs: 13, fat: 10),
            MenuItem(name: 'Broccoli Beef', calories: 150, protein: 9, carbs: 13, fat: 7),
            MenuItem(name: 'Honey Sesame Chicken Breast', calories: 340, protein: 14, carbs: 35, fat: 15),
            MenuItem(name: 'String Bean Chicken Breast', calories: 190, protein: 14, carbs: 13, fat: 9),
            MenuItem(name: 'Sweetfire Chicken Breast', calories: 380, protein: 14, carbs: 47, fat: 15),
            MenuItem(name: 'Eggplant Tofu', calories: 340, protein: 7, carbs: 33, fat: 19),
          ],
        ),
      ],
      'Plate': const [
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Chow Mein', calories: 510, protein: 13, carbs: 80, fat: 20),
            MenuItem(name: 'Fried Rice', calories: 520, protein: 11, carbs: 85, fat: 16),
            MenuItem(name: 'White Steamed Rice', calories: 380, protein: 7, carbs: 87, fat: 0),
            MenuItem(name: 'Brown Steamed Rice', calories: 420, protein: 9, carbs: 86, fat: 4),
            MenuItem(name: 'Super Greens', calories: 90, protein: 6, carbs: 10, fat: 3),
          ],
        ),
        MenuCategory(
          name: 'Entree #1',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Orange Chicken', calories: 510, protein: 25, carbs: 51, fat: 23),
            MenuItem(name: 'Beijing Beef', calories: 480, protein: 14, carbs: 47, fat: 27),
            MenuItem(name: 'Kung Pao Chicken', calories: 290, protein: 16, carbs: 14, fat: 19),
            MenuItem(name: 'String Bean Chicken Breast', calories: 190, protein: 14, carbs: 13, fat: 9),
            MenuItem(name: 'Broccoli Beef', calories: 150, protein: 9, carbs: 13, fat: 7),
            MenuItem(name: 'Mushroom Chicken', calories: 220, protein: 14, carbs: 10, fat: 14),
          ],
        ),
        MenuCategory(
          name: 'Entree #2',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Orange Chicken', calories: 510, protein: 25, carbs: 51, fat: 23),
            MenuItem(name: 'Beijing Beef', calories: 480, protein: 14, carbs: 47, fat: 27),
            MenuItem(name: 'Kung Pao Chicken', calories: 290, protein: 16, carbs: 14, fat: 19),
            MenuItem(name: 'String Bean Chicken Breast', calories: 190, protein: 14, carbs: 13, fat: 9),
            MenuItem(name: 'Broccoli Beef', calories: 150, protein: 9, carbs: 13, fat: 7),
            MenuItem(name: 'Mushroom Chicken', calories: 220, protein: 14, carbs: 10, fat: 14),
          ],
        ),
      ],
      'Bigger Plate': const [
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Chow Mein', calories: 510, protein: 13, carbs: 80, fat: 20),
            MenuItem(name: 'Fried Rice', calories: 520, protein: 11, carbs: 85, fat: 16),
            MenuItem(name: 'White Steamed Rice', calories: 380, protein: 7, carbs: 87, fat: 0),
            MenuItem(name: 'Super Greens', calories: 90, protein: 6, carbs: 10, fat: 3),
          ],
        ),
        MenuCategory(
          name: 'Entree #1',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Orange Chicken', calories: 510, protein: 25, carbs: 51, fat: 23),
            MenuItem(name: 'Beijing Beef', calories: 480, protein: 14, carbs: 47, fat: 27),
            MenuItem(name: 'Kung Pao Chicken', calories: 290, protein: 16, carbs: 14, fat: 19),
            MenuItem(name: 'Broccoli Beef', calories: 150, protein: 9, carbs: 13, fat: 7),
          ],
        ),
        MenuCategory(
          name: 'Entree #2',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Orange Chicken', calories: 510, protein: 25, carbs: 51, fat: 23),
            MenuItem(name: 'Mushroom Chicken', calories: 220, protein: 14, carbs: 10, fat: 14),
            MenuItem(name: 'String Bean Chicken Breast', calories: 190, protein: 14, carbs: 13, fat: 9),
          ],
        ),
        MenuCategory(
          name: 'Entree #3',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Orange Chicken', calories: 510, protein: 25, carbs: 51, fat: 23),
            MenuItem(name: 'Broccoli Beef', calories: 150, protein: 9, carbs: 13, fat: 7),
            MenuItem(name: 'Honey Sesame Chicken Breast', calories: 340, protein: 14, carbs: 35, fat: 15),
          ],
        ),
      ],
      'A La Carte': const [
        MenuCategory(
          name: 'Side',
          mode: SelectionMode.multiple,
          optional: true,
          items: [
            MenuItem(name: 'Cream Cheese Rangoon (3 pcs)', calories: 190, protein: 4, carbs: 24, fat: 8),
            MenuItem(name: 'Chicken Egg Roll', calories: 200, protein: 8, carbs: 21, fat: 10),
            MenuItem(name: 'Veggie Spring Roll (2 pcs)', calories: 240, protein: 4, carbs: 24, fat: 14),
            MenuItem(name: 'Chicken Potsticker (3 pcs)', calories: 220, protein: 8, carbs: 24, fat: 11),
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
            MenuItem(name: 'Spicy Broccoli + Greens', calories: 100, protein: 7, carbs: 16, fat: 3),
          ],
        ),
        MenuCategory(
          name: 'Protein',
          mode: SelectionMode.single,
          optional: true,
          items: [
            MenuItem(name: 'Roasted Chicken', calories: 220, protein: 36, carbs: 1, fat: 7),
            MenuItem(name: 'Blackened Chicken', calories: 240, protein: 36, carbs: 3, fat: 9),
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
            MenuItem(name: 'Spicy Broccoli', calories: 160, protein: 8, carbs: 18, fat: 8),
            MenuItem(name: 'Sweetpotato + Wild Rice', calories: 310, protein: 8, carbs: 64, fat: 2),
          ],
        ),
        MenuCategory(
          name: 'Protein',
          mode: SelectionMode.single,
          items: [
            MenuItem(name: 'Roasted Chicken', calories: 220, protein: 36, carbs: 1, fat: 7),
            MenuItem(name: 'Steelhead', calories: 270, protein: 33, carbs: 1, fat: 14),
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
        MenuCategory(
          name: 'Protein',
          mode: SelectionMode.single,
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
          mode: SelectionMode.single,
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
          mode: SelectionMode.single,
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
];

/// Lookup helper — returns null if no restaurant matches the id.
RestaurantMenu? restaurantById(String id) {
  for (final r in restaurantMenus) {
    if (r.id == id) return r;
  }
  return null;
}
