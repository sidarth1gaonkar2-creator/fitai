import '../../models/enums.dart';

double calculateBMR({
  required double weightKg,
  required double heightCm,
  required int age,
  required Sex sex,
}) {
  final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return switch (sex) {
    Sex.male => base + 5,
    Sex.female => base - 161,
  };
}

double calculateTDEE({
  required double bmr,
  required ActivityLevel activityLevel,
}) {
  return bmr * activityLevel.multiplier;
}

class TDEEBreakdown {
  final double baseValue;
  final double sexConstant;
  final double bmr;
  final double activityMultiplier;
  final double tdee;
  final double goalAdjustedTarget;
  final int calorieAdjustment;

  const TDEEBreakdown({
    required this.baseValue,
    required this.sexConstant,
    required this.bmr,
    required this.activityMultiplier,
    required this.tdee,
    required this.goalAdjustedTarget,
    required this.calorieAdjustment,
  });
}

TDEEBreakdown calculateTDEEBreakdown({
  required double weightKg,
  required double heightCm,
  required int age,
  required Sex sex,
  required ActivityLevel activityLevel,
  required Goal goal,
}) {
  final baseValue = 10 * weightKg + 6.25 * heightCm - 5 * age;
  final sexConstant = switch (sex) {
    Sex.male => 5.0,
    Sex.female => -161.0,
  };
  final bmr = baseValue + sexConstant;
  final multiplier = activityLevel.multiplier;
  final tdee = bmr * multiplier;

  // TODO: make configurable via settings
  final calorieAdjustment = switch (goal) {
    Goal.loseFat => -500,
    Goal.buildMuscle => 250,
    Goal.maintain => 0,
  };

  final goalAdjustedTarget = tdee + calorieAdjustment;

  return TDEEBreakdown(
    baseValue: baseValue,
    sexConstant: sexConstant,
    bmr: bmr,
    activityMultiplier: multiplier,
    tdee: tdee,
    goalAdjustedTarget: goalAdjustedTarget,
    calorieAdjustment: calorieAdjustment,
  );
}
