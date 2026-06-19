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

/// Maximum reps credited by [estimatedOneRepMaxKg]. The Epley formula (like
/// every 1RM estimator) is only validated for low-to-moderate reps and badly
/// over-estimates at very high reps — uncapped, a light 20-rep set would
/// out-score a genuinely heavier low-rep lift. Capping keeps the ranking
/// honest at the extremes: 12 covers the usual strength/hypertrophy working
/// range, and anything beyond it scores as a 12-rep set.
const int kOneRmRepCap = 12;

/// Estimated one-rep max (kg) for a logged set via the Epley formula —
/// `weight × (1 + reps/30)` — with [reps] capped at [kOneRmRepCap].
///
/// This is the value the ranking pipeline scores on (instead of raw top
/// weight), so lifting heavier OR doing more reps both raise your score. A
/// true single (reps ≤ 1) is its own 1RM, so it returns the weight unchanged
/// rather than Epley's slight one-rep inflation. Returns 0 for a non-positive
/// load so callers never feed garbage into the score (and never divide by a
/// zero body weight downstream — that guard lives in [allometricScoreLbs]).
double estimatedOneRepMaxKg({required double weightKg, required int reps}) {
  if (weightKg <= 0) return 0;
  if (reps <= 1) return weightKg;
  final cappedReps = reps > kOneRmRepCap ? kOneRmRepCap : reps;
  return weightKg * (1 + cappedReps / 30.0);
}

/// Representative working-set rep count the rank thresholds are anchored to.
/// The pipeline now scores ESTIMATED 1RM, which for this rep count is
/// [kCalibrationE1rmFactor]× the raw weight. The per-exercise thresholds (tuned
/// for raw top weight) are scaled by that factor so a lifter who trains at
/// ~[kCalibrationReps] reps keeps the SAME rank as before the e1RM switch —
/// avoiding wholesale rank inflation. Heavy-single specialists then sit
/// slightly lower and high-rep lifters slightly higher, which is the intended,
/// fairer behaviour of estimated-1RM scoring.
const int kCalibrationReps = 5;

/// Epley multiplier for [kCalibrationReps] reps (= 1 + 5/30 ≈ 1.16667) — the
/// factor the rank thresholds in exercise_standards.dart are scaled by.
const double kCalibrationE1rmFactor = 1 + kCalibrationReps / 30;

/// Inverse of [allometricScoreFromKg]: the per-implement weight (kg) needed to
/// reach [targetScore] at the given body weight, sex, and dumbbell multiplier.
/// Used to tell the user "X more lbs to the next rank". Returns 0 for
/// non-positive inputs.
double weightKgForScore({
  required double targetScore,
  required double bodyWeightKg,
  Sex? sex,
  double weightMultiplier = 1.0,
}) {
  if (targetScore <= 0 || bodyWeightKg <= 0 || weightMultiplier <= 0) return 0;
  final g = genderMultiplier(sex);
  if (g <= 0) return 0;
  final bwLbs = bodyWeightKg * _kgToLbs;
  // score = (weightKg * mult * kgToLbs / bwLbs^0.67) * g
  //   ⇒ weightKg = targetScore * bwLbs^0.67 / (g * mult * kgToLbs)
  final perImplementKg = targetScore *
      math.pow(bwLbs, kAllometricExponent) /
      (g * weightMultiplier * _kgToLbs);
  return perImplementKg.isFinite ? perImplementKg : 0;
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
