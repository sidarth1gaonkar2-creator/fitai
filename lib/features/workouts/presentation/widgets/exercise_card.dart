import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Card, Colors, Dismissible, DismissDirection, Icons, Theme, IconButton, TextButton, VisualDensity;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../data/exercise_library.dart';
import '../../../../models/enums.dart';
import '../../../../providers/unit_system_provider.dart';
import '../../domain/active_workout_state.dart';
import 'exercise_thumb.dart';
import 'set_row.dart';

/// Epley 1-rep-max estimate: `weight × (1 + reps/30)`. Returns 0 when either
/// input is non-positive — caller uses that as the "no data yet" signal.
double estimatedOneRepMax(double weight, int reps) {
  if (weight <= 0 || reps <= 0) return 0;
  return weight * (1 + reps / 30.0);
}

/// Picks the best Epley 1RM across every set in the exercise. Includes
/// in-progress sets so the badge updates live as the user types.
double bestOneRepMaxFor(Iterable<({int reps, double weight})> sets) {
  var best = 0.0;
  for (final s in sets) {
    final est = estimatedOneRepMax(s.weight, s.reps);
    if (est > best) best = est;
  }
  return best;
}

class ExerciseCard extends ConsumerWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.onRemove,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onUpdateSet,
    required this.onCompleteSet,
  });

  final ActiveExercise exercise;
  final int exerciseIndex;
  final VoidCallback onRemove;
  final VoidCallback onAddSet;
  final void Function(int setIndex) onRemoveSet;
  final void Function(int setIndex, {int? reps, double? weight}) onUpdateSet;
  final void Function(int setIndex) onCompleteSet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final units = ref.watch(unitSystemProvider);
    // Dumbbell exercises take the weight value as "per dumbbell". Surface
    // that in the column header so users don't double-count both hands.
    final def = lookupExercise(name: exercise.name);
    final isDumbbell = def?.equipment == ExerciseEquipment.dumbbell;
    final unit = UnitConverter.weightUnit(units);
    final weightLabel =
        isDumbbell ? 'Weight ($unit, each)' : 'Weight ($unit)';

    // Epley 1RM in kg across all completed-or-typed sets; display-unit
    // conversion happens at render time so imperial users see lbs.
    final bestOrmKg = bestOneRepMaxFor(
      exercise.sets.map((s) => (reps: s.reps, weight: s.weight)),
    );

    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise header — thumbnail + name (tap either to view full
            // exercise detail) + 1RM badge + remove.
            Row(
              children: [
                ExerciseThumb(exerciseName: exercise.name, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push(
                      '/exercise?name=${Uri.encodeComponent(exercise.name)}',
                    ),
                    child: Text(
                      exercise.name,
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (bestOrmKg > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Est. 1RM ${UnitConverter.formatWeight(bestOrmKg, units)}',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(Icons.close, size: 20, color: colorScheme.error),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove exercise',
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Column headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text('Set',
                        style: textTheme.labelSmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ),
                  Expanded(
                    child: Text('Reps',
                        style: textTheme.labelSmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ),
                  Expanded(
                    child: Text(weightLabel,
                        style: textTheme.labelSmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // "Last time" hint above first set
            if (exercise.sets.isNotEmpty &&
                exercise.sets.first.previousWeight != null &&
                exercise.sets.first.previousReps != null &&
                exercise.sets.first.previousReps! > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Last time: '
                  '${UnitConverter.formatWeight(exercise.sets.first.previousWeight!, units)}'
                  ' \u00d7 ${exercise.sets.first.previousReps}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            // Sets — each wrapped in a Dismissible so users can swipe left
            // to delete a set during active logging. We block deletion of
            // the last remaining set (always keep at least one slot to type
            // into) by reporting it un-dismissible when `sets.length == 1`.
            ...List.generate(exercise.sets.length, (setIndex) {
              final activeSet = exercise.sets[setIndex];
              final canDelete = exercise.sets.length > 1;
              final row = SetRow(
                set: activeSet,
                setNumber: setIndex + 1,
                units: units,
                previousReps: activeSet.previousReps,
                previousWeight: activeSet.previousWeight,
                onUpdate: ({int? reps, double? weight}) =>
                    onUpdateSet(setIndex, reps: reps, weight: weight),
                onComplete: () => onCompleteSet(setIndex),
                onRemove: () => onRemoveSet(setIndex),
                // prev.weight is already kg in state; pass it through
                // unchanged — the storage layer is kg-canonical and SetRow
                // will display it correctly for the user's preferred unit.
                onCopyFromPrevious: setIndex == 0
                    ? null
                    : () {
                        final prev = exercise.sets[setIndex - 1];
                        onUpdateSet(
                          setIndex,
                          reps: prev.reps,
                          weight: prev.weight,
                        );
                      },
              );
              if (!canDelete) return row;
              return Dismissible(
                key: ValueKey('set-${exercise.name}-$setIndex-${activeSet.order}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                onDismissed: (_) {
                  HapticFeedback.lightImpact();
                  onRemoveSet(setIndex);
                },
                child: row,
              );
            }),
            const SizedBox(height: 4),
            // Add set button
            Center(
              child: TextButton.icon(
                onPressed: onAddSet,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Set'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

