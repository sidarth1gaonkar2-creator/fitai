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

  /// Global public feed — every public post, newest first, paginated. Replaces
  /// the old follow-graph feed so a brand-new user (and the App Store reviewer)
  /// sees content immediately. Relies on the `isPublic + createdAt` composite
  /// index (firestore.indexes.json). Blocked authors and locally-reported posts
  /// are filtered CLIENT-SIDE by the caller (Firestore can't combine a not-in
  /// with the isPublic equality + orderBy in one query), so the returned list
  /// may shrink after filtering while [DocumentSnapshot] still paginates the raw
  /// query correctly.
  Future<(List<Post>, DocumentSnapshot?)> getPublicFeed({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> q = _posts
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    final snap = await q.get();
    final docs = snap.docs;
    final posts = docs.map((d) => Post.fromMap(d.data(), doc: d)).toList();
    final lastDoc = docs.isNotEmpty ? docs.last : null;
    return (posts, lastDoc);
  }

  /// Files a moderation report against a post (Guideline 1.2). Write-only by
  /// rule — the client can create but never read the `reports` collection.
  Future<void> reportPost({
    required String postId,
    required String reportedUserId,
    required String reporterId,
    String reason = 'unspecified',
  }) async {
    await _firestore.collection('reports').add({
      'postId': postId,
      'reportedUserId': reportedUserId,
      'reporterId': reporterId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Posts authored by [userId], newest first.
  ///
  /// Pass [publicOnly] when the viewer is NOT the author: it adds a
  /// `where('isPublic', isEqualTo: true)` clause so the query satisfies the
  /// posts read rule's `isPublic == true` clause. Without it, a non-self
  /// `userId ==` filter can't satisfy the rule and Firestore denies the whole
  /// query ("rules are not filters"). Viewing your OWN profile leaves it
  /// unfiltered — the rule permits `userId == you` regardless of visibility,
  /// so you still see your private posts.
  ///
  /// NOTE: the [publicOnly] path needs the composite index
  /// (userId ASC, isPublic ASC, createdAt DESC) — it must be Enabled in
  /// Firestore or the query fails with FAILED_PRECONDITION.
  Future<List<Post>> getUserPosts(String userId,
      {bool publicOnly = false}) async {
    Query<Map<String, dynamic>> q =
        _posts.where('userId', isEqualTo: userId);
    if (publicOnly) {
      q = q.where('isPublic', isEqualTo: true);
    }
    final snap =
        await q.orderBy('createdAt', descending: true).limit(50).get();
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

  // ── Emoji reactions ────────────────────────────────────────────────
  //
  // Stored at posts/{postId}/reactions/{userId} with fields:
  //   emoji     String (the picked emoji glyph)
  //   timestamp serverTimestamp
  //
  // Each user has at most one reaction per post; re-tapping the same emoji
  // removes it (toggle), tapping a different emoji replaces it.

  /// Sets a user's reaction. Pass `null` to clear. Returns the final emoji
  /// (or null if cleared) for convenience.
  Future<String?> setReaction(
    String postId,
    String userId,
    String? emoji,
  ) async {
    final ref =
        _posts.doc(postId).collection('reactions').doc(userId);
    final existing = await ref.get();
    final prevEmoji =
        existing.exists ? (existing.data()?['emoji'] as String?) : null;

    if (emoji == null || emoji == prevEmoji) {
      // Toggle off — same emoji tapped again or explicit clear.
      if (existing.exists) await ref.delete();
      return null;
    }
    await ref.set({
      'userId': userId,
      'emoji': emoji,
      'timestamp': FieldValue.serverTimestamp(),
    });
    return emoji;
  }

  /// Current user's reaction emoji, or null if none.
  Future<String?> getUserReaction(String postId, String userId) async {
    final doc =
        await _posts.doc(postId).collection('reactions').doc(userId).get();
    if (!doc.exists) return null;
    return doc.data()?['emoji'] as String?;
  }

  /// Aggregated reaction counts for a post — emoji → count. Falls back to
  /// an empty map if the subcollection is empty or unreadable. Caller
  /// typically caches this in a FutureProvider to avoid re-fetching per
  /// scroll frame.
  Future<Map<String, int>> getReactionCounts(String postId) async {
    final snap =
        await _posts.doc(postId).collection('reactions').get();
    final counts = <String, int>{};
    for (final d in snap.docs) {
      final emoji = d.data()['emoji'] as String?;
      if (emoji == null || emoji.isEmpty) continue;
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    return counts;
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
