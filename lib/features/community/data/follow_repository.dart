import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/firestore_provider.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository(ref.watch(firestoreProvider));
});

class FollowRepository {
  FollowRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _follows =>
      _firestore.collection('follows');
  CollectionReference<Map<String, dynamic>> get _users =>
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
    batch.update(_users.doc(followerId), {
      'followingCount': FieldValue.increment(1),
    });
    batch.update(_users.doc(followingId), {
      'followersCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  Future<void> unfollow(String followerId, String followingId) async {
    final batch = _firestore.batch();
    batch.delete(_follows.doc(_docId(followerId, followingId)));
    batch.update(_users.doc(followerId), {
      'followingCount': FieldValue.increment(-1),
    });
    batch.update(_users.doc(followingId), {
      'followersCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  Future<bool> isFollowing(String followerId, String followingId) async {
    final doc = await _follows.doc(_docId(followerId, followingId)).get();
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
