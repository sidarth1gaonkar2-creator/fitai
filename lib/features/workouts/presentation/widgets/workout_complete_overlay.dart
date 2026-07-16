import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../providers/unit_system_provider.dart';
import '../../../ranks/domain/drill_sergeant.dart';
import '../../../ranks/domain/exercise_standards.dart';
import '../../../ranks/domain/military_ranks.dart';
import '../../../ranks/presentation/widgets/rank_badge.dart';
import '../../../ranks/presentation/widgets/rank_celebration_overlay.dart'
    show CupertinoButtonLike;
import '../../domain/workout_results.dart';

/// Full-screen "Workout Complete" results screen shown after EVERY finish.
///
/// Presented as a [showGeneralDialog] overlay on the CURRENT navigator (exactly
/// like [RankCelebrationOverlay]) — it adds NO go_router route and never pushes
/// across the shell, so it cannot trigger the duplicate-`_shellStateKey`
/// black-screen bug. Always shows the workout summary + current per-muscle rank
/// badges; ↑ranked-up / ▲improved / new-PR indicators appear only when earned.
class WorkoutCompleteOverlay extends ConsumerStatefulWidget {
  const WorkoutCompleteOverlay({
    super.key,
    required this.results,
    required this.onDismiss,
  });

  final WorkoutResults results;
  final VoidCallback onDismiss;

  @override
  ConsumerState<WorkoutCompleteOverlay> createState() =>
      _WorkoutCompleteOverlayState();
}

class _WorkoutCompleteOverlayState
    extends ConsumerState<WorkoutCompleteOverlay> {
  late final String _praise;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    // Settle one praise line for the lifetime of the overlay (drill-sergeant
    // completion feedback — the line shown for every finish, PR or not).
    _praise = randomWorkoutPraise();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return '${d.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.results;
    final summary = results.summary;
    final colors = AppColors.of(context);
    final accent = colors.accent;
    final units = ref.watch(unitSystemProvider);

    final volume =
        UnitConverter.kgToDisplayWeight(summary.volumeKg, units).round();
    final volumeStr = '$volume ${UnitConverter.weightUnit(units)}';

    return Material(
      // Ink scrim — ceremony ground per DESIGN.md, not pure black.
      color: const Color(0xFF1A1C1A).withValues(alpha: 0.96),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'WORKOUT COMPLETE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      fontVariations: const [FontVariation('wght', 700)],
                      fontWeight: FontWeight.w700,
                      fontSize: 26,
                      height: 1.05,
                      letterSpacing: 1,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: Color(0xFFE8E4D8), // bone
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _praise,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        height: 1.45,
                        color: Color(0xFFCDC8BA), // muted bone
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SummaryRow(
                    items: [
                      _StatItem(
                          label: 'TIME',
                          value: _formatDuration(summary.duration)),
                      _StatItem(label: 'SETS', value: '${summary.sets}'),
                      _StatItem(label: 'VOLUME', value: volumeStr),
                      _StatItem(
                          label: 'MOVES', value: '${summary.exercises}'),
                    ],
                  ),
                  if (results.muscles.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    _SectionLabel('MUSCLE RANKS'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final m in results.muscles)
                          _MuscleBadgeChip(result: m),
                      ],
                    ),
                  ],
                  if (results.earnedAnything) ...[
                    const SizedBox(height: 26),
                    _SectionLabel('EARNED THIS SESSION'),
                    const SizedBox(height: 12),
                    ..._earnedRows(results),
                  ],
                  const SizedBox(height: 30),
                  CupertinoButtonLike(
                    color: accent,
                    onPressed: widget.onDismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _earnedRows(WorkoutResults results) {
    final rows = <Widget>[];
    if (results.overallRankedUp) {
      rows.add(_EarnedRow(
        icon: Icons.military_tech,
        color: results.overallRank.color,
        text: 'Promoted to ${results.overallRank.displayName}',
        emphatic: true,
      ));
    }
    for (final m in results.muscles.where((m) => m.rankedUp)) {
      rows.add(_EarnedRow(
        icon: Icons.arrow_upward,
        color: m.rank.color,
        text: '${m.group.label} ranked up to ${m.rank.displayName}',
      ));
    }
    for (final e in results.exercises.where((e) => e.newPR)) {
      rows.add(_EarnedRow(
        icon: Icons.bolt,
        color: AppColors.of(context).warning,
        text: 'New PR — ${e.name}',
      ));
    }
    return rows;
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.items});

  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Container(
              width: 1,
              height: 34,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          Expanded(child: items[i]),
        ],
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    // A stat readout (DESIGN.md signature component): bone mono value over
    // a quiet mono eyebrow.
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontVariations: [FontVariation('wght', 700)],
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Color(0xFFE8E4D8), // bone
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontVariations: [FontVariation('wght', 700)],
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 1.2,
            color: Color(0xFF8C9377), // lifted olive
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'JetBrainsMono',
        fontVariations: [FontVariation('wght', 700)],
        fontSize: 11,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFFCDC8BA), // muted bone
      ),
    );
  }
}

class _MuscleBadgeChip extends StatelessWidget {
  const _MuscleBadgeChip({required this.result});

  final MuscleResult result;

  @override
  Widget build(BuildContext context) {
    final indicator = result.rankedUp
        ? Icons.arrow_upward
        : (result.improved ? Icons.trending_up : null);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF21241F), // field
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.rankedUp
              ? result.rank.color.withValues(alpha: 0.7)
              : const Color(0x1FE8E4D8), // hairline
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            result.group.label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontVariations: [FontVariation('wght', 500)],
              fontWeight: FontWeight.w500,
              fontSize: 11,
              letterSpacing: 0.5,
              color: Color(0xFFCDC8BA), // muted bone
            ),
          ),
          const SizedBox(width: 8),
          RankBadge(rank: result.rank, compact: true, size: 22),
          if (indicator != null) ...[
            const SizedBox(width: 4),
            Icon(indicator, size: 14, color: result.rank.color),
          ],
        ],
      ),
    );
  }
}

class _EarnedRow extends StatelessWidget {
  const _EarnedRow({
    required this.icon,
    required this.color,
    required this.text,
    this.emphatic = false,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool emphatic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: emphatic ? FontWeight.w700 : FontWeight.w500,
                fontSize: emphatic ? 15 : 14,
                height: 1.35,
                color: emphatic ? color : const Color(0xFFE8E4D8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
