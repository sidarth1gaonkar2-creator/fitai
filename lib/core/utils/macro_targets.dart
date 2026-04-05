import '../../models/enums.dart';

class MacroTargets {
  const MacroTargets({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double protein;
  final double carbs;
  final double fat;
}

MacroTargets macroTargetsFor({
  required double tdee,
  required Goal goal,
}) {
  final (pPct, cPct, fPct) = switch (goal) {
    Goal.loseFat => (0.40, 0.30, 0.30),
    Goal.buildMuscle => (0.30, 0.45, 0.25),
    Goal.maintain => (0.30, 0.40, 0.30),
  };
  return MacroTargets(
    protein: (tdee * pPct) / 4,
    carbs: (tdee * cPct) / 4,
    fat: (tdee * fPct) / 9,
  );
}
