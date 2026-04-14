import 'package:cloud_firestore/cloud_firestore.dart';

class Challenge {
  const Challenge({
    required this.challengeId,
    required this.title,
    this.description = '',
    required this.creatorId,
    required this.creatorUsername,
    required this.type,
    required this.target,
    required this.durationDays,
    this.startDate,
    this.endDate,
    this.participantCount = 0,
    this.isPublic = true,
    this.createdAt,
  });

  final String challengeId;
  final String title;
  final String description;
  final String creatorId;
  final String creatorUsername;
  final String type; // 'streak', 'volume', 'workouts'
  final double target;
  final int durationDays;
  final DateTime? startDate;
  final DateTime? endDate;
  final int participantCount;
  final bool isPublic;
  final DateTime? createdAt;

  bool get isActive {
    if (endDate == null) return true;
    return DateTime.now().isBefore(endDate!);
  }

  String get typeLabel => switch (type) {
        'streak' => 'Streak',
        'volume' => 'Volume (kg)',
        'workouts' => 'Workouts',
        _ => type,
      };

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      challengeId: map['challengeId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      creatorId: map['creatorId'] as String? ?? '',
      creatorUsername: map['creatorUsername'] as String? ?? '',
      type: map['type'] as String? ?? 'workouts',
      target: (map['target'] as num?)?.toDouble() ?? 0,
      durationDays: (map['durationDays'] as num?)?.toInt() ?? 7,
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      participantCount: (map['participantCount'] as num?)?.toInt() ?? 0,
      isPublic: map['isPublic'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'creatorUsername': creatorUsername,
      'type': type,
      'target': target,
      'durationDays': durationDays,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'participantCount': participantCount,
      'isPublic': isPublic,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

class ChallengeParticipant {
  const ChallengeParticipant({
    required this.challengeId,
    required this.userId,
    required this.username,
    this.profilePictureUrl,
    this.progress = 0,
    this.completed = false,
    this.joinedAt,
  });

  final String challengeId;
  final String userId;
  final String username;
  final String? profilePictureUrl;
  final double progress;
  final bool completed;
  final DateTime? joinedAt;

  factory ChallengeParticipant.fromMap(Map<String, dynamic> map) {
    return ChallengeParticipant(
      challengeId: map['challengeId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      username: map['username'] as String? ?? '',
      profilePictureUrl: map['profilePictureUrl'] as String?,
      progress: (map['progress'] as num?)?.toDouble() ?? 0,
      completed: map['completed'] as bool? ?? false,
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'userId': userId,
      'username': username,
      'profilePictureUrl': profilePictureUrl,
      'progress': progress,
      'completed': completed,
      'joinedAt': joinedAt != null
          ? Timestamp.fromDate(joinedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
