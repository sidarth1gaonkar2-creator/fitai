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
      backgroundColor: palette.background,
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
            const SizedBox(height: 16),

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

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.asyncEx});

  final AsyncValue<ExerciseDBExercise?> asyncEx;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return AspectRatio(
      aspectRatio: 16 / 11,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Builder(builder: (context) {
          if (asyncEx.isLoading && !asyncEx.hasValue) {
            return const ShimmerBox(
                width: double.infinity, height: double.infinity);
          }
          final url = asyncEx.valueOrNull?.fullImageUrl;
          if (url == null) {
            return Container(
              color: palette.surface,
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.photo,
                size: 48,
                color: palette.textSecondary,
              ),
            );
          }
          return CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, _) => const ShimmerBox(
                width: double.infinity, height: double.infinity),
            errorWidget: (_, _, _) => Container(
              color: palette.surface,
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 36,
                color: palette.textSecondary,
              ),
            ),
          );
        }),
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
              fontFamily: 'Poppins',
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
            fontFamily: 'Poppins',
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
        fontFamily: 'LeagueSpartan',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Pre-select the exercise in the curve provider then jump to
        // Progress. Cheaper than carrying state through go_router extras.
        ref.read(selectedExerciseProvider.notifier).state = exerciseName;
        context.push('/progress');
      },
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
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                Text(
                  '${display.toStringAsFixed(0)} $unit × ${match.bestReps} reps',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
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
            fontFamily: 'Poppins',
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
                        fontFamily: 'Poppins',
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
                        fontFamily: 'Poppins',
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
                                fontFamily: 'Poppins',
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
