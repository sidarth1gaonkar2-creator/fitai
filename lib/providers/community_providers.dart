import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/community/data/block_repository.dart';
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
import '../core/utils/scoped_prefs.dart';
import '../features/community/domain/post.dart';
import 'auth_provider.dart';
import 'unit_system_provider.dart' show sharedPreferencesProvider;

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

/// All users currently at a given overall rank ordinal — powers the "browse by
/// rank" filter on the search tab.
final usersByRankProvider =
    FutureProvider.family<List<FirestoreUser>, int>((ref, rankIndex) async {
  return ref.watch(userRepositoryProvider).getUsersByRank(rankIndex);
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
  // Viewing another user's profile → request only their PUBLIC posts so the
  // query satisfies the posts read rule (isPublic == true). Your own profile
  // stays unfiltered: the rule permits userId == you regardless of visibility,
  // so you still see your private posts.
  final currentUserId = ref.watch(currentUserIdProvider);
  final publicOnly = currentUserId != userId;
  return ref
      .watch(postRepositoryProvider)
      .getUserPosts(userId, publicOnly: publicOnly);
});

// ─── Moderation (Guideline 1.2: report + block) ─────────────────────────────

/// Uids the current account has blocked. The feed filters these out client-side
/// on top of the global public query. Invalidate after a block/unblock.
final blockedUserIdsProvider = FutureProvider<Set<String>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const {};
  return ref.watch(blockRepositoryProvider).blockedIds(uid);
});

/// Post ids the current user has reported and chosen to hide. Persisted locally
/// (uid-scoped) so a reported post stays gone across launches; the feed filters
/// these out client-side. Reporting does not delete the post for everyone — it
/// files a [reports] doc and hides it for the reporter.
class HiddenPostsNotifier extends StateNotifier<Set<String>> {
  HiddenPostsNotifier(this._prefs, this._uid)
      : super(_load(_prefs, _uid));

  final SharedPreferences _prefs;
  final String? _uid;

  static Set<String> _load(SharedPreferences prefs, String? uid) {
    if (uid == null) return <String>{};
    return (prefs.getStringList(hiddenPostsPrefsKey(uid)) ?? const <String>[])
        .toSet();
  }

  Future<void> hide(String postId) async {
    final uid = _uid;
    if (uid == null || state.contains(postId)) return;
    final next = {...state, postId};
    state = next;
    await _prefs.setStringList(hiddenPostsPrefsKey(uid), next.toList());
  }
}

/// Prefs key of an account's hidden-post ids — the original instance of the
/// [scopedKey] pattern the rest of the per-user prefs now follow. Public so
/// account deletion (settings) can remove exactly this account's key and
/// nothing else.
String hiddenPostsPrefsKey(String uid) => scopedKey('hidden_posts', uid);

final hiddenPostsProvider =
    StateNotifierProvider<HiddenPostsNotifier, Set<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final uid = ref.watch(currentUserIdProvider);
  return HiddenPostsNotifier(prefs, uid);
});

// ─── Leaderboard Providers ──────────────────────────────────────────────────

final leaderboardByFieldProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>((ref, field) async {
  return ref.watch(leaderboardRepositoryProvider).getTopBy(field);
});

/// A single user's leaderboard row (rank scores + big-3 lifts), or null if they
/// have none yet. Used by the mini-profile sheet.
final leaderboardEntryProvider =
    FutureProvider.family<LeaderboardEntry?, String>((ref, userId) async {
  return ref.watch(leaderboardRepositoryProvider).getEntry(userId);
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

// ─── Reactions ─────────────────────────────────────────────────────────────

/// Aggregated emoji → count map for a post. Auto-disposes so we don't keep
/// firestore snapshots open for every post the user has scrolled past.
final postReactionsProvider = FutureProvider.autoDispose
    .family<Map<String, int>, String>((ref, postId) async {
  return ref.watch(postRepositoryProvider).getReactionCounts(postId);
});

/// Current user's reaction emoji for a post, or null if none.
final userReactionProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, postId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(postRepositoryProvider).getUserReaction(postId, userId);
});
