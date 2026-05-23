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
      'profilePictureUrl': null,
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
      'userProfilePic': null,
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
        'userProfilePic': null,
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
