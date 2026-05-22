import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/page_transitions.dart';
import '../features/ai_coach/presentation/ai_coach_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/community/presentation/challenges/challenge_detail_screen.dart';
import '../features/community/presentation/challenges/create_challenge_screen.dart';
import '../features/community/presentation/community_screen.dart';
import '../features/community/presentation/feed/post_detail_screen.dart';
import '../features/community/presentation/followers/followers_list_screen.dart';
import '../features/community/presentation/notifications/notifications_screen.dart';
import '../features/community/presentation/profile/edit_social_profile_screen.dart';
import '../features/community/presentation/profile/profile_screen.dart';
import '../features/community/presentation/profile_setup/profile_setup_screen.dart';
import '../features/community/presentation/share/create_post_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/nutrition/domain/food_search_result.dart';
import '../features/nutrition/presentation/barcode_scanner_screen.dart';
import '../features/nutrition/presentation/food_detail_screen.dart';
import '../features/nutrition/presentation/food_search_screen.dart';
import '../features/nutrition/presentation/meal_builder_screen.dart';
import '../features/nutrition/presentation/meal_plan_preview_screen.dart';
import '../features/nutrition/presentation/nutrition_screen.dart';
import '../features/nutrition/presentation/restaurant_browser_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/progress/presentation/pr_hall_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/settings/presentation/edit_profile_screen.dart';
import '../features/settings/presentation/notification_settings_screen.dart';
import '../features/nutrition/presentation/create_saved_meal_screen.dart';
import '../features/nutrition/presentation/saved_meals_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/themes/presentation/theme_store_screen.dart';
import '../features/supplements/presentation/supplements_screen.dart';
import '../features/shell/presentation/shell_screen.dart';
import '../data/workout_templates.dart';
import '../features/workouts/presentation/exercise_detail_screen.dart';
import '../features/workouts/presentation/workout_detail_screen.dart';
import '../features/workouts/presentation/workout_logging_screen.dart';
import '../features/workouts/presentation/workouts_screen.dart';
import '../models/enums.dart';
import '../providers/auth_provider.dart';
import '../providers/community_providers.dart';
import '../providers/user_profile_provider.dart';

const _authRoutes = {'/welcome', '/signin', '/signup'};

final appRouterProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final profileAsync = ref.watch(userProfileProvider);
  final firestoreUserAsync = ref.watch(firestoreUserProvider);

  return GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      if (authAsync.isLoading) return null;

      final user = authAsync.valueOrNull;
      final location = state.matchedLocation;
      final isAuthRoute = _authRoutes.contains(location);

      // Not authenticated → welcome
      if (user == null) {
        return isAuthRoute ? null : '/welcome';
      }

      // Authenticated on auth route → forward
      if (isAuthRoute) {
        final hasProfile = profileAsync.valueOrNull != null;
        if (!hasProfile) return '/onboarding';
        final hasFirestoreProfile = firestoreUserAsync.valueOrNull != null;
        return hasFirestoreProfile ? '/dashboard' : '/profile-setup';
      }

      // Onboarding guard
      final hasProfile = profileAsync.valueOrNull != null;
      final isOnboarding = location == '/onboarding';
      final isProfileSetup = location == '/profile-setup';

      if (!hasProfile && !isOnboarding) return '/onboarding';
      if (hasProfile && isOnboarding) {
        final hasFirestoreProfile = firestoreUserAsync.valueOrNull != null;
        return hasFirestoreProfile ? '/dashboard' : '/profile-setup';
      }

      // Profile setup guard
      if (hasProfile && !isProfileSetup) {
        final hasFirestoreProfile = firestoreUserAsync.valueOrNull != null;
        if (!hasFirestoreProfile &&
            !isOnboarding &&
            location != '/profile-setup') {
          return '/profile-setup';
        }
      }

      return null;
    },
    routes: [
      // ─── Auth ─────────────────────────────────────────────────
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // ─── Main Shell (5 tabs) ──────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
          // Tab 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Tab 1: Workouts
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workouts',
                builder: (context, state) => const WorkoutsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    pageBuilder: (context, state) {
                      final template = state.extra as WorkoutTemplate?;
                      return slideUpTransitionPage(
                        key: state.pageKey,
                        child: WorkoutLoggingScreen(
                          initialTemplate: template,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: ':id',
                    pageBuilder: (context, state) {
                      final id =
                          int.parse(state.pathParameters['id']!);
                      return slideUpTransitionPage(
                        key: state.pageKey,
                        child: WorkoutDetailScreen(workoutId: id),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        pageBuilder: (context, state) {
                          final id = int.parse(
                              state.pathParameters['id']!);
                          return slideUpTransitionPage(
                            key: state.pageKey,
                            child: WorkoutLoggingScreen(
                                editWorkoutId: id),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Tab 2: Nutrition
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/nutrition',
                builder: (context, state) => const NutritionScreen(),
                routes: [
                  GoRoute(
                    path: 'meal-plan/:planId',
                    pageBuilder: (context, state) {
                      final planId = state.pathParameters['planId']!;
                      return slideUpTransitionPage(
                        key: state.pageKey,
                        child: MealPlanPreviewScreen(planId: planId),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'search/:mealType',
                    pageBuilder: (context, state) {
                      final mealType = MealType.values.byName(
                          state.pathParameters['mealType']!);
                      return slideUpTransitionPage(
                        key: state.pageKey,
                        child: FoodSearchScreen(mealType: mealType),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'scan/:mealType',
                    pageBuilder: (context, state) {
                      final mealType = MealType.values.byName(
                          state.pathParameters['mealType']!);
                      return slideUpTransitionPage(
                        key: state.pageKey,
                        child:
                            BarcodeScannerScreen(mealType: mealType),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'food/:mealType',
                    pageBuilder: (context, state) {
                      final mealType = MealType.values.byName(
                          state.pathParameters['mealType']!);
                      final food = state.extra as FoodSearchResult?;
                      if (food == null) {
                        return slideUpTransitionPage(
                          key: state.pageKey,
                          child: const NutritionScreen(),
                        );
                      }
                      return slideUpTransitionPage(
                        key: state.pageKey,
                        child: FoodDetailScreen(
                            mealType: mealType, food: food),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'restaurants',
                    pageBuilder: (context, state) {
                      final mealTypeParam =
                          state.uri.queryParameters['mealType'];
                      MealType? mt;
                      if (mealTypeParam != null) {
                        try {
                          mt = MealType.values.byName(mealTypeParam);
                        } catch (_) {/* ignore bad param */}
                      }
                      return slideUpTransitionPage(
                        key: state.pageKey,
                        child: RestaurantBrowserScreen(mealType: mt),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: ':id',
                        pageBuilder: (context, state) {
                          final id = state.pathParameters['id']!;
                          final mealTypeParam =
                              state.uri.queryParameters['mealType'];
                          MealType? mt;
                          if (mealTypeParam != null) {
                            try {
                              mt = MealType.values.byName(mealTypeParam);
                            } catch (_) {/* ignore bad param */}
                          }
                          return slideUpTransitionPage(
                            key: state.pageKey,
                            child: MealBuilderScreen(
                              restaurantId: id,
                              initialMealType: mt,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'saved-meals',
                    pageBuilder: (context, state) => slideUpTransitionPage(
                      key: state.pageKey,
                      child: const SavedMealsScreen(),
                    ),
                    routes: [
                      GoRoute(
                        path: 'create',
                        pageBuilder: (context, state) =>
                            slideUpTransitionPage(
                          key: state.pageKey,
                          child: const CreateSavedMealScreen(),
                        ),
                      ),
                      GoRoute(
                        path: ':id/edit',
                        pageBuilder: (context, state) {
                          final id = int.tryParse(
                              state.pathParameters['id'] ?? '');
                          return slideUpTransitionPage(
                            key: state.pageKey,
                            child: CreateSavedMealScreen(savedMealId: id),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Tab 3: Progress
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (context, state) => const ProgressScreen(),
                routes: [
                  GoRoute(
                    path: 'pr-hall',
                    pageBuilder: (context, state) =>
                        slideUpTransitionPage(
                      key: state.pageKey,
                      child: const PRHallScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Tab 4: Community (replaced AI Coach)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (context, state) => const CommunityScreen(),
              ),
            ],
          ),
        ],
      ),

      // ─── Standalone routes ────────────────────────────────────
      GoRoute(
        path: '/ai-coach',
        pageBuilder: (context, state) => slideUpTransitionPage(
          key: state.pageKey,
          child: const AICoachScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/:userId',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return slideUpTransitionPage(
            key: state.pageKey,
            child: ProfileScreen(userId: userId),
          );
        },
        routes: [
          GoRoute(
            path: 'followers',
            pageBuilder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return slideUpTransitionPage(
                key: state.pageKey,
                child: FollowersListScreen(
                    userId: userId, isFollowers: true),
              );
            },
          ),
          GoRoute(
            path: 'following',
            pageBuilder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return slideUpTransitionPage(
                key: state.pageKey,
                child: FollowersListScreen(
                    userId: userId, isFollowers: false),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (context, state) => slideUpTransitionPage(
          key: state.pageKey,
          child: const EditSocialProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/community/post/:postId',
        pageBuilder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return slideUpTransitionPage(
            key: state.pageKey,
            child: PostDetailScreen(postId: postId),
          );
        },
      ),
      GoRoute(
        path: '/community/challenge/:challengeId',
        pageBuilder: (context, state) {
          final challengeId = state.pathParameters['challengeId']!;
          return slideUpTransitionPage(
            key: state.pageKey,
            child: ChallengeDetailScreen(challengeId: challengeId),
          );
        },
      ),
      GoRoute(
        path: '/community/challenge/create',
        pageBuilder: (context, state) => slideUpTransitionPage(
          key: state.pageKey,
          child: const CreateChallengeScreen(),
        ),
      ),
      GoRoute(
        path: '/community/notifications',
        pageBuilder: (context, state) => slideUpTransitionPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
        ),
      ),
      GoRoute(
        path: '/community/create-post',
        pageBuilder: (context, state) {
          final idParam = state.uri.queryParameters['workoutId'];
          final workoutId = idParam != null ? int.tryParse(idParam) : null;
          return slideUpTransitionPage(
            key: state.pageKey,
            child: CreatePostScreen(initialWorkoutId: workoutId),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => slideUpTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
        routes: [
          GoRoute(
            path: 'edit-profile',
            pageBuilder: (context, state) => slideUpTransitionPage(
              key: state.pageKey,
              child: const EditProfileScreen(),
            ),
          ),
          GoRoute(
            path: 'notifications',
            pageBuilder: (context, state) => slideUpTransitionPage(
              key: state.pageKey,
              child: const NotificationSettingsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/theme-store',
        pageBuilder: (context, state) => slideUpTransitionPage(
          key: state.pageKey,
          child: const ThemeStoreScreen(),
        ),
      ),
      GoRoute(
        path: '/supplements',
        pageBuilder: (context, state) => slideUpTransitionPage(
          key: state.pageKey,
          child: const SupplementsScreen(),
        ),
      ),
      GoRoute(
        // Standalone (not in the shell) so it can stack on top of any tab.
        // The exercise name comes via query param to keep the URL pure.
        path: '/exercise',
        pageBuilder: (context, state) {
          final name = state.uri.queryParameters['name'] ?? '';
          return slideUpTransitionPage(
            key: state.pageKey,
            child: ExerciseDetailScreen(exerciseName: name),
          );
        },
      ),
    ],
  );
});
