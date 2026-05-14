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
    channel.setMethodCallHandler { call, result in
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
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
