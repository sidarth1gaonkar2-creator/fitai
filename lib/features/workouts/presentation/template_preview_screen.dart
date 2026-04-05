import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/muscle_group_diagram.dart';
import '../../../data/exercise_library.dart';
import '../../../data/workout_templates.dart';
import '../../../models/enums.dart';
import '../domain/active_workout_state.dart';
import 'workouts_controller.dart';

/// Previews a [WorkoutTemplate] with:
/// - Description + difficulty badge
/// - Aggregated [MuscleGroupDiagram]
/// - Swipe-to-remove exercise list
/// - "Start This Workout" button that loads the template and navigates to /workouts/new
class TemplatePreviewScreen extends ConsumerStatefulWidget {
  const TemplatePreviewScreen({super.key, required this.template});

  final WorkoutTemplate template;

  @override
  ConsumerState<TemplatePreviewScreen> createState() =>
      _TemplatePreviewScreenState();
}

class _TemplatePreviewScreenState
    extends ConsumerState<TemplatePreviewScreen> {
  late List<TemplateExercise> _exercises;

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.template.exercises);
  }

  String _exerciseName(String id) =>
      exerciseLibrary
          .where((d) => d.id == id)
          .firstOrNull
          ?.name ??
      id;

  List<MuscleGroup> get _primaryMuscles {
    final muscles = <MuscleGroup>{};
    for (final te in _exercises) {
      final def =
          exerciseLibrary.where((d) => d.id == te.exerciseId).firstOrNull;
      if (def != null) muscles.addAll(def.primaryMuscles);
    }
    return muscles.toList();
  }

  List<MuscleGroup> get _secondaryMuscles {
    final primary = _primaryMuscles.toSet();
    final muscles = <MuscleGroup>{};
    for (final te in _exercises) {
      final def =
          exerciseLibrary.where((d) => d.id == te.exerciseId).firstOrNull;
      if (def != null) {
        muscles.addAll(
            def.secondaryMuscles.where((m) => !primary.contains(m)));
      }
    }
    return muscles.toList();
  }

  void _removeExercise(int index) {
    setState(() => _exercises.removeAt(index));
  }

  Future<void> _startWorkout() async {
    if (_exercises.isEmpty) return;
    HapticFeedback.mediumImpact();

    final activeExercises = _exercises.asMap().entries.map((entry) {
      final te = entry.value;
      return ActiveExercise(
        name: _exerciseName(te.exerciseId),
        order: entry.key,
        sets: List.generate(
          te.sets,
          (i) => ActiveSet(order: i),
        ),
      );
    }).toList();

    ref.read(activeWorkoutProvider.notifier).loadFromTemplate(
          title: widget.template.name,
          exercises: activeExercises,
        );

    if (mounted) {
      context.go('/workouts/new');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (diffLabel, diffColor) = switch (widget.template.difficulty) {
      ExerciseDifficulty.beginner => ('Beginner', colorScheme.primary),
      ExerciseDifficulty.intermediate => ('Intermediate', colorScheme.tertiary),
      ExerciseDifficulty.advanced => ('Advanced', colorScheme.error),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
      ),
      body: _exercises.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.playlist_remove,
                      size: 48, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: 8),
                  Text(
                    'No exercises remaining.',
                    style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => setState(
                        () => _exercises = List.from(widget.template.exercises)),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description + difficulty
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.template.description,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: diffColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          diffLabel,
                          style: textTheme.labelMedium?.copyWith(
                            color: diffColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Stats row
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '~${widget.template.estimatedMinutes} min',
                        style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.fitness_center,
                          size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${_exercises.length} exercises',
                        style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Muscle diagram
                  if (_primaryMuscles.isNotEmpty)
                    Card.filled(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: MuscleGroupDiagram(
                          primaryMuscles: _primaryMuscles,
                          secondaryMuscles: _secondaryMuscles,
                          height: 180,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Exercise list header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Exercises',
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        'Swipe to remove',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Swipe-to-remove exercise list
                  ...List.generate(_exercises.length, (index) {
                    final te = _exercises[index];
                    final name = _exerciseName(te.exerciseId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Dismissible(
                        key: ValueKey('${te.exerciseId}_$index'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          HapticFeedback.mediumImpact();
                          final removed = _exercises[index];
                          _removeExercise(index);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Removed ${_exerciseName(removed.exerciseId)}',
                              ),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () => setState(
                                  () => _exercises.insert(index, removed),
                                ),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.delete,
                              color: colorScheme.onErrorContainer),
                        ),
                        child: Card.filled(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              '${te.sets} sets × ${te.reps} reps'
                              '${te.restSeconds > 0 ? '  ·  ${te.restSeconds}s rest' : ''}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: te.notes != null
                                ? Tooltip(
                                    message: te.notes!,
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: FilledButton.icon(
            onPressed: _exercises.isEmpty ? null : _startWorkout,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start This Workout'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}
