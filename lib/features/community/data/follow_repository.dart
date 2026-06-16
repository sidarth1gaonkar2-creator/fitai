import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/logger.dart';
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

    /// Records that [followerId] now follows [followingId]. Writes happen in
    /// two phases so we don't take down the whole follow attempt if a single
    /// counter update is rule-blocked:
    ///
    /// 1. Create the /follows edge — atomic, this is the source of truth.
    /// 2. Increment the *follower's* own followingCount — owner-write,
    ///    always allowed by /users rules.
    /// 3. Increment the *followed* user's followersCount — cross-user
    ///    write that strict production rules reject. Wrapped in try/catch
    ///    so a rule denial leaves the follow edge intact rather than
    ///    rolling the whole operation back. Followers count then becomes
    ///    eventually-consistent (or just slightly stale on the followed
    ///    user's profile until a server-side aggregator catches up); the
    ///    home feed and following lists derive purely from the edges.
    Future<void> follow(String followerId, String followingId) async {
          await _follows.doc(_docId(followerId, followingId)).set({
                  'followerId': followerId,
                  'followingId': followingId,
                  'createdAt': FieldValue.serverTimestamp(),
          });

          try {
                  await _userDocs.doc(followerId).update({
                            'followingCount': FieldValue.increment(1),
                  });
          } catch (e, s) {
                  AppLogger.error('[Follow] followingCount bump failed', error: e, stack: s);
          }

          try {
                  await _userDocs.doc(followingId).update({
                            'followersCount': FieldValue.increment(1),
                  });
          } catch (e, s) {
                  // Strict rules forbid writing another user's doc. The follow itself
                  // still succeeded above; we just lose the cosmetic counter bump.
                  AppLogger.error('[Follow] cross-user followersCount bump skipped',
                                            error: e, stack: s);
          }

          // Notify the followed user. This is also best-effort — if the
          // recipient is a seed bot with no auth identity, the notification
          // write may fail, and we don't want a failed notification to
          // present as a failed follow.
          try {
                  final me = await _users.getUser(followerId);
                  await _notifications.send(
                            toUserId: followingId,
                            type: 'follow',
                            fromUserId: followerId,
                            fromUsername: me?.username ?? 'Someone',
                            fromUserAvatar: me?.profilePictureUrl,
                            message: '${me?.username ?? 'Someone'} started following you',
                          );
          } catch (e, s) {
                  AppLogger.error('[Follow] notify failed', error: e, stack: s);
          }
    }

    Future<void> unfollow(String followerId, String followingId) async {
          await _follows.doc(_docId(followerId, followingId)).delete();

          try {
                  await _userDocs.doc(followerId).update({
                            'followingCount': FieldValue.increment(-1),
                  });
          } catch (e, s) {
                  AppLogger.error('[Unfollow] followingCount decrement failed',
                                            error: e, stack: s);
          }

          try {
                  await _userDocs.doc(followingId).update({
                            'followersCount': FieldValue.increment(-1),
                  });
          } catch (e, s) {
                  AppLogger.error('[Unfollow] cross-user followersCount decrement skipped',
                                            error: e, stack: s);
          }
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
