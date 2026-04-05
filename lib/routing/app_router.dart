import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/page_transitions.dart';
import '../features/ai_coach/presentation/ai_coach_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/nutrition/domain/food_search_result.dart';
import '../features/nutrition/presentation/barcode_scanner_screen.dart';
import '../features/nutrition/presentation/food_detail_screen.dart';
import '../features/nutrition/presentation/food_search_screen.dart';
import '../features/nutrition/presentation/nutrition_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/settings/presentation/edit_profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shell/presentation/shell_screen.dart';
import '../features/workouts/presentation/workout_detail_screen.dart';
import '../features/workouts/presentation/workout_logging_screen.dart';
import '../features/workouts/presentation/workouts_screen.dart';
import '../models/enums.dart';
import '../providers/user_profile_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final profileAsync = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final hasProfile = profileAsync.valueOrNull != null;
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!hasProfile && !isOnboarding) return '/onboarding';
      if (hasProfile && isOnboarding) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
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
        ],
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
                    pageBuilder: (context, state) =>
                        slideUpTransitionPage(
                      key: state.pageKey,
                      child: const WorkoutLoggingScreen(),
                    ),
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
    ],
  );
});
