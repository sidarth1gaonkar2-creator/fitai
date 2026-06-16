import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/firestore_provider.dart';

final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  return BlockRepository(ref.watch(firestoreProvider));
});

/// Stores the set of users the current account has blocked (Guideline 1.2).
///
/// Kept on the PRIVATE, owner-only subtree `users/{uid}/private/blocked` — the
/// existing `match /users/{userId}/private/{document}` rule already restricts
/// read/write to the owner, so no new Firestore rule is needed for blocking.
/// The blocked uids live in a single `uids` array on that doc.
class BlockRepository {
  BlockRepository(this._firestore);
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('private')
      .doc('blocked');

  /// The uids [uid] has blocked. Empty on any error (never throws — a failed
  /// read must not break the feed).
  Future<Set<String>> blockedIds(String uid) async {
    try {
      final snap = await _doc(uid).get();
      final list = (snap.data()?['uids'] as List?)?.whereType<String>();
      return list?.toSet() ?? const {};
    } catch (_) {
      return const {};
    }
  }

  Future<void> block(String uid, String targetUid) async {
    await _doc(uid).set({
      'uids': FieldValue.arrayUnion([targetUid]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> unblock(String uid, String targetUid) async {
    await _doc(uid).set({
      'uids': FieldValue.arrayRemove([targetUid]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
