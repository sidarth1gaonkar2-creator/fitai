import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/scoped_prefs.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../data/exercise_library.dart';
import '../../../data/workout_templates.dart';
import '../../../models/saved_workout_template.dart';
import '../../../providers/auth_provider.dart' show currentUserIdProvider;
import '../../../providers/entitlement_providers.dart';
import '../../../providers/unit_system_provider.dart'
    show sharedPreferencesProvider;
import '../../ranks/domain/drill_sergeant.dart';
import '../../ranks/presentation/widgets/rank_celebration_overlay.dart';
import '../../ranks/providers/rank_providers.dart';
import '../domain/active_workout_state.dart';
import '../domain/workout_results.dart';
import 'exercise_picker_sheet.dart';
import 'widgets/exercise_card.dart';
import 'widgets/workout_complete_overlay.dart';
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
    this.initialCoachTemplate,
  });

  final int? editWorkoutId;
  final WorkoutTemplate? initialTemplate;

  /// An AI Coach-generated template (started from the chat card or the
  /// Templates tab). Its set weights pre-fill from suggestedWeightKg (kg).
  final SavedWorkoutTemplate? initialCoachTemplate;

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
    } else if (widget.initialCoachTemplate != null) {
      // AI Coach template — pre-fill each set's reps + weight (kg) so the user
      // starts logging immediately.
      final coach = widget.initialCoachTemplate!;
      _titleController.text = coach.name;
      List<dynamic> raw;
      try {
        raw = jsonDecode(coach.exercisesJson) as List<dynamic>;
      } catch (_) {
        raw = const [];
      }
      final activeExercises = <ActiveExercise>[];
      for (var i = 0; i < raw.length; i++) {
        final e = raw[i];
        if (e is! Map) continue;
        activeExercises.add(ActiveExercise(
          name: e['exerciseName'] as String? ?? 'Exercise',
          order: i,
          sets: List.generate(
            (e['sets'] as num?)?.toInt() ?? 1,
            (j) => ActiveSet(
              order: j,
              reps: (e['reps'] as num?)?.toInt() ?? 0,
              weight: (e['suggestedWeightKg'] as num?)?.toDouble() ?? 0,
            ),
          ),
        ));
      }
      Future.microtask(() async {
        if (!mounted) return;
        await ref.read(activeWorkoutProvider.notifier).loadFromTemplate(
              title: coach.name,
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
    final controller = ref.read(activeWorkoutProvider.notifier);
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      showCupertinoToast(context, 'Please enter a workout name.');
      return;
    }

    controller.setTitle(title);

    final stateBefore = ref.read(activeWorkoutProvider);
    if (stateBefore.exercises.isEmpty) {
      showCupertinoToast(context, 'Add at least one exercise.');
      return;
    }

    // Full rank snapshot BEFORE saving, so the after-diff is a genuine
    // before-vs-after (never value-vs-itself). RankCalculation is immutable, so
    // this stays frozen even after the post-save recompute. Best-effort — a
    // failure just disables the deltas and the promotion celebration.
    RankCalculation? calcBefore;
    try {
      calcBefore = await ref.read(rankCalculatorProvider.future);
    } catch (_) {/* diff + promotion detection disabled */}
    if (!mounted) return;

    int? savedWorkoutId;
    try {
      savedWorkoutId = await controller.saveWorkout();
    } catch (e, st) {
      AppLogger.error('Finish workout failed', error: e, stack: st);
    }

    if (!mounted) return;

    if (savedWorkoutId == null) {
      showCupertinoToast(context, 'Failed to save workout.');
      return;
    }

    final state = ref.read(activeWorkoutProvider);
    final prNames = state.newPRs;

    // Only a new PR can move a score (PR1), so a recompute is meaningful only
    // then. No PR ⇒ after == before ⇒ no deltas, no fake improvement, and no
    // needless extra Firestore rank write.
    RankCalculation? calcAfter = calcBefore;
    if (prNames.isNotEmpty) {
      ref.invalidate(rankCalculatorProvider);
      try {
        calcAfter = await ref.read(rankCalculatorProvider.future);
      } catch (_) {
        calcAfter = calcBefore; // fall back to the snapshot
      }
    }
    if (!mounted) return;

    final promoted = calcBefore != null &&
        calcAfter != null &&
        calcAfter.overall.index > calcBefore.overall.index;

    // PR confetti first (its own flourish), then the results screen below.
    if (prNames.isNotEmpty) {
      try {
        await showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => PRConfettiOverlay(
            exerciseNames: prNames,
            onDismiss: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        );
      } catch (e, st) {
        AppLogger.error('PR confetti dialog failed', error: e, stack: st);
      }
    }
    if (!mounted) return;

    // Results screen — shown after EVERY finish. Diff the captured before/after
    // (no fake deltas — see computeWorkoutResults), then present as a
    // full-screen overlay on the CURRENT navigator. This is a dialog, NOT a
    // go_router route: it adds no GoRoute and never pushes across the shell, so
    // it cannot clone the StatefulShellRoute / dup-GlobalKey → no black screen.
    final results = computeWorkoutResults(
      before: calcBefore,
      after: calcAfter ?? calcBefore ?? RankCalculation.empty,
      summary: _buildWorkoutSummary(state),
      sessionExerciseNames: [for (final e in state.exercises) e.name],
      prNames: prNames,
    );
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (ctx, _, _) => WorkoutCompleteOverlay(
          results: results,
          onDismiss: () => Navigator.of(ctx).pop(),
        ),
      );
    } catch (e, st) {
      AppLogger.error('Workout complete overlay failed', error: e, stack: st);
    }
    if (!mounted) return;

    // An OVERALL promotion gets its own full-screen celebration on top, fired
    // at most ONCE per rank — the SharedPreferences marker stops it
    // re-triggering on later recomputes or launches. (Stored in prefs rather
    // than Isar to avoid this project's broken Isar codegen; same once-only
    // guarantee.) Per-muscle rank-ups surface as badges on the results screen,
    // not a separate celebration.
    if (promoted) {
      final newRank = calcAfter.overall;

      // 5B: scaffold the (not-yet-sent) promotion push-notification text.
      AppLogger.log(rankUpNotificationText(newRank));

      // The once-only marker is per-account (`..._<uid>`, PR-B). Signed out
      // (passive revocation mid-workout): skip — without an account key the
      // once-only guarantee can't hold, and nothing user-scoped is written
      // while signed out.
      final prefs = ref.read(sharedPreferencesProvider);
      final uid = ref.read(currentUserIdProvider);
      final celebratedKey =
          uid == null ? null : scopedKey('last_celebrated_rank_index', uid);
      if (celebratedKey != null &&
          newRank.index > (prefs.getInt(celebratedKey) ?? -1)) {
        await prefs.setInt(celebratedKey, newRank.index);
        if (!mounted) return;
        try {
          await showGeneralDialog<void>(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.transparent,
            transitionDuration: const Duration(milliseconds: 250),
            pageBuilder: (ctx, _, _) => RankCelebrationOverlay(
              rank: newRank,
              airborne: ref.read(airborneActiveProvider),
              onDismiss: () => Navigator.of(ctx).pop(),
            ),
          );
        } catch (e, st) {
          AppLogger.error('Rank celebration failed', error: e, stack: st);
        }
      }
    }
    if (!mounted) return;

    // Ask the user if they want to share this workout with the community.
    // Wrapped in try so a failed sheet can't strand the user on this screen.
    bool? shouldShare;
    try {
      shouldShare = await showCupertinoModalPopup<bool>(
        context: context,
        builder: (_) => const _ShareWorkoutPrompt(),
      );
    } catch (e, st) {
      AppLogger.error('Share prompt failed', error: e, stack: st);
    }
    if (!mounted) return;

    // Two-step navigation to avoid the black-screen bug.
    //
    // The workout logging screen lives inside the Workouts shell branch
    // (StatefulShellRoute.indexedStack), but /community/create-post is a
    // STANDALONE route outside the shell. Calling `context.go(...)` to jump
    // directly cross-stack tears down the shell+page transition mid-flight
    // and produces a black frame the OS never recovers from.
    //
    // Instead: first go back to /workouts (still inside the shell — safe
    // and animates correctly), give the navigator a frame to settle, then
    // push the standalone create-post route on top of the root navigator.
    context.go('/workouts');

    if (shouldShare == true) {
      // One frame for the shell route to render before we stack on top.
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      context.push('/community/create-post?workoutId=$savedWorkoutId');
    }
  }

  /// Builds the results-screen summary from the just-finished session: logged
  /// working-set count (reps > 0), total tonnage in kg (Σ weight×reps over
  /// weighted sets), and elapsed time.
  WorkoutSummary _buildWorkoutSummary(ActiveWorkoutState state) {
    var sets = 0;
    var volumeKg = 0.0;
    for (final exercise in state.exercises) {
      for (final s in exercise.sets) {
        if (s.reps <= 0) continue; // a logged working set
        sets++;
        if (s.weight > 0) volumeKg += s.weight * s.reps;
      }
    }
    return WorkoutSummary(
      title: state.title,
      duration: DateTime.now().difference(state.startTime),
      sets: sets,
      exercises: state.exercises.length,
      volumeKg: volumeKg,
    );
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
          child: const Icon(CupertinoIcons.xmark,
              size: 22, semanticLabel: 'Discard workout'),
        ),
        // Elapsed time is an instrument readout — mono, glanceable.
        middle: Text(
          elapsedStr,
          semanticsLabel: 'Elapsed time $elapsedStr',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontVariations: const [FontVariation('wght', 700)],
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 1,
            color: AppColors.of(context).text,
          ),
        ),
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
                          // Oswald via the shim — bark case for commands.
                          label: const Text('ADD EXERCISE',
                              semanticsLabel: 'Add exercise'),
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
                        label: const Text('INTERVALS',
                            semanticsLabel: 'Intervals'),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(top: BorderSide(color: palette.border)),
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
                fontFamily: 'Inter',
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
                        fontFamily: 'Inter',
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
                    borderRadius: BorderRadius.circular(4),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'SHARE',
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontVariations: [FontVariation('wght', 600)],
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: 0.6,
                        color: Color(0xFF1A1C1A), // ink on accent
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
