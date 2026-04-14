import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.profilePictureUrl,
    this.weeklyVolume = 0,
    this.weeklyWorkouts = 0,
    this.currentStreak = 0,
    this.updatedAt,
  });

  final String userId;
  final String username;
  final String? profilePictureUrl;
  final double weeklyVolume;
  final int weeklyWorkouts;
  final int currentStreak;
  final DateTime? updatedAt;

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['userId'] as String? ?? '',
      username: map['username'] as String? ?? '',
      profilePictureUrl: map['profilePictureUrl'] as String?,
      weeklyVolume: (map['weeklyVolume'] as num?)?.toDouble() ?? 0,
      weeklyWorkouts: (map['weeklyWorkouts'] as num?)?.toInt() ?? 0,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'profilePictureUrl': profilePictureUrl,
      'weeklyVolume': weeklyVolume,
      'weeklyWorkouts': weeklyWorkouts,
      'currentStreak': currentStreak,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
