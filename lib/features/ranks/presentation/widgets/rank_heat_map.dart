import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/anatomy_paths.dart';
import '../../domain/exercise_standards.dart';
import '../../domain/military_ranks.dart';

/// Tier colour for a muscle group's rank on the heat map (5 tiers, two ranks
/// each), per the Phase-3 spec. Unranked groups read as a dim neutral.
Color heatColorForRank(MilitaryRank? rank) {
  if (rank == null) return const Color(0xFF3A3A3C);
  switch (rank) {
    case MilitaryRank.private_e1:
    case MilitaryRank.privateFc_e2:
      return const Color(0xFF636366); // gray
    case MilitaryRank.corporal_e3:
    case MilitaryRank.specialist_e4:
      return const Color(0xFF64D2FF); // light blue
    case MilitaryRank.sergeant_e5:
    case MilitaryRank.staffSergeant_e6:
      return const Color(0xFF0A84FF); // blue
    case MilitaryRank.sergeantFc_e7:
    case MilitaryRank.masterSergeant_e8:
      return const Color(0xFF30A8FF); // bright blue
    case MilitaryRank.sergeantMajor_e9:
    case MilitaryRank.sgmArmy_e10:
      return const Color(0xFFFFD60A); // gold
  }
}

/// Front-view anatomy zone (AnatomyPaths key) → ranking group.
const Map<String, RankGroup> _frontZoneGroups = {
  'chest': RankGroup.chest,
  'deltoids': RankGroup.shoulders,
  'biceps': RankGroup.arms,
  'forearms': RankGroup.arms,
  'abs': RankGroup.core,
  'obliques': RankGroup.core,
  'hip flexors': RankGroup.legs,
  'quadriceps': RankGroup.legs,
  'tibialis': RankGroup.legs,
};

/// Back-view anatomy zone (AnatomyPaths key) → ranking group.
const Map<String, RankGroup> _backZoneGroups = {
  'traps': RankGroup.back,
  'lats': RankGroup.back,
  'lower back': RankGroup.back,
  'rear deltoids': RankGroup.shoulders,
  'triceps': RankGroup.arms,
  'forearms': RankGroup.arms,
  'glutes': RankGroup.legs,
  'hamstrings': RankGroup.legs,
  'calves': RankGroup.legs,
};

/// Front + back body diagrams with each muscle group tinted by its rank tier —
/// an instant strong-vs-weak overview. Drawn with [AnatomyPaths] geometry
/// (silhouette outline + per-zone fills), so colouring is per-group and clean.
class RankHeatMap extends StatelessWidget {
  const RankHeatMap({super.key, required this.groupRanks, this.height = 220});

  /// Rank per group; a missing group renders as "unranked".
  final Map<RankGroup, MilitaryRank> groupRanks;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: _HeatPanel(
              zoneGroups: _frontZoneGroups,
              isFront: true,
              groupRanks: groupRanks,
              bodyColor: palette.surfaceElevated,
              outlineColor: palette.border,
              label: 'Front',
              labelColor: palette.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _HeatPanel(
              zoneGroups: _backZoneGroups,
              isFront: false,
              groupRanks: groupRanks,
              bodyColor: palette.surfaceElevated,
              outlineColor: palette.border,
              label: 'Back',
              labelColor: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatPanel extends StatelessWidget {
  const _HeatPanel({
    required this.zoneGroups,
    required this.isFront,
    required this.groupRanks,
    required this.bodyColor,
    required this.outlineColor,
    required this.label,
    required this.labelColor,
  });

  final Map<String, RankGroup> zoneGroups;
  final bool isFront;
  final Map<RankGroup, MilitaryRank> groupRanks;
  final Color bodyColor;
  final Color outlineColor;
  final String label;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 0.46,
              child: CustomPaint(
                painter: _HeatPainter(
                  zoneGroups: zoneGroups,
                  isFront: isFront,
                  groupRanks: groupRanks,
                  bodyColor: bodyColor,
                  outlineColor: outlineColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}

class _HeatPainter extends CustomPainter {
  _HeatPainter({
    required this.zoneGroups,
    required this.isFront,
    required this.groupRanks,
    required this.bodyColor,
    required this.outlineColor,
  });

  final Map<String, RankGroup> zoneGroups;
  final bool isFront;
  final Map<RankGroup, MilitaryRank> groupRanks;
  final Color bodyColor;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final silhouette = AnatomyPaths.silhouette(size);

    // Neutral body fill.
    canvas.drawPath(silhouette, Paint()..color = bodyColor);

    // Per-group zone fills, clipped to the body so nothing bleeds outside.
    canvas.save();
    canvas.clipPath(silhouette);
    for (final entry in zoneGroups.entries) {
      final path = isFront
          ? AnatomyPaths.frontPathFor(entry.key, size)
          : AnatomyPaths.backPathFor(entry.key, size);
      if (path == null) continue;
      final color = heatColorForRank(groupRanks[entry.value]);
      canvas.drawPath(path, Paint()..color = color);
    }
    canvas.restore();

    // Outline on top so the figure stays legible.
    canvas.drawPath(
      silhouette,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_HeatPainter old) =>
      old.isFront != isFront ||
      old.bodyColor != bodyColor ||
      old.outlineColor != outlineColor ||
      !mapEquals(old.zoneGroups, zoneGroups) ||
      !_mapEq(old.groupRanks, groupRanks);

  static bool _mapEq(
      Map<RankGroup, MilitaryRank> a, Map<RankGroup, MilitaryRank> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
