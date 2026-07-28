/// Recommended Daily Allowance targets for tracked micronutrients.
/// Sodium is an upper limit (not a minimum goal) — colour logic should invert for it.
const Map<String, double> microRdaTargets = {
  'Vitamin D': 20, // mcg
  'Iron': 18, // mg
  'Calcium': 1000, // mg
  'Vitamin C': 90, // mg
  'Magnesium': 400, // mg
  'Sodium': 2300, // mg (upper limit)
  'Potassium': 3500, // mg
  'Zinc': 11, // mg
  'Vitamin B12': 2.4, // mcg
  'Folate': 400, // mcg
};

/// Sodium is an upper limit — progress bar colour should invert
/// (green when under, red when over).
const String sodiumKey = 'Sodium';

/// Serving unit written exclusively by the restaurant meal builder when it
/// logs a composed item. Doubles as the persisted marker that an entry's
/// micronutrients came from the hardcoded restaurant data — no schema field
/// needed, and it survives restore, recent-foods re-log and saved-meal
/// re-log because every path copies servingUnit through.
const String restaurantServingUnit = 'meal';

/// Panel keys whose restaurant-item values are USDA-derived ESTIMATES
/// (Tier 2 in report_mcdonalds_micros.txt) rather than chain-published
/// label data. Only these five ever get the "est." marker; fiber, sodium,
/// vitamin D, calcium, iron and potassium come from the chains' own
/// published nutrition data and render like any other food's values.
const Set<String> estimatedRestaurantMicroKeys = {
  'Vitamin C',
  'Magnesium',
  'Zinc',
  'Vitamin B12',
  'Folate',
};
