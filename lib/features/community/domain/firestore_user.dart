import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreUser {
  const FirestoreUser({
    required this.userId,
    required this.username,
    required this.displayName,
    this.bio = '',
    this.profilePictureUrl,
    this.isPublic = true,
    this.followersCount = 0,
    this.followingCount = 0,
    this.workoutsCount = 0,
    this.createdAt,
    this.rankIndex,
    this.rankName,
  });

  final String userId;
  final String username;
  final String displayName;
  final String bio;
  final String? profilePictureUrl;
  final bool isPublic;
  final int followersCount;
  final int followingCount;
  final int workoutsCount;
  final DateTime? createdAt;

  /// Overall [MilitaryRank] ordinal, mirrored from the local rank engine so the
  /// community can show this user's rank badge. Null until first computed.
  final int? rankIndex;

  /// Display name of the overall rank (e.g. "Corporal"), for convenience.
  final String? rankName;

  factory FirestoreUser.fromMap(Map<String, dynamic> map) {
    return FirestoreUser(
      userId: map['userId'] as String? ?? '',
      username: map['username'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      profilePictureUrl: map['profilePictureUrl'] as String?,
      isPublic: map['isPublic'] as bool? ?? true,
      followersCount: (map['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (map['followingCount'] as num?)?.toInt() ?? 0,
      workoutsCount: (map['workoutsCount'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      rankIndex: (map['rankIndex'] as num?)?.toInt(),
      rankName: map['rankName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'bio': bio,
      'profilePictureUrl': profilePictureUrl,
      'isPublic': isPublic,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'workoutsCount': workoutsCount,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (rankIndex != null) 'rankIndex': rankIndex,
      if (rankName != null) 'rankName': rankName,
    };
  }

  FirestoreUser copyWith({
    String? username,
    String? displayName,
    String? bio,
    String? profilePictureUrl,
    bool? isPublic,
    int? followersCount,
    int? followingCount,
    int? workoutsCount,
    int? rankIndex,
    String? rankName,
  }) {
    return FirestoreUser(
      userId: userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isPublic: isPublic ?? this.isPublic,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      workoutsCount: workoutsCount ?? this.workoutsCount,
      createdAt: createdAt,
      rankIndex: rankIndex ?? this.rankIndex,
      rankName: rankName ?? this.rankName,
    );
  }
}
