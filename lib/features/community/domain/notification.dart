import 'package:cloud_firestore/cloud_firestore.dart';

/// A social notification shown to the user (follow / like / comment / challenge).
///
/// Stored at /users/{userId}/notifications/{notifId}.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.fromUserId,
    required this.fromUsername,
    this.fromUserAvatar,
    required this.message,
    this.postId,
    this.challengeId,
    this.isRead = false,
    this.createdAt,
  });

  final String id;

  /// 'follow' | 'like' | 'comment' | 'challenge_join'
  final String type;
  final String fromUserId;
  final String fromUsername;
  final String? fromUserAvatar;
  final String message;
  final String? postId;
  final String? challengeId;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      type: map['type'] as String? ?? '',
      fromUserId: map['fromUserId'] as String? ?? '',
      fromUsername: map['fromUsername'] as String? ?? '',
      fromUserAvatar: map['fromUserAvatar'] as String?,
      message: map['message'] as String? ?? '',
      postId: map['postId'] as String?,
      challengeId: map['challengeId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'fromUserId': fromUserId,
      'fromUsername': fromUsername,
      'fromUserAvatar': fromUserAvatar,
      'message': message,
      if (postId != null) 'postId': postId,
      if (challengeId != null) 'challengeId': challengeId,
      'isRead': isRead,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
