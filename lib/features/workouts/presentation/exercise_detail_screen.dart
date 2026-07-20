import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../data/exercise_library.dart';
import '../../../models/exercisedb_exercise.dart';
import '../../../models/personal_record.dart';
import '../../../providers/exercisedb_providers.dart';
import '../../../providers/personal_records_hall_providers.dart' as pr_hall;
import '../../../providers/progress_providers.dart';
import '../../../providers/unit_system_provider.dart';
import '../../ranks/domain/military_ranks.dart';
import '../../ranks/presentation/widgets/rank_badge.dart';
import '../../ranks/providers/rank_providers.dart';
import 'widgets/muscle_highlight_widget.dart';

/// Detail view for a single exercise. Combines:
///   * Hero image from ExerciseDB (cached)
///   * Muscle highlight diagram (front/back)
///   * Step-by-step instructions (ExerciseDB → local fallback)
///   * Tips
///   * Equipment
///   * "View Strength Curve" shortcut
///   * Current PR for this exercise (if any)
///
/// Falls back gracefully when ExerciseDB is unreachable or the exercise
/// isn't in the API's catalogue — the local instructions still render.
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseName});

  final String exerciseName;

  ExerciseDefinition? _localDef() {
    for (final e in exerciseLibrary) {
      if (e.name.toLowerCase() == exerciseName.toLowerCase()) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final asyncEx = ref.watch(exerciseDBProvider(exerciseName));
    final local = _localDef();

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: CupertinoNavigationBar(
        middle: Text(
          exerciseName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            _HeroImage(asyncEx: asyncEx),

            // ── Muscle diagram ──────────────────────────────────────
            // Prefer ExerciseDB's muscle names (more granular). When the
            // API is offline we synthesise a list from local muscle group
            // enums so the diagram is never blank.
            _MuscleSection(
              asyncEx: asyncEx,
              localFallback: local,
              palette: palette,
              textTheme: textTheme,
            ),
            const SizedBox(height: 20),

            // ── Strength curve shortcut ────────────────────────────
            _StrengthLink(
              exerciseName: exerciseName,
              palette: palette,
              textTheme: textTheme,
            ),
            const SizedBox(height: 12),

            // ── PR for this exercise ───────────────────────────────
            _PRTile(exerciseName: exerciseName),
            const SizedBox(height: 12),

            // ── Military rank for this exercise ────────────────────
            _RankSection(exerciseName: exerciseName),
            const SizedBox(height: 20),

            // ── Equipment ──────────────────────────────────────────
            _EquipmentChips(
              asyncEx: asyncEx,
              localFallback: local,
              palette: palette,
              textTheme: textTheme,
            ),
            const SizedBox(height: 20),

            // ── Instructions ───────────────────────────────────────
            _StepsBlock(
              title: 'Instructions',
              icon: CupertinoIcons.list_number,
              steps: asyncEx.valueOrNull?.instructions ?? const [],
              fallback: local?.instructions ?? const [],
              palette: palette,
              textTheme: textTheme,
            ),
            const SizedBox(height: 12),

            // ── Tips (ExerciseDB only) ─────────────────────────────
            if ((asyncEx.valueOrNull?.tips ?? const []).isNotEmpty)
              _StepsBlock(
                title: 'Tips',
                icon: CupertinoIcons.lightbulb,
                steps: asyncEx.valueOrNull!.tips,
                fallback: const [],
                palette: palette,
                textTheme: textTheme,
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Hero image ────────────────────────────────────────────────────────────

class _HeroImage extends StatefulWidget {
  const _HeroImage({required this.asyncEx});

  final AsyncValue<ExerciseDBExercise?> asyncEx;

  @override
  State<_HeroImage> createState() => _HeroImageState();
}

class _HeroImageState extends State<_HeroImage> {
  bool _failed = false;

  @override
  void didUpdateWidget(_HeroImage old) {
    super.didUpdateWidget(old);
    if (old.asyncEx.valueOrNull?.fullImageUrl !=
        widget.asyncEx.valueOrNull?.fullImageUrl) {
      _failed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a shimmer while the ExerciseDB lookup is in flight so the screen
    // doesn't reflow once the URL arrives.
    if (widget.asyncEx.isLoading && !widget.asyncEx.hasValue) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: AspectRatio(
          aspectRatio: 16 / 11,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const ShimmerBox(
                width: double.infinity, height: double.infinity),
          ),
        ),
      );
    }
    final url = widget.asyncEx.valueOrNull?.fullImageUrl;
    if (url == null || url.isEmpty || _failed) {
      // No image available — collapse instead of showing a huge gray
      // placeholder card. The muscle diagram below carries the visual.
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AspectRatio(
        aspectRatio: 16 / 11,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, _) => const ShimmerBox(
                width: double.infinity, height: double.infinity),
            errorWidget: (_, _, _) {
              // Schedule the rebuild so the empty space disappears entirely
              // instead of leaving the user staring at a broken-image card.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_failed) setState(() => _failed = true);
              });
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

// ─── Muscle section (diagram + legend) ─────────────────────────────────────

class _MuscleSection extends StatelessWidget {
  const _MuscleSection({
    required this.asyncEx,
    required this.localFallback,
    required this.palette,
    required this.textTheme,
  });

  final AsyncValue<ExerciseDBExercise?> asyncEx;
  final ExerciseDefinition? localFallback;
  final Palette palette;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    // Resolve target + secondary muscle name lists. Use ExerciseDB if
    // available; otherwise synthesize from the local enum-based muscle
    // groups so we still show something.
    final fromApi = asyncEx.valueOrNull;
    final target = fromApi?.targetMuscles.isNotEmpty == true
        ? fromApi!.targetMuscles
        : (localFallback?.primaryMuscles
                .map((m) => m.toString().split('.').last)
                .toList() ??
            const <String>[]);
    final secondary = fromApi?.secondaryMuscles.isNotEmpty == true
        ? fromApi!.secondaryMuscles
        : (localFallback?.secondaryMuscles
                .map((m) => m.toString().split('.').last)
                .toList() ??
            const <String>[]);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Muscles worked',
            style: textTheme.titleSmall?.copyWith(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 8),
          MuscleHighlightWidget(
            targetMuscles: target,
            secondaryMuscles: secondary,
          ),
          const SizedBox(height: 8),
          // Legend.
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _legendSwatch(
                MuscleHighlightWidget.targetColor(palette.accent),
                'Primary',
              ),
              _legendSwatch(
                MuscleHighlightWidget.secondaryColor(palette.accent),
                'Secondary',
              ),
            ],
          ),
          if (target.isNotEmpty) ...[
            const SizedBox(height: 8),
            _muscleList('Primary', target),
          ],
          if (secondary.isNotEmpty) ...[
            const SizedBox(height: 4),
            _muscleList('Secondary', secondary),
          ],
        ],
      ),
    );
  }

  Widget _legendSwatch(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _muscleList(String label, List<String> names) {
    return Text(
      '$label: ${names.join(', ')}',
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        color: palette.textSecondary,
        height: 1.35,
      ),
    );
  }
}

// ─── Strength curve shortcut + PR ──────────────────────────────────────────

class _StrengthLink extends ConsumerWidget {
  const _StrengthLink({
    required this.exerciseName,
    required this.palette,
    required this.textTheme,
  });

  final String exerciseName;
  final Palette palette;
  final TextTheme textTheme;

  /// Counts how many distinct sessions this exercise has been logged in —
  /// the same metric the chart needs ≥2 of to render a curve. Cheaper than
  /// running the full `strengthHistoryProvider` aggregation just to peek.
  Future<int> _countSessions(WidgetRef ref) async {
    final points =
        await ref.read(strengthHistoryProvider(exerciseName).future);
    return points.length;
  }

  /// Gate the "View Strength Curve" tap so a single-session (or zero-session)
  /// exercise can't navigate into an empty chart that — combined with a
  /// `context.push('/progress')` from a standalone route — used to leave
  /// the Progress tab in an unrecoverable state.
  ///
  /// What changed for safety:
  ///   * Pre-flight session count → friendly dialog when <2
  ///   * `context.go(...)` instead of `context.push(...)`: progress is a
  ///     shell-route tab, pushing it from outside the shell stacks a fresh
  ///     shell on top and the back button can't pop it cleanly
  ///   * Whole thing wrapped in try/catch so a router error surfaces as a
  ///     toast rather than freezing the UI
  Future<void> _openStrengthCurve(
      BuildContext context, WidgetRef ref) async {
    final sessions = await _countSessions(ref);
    if (!context.mounted) return;
    if (sessions < 2) {
      final message = sessions == 0
          ? 'No data yet — log your first workout to start tracking '
              'progress.'
          : 'One more session to go — strength trends need at least 2 '
              'workouts.';
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Not enough data yet'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    try {
      ref.read(selectedExerciseProvider.notifier).state = exerciseName;
      if (!context.mounted) return;
      context.go('/progress');
    } catch (e) {
      debugPrint('[strength-curve] navigation failed: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openStrengthCurve(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: palette.accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.show_chart, color: palette.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'View Strength Curve',
                style: textTheme.bodyMedium?.copyWith(
                  color: palette.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(CupertinoIcons.chevron_right,
                size: 18, color: palette.accent),
          ],
        ),
      ),
    );
  }
}

class _PRTile extends ConsumerWidget {
  const _PRTile({required this.exerciseName});

  final String exerciseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final units = ref.watch(unitSystemProvider);
    final async = ref.watch(pr_hall.allPersonalRecordsProvider);
    final prs = async.valueOrNull ?? const <PersonalRecord>[];
    PersonalRecord? match;
    for (final p in prs) {
      if (p.exerciseName.toLowerCase() == exerciseName.toLowerCase()) {
        match = p;
        break;
      }
    }
    if (match == null || match.weightKg <= 0) return const SizedBox.shrink();
    final display =
        UnitConverter.kgToDisplayWeight(match.weightKg, units);
    final unit = UnitConverter.weightUnit(units);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: palette.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Record',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                Text(
                  '${display.toStringAsFixed(0)} $unit × ${match.bestReps} reps',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Per-exercise military rank ────────────────────────────────────────────

class _RankSection extends ConsumerWidget {
  const _RankSection({required this.exerciseName});

  final String exerciseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final units = ref.watch(unitSystemProvider);
    final async = ref.watch(exerciseRankDetailProvider(exerciseName));

    if (async.isLoading && !async.hasValue) {
      return const ShimmerBox(
          width: double.infinity, height: 96, borderRadius: 12);
    }
    final detail = async.valueOrNull;
    // Not rankable (bodyweight / cardio) → render nothing.
    if (detail == null) return const SizedBox.shrink();

    final unit = UnitConverter.weightUnit(units);

    // Rankable but no PR logged yet → empty state.
    if (!detail.hasData) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.shield_lefthalf_fill,
                color: palette.textSecondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Log this exercise to earn your rank.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: palette.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final best = UnitConverter.kgToDisplayWeight(detail.bestWeightKg, units);
    final rankColor = detail.rank.color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rankColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RankBadge(rank: detail.rank, size: 30),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Your best: ${best.toStringAsFixed(0)} $unit',
            style: textTheme.bodyMedium?.copyWith(color: palette.text),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: detail.progressToNext.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: palette.surfaceElevated,
              valueColor: AlwaysStoppedAnimation(rankColor),
            ),
          ),
          const SizedBox(height: 6),
          if (detail.nextRank != null)
            Text(
              _nextRankText(
                weightToNextKg: detail.weightToNextKg,
                targetWeightKg: detail.targetWeightKg,
                targetReps: detail.targetReps,
                next: detail.nextRank!,
                units: units,
              ),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: palette.textSecondary,
              ),
            )
          else
            Text(
              'Top rank achieved — Sergeant Major of the Army 🎖️',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: rankColor,
              ),
            ),
        ],
      ),
    );
  }

  /// The concrete rank-up target: "195 lbs × 5 → Corporal". Holds the user's PR
  /// reps constant and shows the weight that reaches the next rank at those
  /// reps. [targetWeightKg] is in kg; convert ONCE here for display.
  String _nextRankText({
    required double? weightToNextKg,
    required double? targetWeightKg,
    required int targetReps,
    required MilitaryRank next,
    required UnitSystem units,
  }) {
    // Already at/over the threshold (no weight to add) → ready to promote.
    if (weightToNextKg == null || weightToNextKg <= 0 || targetWeightKg == null) {
      return 'Ready to rank up to ${next.displayName}!';
    }
    final target = UnitConverter.kgToDisplayWeight(targetWeightKg, units);
    final unit = UnitConverter.weightUnit(units);
    return '${target.toStringAsFixed(0)} $unit × $targetReps → ${next.displayName}';
  }
}

// ─── Equipment chips ───────────────────────────────────────────────────────

class _EquipmentChips extends StatelessWidget {
  const _EquipmentChips({
    required this.asyncEx,
    required this.localFallback,
    required this.palette,
    required this.textTheme,
  });

  final AsyncValue<ExerciseDBExercise?> asyncEx;
  final ExerciseDefinition? localFallback;
  final Palette palette;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final apiEquip = asyncEx.valueOrNull?.equipments ?? const [];
    final names = apiEquip.isNotEmpty
        ? apiEquip
        : (localFallback != null
            ? [localFallback!.equipment.toString().split('.').last]
            : const <String>[]);
    if (names.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Equipment',
          style: textTheme.titleSmall?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            color: palette.text,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: names
              .map((n) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: palette.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      n,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: palette.text,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─── Steps block (instructions / tips) ─────────────────────────────────────

class _StepsBlock extends StatefulWidget {
  const _StepsBlock({
    required this.title,
    required this.icon,
    required this.steps,
    required this.fallback,
    required this.palette,
    required this.textTheme,
  });

  final String title;
  final IconData icon;
  final List<String> steps;
  final List<String> fallback;
  final Palette palette;
  final TextTheme textTheme;

  @override
  State<_StepsBlock> createState() => _StepsBlockState();
}

class _StepsBlockState extends State<_StepsBlock> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final lines = widget.steps.isNotEmpty ? widget.steps : widget.fallback;
    if (lines.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: widget.palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(widget.icon,
                      color: widget.palette.accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: widget.textTheme.titleSmall?.copyWith(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: widget.palette.text,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    color: widget.palette.textSecondary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < lines.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: widget.palette.accent
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: widget.palette.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              lines[i],
                              style: widget.textTheme.bodyMedium?.copyWith(
                                color: widget.palette.text,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
