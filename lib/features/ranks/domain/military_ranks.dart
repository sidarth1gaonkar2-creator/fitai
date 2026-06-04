// Rank enum values use the spec-mandated E-grade names (private_e1 …).
// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';

/// The 10 enlisted ranks the DrillFit ranking system maps lifters onto, from
/// Private (E1) up to Sergeant Major of the Army (E10). Stored in Isar as the
/// enum index, so values must only ever be APPENDED — never reordered.
enum MilitaryRank {
  private_e1,
  privateFc_e2,
  corporal_e3,
  specialist_e4,
  sergeant_e5,
  staffSergeant_e6,
  sergeantFc_e7,
  masterSergeant_e8,
  sergeantMajor_e9,
  sgmArmy_e10,
}

/// Static, UI-facing metadata for a rank. [minimumScore] is on the composite
/// **rank-points** scale (0–9), where each whole number is one rank — Private
/// is 0, SMA is 9 — so a composite score simply floors to its rank.
class RankInfo {
  const RankInfo({
    required this.name,
    required this.abbreviation,
    required this.chevronCount,
    required this.minimumScore,
    required this.color,
    this.hasEagle = false,
    this.hasStar = false,
  });

  final String name;
  final String abbreviation;
  final int chevronCount;
  final double minimumScore;
  final Color color;

  /// Insignia hints for the Phase-2 badge renderer.
  final bool hasEagle;
  final bool hasStar;
}

const Map<MilitaryRank, RankInfo> _rankInfo = {
  MilitaryRank.private_e1: RankInfo(
    name: 'Private',
    abbreviation: 'PVT',
    chevronCount: 1,
    minimumScore: 0,
    color: Color(0xFF8E8E93), // gray
  ),
  MilitaryRank.privateFc_e2: RankInfo(
    name: 'Private First Class',
    abbreviation: 'PFC',
    chevronCount: 2,
    minimumScore: 1,
    color: Color(0xFF7C8A5C), // olive green
  ),
  MilitaryRank.corporal_e3: RankInfo(
    name: 'Corporal',
    abbreviation: 'CPL',
    chevronCount: 3,
    minimumScore: 2,
    color: Color(0xFF30D158), // green
  ),
  MilitaryRank.specialist_e4: RankInfo(
    name: 'Specialist',
    abbreviation: 'SPC',
    chevronCount: 0,
    minimumScore: 3,
    color: Color(0xFF5AC8FA), // teal / cyan
    hasEagle: true, // specialist "eagle" / shield badge
  ),
  MilitaryRank.sergeant_e5: RankInfo(
    name: 'Sergeant',
    abbreviation: 'SGT',
    chevronCount: 3,
    minimumScore: 4,
    color: Color(0xFF0A84FF), // blue
  ),
  MilitaryRank.staffSergeant_e6: RankInfo(
    name: 'Staff Sergeant',
    abbreviation: 'SSG',
    chevronCount: 4,
    minimumScore: 5,
    color: Color(0xFF5856D6), // indigo
  ),
  MilitaryRank.sergeantFc_e7: RankInfo(
    name: 'Sergeant First Class',
    abbreviation: 'SFC',
    chevronCount: 5,
    minimumScore: 6,
    color: Color(0xFFAF52DE), // purple
  ),
  MilitaryRank.masterSergeant_e8: RankInfo(
    name: 'Master Sergeant',
    abbreviation: 'MSG',
    chevronCount: 6,
    minimumScore: 7,
    color: Color(0xFFFFD60A), // yellow / gold
  ),
  MilitaryRank.sergeantMajor_e9: RankInfo(
    name: 'Sergeant Major',
    abbreviation: 'SGM',
    chevronCount: 3,
    minimumScore: 8,
    color: Color(0xFFFF9F0A), // amber / gold
    hasStar: true, // 3 chevrons + 3 rockers + star
  ),
  MilitaryRank.sgmArmy_e10: RankInfo(
    name: 'Sergeant Major of the Army',
    abbreviation: 'SMA',
    chevronCount: 3,
    minimumScore: 9,
    color: Color(0xFFFF453A), // crimson — the apex
    hasStar: true,
    hasEagle: true, // eagle + stars + chevrons
  ),
};

extension MilitaryRankX on MilitaryRank {
  RankInfo get info => _rankInfo[this]!;
  String get displayName => info.name;
  String get abbreviation => info.abbreviation;
  int get chevronCount => info.chevronCount;
  double get minimumScore => info.minimumScore;
  Color get color => info.color;
  bool get hasEagle => info.hasEagle;
  bool get hasStar => info.hasStar;

  /// Pay-grade tier, 1–10 (E1…E10). Purely for display.
  int get tier => index + 1;
}

/// Clamps an arbitrary integer to a valid [MilitaryRank].
MilitaryRank rankFromIndex(int index) =>
    MilitaryRank.values[index.clamp(0, MilitaryRank.values.length - 1)];

/// Discrete rank index (0–9) for an allometric [score] against a 10-entry
/// [thresholds] list. `thresholds[i]` is the minimum score to hold rank `i`;
/// anything below `thresholds[0]` stays Private (0). Equivalent to "how many
/// thresholds, counting up from the bottom, has this score cleared".
int rankIndexForScore(double score, List<double> thresholds) {
  assert(thresholds.length == MilitaryRank.values.length,
      'each exercise needs exactly 10 rank thresholds');
  var rank = 0;
  for (var i = 0; i < thresholds.length; i++) {
    if (score >= thresholds[i]) {
      rank = i;
    } else {
      break;
    }
  }
  return rank;
}

/// Continuous rank "points" (0–9) for [score] — the discrete rank plus the
/// fractional progress toward the next one. Used when AVERAGING across
/// exercises / muscle groups so a lifter halfway to the next rank contributes
/// proportionally instead of snapping. `thresholds[i]` maps to exactly `i.0`.
double rankPointsForScore(double score, List<double> thresholds) {
  final last = thresholds.length - 1;
  if (score <= thresholds.first) return 0;
  if (score >= thresholds[last]) return last.toDouble();
  for (var i = 0; i < last; i++) {
    final lo = thresholds[i];
    final hi = thresholds[i + 1];
    if (score < hi) {
      final span = hi - lo;
      final frac = span <= 0 ? 0.0 : (score - lo) / span;
      return i + frac;
    }
  }
  return last.toDouble();
}

/// Maps composite rank-points (0–9) to a [MilitaryRank] by flooring.
MilitaryRank rankFromPoints(double points) =>
    rankFromIndex(points.floor());

/// Heat-map colour for a muscle group's rank: the rank's own distinct insignia
/// colour (so each rank reads clearly apart on the body, matching the rank
/// ladder), or a dim neutral when the group is unranked (null).
Color heatColorForRank(MilitaryRank? rank) =>
    rank?.color ?? const Color(0xFF3A3A3C);
