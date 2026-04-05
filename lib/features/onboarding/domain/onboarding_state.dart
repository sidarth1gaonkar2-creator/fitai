import '../../../core/utils/tdee_calculator.dart';
import '../../../models/enums.dart';

class OnboardingState {
  final String name;
  final int? age;
  final Sex? sex;
  final double? weight;
  final double? height;
  final Goal? goal;
  final ActivityLevel? activityLevel;
  final int currentStep;
  final int? previousStep;
  final bool isSaving;
  final TDEEBreakdown? tdeeBreakdown;

  const OnboardingState({
    this.name = '',
    this.age,
    this.sex,
    this.weight,
    this.height,
    this.goal,
    this.activityLevel,
    this.currentStep = 0,
    this.previousStep,
    this.isSaving = false,
    this.tdeeBreakdown,
  });

  OnboardingState copyWith({
    String? name,
    int? age,
    Sex? sex,
    double? weight,
    double? height,
    Goal? goal,
    ActivityLevel? activityLevel,
    int? currentStep,
    int? previousStep,
    bool? isSaving,
    TDEEBreakdown? tdeeBreakdown,
  }) {
    return OnboardingState(
      name: name ?? this.name,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      currentStep: currentStep ?? this.currentStep,
      previousStep: previousStep ?? this.previousStep,
      isSaving: isSaving ?? this.isSaving,
      tdeeBreakdown: tdeeBreakdown ?? this.tdeeBreakdown,
    );
  }
}
