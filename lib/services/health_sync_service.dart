import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../core/utils/logger.dart';
import '../models/user_profile.dart';
import '../models/weight_entry.dart';
import 'health_service.dart';

/// Bidirectional sync glue between Apple Health and the app's local Isar
/// store. Public methods are no-ops on non-iOS, on disconnected users, and
/// when individual import/export toggles are off — gating happens at the
/// provider layer, not here, so this service can be unit-tested in isolation.
class HealthSyncService {
  HealthSyncService({
    required HealthService healthService,
    required Isar isar,
  })  : _healthService = healthService,
        _isar = isar;

  final HealthService _healthService;
  final Isar _isar;

  /// Import the latest Apple Health values that the user opted into. Called
  /// after app launch (gated on health_connected). Failures are logged but
  /// never bubble — sync must NEVER block app boot.
  Future<HealthImportResult> importFromHealthKit({
    bool importWeight = true,
    bool importHeight = true,
  }) async {
    if (!Platform.isIOS) return const HealthImportResult();
    var weightImported = false;
    var heightImported = false;

    if (importWeight) {
      try {
        final hkWeight = await _healthService.getLatestWeight();
        if (hkWeight != null && hkWeight > 0) {
          weightImported = await _maybeImportWeight(hkWeight);
        }
      } catch (e, st) {
        AppLogger.error('Health weight import failed', error: e, stack: st);
      }
    }

    if (importHeight) {
      try {
        final hkHeightCm = await _healthService.getLatestHeight();
        if (hkHeightCm != null && hkHeightCm > 0) {
          heightImported = await _maybeImportHeight(hkHeightCm);
        }
      } catch (e, st) {
        AppLogger.error('Health height import failed', error: e, stack: st);
      }
    }

    return HealthImportResult(
      weightImported: weightImported,
      heightImported: heightImported,
    );
  }

  /// Fire-and-forget export of a batch of values. Each parameter is optional
  /// — pass only the ones that just changed. Caller is responsible for
  /// checking the per-type "sync to Apple Health" toggle before invoking.
  Future<void> exportToHealthKit({
    double? weightKg,
    double? heightCm,
    double? waterLiters,
    Map<String, double>? nutrition,
  }) async {
    if (!Platform.isIOS) return;
    try {
      if (weightKg != null) {
        await _healthService.writeWeight(weightKg);
      }
      if (heightCm != null) {
        await _healthService.writeHeight(heightCm);
      }
      if (waterLiters != null) {
        await _healthService.writeWater(waterLiters);
      }
      if (nutrition != null) {
        await _healthService.writeNutrition(
          calories: nutrition['calories'] ?? 0,
          protein: nutrition['protein'] ?? 0,
          carbs: nutrition['carbs'] ?? 0,
          fat: nutrition['fat'] ?? 0,
        );
      }
    } catch (e, st) {
      debugPrint('[HealthSync] export error: $e');
      AppLogger.error('Health export failed', error: e, stack: st);
    }
  }

  /// If [hkWeightKg] differs from our latest stored weight (or we have none),
  /// insert a new `WeightEntry` and update the user profile.
  Future<bool> _maybeImportWeight(double hkWeightKg) async {
    final latest =
        await _isar.weightEntrys.where().sortByDateDesc().findFirst();
    // Only import when the HealthKit value differs noticeably (>0.05 kg) from
    // our latest entry, OR when we have no entries at all. This stops the
    // sync from inserting a duplicate every launch.
    if (latest != null && (latest.weightKg - hkWeightKg).abs() < 0.05) {
      return false;
    }
    await _isar.writeTxn(() async {
      final today = DateTime.now();
      final entry = WeightEntry()
        ..date = DateTime(today.year, today.month, today.day)
        ..weightKg = hkWeightKg;
      await _isar.weightEntrys.put(entry);
      final profile =
          await _isar.userProfiles.where().anyId().build().findFirst();
      if (profile != null) {
        profile.weight = hkWeightKg;
        await _isar.userProfiles.put(profile);
      }
    });
    return true;
  }

  /// Updates the user profile's height if HealthKit reports a different
  /// value. We don't keep a height history in Isar — profile is the
  /// source of truth.
  Future<bool> _maybeImportHeight(double hkHeightCm) async {
    final profile =
        await _isar.userProfiles.where().anyId().build().findFirst();
    if (profile == null) return false;
    if ((profile.height - hkHeightCm).abs() < 0.1) return false;
    await _isar.writeTxn(() async {
      profile.height = hkHeightCm;
      await _isar.userProfiles.put(profile);
    });
    return true;
  }
}

class HealthImportResult {
  const HealthImportResult({
    this.weightImported = false,
    this.heightImported = false,
  });

  final bool weightImported;
  final bool heightImported;

  bool get anyImported => weightImported || heightImported;
}
