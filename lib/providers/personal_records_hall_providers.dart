import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../data/exercise_library.dart';
import '../features/ranks/providers/rank_providers.dart';
import '../models/enums.dart';
import '../models/personal_record.dart';
import 'isar_provider.dart';

enum PRSortMode { byDate, byMuscleGroup, alphabetical, byRank }

/// All personal records from Isar.
final allPersonalRecordsProvider =
    FutureProvider<List<PersonalRecord>>((ref) async {
  final isar = ref.watch(isarProvider);
  final prs = await isar.personalRecords.where().findAll();
  prs.sort((a, b) => b.dateAchieved.compareTo(a.dateAchieved));
  return prs;
});

/// Current sort mode for the PR Hall screen.
final prSortModeProvider = StateProvider<PRSortMode>((ref) => PRSortMode.byDate);

/// Current muscle group filter (null = show all).
final prFilterMuscleProvider = StateProvider<MuscleGroup?>((ref) => null);

/// Filtered and sorted list of personal records.
final filteredPRsProvider = Provider<AsyncValue<List<PersonalRecord>>>((ref) {
  final asyncPRs = ref.watch(allPersonalRecordsProvider);
  final sortMode = ref.watch(prSortModeProvider);
  final muscleFilter = ref.watch(prFilterMuscleProvider);
  // Only the rank sort needs the (async) rank calculation; null while loading.
  final calc = sortMode == PRSortMode.byRank
      ? ref.watch(rankCalculatorProvider).valueOrNull
      : null;

  return asyncPRs.whenData((prs) {
    var filtered = prs.toList();

    // Apply muscle group filter
    if (muscleFilter != null) {
      filtered = filtered.where((pr) => pr.muscleGroup == muscleFilter).toList();
    }

    // Apply sort
    switch (sortMode) {
      case PRSortMode.byDate:
        filtered.sort((a, b) => b.dateAchieved.compareTo(a.dateAchieved));
      case PRSortMode.byMuscleGroup:
        filtered.sort((a, b) {
          final cmp = a.muscleGroup.index.compareTo(b.muscleGroup.index);
          if (cmp != 0) return cmp;
          return a.exerciseName.compareTo(b.exerciseName);
        });
      case PRSortMode.alphabetical:
        filtered.sort(
            (a, b) => a.exerciseName.toLowerCase().compareTo(b.exerciseName.toLowerCase()));
      case PRSortMode.byRank:
        double scoreFor(PersonalRecord pr) {
          if (calc == null) return -1;
          final key = lookupExercise(name: pr.exerciseName)?.id ??
              pr.exerciseName.toLowerCase();
          return calc.exerciseScores[key] ?? -1;
        }

        // Highest score (rank) first; break ties by most recent.
        filtered.sort((a, b) {
          final cmp = scoreFor(b).compareTo(scoreFor(a));
          if (cmp != 0) return cmp;
          return b.dateAchieved.compareTo(a.dateAchieved);
        });
    }

    return filtered;
  });
});
