import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Card, Icons, Theme, IconButton, TextButton, VisualDensity;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../providers/unit_system_provider.dart';
import '../../domain/active_workout_state.dart';
import 'set_row.dart';

String _formatWeight(double w) =>
    w == w.roundToDouble() ? w.toInt().toString() : w.toString();

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
    final weightLabel = 'Weight (${UnitConverter.weightUnit(units)})';

    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise header
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(Icons.close, size: 20, color: colorScheme.error),
                  visualDensity: VisualDensity.compact,
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
                  'Last time: ${_formatWeight(units == UnitSystem.imperial ? UnitConverter.kgToLbs(exercise.sets.first.previousWeight!) : exercise.sets.first.previousWeight!)} ${UnitConverter.weightUnit(units)} '
                  '\u00d7 ${exercise.sets.first.previousReps}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            // Sets
            ...List.generate(exercise.sets.length, (setIndex) {
              final activeSet = exercise.sets[setIndex];
              return SetRow(
                set: activeSet,
                setNumber: setIndex + 1,
                previousReps: activeSet.previousReps,
                previousWeight: activeSet.previousWeight,
                onUpdate: ({int? reps, double? weight}) =>
                    onUpdateSet(setIndex, reps: reps, weight: weight),
                onComplete: () => onCompleteSet(setIndex),
                onRemove: () => onRemoveSet(setIndex),
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
