import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.currentStreak = 0,
    this.totalWorkouts = 0,
    this.totalVolume = 0,
    this.updatedAt,
  });

  final String userId;
  final String username;
  final String? avatarUrl;
  final int currentStreak;
  final int totalWorkouts;
  final double totalVolume;
  final DateTime? updatedAt;

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['userId'] as String? ?? '',
      username: map['username'] as String? ?? '',
      avatarUrl:
          (map['avatarUrl'] ?? map['profilePictureUrl']) as String?,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      totalWorkouts:
          (map['totalWorkouts'] as num?)?.toInt() ??
              (map['weeklyWorkouts'] as num?)?.toInt() ??
              0,
      totalVolume:
          (map['totalVolume'] as num?)?.toDouble() ??
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
      'currentStreak': currentStreak,
      'totalWorkouts': totalWorkouts,
      'totalVolume': totalVolume,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
