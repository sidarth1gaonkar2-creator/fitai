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

/// All weight entries sorted by date ascending, with at most one entry per
/// calendar day. Historical same-day duplicates (which drew a vertical spike on
/// the chart) are collapsed here, keeping the most recently inserted entry
/// (largest id) for each date.
final weightEntriesProvider = FutureProvider<List<WeightEntry>>((ref) async {
  final isar = ref.watch(isarProvider);
  final all = await isar.weightEntrys.where().sortByDate().findAll();

  final byDate = <DateTime, WeightEntry>{};
  for (final e in all) {
    final d = DateTime(e.date.year, e.date.month, e.date.day);
    final existing = byDate[d];
    if (existing == null || e.id > existing.id) byDate[d] = e;
  }
  final deduped = byDate.values.toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  return deduped;
});

/// Saves a weight entry for today and updates the user profile. Replaces any
/// existing entry for today (one entry per calendar day) so re-logging doesn't
/// create a duplicate.
Future<bool> saveWeightEntry(WidgetRef ref, double kg) async {
  final isar = ref.read(isarProvider);
  try {
    await isar.writeTxn(() async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Remove any existing entries for today so we replace rather than
      // duplicate (the chart drew a spike when two entries shared a date).
      final existingToday =
          await isar.weightEntrys.filter().dateEqualTo(today).findAll();
      for (final old in existingToday) {
        await isar.weightEntrys.delete(old.id);
      }

      final entry = WeightEntry()
        ..date = today
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
  } catch (e, st) {
    AppLogger.error('Failed to save weight entry', error: e, stack: st);
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

/// The exercise the user has logged most often. Used to pick a sensible
/// default selection on the strength curve chart so first-time visitors see
/// a populated chart instead of an empty picker. Returns null when no
/// exercises have been logged yet.
final mostFrequentExerciseProvider = FutureProvider<String?>((ref) async {
  final isar = ref.watch(isarProvider);
  final exercises = await isar.workoutExercises.where().findAll();
  if (exercises.isEmpty) return null;
  final counts = <String, int>{};
  for (final e in exercises) {
    counts[e.name] = (counts[e.name] ?? 0) + 1;
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.first.key;
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

/// Per-session strength data: best 1RM (Epley), max weight, and total
/// volume for an exercise. Drives the multi-metric strength curve chart.
///
/// Each point is the AGGREGATE for one session — if the user logs multiple
/// sets of the same exercise on the same day, this rolls them up.
final strengthCurveProvider = FutureProvider.family<
    List<
        ({
          DateTime date,
          double oneRepMaxKg,
          double maxWeightKg,
          double volumeKg
        })>,
    String>((ref, exerciseName) async {
  final isar = ref.watch(isarProvider);
  final workouts = await isar.workouts.where().sortByDate().findAll();

  final points = <({
    DateTime date,
    double oneRepMaxKg,
    double maxWeightKg,
    double volumeKg
  })>[];

  for (final workout in workouts) {
    await workout.exercises.load();
    for (final exercise in workout.exercises) {
      if (exercise.name.toLowerCase() != exerciseName.toLowerCase()) continue;
      await exercise.sets.load();
      double bestOrm = 0;
      double maxWeight = 0;
      double volume = 0;
      for (final s in exercise.sets) {
        if (s.weight <= 0 || s.reps <= 0) continue;
        // Epley: 1RM = w * (1 + reps / 30)
        final orm = s.weight * (1 + s.reps / 30.0);
        if (orm > bestOrm) bestOrm = orm;
        if (s.weight > maxWeight) maxWeight = s.weight;
        volume += s.weight * s.reps;
      }
      if (bestOrm <= 0 && maxWeight <= 0 && volume <= 0) continue;
      points.add((
        date: DateTime(
            workout.date.year, workout.date.month, workout.date.day),
        oneRepMaxKg: bestOrm,
        maxWeightKg: maxWeight,
        volumeKg: volume,
      ));
    }
  }

  return points;
});

// ---------------------------------------------------------------------------
// Nutrition trends
// ---------------------------------------------------------------------------

/// Selected range for nutrition trends: 7, 30, or 90.
final selectedNutritionRangeProvider = StateProvider<int>((ref) => 7);

/// Nutrition totals for a single calendar day. Days with no log are still
/// represented (all-zero) so the trend bar charts stay aligned to the calendar.
class DailyNutrition {
  const DailyNutrition({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final DateTime date;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
}

class NutritionTrendData {
  const NutritionTrendData({
    required this.avgCalories,
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
    required this.daily,
  });

  final double avgCalories;
  final double avgProtein;
  final double avgCarbs;
  final double avgFat;

  /// One entry per day across the requested range, oldest first. Includes
  /// zero-value days so the bar charts/X-axis line up with the calendar.
  final List<DailyNutrition> daily;

  /// Daily calorie values (oldest first). Kept for the AI coach context.
  List<double> get dailyCalories => daily.map((d) => d.calories).toList();

  /// True when at least one day in the range has logged calories.
  bool get hasData => daily.any((d) => d.calories > 0);
}

/// Average daily nutrition over the last N days, plus the per-day series the
/// trend bar charts plot. Averages are computed over *logged* days only (so a
/// gap day doesn't drag the average down), while [NutritionTrendData.daily]
/// carries every calendar day in the range (zeros included).
final nutritionTrendsProvider =
    FutureProvider.family<NutritionTrendData, int>((ref, days) async {
  final isar = ref.watch(isarProvider);
  final now = DateTime.now();
  final todayMidnight = DateTime(now.year, now.month, now.day);
  final start = todayMidnight.subtract(Duration(days: days - 1));

  final logs = await isar.nutritionLogs
      .where()
      .dateGreaterThan(start.subtract(const Duration(seconds: 1)))
      .sortByDate()
      .findAll();

  // Index logs by midnight date for O(1) per-day lookup.
  final byDate = <DateTime, NutritionLog>{};
  for (final log in logs) {
    byDate[DateTime(log.date.year, log.date.month, log.date.day)] = log;
  }

  final daily = <DailyNutrition>[];
  double totalCal = 0, totalPro = 0, totalCarb = 0, totalFat = 0;
  var loggedDays = 0;
  for (int i = days - 1; i >= 0; i--) {
    final d = todayMidnight.subtract(Duration(days: i));
    final log = byDate[d];
    daily.add(DailyNutrition(
      date: d,
      calories: log?.totalCalories ?? 0,
      protein: log?.totalProtein ?? 0,
      carbs: log?.totalCarbs ?? 0,
      fat: log?.totalFat ?? 0,
    ));
    if (log != null) {
      totalCal += log.totalCalories;
      totalPro += log.totalProtein;
      totalCarb += log.totalCarbs;
      totalFat += log.totalFat;
      loggedDays++;
    }
  }

  final divisor = loggedDays == 0 ? 1 : loggedDays;
  return NutritionTrendData(
    avgCalories: totalCal / divisor,
    avgProtein: totalPro / divisor,
    avgCarbs: totalCarb / divisor,
    avgFat: totalFat / divisor,
    daily: daily,
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
