import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/progress_providers.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../providers/workout_providers.dart';

/// Builds a context string summarising the user's recent data.
/// Injected into the system prompt so the AI coach can give
/// personalised advice.
class CoachContextBuilder {
  static Future<String> build(Ref ref) async {
    final parts = <String>[];

    // --- User profile ---
    final profile = await ref.read(userProfileProvider.future);
    if (profile != null) {
      parts.add(
        'User: ${profile.name}, '
        'Goal: ${profile.goal.name}, '
        'TDEE: ${profile.tdee.toInt()} kcal, '
        'Weight: ${profile.weight} kg',
      );
    }

    // --- Current streak ---
    try {
      final streak = await ref.read(streakProvider.future);
      parts.add('Current streak: $streak days');
    } catch (_) {}

    // --- Last 7 days of workouts ---
    try {
      final allWorkouts = await ref.read(allWorkoutsProvider.future);
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recent =
          allWorkouts.where((w) => w.date.isAfter(sevenDaysAgo)).toList();

      if (recent.isNotEmpty) {
        final exerciseNames = <String>{};
        for (final workout in recent) {
          await workout.exercises.load();
          for (final ex in workout.exercises) {
            exerciseNames.add(ex.name);
          }
        }
        parts.add(
          'Last 7 days: ${recent.length} workouts '
          '(${exerciseNames.take(8).join(", ")})',
        );
      } else {
        parts.add('Last 7 days: no workouts logged');
      }
    } catch (_) {}

    // --- PRs ---
    try {
      final prs = await ref.read(personalRecordsProvider.future);
      if (prs.isNotEmpty) {
        final topPrs = prs.entries.take(5).map(
            (e) => '${e.key}: ${e.value.toStringAsFixed(1)} kg');
        parts.add('Personal records: ${topPrs.join(", ")}');
      }
    } catch (_) {}

    // --- Nutrition averages (7 days) ---
    try {
      final trends = await ref.read(nutritionTrendsProvider(7).future);
      if (trends.dailyCalories.isNotEmpty) {
        parts.add(
          'Nutrition avg (7d): '
          '${trends.avgCalories.toInt()} kcal, '
          '${trends.avgProtein.toInt()}g protein, '
          '${trends.avgCarbs.toInt()}g carbs, '
          '${trends.avgFat.toInt()}g fat',
        );
      }
    } catch (_) {}

    return parts.join('\n');
  }
}
