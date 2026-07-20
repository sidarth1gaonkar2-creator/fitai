import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/field_manual.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../providers/health_providers.dart';
import '../../../providers/progress_providers.dart';
import '../../../providers/workout_providers.dart';
import 'widgets/fitness_trends.dart';
import '../../../core/widgets/fm_segmented.dart';
import 'widgets/milestone_badges.dart';
import 'widgets/nutrition_trends.dart';
import 'widgets/strength_chart.dart';
import 'widgets/strength_curve_chart.dart';
import 'widgets/weight_chart.dart';
import 'widgets/weight_entry_dialog.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _selectedTab = 0; // 0 = Workout Log, 1 = Charts

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FieldManual.scaffold,
      appBar: CupertinoNavigationBar(
        middle: Text('PROGRESS', style: FieldManual.title()),
        backgroundColor: FieldManual.ink.withValues(alpha: 0.82),
        border: const Border(bottom: BorderSide(color: FieldManual.hairline)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: FmSegmented<int>(
              segments: const [(0, 'Workout Log'), (1, 'Charts')],
              selected: _selectedTab,
              onChanged: (i) => setState(() => _selectedTab = i),
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _WorkoutLogTab(key: const ValueKey('workout_log'))
                : _ChartsTab(key: const ValueKey('charts')),
          ),
        ],
      ),
    );
  }
}

// ─── Workout Log Tab ─────────────────────────────────────────────────────────

class _WorkoutLogTab extends ConsumerWidget {
  const _WorkoutLogTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(milestonesProvider);
    final weightAsync = ref.watch(weightEntriesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // --- Milestones ---
          Text('MILESTONES', style: FieldManual.headline()),
          const SizedBox(height: 12),
          milestonesAsync.when(
            data: (milestones) => MilestoneBadges(milestones: milestones),
            loading: () => const ShimmerBox(
                width: double.infinity, height: 80, borderRadius: 8),
            error: (_, _) =>
                const ErrorCard(message: 'Could not load milestones.'),
          ),
          const SizedBox(height: 24),

          // --- Body Weight ---
          Row(
            children: [
              Expanded(
                child: Text('BODY WEIGHT', style: FieldManual.headline()),
              ),
              _LogWeightButton(
                onPressed: () => showCupertinoModalPopup(
                  context: context,
                  builder: (_) => const WeightEntryDialog(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          weightAsync.when(
            data: (entries) => WeightChart(entries: entries),
            loading: () => const ShimmerBox(
                width: double.infinity, height: 220, borderRadius: 8),
            error: (_, _) =>
                const ErrorCard(message: 'Could not load weight data.'),
          ),
          const SizedBox(height: 24),

          // --- Strength ---
          // Multi-metric curve chart (Est. 1RM / Max Weight / Volume) with
          // an inline exercise picker. The wrapper defaults the selection
          // to the user's most-frequently-logged exercise so first-time
          // visitors land on a populated chart instead of an empty picker.
          // Gated on 3+ workout sessions so a fresh user isn't shown an
          // empty chart on day one.
          const _StrengthSectionGate(),

          // --- Fitness Trends (Apple Health, iOS only when connected) ---
          // Consolidates the previous "Activity Trends" (Steps + Calories
          // burned line chart) and "Fitness Trends" (Move calories +
          // Exercise minutes) into a single section so the user sees each
          // Apple-Health metric exactly once. The "Calories burned" line
          // was duplicate data — Move calories IS the daily active energy
          // burned.
          if (Platform.isIOS && ref.watch(healthConnectedProvider)) ...[
            Text('FITNESS TRENDS', style: FieldManual.headline()),
            const SizedBox(height: 12),
            const FitnessTrends(),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

/// Compact accent CTA next to the Body Weight header — FM issue: accent
/// fill, on-accent ink, Oswald uppercase, sharp 4px, ≥44pt target.
class _LogWeightButton extends StatelessWidget {
  const _LogWeightButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    // Spoken label stays sentence case; the uppercase is visual only.
    return Semantics(
      label: 'Log weight',
      button: true,
      child: ExcludeSemantics(
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          color: palette.accent,
          borderRadius: BorderRadius.circular(4),
          onPressed: onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.add, color: palette.onAccent, size: 16),
              const SizedBox(width: 4),
              Text(
                'LOG WEIGHT',
                style: TextStyle(
                  fontFamily: 'Oswald',
                  fontVariations: const [FontVariation('wght', 600)],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.6,
                  color: palette.onAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Charts Tab ──────────────────────────────────────────────────────────────

class _ChartsTab extends StatelessWidget {
  const _ChartsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // --- Personal Records ---
          _PRHallCard(),
          const SizedBox(height: 28),

          // --- Strength Progress ---
          Text('STRENGTH PROGRESS', style: FieldManual.headline()),
          const SizedBox(height: 12),
          const StrengthChart(),
          const SizedBox(height: 28),

          // --- Nutrition Trends ---
          Text('NUTRITION TRENDS', style: FieldManual.headline()),
          const SizedBox(height: 12),
          const NutritionTrends(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── PR Hall Navigation Card ────────────────────────────────────────────────

class _PRHallCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Semantics(
      label: 'Personal records. View your all-time bests',
      button: true,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/progress/pr-hall');
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FieldManual.field,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FieldManual.hairline),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: FieldManual.fieldRaised,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: FieldManual.hairline),
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: palette.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PERSONAL RECORDS', style: FieldManual.title()),
                      const SizedBox(height: 2),
                      Text(
                        'View your all-time bests',
                        style: FieldManual.body(
                          fontSize: 13,
                          color: FieldManual.mutedBone,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 18,
                  color: FieldManual.mutedBone,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Strength section wrapper ───────────────────────────────────────────────

/// Gates the entire strength section behind 3+ logged workouts so a fresh
/// user doesn't see an empty chart. Once the threshold is hit we render the
/// section header + the auto-bootstrapping curve chart.
class _StrengthSectionGate extends ConsumerWidget {
  const _StrengthSectionGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(allWorkoutsProvider);
    final count = workoutsAsync.valueOrNull?.length ?? 0;
    if (count < 3) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STRENGTH', style: FieldManual.headline()),
        const SizedBox(height: 12),
        const _StrengthSection(),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Wraps [StrengthCurveChart] with a one-shot bootstrapping step that
/// selects the user's most-frequently-logged exercise when nothing has been
/// picked yet. Subsequent picks made via the chart's dropdown win — we
/// only override the initial null state.
class _StrengthSection extends ConsumerWidget {
  const _StrengthSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedExerciseProvider);
    if (selected == null) {
      // Listen, not watch — we don't want to fight the user if they
      // explicitly clear the selection later (the chart's dropdown doesn't
      // expose a "clear" affordance today, so the bootstrap is effectively
      // one-shot per cold start).
      final mostFrequentAsync = ref.watch(mostFrequentExerciseProvider);
      mostFrequentAsync.whenData((name) {
        if (name != null && ref.read(selectedExerciseProvider) == null) {
          // Defer to avoid mutating providers during a build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedExerciseProvider.notifier).state = name;
          });
        }
      });
    }
    return const StrengthCurveChart();
  }
}
