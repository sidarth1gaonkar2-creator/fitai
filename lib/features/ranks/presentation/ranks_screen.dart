import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../data/exercise_library.dart';
import '../../../providers/unit_system_provider.dart';
import '../domain/drill_sergeant.dart';
import '../domain/exercise_standards.dart';
import '../domain/military_ranks.dart';
import '../providers/rank_providers.dart';
import 'widgets/rank_badge.dart';
import 'widgets/rank_heat_map.dart';

/// Phase-3 dedicated ranks screen: overall rank, a body heat map, per-muscle-
/// group rank cards, a drill-sergeant weak-point callout, and the full
/// per-exercise rank breakdown.
class RanksScreen extends ConsumerWidget {
  const RanksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final async = ref.watch(rankCalculatorProvider);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: CupertinoNavigationBar(
        middle: const Text('My Ranks'),
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
      ),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              ShimmerBox(width: double.infinity, height: 120, borderRadius: 16),
              SizedBox(height: 16),
              ShimmerBox(width: double.infinity, height: 220, borderRadius: 16),
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
              _OverallSection(calc: calc),
              const SizedBox(height: 24),
              _SectionLabel('Strength Map'),
              const SizedBox(height: 4),
              _HeatLegend(),
              const SizedBox(height: 8),
              RankHeatMap(groupRanks: calc.muscleGroupRanks),
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
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Overall rank ───────────────────────────────────────────────────────────

class _OverallSection extends StatelessWidget {
  const _OverallSection({required this.calc});
  final RankCalculation calc;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final hasData = calc.exerciseScores.isNotEmpty;
    final rank = calc.overall;
    final color = rank.color;
    final progress = _progress(calc.overallPoints);
    final next = _next(calc.overallPoints);
    final toNext = next == null ? 0.0 : (rank.index + 1) - calc.overallPoints;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
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
            child: RankInsignia(rank: rank, size: 56),
          ),
          const SizedBox(height: 12),
          Text(
            rank.displayName,
            style: textTheme.titleLarge?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            hasData ? 'Overall Strength Rank · E${rank.tier}' : 'Log lifts to earn your rank',
            style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: 14),
          _RankProgressBar(value: progress, color: color),
          const SizedBox(height: 6),
          Text(
            next == null
                ? 'Top rank achieved, soldier. 🎖️'
                : '${toNext.toStringAsFixed(1)} points to ${next.displayName}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: palette.textSecondary,
            ),
          ),
        ],
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
    // Count ranked exercises per group from the calc.
    final counts = <RankGroup, int>{};
    for (final id in calc.exerciseScores.keys) {
      final group = exerciseStandards[id]?.group;
      if (group != null) counts[group] = (counts[group] ?? 0) + 1;
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
        borderRadius: BorderRadius.circular(14),
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
                  group.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: palette.textSecondary,
              ),
            ),
          const Spacer(),
          _RankProgressBar(value: progress, color: color),
          const SizedBox(height: 5),
          Text(
            '$rankedCount exercise${rankedCount == 1 ? '' : 's'} ranked',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 11,
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.destructive.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.destructive.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: palette.destructive.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
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
                  'Drill Sergeant Says',
                  style: textTheme.titleSmall?.copyWith(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: palette.destructive,
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
  const _ExerciseRow(this.def, this.score, this.rank, this.weightKg);
  final ExerciseDefinition def;
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
        def,
        score,
        rankIdx == null ? null : rankFromIndex(rankIdx),
        calc.exerciseBestWeightKg[def.id],
      );
      byGroup.putIfAbsent(std.group, () => []).add(row);
    }
    // Sort: ranked (highest score first), then unranked alphabetically.
    for (final list in byGroup.values) {
      list.sort((a, b) {
        if (a.score != null && b.score != null) return b.score!.compareTo(a.score!);
        if (a.score != null) return -1;
        if (b.score != null) return 1;
        return a.def.name.toLowerCase().compareTo(b.def.name.toLowerCase());
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Text(
                    group.label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$rankedCount/${rows.length} ranked',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 12,
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
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Column(
                children: [
                  for (final row in rows) _exerciseTile(row),
                ],
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
                  row.def.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: ranked ? palette.text : palette.textSecondary,
                  ),
                ),
                if (ranked)
                  Text(
                    '${weight!.toStringAsFixed(0)} $unit · score ${row.score!.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 11,
                      color: palette.textSecondary,
                    ),
                  )
                else
                  Text(
                    'Not yet ranked',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
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
            Icon(CupertinoIcons.minus,
                size: 14, color: palette.textSecondary.withValues(alpha: 0.5)),
        ],
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
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: AppColors.of(context).accent,
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
      ),
    );
  }
}

/// Five-tier colour legend for the heat map.
class _HeatLegend extends StatelessWidget {
  const _HeatLegend();

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    Widget swatch(MilitaryRank r, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: heatColorForRank(r),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 11,
                color: palette.textSecondary,
              ),
            ),
          ],
        );
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        swatch(MilitaryRank.private_e1, 'PVT–PFC'),
        swatch(MilitaryRank.corporal_e3, 'CPL–SPC'),
        swatch(MilitaryRank.sergeant_e5, 'SGT–SSG'),
        swatch(MilitaryRank.sergeantFc_e7, 'SFC–MSG'),
        swatch(MilitaryRank.sergeantMajor_e9, 'SGM–SMA'),
      ],
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
