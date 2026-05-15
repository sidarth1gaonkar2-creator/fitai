import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';

class HealthService {
  HealthService();

  /// Native pre-flight channel registered by `ios/Runner/AppDelegate.swift`.
  /// Returns true only when the device supports HealthKit and `HKHealthStore`
  /// can be allocated. We call this before ever touching the [health] plugin
  /// so the plugin's `HKHealthStore` never runs without a sanity check.
  static const _healthCheckChannel =
      MethodChannel('com.sidarth.fitai/health_check');

  final Health _health = Health();
  bool _configured = false;

  /// Cached result of the native pre-flight. Tri-state:
  ///   * `null` — never run, will run on first access.
  ///   * `true` — native side said HealthKit is usable.
  ///   * `false` — native pre-flight returned false OR threw; we will NOT
  ///     touch the `health` plugin in this session.
  bool? _nativeReady;

  /// True if HealthKit can be used on this device. Cheap to call repeatedly;
  /// the underlying native check runs at most once per app launch. Always
  /// returns false on non-iOS or when the feature flag is off.
  Future<bool> canUseHealthKit() async {
    if (!AppConstants.healthKitEnabled) return false;
    if (!Platform.isIOS) return false;
    final cached = _nativeReady;
    if (cached != null) return cached;
    bool ok = false;
    try {
      ok = await _healthCheckChannel.invokeMethod<bool>('canUseHealthKit') ??
          false;
    } catch (e, st) {
      debugPrint('[HealthService] canUseHealthKit channel threw: $e');
      AppLogger.error('canUseHealthKit channel threw', error: e, stack: st);
      ok = false;
    }
    _nativeReady = ok;
    return ok;
  }

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

  /// `Health.configure()` returns a Future and the docs ("The plugin must be
  /// configured using the configure method before used") explicitly require it
  /// to complete before any other call into the plugin.
  ///
  /// Throws [_HealthUnavailable] if the native pre-flight failed — callers
  /// already wrap every public method in try/catch and return safe defaults,
  /// so this is the cheapest way to ensure NO call into the `health` plugin
  /// happens when HealthKit can't be used on this device.
  Future<void> _ensureConfigured() async {
    final ready = await canUseHealthKit();
    if (!ready) throw const _HealthUnavailable();
    if (_configured) return;
    try {
      await _health.configure();
      _configured = true;
    } catch (e, st) {
      AppLogger.error('HealthService.configure failed', error: e, stack: st);
      rethrow;
    }
  }

  // ───────────────────────────────────────────────────────────────────
  // Availability & permissions
  // ───────────────────────────────────────────────────────────────────

  /// True when the dashboard / settings should surface HealthKit affordances.
  /// Combines the feature flag, the platform check, and the native pre-flight.
  Future<bool> isAvailable() async => canUseHealthKit();

  /// Schema version of the permission set requested by [requestPermissions].
  /// Bump this whenever the type lists below change — the settings UI uses it
  /// to decide whether the current authorization is stale and the user
  /// should re-prompt iOS for the new types.
  ///
  /// History:
  ///   * v1 — diagnostic-only set (STEPS, ACTIVE_ENERGY, WEIGHT, WATER).
  ///   * v2 — full set: all safe read-only stats + writable food/weight/water/workout.
  ///   * v3 — added APPLE_STAND_HOUR, RESTING_HEART_RATE (read-only Fitness app data).
  ///   * v4 — added HEIGHT (read-write, user-set body measurement).
  static const int permissionsSchemaVersion = 4;

  /// Full read-only set requested with [HealthDataAccess.READ]. None of these
  /// are writable in HealthKit (they're system-computed or sensor-derived),
  /// so requesting WRITE access on any of them raises NSInvalidArgumentException.
  static const List<HealthDataType> _fullReadTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BASAL_ENERGY_BURNED,
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.FLIGHTS_CLIMBED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.EXERCISE_TIME,
    HealthDataType.APPLE_STAND_HOUR,
    HealthDataType.BODY_FAT_PERCENTAGE,
  ];

  /// Types we both read from and write to Apple Health.
  static const List<HealthDataType> _fullReadWriteTypes = [
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.WATER,
    HealthDataType.WORKOUT,
    HealthDataType.DIETARY_ENERGY_CONSUMED,
    HealthDataType.DIETARY_PROTEIN_CONSUMED,
    HealthDataType.DIETARY_CARBS_CONSUMED,
    HealthDataType.DIETARY_FATS_CONSUMED,
  ];

  Future<bool> requestPermissions() async {
    // Native pre-flight first. If HealthKit can't be used on this device or
    // the entitlement is missing, this returns false WITHOUT touching the
    // `health` plugin — so the plugin's HKHealthStore.requestAuthorization
    // can never be called in an environment that would crash it.
    final canUse = await canUseHealthKit();
    if (!canUse) {
      debugPrint(
        '[HealthService] requestPermissions skipped: '
        'native pre-flight returned false',
      );
      return false;
    }

    try {
      await _ensureConfigured();
    } on _HealthUnavailable {
      return false;
    } catch (e, st) {
      debugPrint('[HealthService] configure threw: $e');
      AppLogger.error('configure() threw', error: e, stack: st);
      return false;
    }

    final allTypes = <HealthDataType>[
      ..._fullReadTypes,
      ..._fullReadWriteTypes,
    ];
    final allPermissions = <HealthDataAccess>[
      ..._fullReadTypes.map((_) => HealthDataAccess.READ),
      ..._fullReadWriteTypes.map((_) => HealthDataAccess.READ_WRITE),
    ];
    assert(
      allTypes.length == allPermissions.length,
      'types/permissions must be same length',
    );

    try {
      debugPrint(
        '[HealthService] requesting auth for ${allTypes.length} types '
        '(schema v$permissionsSchemaVersion)',
      );
      final authorized = await _health.requestAuthorization(
        allTypes,
        permissions: allPermissions,
      );
      debugPrint('[HealthService] authorization result: $authorized');
      _cache.clear();
      return authorized;
    } catch (e, st) {
      debugPrint('[HealthService] requestAuthorization threw: $e');
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
          await _ensureConfigured();
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
          await _ensureConfigured();
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
      await _ensureConfigured();
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
          await _ensureConfigured();
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
      await _ensureConfigured();
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
      await _ensureConfigured();
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
      await _ensureConfigured();
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

  /// Apple Activity-style stand hours for today. HealthKit emits one
  /// `APPLE_STAND_HOUR` sample for every hour the user stood for at least one
  /// minute, so the count of distinct hour-of-day values gives us the stand
  /// ring number directly.
  Future<int> getTodayStandHours() => _cached('stand_hours', () async {
        if (!Platform.isIOS) return 0;
        try {
          await _ensureConfigured();
          final (start, end) = _todayRange();
          final data = await _health.getHealthDataFromTypes(
            types: [HealthDataType.APPLE_STAND_HOUR],
            startTime: start,
            endTime: end,
          );
          final hours = <int>{};
          for (final point in data) {
            hours.add(point.dateFrom.hour);
          }
          return hours.length;
        } on _HealthUnavailable {
          return 0;
        } catch (e, st) {
          debugPrint('[HealthService] stand hours error: $e');
          AppLogger.error('Stand hours read failed', error: e, stack: st);
          return 0;
        }
      });

  /// Resting heart rate from HealthKit's `RESTING_HEART_RATE` series (computed
  /// by iOS from passive HR readings — much more accurate than scanning for
  /// the lowest HR sample of the day).
  Future<int?> getRestingHeartRate() => _cached('resting_hr', () async {
        if (!Platform.isIOS) return null;
        try {
          await _ensureConfigured();
          final now = DateTime.now();
          final start = now.subtract(const Duration(days: 7));
          final data = await _health.getHealthDataFromTypes(
            types: [HealthDataType.RESTING_HEART_RATE],
            startTime: start,
            endTime: now,
          );
          if (data.isEmpty) return null;
          data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
          final v = data.first.value;
          if (v is NumericHealthValue) return v.numericValue.toInt();
          return null;
        } on _HealthUnavailable {
          return null;
        } catch (e, st) {
          debugPrint('[HealthService] resting HR error: $e');
          AppLogger.error('Resting HR read failed', error: e, stack: st);
          return null;
        }
      });

  /// VO2 max placeholder. VO2_MAX / VO2MAX are NOT defined in `health 13.3.1`'s
  /// `HealthDataType` enum, so we can't query the type without a compile-time
  /// error. Returns null and logs once at startup so the caller can hide the
  /// VO2 card.
  Future<double?> getLatestVO2Max() async {
    debugPrint(
      '[HealthService] VO2 max not available in health 13.3.1 — '
      'no HealthDataType.VO2MAX enum entry. Returning null.',
    );
    return null;
  }

  /// Recent workouts from Apple Fitness / Apple Watch / 3rd-party apps. Each
  /// row's `source` is the originating app name (e.g. "Apple Fitness",
  /// "Strava"). Energy is read from the workout's [WorkoutHealthValue].
  Future<List<Map<String, dynamic>>> getRecentFitnessWorkouts({
    int days = 7,
  }) async {
    if (!Platform.isIOS) return const [];
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: start,
        endTime: now,
      );
      final rows = <Map<String, dynamic>>[];
      for (final point in data) {
        final duration = point.dateTo.difference(point.dateFrom);
        String activity = 'workout';
        double calories = 0;
        final v = point.value;
        if (v is WorkoutHealthValue) {
          activity = v.workoutActivityType.name;
          calories = (v.totalEnergyBurned ?? 0).toDouble();
        }
        rows.add({
          'activity': activity,
          'start': point.dateFrom,
          'end': point.dateTo,
          'durationMinutes': duration.inMinutes,
          'calories': calories,
          'source': point.sourceName,
        });
      }
      rows.sort(
        (a, b) => (b['start'] as DateTime).compareTo(a['start'] as DateTime),
      );
      return rows;
    } on _HealthUnavailable {
      return const [];
    } catch (e, st) {
      debugPrint('[HealthService] fitness workouts error: $e');
      AppLogger.error('Fitness workouts read failed', error: e, stack: st);
      return const [];
    }
  }

  /// Generic 7-day rollup for a numeric quantity type. Used by the Fitness
  /// Trends charts on the Progress screen.
  Future<List<double>> getWeeklyData(HealthDataType type) async {
    if (!Platform.isIOS) return List<double>.filled(7, 0);
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final results = <double>[];
      for (int i = 6; i >= 0; i--) {
        final dayStart = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: i));
        final dayEnd = dayStart.add(const Duration(days: 1));
        final total = await _sumNumeric(
          [type],
          (dayStart, dayEnd),
          useCache: false,
        );
        results.add(total);
      }
      return results;
    } on _HealthUnavailable {
      return List<double>.filled(7, 0);
    } catch (e, st) {
      debugPrint('[HealthService] weekly data error for $type: $e');
      AppLogger.error(
        'Weekly data read failed for $type',
        error: e,
        stack: st,
      );
      return List<double>.filled(7, 0);
    }
  }

  /// Daily active calories burned over the last [days] days, oldest first.
  Future<List<double>> getDailyActiveCalories({int days = 7}) async {
    if (!Platform.isIOS) return List.filled(days, 0);
    try {
      await _ensureConfigured();
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
      await _ensureConfigured();
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
      await _ensureConfigured();
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

  /// Returns the most recent height value in centimetres, or null if there
  /// are no `HEIGHT` samples in HealthKit (or the user denied permission).
  Future<double?> getLatestHeight() => _cached('latest_height', () async {
        if (!Platform.isIOS) return null;
        try {
          await _ensureConfigured();
          final now = DateTime.now();
          final data = await _health.getHealthDataFromTypes(
            types: [HealthDataType.HEIGHT],
            startTime: now.subtract(const Duration(days: 3650)),
            endTime: now,
          );
          if (data.isEmpty) return null;
          data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
          final v = data.first.value;
          if (v is NumericHealthValue) {
            // HealthKit reports HEIGHT in METERS; convert to cm for the rest
            // of the app which uses centimetres throughout.
            return v.numericValue.toDouble() * 100;
          }
          return null;
        } on _HealthUnavailable {
          return null;
        } catch (e, st) {
          debugPrint('[HealthService] height read error: $e');
          AppLogger.error('Height read failed', error: e, stack: st);
          return null;
        }
      });

  /// Writes a single HEIGHT sample. [heightCm] is in centimetres; we convert
  /// to metres for the HealthKit METER unit.
  Future<bool> writeHeight(double heightCm) async {
    if (!Platform.isIOS) return false;
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final ok = await _health.writeHealthData(
        value: heightCm / 100,
        type: HealthDataType.HEIGHT,
        startTime: now,
        endTime: now,
        unit: HealthDataUnit.METER,
      );
      _cache.clear();
      return ok;
    } on _HealthUnavailable {
      return false;
    } catch (e, st) {
      AppLogger.error('Write height failed', error: e, stack: st);
      return false;
    }
  }

  Future<bool> writeWater(double liters) async {
    if (!Platform.isIOS) return false;
    try {
      await _ensureConfigured();
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
      await _ensureConfigured();
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
      getTodayStandHours(),
      getRestingHeartRate(),
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
      'standHours': results[9] as int,
      'restingHeartRate': results[10] as int?,
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
      await _ensureConfigured();
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

/// Sentinel thrown by [HealthService._ensureConfigured] when the native
/// pre-flight has confirmed HealthKit is not usable. Read/write methods
/// catch it silently and return safe defaults instead of logging an error
/// (no error has actually occurred — we're just refusing to call into a
/// disabled subsystem).
class _HealthUnavailable implements Exception {
  const _HealthUnavailable();
}
