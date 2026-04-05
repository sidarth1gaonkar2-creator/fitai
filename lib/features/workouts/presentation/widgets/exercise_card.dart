import 'package:flutter/material.dart';
import '../../domain/active_workout_state.dart';
import 'set_row.dart';

class ExerciseCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                    child: Text('Weight (kg)',
                        style: textTheme.labelSmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Sets
            ...List.generate(exercise.sets.length, (setIndex) {
              return SetRow(
                set: exercise.sets[setIndex],
                setNumber: setIndex + 1,
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
