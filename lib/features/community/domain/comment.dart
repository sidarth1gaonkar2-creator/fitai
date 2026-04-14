import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  const Comment({
    required this.commentId,
    required this.userId,
    required this.username,
    this.userProfilePic,
    required this.text,
    this.createdAt,
  });

  final String commentId;
  final String userId;
  final String username;
  final String? userProfilePic;
  final String text;
  final DateTime? createdAt;

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      commentId: map['commentId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      username: map['username'] as String? ?? '',
      userProfilePic: map['userProfilePic'] as String?,
      text: map['text'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'userId': userId,
      'username': username,
      'userProfilePic': userProfilePic,
      'text': text,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
