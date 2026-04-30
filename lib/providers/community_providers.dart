import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/community/data/challenge_repository.dart';
import '../features/community/data/follow_repository.dart';
import '../features/community/data/leaderboard_repository.dart';
import '../features/community/data/notification_repository.dart';
import '../features/community/data/post_repository.dart';
import '../features/community/data/user_repository.dart';
import '../features/community/domain/challenge.dart';
import '../features/community/domain/comment.dart';
import '../features/community/domain/firestore_user.dart';
import '../features/community/domain/leaderboard_entry.dart';
import '../features/community/domain/notification.dart';
import '../features/community/domain/post.dart';
import 'auth_provider.dart';

// ─── User Profile Providers ─────────────────────────────────────────────────

final firestoreUserProvider = FutureProvider<FirestoreUser?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(userRepositoryProvider).getUser(userId);
});

final userByIdProvider =
    FutureProvider.family<FirestoreUser?, String>((ref, userId) async {
  return ref.watch(userRepositoryProvider).getUser(userId);
});

final usernameAvailableProvider =
    FutureProvider.family<bool, String>((ref, username) async {
  if (username.length < 3) return false;
  final taken =
      await ref.watch(userRepositoryProvider).isUsernameTaken(username);
  return !taken;
});

final userSearchResultsProvider =
    FutureProvider.family<List<FirestoreUser>, String>((ref, query) async {
  if (query.length < 2) return const [];
  return ref.watch(userRepositoryProvider).searchUsers(query);
});

// ─── Follow Providers ───────────────────────────────────────────────────────

final isFollowingProvider =
    FutureProvider.family<bool, String>((ref, targetUserId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;
  return ref
      .watch(followRepositoryProvider)
      .isFollowing(userId, targetUserId);
});

final followingIdsProvider = FutureProvider<Set<String>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const {};
  return ref.watch(followRepositoryProvider).getFollowingIds(userId);
});

final followerIdsProvider =
    FutureProvider.family<List<String>, String>((ref, userId) async {
  return ref.watch(followRepositoryProvider).getFollowerIds(userId);
});

// ─── Feed Providers ─────────────────────────────────────────────────────────

final isPostLikedProvider =
    FutureProvider.family<bool, String>((ref, postId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;
  return ref.watch(postRepositoryProvider).isLiked(postId, userId);
});

final postCommentsProvider =
    FutureProvider.family<List<Comment>, String>((ref, postId) async {
  return ref.watch(postRepositoryProvider).getComments(postId);
});

final userPostsProvider =
    FutureProvider.family<List<Post>, String>((ref, userId) async {
  return ref.watch(postRepositoryProvider).getUserPosts(userId);
});

// ─── Leaderboard Providers ──────────────────────────────────────────────────

final leaderboardByFieldProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>((ref, field) async {
  return ref.watch(leaderboardRepositoryProvider).getTopBy(field);
});

// ─── Challenge Providers ────────────────────────────────────────────────────

final publicChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  return ref.watch(challengeRepositoryProvider).getPublicChallenges();
});

final myChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(challengeRepositoryProvider).getMyChallenges(userId);
});

final challengeByIdProvider =
    FutureProvider.family<Challenge?, String>((ref, id) async {
  return ref.watch(challengeRepositoryProvider).getChallenge(id);
});

final challengeParticipantsProvider = FutureProvider.family<
    List<ChallengeParticipant>, String>((ref, challengeId) async {
  return ref
      .watch(challengeRepositoryProvider)
      .getParticipants(challengeId);
});

final isParticipantProvider =
    FutureProvider.family<bool, String>((ref, challengeId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;
  return ref
      .watch(challengeRepositoryProvider)
      .isParticipant(challengeId, userId);
});

final myChallengeParticipationProvider =
    FutureProvider.family<ChallengeParticipant?, String>(
        (ref, challengeId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref
      .watch(challengeRepositoryProvider)
      .getParticipant(challengeId, userId);
});

// ─── Notification Providers ────────────────────────────────────────────────

final notificationsStreamProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();
  return ref.watch(notificationRepositoryProvider).streamFor(userId);
});

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(0);
  return ref
      .watch(notificationRepositoryProvider)
      .streamUnreadCount(userId);
});
