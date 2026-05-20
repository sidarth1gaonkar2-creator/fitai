/// Curated emoji catalogue for naming saved meals, quick-add presets,
/// and any other user-named food entry. Organised by category for the
/// picker UI; the comments after each entry are kept for grep-ability
/// (the emoji glyphs alone are awful to search for in source).
class FoodEmojis {
  const FoodEmojis._();

  /// The default glyph shown when a saved item has no emoji set.
  static const String defaultEmoji = '🍽️';

  /// Section name → emoji list. Order is intentional — Protein first so it
  /// matches how users typically think about their meals (macro-first).
  static const Map<String, List<String>> categories = {
    'Protein': [
      '🥩', // steak
      '🍗', // poultry leg
      '🍖', // meat on bone
      '🥓', // bacon
      '🌭', // hot dog
      '🍔', // hamburger
      '🥚', // egg
      '🍳', // fried egg
      '🐟', // fish
      '🍣', // sushi
      '🦐', // shrimp
      '🥜', // peanuts
      '🫘', // beans
      '🧆', // falafel
    ],
    'Grains & Carbs': [
      '🍞', // bread
      '🥖', // baguette
      '🥐', // croissant
      '🧇', // waffle
      '🥞', // pancakes
      '🍝', // spaghetti
      '🍜', // ramen
      '🍚', // rice
      '🌮', // taco
      '🌯', // burrito
      '🥪', // sandwich
      '🍕', // pizza
      '🥯', // bagel
      '🫓', // flatbread
      '🥔', // potato
      '🍠', // sweet potato
    ],
    'Fruits': [
      '🍎', // apple
      '🍌', // banana
      '🍊', // orange
      '🍇', // grapes
      '🍓', // strawberry
      '🫐', // blueberries
      '🍑', // peach
      '🍍', // pineapple
      '🥭', // mango
      '🍉', // watermelon
      '🥝', // kiwi
      '🍒', // cherries
      '🍋', // lemon
      '🥥', // coconut
      '🍐', // pear
      '🫒', // olive
    ],
    'Vegetables': [
      '🥗', // salad
      '🥦', // broccoli
      '🥕', // carrot
      '🌽', // corn
      '🥒', // cucumber
      '🍅', // tomato
      '🫑', // bell pepper
      '🧅', // onion
      '🧄', // garlic
      '🥬', // leafy green
      '🍆', // eggplant
      '🥑', // avocado
      '🌶️', // hot pepper
      '🫛', // pea pod
      '🍄', // mushroom
    ],
    'Dairy & Drinks': [
      '🥛', // milk
      '🧀', // cheese
      '🧈', // butter
      '🍦', // ice cream
      '🍶', // sake/milk
      '☕', // coffee
      '🍵', // tea
      '🧃', // juice box
      '🥤', // cup with straw
      '🍺', // beer
      '🍷', // wine
      '🧋', // boba tea
      '💧', // water
    ],
    'Snacks & Sweets': [
      '🍪', // cookie
      '🍫', // chocolate
      '🍩', // donut
      '🧁', // cupcake
      '🎂', // cake
      '🍰', // shortcake
      '🍿', // popcorn
      '🥨', // pretzel
      '🍬', // candy
      '🍮', // flan/pudding
      '🍯', // honey
      '🥧', // pie
    ],
    'Meals & Restaurants': [
      '🍱', // bento
      '🥘', // paella/stew
      '🫕', // fondue
      '🥙', // pita
      '🥫', // canned food
      '🍲', // pot of food
      '🍛', // curry
      '🍤', // fried shrimp
      '🥡', // takeout
      '🫔', // tamale
      '🥣', // cereal/oatmeal
      '🍽️', // plate with cutlery
      '🔥', // fire (spicy/hot)
      '💪', // strong (protein heavy)
      '⚡', // energy/pre-workout
    ],
  };

  /// Flat list of every glyph in [categories]. Used by callers that just
  /// need a membership check.
  static List<String> get all =>
      categories.values.expand((e) => e).toList(growable: false);

  /// Most-commonly-used emojis surfaced as a quick-pick row at the top of
  /// the picker so the user can choose in one tap without scrolling.
  static const List<String> quickPicks = [
    '🍳', '🥗', '🍔', '🌯', '🍕', '🥩', '🍗', '🍝',
    '🥤', '☕', '🍎', '🥑', '🥚', '🍞', '🥜', '🍫',
  ];
}
