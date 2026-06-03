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

  /// Reads today's Move / Exercise / Stand goals from `HKActivitySummary`
  /// via the native bridge. The Flutter `health` package doesn't surface
  /// this API, so we route through `AppDelegate.fetchActivityGoals`.
  ///
  /// Returns null on non-iOS, when HealthKit is unavailable, or when the
  /// native side errored. Returns an empty map when HealthKit is reachable
  /// but there's no summary for today (e.g. no Apple Watch paired and the
  /// user hasn't opened the Fitness app yet). Otherwise returns the goal
  /// triple — each value rounded to int.
  Future<({int? moveCalories, int? exerciseMinutes, int? standHours})?>
      getAppleActivityGoals() async {
    if (!Platform.isIOS) return null;
    if (!await canUseHealthKit()) return null;
    try {
      final raw = await _healthCheckChannel
          .invokeMethod<Map<Object?, Object?>>('getActivityGoals');
      if (raw == null) return null;
      int? readInt(String key) {
        final v = raw[key];
        if (v is int) return v;
        if (v is num) return v.round();
        return null;
      }

      return (
        moveCalories: readInt('moveCalories'),
        exerciseMinutes: readInt('exerciseMinutes'),
        standHours: readInt('standHours'),
      );
    } catch (e, st) {
      debugPrint('[HealthService] getAppleActivityGoals threw: $e');
      AppLogger.error('getAppleActivityGoals threw', error: e, stack: st);
      return null;
    }
  }

  // Simple in-memory cache to avoid repeatedly hitting HealthKit while the user
  // pulls-to-refresh or navigates between tabs.
  static const _cacheTtl = Duration(minutes: 5);
  final Map<String, _CacheEntry> _cache = {};

  // ───────────────────────────────────────────────────────────────────
  // Type registries
  //
  // The authoritative read / write type lists live next to
  // [requestPermissions] below ([_fullReadTypes] and [_fullReadWriteTypes]).
  //
  // CRITICAL: HealthKit treats some quantity types as system-computed and
  // read-only — STEPS, ACTIVE_ENERGY_BURNED, BASAL_ENERGY_BURNED,
  // EXERCISE_TIME and APPLE_STAND_HOUR among them. Requesting *share*
  // (write) access on any of them raises NSInvalidArgumentException at the
  // native bridge and crashes the app before any Dart try/catch runs — and,
  // just as importantly, an app that wrote those types would be injecting a
  // second data source that Apple Health could double-count or misattribute,
  // breaking the user's Activity rings. We therefore READ those types and
  // never write them; only [_fullReadWriteTypes] (body mass/height, water,
  // workouts, and *dietary* energy/macros) is ever written.
  // ───────────────────────────────────────────────────────────────────

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
        return _activeEnergyForRange(_todayRange());
      });

  Future<double> getTodayCaloriesBurned() => _cached('total_cals', () async {
        // Active + basal. Active reuses the cached cascading reader; basal goes
        // native-first (statistics) then falls back to the plugin path so the
        // totals match what Apple Health itself reports.
        final active = await getTodayActiveCalories();
        final basal = await _energyForRange(
            'basal', _todayRange(), HealthDataType.BASAL_ENERGY_BURNED);
        return active + basal;
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
        final total = await _activeEnergyForRange((day, next));
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

  /// Active energy (kcal) for [range], trying every reader in order of
  /// reliability until one returns a positive value:
  ///   1. Native `HKStatisticsQuery` (.cumulativeSum) via [_nativeEnergy] —
  ///      the exact mechanism Apple's Move ring and our step reads use.
  ///   2. The `health` plugin's statistics path ([_sumCumulative]).
  ///   3. A raw sample-sum ([_sumNumeric]) as a last resort.
  ///
  /// A legitimate 0 (no movement yet) simply falls through all three and
  /// returns 0 — harmless. This cascade exists because the plugin paths were
  /// observed returning 0 on devices where HealthKit clearly had the data.
  Future<double> _activeEnergyForRange((DateTime, DateTime) range) =>
      _energyForRange('active', range, HealthDataType.ACTIVE_ENERGY_BURNED);

  /// Generic energy reader cascade for [nativeType] ('active' | 'basal') with
  /// the matching [HealthDataType] used for the plugin fallbacks.
  Future<double> _energyForRange(
    String nativeType,
    (DateTime, DateTime) range,
    HealthDataType pluginType,
  ) async {
    if (!Platform.isIOS) return 0;
    final native = await _nativeEnergy(nativeType, range);
    if (native != null && native > 0) return native;
    final viaPlugin = await _sumCumulative(pluginType, range);
    if (viaPlugin > 0) return viaPlugin;
    return _sumNumeric([pluginType], range);
  }

  /// Reads a cumulative energy total (kcal) for [type] ('active' | 'basal')
  /// over [range] through the native `HKStatisticsQuery` bridge in
  /// `AppDelegate.swift`. Returns null when the native side is unusable or
  /// errored, so [_energyForRange] can fall back to the plugin path. A native
  /// result of 0.0 is returned as-is (it means "HealthKit has no samples").
  Future<double?> _nativeEnergy(
    String type,
    (DateTime, DateTime) range,
  ) async {
    if (!Platform.isIOS) return null;
    if (!await canUseHealthKit()) return null;
    try {
      final kcal = await _healthCheckChannel.invokeMethod<double>(
        'getCumulativeEnergy',
        {
          'type': type,
          'startMs': range.$1.millisecondsSinceEpoch.toDouble(),
          'endMs': range.$2.millisecondsSinceEpoch.toDouble(),
        },
      );
      return kcal;
    } catch (e, st) {
      debugPrint('[HealthService] native energy ($type) threw: $e');
      AppLogger.error('native energy read failed', error: e, stack: st);
      return null;
    }
  }

  /// Native (share-only) authorization status string for an energy [type].
  /// HealthKit hides READ status, so this can read "notDetermined" even when
  /// reads are granted — it's a diagnostic that the type resolves and the
  /// bridge is reachable, not proof of read access.
  Future<String> _nativeAuthStatus(String type) async {
    if (!Platform.isIOS) return 'n/a (not iOS)';
    try {
      final s = await _healthCheckChannel
          .invokeMethod<String>('getEnergyAuthStatus', {'type': type});
      return s ?? 'unknown';
    } catch (e) {
      return 'error: $e';
    }
  }

  /// Gathers a side-by-side comparison of every active-energy read path plus
  /// context (steps, Move goal, auth status) for the admin-only "HealthKit
  /// Debug" dialog. Each value is computed independently so we can see exactly
  /// which path returns data and which returns 0.
  Future<Map<String, Object?>> collectDiagnostics() async {
    final range = _todayRange();
    Future<T> guard<T>(Future<T> Function() f, T fallback) async {
      try {
        return await f();
      } catch (e) {
        return fallback;
      }
    }

    final canUse = await guard(canUseHealthKit, false);
    final steps = await guard(getTodaySteps, -1);
    final native = await guard(() => _nativeEnergy('active', range), null);
    final pluginStats = await guard(
        () => _sumCumulative(HealthDataType.ACTIVE_ENERGY_BURNED, range), -1.0);
    final pluginRaw = await guard(
        () => _sumNumeric([HealthDataType.ACTIVE_ENERGY_BURNED], range), -1.0);
    final goals = await guard(getAppleActivityGoals, null);
    final auth = await guard(() => _nativeAuthStatus('active'), 'error');

    return {
      'canUseHealthKit': canUse,
      'steps': steps,
      'nativeActive': native,
      'pluginStatsActive': pluginStats,
      'pluginRawActive': pluginRaw,
      'moveGoal': goals?.moveCalories,
      'authStatus': auth,
    };
  }

  /// Sums a single cumulative quantity type over [range] using HealthKit's
  /// `HKStatisticsCollectionQuery` with `.cumulativeSum` — the SAME mechanism
  /// Apple's Activity rings / Fitness app use to compute the Move ring, and
  /// the same path our step reads already take via `getTotalStepsInInterval`.
  ///
  /// Why not `getHealthDataFromTypes` (a raw `HKSampleQuery`) + a manual sum?
  /// Active/basal energy is emitted as a long stream of tiny per-minute
  /// samples. Summing them in Dart is slower, and the `health` plugin dedupes
  /// the returned points by value/date — collapsing the many identical small
  /// energy samples and under-counting (or, in practice, reporting 0) even
  /// when HealthKit clearly has the data. The statistics query returns the
  /// authoritative cumulative total HealthKit itself maintains, so AtlasFit's
  /// number matches the ring.
  ///
  /// One bucket spanning the whole window (interval = window length) gives a
  /// single cumulative point; we still iterate in case HealthKit splits it.
  Future<double> _sumCumulative(
    HealthDataType type,
    (DateTime, DateTime) range,
  ) async {
    if (!Platform.isIOS) return 0;
    try {
      await _ensureConfigured();
      final seconds = range.$2.difference(range.$1).inSeconds;
      final points = await _health.getHealthIntervalDataFromTypes(
        startDate: range.$1,
        endDate: range.$2,
        types: [type],
        interval: seconds < 1 ? 1 : seconds,
      );
      double total = 0;
      for (final point in points) {
        final v = point.value;
        if (v is NumericHealthValue) {
          total += v.numericValue.toDouble();
        }
      }
      return total;
    } on _HealthUnavailable {
      return 0;
    } catch (e, st) {
      AppLogger.error(
        'Cumulative sum read failed for $type',
        error: e,
        stack: st,
      );
      return 0;
    }
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
