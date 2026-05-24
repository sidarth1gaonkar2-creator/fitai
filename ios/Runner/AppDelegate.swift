import Flutter
import HealthKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Method channel name used by Dart's HealthService.canUseHealthKit().
  private static let healthCheckChannel = "com.sidarth.fitai/health_check"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerHealthKitCheckChannel(registry: engineBridge.pluginRegistry)
  }

  /// Registers a method channel that lets Dart pre-flight HealthKit availability
  /// without ever touching the `health` Flutter plugin. The two things we can
  /// safely check from Swift without triggering an entitlement crash are:
  ///
  ///  1. `HKHealthStore.isHealthDataAvailable()` — a class method that
  ///     returns false on iPad and other devices with no Health app.
  ///  2. Allocating an `HKHealthStore` — does not consult the entitlement
  ///     until you actually call `requestAuthorization`.
  ///
  /// If either fails the Dart side knows to never call into the health
  /// package and the user never sees the Connect button.
  private func registerHealthKitCheckChannel(registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "HealthKitCheckPlugin")
    else { return }
    let channel = FlutterMethodChannel(
      name: Self.healthCheckChannel,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "canUseHealthKit":
        guard HKHealthStore.isHealthDataAvailable() else {
          NSLog("[HealthKitCheck] isHealthDataAvailable() = false")
          result(false)
          return
        }
        // Instantiating the store itself never triggers the entitlement
        // check (the check happens on requestAuthorization). We do the
        // alloc here so any future native exception path runs through this
        // bridge instead of the health-plugin bridge.
        _ = HKHealthStore()
        NSLog("[HealthKitCheck] HKHealthStore allocated OK")
        result(true)
      case "getActivityGoals":
        // Returns today's Move / Exercise / Stand goals from HKActivitySummary.
        // The Flutter `health` package doesn't expose this API, so we route
        // through here. All three goals are nullable — null means "not set"
        // (e.g. user has no Apple Watch paired for Exercise/Stand, or hasn't
        // ever opened the Fitness app to seed the Move goal).
        self?.fetchActivityGoals(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Queries `HKActivitySummaryQuery` for today's record and returns the
  /// goal values to Flutter as a `[String: Any]` map. Requests read
  /// permission for the activity summary type if it hasn't been granted
  /// yet (a no-op if the user has already granted via the health plugin's
  /// general request — HealthKit dedupes the prompt).
  private func fetchActivityGoals(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(nil)
      return
    }
    let store = HKHealthStore()
    let summaryType = HKObjectType.activitySummaryType()

    store.requestAuthorization(toShare: nil, read: [summaryType]) {
      granted, error in
      if let error = error {
        NSLog("[HealthKitGoals] auth error: \(error.localizedDescription)")
        result(nil)
        return
      }
      if !granted {
        // Authorization status can be "not determined" → granted=false even
        // when no error. We try the query anyway — `queryActivitySummaries`
        // returns an empty array rather than throwing when unauthorized.
        NSLog("[HealthKitGoals] activitySummary auth not granted")
      }

      let cal = Calendar.current
      let today = cal.dateComponents([.year, .month, .day], from: Date())
      var todayComponents = today
      todayComponents.calendar = cal

      let predicate = HKQuery.predicateForActivitySummary(with: todayComponents)
      let query = HKActivitySummaryQuery(predicate: predicate) {
        _, summaries, error in
        if let error = error {
          NSLog("[HealthKitGoals] query error: \(error.localizedDescription)")
          result(nil)
          return
        }
        guard let summary = summaries?.first else {
          NSLog("[HealthKitGoals] no summary returned for today")
          // Send an empty map so Dart can distinguish "no Apple Health data
          // yet today" from "native bridge failed". Both legitimately fall
          // through to the profile-derived fallback.
          result([String: Any]())
          return
        }

        let moveKcal: Double
        let exerciseMin: Double
        let standHours: Double
        if #available(iOS 14.0, *) {
          // iOS 14+ exposes goals in the unit the user prefers; we ask
          // for the canonical units explicitly so the values are stable
          // regardless of locale.
          moveKcal = summary.activeEnergyBurnedGoal
            .doubleValue(for: .kilocalorie())
          exerciseMin = summary.appleExerciseTimeGoal
            .doubleValue(for: .minute())
          standHours = summary.appleStandHoursGoal
            .doubleValue(for: .count())
        } else {
          // Pre-iOS 14: only Move and Exercise goals are exposed; Stand
          // goal API doesn't exist, default to the Apple-standard 12.
          moveKcal = summary.activeEnergyBurnedGoal
            .doubleValue(for: .kilocalorie())
          exerciseMin = 30
          standHours = 12
        }

        let payload: [String: Any] = [
          "moveCalories": Int(moveKcal.rounded()),
          "exerciseMinutes": Int(exerciseMin.rounded()),
          "standHours": Int(standHours.rounded()),
        ]
        NSLog("[HealthKitGoals] returning \(payload)")
        result(payload)
      }
      store.execute(query)
    }
  }
}
