---
name: Community Feature
description: Full social system — Firebase-backed feed, profiles, follows, leaderboards, challenges with Firestore collections and 10+ screens
type: project
---

## Overview
A complete social/community feature added as the 5th tab in the bottom nav ("Community"). Uses Firebase (Auth, Firestore, Storage) for all backend operations — NOT Isar.

## Domain Models (lib/features/community/domain/)

**FirestoreUser** — User social profile (separate from local Isar UserProfile)
- userId, username, displayName, bio, profilePictureUrl, isPublic
- followersCount, followingCount, workoutsCount
- Methods: fromMap(), toMap(), copyWith()

**Post** — Workout shared to feed
- postId, userId, username, userProfilePic, workoutName, duration
- exercises (List<PostExercise>: name, sets, bestWeight)
- totalSets, totalVolume, caption, isPublic, likesCount, commentsCount
- documentSnapshot for pagination cursor

**Comment** — commentId, userId, username, userProfilePic, text, createdAt

**Challenge** — Community fitness challenges
- challengeId, title, description, creatorId, creatorUsername
- type ('streak'/'volume'/'workouts'), target, durationDays
- startDate, endDate, participantCount, isPublic
- ChallengeParticipant sub-model: progress, completed, joinedAt

**LeaderboardEntry** — weeklyVolume, weeklyWorkouts, currentStreak, updatedAt

## Repositories (lib/features/community/data/)

All use Firestore as backend, exposed via Riverpod providers.

- **UserRepository** — createUser, getUser, searchUsers (prefix), isUsernameTaken, updateUser, incrementWorkoutCount
- **PostRepository** — createPost, deletePost, getFeedPosts (paginated by followingIds), getUserPosts, toggleLike, isLiked, addComment, getComments
- **FollowRepository** — follow/unfollow (batch writes updating counts), isFollowing, getFollowingIds, getFollowerIds
- **ChallengeRepository** — createChallenge, getPublicChallenges, getMyChallenges, joinChallenge, leaveChallenge, updateProgress, getParticipants, isParticipant
- **LeaderboardRepository** — updateEntry, getTopBy(field, limit=50), getFriendsLeaderboard

## Firestore Collections Structure
```
users/{userId}
usernames/{username_lowercase} → {userId}
follows/{followerId}_{followingId}
posts/{postId}
  └── likes/{userId}
  └── comments/{commentId}
challenges/{challengeId}
challenge_participants/{challengeId}_{userId}
leaderboard_entries/{userId}
```

## Screens (lib/features/community/presentation/)

- **CommunityScreen** — Hub with 4-segment CupertinoSlidingSegmentedControl: Feed, Leaderboard, Challenges, Search
- **FeedScreen** — Paginated workout posts (20/page), pull-to-refresh, infinite scroll
- **PostDetailScreen** — Single post with full comment section, like/unlike
- **PostCard** (widget) — Header, workout name, exercise list (first 3), stats, caption, like/comment counts
- **LeaderboardScreen** — 3 tabs (Streak/Volume/Workouts), Global vs Friends toggle
- **LeaderboardTile** (widget) — Medal for top 3, accent highlight for current user
- **ChallengesScreen** — Browse (public) / My Challenges tabs, create button
- **ChallengeDetailScreen** — Info card, personal progress, join/leave, participants list
- **CreateChallengeScreen** — Form: title, description, type, target, duration, public toggle
- **ProfileScreen** — Avatar, stats row (workouts/followers/following), follow button, user's posts
- **EditSocialProfileScreen** — Edit username (availability check), bio, profile picture, public toggle
- **ProfileSetupScreen** — Initial profile creation after onboarding (username, bio, pic)
- **UserSearchScreen** — Debounced search (300ms), results with follow buttons
- **FollowersListScreen** — Followers/Following list with follow/unfollow actions
- **ShareWorkoutSheet** — Share completed workout to feed

## Providers (lib/providers/community_providers.dart)

User: firestoreUserProvider, userByIdProvider, usernameAvailableProvider, userSearchResultsProvider
Follow: isFollowingProvider, followingIdsProvider, followerIdsProvider
Feed: isPostLikedProvider, postCommentsProvider, userPostsProvider
Leaderboard: leaderboardByFieldProvider
Challenge: publicChallengesProvider, myChallengesProvider, challengeByIdProvider, challengeParticipantsProvider, isParticipantProvider

## Routes (lib/routing/app_router.dart)

- `/community` — CommunityScreen (shell tab 4)
- `/community/post/:postId` — PostDetailScreen
- `/community/challenge/:challengeId` — ChallengeDetailScreen
- `/community/challenge/create` — CreateChallengeScreen
- `/profile/:userId` — ProfileScreen
- `/profile/:userId/followers` — FollowersListScreen
- `/profile/:userId/following` — FollowersListScreen
- `/profile/edit` — EditSocialProfileScreen
- `/profile-setup` — ProfileSetupScreen (standalone, post-onboarding)
