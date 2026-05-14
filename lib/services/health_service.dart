import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../core/utils/logger.dart';

class HealthService {
  HealthService();

  final Health _health = Health();
  bool _configured = false;

  // Simple in-memory cache to avoid repeatedly hitting HealthKit while the user
  // pulls-to-refresh or navigates between tabs.
  static const _cacheTtl = Duration(minutes: 5);
  final Map<String, _CacheEntry> _cache = {};

  // ───────────────────────────────────────────────────────────────────
  // Type registries
  //
  // CRITICAL: HealthKit treats some quantity types as system-computed and
  // read-only. Requesting *share* (write) access on any of them raises
  // NSInvalidArgumentException at the native bridge and crashes the app
  // before any try/catch on the Dart side can run. The split below has
  // been validated against the iOS HealthKit reference — every type in
  // [_readWriteTypes] is writable, every type in [_readOnlyTypes] is not.
  // ───────────────────────────────────────────────────────────────────

  /// Read-only on iOS. Most are computed by the OS (exercise time, flights,
  /// basal energy) or only meaningful as observations (heart rate, sleep).
  static const List<HealthDataType> _readOnlyTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BASAL_ENERGY_BURNED,
    HealthDataType.HEART_RATE,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.FLIGHTS_CLIMBED,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.EXERCISE_TIME,
  ];

  /// Types the app both reads from and writes to Apple Health.
  static const List<HealthDataType> _readWriteTypes = [
    HealthDataType.WEIGHT,
    HealthDataType.WATER,
    HealthDataType.WORKOUT,
    HealthDataType.DIETARY_ENERGY_CONSUMED,
    HealthDataType.DIETARY_PROTEIN_CONSUMED,
    HealthDataType.DIETARY_CARBS_CONSUMED,
    HealthDataType.DIETARY_FATS_CONSUMED,
  ];

  /// All types the app may read (read-only + read-write).
  static const List<HealthDataType> readTypes = [
    ..._readOnlyTypes,
    ..._readWriteTypes,
  ];

  /// All types the app may write (subset of read-write).
  static const List<HealthDataType> writeTypes = _readWriteTypes;

  void _ensureConfigured() {
    if (_configured) return;
    _health.configure();
    _configured = true;
  }

  // ───────────────────────────────────────────────────────────────────
  // Availability & permissions
  // ───────────────────────────────────────────────────────────────────

  Future<bool> isAvailable() async {
    if (!Platform.isIOS) return false;
    try {
      _ensureConfigured();
      return _health.isDataTypeAvailable(HealthDataType.STEPS);
    } catch (e, st) {
      AppLogger.error('HealthService.isAvailable failed', error: e, stack: st);
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    if (!Platform.isIOS) return false;
    try {
      _ensureConfigured();
      // Build parallel `types` and `permissions` arrays. Every read-only type
      // gets HealthDataAccess.READ; every read-write type gets READ_WRITE.
      // Mismatched lengths or wrong access-for-type both crash natively.
      final types = <HealthDataType>[
        ..._readOnlyTypes,
        ..._readWriteTypes,
      ];
      final permissions = <HealthDataAccess>[
        ..._readOnlyTypes.map((_) => HealthDataAccess.READ),
        ..._readWriteTypes.map((_) => HealthDataAccess.READ_WRITE),
      ];
      assert(
        types.length == permissions.length,
        'types and permissions must be the same length',
      );
      final granted = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
      _cache.clear();
      return granted;
    } catch (e, st) {
      debugPrint('[HealthService] requestPermissions crashed: $e');
      AppLogger.error(
        'HealthService.requestPermissions failed',
        error: e,
        stack: st,
      );
      return false;
    }
  }

  void invalidateCache() => _cache.clear();

  // ───────────────────────────────────────────────────────────────────
  // Read — totals
  // ───────────────────────────────────────────────────────────────────

  Future<int> getTodaySteps() => _cached('steps', () async {
        if (!Platform.isIOS) return 0;
        try {
          _ensureConfigured();
          final now = DateTime.now();
          final midnight = DateTime(now.year, now.month, now.day);
          final steps =
              await _health.getTotalStepsInInterval(midnight, now);
          return steps ?? 0;
        } catch (e, st) {
          AppLogger.error('Steps read failed', error: e, stack: st);
          return 0;
        }
      });

  Future<double> getTodayActiveCalories() =>
      _cached('active_cals', () async {
        return _sumNumeric([HealthDataType.ACTIVE_ENERGY_BURNED], _todayRange());
      });

  Future<double> getTodayCaloriesBurned() => _cached('total_cals', () async {
        return _sumNumeric(
          [
            HealthDataType.ACTIVE_ENERGY_BURNED,
            HealthDataType.BASAL_ENERGY_BURNED,
          ],
          _todayRange(),
        );
      });

  Future<double> getTodayDistance() => _cached('distance', () async {
        return _sumNumeric(
          [HealthDataType.DISTANCE_WALKING_RUNNING],
          _todayRange(),
        );
      });

  Future<int> getTodayFlightsClimbed() => _cached('flights', () async {
        final total = await _sumNumeric(
          [HealthDataType.FLIGHTS_CLIMBED],
          _todayRange(),
        );
        return total.toInt();
      });

  Future<int> getTodayActiveMinutes() =>
      _cached('exercise_time', () async {
        final total = await _sumNumeric(
          [HealthDataType.EXERCISE_TIME],
          _todayRange(),
        );
        return total.toInt();
      });

  Future<int?> getLatestHeartRate() => _cached('latest_hr', () async {
        if (!Platform.isIOS) return null;
        try {
          _ensureConfigured();
          final now = DateTime.now();
          final data = await _health.getHealthDataFromTypes(
            types: [HealthDataType.HEART_RATE],
            startTime: now.subtract(const Duration(hours: 6)),
            endTime: now,
          );
          if (data.isEmpty) return null;
          data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
          final v = data.first.value;
          if (v is NumericHealthValue) return v.numericValue.toInt();
          return null;
        } catch (e, st) {
          AppLogger.error('Heart rate read failed', error: e, stack: st);
          return null;
        }
      });

  Future<List<HealthDataPoint>> getHeartRate(
    DateTime start,
    DateTime end,
  ) async {
    if (!Platform.isIOS) return [];
    try {
      _ensureConfigured();
      return await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );
    } catch (e, st) {
      AppLogger.error('Heart rate range read failed', error: e, stack: st);
      return [];
    }
  }

  Future<double?> getLatestWeight() => _cached('latest_weight', () async {
        if (!Platform.isIOS) return null;
        try {
          _ensureConfigured();
          final now = DateTime.now();
          final data = await _health.getHealthDataFromTypes(
            types: [HealthDataType.WEIGHT],
            startTime: now.subtract(const Duration(days: 30)),
            endTime: now,
          );
          if (data.isEmpty) return null;
          data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
          final v = data.first.value;
          if (v is NumericHealthValue) return v.numericValue.toDouble();
          return null;
        } catch (e, st) {
          AppLogger.error('Weight read failed', error: e, stack: st);
          return null;
        }
      });

  /// Returns daily weight points over the last [days] days from Apple Health.
  Future<List<({DateTime date, double weightKg})>> getWeightHistory({
    int days = 90,
  }) async {
    if (!Platform.isIOS) return [];
    try {
      _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: start,
        endTime: now,
      );
      final points = <({DateTime date, double weightKg})>[];
      for (final p in data) {
        final v = p.value;
        if (v is NumericHealthValue) {
          points.add((
            date: DateTime(
              p.dateFrom.year,
              p.dateFrom.month,
              p.dateFrom.day,
            ),
            weightKg: v.numericValue.toDouble(),
          ));
        }
      }
      points.sort((a, b) => a.date.compareTo(b.date));
      return points;
    } catch (e, st) {
      AppLogger.error('Weight history read failed', error: e, stack: st);
      return [];
    }
  }

  Future<int> getLastNightSleepMinutes() =>
      _cached('sleep_minutes', () async {
        final dur = await getLastNightSleep();
        return dur.inMinutes;
      });

  Future<Duration> getLastNightSleep() async {
    if (!Platform.isIOS) return Duration.zero;
    try {
      _ensureConfigured();
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP, HealthDataType.SLEEP_IN_BED],
        startTime: yesterday,
        endTime: now,
      );
      Duration total = Duration.zero;
      for (final point in data) {
        total += point.dateTo.difference(point.dateFrom);
      }
      return total;
    } catch (e, st) {
      AppLogger.error('Sleep read failed', error: e, stack: st);
      return Duration.zero;
    }
  }

  /// Daily steps over the last [days] days, oldest first. Returns the goal-sized
  /// list even if some days had no data (those become 0).
  Future<List<int>> getDailySteps({int days = 7}) async {
    if (!Platform.isIOS) return List.filled(days, 0);
    try {
      _ensureConfigured();
      final now = DateTime.now();
      final result = <int>[];
      for (int i = days - 1; i >= 0; i--) {
        final day = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: i));
        final next = day.add(const Duration(days: 1));
        final steps = await _health.getTotalStepsInInterval(day, next);
        result.add(steps ?? 0);
      }
      return result;
    } catch (e, st) {
      AppLogger.error('Daily steps read failed', error: e, stack: st);
      return List.filled(days, 0);
    }
  }

  /// Daily active calories burned over the last [days] days, oldest first.
  Future<List<double>> getDailyActiveCalories({int days = 7}) async {
    if (!Platform.isIOS) return List.filled(days, 0);
    try {
      _ensureConfigured();
      final now = DateTime.now();
      final result = <double>[];
      for (int i = days - 1; i >= 0; i--) {
        final day = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: i));
        final next = day.add(const Duration(days: 1));
        final total = await _sumNumeric(
          [HealthDataType.ACTIVE_ENERGY_BURNED],
          (day, next),
          useCache: false,
        );
        result.add(total);
      }
      return result;
    } catch (e, st) {
      AppLogger.error('Daily calories read failed', error: e, stack: st);
      return List.filled(days, 0);
    }
  }

  // ───────────────────────────────────────────────────────────────────
  // Writes
  // ───────────────────────────────────────────────────────────────────

  Future<bool> writeWorkout({
    required DateTime start,
    required DateTime end,
    required double caloriesBurned,
    required String workoutType,
  }) async {
    if (!Platform.isIOS) return false;
    try {
      _ensureConfigured();
      final ok = await _health.writeWorkoutData(
        activityType: _mapWorkoutType(workoutType),
        start: start,
        end: end,
        totalEnergyBurned: caloriesBurned.round(),
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
      );
      _cache.clear();
      return ok;
    } catch (e, st) {
      AppLogger.error('Write workout failed', error: e, stack: st);
      return false;
    }
  }

  Future<bool> writeWeight(double weightKg) async {
    if (!Platform.isIOS) return false;
    try {
      _ensureConfigured();
      final now = DateTime.now();
      final ok = await _health.writeHealthData(
        value: weightKg,
        type: HealthDataType.WEIGHT,
        startTime: now,
        endTime: now,
        unit: HealthDataUnit.KILOGRAM,
      );
      _cache.clear();
      return ok;
    } catch (e, st) {
      AppLogger.error('Write weight failed', error: e, stack: st);
      return false;
    }
  }

  Future<bool> writeWater(double liters) async {
    if (!Platform.isIOS) return false;
    try {
      _ensureConfigured();
      final now = DateTime.now();
      return await _health.writeHealthData(
        value: liters,
        type: HealthDataType.WATER,
        startTime: now,
        endTime: now,
        unit: HealthDataUnit.LITER,
      );
    } catch (e, st) {
      AppLogger.error('Write water failed', error: e, stack: st);
      return false;
    }
  }

  Future<bool> writeNutrition({
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    if (!Platform.isIOS) return false;
    try {
      _ensureConfigured();
      final now = DateTime.now();
      final results = await Future.wait([
        _health.writeHealthData(
          value: calories,
          type: HealthDataType.DIETARY_ENERGY_CONSUMED,
          startTime: now,
          endTime: now,
          unit: HealthDataUnit.KILOCALORIE,
        ),
        _health.writeHealthData(
          value: protein,
          type: HealthDataType.DIETARY_PROTEIN_CONSUMED,
          startTime: now,
          endTime: now,
          unit: HealthDataUnit.GRAM,
        ),
        _health.writeHealthData(
          value: carbs,
          type: HealthDataType.DIETARY_CARBS_CONSUMED,
          startTime: now,
          endTime: now,
          unit: HealthDataUnit.GRAM,
        ),
        _health.writeHealthData(
          value: fat,
          type: HealthDataType.DIETARY_FATS_CONSUMED,
          startTime: now,
          endTime: now,
          unit: HealthDataUnit.GRAM,
        ),
      ]);
      return results.every((r) => r == true);
    } catch (e, st) {
      AppLogger.error('Write nutrition failed', error: e, stack: st);
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────────
  // Aggregate
  // ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDailySummary() async {
    final results = await Future.wait([
      getTodaySteps(),
      getTodayCaloriesBurned(),
      getTodayActiveCalories(),
      getTodayDistance(),
      getTodayFlightsClimbed(),
      getTodayActiveMinutes(),
      getLatestHeartRate(),
      getLatestWeight(),
      getLastNightSleepMinutes(),
    ]);
    return {
      'steps': results[0] as int,
      'caloriesBurned': results[1] as double,
      'activeCalories': results[2] as double,
      'distanceMeters': results[3] as double,
      'flightsClimbed': results[4] as int,
      'activeMinutes': results[5] as int,
      'heartRate': results[6] as int?,
      'weightKg': results[7] as double?,
      'sleepMinutes': results[8] as int,
    };
  }

  // ───────────────────────────────────────────────────────────────────
  // Internals
  // ───────────────────────────────────────────────────────────────────

  (DateTime, DateTime) _todayRange() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return (midnight, now);
  }

  Future<double> _sumNumeric(
    List<HealthDataType> types,
    (DateTime, DateTime) range, {
    bool useCache = true,
  }) async {
    if (!Platform.isIOS) return 0;
    try {
      _ensureConfigured();
      final data = await _health.getHealthDataFromTypes(
        types: types,
        startTime: range.$1,
        endTime: range.$2,
      );
      double total = 0;
      for (final point in data) {
        final v = point.value;
        if (v is NumericHealthValue) {
          total += v.numericValue.toDouble();
        }
      }
      return total;
    } catch (e, st) {
      AppLogger.error(
        'Numeric sum read failed for ${types.join(",")}',
        error: e,
        stack: st,
      );
      return 0;
    }
  }

  Future<T> _cached<T>(String key, Future<T> Function() compute) async {
    final hit = _cache[key];
    if (hit != null && !hit.isExpired) {
      return hit.value as T;
    }
    final value = await compute();
    _cache[key] = _CacheEntry(value, DateTime.now().add(_cacheTtl));
    return value;
  }

  HealthWorkoutActivityType _mapWorkoutType(String type) {
    switch (type.toLowerCase()) {
      case 'strength':
      case 'weight training':
        return HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING;
      case 'cardio':
      case 'running':
        return HealthWorkoutActivityType.RUNNING;
      case 'cycling':
      case 'biking':
        return HealthWorkoutActivityType.BIKING;
      case 'hiit':
        return HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING;
      case 'yoga':
        return HealthWorkoutActivityType.YOGA;
      case 'swimming':
        return HealthWorkoutActivityType.SWIMMING;
      default:
        return HealthWorkoutActivityType.OTHER;
    }
  }

  @visibleForTesting
  bool get isConfigured => _configured;
}

class _CacheEntry {
  _CacheEntry(this.value, this.expiresAt);
  final Object? value;
  final DateTime expiresAt;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
