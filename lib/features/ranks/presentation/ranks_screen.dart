import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/tactical_surface.dart';
import '../../../data/exercise_library.dart';
import '../../../providers/entitlement_providers.dart';
import '../../../providers/unit_system_provider.dart';
import '../../workouts/presentation/widgets/muscle_highlight_widget.dart';
import '../domain/drill_sergeant.dart';
import '../domain/exercise_standards.dart';
import '../domain/military_ranks.dart';
import '../providers/rank_providers.dart';
import 'widgets/rank_badge.dart';
import 'rank_card_preview.dart';

/// Phase-3 dedicated ranks screen: overall rank, a body heat map, per-muscle-
/// group rank cards, a drill-sergeant weak-point callout, and the full
/// per-exercise rank breakdown.
class RanksScreen extends ConsumerWidget {
  const RanksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final async = ref.watch(rankCalculatorProvider);
    // Airborne subscribers see their OWN current rank brass-mounted — the hero
    // and the "you are here" ladder rung only. Every other rung stays base.
    final airborne = ref.watch(airborneActiveProvider);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: CupertinoNavigationBar(
        middle: const Text('My Ranks'),
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
      ),
      body: SkinBackground(child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              ShimmerBox(width: double.infinity, height: 120, borderRadius: 8),
              SizedBox(height: 16),
              ShimmerBox(width: double.infinity, height: 220, borderRadius: 8),
            ],
          ),
        ),
        error: (_, _) => ErrorCard(
          message: 'Could not load your ranks.',
          onRetry: () => ref.invalidate(rankCalculatorProvider),
        ),
        data: (calc) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OverallSection(calc: calc, airborne: airborne),
              const SizedBox(height: 24),
              _SectionLabel('Your Rank'),
              const SizedBox(height: 10),
              _RankLadder(current: calc.overall, airborne: airborne),
              const SizedBox(height: 24),
              _SectionLabel('Strength Map'),
              const SizedBox(height: 10),
              // The heat map is a silent painting to VoiceOver — give it a
              // one-sentence spoken summary of what it shows.
              Semantics(
                image: true,
                label: calc.muscleGroupRanks.isEmpty
                    ? 'Strength map. No muscle groups ranked yet.'
                    : 'Strength map. ${calc.muscleGroupRanks.entries.map((e) => '${e.key.label}: ${e.value.displayName}').join(', ')}.',
                child: ExcludeSemantics(
                  child: MuscleHighlightWidget.rankHeatMap(
                    muscleGroupRanks: {
                      for (final e in calc.muscleGroupRanks.entries)
                        e.key.name: e.value,
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel('Muscle Groups'),
              const SizedBox(height: 10),
              _MuscleGroupGrid(calc: calc),
              const SizedBox(height: 20),
              _DrillSergeantCard(calc: calc),
              const SizedBox(height: 24),
              _SectionLabel('All Exercises'),
              const SizedBox(height: 10),
              _AllExerciseRanks(calc: calc),
              const SizedBox(height: 24),
              const _ShareRankButton(),
            ],
          ),
        ),
      )),
    );
  }
}

// ─── Overall rank ───────────────────────────────────────────────────────────

class _OverallSection extends StatelessWidget {
  const _OverallSection({required this.calc, this.airborne = false});
  final RankCalculation calc;
  final bool airborne;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final hasData = calc.exerciseScores.isNotEmpty;
    final rank = calc.overall;
    final color = rank.color;
    final progress = _progress(calc.overallPoints);
    final next = _next(calc.overallPoints);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: RankInsignia(rank: rank, size: 56, airborne: airborne),
          ),
          const SizedBox(height: 12),
          // The rank designation — the sergeant's bark.
          Text(
            rank.displayName.toUpperCase(),
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              fontFamily: 'Oswald',
              fontVariations: const [FontVariation('wght', 700)],
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            hasData
                ? 'OVERALL RANK · E${rank.tier}'
                : 'Log lifts to earn your rank',
            style: hasData
                ? TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontVariations: const [FontVariation('wght', 700)],
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: palette.textSecondary,
                  )
                : textTheme.bodySmall?.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: 14),
          _RankProgressBar(value: progress, color: color),
          const SizedBox(height: 6),
          Text(
            next == null
                ? 'Top rank achieved, soldier. 🎖️'
                : '${(progress * 100).round()}% TO ${next.displayName.toUpperCase()}',
            style: next == null
                ? TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                  )
                : TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontVariations: const [FontVariation('wght', 500)],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: palette.textSecondary,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Rank ladder ────────────────────────────────────────────────────────────

/// Vertical ladder of all 10 ranks (SMA at top → Private at bottom) with the
/// user's current rank highlighted, so where they stand among the ranks is
/// obvious at a glance without decoding "E3" / "CPL".
class _RankLadder extends StatefulWidget {
  const _RankLadder({required this.current, this.airborne = false});
  final MilitaryRank current;
  final bool airborne;

  @override
  State<_RankLadder> createState() => _RankLadderState();
}

class _RankLadderState extends State<_RankLadder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: the current-rank node holds steady instead of pulsing.
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final ranks = MilitaryRank.values.reversed.toList(); // SMA → Private
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      // Ladder text rides Dynamic Type clamped at 1.35× and each row grows
      // with the scale, so rank names never clip at AX sizes.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.35,
        child: Builder(
          builder: (context) {
            return Column(
              children: [
                for (var i = 0; i < ranks.length; i++)
                  _RankLadderRow(
                    rank: ranks[i],
                    current: widget.current,
                    isFirst: i == 0,
                    isLast: i == ranks.length - 1,
                    pulse: _pulse,
                    palette: palette,
                    airborne: widget.airborne,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RankLadderRow extends StatelessWidget {
  const _RankLadderRow({
    required this.rank,
    required this.current,
    required this.isFirst,
    required this.isLast,
    required this.pulse,
    required this.palette,
    this.airborne = false,
  });

  final MilitaryRank rank;
  final MilitaryRank current;
  final bool isFirst;
  final bool isLast;
  final Animation<double> pulse;
  final Palette palette;
  final bool airborne;

  @override
  Widget build(BuildContext context) {
    // 34pt at default text size, growing with the (clamped) scaler.
    final double rowHeight = math.max(
      34.0,
      MediaQuery.textScalerOf(context).scale(13) + 21,
    );
    final isCurrent = rank == current;
    final isEarned = rank.index < current.index; // already passed
    // One spoken sentence per row — earned state is otherwise conveyed by
    // colour/opacity alone, which VoiceOver cannot perceive.
    final semanticsLabel = isCurrent
        ? '${rank.displayName}, E${rank.tier} — current rank'
        : isEarned
        ? '${rank.displayName}, E${rank.tier} — earned'
        : '${rank.displayName}, E${rank.tier} — not yet earned';
    final color = rank.color;
    // The current row's name reads in bone — the rank colour already speaks
    // through the insignia, node, border and stamp, and several ramp colours
    // sit below 4.5:1 on ink at 13pt.
    final nameColor = isCurrent
        ? palette.text
        : (isEarned
              ? palette.textSecondary
              : palette.text.withValues(alpha: 0.55));

    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: Container(
        height: rowHeight,
        decoration: isCurrent
            ? BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            // Connecting rail + node.
            SizedBox(
              width: 22,
              height: rowHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: isFirst ? rowHeight / 2 : 0,
                    bottom: isLast ? rowHeight / 2 : 0,
                    child: Container(width: 2, color: palette.border),
                  ),
                  if (isCurrent)
                    AnimatedBuilder(
                      animation: pulse,
                      builder: (_, _) => Container(
                        width: 10 + 5 * pulse.value,
                        height: 10 + 5 * pulse.value,
                        decoration: BoxDecoration(
                          color: color.withValues(
                            alpha: 0.30 * (1 - pulse.value) + 0.10,
                          ),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isEarned
                            ? palette.textSecondary
                            : palette.surface,
                        shape: BoxShape.circle,
                        border: isEarned
                            ? null
                            : Border.all(color: palette.border, width: 1.5),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Opacity(
              opacity: isCurrent ? 1.0 : (isEarned ? 0.9 : 0.55),
              // 20pt floor — MSG's six chevrons turn to mush below it.
              // GUARDRAIL: the mount is applied ONLY to the user's own current
              // rung — never to other rungs (earned or locked). Rank is earned,
              // never bought; the ladder must not imply buying rank.
              child: RankInsignia(
                  rank: rank, size: 20, airborne: airborne && isCurrent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                rank.displayName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Oswald',
                  fontVariations: [
                    FontVariation('wght', isCurrent ? 600 : 500),
                  ],
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                  letterSpacing: 0.5,
                  color: nameColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'YOU ARE HERE',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontVariations: const [FontVariation('wght', 700)],
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    // Black/white split at L 0.175 clears 4.5:1 on every ramp
                    // colour (ink falls short on the mid-luminance purples).
                    color: color.computeLuminance() >= 0.175
                        ? Colors.black
                        : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            else
              Text(
                rank.abbreviation,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontVariations: const [FontVariation('wght', 500)],
                  fontSize: 11,
                  letterSpacing: 0.5,
                  color: palette.textSecondary.withValues(
                    alpha: isEarned ? 0.9 : 0.7,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Muscle group grid ──────────────────────────────────────────────────────

class _MuscleGroupGrid extends StatelessWidget {
  const _MuscleGroupGrid({required this.calc});
  final RankCalculation calc;

  static IconData _icon(RankGroup g) => switch (g) {
    RankGroup.chest => Icons.fitness_center,
    RankGroup.back => Icons.rowing,
    RankGroup.legs => Icons.directions_walk,
    RankGroup.shoulders => Icons.sports_gymnastics,
    RankGroup.arms => Icons.sports_mma,
    RankGroup.core => Icons.self_improvement,
  };

  @override
  Widget build(BuildContext context) {
    // Count ranked exercises per group from the calc. Built-in exercises map
    // their id → group via the standards table; custom (off-library) keys
    // aren't in that table, so they're counted from [customExercises].
    final counts = <RankGroup, int>{};
    for (final id in calc.exerciseScores.keys) {
      final group = exerciseStandards[id]?.group;
      if (group != null) counts[group] = (counts[group] ?? 0) + 1;
    }
    for (final custom in calc.customExercises) {
      counts[custom.group] = (counts[custom.group] ?? 0) + 1;
    }

    final cards = [
      for (final g in RankGroup.values)
        _MuscleGroupCard(
          group: g,
          icon: _icon(g),
          points: calc.muscleGroupPoints[g],
          rank: calc.muscleGroupRanks[g],
          rankedCount: counts[g] ?? 0,
        ),
    ];

    // Content-driven 2-column layout instead of a fixed-aspect GridView. A
    // fixed childAspectRatio ties cell HEIGHT to WIDTH, so on a narrow screen
    // (or under iOS Dynamic Type, which the app doesn't clamp) the cell becomes
    // shorter than the card's content — the Spacer collapses and the Column
    // overflows. Pairing cards in IntrinsicHeight rows lets each row grow to
    // its tallest card's natural height, so it can never clip.
    const gap = 12.0;
    return Column(
      children: [
        for (var i = 0; i < cards.length; i += 2) ...[
          if (i > 0) const SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[i]),
                const SizedBox(width: gap),
                if (i + 1 < cards.length)
                  Expanded(child: cards[i + 1])
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MuscleGroupCard extends StatelessWidget {
  const _MuscleGroupCard({
    required this.group,
    required this.icon,
    required this.points,
    required this.rank,
    required this.rankedCount,
  });

  final RankGroup group;
  final IconData icon;
  final double? points;
  final MilitaryRank? rank;
  final int rankedCount;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final color = rank?.color ?? palette.textSecondary;
    final progress = points == null ? 0.0 : _progress(points!);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  group.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    fontVariations: const [FontVariation('wght', 600)],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.5,
                    color: palette.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (rank != null)
            RankBadge(rank: rank!, compact: true, size: 18)
          else
            Text(
              'Unranked',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: palette.textSecondary,
              ),
            ),
          const Spacer(),
          _RankProgressBar(value: progress, color: color),
          const SizedBox(height: 5),
          Text(
            // Ranked-count is a readout.
            '$rankedCount RANKED',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontVariations: const [FontVariation('wght', 500)],
              fontSize: 11,
              letterSpacing: 0.6,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Drill Sergeant weak-point card ─────────────────────────────────────────

class _DrillSergeantCard extends StatelessWidget {
  const _DrillSergeantCard({required this.calc});
  final RankCalculation calc;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final message = weakPointMessage(calc.muscleGroupPoints);
    // FM alert, not iOS system red — this is a consequence callout
    // (DESIGN.md); the Oswald title qualifies as large text.
    const alert = Color(0xFFC24A38);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alert.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: alert.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: alert.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: const Text('🪖', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DRILL SERGEANT SAYS',
                  style: textTheme.titleSmall?.copyWith(
                    fontFamily: 'Oswald',
                    fontVariations: const [FontVariation('wght', 600)],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: alert,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.text,
                    height: 1.35,
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

// ─── All exercises (expandable per group) ───────────────────────────────────

class _ExerciseRow {
  const _ExerciseRow(this.name, this.score, this.rank, this.weightKg);
  final String name;
  final double? score; // null → not yet ranked
  final MilitaryRank? rank;
  final double? weightKg;
}

class _AllExerciseRanks extends ConsumerStatefulWidget {
  const _AllExerciseRanks({required this.calc});
  final RankCalculation calc;

  @override
  ConsumerState<_AllExerciseRanks> createState() => _AllExerciseRanksState();
}

class _AllExerciseRanksState extends ConsumerState<_AllExerciseRanks> {
  final _expanded = <RankGroup>{};

  Map<RankGroup, List<_ExerciseRow>> _build() {
    final calc = widget.calc;
    final byGroup = <RankGroup, List<_ExerciseRow>>{};
    for (final def in exerciseLibrary) {
      final std = exerciseStandards[def.id];
      if (std == null || !std.rankable) continue;
      final score = calc.exerciseScores[def.id];
      final rankIdx = calc.exerciseRanks[def.id];
      final row = _ExerciseRow(
        def.name,
        score,
        rankIdx == null ? null : rankFromIndex(rankIdx),
        calc.exerciseBestWeightKg[def.id],
      );
      byGroup.putIfAbsent(std.group, () => []).add(row);
    }
    // User-custom (off-library) exercises that scored — surface them under the
    // group the user chose at creation. They aren't in [exerciseLibrary], so
    // the loop above never reaches them.
    for (final custom in calc.customExercises) {
      final rankIdx = calc.exerciseRanks[custom.key];
      byGroup
          .putIfAbsent(custom.group, () => [])
          .add(
            _ExerciseRow(
              custom.name,
              calc.exerciseScores[custom.key],
              rankIdx == null ? null : rankFromIndex(rankIdx),
              calc.exerciseBestWeightKg[custom.key],
            ),
          );
    }
    // Sort: ranked (highest score first), then unranked alphabetically.
    for (final list in byGroup.values) {
      list.sort((a, b) {
        if (a.score != null && b.score != null) {
          return b.score!.compareTo(a.score!);
        }
        if (a.score != null) return -1;
        if (b.score != null) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }
    return byGroup;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final units = ref.watch(unitSystemProvider);
    final byGroup = _build();

    return Column(
      children: [
        for (final g in RankGroup.values)
          if (byGroup[g] != null && byGroup[g]!.isNotEmpty)
            _GroupExpansion(
              group: g,
              rows: byGroup[g]!,
              expanded: _expanded.contains(g),
              units: units,
              palette: palette,
              onToggle: () => setState(() {
                HapticFeedback.selectionClick();
                if (!_expanded.add(g)) _expanded.remove(g);
              }),
            ),
      ],
    );
  }
}

class _GroupExpansion extends StatelessWidget {
  const _GroupExpansion({
    required this.group,
    required this.rows,
    required this.expanded,
    required this.units,
    required this.palette,
    required this.onToggle,
  });

  final RankGroup group;
  final List<_ExerciseRow> rows;
  final bool expanded;
  final UnitSystem units;
  final Palette palette;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final rankedCount = rows.where((r) => r.score != null).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Semantics(
            button: true,
            label:
                '${group.label}, $rankedCount of ${rows.length} ranked, '
                '${expanded ? 'expanded' : 'collapsed'}',
            child: ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        group.label.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontVariations: const [FontVariation('wght', 600)],
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          letterSpacing: 0.5,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$rankedCount/${rows.length}',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontVariations: const [FontVariation('wght', 500)],
                          fontSize: 11,
                          letterSpacing: 0.5,
                          color: palette.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        expanded
                            ? CupertinoIcons.chevron_up
                            : CupertinoIcons.chevron_down,
                        size: 16,
                        color: palette.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Column(
                children: [for (final row in rows) _exerciseTile(row)],
              ),
            ),
        ],
      ),
    );
  }

  Widget _exerciseTile(_ExerciseRow row) {
    final ranked = row.score != null && row.rank != null;
    final weight = row.weightKg == null
        ? null
        : UnitConverter.kgToDisplayWeight(row.weightKg!, units);
    final unit = UnitConverter.weightUnit(units);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: ranked ? palette.text : palette.textSecondary,
                  ),
                ),
                if (ranked)
                  Text(
                    // Best lift — a trained-against number, so mono.
                    '${weight!.toStringAsFixed(0)} ${unit.toUpperCase()}',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontVariations: const [FontVariation('wght', 700)],
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: palette.textSecondary,
                    ),
                  )
                else
                  Text(
                    'Not yet ranked',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: palette.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (ranked)
            RankBadge(rank: row.rank!, compact: true, size: 16)
          else
            Icon(
              CupertinoIcons.minus,
              size: 14,
              color: palette.textSecondary.withValues(alpha: 0.5),
            ),
        ],
      ),
    );
  }
}

// ─── Share ──────────────────────────────────────────────────────────────────

class _ShareRankButton extends ConsumerWidget {
  const _ShareRankButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        label: 'Share my rank',
        button: true,
        child: ExcludeSemantics(
          child: CupertinoButton(
            color: palette.accent,
            borderRadius: BorderRadius.circular(4),
            onPressed: () => openRankCardPreview(context),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.share, size: 18, color: Color(0xFF1A1C1A)),
                SizedBox(width: 8),
                Text(
                  'SHARE MY RANK',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    fontVariations: [FontVariation('wght', 600)],
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.6,
                    color: Color(0xFF1A1C1A), // ink on accent
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared bits ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    // Section headers wear the display face in bone — the One Voice Rule
    // keeps the accent for actions and the rank colours for insignia.
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontFamily: 'Oswald',
        fontVariations: const [FontVariation('wght', 600)],
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.of(context).text,
      ),
    );
  }
}

class _RankProgressBar extends StatelessWidget {
  const _RankProgressBar({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 7,
        backgroundColor: palette.surfaceElevated,
        valueColor: AlwaysStoppedAnimation(color),
        // Otherwise VoiceOver announces a naked percentage.
        semanticsLabel: 'Progress to next rank',
      ),
    );
  }
}

// Overall/group rank-points (0–9) → progress within the current rank band.
double _progress(double points) {
  final floor = points.floor();
  if (floor >= MilitaryRank.values.length - 1) return 1;
  return (points - floor).clamp(0.0, 1.0);
}

// The next rank up from a rank-points value, or null at the top.
MilitaryRank? _next(double points) {
  final floor = points.floor();
  if (floor >= MilitaryRank.values.length - 1) return null;
  return rankFromIndex(floor + 1);
}
