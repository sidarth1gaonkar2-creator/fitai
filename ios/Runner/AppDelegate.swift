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
      case "getCumulativeEnergy":
        // Sums an energy quantity (active or basal) over a date range using a
        // native HKStatisticsQuery with .cumulativeSum — the SAME mechanism
        // that makes the step read reliable. The Flutter `health` plugin's
        // sample-query + Dart-side sum was returning 0 for active energy on
        // some devices; this native path mirrors what Apple's own Fitness app
        // does to compute the Move ring. Returns the kcal total (Double), or
        // null on error so Dart can fall back to the plugin path.
        self?.sumCumulativeEnergy(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Sums `activeEnergyBurned` or `basalEnergyBurned` (in kilocalories) over a
  /// caller-supplied date range using `HKStatisticsQuery` with `.cumulativeSum`.
  ///
  /// Arguments (from Dart): `type` ("active" | "basal"), `startMs`, `endMs`
  /// (epoch milliseconds). Returns a `Double` kcal total, `0` when HealthKit
  /// has no samples, or `nil` when the bridge is unusable / the query errors —
  /// the Dart side treats `nil` as "fall back to the plugin".
  private func sumCumulativeEnergy(
    call: FlutterMethodCall, result: @escaping FlutterResult
  ) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(nil)
      return
    }
    let args = call.arguments as? [String: Any]
    let typeKey = (args?["type"] as? String) ?? "active"
    let startMs = (args?["startMs"] as? NSNumber)?.doubleValue
    let endMs = (args?["endMs"] as? NSNumber)?.doubleValue
    guard let startMs, let endMs else {
      NSLog("[HealthEnergy] missing startMs/endMs")
      result(nil)
      return
    }

    let identifier: HKQuantityTypeIdentifier =
      typeKey == "basal" ? .basalEnergyBurned : .activeEnergyBurned
    guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier)
    else {
      result(nil)
      return
    }

    let store = HKHealthStore()
    let start = Date(timeIntervalSince1970: startMs / 1000.0)
    let end = Date(timeIntervalSince1970: endMs / 1000.0)
    let predicate = HKQuery.predicateForSamples(
      withStart: start, end: end, options: .strictStartDate
    )

    let query = HKStatisticsQuery(
      quantityType: quantityType,
      quantitySamplePredicate: predicate,
      options: .cumulativeSum
    ) { _, statistics, error in
      if let error = error {
        NSLog("[HealthEnergy] \(typeKey) query error: \(error.localizedDescription)")
        DispatchQueue.main.async { result(nil) }
        return
      }
      let kcal =
        statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
      DispatchQueue.main.async { result(kcal) }
    }
    store.execute(query)
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

      // Query the last 14 days of activity summaries (not just today). The
      // Watch's daily summary for "today" is often missing until the user
      // has worn the device and the Fitness app has synced — querying a
      // window lets us pick the most recent summary with a non-zero Move
      // goal so we still show the user's real goal first thing in the
      // morning, before any data has flowed in for the current day.
      let cal = Calendar.current
      let endDate = Date()
      guard let startDate = cal.date(byAdding: .day, value: -14, to: endDate)
      else {
        result(nil)
        return
      }
      let startComp = cal.dateComponents(
        [.year, .month, .day], from: startDate)
      let endComp = cal.dateComponents(
        [.year, .month, .day], from: endDate)
      var startComponents = startComp
      var endComponents = endComp
      startComponents.calendar = cal
      endComponents.calendar = cal

      // Swift 6 / Xcode 26 importer surfaces this as
      // `predicate(forActivitySummariesBetweenStart:end:)` (a static method
      // on HKQuery). The older Swift name `predicateForActivitySummary(between:end:)`
      // does not exist in current SDKs and produces "Extra arguments" /
      // "Missing argument for parameter 'with'" build errors.
      let predicate = HKQuery.predicate(
        forActivitySummariesBetweenStart: startComponents,
        end: endComponents)
      let query = HKActivitySummaryQuery(predicate: predicate) {
        _, summaries, error in
        if let error = error {
          NSLog("[HealthKitGoals] query error: \(error.localizedDescription)")
          result(nil)
          return
        }
        let list = summaries ?? []
        if list.isEmpty {
          NSLog("[HealthKitGoals] no summaries returned in 14-day window")
          // Empty (not nil) tells Dart "bridge OK, no data" so it falls
          // through to the profile-derived fallback.
          result([String: Any]())
          return
        }

        // Pick the most recent summary whose Move goal is > 0. Walking the
        // list backwards is robust: HealthKit may return summaries in
        // ascending date order, and a freshly-rolled-over day may have a
        // zero goal until the device commits the day's targets.
        func nonZeroMove(_ s: HKActivitySummary) -> Bool {
          return s.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie()) > 0
        }
        let picked = list.reversed().first(where: nonZeroMove) ?? list.last!

        let moveKcal: Double
        let exerciseMin: Double
        let standHours: Double
        if #available(iOS 14.0, *) {
          // iOS 14+ exposes goals in the unit the user prefers; we ask
          // for the canonical units explicitly so the values are stable
          // regardless of locale.
          moveKcal = picked.activeEnergyBurnedGoal
            .doubleValue(for: .kilocalorie())
          exerciseMin = picked.appleExerciseTimeGoal
            .doubleValue(for: .minute())
          standHours = picked.appleStandHoursGoal
            .doubleValue(for: .count())
        } else {
          // Pre-iOS 14: only Move and Exercise goals are exposed; Stand
          // goal API doesn't exist, default to the Apple-standard 12.
          moveKcal = picked.activeEnergyBurnedGoal
            .doubleValue(for: .kilocalorie())
          exerciseMin = 30
          standHours = 12
        }

        // If even the most recent valid summary has a zero Move goal, omit
        // the field so Dart falls back to profileMove() rather than showing
        // "0 / 0 kcal" — that's almost certainly an unconfigured account
        // rather than a real goal of zero.
        var payload: [String: Any] = [
          "exerciseMinutes": Int(exerciseMin.rounded()),
          "standHours": Int(standHours.rounded()),
        ]
        if moveKcal > 0 {
          payload["moveCalories"] = Int(moveKcal.rounded())
        }
        NSLog("[HealthKitGoals] returning \(payload) (from \(list.count) summaries)")
        result(payload)
      }
      store.execute(query)
    }
  }
}
