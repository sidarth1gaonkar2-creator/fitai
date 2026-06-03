import 'dart:math' as math;

import '../../../models/enums.dart';

/// Allometric scaling exponent — the biological square-cube law: muscle
/// cross-sectional area (and thus force) scales with body mass^(2/3) ≈ 0.67.
const double kAllometricExponent = 0.67;

const double _kgToLbs = 2.20462;

/// Core strength score: `weightLifted / bodyWeight^0.67`.
///
/// Both weights MUST be in the SAME unit and that unit is **pounds** — the
/// per-exercise rank thresholds were calibrated in lbs (e.g. a 150 lb lifter
/// benching 225 → 225 / 150^0.67 ≈ 8.0). Allometric scaling means a heavier
/// lifter at the same bodyweight ratio scores higher (absolute load matters),
/// while a small lifter who lifts exceptionally for their size still ranks
/// well.
///
/// Returns 0 for non-positive inputs (no bodyweight / no load) so callers
/// never divide by zero or feed NaN into the rank mapping.
double allometricScoreLbs({
  required double weightLbs,
  required double bodyWeightLbs,
}) {
  if (weightLbs <= 0 || bodyWeightLbs <= 0) return 0;
  final score = weightLbs / math.pow(bodyWeightLbs, kAllometricExponent);
  return score.isFinite ? score : 0;
}

/// Convenience wrapper that takes kilograms (the app's storage unit) and
/// converts to pounds before scoring, then applies the [sex] multiplier.
///
/// [weightMultiplier] converts a per-implement PR into total load moved — 2.0
/// for two-dumbbell movements (the app stores "per dumbbell"), 1.0 otherwise.
double allometricScoreFromKg({
  required double weightKg,
  required double bodyWeightKg,
  Sex? sex,
  double weightMultiplier = 1.0,
}) {
  final raw = allometricScoreLbs(
    weightLbs: weightKg * weightMultiplier * _kgToLbs,
    bodyWeightLbs: bodyWeightKg * _kgToLbs,
  );
  return raw * genderMultiplier(sex);
}

/// Strength distributions differ by sex, so a woman lifting at the same
/// allometric score as a man earns a higher rank. Applied as a multiplier on
/// the score before the rank lookup.
///
///   * male   → 1.00 (baseline)
///   * female → 1.35
///   * unknown/null → 1.15 (middle ground; the profile only stores
///     male/female today, so this is the no-profile fallback)
double genderMultiplier(Sex? sex) {
  switch (sex) {
    case Sex.male:
      return 1.0;
    case Sex.female:
      return 1.35;
    case null:
      return 1.15;
  }
}
