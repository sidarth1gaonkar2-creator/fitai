import '../features/nutrition/domain/food_search_result.dart';
import '../models/enums.dart';

/// Hardcoded "most popular items" for each of the 12 API-search chains.
/// Numbers come from each chain's official nutrition PDF / website. We
/// surface these even when:
///   * the Spoonacular daily quota is exhausted, or
///   * the user is offline, or
///   * the cache has never been populated for this restaurant.
///
/// Calories are stored as per-serving values; the search-result type
/// uses *Per100g* fields but for a meal item we treat the row as one
/// serving of fixed weight (300g placeholder) so the downstream detail
/// screen shows the right macro figures without re-scaling. Users adjust
/// portion in the detail screen if they want.
class PreSeedMenuItem {
  const PreSeedMenuItem({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.servingGrams = 300,
  });

  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double servingGrams;

  FoodSearchResult toResult(String restaurantName) {
    // Per-100g scaling so the FoodSearchResult math works consistently.
    final factor = 100 / servingGrams;
    return FoodSearchResult(
      name: name,
      brand: restaurantName,
      caloriesPer100g: calories * factor,
      proteinPer100g: protein * factor,
      carbsPer100g: carbs * factor,
      fatPer100g: fat * factor,
      defaultServingSize: servingGrams,
      servingUnit: 'g',
      servingDescription: '1 serving',
      source: FoodSource.spoonacular,
    );
  }
}

/// Map of restaurant id (matching `RestaurantMenu.id`) → curated item list.
const Map<String, List<PreSeedMenuItem>> preSeedMenuItems = {
  'applebees': [
    PreSeedMenuItem(name: 'Oriental Chicken Salad', calories: 1370, protein: 49, carbs: 67, fat: 99),
    PreSeedMenuItem(name: 'Riblets Platter', calories: 1430, protein: 53, carbs: 117, fat: 81),
    PreSeedMenuItem(name: 'Chicken Tenders Platter', calories: 1340, protein: 56, carbs: 105, fat: 75),
    PreSeedMenuItem(name: 'Bourbon Street Steak (8 oz)', calories: 740, protein: 51, carbs: 12, fat: 53),
    PreSeedMenuItem(name: 'Fiesta Lime Chicken', calories: 1200, protein: 53, carbs: 88, fat: 65),
    PreSeedMenuItem(name: 'Classic Burger', calories: 980, protein: 52, carbs: 67, fat: 53),
    PreSeedMenuItem(name: 'Quesadilla Burger', calories: 1410, protein: 64, carbs: 92, fat: 86),
    PreSeedMenuItem(name: '4-Cheese Mac & Cheese w/ Honey Pepper Chicken', calories: 1410, protein: 71, carbs: 138, fat: 60),
    PreSeedMenuItem(name: 'Chicken Wonton Stir-Fry', calories: 700, protein: 38, carbs: 92, fat: 19),
    PreSeedMenuItem(name: 'Caesar Salad w/ Grilled Chicken', calories: 800, protein: 51, carbs: 31, fat: 51),
  ],
  'cheesecakefactory': [
    PreSeedMenuItem(name: 'Avocado Eggrolls', calories: 1140, protein: 14, carbs: 117, fat: 70),
    PreSeedMenuItem(name: 'Chicken Madeira', calories: 1500, protein: 95, carbs: 112, fat: 72),
    PreSeedMenuItem(name: 'Pasta Carbonara w/ Chicken', calories: 2070, protein: 71, carbs: 144, fat: 128),
    PreSeedMenuItem(name: 'Glamburger', calories: 1740, protein: 67, carbs: 119, fat: 105),
    PreSeedMenuItem(name: 'Chicken Piccata', calories: 1330, protein: 86, carbs: 88, fat: 70),
    PreSeedMenuItem(name: 'Fish Tacos', calories: 1100, protein: 56, carbs: 92, fat: 54),
    PreSeedMenuItem(name: 'Louisiana Chicken Pasta', calories: 2370, protein: 100, carbs: 144, fat: 156),
    PreSeedMenuItem(name: 'Original Cheesecake (slice)', calories: 710, protein: 12, carbs: 60, fat: 47, servingGrams: 180),
    PreSeedMenuItem(name: 'Fresh Strawberry Cheesecake (slice)', calories: 820, protein: 11, carbs: 75, fat: 52, servingGrams: 200),
    PreSeedMenuItem(name: 'Oreo Dream Cheesecake (slice)', calories: 1230, protein: 14, carbs: 109, fat: 81, servingGrams: 230),
  ],
  'olivegarden': [
    PreSeedMenuItem(name: 'Chicken Alfredo', calories: 1480, protein: 76, carbs: 99, fat: 87),
    PreSeedMenuItem(name: 'Tour of Italy', calories: 1450, protein: 78, carbs: 99, fat: 79),
    PreSeedMenuItem(name: 'Chicken Parmigiana', calories: 1060, protein: 60, carbs: 100, fat: 49),
    PreSeedMenuItem(name: 'Eggplant Parmigiana', calories: 850, protein: 32, carbs: 105, fat: 35),
    PreSeedMenuItem(name: 'Lasagna Classico', calories: 850, protein: 47, carbs: 70, fat: 47),
    PreSeedMenuItem(name: 'Zuppa Toscana (bowl)', calories: 240, protein: 9, carbs: 22, fat: 14, servingGrams: 360),
    PreSeedMenuItem(name: 'Minestrone (bowl)', calories: 160, protein: 7, carbs: 28, fat: 2, servingGrams: 360),
    PreSeedMenuItem(name: 'Breadstick (1)', calories: 140, protein: 5, carbs: 26, fat: 2, servingGrams: 50),
    PreSeedMenuItem(name: 'Garden Salad w/ Italian Dressing', calories: 350, protein: 5, carbs: 23, fat: 26),
    PreSeedMenuItem(name: 'Spaghetti & Meatballs', calories: 1110, protein: 56, carbs: 109, fat: 47),
  ],
  'chilis': [
    PreSeedMenuItem(name: 'Baby Back Ribs (full rack)', calories: 1430, protein: 90, carbs: 53, fat: 96),
    PreSeedMenuItem(name: 'Crispy Chicken Crispers (3 pc)', calories: 990, protein: 39, carbs: 93, fat: 50),
    PreSeedMenuItem(name: 'Oldtimer Burger', calories: 920, protein: 49, carbs: 67, fat: 50),
    PreSeedMenuItem(name: 'Cajun Chicken Pasta', calories: 1410, protein: 67, carbs: 121, fat: 70),
    PreSeedMenuItem(name: 'Chicken Bacon Ranch Quesadilla', calories: 1620, protein: 79, carbs: 100, fat: 99),
    PreSeedMenuItem(name: 'Southwest Eggrolls', calories: 760, protein: 31, carbs: 65, fat: 41),
    PreSeedMenuItem(name: 'Molten Chocolate Cake', calories: 1170, protein: 13, carbs: 152, fat: 56, servingGrams: 260),
    PreSeedMenuItem(name: 'Boneless Wings (10 pc)', calories: 800, protein: 60, carbs: 30, fat: 50),
    PreSeedMenuItem(name: 'Classic Nachos', calories: 1500, protein: 55, carbs: 95, fat: 95),
    PreSeedMenuItem(name: 'Margarita Grilled Chicken', calories: 620, protein: 50, carbs: 71, fat: 16),
  ],
  'buffalowildwings': [
    PreSeedMenuItem(name: 'Traditional Wings (6 pc, plain)', calories: 480, protein: 60, carbs: 0, fat: 28),
    PreSeedMenuItem(name: 'Traditional Wings (12 pc, plain)', calories: 960, protein: 120, carbs: 0, fat: 56),
    PreSeedMenuItem(name: 'Traditional Wings (18 pc, plain)', calories: 1440, protein: 180, carbs: 0, fat: 84),
    PreSeedMenuItem(name: 'Boneless Wings (6 pc, plain)', calories: 540, protein: 40, carbs: 23, fat: 32),
    PreSeedMenuItem(name: 'Boneless Wings (12 pc, plain)', calories: 1080, protein: 80, carbs: 46, fat: 64),
    PreSeedMenuItem(name: 'Boneless Wings (18 pc, plain)', calories: 1620, protein: 120, carbs: 69, fat: 96),
    PreSeedMenuItem(name: 'Chicken Tender Wrap', calories: 1010, protein: 47, carbs: 86, fat: 53),
    PreSeedMenuItem(name: 'Big Jack Daddy Burger', calories: 1310, protein: 65, carbs: 92, fat: 76),
    PreSeedMenuItem(name: 'Mozzarella Sticks (5 pc)', calories: 590, protein: 26, carbs: 51, fat: 31),
    PreSeedMenuItem(name: 'Ultimate Nachos', calories: 1850, protein: 73, carbs: 140, fat: 113),
    PreSeedMenuItem(name: 'House Side Salad', calories: 100, protein: 6, carbs: 8, fat: 5),
  ],
  'redlobster': [
    PreSeedMenuItem(name: 'Cheddar Bay Biscuit (1)', calories: 160, protein: 3, carbs: 16, fat: 9, servingGrams: 40),
    PreSeedMenuItem(name: 'Ultimate Feast', calories: 1480, protein: 99, carbs: 124, fat: 60),
    PreSeedMenuItem(name: 'Walt\'s Favorite Shrimp', calories: 770, protein: 31, carbs: 78, fat: 36),
    PreSeedMenuItem(name: 'Lobster Tail (live Maine)', calories: 100, protein: 22, carbs: 0, fat: 1, servingGrams: 140),
    PreSeedMenuItem(name: 'Garlic Shrimp Scampi', calories: 430, protein: 23, carbs: 6, fat: 35),
    PreSeedMenuItem(name: 'Coconut Shrimp Bites', calories: 700, protein: 22, carbs: 65, fat: 38),
    PreSeedMenuItem(name: 'Atlantic Salmon (full)', calories: 590, protein: 65, carbs: 14, fat: 30),
    PreSeedMenuItem(name: 'Snow Crab Legs (1 lb)', calories: 230, protein: 50, carbs: 0, fat: 4),
  ],
  'dennys': [
    PreSeedMenuItem(name: 'Grand Slam (eggs/bacon/sausage/pancakes)', calories: 760, protein: 33, carbs: 65, fat: 41),
    PreSeedMenuItem(name: 'Lumberjack Slam', calories: 1190, protein: 53, carbs: 117, fat: 56),
    PreSeedMenuItem(name: 'Moons Over My Hammy', calories: 870, protein: 46, carbs: 72, fat: 47),
    PreSeedMenuItem(name: 'Build Your Own Grand Slam (4 items)', calories: 700, protein: 32, carbs: 53, fat: 41),
    PreSeedMenuItem(name: 'Bacon Slamburger', calories: 1120, protein: 51, carbs: 71, fat: 70),
    PreSeedMenuItem(name: 'Chicken Strips Dinner', calories: 1050, protein: 47, carbs: 86, fat: 56),
    PreSeedMenuItem(name: 'T-Bone Steak & Eggs', calories: 900, protein: 74, carbs: 13, fat: 60),
    PreSeedMenuItem(name: 'Country Fried Steak & Eggs', calories: 1110, protein: 38, carbs: 76, fat: 70),
  ],
  'ihop': [
    PreSeedMenuItem(name: 'Original Buttermilk Pancakes (5)', calories: 770, protein: 18, carbs: 119, fat: 23),
    PreSeedMenuItem(name: 'Original Buttermilk Pancakes (short stack 3)', calories: 460, protein: 11, carbs: 71, fat: 14),
    PreSeedMenuItem(name: 'Belgian Waffle', calories: 590, protein: 13, carbs: 65, fat: 30),
    PreSeedMenuItem(name: 'Big Steak Omelette', calories: 970, protein: 50, carbs: 28, fat: 71),
    PreSeedMenuItem(name: 'Stuffed French Toast', calories: 990, protein: 23, carbs: 134, fat: 38),
    PreSeedMenuItem(name: 'Cupcake Pancakes', calories: 1010, protein: 17, carbs: 147, fat: 36),
    PreSeedMenuItem(name: 'Country Fried Steak Combo', calories: 1410, protein: 48, carbs: 105, fat: 89),
    PreSeedMenuItem(name: 'Chicken & Waffles', calories: 1020, protein: 34, carbs: 99, fat: 53),
    PreSeedMenuItem(name: 'Hashbrowns (side)', calories: 280, protein: 3, carbs: 26, fat: 18, servingGrams: 130),
  ],
  'outback': [
    PreSeedMenuItem(name: 'Bloomin\' Onion (full)', calories: 1950, protein: 21, carbs: 184, fat: 124),
    PreSeedMenuItem(name: 'Outback Center-Cut Sirloin (8 oz)', calories: 360, protein: 56, carbs: 0, fat: 13),
    PreSeedMenuItem(name: 'Outback Special Sirloin (8 oz)', calories: 350, protein: 52, carbs: 0, fat: 14),
    PreSeedMenuItem(name: 'Ribeye (12 oz)', calories: 880, protein: 65, carbs: 0, fat: 67),
    PreSeedMenuItem(name: 'Filet Mignon (6 oz)', calories: 320, protein: 46, carbs: 0, fat: 14),
    PreSeedMenuItem(name: 'Alice Springs Chicken', calories: 870, protein: 73, carbs: 11, fat: 58),
    PreSeedMenuItem(name: 'Grilled Shrimp on the Barbie', calories: 380, protein: 32, carbs: 11, fat: 22),
    PreSeedMenuItem(name: 'Loaded Baked Potato', calories: 480, protein: 12, carbs: 65, fat: 19, servingGrams: 280),
    PreSeedMenuItem(name: 'Aussie Cheese Fries (regular)', calories: 1410, protein: 41, carbs: 100, fat: 96),
  ],
  'crackerbarrel': [
    PreSeedMenuItem(name: 'Country Boy Breakfast', calories: 1230, protein: 53, carbs: 87, fat: 69),
    PreSeedMenuItem(name: 'Old Timer\'s Breakfast', calories: 740, protein: 39, carbs: 31, fat: 53),
    PreSeedMenuItem(name: 'Momma\'s Pancake Breakfast', calories: 660, protein: 17, carbs: 96, fat: 21),
    PreSeedMenuItem(name: 'Chicken n\' Dumplins (regular)', calories: 720, protein: 31, carbs: 81, fat: 30),
    PreSeedMenuItem(name: 'Country Fried Steak', calories: 870, protein: 36, carbs: 56, fat: 56),
    PreSeedMenuItem(name: 'Meatloaf', calories: 700, protein: 47, carbs: 36, fat: 41),
    PreSeedMenuItem(name: 'Hashbrown Casserole', calories: 380, protein: 12, carbs: 36, fat: 21),
    PreSeedMenuItem(name: 'Sunday Homestyle Chicken', calories: 590, protein: 42, carbs: 39, fat: 28),
    PreSeedMenuItem(name: 'Biscuit (1)', calories: 200, protein: 4, carbs: 23, fat: 11, servingGrams: 50),
  ],
  'pfchangs': [
    PreSeedMenuItem(name: 'Chicken Lettuce Wraps', calories: 590, protein: 30, carbs: 49, fat: 30),
    PreSeedMenuItem(name: 'Mongolian Beef', calories: 1330, protein: 60, carbs: 100, fat: 71),
    PreSeedMenuItem(name: 'Kung Pao Chicken', calories: 1110, protein: 65, carbs: 75, fat: 60),
    PreSeedMenuItem(name: 'Orange Chicken', calories: 990, protein: 41, carbs: 113, fat: 41),
    PreSeedMenuItem(name: 'Pepper Steak', calories: 750, protein: 49, carbs: 50, fat: 41),
    PreSeedMenuItem(name: 'Shrimp Fried Rice', calories: 970, protein: 35, carbs: 130, fat: 33),
    PreSeedMenuItem(name: 'Crab Wontons (6 pc)', calories: 500, protein: 13, carbs: 33, fat: 35),
    PreSeedMenuItem(name: 'Egg Rolls (2 pc)', calories: 290, protein: 7, carbs: 23, fat: 19),
    PreSeedMenuItem(name: 'Vegetable Spring Rolls (2 pc)', calories: 220, protein: 5, carbs: 26, fat: 11),
  ],
  'tgifridays': [
    PreSeedMenuItem(name: 'Loaded Potato Skins (4 pc)', calories: 1010, protein: 33, carbs: 67, fat: 65),
    PreSeedMenuItem(name: 'Jack Daniel\'s Ribs (full rack)', calories: 1650, protein: 100, carbs: 110, fat: 89),
    PreSeedMenuItem(name: 'Jack Daniel\'s Chicken', calories: 870, protein: 60, carbs: 100, fat: 26),
    PreSeedMenuItem(name: 'Cajun Shrimp & Chicken Pasta', calories: 1250, protein: 60, carbs: 117, fat: 56),
    PreSeedMenuItem(name: 'Friday\'s Signature Whiskey-Glazed Burger', calories: 1230, protein: 58, carbs: 96, fat: 65),
    PreSeedMenuItem(name: 'Mozzarella Sticks (5 pc)', calories: 620, protein: 27, carbs: 53, fat: 32),
    PreSeedMenuItem(name: 'Pan-Seared Pot Stickers (5 pc)', calories: 470, protein: 17, carbs: 53, fat: 21),
    PreSeedMenuItem(name: 'Brownie Obsession', calories: 1500, protein: 14, carbs: 187, fat: 80, servingGrams: 350),
  ],
};

/// Surface pre-seed items for the search [query] within [restaurantName].
/// If [restaurantName] is empty we search across every chain's list — this
/// powers the "Other Restaurant" catch-all when the user is offline or
/// out of API budget. If [query] is empty we return the full curated list
/// for the named chain (matches the auto-fire-on-open behaviour of the
/// API search screen).
List<FoodSearchResult> preSeedResultsFor({
  required String restaurantName,
  required String query,
}) {
  final rest = restaurantName.trim().toLowerCase();
  final q = query.trim().toLowerCase();

  Iterable<MapEntry<String, List<PreSeedMenuItem>>> candidates;
  if (rest.isEmpty) {
    candidates = preSeedMenuItems.entries;
  } else {
    candidates = preSeedMenuItems.entries.where((e) {
      // Match either restaurant id or restaurant display name. We don't
      // have the display name in this map so we match on contains() of
      // the restaurant name vs. the id — close enough since ids are
      // contiguous lowercased slugs derived from the name.
      final id = e.key.toLowerCase();
      return rest.contains(id) || id.contains(rest.replaceAll(' ', '')) ||
          rest.split(' ').any((tok) => id.contains(tok));
    });
  }

  // Try restaurant name first; if the user passed a fully-qualified
  // "restaurant + query" we strip the chain name to compare against
  // item names cleanly.
  final cleanQuery =
      rest.isEmpty ? q : q.replaceFirst(rest, '').trim();

  final out = <FoodSearchResult>[];
  for (final entry in candidates) {
    final restaurantLabel = _displayNameFor(entry.key);
    for (final item in entry.value) {
      if (cleanQuery.isEmpty ||
          item.name.toLowerCase().contains(cleanQuery)) {
        out.add(item.toResult(restaurantLabel));
      }
    }
  }
  return out;
}

/// Map of restaurant id → display name. Kept inline so we don't need a
/// cross-import to `restaurant_menus.dart` (and the circular risk that
/// creates between data files).
String _displayNameFor(String id) => switch (id) {
      'applebees' => "Applebee's",
      'buffalowildwings' => 'Buffalo Wild Wings',
      'cheesecakefactory' => 'Cheesecake Factory',
      'chilis' => "Chili's",
      'crackerbarrel' => 'Cracker Barrel',
      'dennys' => "Denny's",
      'ihop' => 'IHOP',
      'olivegarden' => 'Olive Garden',
      'outback' => 'Outback Steakhouse',
      'pfchangs' => "P.F. Chang's",
      'redlobster' => 'Red Lobster',
      'tgifridays' => "TGI Friday's",
      _ => id,
    };
