import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../models/workout_set.dart';

/// One-time data fix for users who imported workout history before the
/// imperial/metric storage was unified. WorkoutSet.weight is canonically
/// stored in kg, but some early imperial-flow code wrote the lbs value
/// straight into `weight`, leaving sets with absurd weights (a 315 lb
/// bench saved as 315 kg → 694 lb on reload).
///
/// Heuristic: any set with weight > 200 kg is almost certainly a lbs
/// number that was never converted; reasonable real-world strength sets
/// for the supported exercises top out around 250 kg (≈ 550 lb), and
/// users above that ceiling don't use this app's lbs flow. Dividing by
/// 2.205 maps the lbs value back to kg.
///
/// Gated by a SharedPreferences flag — runs at most once per install.
class WeightMigrationService {
  static const _suspiciousThresholdKg = 200.0;
  static const _lbsPerKg = 2.205;

  static Future<int> migrate(Isar isar) async {
    final candidates =
        await isar.workoutSets.filter().weightGreaterThan(_suspiciousThresholdKg).findAll();
    if (candidates.isEmpty) return 0;

    await isar.writeTxn(() async {
      for (final set in candidates) {
        set.weight = set.weight / _lbsPerKg;
        await isar.workoutSets.put(set);
      }
    });
    if (kDebugMode) {
      debugPrint(
          '[WeightMigration] fixed ${candidates.length} oversized sets');
    }
    return candidates.length;
  }
}
