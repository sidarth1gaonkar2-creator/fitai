class AppConstants {
  static const String appName = 'SwoleCoach';
  static const int onboardingStepCount = 6;

  /// Master kill-switch for the Apple Health integration. When false, every
  /// HealthKit code path returns early and the Connect UI is hidden — the
  /// `health` Flutter plugin is never loaded. Ship with `true` (the native
  /// pre-flight in [HealthService.canUseHealthKit] still has to pass before
  /// the plugin is touched); flip to `false` only as a remote emergency
  /// switch if HealthKit is crashing in production.
  static const bool healthKitEnabled = true;
}
