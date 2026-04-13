import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/page_transitions.dart';
import '../features/ai_coach/presentation/ai_coach_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/nutrition/domain/food_search_result.dart';
import '../features/nutrition/presentation/barcode_scanner_screen.dart';
import '../features/nutrition/presentation/food_detail_screen.dart';
import '../features/nutrition/presentation/food_search_screen.dart';
import '../features/nutrition/presentation/meal_plan_preview_screen.dart';
import '../features/nutrition/presentation/nutrition_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/progress/presentation/pr_hall_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/settings/presentation/edit_profile_screen.dart';
import '../features/settings/presentation/notification_settings_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/supplements/presentation/supplements_screen.dart';
import '../features/shell/presentation/shell_screen.dart';
import '../data/workout_templates.dart';
import '../features/workouts/presentation/workout_detail_screen.dart';
import '../features/workouts/presentation/workout_logging_screen.dart';
import '../features/workouts/presentation/workouts_screen.dart';
import '../models/enums.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';

const _authRoutes = {'/welcome', '/signin', '/signup'};

final appRouterProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final profileAsync = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      // Wait for auth state to resolve
      if (authAsync.isLoading) return null;

      final user = authAsync.valueOrNull;
      final location = state.matchedLocation;
      final isAuthRoute = _authRoutes.contains(location);

      // Not authenticated → send to /welcome
      if (user == null) {
        return isAuthRoute ? null : '/welcome';
      }

      // Authenticated but on an auth route → forward to app
      if (isAuthRoute) {
        final hasProfile = profileAsync.valueOrNull != null;
        return hasProfile ? '/dashboard' : '/onboarding';
      }

      // Authenticated, not on auth route → existing onboarding guard
      final hasProfile = profileAsync.valueOrNull != null;
      final isOnboarding = location == '/onboarding';

      if (!hasProfile && !isOnboarding) return '/onboarding';
      if (hasProfile && isOnboarding) return '/dashboard';
      return null;
    },
    routes: [
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
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
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (context, state) => const ProgressScreen(),
                routes: [
                  GoRoute(
                    path: 'pr-hall',
                    pageBuilder: (context, state) => slideUpTransitionPage(
                      key: state.pageKey,
                      child: const PRHallScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ai-coach',
                builder: (context, state) => const AICoachScreen(),
              ),
            ],
          ),
        ],
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
        path: '/supplements',
        pageBuilder: (context, state) => slideUpTransitionPage(
          key: state.pageKey,
          child: const SupplementsScreen(),
        ),
      ),
    ],
  );
});
