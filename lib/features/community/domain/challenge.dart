import 'package:cloud_firestore/cloud_firestore.dart';

/// A user or system-created challenge.
class Challenge {
  const Challenge({
    required this.challengeId,
    required this.title,
    this.description = '',
    required this.creatorId,
    required this.creatorUsername,
    this.type = 'habit',
    required this.durationDays,
    this.startDate,
    this.endDate,
    this.participantCount = 0,
    this.isPublic = true,
    this.requiresPhotoProof = false,
    this.proofInstructions,
    this.category,
    this.icon,
    this.difficulty,
    this.createdAt,
  });

  final String challengeId;
  final String title;
  final String description;
  final String creatorId;
  final String creatorUsername;

  /// 'workout' | 'nutrition' | 'habit'
  final String type;
  final int durationDays;
  final DateTime? startDate;
  final DateTime? endDate;
  final int participantCount;
  final bool isPublic;
  final bool requiresPhotoProof;
  final String? proofInstructions;
  final String? category;
  final String? icon;
  final String? difficulty;
  final DateTime? createdAt;

  bool get isActive {
    if (endDate == null) return true;
    return DateTime.now().isBefore(endDate!);
  }

  String get typeLabel => switch (type) {
        'workout' => 'Workout',
        'nutrition' => 'Nutrition',
        'habit' => 'Habit',
        _ => type.isEmpty ? 'Habit' : type[0].toUpperCase() + type.substring(1),
      };

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      challengeId: map['challengeId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      creatorId: map['creatorId'] as String? ?? '',
      creatorUsername: map['creatorUsername'] as String? ?? '',
      type: map['type'] as String? ?? 'habit',
      durationDays: (map['durationDays'] as num?)?.toInt() ?? 7,
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      participantCount: (map['participantCount'] as num?)?.toInt() ?? 0,
      isPublic: map['isPublic'] as bool? ?? true,
      requiresPhotoProof: map['requiresPhotoProof'] as bool? ?? false,
      proofInstructions: map['proofInstructions'] as String?,
      category: map['category'] as String?,
      icon: map['icon'] as String?,
      difficulty: map['difficulty'] as String?,
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
      'durationDays': durationDays,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'participantCount': participantCount,
      'isPublic': isPublic,
      'requiresPhotoProof': requiresPhotoProof,
      if (proofInstructions != null) 'proofInstructions': proofInstructions,
      if (category != null) 'category': category,
      if (icon != null) 'icon': icon,
      if (difficulty != null) 'difficulty': difficulty,
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
    this.joinedAt,
    this.completedDays = 0,
    this.currentStreak = 0,
    this.proofPhotos = const [],
    this.isCompleted = false,
    this.lastCheckInDate,
  });

  final String challengeId;
  final String userId;
  final String username;
  final String? profilePictureUrl;
  final DateTime? joinedAt;
  final int completedDays;
  final int currentStreak;
  final List<String> proofPhotos;
  final bool isCompleted;
  final DateTime? lastCheckInDate;

  factory ChallengeParticipant.fromMap(Map<String, dynamic> map) {
    return ChallengeParticipant(
      challengeId: map['challengeId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      username: map['username'] as String? ?? '',
      profilePictureUrl: map['profilePictureUrl'] as String?,
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate(),
      completedDays: (map['completedDays'] as num?)?.toInt() ??
          (map['progress'] as num?)?.toInt() ??
          0,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      proofPhotos: (map['proofPhotos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isCompleted: map['isCompleted'] as bool? ?? false,
      lastCheckInDate:
          (map['lastCheckInDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'userId': userId,
      'username': username,
      'profilePictureUrl': profilePictureUrl,
      'joinedAt': joinedAt != null
          ? Timestamp.fromDate(joinedAt!)
          : FieldValue.serverTimestamp(),
      'completedDays': completedDays,
      'currentStreak': currentStreak,
      'proofPhotos': proofPhotos,
      'isCompleted': isCompleted,
      'lastCheckInDate': lastCheckInDate != null
          ? Timestamp.fromDate(lastCheckInDate!)
          : null,
    };
  }
}
