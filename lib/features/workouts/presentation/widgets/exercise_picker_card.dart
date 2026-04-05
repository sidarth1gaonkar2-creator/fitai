import 'package:flutter/material.dart';
import '../../../../data/exercise_library.dart';
import '../../../../models/enums.dart';

/// A card in the exercise picker list showing name, primary muscle icon,
/// difficulty badge, and equipment tag.
class ExercisePickerCard extends StatelessWidget {
  const ExercisePickerCard({
    super.key,
    required this.exercise,
    required this.onTap,
  });

  final ExerciseDefinition exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final primaryMuscle = exercise.primaryMuscles.isNotEmpty
        ? exercise.primaryMuscles.first
        : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Muscle icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                primaryMuscle != null
                    ? _muscleIcon(primaryMuscle)
                    : Icons.fitness_center,
                color: colorScheme.onPrimaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Name + tags
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: [
                      if (primaryMuscle != null)
                        _Tag(
                          label: primaryMuscle.label,
                          color: colorScheme.primary,
                        ),
                      _Tag(
                        label: exercise.equipment.label,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Difficulty badge
            _DifficultyBadge(difficulty: exercise.difficulty),
          ],
        ),
      ),
    );
  }

  static IconData _muscleIcon(MuscleGroup muscle) => switch (muscle) {
        MuscleGroup.chest => Icons.fitness_center,
        MuscleGroup.upperBack => Icons.accessibility_new,
        MuscleGroup.lats => Icons.expand,
        MuscleGroup.shoulders => Icons.sports_gymnastics,
        MuscleGroup.biceps => Icons.sports_handball,
        MuscleGroup.triceps => Icons.sports_handball,
        MuscleGroup.forearms => Icons.back_hand_outlined,
        MuscleGroup.quads => Icons.directions_run,
        MuscleGroup.hamstrings => Icons.directions_run,
        MuscleGroup.glutes => Icons.airline_seat_recline_normal,
        MuscleGroup.calves => Icons.directions_walk,
        MuscleGroup.abs => Icons.grid_view,
        MuscleGroup.obliques => Icons.grid_view,
        MuscleGroup.cardio => Icons.favorite_outline,
      };
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final ExerciseDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (label, color) = switch (difficulty) {
      ExerciseDifficulty.beginner => (
          'Beginner',
          colorScheme.primary,
        ),
      ExerciseDifficulty.intermediate => (
          'Intermediate',
          colorScheme.tertiary,
        ),
      ExerciseDifficulty.advanced => (
          'Advanced',
          colorScheme.error,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
