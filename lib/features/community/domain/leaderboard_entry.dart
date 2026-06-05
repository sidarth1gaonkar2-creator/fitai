import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore field name for a leaderboard segment's rank score. The leaderboard
/// query sorts by one of these directly (`orderBy(field, descending: true)`),
/// so every entry doc must carry all six fields. Keys are stable — used by the
/// repository, the screen segments, and the seeder.
class LeaderboardSegments {
  const LeaderboardSegments._();

  static const overall = 'scoreOverall';
  static const chest = 'scoreChest';
  static const back = 'scoreBack';
  static const legs = 'scoreLegs';
  static const shoulders = 'scoreShoulders';
  static const arms = 'scoreArms';

  /// Default sort field — the composite overall rank score.
  static const defaultField = overall;
}

/// One row on the strength leaderboard. The leaderboard is ranked by military
/// rank score (composite or per-muscle-group), with the lifter's big-3 best
/// lifts and legacy activity stats kept as secondary info.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.rankIndex = 0,
    this.scoreOverall = 0,
    this.scoreChest = 0,
    this.scoreBack = 0,
    this.scoreLegs = 0,
    this.scoreShoulders = 0,
    this.scoreArms = 0,
    this.benchKg = 0,
    this.squatKg = 0,
    this.deadliftKg = 0,
    this.currentStreak = 0,
    this.totalWorkouts = 0,
    this.totalVolume = 0,
    this.updatedAt,
  });

  final String userId;
  final String username;
  final String? avatarUrl;

  /// Overall [MilitaryRank] ordinal (0–9), floored from [scoreOverall] points.
  final int rankIndex;

  /// Composite rank points (0–9). Per-group rank points are the same scale.
  final double scoreOverall;
  final double scoreChest;
  final double scoreBack;
  final double scoreLegs;
  final double scoreShoulders;
  final double scoreArms;

  /// Best big-3 lifts in kg (storage unit) — the secondary stat line.
  final double benchKg;
  final double squatKg;
  final double deadliftKg;

  // Legacy activity stats — kept for the friends sort + de-emphasised secondary
  // info, no longer the leaderboard's primary ranking metric.
  final int currentStreak;
  final int totalWorkouts;
  final double totalVolume;
  final DateTime? updatedAt;

  /// Rank points for a given segment field (see [LeaderboardSegments]).
  double scoreForField(String field) => switch (field) {
        LeaderboardSegments.overall => scoreOverall,
        LeaderboardSegments.chest => scoreChest,
        LeaderboardSegments.back => scoreBack,
        LeaderboardSegments.legs => scoreLegs,
        LeaderboardSegments.shoulders => scoreShoulders,
        LeaderboardSegments.arms => scoreArms,
        _ => scoreOverall,
      };

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    double d(String key) => (map[key] as num?)?.toDouble() ?? 0;
    return LeaderboardEntry(
      userId: map['userId'] as String? ?? '',
      username: map['username'] as String? ?? '',
      avatarUrl: (map['avatarUrl'] ?? map['profilePictureUrl']) as String?,
      rankIndex: (map['rankIndex'] as num?)?.toInt() ?? 0,
      scoreOverall: d(LeaderboardSegments.overall),
      scoreChest: d(LeaderboardSegments.chest),
      scoreBack: d(LeaderboardSegments.back),
      scoreLegs: d(LeaderboardSegments.legs),
      scoreShoulders: d(LeaderboardSegments.shoulders),
      scoreArms: d(LeaderboardSegments.arms),
      benchKg: d('benchKg'),
      squatKg: d('squatKg'),
      deadliftKg: d('deadliftKg'),
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      totalWorkouts: (map['totalWorkouts'] as num?)?.toInt() ??
          (map['weeklyWorkouts'] as num?)?.toInt() ??
          0,
      totalVolume: (map['totalVolume'] as num?)?.toDouble() ??
          (map['weeklyVolume'] as num?)?.toDouble() ??
          0,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'avatarUrl': avatarUrl,
      'rankIndex': rankIndex,
      LeaderboardSegments.overall: scoreOverall,
      LeaderboardSegments.chest: scoreChest,
      LeaderboardSegments.back: scoreBack,
      LeaderboardSegments.legs: scoreLegs,
      LeaderboardSegments.shoulders: scoreShoulders,
      LeaderboardSegments.arms: scoreArms,
      'benchKg': benchKg,
      'squatKg': squatKg,
      'deadliftKg': deadliftKg,
      'currentStreak': currentStreak,
      'totalWorkouts': totalWorkouts,
      'totalVolume': totalVolume,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
