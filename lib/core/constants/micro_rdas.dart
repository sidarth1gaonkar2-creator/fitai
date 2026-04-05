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
