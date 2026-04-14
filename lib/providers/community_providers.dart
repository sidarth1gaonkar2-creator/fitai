import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/community/data/challenge_repository.dart';
import '../features/community/data/follow_repository.dart';
import '../features/community/data/leaderboard_repository.dart';
import '../features/community/data/post_repository.dart';
import '../features/community/data/user_repository.dart';
import '../features/community/domain/challenge.dart';
import '../features/community/domain/comment.dart';
import '../features/community/domain/firestore_user.dart';
import '../features/community/domain/leaderboard_entry.dart';
import '../features/community/domain/post.dart';
import 'auth_provider.dart';

// ─── User Profile Providers ─────────────────────────────────────────────────

/// Current user's Firestore profile.
final firestoreUserProvider = FutureProvider<FirestoreUser?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(userRepositoryProvider).getUser(userId);
});

/// Any user's profile by ID.
final userByIdProvider =
    FutureProvider.family<FirestoreUser?, String>((ref, userId) async {
  return ref.watch(userRepositoryProvider).getUser(userId);
});

/// Check if a username is available.
final usernameAvailableProvider =
    FutureProvider.family<bool, String>((ref, username) async {
  if (username.length < 3) return false;
  final taken = await ref.watch(userRepositoryProvider).isUsernameTaken(username);
  return !taken;
});

/// Search users by username prefix.
final userSearchResultsProvider =
    FutureProvider.family<List<FirestoreUser>, String>((ref, query) async {
  if (query.length < 2) return const [];
  return ref.watch(userRepositoryProvider).searchUsers(query);
});

// ─── Follow Providers ───────────────────────────────────────────────────────

/// Whether current user follows a target user.
final isFollowingProvider =
    FutureProvider.family<bool, String>((ref, targetUserId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;
  return ref.watch(followRepositoryProvider).isFollowing(userId, targetUserId);
});

/// Set of user IDs the current user follows.
final followingIdsProvider = FutureProvider<Set<String>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const {};
  return ref.watch(followRepositoryProvider).getFollowingIds(userId);
});

/// Follower user IDs for a user.
final followerIdsProvider =
    FutureProvider.family<List<String>, String>((ref, userId) async {
  return ref.watch(followRepositoryProvider).getFollowerIds(userId);
});

// ─── Feed Providers ─────────────────────────────────────────────────────────

/// Whether current user liked a post.
final isPostLikedProvider =
    FutureProvider.family<bool, String>((ref, postId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;
  return ref.watch(postRepositoryProvider).isLiked(postId, userId);
});

/// Comments for a post.
final postCommentsProvider =
    FutureProvider.family<List<Comment>, String>((ref, postId) async {
  return ref.watch(postRepositoryProvider).getComments(postId);
});

/// A user's posts (for profile screen).
final userPostsProvider =
    FutureProvider.family<List<Post>, String>((ref, userId) async {
  return ref.watch(postRepositoryProvider).getUserPosts(userId);
});

// ─── Leaderboard Providers ──────────────────────────────────────────────────

/// Top entries by a specific metric field.
final leaderboardByFieldProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>((ref, field) async {
  return ref.watch(leaderboardRepositoryProvider).getTopBy(field);
});

// ─── Challenge Providers ────────────────────────────────────────────────────

/// Active public challenges.
final publicChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  return ref.watch(challengeRepositoryProvider).getPublicChallenges();
});

/// Current user's joined challenges.
final myChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(challengeRepositoryProvider).getMyChallenges(userId);
});

/// Challenge by ID.
final challengeByIdProvider =
    FutureProvider.family<Challenge?, String>((ref, id) async {
  return ref.watch(challengeRepositoryProvider).getChallenge(id);
});

/// Participants for a challenge.
final challengeParticipantsProvider = FutureProvider.family<
    List<ChallengeParticipant>, String>((ref, challengeId) async {
  return ref
      .watch(challengeRepositoryProvider)
      .getParticipants(challengeId);
});

/// Whether current user is a participant.
final isParticipantProvider =
    FutureProvider.family<bool, String>((ref, challengeId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;
  return ref
      .watch(challengeRepositoryProvider)
      .isParticipant(challengeId, userId);
});
