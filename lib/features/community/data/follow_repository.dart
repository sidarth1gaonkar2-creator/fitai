import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/firestore_provider.dart';
import 'notification_repository.dart';
import 'user_repository.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository(
    firestore: ref.watch(firestoreProvider),
    notifications: ref.watch(notificationRepositoryProvider),
    users: ref.watch(userRepositoryProvider),
  );
});

class FollowRepository {
  FollowRepository({
    required FirebaseFirestore firestore,
    required NotificationRepository notifications,
    required UserRepository users,
  })  : _firestore = firestore,
        _notifications = notifications,
        _users = users;

  final FirebaseFirestore _firestore;
  final NotificationRepository _notifications;
  final UserRepository _users;

  CollectionReference<Map<String, dynamic>> get _follows =>
      _firestore.collection('follows');
  CollectionReference<Map<String, dynamic>> get _userDocs =>
      _firestore.collection('users');

  String _docId(String followerId, String followingId) =>
      '${followerId}_$followingId';

  Future<void> follow(String followerId, String followingId) async {
    final batch = _firestore.batch();
    batch.set(_follows.doc(_docId(followerId, followingId)), {
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_userDocs.doc(followerId), {
      'followingCount': FieldValue.increment(1),
    });
    batch.update(_userDocs.doc(followingId), {
      'followersCount': FieldValue.increment(1),
    });
    await batch.commit();

    // Notify the followed user.
    final me = await _users.getUser(followerId);
    await _notifications.send(
      toUserId: followingId,
      type: 'follow',
      fromUserId: followerId,
      fromUsername: me?.username ?? 'Someone',
      fromUserAvatar: me?.profilePictureUrl,
      message: '${me?.username ?? 'Someone'} started following you',
    );
  }

  Future<void> unfollow(String followerId, String followingId) async {
    final batch = _firestore.batch();
    batch.delete(_follows.doc(_docId(followerId, followingId)));
    batch.update(_userDocs.doc(followerId), {
      'followingCount': FieldValue.increment(-1),
    });
    batch.update(_userDocs.doc(followingId), {
      'followersCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  Future<bool> isFollowing(String followerId, String followingId) async {
    final doc =
        await _follows.doc(_docId(followerId, followingId)).get();
    return doc.exists;
  }

  Future<Set<String>> getFollowingIds(String userId) async {
    final snap =
        await _follows.where('followerId', isEqualTo: userId).get();
    return snap.docs
        .map((d) => d.data()['followingId'] as String)
        .toSet();
  }

  Future<List<String>> getFollowerIds(String userId) async {
    final snap =
        await _follows.where('followingId', isEqualTo: userId).get();
    return snap.docs
        .map((d) => d.data()['followerId'] as String)
        .toList();
  }
}
