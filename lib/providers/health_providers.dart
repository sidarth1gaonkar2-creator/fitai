import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/logger.dart';
import '../services/health_service.dart';
import '../services/health_sync_service.dart';
import 'isar_provider.dart';
import 'unit_system_provider.dart';
import 'user_profile_provider.dart';

// ───────────────────────────────────────────────────────────────────────────
// Service
// ───────────────────────────────────────────────────────────────────────────

final healthServiceProvider = Provider<HealthService>((ref) => HealthService());

final healthAvailableProvider = FutureProvider<bool>((ref) {
  if (!Platform.isIOS) return Future.value(false);
  return ref.read(healthServiceProvider).isAvailable();
});

// ───────────────────────────────────────────────────────────────────────────
// Preferences (SharedPreferences)
// ───────────────────────────────────────────────────────────────────────────

class HealthPrefs {
  const HealthPrefs({
    required this.connected,
    required this.showOnDashboard,
    required this.syncWorkouts,
    required this.syncNutrition,
    required this.syncWeight,
    required this.syncWater,
    required this.syncBodyMeasurements,
    required this.importWeight,
    required this.importHeight,
    required this.importBodyFat,
    required this.authorizedSchemaVersion,
  });

  final bool connected;
  final bool showOnDashboard;
  final bool syncWorkouts;
  final bool syncNutrition;
  final bool syncWeight;
  final bool syncWater;
  final bool syncBodyMeasurements;
  final bool importWeight;
  final bool importHeight;
  final bool importBodyFat;

  /// Schema version of the permission set the user last successfully
  /// authorized. Compared against [HealthService.permissionsSchemaVersion]
  /// to detect when the app now requests new HealthKit types that iOS hasn't
  /// been asked about yet.
  final int authorizedSchemaVersion;

  HealthPrefs copyWith({
    bool? connected,
    bool? showOnDashboard,
    bool? syncWorkouts,
    bool? syncNutrition,
    bool? syncWeight,
    bool? syncWater,
    bool? syncBodyMeasurements,
    bool? importWeight,
    bool? importHeight,
    bool? importBodyFat,
    int? authorizedSchemaVersion,
  }) {
    return HealthPrefs(
      connected: connected ?? this.connected,
      showOnDashboard: showOnDashboard ?? this.showOnDashboard,
      syncWorkouts: syncWorkouts ?? this.syncWorkouts,
      syncNutrition: syncNutrition ?? this.syncNutrition,
      syncWeight: syncWeight ?? this.syncWeight,
      syncWater: syncWater ?? this.syncWater,
      syncBodyMeasurements:
          syncBodyMeasurements ?? this.syncBodyMeasurements,
      importWeight: importWeight ?? this.importWeight,
      importHeight: importHeight ?? this.importHeight,
      importBodyFat: importBodyFat ?? this.importBodyFat,
      authorizedSchemaVersion:
          authorizedSchemaVersion ?? this.authorizedSchemaVersion,
    );
  }
}

class HealthPrefsNotifier extends StateNotifier<HealthPrefs> {
  HealthPrefsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static const _kConnected = 'health_connected';
  static const _kShowDashboard = 'health_show_dashboard';
  static const _kSyncWorkouts = 'health_sync_workouts';
  static const _kSyncNutrition = 'health_sync_nutrition';
  static const _kSyncWeight = 'health_sync_weight';
  static const _kSyncWater = 'health_sync_water';
  static const _kSyncMeasurements = 'health_export_measurements';
  static const _kImportWeight = 'health_import_weight';
  static const _kImportHeight = 'health_import_height';
  static const _kImportBodyFat = 'health_import_body_fat';
  static const _kAuthorizedSchema = 'health_authorized_schema_version';

  static HealthPrefs _load(SharedPreferences prefs) {
    return HealthPrefs(
      connected: prefs.getBool(_kConnected) ?? false,
      showOnDashboard: prefs.getBool(_kShowDashboard) ?? true,
      syncWorkouts: prefs.getBool(_kSyncWorkouts) ?? true,
      syncNutrition: prefs.getBool(_kSyncNutrition) ?? true,
      syncWeight: prefs.getBool(_kSyncWeight) ?? true,
      syncWater: prefs.getBool(_kSyncWater) ?? true,
      syncBodyMeasurements: prefs.getBool(_kSyncMeasurements) ?? true,
      importWeight: prefs.getBool(_kImportWeight) ?? true,
      importHeight: prefs.getBool(_kImportHeight) ?? true,
      importBodyFat: prefs.getBool(_kImportBodyFat) ?? false,
      authorizedSchemaVersion: prefs.getInt(_kAuthorizedSchema) ?? 0,
    );
  }

  Future<void> setConnected(bool value) async {
    state = state.copyWith(connected: value);
    await _prefs.setBool(_kConnected, value);
  }

  /// Records that the user just authorized the given [version] of the
  /// permission set. Called from the connect / refresh handlers after
  /// [HealthService.requestPermissions] returns true.
  Future<void> markAuthorizedAt(int version) async {
    state = state.copyWith(authorizedSchemaVersion: version);
    await _prefs.setInt(_kAuthorizedSchema, version);
  }

  Future<void> setShowOnDashboard(bool value) async {
    state = state.copyWith(showOnDashboard: value);
    await _prefs.setBool(_kShowDashboard, value);
  }

  Future<void> setSyncWorkouts(bool value) async {
    state = state.copyWith(syncWorkouts: value);
    await _prefs.setBool(_kSyncWorkouts, value);
  }

  Future<void> setSyncNutrition(bool value) async {
    state = state.copyWith(syncNutrition: value);
    await _prefs.setBool(_kSyncNutrition, value);
  }

  Future<void> setSyncWeight(bool value) async {
    state = state.copyWith(syncWeight: value);
    await _prefs.setBool(_kSyncWeight, value);
  }

  Future<void> setSyncWater(bool value) async {
    state = state.copyWith(syncWater: value);
    await _prefs.setBool(_kSyncWater, value);
  }

  Future<void> setSyncBodyMeasurements(bool value) async {
    state = state.copyWith(syncBodyMeasurements: value);
    await _prefs.setBool(_kSyncMeasurements, value);
  }

  Future<void> setImportWeight(bool value) async {
    state = state.copyWith(importWeight: value);
    await _prefs.setBool(_kImportWeight, value);
  }

  Future<void> setImportHeight(bool value) async {
    state = state.copyWith(importHeight: value);
    await _prefs.setBool(_kImportHeight, value);
  }

  Future<void> setImportBodyFat(bool value) async {
    state = state.copyWith(importBodyFat: value);
    await _prefs.setBool(_kImportBodyFat, value);
  }
}

final healthPrefsProvider =
    StateNotifierProvider<HealthPrefsNotifier, HealthPrefs>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HealthPrefsNotifier(prefs);
});

/// Convenience flag — true if the user is on iOS AND the Connect toggle is on.
final healthConnectedProvider = Provider<bool>((ref) {
  if (!Platform.isIOS) return false;
  return ref.watch(healthPrefsProvider).connected;
});

/// Should the dashboard surface Health data (depends on connected + showOnDashboard).
final healthDashboardEnabledProvider = Provider<bool>((ref) {
  if (!ref.watch(healthConnectedProvider)) return false;
  return ref.watch(healthPrefsProvider).showOnDashboard;
});

/// True when the user is connected but the permission set the app now
/// requests is newer than what they last authorized. The settings UI shows
/// a "Refresh permissions" hint so iOS can prompt for the new types.
final healthPermissionsStaleProvider = Provider<bool>((ref) {
  final prefs = ref.watch(healthPrefsProvider);
  if (!prefs.connected) return false;
  return prefs.authorizedSchemaVersion < HealthService.permissionsSchemaVersion;
});

// ───────────────────────────────────────────────────────────────────────────
// Today's reads — gated on healthConnectedProvider so disconnected returns
// safe defaults without calling HealthKit.
// ───────────────────────────────────────────────────────────────────────────

/// Wraps a provider body so a thrown exception from HealthService returns a
/// safe fallback rather than propagating into the widget's error state and
/// re-firing on every rebuild.
Future<T> _safe<T>(
  String name,
  Future<T> Function() compute,
  T fallback,
) async {
  try {
    return await compute();
  } catch (e, st) {
    debugPrint('[HealthProvider] $name failed: $e');
    AppLogger.error('[HealthProvider] $name failed', error: e, stack: st);
    return fallback;
  }
}

final todayStepsProvider = FutureProvider.autoDispose<int>((ref) async {
  if (!ref.watch(healthConnectedProvider)) return 0;
  return _safe(
    'todaySteps',
    () => ref.read(healthServiceProvider).getTodaySteps(),
    0,
  );
});

final todayCaloriesBurnedProvider =
    FutureProvider.autoDispose<double>((ref) async {
  if (!ref.watch(healthConnectedProvider)) return 0;
  return _safe(
    'todayCaloriesBurned',
    () => ref.read(healthServiceProvider).getTodayCaloriesBurned(),
    0.0,
  );
});

final todayActiveCaloriesProvider =
    FutureProvider.autoDispose<double>((ref) async {
  if (!ref.watch(healthConnectedProvider)) return 0;
  return _safe(
    'todayActiveCalories',
    () => ref.read(healthServiceProvider).getTodayActiveCalories(),
    0.0,
  );
});

final todayDistanceProvider =
    FutureProvider.autoDispose<double>((ref) async {
  if (!ref.watch(healthConnectedProvider)) return 0;
  return _safe(
    'todayDistance',
    () => ref.read(healthServiceProvider).getTodayDistance(),
    0.0,
  );
});

final todayFlightsProvider = FutureProvider.autoDispose<int>((ref) async {
  if (!ref.watch(healthConnectedProvider)) return 0;
  return _safe(
    'todayFlights',
    () => ref.read(healthServiceProvider).getTodayFlightsClimbed(),
    0,
  );
});

final todayActiveMinutesProvider =
    FutureProvider.autoDispose<int>((ref) async {
  if (!ref.watch(healthConnectedProvider)) return 0;
  return _safe(
    'todayActiveMinutes',
    () => ref.read(healthServiceProvider).getTodayActiveMinutes(),
    0,
  );
});

final latestHeartRateProvider =
    FutureProvider.autoDispose<int?>((ref) async {
  if (!ref.watch(healthConnectedProvider)) return null;
  return _safe<int?>(
    'latestHeartRate',
    () => ref.read(healthServiceProvider).getLatestHeartRate(),
    null,
  );
});

final latestWeightProvider =
    FutureProvider.autoDispose<double?>((ref) async {
  if (!ref.watch(healthConnectedProvider)) return null;
  return _safe<double?>(
    'latestWeight',
    () => ref.read(healthServiceProvider).getLatestWeight(),
    null,
  );
});

final lastNightSleepProvider =
    FutureProvider.autoDispose<int>((ref) async {
  if (!ref.watch(healthConnectedProvider)) return 0;
  return _safe(
    'lastNightSleep',
    () => ref.read(healthServiceProvider).getLastNightSleepMinutes(),
    0,
  );
});

const Map<String, dynamic> _emptyHealthSummary = {
  'steps': 0,
  'caloriesBurned': 0.0,
  'activeCalories': 0.0,
  'distanceMeters': 0.0,
  'flightsClimbed': 0,
  'activeMinutes': 0,
  'heartRate': null,
  'weightKg': null,
  'sleepMinutes': 0,
  'standHours': 0,
  'restingHeartRate': null,
};

final dailyHealthSummaryProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  if (!ref.watch(healthConnectedProvider)) return _emptyHealthSummary;
  return _safe(
    'dailySummary',
    () => ref.read(healthServiceProvider).getDailySummary(),
    _emptyHealthSummary,
  );
});

// ───────────────────────────────────────────────────────────────────────────
// Multi-day reads (charts)
// ───────────────────────────────────────────────────────────────────────────

final weeklyStepsProvider =
    FutureProvider.autoDispose<List<int>>((ref) async {
  if (!ref.watch(healthConnectedProvider)) return List<int>.filled(7, 0);
  return _safe(
    'weeklySteps',
    () => ref.read(healthServiceProvider).getDailySteps(days: 7),
    List<int>.filled(7, 0),
  );
});

final weeklyActiveCaloriesProvider =
    FutureProvider.autoDispose<List<double>>((ref) async {
  if (!ref.watch(healthConnectedProvider)) {
    return List<double>.filled(7, 0);
  }
  return _safe(
    'weeklyActiveCalories',
    () => ref.read(healthServiceProvider).getDailyActiveCalories(days: 7),
    List<double>.filled(7, 0),
  );
});

final healthWeightHistoryProvider = FutureProvider.autoDispose<
    List<({DateTime date, double weightKg})>>((ref) async {
  if (!ref.watch(healthConnectedProvider)) {
    return const <({DateTime date, double weightKg})>[];
  }
  return _safe(
    'weightHistory',
    () => ref.read(healthServiceProvider).getWeightHistory(days: 90),
    const <({DateTime date, double weightKg})>[],
  );
});

// ───────────────────────────────────────────────────────────────────────────
// Apple Fitness — new in schema v3
// ───────────────────────────────────────────────────────────────────────────

final todayStandHoursProvider =
    FutureProvider.autoDispose<int>((ref) async {
  if (!ref.watch(healthConnectedProvider)) return 0;
  return _safe(
    'standHours',
    () => ref.read(healthServiceProvider).getTodayStandHours(),
    0,
  );
});

final restingHeartRateProvider =
    FutureProvider.autoDispose<int?>((ref) async {
  if (!ref.watch(healthConnectedProvider)) return null;
  return _safe<int?>(
    'restingHeartRate',
    () => ref.read(healthServiceProvider).getRestingHeartRate(),
    null,
  );
});

/// Placeholder provider for VO2 max. The `health 13.3.1` package has no
/// VO2_MAX enum entry, so the service method always returns null. Kept as a
/// provider so the Progress screen can call it uniformly and so the value
/// starts flowing automatically the day VO2 lands in the package.
final latestVO2MaxProvider =
    FutureProvider.autoDispose<double?>((ref) async {
  if (!ref.watch(healthConnectedProvider)) return null;
  return _safe<double?>(
    'vo2Max',
    () => ref.read(healthServiceProvider).getLatestVO2Max(),
    null,
  );
});

final recentFitnessWorkoutsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  if (!ref.watch(healthConnectedProvider)) {
    return const <Map<String, dynamic>>[];
  }
  return _safe<List<Map<String, dynamic>>>(
    'recentFitnessWorkouts',
    () => ref.read(healthServiceProvider).getRecentFitnessWorkouts(),
    const <Map<String, dynamic>>[],
  );
});

/// Family provider: 7-day rollup for any numeric HealthDataType. Used by
/// the Fitness Trends section on the progress screen.
final weeklyHealthDataProvider =
    FutureProvider.autoDispose.family<List<double>, HealthDataType>(
        (ref, type) async {
  if (!ref.watch(healthConnectedProvider)) {
    return List<double>.filled(7, 0);
  }
  return _safe(
    'weeklyData($type)',
    () => ref.read(healthServiceProvider).getWeeklyData(type),
    List<double>.filled(7, 0),
  );
});

// ───────────────────────────────────────────────────────────────────────────
// Activity ring goals (persisted in SharedPreferences)
// ───────────────────────────────────────────────────────────────────────────

class ActivityGoals {
  const ActivityGoals({
    required this.moveCalories,
    required this.exerciseMinutes,
    required this.standHours,
  });

  final int moveCalories;
  final int exerciseMinutes;
  final int standHours;

  static const defaults = ActivityGoals(
    moveCalories: 500,
    exerciseMinutes: 30,
    standHours: 12,
  );
}

class ActivityGoalsNotifier extends StateNotifier<ActivityGoals> {
  ActivityGoalsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;
  static const _kMove = 'health_goal_move_kcal';
  static const _kExercise = 'health_goal_exercise_min';
  static const _kStand = 'health_goal_stand_hours';

  static ActivityGoals _load(SharedPreferences prefs) {
    return ActivityGoals(
      moveCalories: prefs.getInt(_kMove) ?? ActivityGoals.defaults.moveCalories,
      exerciseMinutes:
          prefs.getInt(_kExercise) ?? ActivityGoals.defaults.exerciseMinutes,
      standHours:
          prefs.getInt(_kStand) ?? ActivityGoals.defaults.standHours,
    );
  }

  Future<void> setMove(int v) async {
    state = ActivityGoals(
      moveCalories: v,
      exerciseMinutes: state.exerciseMinutes,
      standHours: state.standHours,
    );
    await _prefs.setInt(_kMove, v);
  }

  Future<void> setExercise(int v) async {
    state = ActivityGoals(
      moveCalories: state.moveCalories,
      exerciseMinutes: v,
      standHours: state.standHours,
    );
    await _prefs.setInt(_kExercise, v);
  }

  Future<void> setStand(int v) async {
    state = ActivityGoals(
      moveCalories: state.moveCalories,
      exerciseMinutes: state.exerciseMinutes,
      standHours: v,
    );
    await _prefs.setInt(_kStand, v);
  }
}

final activityGoalsProvider =
    StateNotifierProvider<ActivityGoalsNotifier, ActivityGoals>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ActivityGoalsNotifier(prefs);
});

/// Live Move/Exercise/Stand goals read straight from Apple Health via the
/// native bridge. Re-runs whenever the Health connection flips on/off so a
/// just-connected user sees their real goals on the next frame. Returns
/// null on Android or when the bridge isn't usable.
final appleHealthActivityGoalsProvider = FutureProvider<
    ({int? moveCalories, int? exerciseMinutes, int? standHours})?>((ref) async {
  if (!Platform.isIOS) return null;
  if (!ref.watch(healthConnectedProvider)) return null;
  return ref.read(healthServiceProvider).getAppleActivityGoals();
});

/// The activity goals the dashboard should actually display.
///
/// Priority per field:
///   1. The Apple Health goal (when readable + non-null).
///   2. A profile-derived estimate (Move only: ~25% of TDEE, rounded to 50).
///   3. The user's manual override from `activityGoalsProvider` (which itself
///      falls back to the baked-in defaults when no override exists).
///
/// The Move-from-TDEE fallback exists because a Watch-less user with no
/// Fitness app set-up has no HKActivitySummary at all — showing "500" in
/// that case is misleading. 25% of TDEE matches Apple's rough rule of
/// thumb for the active-energy portion of maintenance.
final effectiveActivityGoalsProvider = Provider<ActivityGoals>((ref) {
  final manual = ref.watch(activityGoalsProvider);
  final apple = ref.watch(appleHealthActivityGoalsProvider).valueOrNull;
  final profile = ref.watch(userProfileProvider).valueOrNull;

  int profileMove() {
    final tdee = profile?.tdee;
    if (tdee == null || tdee <= 0) return manual.moveCalories;
    // Round to nearest 50 kcal so the displayed denominator reads as a
    // human-set number rather than a fractional estimate.
    final raw = (tdee * 0.25).round();
    return (raw / 50).round() * 50;
  }

  return ActivityGoals(
    moveCalories: apple?.moveCalories ?? profileMove(),
    exerciseMinutes: apple?.exerciseMinutes ?? manual.exerciseMinutes,
    standHours: apple?.standHours ?? manual.standHours,
  );
});

// ───────────────────────────────────────────────────────────────────────────
// Bidirectional sync
// ───────────────────────────────────────────────────────────────────────────

final healthSyncServiceProvider = Provider<HealthSyncService>((ref) {
  return HealthSyncService(
    healthService: ref.read(healthServiceProvider),
    isar: ref.read(isarProvider),
  );
});

/// Imports latest weight / height from Apple Health into Isar at app launch.
/// Returns nothing (the providers that read Isar will pick up changes on
/// their next rebuild).
Future<void> runHealthSyncOnLaunch(Ref ref) async {
  if (!ref.read(healthConnectedProvider)) return;
  final prefs = ref.read(healthPrefsProvider);
  try {
    await ref.read(healthSyncServiceProvider).importFromHealthKit(
          importWeight: prefs.importWeight,
          importHeight: prefs.importHeight,
        );
  } catch (e, st) {
    debugPrint('[HealthSync] launch sync failed: $e');
    AppLogger.error('Launch sync failed', error: e, stack: st);
  }
}
