import 'package:cloud_firestore/cloud_firestore.dart';

/// How the app verifies that a participant has met a challenge's daily
/// goal. Stored as the string name of the enum value in Firestore — keep
/// the names stable.
enum ChallengeTrackingMode {
  /// User self-reports (photo, manual tap). The pre-existing behaviour for
  /// every existing challenge in Firestore.
  manual,

  /// Auto-import daily steps from HealthKit. Goal expressed in steps.
  autoSteps,

  /// Auto-import daily active calories burned. Goal expressed in kcal.
  autoCalories,

  /// Auto-detect any workout logged in Isar today. Goal: 1 workout.
  autoWorkouts,

  /// Auto-import water intake from the local tracker (NOT HealthKit — water
  /// has different units in HK and the local store is the source of truth).
  /// Goal expressed in millilitres.
  autoWater,
}

ChallengeTrackingMode _parseTrackingMode(String? raw) {
  for (final m in ChallengeTrackingMode.values) {
    if (m.name == raw) return m;
  }
  return ChallengeTrackingMode.manual;
}

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
    this.trackingMode = ChallengeTrackingMode.manual,
    this.dailyGoalValue,
    this.goalUnit,
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

  /// How the challenge tracks daily progress (manual photo proof vs. an
  /// automated HealthKit/Isar reading). Defaults to [ChallengeTrackingMode.manual]
  /// so existing Firestore docs without this field continue to work.
  final ChallengeTrackingMode trackingMode;

  /// Target value per day. Interpreted via [goalUnit]. Only set when
  /// [trackingMode] is one of the auto modes.
  final double? dailyGoalValue;

  /// Unit string for [dailyGoalValue]: 'steps', 'kcal', 'ml', 'workouts'.
  final String? goalUnit;

  bool get isAutoTracked => trackingMode != ChallengeTrackingMode.manual;

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
      trackingMode: _parseTrackingMode(map['trackingMode'] as String?),
      dailyGoalValue: (map['dailyGoalValue'] as num?)?.toDouble(),
      goalUnit: map['goalUnit'] as String?,
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
      'trackingMode': trackingMode.name,
      if (dailyGoalValue != null) 'dailyGoalValue': dailyGoalValue,
      if (goalUnit != null) 'goalUnit': goalUnit,
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
