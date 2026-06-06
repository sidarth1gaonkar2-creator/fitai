import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  Post({
    required this.postId,
    required this.userId,
    required this.username,
    this.userProfilePic,
    required this.workoutName,
    required this.duration,
    this.exercises = const [],
    this.totalSets = 0,
    this.totalVolume = 0,
    this.caption = '',
    this.isPublic = true,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.createdAt,
    this.allowedUsers,
    this.workoutId,
    this.rankIndex,
    this.rankName,
  });

  final String postId;
  final String userId;
  final String username;
  final String? userProfilePic;
  final String workoutName;
  final int duration;
  final List<PostExercise> exercises;
  final int totalSets;
  final double totalVolume;
  final String caption;
  final bool isPublic;
  final int likesCount;
  final int commentsCount;
  final DateTime? createdAt;
  final List<String>? allowedUsers;

  /// Local Isar workout ID that this post was generated from (optional).
  final int? workoutId;

  /// Author's overall [MilitaryRank] ordinal at post time, embedded so the feed
  /// can render the rank badge without a separate user-doc lookup. Null on
  /// legacy posts — the card falls back to the author's user doc, then Private.
  final int? rankIndex;

  /// Author's overall rank name at post time (e.g. "Corporal").
  final String? rankName;

  /// Firestore document snapshot for pagination cursor.
  DocumentSnapshot? documentSnapshot;

  factory Post.fromMap(Map<String, dynamic> map, {DocumentSnapshot? doc}) {
    final exercises = (map['exercises'] as List<dynamic>?)
            ?.map((e) => PostExercise.fromMap(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final post = Post(
      postId: map['postId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      username: map['username'] as String? ?? '',
      userProfilePic: map['userProfilePic'] as String?,
      workoutName: map['workoutName'] as String? ?? '',
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      exercises: exercises,
      totalSets: (map['totalSets'] as num?)?.toInt() ?? 0,
      totalVolume: (map['totalVolume'] as num?)?.toDouble() ?? 0,
      caption: map['caption'] as String? ?? '',
      isPublic: map['isPublic'] as bool? ?? true,
      likesCount: (map['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (map['commentsCount'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      allowedUsers: (map['allowedUsers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      workoutId: (map['workoutId'] as num?)?.toInt(),
      rankIndex: (map['rankIndex'] as num?)?.toInt(),
      rankName: map['rankName'] as String?,
    );
    post.documentSnapshot = doc;
    return post;
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'username': username,
      'userProfilePic': userProfilePic,
      'workoutName': workoutName,
      'duration': duration,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'totalSets': totalSets,
      'totalVolume': totalVolume,
      'caption': caption,
      'isPublic': isPublic,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'allowedUsers': allowedUsers ?? [],
      if (workoutId != null) 'workoutId': workoutId,
      if (rankIndex != null) 'rankIndex': rankIndex,
      if (rankName != null) 'rankName': rankName,
    };
  }
}

class PostExercise {
  const PostExercise({
    required this.name,
    this.sets = 0,
    this.bestWeight = 0,
  });

  final String name;
  final int sets;
  final double bestWeight;

  factory PostExercise.fromMap(Map<String, dynamic> map) {
    return PostExercise(
      name: map['name'] as String? ?? '',
      sets: (map['sets'] as num?)?.toInt() ?? 0,
      bestWeight: (map['bestWeight'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'sets': sets,
        'bestWeight': bestWeight,
      };
}
