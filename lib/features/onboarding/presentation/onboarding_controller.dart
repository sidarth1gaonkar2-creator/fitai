import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/tdee_calculator.dart';
import '../../../models/enums.dart';
import '../../../models/onboarding_progress.dart';
import '../../../models/user_profile.dart';
import '../../../providers/isar_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../domain/onboarding_state.dart';

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this._ref) : super(const OnboardingState());

  final Ref _ref;

  void setName(String name) => state = state.copyWith(name: name);
  void setAge(int age) => state = state.copyWith(age: age);
  void setSex(Sex sex) => state = state.copyWith(sex: sex);
  void setWeight(double weight) => state = state.copyWith(weight: weight);
  void setHeight(double height) => state = state.copyWith(height: height);
  void setGoal(Goal goal) => state = state.copyWith(goal: goal);
  void setActivityLevel(ActivityLevel level) =>
      state = state.copyWith(activityLevel: level);

  void nextStep() {
    state = state.copyWith(
      previousStep: state.currentStep,
      currentStep: state.currentStep + 1,
    );
    _saveProgress();
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(
        previousStep: state.currentStep,
        currentStep: state.currentStep - 1,
      );
    }
  }

  Future<void> loadProgress() async {
    final isar = _ref.read(isarProvider);
    final progress = await isar.onboardingProgress.get(1);
    if (progress == null) return;

    state = OnboardingState(
      name: progress.name ?? '',
      age: progress.age,
      sex: progress.sex != null
          ? Sex.values.byName(progress.sex!)
          : null,
      weight: progress.weightKg,
      height: progress.heightCm,
      goal: progress.goal != null
          ? Goal.values.byName(progress.goal!)
          : null,
      activityLevel: progress.activityLevel != null
          ? ActivityLevel.values.byName(progress.activityLevel!)
          : null,
      currentStep: progress.lastCompletedStep,
    );
  }

  Future<void> _saveProgress() async {
    final isar = _ref.read(isarProvider);
    final progress = OnboardingProgress()
      ..id = 1
      ..name = state.name.isNotEmpty ? state.name : null
      ..age = state.age
      ..sex = state.sex?.name
      ..weightKg = state.weight
      ..heightCm = state.height
      ..goal = state.goal?.name
      ..activityLevel = state.activityLevel?.name
      ..lastCompletedStep = state.currentStep
      ..updatedAt = DateTime.now();
    await isar.writeTxn(() => isar.onboardingProgress.put(progress));
  }

  Future<void> calculateAndSave() async {
    state = state.copyWith(isSaving: true);

    try {
      final breakdown = calculateTDEEBreakdown(
        weightKg: state.weight!,
        heightCm: state.height!,
        age: state.age!,
        sex: state.sex!,
        activityLevel: state.activityLevel!,
        goal: state.goal!,
      );

      state = state.copyWith(tdeeBreakdown: breakdown);

      final profile = UserProfile()
        ..name = state.name
        ..age = state.age!
        ..sex = state.sex!
        ..weight = state.weight!
        ..height = state.height!
        ..goal = state.goal!
        ..activityLevel = state.activityLevel!
        ..tdee = breakdown.goalAdjustedTarget;

      final isar = _ref.read(isarProvider);
      // Save profile and clear draft in a single transaction
      await isar.writeTxn(() async {
        await isar.userProfiles.put(profile);
        await isar.onboardingProgress.delete(1);
      });

      // Refresh (not invalidate) so the provider resolves with the
      // new profile before the router re-evaluates the redirect.
      _ref.invalidate(userProfileProvider);
      await _ref.read(userProfileProvider.future);
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  return OnboardingController(ref);
});
