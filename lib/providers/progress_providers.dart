import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../core/utils/logger.dart';
import '../features/progress/domain/milestone.dart';
import '../models/nutrition_log.dart';
import '../models/user_profile.dart';
import '../models/weight_entry.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import 'dashboard_providers.dart';
import 'health_providers.dart';
import 'isar_provider.dart';
import 'user_profile_provider.dart';
import 'workout_providers.dart';

// ---------------------------------------------------------------------------
// Weight
// ---------------------------------------------------------------------------

/// All weight entries sorted by date ascending.
final weightEntriesProvider = FutureProvider<List<WeightEntry>>((ref) async {
  final isar = ref.watch(isarProvider);
  return isar.weightEntrys.where().sortByDate().findAll();
});

/// Saves a weight entry for today and updates the user profile.
Future<bool> saveWeightEntry(WidgetRef ref, double kg) async {
  final isar = ref.read(isarProvider);
  try {
    await isar.writeTxn(() async {
      final now = DateTime.now();
      final entry = WeightEntry()
        ..date = DateTime(now.year, now.month, now.day)
        ..weightKg = kg;
      await isar.weightEntrys.put(entry);

      // Update profile weight
      final profile =
          await isar.userProfiles.where().anyId().build().findFirst();
      if (profile != null) {
        profile.weight = kg;
        await isar.userProfiles.put(profile);
      }
    });
    ref.invalidate(weightEntriesProvider);
    ref.invalidate(userProfileProvider);

    // Fire-and-forget Apple Health weight sync.
    if (ref.read(healthConnectedProvider) &&
        ref.read(healthPrefsProvider).syncWeight) {
      ref
          .read(healthServiceProvider)
          .writeWeight(kg)
          .catchError((Object e, StackTrace st) {
        AppLogger.error('Apple Health weight sync failed',
            error: e, stack: st);
        return false;
      });
    }
    return true;
  } catch (_) {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Strength
// ---------------------------------------------------------------------------

/// Currently selected exercise name for the strength chart.
final selectedExerciseProvider = StateProvider<String?>((ref) => null);

/// Distinct exercise names from all logged workouts.
final exerciseNamesProvider = FutureProvider<List<String>>((ref) async {
  final isar = ref.watch(isarProvider);
  final exercises = await isar.workoutExercises.where().findAll();
  final names = exercises.map((e) => e.name).toSet().toList()..sort();
  return names;
});

/// Best set weight per workout date for a given exercise name.
final strengthHistoryProvider = FutureProvider.family<
    List<({DateTime date, double weight})>, String>((ref, exerciseName) async {
  final isar = ref.watch(isarProvider);
  final workouts = await isar.workouts.where().sortByDate().findAll();

  final points = <({DateTime date, double weight})>[];

  for (final workout in workouts) {
    await workout.exercises.load();
    for (final exercise in workout.exercises) {
      if (exercise.name.toLowerCase() != exerciseName.toLowerCase()) continue;
      await exercise.sets.load();
      double best = 0;
      for (final s in exercise.sets) {
        if (s.weight > best) best = s.weight;
      }
      if (best > 0) {
        points.add((
          date: DateTime(
              workout.date.year, workout.date.month, workout.date.day),
          weight: best,
        ));
      }
    }
  }

  return points;
});

// ---------------------------------------------------------------------------
// Nutrition trends
// ---------------------------------------------------------------------------

/// Selected range for nutrition trends: 7, 30, or 90.
final selectedNutritionRangeProvider = StateProvider<int>((ref) => 7);

class NutritionTrendData {
  const NutritionTrendData({
    required this.avgCalories,
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
    required this.dailyCalories,
  });

  final double avgCalories;
  final double avgProtein;
  final double avgCarbs;
  final double avgFat;
  /// Daily calorie values for sparkline (oldest first).
  final List<double> dailyCalories;
}

/// Average daily nutrition over the last N days.
final nutritionTrendsProvider =
    FutureProvider.family<NutritionTrendData, int>((ref, days) async {
  final isar = ref.watch(isarProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: days));

  final logs = await isar.nutritionLogs
      .where()
      .dateGreaterThan(start)
      .sortByDate()
      .findAll();

  if (logs.isEmpty) {
    return const NutritionTrendData(
      avgCalories: 0,
      avgProtein: 0,
      avgCarbs: 0,
      avgFat: 0,
      dailyCalories: [],
    );
  }

  double totalCal = 0, totalPro = 0, totalCarb = 0, totalFat = 0;
  final dailyCals = <double>[];

  for (final log in logs) {
    totalCal += log.totalCalories;
    totalPro += log.totalProtein;
    totalCarb += log.totalCarbs;
    totalFat += log.totalFat;
    dailyCals.add(log.totalCalories);
  }

  final count = logs.length;
  return NutritionTrendData(
    avgCalories: totalCal / count,
    avgProtein: totalPro / count,
    avgCarbs: totalCarb / count,
    avgFat: totalFat / count,
    dailyCalories: dailyCals,
  );
});

// ---------------------------------------------------------------------------
// Milestones
// ---------------------------------------------------------------------------

final milestonesProvider = FutureProvider<List<Milestone>>((ref) async {
  final isar = ref.watch(isarProvider);

  final workoutCount = await isar.workouts.count();
  final records = await ref.watch(personalRecordsProvider.future);
  final streak = await ref.watch(streakProvider.future);

  // Count distinct logged days
  final allWorkouts = await isar.workouts.where().findAll();
  final allLogs = await isar.nutritionLogs.where().findAll();
  final loggedDays = <DateTime>{};
  for (final w in allWorkouts) {
    loggedDays.add(DateTime(w.date.year, w.date.month, w.date.day));
  }
  for (final l in allLogs) {
    loggedDays.add(DateTime(l.date.year, l.date.month, l.date.day));
  }

  return [
    Milestone(
      title: 'First Workout',
      icon: Icons.fitness_center,
      isEarned: workoutCount >= 1,
    ),
    Milestone(
      title: 'First PR',
      icon: Icons.emoji_events,
      isEarned: records.isNotEmpty,
    ),
    Milestone(
      title: '7 Day Streak',
      icon: Icons.local_fire_department,
      isEarned: streak >= 7,
    ),
    Milestone(
      title: '30 Days Logged',
      icon: Icons.calendar_month,
      isEarned: loggedDays.length >= 30,
    ),
    Milestone(
      title: '100 Workouts',
      icon: Icons.military_tech,
      isEarned: workoutCount >= 100,
    ),
  ];
});
