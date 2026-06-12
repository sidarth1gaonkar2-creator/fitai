import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../providers/nutrition_providers.dart';
import '../../../providers/progress_providers.dart';
import '../../../providers/unit_system_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../providers/workout_providers.dart';

/// Builds a compact (≤~2000 char) context block summarising the user's goals,
/// body-weight trend, and lift history. Injected into the AI Coach system
/// prompt so the model gives personalised advice and derives realistic
/// `suggestedWeightKg` values for create_workout proposals.
class CoachContextBuilder {
  static const _maxChars = 2000;

  static Future<String> build(Ref ref) async {
    final parts = <String>[];
    final units = ref.read(unitSystemProvider);
    parts.add(
        'Display units: ${UnitConverter.weightUnit(units)} (use these when '
        'you reply to the user).');

    // --- Profile + goal ---
    try {
      final profile = await ref.read(userProfileProvider.future);
      if (profile != null) {
        parts.add(
          'Profile: ${profile.name}, goal ${profile.goal.name}, '
          'TDEE ${profile.tdee.toInt()} kcal, '
          'weight ${UnitConverter.formatWeight(profile.weight, units)}.',
        );
      }
    } catch (_) {}

    // --- Current nutrition goals (the targets to edit) ---
    try {
      final t = await ref.read(dailyTargetsProvider.future);
      if (t != null) {
        parts.add(
          'Current goals: ${t.calories.toInt()} kcal, '
          '${t.protein.toInt()}g protein, ${t.carbs.toInt()}g carbs, '
          '${t.fat.toInt()}g fat.',
        );
      }
    } catch (_) {}

    // --- Body-weight trend (latest 5, oldest→newest) ---
    try {
      final entries = await ref.read(weightEntriesProvider.future);
      if (entries.isNotEmpty) {
        final latest =
            entries.length > 5 ? entries.sublist(entries.length - 5) : entries;
        final trend = latest
            .map((e) =>
                '${_date(e.date)} ${UnitConverter.formatWeight(e.weightKg, units)}')
            .join(', ');
        parts.add('Weight trend (last ${latest.length}): $trend.');
      }
    } catch (_) {}

    // --- Recent lift history (top 10 most-trained). Reported in KG so the model
    //     can scale suggestedWeightKg (also kg) directly, no conversion. ---
    try {
      final lift = await _liftSummary(ref);
      if (lift.isNotEmpty) {
        parts.add('Lift history in kg (most-trained first):\n$lift');
      }
    } catch (_) {}

    // --- Avg intake (7d): actual vs the goals above ---
    try {
      final trends = await ref.read(nutritionTrendsProvider(7).future);
      if (trends.hasData) {
        parts.add(
          'Avg intake (7d): ${trends.avgCalories.toInt()} kcal, '
          '${trends.avgProtein.toInt()}g P, ${trends.avgCarbs.toInt()}g C, '
          '${trends.avgFat.toInt()}g F.',
        );
      }
    } catch (_) {}

    final ctx = parts.join('\n');
    return ctx.length > _maxChars ? '${ctx.substring(0, _maxChars)}…' : ctx;
  }

  /// Aggregates per-exercise: best set (heaviest weight × its reps), current PR,
  /// last performed date, ranked by how often it's been trained. Top 10.
  static Future<String> _liftSummary(Ref ref) async {
    final workouts = await ref.read(allWorkoutsProvider.future);
    final prs = await ref.read(personalRecordsProvider.future);

    final agg = <String, _LiftAgg>{};
    for (final w in workouts) {
      await w.exercises.load();
      for (final ex in w.exercises) {
        await ex.sets.load();
        final a = agg.putIfAbsent(ex.name, _LiftAgg.new);
        if (a.lastDate == null || w.date.isAfter(a.lastDate!)) {
          a.lastDate = w.date;
        }
        for (final s in ex.sets) {
          a.setCount++;
          if (s.weight > a.bestWeight) {
            a.bestWeight = s.weight;
            a.bestReps = s.reps;
          }
        }
      }
    }
    if (agg.isEmpty) return '';

    final ranked = agg.entries.toList()
      ..sort((x, y) => y.value.setCount.compareTo(x.value.setCount));

    final lines = <String>[];
    for (final e in ranked.take(10)) {
      final a = e.value;
      final best =
          a.bestWeight > 0 ? '${_kg(a.bestWeight)}x${a.bestReps}' : 'bodyweight';
      final pr = prs[e.key];
      final prStr = pr != null ? ', PR ${_kg(pr)}' : '';
      final last = a.lastDate != null ? _date(a.lastDate!) : '—';
      lines.add('- ${e.key}: best $best$prStr, last $last');
    }
    return lines.join('\n');
  }

  static String _date(DateTime d) => '${d.month}/${d.day}';

  static String _kg(double w) =>
      w % 1 == 0 ? '${w.toInt()}kg' : '${w.toStringAsFixed(1)}kg';
}

class _LiftAgg {
  int setCount = 0;
  double bestWeight = 0;
  int bestReps = 0;
  DateTime? lastDate;
}
