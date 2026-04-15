---
name: Provider Conventions
description: Naming, lifecycle, and invalidation patterns for Riverpod providers (updated April 2026)
type: reference
---

## Naming Conventions
- `*Provider` suffix on all providers
- `*Notifier` suffix on StateNotifier subclasses
- Free async mutation functions (e.g., `addFoodEntry`, `completeDay`, `toggleSupplementTaken`) live in the provider file alongside related providers and accept `WidgetRef` as first param
- `activeWorkoutProvider` — StateNotifierProvider.autoDispose for the in-progress workout
- `exerciseFilterProvider` — StateNotifierProvider.autoDispose reset on sheet open

## autoDispose Usage
- `exerciseFilterProvider` and `filteredExercisesProvider` — autoDispose (sheet-scoped)
- `activeWorkoutProvider` — autoDispose (logging screen-scoped)
- All other providers are persistent (no autoDispose)

## Provider.family Usage
- `workoutsByDateProvider` — family<List<Workout>, DateTime>
- `workoutByIdProvider` — family<Workout?, int>
- `foodLocalSearchProvider` — family<List<FoodSearchResult>, String>
- `foodRemoteSearchProvider` — FutureProvider.family<List<FoodSearchResult>, String>
- `barcodeLookupProvider` — FutureProvider.family<FoodSearchResult?, String>
- `supplementConsistencyProvider` — FutureProvider.family<double, int> (30-day adherence)
- `userByIdProvider` — FutureProvider.family<FirestoreUser?, String>
- `isFollowingProvider` — FutureProvider.family<bool, String>
- `challengeByIdProvider` — FutureProvider.family<Challenge?, String>
- `leaderboardByFieldProvider` — FutureProvider.family<List<LeaderboardEntry>, String>

## Invalidation Pattern After Mutations
After every successful write, the relevant providers are explicitly invalidated:
- Nutrition mutations: `todayNutritionProvider`, `todayMealsProvider`, `streakProvider`, `todayMicronutrientsProvider`
- Workout saves: `allWorkoutsProvider`, `workoutDatesProvider`, `todayWorkoutProvider`, `streakProvider`, `personalRecordsProvider`
- Day completion: `todayCompletedDayProvider`
- Supplement toggles: `todaySupplementLogsProvider`, `supplementChecklistProvider`
- Supplement add/delete: `allSupplementsProvider`, `activeSupplementsProvider`, `supplementChecklistProvider`
- Community follows: `isFollowingProvider`, `followingIdsProvider`, `userByIdProvider`
- Community challenges: `isParticipantProvider`, `challengeParticipantsProvider`

## Provider Files
- `lib/providers/user_profile_provider.dart` — UserProfile (Isar)
- `lib/providers/nutrition_providers.dart` — Meals, nutrition logs, food search, completed day
- `lib/providers/workout_providers.dart` — Workouts, exercises, sets, active workout
- `lib/providers/settings_providers.dart` — ThemeMode, app settings
- `lib/providers/supplement_providers.dart` — Supplement catalog, checklist, consistency
- `lib/providers/custom_meal_plan_providers.dart` — Meal plan CRUD + import
- `lib/providers/personal_records_hall_providers.dart` — PR sort, filter, display
- `lib/providers/community_providers.dart` — All social providers (20+)
- `lib/providers/auth_provider.dart` — Firebase Auth state
- `lib/providers/firestore_provider.dart` — Firestore + Storage instances
- `lib/providers/notification_providers.dart` — Notification settings + scheduling
- `lib/providers/isar_provider.dart` — Isar instance (overridden in main)
