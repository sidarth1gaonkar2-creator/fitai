import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../providers/firestore_provider.dart';
import '../domain/comment.dart';
import '../domain/post.dart';
import 'notification_repository.dart';
import 'user_repository.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(
    firestore: ref.watch(firestoreProvider),
    notifications: ref.watch(notificationRepositoryProvider),
    users: ref.watch(userRepositoryProvider),
  );
});

class PostRepository {
  PostRepository({
    required FirebaseFirestore firestore,
    required NotificationRepository notifications,
    required UserRepository users,
  })  : _firestore = firestore,
        _notifications = notifications,
        _users = users;

  final FirebaseFirestore _firestore;
  final NotificationRepository _notifications;
  final UserRepository _users;
  static const _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  Future<void> createPost(Post post) async {
    final id = post.postId.isEmpty ? _uuid.v4() : post.postId;
    final data = post.toMap();
    data['postId'] = id;
    await _posts.doc(id).set(data);
  }

  Future<void> deletePost(String postId) async {
    await _posts.doc(postId).delete();
  }

  /// Fetch feed posts from followed users + own posts, paginated.
  Future<(List<Post>, DocumentSnapshot?)> getFeedPosts({
    required String userId,
    required Set<String> followingIds,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    final allIds = {...followingIds, userId};
    final idList = allIds.toList();

    final batches = <List<String>>[];
    for (var i = 0; i < idList.length; i += 30) {
      batches.add(idList.sublist(i, (i + 30).clamp(0, idList.length)));
    }

    final allDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final batch in batches) {
      Query<Map<String, dynamic>> q = _posts
          .where('userId', whereIn: batch)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      if (startAfter != null) q = q.startAfterDocument(startAfter);
      final snap = await q.get();
      allDocs.addAll(snap.docs);
    }

    allDocs.sort((a, b) {
      final aTime =
          (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      final bTime =
          (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    final limited = allDocs.take(limit).toList();
    final posts =
        limited.map((d) => Post.fromMap(d.data(), doc: d)).toList();
    final lastDoc = limited.isNotEmpty ? limited.last : null;
    return (posts, lastDoc);
  }

  Future<List<Post>> getUserPosts(String userId) async {
    final snap = await _posts
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snap.docs.map((d) => Post.fromMap(d.data(), doc: d)).toList();
  }

  Future<Post?> getPost(String postId) async {
    final doc = await _posts.doc(postId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Post.fromMap(doc.data()!, doc: doc);
  }

  Future<bool> toggleLike(String postId, String userId) async {
    final likeRef = _posts.doc(postId).collection('likes').doc(userId);
    final doc = await likeRef.get();
    if (doc.exists) {
      await likeRef.delete();
      await _posts.doc(postId).update({
        'likesCount': FieldValue.increment(-1),
      });
      return false;
    }
    await likeRef.set({
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _posts.doc(postId).update({
      'likesCount': FieldValue.increment(1),
    });

    // Notify post owner.
    final post = await getPost(postId);
    if (post != null) {
      final me = await _users.getUser(userId);
      await _notifications.send(
        toUserId: post.userId,
        type: 'like',
        fromUserId: userId,
        fromUsername: me?.username ?? 'Someone',
        fromUserAvatar: me?.profilePictureUrl,
        message: '${me?.username ?? 'Someone'} liked your post',
        postId: postId,
      );
    }
    return true;
  }

  Future<bool> isLiked(String postId, String userId) async {
    final doc =
        await _posts.doc(postId).collection('likes').doc(userId).get();
    return doc.exists;
  }

  Future<void> addComment(String postId, Comment comment) async {
    final id = comment.commentId.isEmpty ? _uuid.v4() : comment.commentId;
    final data = comment.toMap();
    data['commentId'] = id;
    await _posts.doc(postId).collection('comments').doc(id).set(data);
    await _posts.doc(postId).update({
      'commentsCount': FieldValue.increment(1),
    });

    // Notify post owner.
    final post = await getPost(postId);
    if (post != null) {
      final preview = comment.text.length > 80
          ? '${comment.text.substring(0, 80)}…'
          : comment.text;
      await _notifications.send(
        toUserId: post.userId,
        type: 'comment',
        fromUserId: comment.userId,
        fromUsername: comment.username,
        fromUserAvatar: comment.userProfilePic,
        message: '${comment.username} commented: "$preview"',
        postId: postId,
      );
    }
  }

  Future<List<Comment>> getComments(String postId) async {
    final snap = await _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .get();
    return snap.docs.map((d) => Comment.fromMap(d.data())).toList();
  }
}
