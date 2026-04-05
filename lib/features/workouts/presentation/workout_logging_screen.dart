import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'exercise_picker_sheet.dart';
import 'widgets/exercise_card.dart';
import 'widgets/pr_banner.dart';
import 'widgets/rest_timer_sheet.dart';
import 'workouts_controller.dart';

class WorkoutLoggingScreen extends ConsumerStatefulWidget {
  const WorkoutLoggingScreen({super.key, this.editWorkoutId});

  final int? editWorkoutId;

  @override
  ConsumerState<WorkoutLoggingScreen> createState() =>
      _WorkoutLoggingScreenState();
}

class _WorkoutLoggingScreenState extends ConsumerState<WorkoutLoggingScreen> {
  late final TextEditingController _titleController;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();

    if (widget.editWorkoutId != null) {
      // Load existing workout for editing
      Future.microtask(() async {
        await ref
            .read(activeWorkoutProvider.notifier)
            .loadWorkout(widget.editWorkoutId!);
        final state = ref.read(activeWorkoutProvider);
        _titleController.text = state.title;
      });
    }

    // Start elapsed timer
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now()
              .difference(ref.read(activeWorkoutProvider).startTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  Future<void> _showAddExerciseSheet() async {
    final name = await showExercisePickerSheet(context);
    if (name != null && name.isNotEmpty && mounted) {
      ref.read(activeWorkoutProvider.notifier).addExercise(name);
    }
  }

  Future<void> _finishWorkout() async {
    final controller = ref.read(activeWorkoutProvider.notifier);
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a workout name.')),
      );
      return;
    }

    controller.setTitle(title);

    final state = ref.read(activeWorkoutProvider);
    if (state.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise.')),
      );
      return;
    }

    final success = await controller.saveWorkout();
    if (mounted) {
      if (success) {
        context.go('/workouts');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save workout.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeWorkoutProvider);
    final textTheme = Theme.of(context).textTheme;

    final elapsedStr =
        '${_elapsed.inMinutes.toString().padLeft(2, '0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            final shouldPop = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Discard workout?'),
                content: const Text(
                    'Your progress will be lost if you go back.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep Going'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Discard'),
                  ),
                ],
              ),
            );
            if (shouldPop == true && context.mounted) {
              context.go('/workouts');
            }
          },
        ),
        title: Text(elapsedStr),
        actions: [
          FilledButton(
            onPressed: state.isSaving ? null : _finishWorkout,
            child: state.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Finish'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // PR Banner
                  if (state.prExerciseName != null) ...[
                    PRBanner(exerciseName: state.prExerciseName!),
                    const SizedBox(height: 12),
                  ],
                  // Workout title
                  TextField(
                    controller: _titleController,
                    style: textTheme.titleLarge,
                    decoration: const InputDecoration(
                      hintText: 'Workout Name',
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Exercise cards
                  ...List.generate(state.exercises.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ExerciseCard(
                        exercise: state.exercises[i],
                        exerciseIndex: i,
                        onRemove: () => ref
                            .read(activeWorkoutProvider.notifier)
                            .removeExercise(i),
                        onAddSet: () => ref
                            .read(activeWorkoutProvider.notifier)
                            .addSet(i),
                        onRemoveSet: (setIndex) => ref
                            .read(activeWorkoutProvider.notifier)
                            .removeSet(i, setIndex),
                        onUpdateSet: (setIndex, {int? reps, double? weight}) =>
                            ref
                                .read(activeWorkoutProvider.notifier)
                                .updateSet(i, setIndex,
                                    reps: reps, weight: weight),
                        onCompleteSet: (setIndex) => ref
                            .read(activeWorkoutProvider.notifier)
                            .completeSet(i, setIndex),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  // Add exercise button
                  OutlinedButton.icon(
                    onPressed: _showAddExerciseSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Exercise'),
                  ),
                ],
              ),
            ),
          ),
          // Rest timer (bottom)
          const RestTimerSheet(),
        ],
      ),
    );
  }
}
