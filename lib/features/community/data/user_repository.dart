import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/logger.dart';
import '../../../providers/firestore_provider.dart';
import '../domain/firestore_user.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(firestoreProvider));
});

class UserRepository {
  UserRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _usernames =>
      _firestore.collection('usernames');

  Future<void> createUser(FirestoreUser user) async {
    final batch = _firestore.batch();
    batch.set(_users.doc(user.userId), user.toMap());
    batch.set(_usernames.doc(user.username.toLowerCase()), {
      'userId': user.userId,
    });
    await batch.commit();
  }

  Future<FirestoreUser?> getUser(String userId) async {
    try {
      final doc = await _users.doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return FirestoreUser.fromMap(doc.data()!);
    } catch (e, st) {
      AppLogger.error(
        'UserRepository.getUser failed (userId=$userId)',
        error: e,
        stack: st,
      );
      return null;
    }
  }

  Future<bool> isUsernameTaken(String username) async {
    final doc = await _usernames.doc(username.toLowerCase()).get();
    return doc.exists;
  }

  Future<List<FirestoreUser>> searchUsers(String query) async {
    if (query.isEmpty) return const [];
    final lower = query.toLowerCase();
    final snap = await _users
        .where('username', isGreaterThanOrEqualTo: lower)
        .where('username', isLessThan: '$lower\uf8ff')
        .limit(20)
        .get();
    return snap.docs.map((d) => FirestoreUser.fromMap(d.data())).toList();
  }

  Future<void> updateUser(
      String userId, Map<String, dynamic> fields) async {
    await _users.doc(userId).update(fields);
  }

  /// Mirrors the user's overall military rank onto their user doc so the
  /// community (posts, comments, leaderboard) can show a rank badge. Merge so
  /// it's safe whether or not the field already exists. Best-effort.
  Future<void> updateUserRank(
      String userId, int rankIndex, String rankName) async {
    try {
      await _users.doc(userId).set(
        {'rankIndex': rankIndex, 'rankName': rankName},
        SetOptions(merge: true),
      );
    } catch (e, st) {
      AppLogger.error(
        'UserRepository.updateUserRank failed (userId=$userId)',
        error: e,
        stack: st,
      );
    }
  }

  Future<void> incrementWorkoutCount(String userId) async {
    try {
      await _users.doc(userId).update({
        'workoutsCount': FieldValue.increment(1),
      });
    } catch (e, st) {
      AppLogger.error(
        'UserRepository.incrementWorkoutCount failed (userId=$userId)',
        error: e,
        stack: st,
      );
    }
  }
}
