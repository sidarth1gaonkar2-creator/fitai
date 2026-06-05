import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../features/community/domain/challenge.dart';
import '../features/community/domain/leaderboard_entry.dart';
import '../features/ranks/domain/military_ranks.dart';

/// One-time seeding script used to populate the Firestore community feed with
/// realistic-looking posts for App Store screenshots and demos. Not wired up
/// to anything in release — the Settings entry that triggers this is gated by
/// `kDebugMode`.
///
/// What it writes:
///   * `users/{seedUid}` — 10 fake author profiles, each with a realistic
///     military rank. Idempotent (re-running overwrites).
///   * `follows/{currentUid}_{seedUid}` — current user → each fake author, so
///     the seeded posts actually show up in the home feed (the feed query
///     filters by following+self).
///   * `posts/{seedPostId}` — 10 posts spread over the last 7 days with the
///     caption strings from the task spec. Rank badges render from the author's
///     `rankIndex` on their user doc.
///   * `posts/{id}/reactions/{reactorUid}` — random count + emoji per post.
///   * `posts/{id}/comments/{commentId}` — short, casual comments on some posts.
///
/// Deterministic IDs make the seed idempotent: re-running just replaces the
/// same docs in place — no duplicate posts piling up between hot restarts.
///
/// Reaction emoji set must match `PostCard.reactionChoices`. If that list
/// changes, mirror it here.
const _reactionEmojis = ['💪', '🔥', '🏆', '👏', '😤'];

/// Builds a DiceBear avataaars URL for [username]. The seed is the username
/// itself, so each bot gets a deterministic, unique cartoon avatar.
String _avatarUrlFor(String username) =>
    'https://api.dicebear.com/9.x/avataaars/png?seed=$username&size=200';

/// Fake authors. Each carries a hand-tuned strength profile: an overall rank
/// score (0–9 rank points), per-muscle-group scores, and best big-3 lifts (kg).
/// `rankIndex` is `overall.floor()` and must stay consistent with `overall`.
const _authors = <_SeedAuthor>[
  _SeedAuthor(
    uid: 'seed_mike_t',
    username: 'mike_t',
    displayName: 'Mike T',
    bio: 'powerlifting · 5/3/1',
    // SGT — strong across the board.
    rankIndex: 4,
    overall: 4.6,
    chest: 4.6, back: 4.7, legs: 4.5, shoulders: 4.4, arms: 4.3,
    benchKg: 110, squatKg: 150, deadliftKg: 185,
  ),
  _SeedAuthor(
    uid: 'seed_sarahlifts',
    username: 'sarahlifts',
    displayName: 'Sarah',
    bio: 'glutes & gains',
    // SSG — high bench and squat.
    rankIndex: 5,
    overall: 5.4,
    chest: 5.8, back: 5.0, legs: 5.7, shoulders: 5.1, arms: 4.8,
    benchKg: 85, squatKg: 130, deadliftKg: 140,
  ),
  _SeedAuthor(
    uid: 'seed_jfit',
    username: 'jfit',
    displayName: 'Jordan',
    bio: 'recomp era 📉',
    // CPL — intermediate.
    rankIndex: 2,
    overall: 2.6,
    chest: 2.7, back: 2.6, legs: 2.5, shoulders: 2.4, arms: 2.6,
    benchKg: 75, squatKg: 100, deadliftKg: 120,
  ),
  _SeedAuthor(
    uid: 'seed_ironmike',
    username: 'ironmike',
    displayName: 'Iron Mike',
    bio: '6\'2" · 215 · meal prep god',
    // SFC — very strong.
    rankIndex: 6,
    overall: 6.5,
    chest: 6.6, back: 6.7, legs: 6.5, shoulders: 6.3, arms: 6.2,
    benchKg: 145, squatKg: 205, deadliftKg: 250,
  ),
  _SeedAuthor(
    uid: 'seed_natty_king',
    username: 'natty_king',
    displayName: 'Devin',
    bio: 'all natty all year',
    // SPC — good but not great.
    rankIndex: 3,
    overall: 3.5,
    chest: 3.6, back: 3.5, legs: 3.4, shoulders: 3.5, arms: 3.6,
    benchKg: 95, squatKg: 125, deadliftKg: 150,
  ),
  _SeedAuthor(
    uid: 'seed_cardioqueeen',
    username: 'cardioqueeen',
    displayName: 'Riley',
    bio: 'runs + lifts',
    // PFC — more cardio focused, lower strength.
    rankIndex: 1,
    overall: 1.4,
    chest: 1.5, back: 1.4, legs: 1.6, shoulders: 1.2, arms: 1.3,
    benchKg: 35, squatKg: 55, deadliftKg: 65,
  ),
  _SeedAuthor(
    uid: 'seed_bigbenching',
    username: 'bigbenching',
    displayName: 'Tomás',
    bio: 'bench day every day',
    // SGT — strong bench, weaker legs.
    rankIndex: 4,
    overall: 4.2,
    chest: 6.0, back: 4.0, legs: 3.0, shoulders: 4.5, arms: 4.6,
    benchKg: 140, squatKg: 110, deadliftKg: 130,
  ),
  _SeedAuthor(
    uid: 'seed_liftorleave',
    username: 'liftorleave',
    displayName: 'Kev',
    bio: 'gymrat · 4 yrs in',
    // CPL — intermediate.
    rankIndex: 2,
    overall: 2.3,
    chest: 2.4, back: 2.3, legs: 2.2, shoulders: 2.1, arms: 2.4,
    benchKg: 70, squatKg: 90, deadliftKg: 110,
  ),
  _SeedAuthor(
    uid: 'seed_deadliftdiana',
    username: 'deadliftdiana',
    displayName: 'Diana',
    bio: 'pulls heavy on tuesdays',
    // SSG — strong deadlift (back group leads).
    rankIndex: 5,
    overall: 5.1,
    chest: 4.6, back: 6.5, legs: 5.5, shoulders: 4.4, arms: 4.5,
    benchKg: 65, squatKg: 115, deadliftKg: 165,
  ),
  _SeedAuthor(
    uid: 'seed_cardiocass',
    username: 'cardiocass',
    displayName: 'Cass',
    bio: '10k steps daily',
    // PFC — beginner strength.
    rankIndex: 1,
    overall: 1.1,
    chest: 1.2, back: 1.1, legs: 1.0, shoulders: 0.9, arms: 1.0,
    benchKg: 30, squatKg: 45, deadliftKg: 55,
  ),
];

/// Each entry pairs a caption with the author UID (index into [_authors]) and
/// a rough "popularity" hint that scales how many reactions/comments we
/// generate. Order roughly matches the spec.
const _posts = <_SeedPost>[
  _SeedPost(author: 0, caption: '315 squat for a set of 5 today 🦵', hoursAgo: 4, popularity: 3),
  _SeedPost(author: 1, caption: 'finally hit 225 bench lfg', hoursAgo: 9, popularity: 3),
  _SeedPost(author: 2, caption: 'down 12 lbs since I started tracking', hoursAgo: 22, popularity: 2),
  _SeedPost(author: 3, caption: 'meal prep sunday 🍗', hoursAgo: 30, popularity: 2),
  _SeedPost(author: 4, caption: '6am gang wya', hoursAgo: 48, popularity: 1),
  _SeedPost(author: 5, caption: '30 day streak 🔥', hoursAgo: 60, popularity: 3),
  _SeedPost(author: 6, caption: 'this app got my nutrition dialed in fr', hoursAgo: 75, popularity: 2),
  _SeedPost(author: 7, caption: 'whats everyones go to preworkout meal', hoursAgo: 96, popularity: 1, commentsHeavy: true),
  _SeedPost(author: 8, caption: 'hit a pr on deadlift and its not even noon', hoursAgo: 120, popularity: 3),
  _SeedPost(author: 9, caption: 'rest day but still walking 10k steps', hoursAgo: 150, popularity: 1),
];

/// Short comment pool — picked at random for posts that get comments.
const _commentPool = [
  'lets go', 'beast mode', 'w', 'how long did that take', 'solid', 'huge',
  'goated', 'inspiring 💯', 'whats your bw rn', 'pr szn', 'congrats!!',
  'i need to lock in fr', 'eggs and oats every time', 'banana + coffee 🍌',
  'this is the way',
];

class _SeedAuthor {
  const _SeedAuthor({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.rankIndex,
    required this.overall,
    required this.chest,
    required this.back,
    required this.legs,
    required this.shoulders,
    required this.arms,
    required this.benchKg,
    required this.squatKg,
    required this.deadliftKg,
  });
  final String uid;
  final String username;
  final String displayName;
  final String bio;
  final int rankIndex;
  final double overall;
  final double chest;
  final double back;
  final double legs;
  final double shoulders;
  final double arms;
  final double benchKg;
  final double squatKg;
  final double deadliftKg;

  String get rankName => rankFromIndex(rankIndex).displayName;
}

class _SeedPost {
  const _SeedPost({
    required this.author,
    required this.caption,
    required this.hoursAgo,
    required this.popularity,
    this.commentsHeavy = false,
  });
  final int author;
  final String caption;
  final int hoursAgo;
  final int popularity; // 1 low · 2 medium · 3 high
  final bool commentsHeavy;
}

/// Rank fields written onto every author's user doc so the community surfaces
/// (posts, comments, leaderboard, search) can show their rank badge.
Map<String, dynamic> _authorRankFields(_SeedAuthor a) => {
      'rankIndex': a.rankIndex,
      'rankName': a.rankName,
    };

/// Aggregate result returned from [seedCommunityFeed].
class SeedCommunityResult {
  const SeedCommunityResult({
    required this.posts,
    required this.users,
    required this.reactions,
    required this.comments,
  });
  final int posts;
  final int users;
  final int reactions;
  final int comments;
}

/// Writes the full seed dataset to Firestore. Safe to re-run — every doc has
/// a deterministic ID, so re-running overwrites in place.
Future<SeedCommunityResult> seedCommunityFeed({
  required FirebaseFirestore firestore,
  required String currentUserId,
}) async {
  final rand = math.Random(42); // seeded — deterministic reaction/comment mix
  final now = DateTime.now();

  // ── 1. Fake author user docs ─────────────────────────────────────────
  for (final a in _authors) {
    await firestore.collection('users').doc(a.uid).set({
      'userId': a.uid,
      'username': a.username,
      'displayName': a.displayName,
      'bio': a.bio,
      'profilePictureUrl': _avatarUrlFor(a.username),
      'isPublic': true,
      'followersCount': 1, // we're about to follow them
      'followingCount': 0,
      'workoutsCount': rand.nextInt(120) + 20,
      'createdAt': Timestamp.fromDate(
        now.subtract(Duration(days: 60 + rand.nextInt(120))),
      ),
      ..._authorRankFields(a),
    });
  }

  // ── 2. Follow each fake author from the current user ────────────────
  for (final a in _authors) {
    final followDocId = '${currentUserId}_${a.uid}';
    await firestore.collection('follows').doc(followDocId).set({
      'followerId': currentUserId,
      'followingId': a.uid,
      'createdAt': Timestamp.fromDate(
        now.subtract(Duration(days: 7 + rand.nextInt(7))),
      ),
    });
  }

  // ── 3. Posts + reactions + comments ─────────────────────────────────
  var totalReactions = 0;
  var totalComments = 0;

  for (var i = 0; i < _posts.length; i++) {
    final seed = _posts[i];
    final author = _authors[seed.author];
    final postId = 'seed_post_${i + 1}';
    final createdAt = now.subtract(Duration(hours: seed.hoursAgo));

    final reactionCount = switch (seed.popularity) {
      3 => 18 + rand.nextInt(14),
      2 => 6 + rand.nextInt(10),
      _ => rand.nextInt(6),
    };
    final commentCount = seed.commentsHeavy
        ? 5 + rand.nextInt(4)
        : (seed.popularity == 1 ? 0 : 1 + rand.nextInt(3));

    await firestore.collection('posts').doc(postId).set({
      'postId': postId,
      'userId': author.uid,
      'username': author.username,
      'userProfilePic': _avatarUrlFor(author.username),
      'workoutName': '',
      'duration': 0,
      'exercises': const <Map<String, dynamic>>[],
      'totalSets': 0,
      'totalVolume': 0,
      'caption': seed.caption,
      'isPublic': true,
      'likesCount': reactionCount,
      'commentsCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'allowedUsers': const <String>[],
    });

    for (var r = 0; r < reactionCount; r++) {
      final reactorUid = 'seed_reactor_${i}_$r';
      final emoji = _reactionEmojis[rand.nextInt(_reactionEmojis.length)];
      await firestore
          .collection('posts')
          .doc(postId)
          .collection('reactions')
          .doc(reactorUid)
          .set({
        'userId': reactorUid,
        'emoji': emoji,
        'timestamp': Timestamp.fromDate(
          createdAt.add(Duration(minutes: rand.nextInt(360))),
        ),
      });
      totalReactions++;
    }

    for (var c = 0; c < commentCount; c++) {
      _SeedAuthor commenter;
      var attempts = 0;
      do {
        commenter = _authors[rand.nextInt(_authors.length)];
        attempts++;
      } while (commenter.uid == author.uid && attempts < 5);

      final commentId = 'seed_comment_${i}_$c';
      final commentText = _commentPool[rand.nextInt(_commentPool.length)];
      await firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .set({
        'commentId': commentId,
        'userId': commenter.uid,
        'username': commenter.username,
        'userProfilePic': _avatarUrlFor(commenter.username),
        'text': commentText,
        'createdAt': Timestamp.fromDate(
          createdAt.add(Duration(minutes: 5 + c * 7)),
        ),
      });
      totalComments++;
    }
  }

  if (kDebugMode) {
    debugPrint('[seed] wrote ${_posts.length} posts, ${_authors.length} users, '
        '$totalReactions reactions, $totalComments comments');
  }

  return SeedCommunityResult(
    posts: _posts.length,
    users: _authors.length,
    reactions: totalReactions,
    comments: totalComments,
  );
}

// ─── Leaderboard seeder ─────────────────────────────────────────────────────

class SeedLeaderboardResult {
  const SeedLeaderboardResult({required this.entries});
  final int entries;
}

/// The current user's seeded strength profile — a believable mid-pack SPC so
/// they land between bigbenching (4.2) and natty_king (3.5) on the overall
/// board, with their own entry highlighted.
const _userOverall = 3.9;
const _userRankIndex = 3;

/// Writes leaderboard rows for all 10 bots + the current user to the
/// `leaderboard_entries` collection, sorted by overall rank score.
Future<SeedLeaderboardResult> seedLeaderboard({
  required FirebaseFirestore firestore,
  required String currentUserId,
  String currentUsername = 'you',
}) async {
  // Ensure the bot user docs exist (and carry rank) — leaderboard rows resolve
  // avatars/ranks by re-fetching `users/{userId}`.
  for (final a in _authors) {
    await firestore.collection('users').doc(a.uid).set({
      'userId': a.uid,
      'username': a.username,
      'displayName': a.displayName,
      'bio': a.bio,
      'profilePictureUrl': _avatarUrlFor(a.username),
      'isPublic': true,
      ..._authorRankFields(a),
    }, SetOptions(merge: true));
  }

  // Bot rows — built through LeaderboardEntry so field names stay in sync.
  for (final a in _authors) {
    final entry = LeaderboardEntry(
      userId: a.uid,
      username: a.username,
      avatarUrl: _avatarUrlFor(a.username),
      rankIndex: a.rankIndex,
      scoreOverall: a.overall,
      scoreChest: a.chest,
      scoreBack: a.back,
      scoreLegs: a.legs,
      scoreShoulders: a.shoulders,
      scoreArms: a.arms,
      benchKg: a.benchKg,
      squatKg: a.squatKg,
      deadliftKg: a.deadliftKg,
      // Legacy activity stats — secondary info, derived from rank.
      currentStreak: a.rankIndex * 3 + 2,
      totalWorkouts: 20 + a.rankIndex * 9,
      totalVolume: a.overall * 9000,
    );
    await firestore
        .collection('leaderboard_entries')
        .doc(a.uid)
        .set(entry.toMap());
  }

  // Current user row.
  final userEntry = LeaderboardEntry(
    userId: currentUserId,
    username: currentUsername,
    rankIndex: _userRankIndex,
    scoreOverall: _userOverall,
    scoreChest: 4.0,
    scoreBack: 3.8,
    scoreLegs: 3.9,
    scoreShoulders: 3.7,
    scoreArms: 3.6,
    benchKg: 100,
    squatKg: 135,
    deadliftKg: 160,
    currentStreak: 12,
    totalWorkouts: 48,
    totalVolume: 35000,
  );
  await firestore
      .collection('leaderboard_entries')
      .doc(currentUserId)
      .set(userEntry.toMap(), SetOptions(merge: true));

  if (kDebugMode) {
    debugPrint('[seed] wrote ${_authors.length + 1} leaderboard entries '
        '(current user overall=$_userOverall)');
  }

  return SeedLeaderboardResult(entries: _authors.length + 1);
}

// ─── Challenges seeder ──────────────────────────────────────────────────────

/// A rank-focused seed challenge with its participant roster pre-baked.
class _ChallengeSeed {
  const _ChallengeSeed({
    required this.id,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.icon,
    required this.difficulty,
    required this.rankGoalType,
    required this.participants, // author indices
    this.targetRankIndex,
    this.goalExerciseId,
    this.goalExerciseLabel,
    this.targetWeightLbs,
    this.targetBodyweightMultiple,
    this.enrollCurrentUser = false,
  });

  final String id;
  final String title;
  final String description;
  final int durationDays;
  final String icon;
  final String difficulty;
  final RankGoalType rankGoalType;
  final int? targetRankIndex;
  final String? goalExerciseId;
  final String? goalExerciseLabel;
  final double? targetWeightLbs;
  final double? targetBodyweightMultiple;
  final List<int> participants;
  final bool enrollCurrentUser;
}

const _challengeSeeds = <_ChallengeSeed>[
  _ChallengeSeed(
    id: 'seed_challenge_earn_sergeant',
    title: 'Earn Sergeant',
    description:
        'Climb to Sergeant (E5) overall rank. Balance every muscle group to '
        'pin on those stripes.',
    durationDays: 60,
    icon: '🎖️',
    difficulty: 'hard',
    rankGoalType: RankGoalType.overallRank,
    targetRankIndex: 4,
    participants: [3, 1, 8, 0, 6, 4, 2],
    enrollCurrentUser: true,
  ),
  _ChallengeSeed(
    id: 'seed_challenge_bench_corporal',
    title: 'Bench Press Corporal',
    description:
        'Reach Corporal rank on the barbell bench press. Drill the press until '
        'it earns its stripes.',
    durationDays: 30,
    icon: '🏋️',
    difficulty: 'medium',
    rankGoalType: RankGoalType.exerciseRank,
    targetRankIndex: 2,
    goalExerciseId: 'barbell_bench_press',
    goalExerciseLabel: 'Bench',
    participants: [6, 3, 0, 1, 4, 2, 7, 5],
  ),
  _ChallengeSeed(
    id: 'seed_challenge_full_body_specialist',
    title: 'Full Body Specialist',
    description:
        'Reach Specialist rank in ALL six muscle groups. No weak links.',
    durationDays: 90,
    icon: '🛡️',
    difficulty: 'hard',
    rankGoalType: RankGoalType.allMuscleGroups,
    targetRankIndex: 3,
    participants: [3, 0, 1, 8, 4],
  ),
  _ChallengeSeed(
    id: 'seed_challenge_2x_bw_squat',
    title: '2x Bodyweight Squat',
    description:
        'Back squat twice your bodyweight — a benchmark of serious lower-body '
        'strength.',
    durationDays: 60,
    icon: '🦵',
    difficulty: 'hard',
    rankGoalType: RankGoalType.bodyweightMultiple,
    goalExerciseId: 'barbell_back_squat',
    goalExerciseLabel: 'Squat',
    targetBodyweightMultiple: 2.0,
    participants: [3, 1, 8, 0],
  ),
  _ChallengeSeed(
    id: 'seed_challenge_big3_1000',
    title: 'The Big 3: 1000 lb Total',
    description:
        'Combined bench + squat + deadlift of 1000 lb. Join the four-figure club.',
    durationDays: 90,
    icon: '🏅',
    difficulty: 'hard',
    rankGoalType: RankGoalType.big3Total,
    targetWeightLbs: 1000,
    participants: [3, 0, 8, 1, 6],
    enrollCurrentUser: true,
  ),
];

class SeedChallengesResult {
  const SeedChallengesResult({
    required this.challenges,
    required this.participants,
  });
  final int challenges;
  final int participants;
}

/// Writes rank-focused challenge docs + participant rosters to Firestore. The
/// current user is auto-enrolled in challenges flagged [enrollCurrentUser].
Future<SeedChallengesResult> seedChallenges({
  required FirebaseFirestore firestore,
  required String currentUserId,
  String currentUsername = 'you',
}) async {
  final now = DateTime.now();
  var participantCount = 0;

  // Make sure the bot user docs exist (with rank) so participant badge/avatar
  // lookups don't 404.
  for (final a in _authors) {
    await firestore.collection('users').doc(a.uid).set({
      'userId': a.uid,
      'username': a.username,
      'displayName': a.displayName,
      'bio': a.bio,
      'profilePictureUrl': _avatarUrlFor(a.username),
      'isPublic': true,
      ..._authorRankFields(a),
    }, SetOptions(merge: true));
  }

  for (final c in _challengeSeeds) {
    final totalParticipants =
        c.participants.length + (c.enrollCurrentUser ? 1 : 0);
    final startDate = now.subtract(Duration(days: c.durationDays ~/ 2));
    final endDate = now.add(Duration(days: c.durationDays ~/ 2));

    final challenge = Challenge(
      challengeId: c.id,
      title: c.title,
      description: c.description,
      creatorId: 'system',
      creatorUsername: 'DrillFit',
      type: 'workout',
      durationDays: c.durationDays,
      startDate: startDate,
      endDate: endDate,
      participantCount: totalParticipants,
      isPublic: true,
      icon: c.icon,
      difficulty: c.difficulty,
      createdAt: startDate,
      rankGoalType: c.rankGoalType,
      targetRankIndex: c.targetRankIndex,
      goalExerciseId: c.goalExerciseId,
      goalExerciseLabel: c.goalExerciseLabel,
      targetWeightLbs: c.targetWeightLbs,
      targetBodyweightMultiple: c.targetBodyweightMultiple,
    );
    await firestore.collection('challenges').doc(c.id).set(challenge.toMap());

    // Bot participants — carry their rank so the roster ranks by strength.
    for (var i = 0; i < c.participants.length; i++) {
      final author = _authors[c.participants[i]];
      final participant = ChallengeParticipant(
        challengeId: c.id,
        userId: author.uid,
        username: author.username,
        profilePictureUrl: _avatarUrlFor(author.username),
        joinedAt: startDate.add(Duration(hours: i * 4)),
        completedDays: (author.overall * 10).round(),
        rankIndex: author.rankIndex,
      );
      await firestore
          .collection('challenge_participants')
          .doc('${c.id}_${author.uid}')
          .set(participant.toMap());
      participantCount++;
    }

    if (c.enrollCurrentUser) {
      final me = ChallengeParticipant(
        challengeId: c.id,
        userId: currentUserId,
        username: currentUsername,
        joinedAt: startDate.add(const Duration(days: 1)),
        completedDays: (_userOverall * 10).round(),
        rankIndex: _userRankIndex,
      );
      await firestore
          .collection('challenge_participants')
          .doc('${c.id}_$currentUserId')
          .set(me.toMap(), SetOptions(merge: true));
      participantCount++;
    }
  }

  if (kDebugMode) {
    debugPrint('[seed] wrote ${_challengeSeeds.length} challenges with '
        '$participantCount participants');
  }

  return SeedChallengesResult(
    challenges: _challengeSeeds.length,
    participants: participantCount,
  );
}
