import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/logger.dart';
import '../../../providers/firestore_provider.dart';
import '../domain/notification.dart';

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(firestoreProvider));
});

class NotificationRepository {
  NotificationRepository(this._firestore);
  final FirebaseFirestore _firestore;
  static const _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _firestore.collection('users').doc(userId).collection('notifications');

  /// Writes a notification to the target user's subcollection. Never throws —
  /// the caller's primary action (follow/like/comment) must not fail because
  /// of a notification error.
  Future<void> send({
    required String toUserId,
    required String type,
    required String fromUserId,
    required String fromUsername,
    String? fromUserAvatar,
    required String message,
    String? postId,
    String? challengeId,
  }) async {
    if (toUserId == fromUserId) return; // don't notify yourself
    try {
      final id = _uuid.v4();
      final notif = AppNotification(
        id: id,
        type: type,
        fromUserId: fromUserId,
        fromUsername: fromUsername,
        fromUserAvatar: fromUserAvatar,
        message: message,
        postId: postId,
        challengeId: challengeId,
      );
      await _col(toUserId).doc(id).set(notif.toMap());
    } catch (e, st) {
      AppLogger.error(
        'NotificationRepository.send failed '
        '(to=$toUserId, type=$type)',
        error: e,
        stack: st,
      );
    }
  }

  Stream<List<AppNotification>> streamFor(String userId) {
    return _col(userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<int> streamUnreadCount(String userId) {
    return _col(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markRead(String userId, String notifId) async {
    try {
      await _col(userId).doc(notifId).update({'isRead': true});
    } catch (e, st) {
      AppLogger.error(
        'NotificationRepository.markRead failed (notifId=$notifId)',
        error: e,
        stack: st,
      );
    }
  }

  Future<void> markAllRead(String userId) async {
    try {
      final snap =
          await _col(userId).where('isRead', isEqualTo: false).get();
      if (snap.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e, st) {
      AppLogger.error(
        'NotificationRepository.markAllRead failed',
        error: e,
        stack: st,
      );
    }
  }
}
