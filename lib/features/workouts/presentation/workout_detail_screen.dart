import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../data/exercise_library.dart';
import '../../../models/enums.dart';
import '../../../providers/unit_system_provider.dart';
import '../../../providers/workout_providers.dart';
import 'widgets/exercise_thumb.dart';
import 'widgets/muscle_highlight_widget.dart';

/// Maps the local [MuscleGroup] enum to the muscle-name strings that the
/// [MuscleHighlightWidget] knows zones for. Anything not in this table
/// (e.g. cardio) is dropped — the widget tolerates unknown names.
String? _muscleGroupToZoneName(MuscleGroup g) {
  switch (g) {
    case MuscleGroup.chest:
      return 'chest';
    case MuscleGroup.upperBack:
      return 'traps';
    case MuscleGroup.lowerBack:
      return 'lower back';
    case MuscleGroup.lats:
      return 'lats';
    case MuscleGroup.shoulders:
      return 'deltoids';
    case MuscleGroup.biceps:
      return 'biceps';
    case MuscleGroup.triceps:
      return 'triceps';
    case MuscleGroup.forearms:
      return 'forearms';
    case MuscleGroup.quads:
      return 'quadriceps';
    case MuscleGroup.hamstrings:
      return 'hamstrings';
    case MuscleGroup.glutes:
      return 'glutes';
    case MuscleGroup.calves:
      return 'calves';
    case MuscleGroup.abs:
      return 'abs';
    case MuscleGroup.obliques:
      return 'obliques';
    case MuscleGroup.cardio:
      return null;
  }
}

class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});

  final int workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(workoutByIdProvider(workoutId));
    final units = ref.watch(unitSystemProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final palette = AppColors.of(context);
    return workoutAsync.when(
      loading: () => Scaffold(
        appBar: CupertinoNavigationBar(
          middle: const Text('Workout'),
          backgroundColor: palette.background.withValues(alpha: 0.8),
          border: null,
          leading: _BackButton(),
        ),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              ShimmerBox(width: double.infinity, height: 24, borderRadius: 6),
              SizedBox(height: 16),
              ShimmerCard(height: 120),
              SizedBox(height: 8),
              ShimmerCard(height: 120),
            ],
          ),
        ),
      ),
      error: (_, _) => Scaffold(
        appBar: CupertinoNavigationBar(
          middle: const Text('Workout'),
          backgroundColor: palette.background.withValues(alpha: 0.8),
          border: null,
          leading: _BackButton(),
        ),
        body: ErrorCard(
          message: 'Could not load workout.',
          onRetry: () => ref.invalidate(workoutByIdProvider(workoutId)),
        ),
      ),
      data: (workout) {
        if (workout == null) {
          return Scaffold(
            appBar: AppBar(
              leading: const BackButton(),
              title: const Text('Workout'),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 8),
                  Text('Workout not found.',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => context.go('/workouts'),
                    child: const Text('Back to Workouts'),
                  ),
                ],
              ),
            ),
          );
        }

        final date = workout.date;
        final dateStr = '${date.day}/${date.month}/${date.year}';

        return Scaffold(
          appBar: CupertinoNavigationBar(
            middle: Text(workout.title),
            backgroundColor: palette.background.withValues(alpha: 0.8),
            border: null,
            leading: _BackButton(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: () => context.go('/workouts/$workoutId/edit'),
                  child: const Icon(CupertinoIcons.pencil, size: 22),
                ),
                const SizedBox(width: 14),
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: () => _confirmDelete(context, ref),
                  child: Icon(CupertinoIcons.trash,
                      size: 22, color: colorScheme.error),
                ),
              ],
            ),
          ),
          body: ref.watch(workoutExercisesProvider(workoutId)).when(
            loading: () =>
                const Center(child: CupertinoActivityIndicator()),
            error: (_, _) => ErrorCard(
              message: 'Could not load exercises.',
              onRetry: () =>
                  ref.invalidate(workoutExercisesProvider(workoutId)),
            ),
            data: (exercises) {
              // Aggregate muscles across all exercises. Routes through
              // lookupExercise so name drift (case, hyphenation, etc.) and
              // future id-based stores both resolve cleanly. Logs a debug
              // warning for any exercise that can't be matched.
              final primaryMuscles = <MuscleGroup>{};
              final secondaryMuscles = <MuscleGroup>{};
              for (final entry in exercises) {
                final def = lookupExercise(name: entry.name);
                if (def != null) {
                  primaryMuscles.addAll(def.primaryMuscles);
                  secondaryMuscles.addAll(def.secondaryMuscles
                      .where((m) => !primaryMuscles.contains(m)));
                }
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info row
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(dateStr,
                            style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
                        if (workout.durationMinutes != null) ...[
                          const SizedBox(width: 16),
                          Icon(Icons.timer_outlined,
                              size: 16, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('${workout.durationMinutes} min',
                              style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant)),
                        ],
                      ],
                    ),
                    // Combined muscle highlight — aggregates target +
                    // secondary muscles across every exercise in this
                    // workout into a single Apple-Fitness-style preview.
                    if (primaryMuscles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card.filled(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Center(
                            child: MuscleHighlightWidget(
                              targetMuscles: primaryMuscles
                                  .map(_muscleGroupToZoneName)
                                  .whereType<String>()
                                  .toList(),
                              secondaryMuscles: secondaryMuscles
                                  .map(_muscleGroupToZoneName)
                                  .whereType<String>()
                                  .toList(),
                              height: 200,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (workout.notes != null &&
                        workout.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(workout.notes!,
                          style: textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 20),
                    // Exercises
                    ...exercises.map((entry) {
                      final exerciseName = entry.name;
                      final sets = entry.sets;
                      final exDef = lookupExercise(name: exerciseName);
                      final isDumbbell =
                          exDef?.equipment == ExerciseEquipment.dumbbell;
                      return Card.filled(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Thumbnail + name — both tap to the
                              // exercise detail.
                              Row(
                                children: [
                                  ExerciseThumb(
                                    exerciseName: exerciseName,
                                    size: 36,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => context.push(
                                        '/exercise?name='
                                        '${Uri.encodeComponent(exerciseName)}',
                                      ),
                                      child: Text(
                                        exerciseName,
                                        style: textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Header
                              Row(
                                children: [
                                  SizedBox(
                                      width: 40,
                                      child: Text('Set',
                                          style: textTheme.labelSmall?.copyWith(
                                              color: colorScheme
                                                  .onSurfaceVariant))),
                                  Expanded(
                                      child: Text('Reps',
                                          style: textTheme.labelSmall?.copyWith(
                                              color: colorScheme
                                                  .onSurfaceVariant))),
                                  Expanded(
                                      child: Text(
                                          isDumbbell
                                              ? 'Weight (each)'
                                              : 'Weight',
                                          style: textTheme.labelSmall?.copyWith(
                                              color: colorScheme
                                                  .onSurfaceVariant))),
                                ],
                              ),
                              const Divider(height: 8),
                              ...sets.asMap().entries.map((e) {
                                final idx = e.key;
                                final set = e.value;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        child: Text('${idx + 1}',
                                            style: textTheme.bodyMedium),
                                      ),
                                      Expanded(
                                          child: Text('${set.reps}',
                                              style: textTheme.bodyMedium)),
                                      Expanded(
                                          child: Text(
                                              UnitConverter.formatWeight(
                                                  set.weight, units),
                                              style: textTheme.bodyMedium)),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete workout?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await deleteWorkoutById(ref, workoutId);
      if (context.mounted) context.go('/workouts');
    }
  }
}

/// Explicit back chevron for the workout detail screen. The screen is
/// presented as an iOS slide-up modal, which has no swipe-back gesture, so
/// we must provide a visible affordance.
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(8),
      minimumSize: const Size(48, 48),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/workouts');
        }
      },
      child: Semantics(
        label: 'Back',
        button: true,
        child: const Icon(CupertinoIcons.back, size: 24),
      ),
    );
  }
}

