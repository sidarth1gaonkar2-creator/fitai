import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/logger.dart';
import '../services/health_service.dart';
import 'unit_system_provider.dart';

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
  });

  final bool connected;
  final bool showOnDashboard;
  final bool syncWorkouts;
  final bool syncNutrition;
  final bool syncWeight;
  final bool syncWater;

  HealthPrefs copyWith({
    bool? connected,
    bool? showOnDashboard,
    bool? syncWorkouts,
    bool? syncNutrition,
    bool? syncWeight,
    bool? syncWater,
  }) {
    return HealthPrefs(
      connected: connected ?? this.connected,
      showOnDashboard: showOnDashboard ?? this.showOnDashboard,
      syncWorkouts: syncWorkouts ?? this.syncWorkouts,
      syncNutrition: syncNutrition ?? this.syncNutrition,
      syncWeight: syncWeight ?? this.syncWeight,
      syncWater: syncWater ?? this.syncWater,
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

  static HealthPrefs _load(SharedPreferences prefs) {
    return HealthPrefs(
      connected: prefs.getBool(_kConnected) ?? false,
      showOnDashboard: prefs.getBool(_kShowDashboard) ?? true,
      syncWorkouts: prefs.getBool(_kSyncWorkouts) ?? true,
      syncNutrition: prefs.getBool(_kSyncNutrition) ?? true,
      syncWeight: prefs.getBool(_kSyncWeight) ?? true,
      syncWater: prefs.getBool(_kSyncWater) ?? true,
    );
  }

  Future<void> setConnected(bool value) async {
    state = state.copyWith(connected: value);
    await _prefs.setBool(_kConnected, value);
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
