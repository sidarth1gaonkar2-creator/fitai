import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/user_profile_provider.dart';
import 'widgets/calorie_ring.dart';
import 'widgets/dashboard_skeleton.dart';
import 'widgets/macro_row.dart';
import 'widgets/streak_counter.dart';
import 'widgets/today_workout_card.dart';
import 'widgets/water_tracker.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final nutritionAsync = ref.watch(todayNutritionProvider);
    final workoutAsync = ref.watch(todayWorkoutProvider);
    final streakAsync = ref.watch(streakProvider);
    final glasses = ref.watch(waterIntakeProvider);

    return profileAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const DashboardSkeleton(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: ErrorCard(
          message: 'Could not load your dashboard.',
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
      ),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final tdee = profile.tdee;
        final nutrition = nutritionAsync.valueOrNull;
        final workout = workoutAsync.valueOrNull;
        final streak = streakAsync.valueOrNull ?? 0;

        final calories = nutrition?.totalCalories ?? 0;
        final protein = nutrition?.totalProtein ?? 0;
        final carbs = nutrition?.totalCarbs ?? 0;
        final fat = nutrition?.totalFat ?? 0;

        final isNutritionLoading =
            nutritionAsync.isLoading && !nutritionAsync.hasValue;
        final isWorkoutLoading =
            workoutAsync.isLoading && !workoutAsync.hasValue;
        final isStreakLoading =
            streakAsync.isLoading && !streakAsync.hasValue;

        return Scaffold(
          appBar: AppBar(
            title: Text('Hi, ${profile.name}!'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.go('/settings'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Calorie Ring ---
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isNutritionLoading
                        ? const ShimmerBox(
                            key: ValueKey('ring-loading'),
                            width: 200,
                            height: 200,
                            borderRadius: 100,
                          )
                        : CalorieRing(
                            key: const ValueKey('ring-loaded'),
                            consumed: calories.toDouble(),
                            target: tdee,
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- Macro Row ---
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isNutritionLoading
                      ? const Row(
                          key: ValueKey('macro-loading'),
                          children: [
                            Expanded(
                                child: ShimmerBox(width: 100, height: 50)),
                            SizedBox(width: 12),
                            Expanded(
                                child: ShimmerBox(width: 100, height: 50)),
                            SizedBox(width: 12),
                            Expanded(
                                child: ShimmerBox(width: 100, height: 50)),
                          ],
                        )
                      : MacroRow(
                          key: const ValueKey('macro-loaded'),
                          proteinGrams: protein.toDouble(),
                          carbsGrams: carbs.toDouble(),
                          fatGrams: fat.toDouble(),
                          tdee: tdee,
                          goal: profile.goal,
                        ),
                ),
                const SizedBox(height: 20),

                // --- Streak + Water side by side ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isStreakLoading
                            ? const ShimmerBox(
                                key: ValueKey('streak-loading'),
                                width: double.infinity,
                                height: 120,
                                borderRadius: 12,
                              )
                            : StreakCounter(
                                key: const ValueKey('streak-loaded'),
                                streak: streak,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: WaterTracker(
                        glasses: glasses,
                        onIncrement: () => ref
                            .read(waterIntakeProvider.notifier)
                            .update((s) => s + 1),
                        onDecrement: () => ref
                            .read(waterIntakeProvider.notifier)
                            .update((s) => s > 0 ? s - 1 : 0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- Today's Workout Card ---
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isWorkoutLoading
                      ? const ShimmerCard(
                          key: ValueKey('workout-loading'),
                          height: 100,
                        )
                      : TodayWorkoutCard(
                          key: const ValueKey('workout-loaded'),
                          workout: workout,
                        ),
                ),
                const SizedBox(height: 24),

                // --- Quick Action Buttons ---
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.go('/nutrition'),
                        icon: const Icon(Icons.add),
                        label: const Text('Log Meal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => context.go('/workouts'),
                        icon: const Icon(Icons.add),
                        label: const Text('Log Workout'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
