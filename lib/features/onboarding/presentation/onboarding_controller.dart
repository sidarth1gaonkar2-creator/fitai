import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/tdee_calculator.dart';
import '../../../models/enums.dart';
import '../../../models/onboarding_progress.dart';
import '../../../models/user_profile.dart';
import '../../../providers/isar_provider.dart';
import '../../../providers/onboarding_gate_provider.dart';
import '../../../providers/unit_system_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../data/remote_profile_repository.dart';
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

    // Pre-fill the name from the Firebase auth profile when we don't have a
    // saved value yet. Email sign-up sets displayName to the typed name and
    // Google sign-in carries it from the Google account, so the user
    // shouldn't have to retype it on the first onboarding step.
    final fallbackName =
        FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';

    if (progress == null) {
      if (fallbackName.isNotEmpty) {
        state = state.copyWith(name: fallbackName);
      }
      return;
    }

    final savedName = progress.name?.trim() ?? '';
    state = OnboardingState(
      name: savedName.isNotEmpty ? savedName : fallbackName,
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

      final isar = _ref.read(isarProvider);

      // Merge into the existing profile row (reuse its id) rather than inserting
      // a duplicate — if onboarding is ever re-entered, this updates the single
      // profile in place and never orphans the prior one (which `findFirst`
      // could otherwise keep returning). Workout/nutrition history lives in
      // separate collections and is untouched.
      final existing =
          await isar.userProfiles.where().anyId().build().findFirst();
      final profile = (existing ?? UserProfile())
        ..name = state.name
        ..age = state.age!
        ..sex = state.sex!
        ..weight = state.weight!
        ..height = state.height!
        ..goal = state.goal!
        ..activityLevel = state.activityLevel!
        ..tdee = breakdown.goalAdjustedTarget;

      // Save profile and clear draft in a single transaction.
      await isar.writeTxn(() async {
        await isar.userProfiles.put(profile); // keeps existing id if present
        await isar.onboardingProgress.delete(1);
      });

      // Refresh (not invalidate) so the provider resolves with the
      // new profile before the router re-evaluates the redirect.
      _ref.invalidate(userProfileProvider);
      await _ref.read(userProfileProvider.future);

      // Persist completion to the PRIVATE Firestore profile — the source of
      // truth so future devices/installs route straight to the app. Best-effort
      // here: on failure the next-launch gate backfills it from the local
      // profile, so we don't block the user on a flaky write.
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // Tag the local profile as belonging to this account so the routing
        // gate trusts it (the local profile collection isn't uid-scoped yet).
        try {
          await _ref
              .read(sharedPreferencesProvider)
              .setString(localProfileOwnerKey, uid);
        } catch (_) {
          // Non-fatal — the gate still resolves via the remote write below.
        }
        try {
          await _ref
              .read(remoteProfileRepositoryProvider)
              .save(uid, RemoteProfile.fromLocal(profile));
        } catch (e, st) {
          AppLogger.error(
            'Onboarding: remote profile write failed (will backfill next launch)',
            error: e,
            stack: st,
          );
        }
        // Refresh the gate so the router advances to the app now.
        _ref.invalidate(onboardingGateProvider);
      }

      AppLogger.log('Onboarding completed');
    } catch (e, st) {
      AppLogger.error('Onboarding save failed', error: e, stack: st);
      rethrow;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  return OnboardingController(ref);
});
