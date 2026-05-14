import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../data/exercise_library.dart';
import '../../../data/workout_templates.dart';
import '../domain/active_workout_state.dart';
import 'exercise_picker_sheet.dart';
import 'widgets/exercise_card.dart';
import '../../progress/presentation/widgets/pr_confetti_overlay.dart';
import 'widgets/interval_timer_sheet.dart';
import 'widgets/pr_banner.dart';
import 'widgets/rest_timer_sheet.dart';
import 'workouts_controller.dart';

class WorkoutLoggingScreen extends ConsumerStatefulWidget {
  const WorkoutLoggingScreen({
    super.key,
    this.editWorkoutId,
    this.initialTemplate,
  });

  final int? editWorkoutId;
  final WorkoutTemplate? initialTemplate;

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
    AppLogger.log(
      widget.editWorkoutId != null
          ? 'Workout logging started (edit id=${widget.editWorkoutId})'
          : widget.initialTemplate != null
              ? 'Workout logging started (template="${widget.initialTemplate!.name}")'
              : 'Workout logging started',
    );

    if (widget.editWorkoutId != null) {
      // Load existing workout for editing
      Future.microtask(() async {
        await ref
            .read(activeWorkoutProvider.notifier)
            .loadWorkout(widget.editWorkoutId!);
        final state = ref.read(activeWorkoutProvider);
        _titleController.text = state.title;
      });
    } else if (widget.initialTemplate != null) {
      // Pre-populate from a template
      final template = widget.initialTemplate!;
      _titleController.text = template.name;
      final activeExercises = template.exercises
          .asMap()
          .entries
          .map((entry) {
            final te = entry.value;
            final name = exerciseLibrary
                    .where((d) => d.id == te.exerciseId)
                    .firstOrNull
                    ?.name ??
                te.exerciseId;
            return ActiveExercise(
              name: name,
              order: entry.key,
              sets: List.generate(te.sets, (i) => ActiveSet(order: i)),
            );
          })
          .toList();
      Future.microtask(() async {
        if (!mounted) return;
        await ref.read(activeWorkoutProvider.notifier).loadFromTemplate(
              title: template.name,
              exercises: activeExercises,
            );
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
      await ref.read(activeWorkoutProvider.notifier).addExercise(name);
    }
  }

  Future<void> _finishWorkout() async {
    debugPrint('[Finish] Finish button tapped');
    final controller = ref.read(activeWorkoutProvider.notifier);
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      debugPrint('[Finish] Validation failed: title empty');
      showCupertinoToast(context, 'Please enter a workout name.');
      return;
    }

    controller.setTitle(title);

    final stateBefore = ref.read(activeWorkoutProvider);
    if (stateBefore.exercises.isEmpty) {
      debugPrint('[Finish] Validation failed: no exercises');
      showCupertinoToast(context, 'Add at least one exercise.');
      return;
    }

    debugPrint('[Finish] Validation passed (title="$title", '
        'exercises=${stateBefore.exercises.length})');
    debugPrint('[Finish] Saving workout...');

    int? savedWorkoutId;
    try {
      savedWorkoutId = await controller.saveWorkout();
    } catch (e, st) {
      debugPrint('[Finish] saveWorkout threw: $e\n$st');
      AppLogger.error('Finish workout failed', error: e, stack: st);
    }

    if (!mounted) return;

    if (savedWorkoutId == null) {
      debugPrint('[Finish] saveWorkout returned null');
      showCupertinoToast(context, 'Failed to save workout.');
      return;
    }

    debugPrint('[Finish] Workout saved with id=$savedWorkoutId');

    final prNames = ref.read(activeWorkoutProvider).newPRs;
    if (prNames.isNotEmpty) {
      debugPrint('[Finish] Showing PR confetti for ${prNames.length} PR(s)');
      // Show confetti then continue. Wrapped in try so a failed dialog
      // can't block the rest of the finish flow.
      try {
        await showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => PRConfettiOverlay(
            exerciseNames: prNames,
            onDismiss: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        );
      } catch (e) {
        debugPrint('[Finish] PR confetti dialog failed: $e');
      }
    }
    if (!mounted) return;

    debugPrint('[Finish] Showing share prompt');
    // Ask the user if they want to share this workout with the community.
    // Wrapped in try so a failed sheet can't strand the user on this screen.
    bool? shouldShare;
    try {
      shouldShare = await showCupertinoModalPopup<bool>(
        context: context,
        builder: (_) => const _ShareWorkoutPrompt(),
      );
    } catch (e) {
      debugPrint('[Finish] Share prompt failed: $e');
    }
    if (!mounted) return;

    if (shouldShare == true) {
      debugPrint('[Finish] Navigating to /community/create-post');
      context.go('/community/create-post?workoutId=$savedWorkoutId');
    } else {
      debugPrint('[Finish] Navigating to /workouts');
      context.go('/workouts');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeWorkoutProvider);
    final textTheme = Theme.of(context).textTheme;

    final elapsedStr =
        '${_elapsed.inMinutes.toString().padLeft(2, '0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: CupertinoNavigationBar(
        backgroundColor: AppColors.of(context).background.withValues(alpha: 0.8),
        border: null,
        leading: CupertinoButton(
          padding: const EdgeInsets.all(8),
          onPressed: () async {
            final shouldPop = await showCupertinoDialog<bool>(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Discard workout?'),
                content: const Text(
                    'Your progress will be lost if you go back.'),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep Going'),
                  ),
                  CupertinoDialogAction(
                    isDestructiveAction: true,
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
          child: const Icon(CupertinoIcons.xmark, size: 22),
        ),
        middle: Text(elapsedStr),
        trailing: CupertinoButton(
          padding: const EdgeInsets.all(8),
          onPressed: state.isSaving ? null : _finishWorkout,
          child: state.isSaving
              ? const CupertinoActivityIndicator()
              : Text(
                  'Finish',
                  style: TextStyle(
                    color: AppColors.of(context).accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
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
                  CupertinoTextField(
                    controller: _titleController,
                    style: textTheme.titleLarge,
                    placeholder: 'Workout Name',
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(),
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
                  // Action buttons row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showAddExerciseSheet,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Exercise'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => const IntervalTimerSheet(),
                          );
                        },
                        icon: const Icon(CupertinoIcons.timer),
                        label: const Text('Intervals'),
                      ),
                    ],
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

/// Bottom sheet shown after a successful workout save, asking whether the
/// user wants to share it with the community.
class _ShareWorkoutPrompt extends StatelessWidget {
  const _ShareWorkoutPrompt();

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: palette.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share this workout with the community?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Share',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
