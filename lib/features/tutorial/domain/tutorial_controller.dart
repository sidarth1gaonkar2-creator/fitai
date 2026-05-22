import 'package:flutter/widgets.dart';

/// Shape of the highlight cutout around the spotlighted widget. Rectangular
/// widgets (chips, list rows, tabs) use [roundedRect]; circular widgets like
/// the calorie ring or the settings gear use [circle].
enum SpotlightShape { circle, roundedRect }

/// One step in the onboarding tour. [targetKey] must be attached to the
/// widget that should be highlighted; [route] (if set) is pushed before the
/// spotlight is drawn so the target has time to mount and lay out.
class TutorialStep {
  const TutorialStep({
    required this.id,
    required this.title,
    required this.description,
    required this.targetKey,
    this.shape = SpotlightShape.roundedRect,
    this.route,
  });

  final String id;
  final String title;
  final String description;
  final GlobalKey targetKey;
  final SpotlightShape shape;
  final String? route;
}

/// Drives the tutorial: tracks current step, navigates between steps (with
/// optional route navigation), and persists the "completed" flag through an
/// injected callback so this class stays UI-framework-only.
class TutorialController extends ChangeNotifier {
  TutorialController({
    required this.steps,
    this.onNavigate,
    this.onComplete,
  });

  final List<TutorialStep> steps;

  /// Called when a step transition requires a tab/route change. Wired in the
  /// provider layer to a GoRouter.go() call.
  final void Function(String route)? onNavigate;

  /// Called once when the tutorial finishes (Skip or last "Get Started!").
  /// Wired in the provider to persist `tutorial_completed=true` in prefs.
  final Future<void> Function()? onComplete;

  int _currentIndex = 0;
  bool _isActive = false;

  bool get isActive => _isActive;
  int get currentIndex => _currentIndex;
  int get totalSteps => steps.length;
  TutorialStep? get currentStep =>
      _isActive && _currentIndex < steps.length ? steps[_currentIndex] : null;

  void start() {
    _currentIndex = 0;
    _isActive = true;
    final route = steps.isNotEmpty ? steps[0].route : null;
    if (route != null) onNavigate?.call(route);
    notifyListeners();
  }

  void next() {
    if (_currentIndex >= steps.length - 1) {
      complete();
      return;
    }
    _currentIndex++;
    final route = steps[_currentIndex].route;
    if (route != null) onNavigate?.call(route);
    notifyListeners();
  }

  void skip() => complete();

  Future<void> complete() async {
    _isActive = false;
    _currentIndex = 0;
    notifyListeners();
    try {
      await onComplete?.call();
    } catch (e, st) {
      // Don't crash the UI if persisting completion fails — log via debug
      // print so it shows up in dev, then silently move on.
      debugPrint('[tutorial] onComplete failed: $e\n$st');
    }
  }
}
