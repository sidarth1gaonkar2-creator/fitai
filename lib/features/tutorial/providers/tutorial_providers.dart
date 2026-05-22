import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/unit_system_provider.dart' show sharedPreferencesProvider;
import '../../../routing/app_router.dart';
import '../domain/tutorial_controller.dart';
import '../domain/tutorial_steps.dart';

const _kTutorialCompletedKey = 'tutorial_completed';

/// The tutorial controller. Re-created on rebuild only if [tutorialSteps]
/// changes (it's a top-level final, so effectively never).
///
/// `onNavigate` is wired to the appRouter so a step with a [TutorialStep.route]
/// switches tabs before the overlay reads the target's RenderBox.
/// `onComplete` flips a SharedPreferences flag so the tutorial doesn't fire
/// again on subsequent launches.
final tutorialControllerProvider =
    ChangeNotifierProvider<TutorialController>((ref) {
  return TutorialController(
    steps: tutorialSteps,
    onNavigate: (route) {
      final router = ref.read(appRouterProvider);
      router.go(route);
    },
    onComplete: () async {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool(_kTutorialCompletedKey, true);
    },
  );
});

/// True while the tutorial is on screen. Cheap to watch from anywhere; widgets
/// can use this to gate spotlight-only behaviour (extra padding, disabling
/// background interactions, etc.).
final tutorialActiveProvider = Provider<bool>((ref) {
  return ref.watch(tutorialControllerProvider).isActive;
});

/// True if the tutorial has *never* been completed on this install. Reads
/// SharedPreferences directly — synchronous because the prefs instance is
/// hydrated at app start and overridden into the provider scope.
final shouldShowTutorialProvider = Provider<bool>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return prefs.getBool(_kTutorialCompletedKey) != true;
});
