import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// One-time seeding script used to populate the Firestore community feed with
/// realistic-looking posts for App Store screenshots and demos. Not wired up
/// to anything in release — the Settings entry that triggers this is gated by
/// `kDebugMode`.
///
/// What it writes:
///   * `users/{seedUid}` — 10 fake author profiles. Idempotent (re-running
///     overwrites).
///   * `follows/{currentUid}_{seedUid}` — current user → each fake author, so
///     the seeded posts actually show up in the home feed (the feed query
///     filters by following+self).
///   * `posts/{seedPostId}` — 10 posts spread over the last 7 days with the
///     caption strings from the task spec.
///   * `posts/{id}/reactions/{reactorUid}` — random count + emoji per post,
///     using fresh synthetic UIDs so we don't have to create a real user doc
///     per reaction (the count is implicit in subcollection size).
///   * `posts/{id}/comments/{commentId}` — short, casual comments on some
///     posts.
///
/// Deterministic IDs make the seed idempotent: re-running just replaces the
/// same docs in place — no duplicate posts piling up between hot restarts.
///
/// Reaction emoji set must match `PostCard.reactionChoices`. If that list
/// changes, mirror it here.
const _reactionEmojis = ['💪', '🔥', '🏆', '👏', '😤'];

/// Builds a DiceBear avataaars URL for [username]. The seed is the username
/// itself, so each bot gets a deterministic, unique cartoon avatar.
///
/// `size=200` matches the typical post-card / leaderboard avatar diameter
/// at 3x retina — large enough to look crisp, small enough to keep the PNG
/// well under 30 KB. The app already uses `CachedNetworkImage` for these
/// URLs so the per-bot PNG is fetched once per install.
String _avatarUrlFor(String username) =>
    'https://api.dicebear.com/9.x/avataaars/png?seed=$username&size=200';

/// Fake authors. The userId is what gets written into `userId` on each post
/// and into the `follows` doc. Keep the IDs prefixed with `seed_` so they're
/// easy to spot (and wipe) in the Firestore console.
const _authors = <_SeedAuthor>[
  _SeedAuthor(
    uid: 'seed_mike_t',
    username: 'mike_t',
    displayName: 'Mike T',
    bio: 'powerlifting · 5/3/1',
  ),
  _SeedAuthor(
    uid: 'seed_sarahlifts',
    username: 'sarahlifts',
    displayName: 'Sarah',
    bio: 'glutes & gains',
  ),
  _SeedAuthor(
    uid: 'seed_jfit',
    username: 'jfit',
    displayName: 'Jordan',
    bio: 'recomp era 📉',
  ),
  _SeedAuthor(
    uid: 'seed_ironmike',
    username: 'ironmike',
    displayName: 'Iron Mike',
    bio: '6\'2" · 215 · meal prep god',
  ),
  _SeedAuthor(
    uid: 'seed_natty_king',
    username: 'natty_king',
    displayName: 'Devin',
    bio: 'all natty all year',
  ),
  _SeedAuthor(
    uid: 'seed_cardioqueeen',
    username: 'cardioqueeen',
    displayName: 'Riley',
    bio: 'runs + lifts',
  ),
  _SeedAuthor(
    uid: 'seed_bigbenching',
    username: 'bigbenching',
    displayName: 'Tomás',
    bio: 'bench day every day',
  ),
  _SeedAuthor(
    uid: 'seed_liftorleave',
    username: 'liftorleave',
    displayName: 'Kev',
    bio: 'gymrat · 4 yrs in',
  ),
  _SeedAuthor(
    uid: 'seed_deadliftdiana',
    username: 'deadliftdiana',
    displayName: 'Diana',
    bio: 'pulls heavy on tuesdays',
  ),
  _SeedAuthor(
    uid: 'seed_cardiocass',
    username: 'cardiocass',
    displayName: 'Cass',
    bio: '10k steps daily',
  ),
];

/// Each entry pairs a caption with the author UID (index into [_authors]) and
/// a rough "popularity" hint that scales how many reactions/comments we
/// generate. Order roughly matches the spec.
const _posts = <_SeedPost>[
  _SeedPost(
    author: 0, // mike_t
    caption: '315 squat for a set of 5 today 🦵',
    hoursAgo: 4,
    popularity: 3, // high — heavy PR-flavoured post
  ),
  _SeedPost(
    author: 1, // sarahlifts
    caption: 'finally hit 225 bench lfg',
    hoursAgo: 9,
    popularity: 3,
  ),
  _SeedPost(
    author: 2, // jfit
    caption: 'down 12 lbs since I started tracking',
    hoursAgo: 22,
    popularity: 2,
  ),
  _SeedPost(
    author: 3, // ironmike
    caption: 'meal prep sunday 🍗',
    hoursAgo: 30,
    popularity: 2,
  ),
  _SeedPost(
    author: 4, // natty_king
    caption: '6am gang wya',
    hoursAgo: 48,
    popularity: 1, // chatter post — fewer reacts
  ),
  _SeedPost(
    author: 5, // cardioqueeen
    caption: '30 day streak 🔥',
    hoursAgo: 60,
    popularity: 3,
  ),
  _SeedPost(
    author: 6, // bigbenching
    caption: 'this app got my nutrition dialed in fr',
    hoursAgo: 75,
    popularity: 2,
  ),
  _SeedPost(
    author: 7, // liftorleave
    caption: 'whats everyones go to preworkout meal',
    hoursAgo: 96,
    popularity: 1, // question post — comments-heavy, reacts-light
    commentsHeavy: true,
  ),
  _SeedPost(
    author: 8, // deadliftdiana
    caption: 'hit a pr on deadlift and its not even noon',
    hoursAgo: 120,
    popularity: 3,
  ),
  _SeedPost(
    author: 9, // cardiocass
    caption: 'rest day but still walking 10k steps',
    hoursAgo: 150,
    popularity: 1,
  ),
];

/// Short comment pool — picked at random for posts that get comments. Mix of
/// hype, dap, and questions so the comment threads don't all read identically.
const _commentPool = [
  'lets go',
  'beast mode',
  'w',
  'how long did that take',
  'solid',
  'huge',
  'goated',
  'inspiring 💯',
  'whats your bw rn',
  'pr szn',
  'congrats!!',
  'i need to lock in fr',
  'eggs and oats every time',
  'banana + coffee 🍌',
  'this is the way',
];

class _SeedAuthor {
  const _SeedAuthor({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.bio,
  });
  final String uid;
  final String username;
  final String displayName;
  final String bio;
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

  /// 1 = low, 2 = medium, 3 = high. Translates to a reaction count band.
  final int popularity;

  /// When true, generate more comments than reactions (used for question posts
  /// like "what's your preworkout meal").
  final bool commentsHeavy;
}

/// Aggregate result returned from [seedCommunityFeed] so the caller can show
/// a confirmation dialog with concrete numbers.
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
///
/// [currentUserId] is needed because the home feed only surfaces posts whose
/// `userId` is in the current user's follow set (plus their own). We
/// auto-follow every seeded author from the current user so the seeded posts
/// appear in their feed without manual setup.
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

    // Reaction count bands by popularity. The actual likesCount/commentsCount
    // are stored on the post doc; the post card reads from those rather than
    // counting subcollection docs every render.
    final reactionCount = switch (seed.popularity) {
      3 => 18 + rand.nextInt(14), // 18-31
      2 => 6 + rand.nextInt(10), //  6-15
      _ => rand.nextInt(6), //       0-5
    };
    final commentCount = seed.commentsHeavy
        ? 5 + rand.nextInt(4) // 5-8 — question posts get more
        : (seed.popularity == 1 ? 0 : 1 + rand.nextInt(3)); // 0-3

    await firestore.collection('posts').doc(postId).set({
      'postId': postId,
      'userId': author.uid,
      'username': author.username,
      'userProfilePic': _avatarUrlFor(author.username),
      // Caption-only posts — leave workout fields empty so the post card
      // doesn't render the "workout attachment" block (it self-gates on
      // `workoutId != null || workoutName.isNotEmpty`).
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

    // Reactions — one doc per synthetic reactor UID. The aggregator
    // (`getReactionCounts`) just counts emoji occurrences across the
    // subcollection, so it doesn't matter that these UIDs don't correspond
    // to real users.
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

    // Comments — pick from a different author than the post owner to avoid
    // self-replies, and stagger the timestamps so they appear in order in
    // the post detail view.
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

/// Per-author leaderboard stats. Hand-picked so the sort by `totalVolume`
/// puts the current user at position 4 once their entry is inserted at the
/// configured volume (48k). Tweak the bot volumes if you want to shift the
/// user's slot.
class _LeaderboardSeed {
  const _LeaderboardSeed({
    required this.authorIndex,
    required this.totalVolume,
    required this.totalWorkouts,
    required this.currentStreak,
  });
  final int authorIndex;
  final double totalVolume;
  final int totalWorkouts;
  final int currentStreak;
}

const _leaderboardSeeds = <_LeaderboardSeed>[
  _LeaderboardSeed(
      authorIndex: 0, totalVolume: 78000, totalWorkouts: 7, currentStreak: 32),
  _LeaderboardSeed(
      authorIndex: 3, totalVolume: 67000, totalWorkouts: 6, currentStreak: 28),
  _LeaderboardSeed(
      authorIndex: 1, totalVolume: 55000, totalWorkouts: 6, currentStreak: 22),
  // ← current user lands here at ~48k
  _LeaderboardSeed(
      authorIndex: 8, totalVolume: 42000, totalWorkouts: 5, currentStreak: 18),
  _LeaderboardSeed(
      authorIndex: 6, totalVolume: 38000, totalWorkouts: 5, currentStreak: 14),
  _LeaderboardSeed(
      authorIndex: 7, totalVolume: 31000, totalWorkouts: 4, currentStreak: 12),
  _LeaderboardSeed(
      authorIndex: 2, totalVolume: 25000, totalWorkouts: 4, currentStreak: 9),
  _LeaderboardSeed(
      authorIndex: 4, totalVolume: 22000, totalWorkouts: 3, currentStreak: 6),
  _LeaderboardSeed(
      authorIndex: 5, totalVolume: 18000, totalWorkouts: 3, currentStreak: 5),
];

/// Volume to slot the current user at — sits between seeds #3 (55k) and
/// #4 (42k), giving them rank 4 of 10. Workouts/streak chosen to look
/// believable for a mid-tier user.
const double _currentUserVolume = 48000;
const int _currentUserWorkouts = 5;
const int _currentUserStreak = 20;

class SeedLeaderboardResult {
  const SeedLeaderboardResult({required this.entries});
  final int entries;
}

/// Writes 10 leaderboard rows (9 bots + the current user) to the
/// `leaderboard_entries` collection. Bot stats are deterministic; the
/// current user is inserted at the 4th highest volume so they appear
/// mid-pack on the leaderboard screen.
///
/// [currentUsername] is the username shown for the current user. If
/// unknown (e.g. profile not loaded yet) we fall back to 'you' so the
/// row still renders something readable.
Future<SeedLeaderboardResult> seedLeaderboard({
  required FirebaseFirestore firestore,
  required String currentUserId,
  String currentUsername = 'you',
}) async {
  final now = DateTime.now();

  // Ensure the fake user docs exist — the leaderboard list often resolves
  // avatars by re-fetching `users/{userId}`, so we want the link to work
  // even if the community seeder hasn't been run.
  for (final a in _authors) {
    await firestore.collection('users').doc(a.uid).set({
      'userId': a.uid,
      'username': a.username,
      'displayName': a.displayName,
      'bio': a.bio,
      'profilePictureUrl': _avatarUrlFor(a.username),
      'isPublic': true,
    }, SetOptions(merge: true));
  }

  // Bot rows.
  for (final seed in _leaderboardSeeds) {
    final author = _authors[seed.authorIndex];
    await firestore
        .collection('leaderboard_entries')
        .doc(author.uid)
        .set({
      'userId': author.uid,
      'username': author.username,
      'avatarUrl': _avatarUrlFor(author.username),
      'currentStreak': seed.currentStreak,
      'totalWorkouts': seed.totalWorkouts,
      'totalVolume': seed.totalVolume,
      'updatedAt': Timestamp.fromDate(
        now.subtract(Duration(hours: seed.authorIndex)),
      ),
    });
  }

  // Current user row.
  await firestore
      .collection('leaderboard_entries')
      .doc(currentUserId)
      .set({
    'userId': currentUserId,
    'username': currentUsername,
    'avatarUrl': null,
    'currentStreak': _currentUserStreak,
    'totalWorkouts': _currentUserWorkouts,
    'totalVolume': _currentUserVolume,
    'updatedAt': Timestamp.fromDate(now),
  }, SetOptions(merge: true));

  if (kDebugMode) {
    debugPrint(
        '[seed] wrote ${_leaderboardSeeds.length + 1} leaderboard entries '
        '(current user at volume=$_currentUserVolume)');
  }

  return SeedLeaderboardResult(entries: _leaderboardSeeds.length + 1);
}

// ─── Challenges seeder ──────────────────────────────────────────────────────

/// One challenge with its participant roster pre-baked. `participantSeeds`
/// lists `(authorIndex, completedDays)` pairs — the seeder writes one
/// `challenge_participants` doc per pair plus, optionally, a doc for the
/// current user.
class _ChallengeSeed {
  const _ChallengeSeed({
    required this.id,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.icon,
    required this.difficulty,
    required this.participantSeeds,
    this.currentUserCompletedDays,
  });

  final String id;
  final String title;
  final String description;
  final int durationDays;
  final String icon;
  final String difficulty;

  /// `(authorIndex, completedDays)` per bot participant.
  final List<(int, int)> participantSeeds;

  /// If set, also enroll the current user with this completed-days value
  /// and put them in the participant list.
  final int? currentUserCompletedDays;
}

const _challengeSeeds = <_ChallengeSeed>[
  _ChallengeSeed(
    id: 'seed_challenge_30_day_streak',
    title: '30 Day Streak',
    description:
        'Train every day for 30 days. Rest days count as long as you log a walk, stretch, or mobility session.',
    durationDays: 30,
    icon: '🔥',
    difficulty: 'medium',
    participantSeeds: [
      (0, 28), // mike_t — nearly done
      (3, 24),
      (1, 22),
      (8, 21),
      (6, 18),
      (7, 15),
      (2, 12),
      (4, 10),
      (5, 8),
      (9, 7),
      (0, 6), // double-up — re-using mike_t's index for a synthetic 12th
      (3, 5),
    ],
    currentUserCompletedDays: 14, // mid-range
  ),
  _ChallengeSeed(
    id: 'seed_challenge_5x_workouts_week',
    title: '5x Workouts This Week',
    description:
        'Hit five workouts in seven days. Cardio, lifting, or sport practice all count.',
    durationDays: 7,
    icon: '💪',
    difficulty: 'easy',
    participantSeeds: [
      (0, 5),
      (1, 5),
      (3, 4),
      (8, 4),
      (2, 3),
      (6, 3),
      (4, 2),
      (5, 1),
    ],
    currentUserCompletedDays: 3,
  ),
  _ChallengeSeed(
    id: 'seed_challenge_1000_lb_club',
    title: '1000 lb Total Club',
    description:
        'Combined 1RM across squat, bench, and deadlift. Track progress and post your big-3 video to qualify.',
    // We use durationDays as the target lb total so the existing progress UI
    // ("X / 1000") reads naturally as pounds. Not a duration in the usual
    // sense — see comment in the seeder docstring.
    durationDays: 1000,
    icon: '🏋️',
    difficulty: 'hard',
    participantSeeds: [
      (0, 950),
      (3, 880),
      (1, 810),
      (8, 760),
      (6, 620),
      (7, 470),
    ],
    currentUserCompletedDays: 720,
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

/// Writes challenge docs + participant rosters to Firestore. The current
/// user is auto-enrolled in every challenge that has a
/// `currentUserCompletedDays` value (currently all three) so they appear
/// in "My Challenges" without manual joining.
///
/// Note on `1000 lb Total Club`: its `durationDays` field is repurposed as
/// a pounds-total target so the existing progress UI reads as "X / 1000".
/// The community feature has no separate "goal value" field; if you add
/// one later, swap that re-purpose for the real field.
Future<SeedChallengesResult> seedChallenges({
  required FirebaseFirestore firestore,
  required String currentUserId,
  String currentUsername = 'you',
}) async {
  final now = DateTime.now();
  var participantCount = 0;

  // Make sure the bot user docs exist so participant avatar lookups don't
  // 404. Same pattern as `seedLeaderboard`.
  for (final a in _authors) {
    await firestore.collection('users').doc(a.uid).set({
      'userId': a.uid,
      'username': a.username,
      'displayName': a.displayName,
      'bio': a.bio,
      'profilePictureUrl': _avatarUrlFor(a.username),
      'isPublic': true,
    }, SetOptions(merge: true));
  }

  for (final c in _challengeSeeds) {
    // Total participants = bot count + (1 if current user is enrolled).
    final totalParticipants = c.participantSeeds.length +
        (c.currentUserCompletedDays != null ? 1 : 0);
    final startDate = now.subtract(Duration(days: c.durationDays ~/ 2));
    final endDate = now.add(Duration(days: c.durationDays ~/ 2));

    await firestore.collection('challenges').doc(c.id).set({
      'challengeId': c.id,
      'title': c.title,
      'description': c.description,
      'creatorId': 'system',
      'creatorUsername': 'SwoleCoach',
      'type': 'workout',
      'durationDays': c.durationDays,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'participantCount': totalParticipants,
      'isPublic': true,
      'requiresPhotoProof': false,
      'icon': c.icon,
      'difficulty': c.difficulty,
      'createdAt': Timestamp.fromDate(startDate),
      'trackingMode': 'manual',
    });

    // Bot participants. Stagger joinedAt so the sort by `joinedAt desc` (in
    // ChallengeRepository.getParticipants) doesn't produce a degenerate
    // tie-break order.
    for (var i = 0; i < c.participantSeeds.length; i++) {
      final (authorIdx, completedDays) = c.participantSeeds[i];
      final author = _authors[authorIdx];
      // Re-using the same author across two slots needs distinct doc IDs.
      final docId =
          '${c.id}_${author.uid}${i >= 10 ? '_dup$i' : ''}';
      await firestore
          .collection('challenge_participants')
          .doc(docId)
          .set({
        'challengeId': c.id,
        'userId': author.uid,
        'username': author.username,
        'profilePictureUrl': _avatarUrlFor(author.username),
        'joinedAt': Timestamp.fromDate(
          startDate.add(Duration(hours: i * 4)),
        ),
        'completedDays': completedDays,
        'currentStreak':
            completedDays >= 3 ? (completedDays / 3).floor() : completedDays,
        'proofPhotos': const <String>[],
        'isCompleted': completedDays >= c.durationDays,
        'lastCheckInDate': Timestamp.fromDate(
          now.subtract(const Duration(hours: 6)),
        ),
      });
      participantCount++;
    }

    // Current user participant — uses the canonical doc ID format
    // (`{challengeId}_{userId}`) so the app's `isParticipant` lookup hits.
    final userProgress = c.currentUserCompletedDays;
    if (userProgress != null) {
      await firestore
          .collection('challenge_participants')
          .doc('${c.id}_$currentUserId')
          .set({
        'challengeId': c.id,
        'userId': currentUserId,
        'username': currentUsername,
        'profilePictureUrl': null,
        'joinedAt': Timestamp.fromDate(
          startDate.add(const Duration(days: 1)),
        ),
        'completedDays': userProgress,
        'currentStreak': userProgress >= 3 ? (userProgress / 3).floor() : userProgress,
        'proofPhotos': const <String>[],
        'isCompleted': userProgress >= c.durationDays,
        'lastCheckInDate': Timestamp.fromDate(now),
      }, SetOptions(merge: true));
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
