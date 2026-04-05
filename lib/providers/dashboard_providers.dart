import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/nutrition_log.dart';
import '../models/workout.dart';
import 'isar_provider.dart';

/// Today's nutrition log (or null if nothing logged yet).
final todayNutritionProvider = FutureProvider<NutritionLog?>((ref) async {
  final isar = ref.watch(isarProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  return isar.nutritionLogs
      .where()
      .dateBetween(startOfDay, endOfDay, includeUpper: false)
      .findFirst();
});

/// Today's workout (or null if none logged yet).
final todayWorkoutProvider = FutureProvider<Workout?>((ref) async {
  final isar = ref.watch(isarProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  return isar.workouts
      .filter()
      .dateBetween(startOfDay, endOfDay, includeUpper: false)
      .findFirst();
});

/// Consecutive-day streak: how many days in a row (ending today or yesterday)
/// the user has logged a workout OR a nutrition entry.
final streakProvider = FutureProvider<int>((ref) async {
  final isar = ref.watch(isarProvider);
  int streak = 0;
  var checkDate = DateTime.now();

  while (true) {
    final start = DateTime(checkDate.year, checkDate.month, checkDate.day);
    final end = start.add(const Duration(days: 1));

    final hasNutrition = await isar.nutritionLogs
        .where()
        .dateBetween(start, end, includeUpper: false)
        .count() >
        0;

    final hasWorkout = await isar.workouts
        .filter()
        .dateBetween(start, end, includeUpper: false)
        .count() >
        0;

    if (hasNutrition || hasWorkout) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  return streak;
});

/// In-memory water intake (glasses). Resets each session.
final waterIntakeProvider = StateProvider<int>((ref) => 0);
