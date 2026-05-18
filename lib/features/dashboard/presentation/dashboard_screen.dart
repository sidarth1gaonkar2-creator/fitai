import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/nutrient_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/health_providers.dart';
import '../../../providers/insight_providers.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../services/insight_service.dart';
import 'widgets/activity_rings.dart';
import 'widgets/activity_row.dart';
import 'widgets/calorie_ring.dart';
import 'widgets/dashboard_skeleton.dart';
import 'widgets/fitness_workouts_card.dart';
import 'widgets/macro_row.dart';
import 'widgets/saved_meals_quick_log.dart';
import 'widgets/streak_counter.dart';
import 'widgets/today_workout_card.dart';
import 'widgets/water_tracker.dart';
import '../../supplements/presentation/widgets/supplement_checklist_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final nutritionAsync = ref.watch(todayNutritionProvider);
    final workoutAsync = ref.watch(todayWorkoutProvider);
    final streakAsync = ref.watch(streakProvider);
    final glasses = ref.watch(waterIntakeProvider);

    return profileAsync.when(
      loading: () => Builder(builder: (context) {
        final palette = AppColors.of(context);
        return Scaffold(
          backgroundColor: palette.background,
          appBar: CupertinoNavigationBar(
            middle: const Text('Dashboard'),
            backgroundColor: palette.background.withValues(alpha: 0.8),
            border: null,
          ),
          body: const DashboardSkeleton(),
        );
      }),
      error: (e, _) => Builder(builder: (context) {
        final palette = AppColors.of(context);
        return Scaffold(
          backgroundColor: palette.background,
          appBar: CupertinoNavigationBar(
            middle: const Text('Dashboard'),
            backgroundColor: palette.background.withValues(alpha: 0.8),
            border: null,
          ),
          body: ErrorCard(
            message: 'Could not load your dashboard.',
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
        );
      }),
      data: (profile) {
        if (profile == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/onboarding');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final tdee = profile.tdee;
        final nutrition = nutritionAsync.valueOrNull;
        final workout = workoutAsync.valueOrNull;
        final streak = streakAsync.valueOrNull ?? 0;

        final calories = nutrition?.totalCalories ?? 0;
        final protein = nutrition?.totalProtein ?? 0;
        final carbs = nutrition?.totalCarbs ?? 0;
        final fat = nutrition?.totalFat ?? 0;

        // Burned calories from Apple Health (0 unless connected + dashboard on)
        final dashboardHealthOn =
            ref.watch(healthDashboardEnabledProvider);
        final burnedAsync = ref.watch(todayActiveCaloriesProvider);
        final burned =
            dashboardHealthOn ? (burnedAsync.valueOrNull ?? 0.0) : 0.0;

        final isNutritionLoading =
            nutritionAsync.isLoading && !nutritionAsync.hasValue;
        final isWorkoutLoading =
            workoutAsync.isLoading && !workoutAsync.hasValue;
        final isStreakLoading =
            streakAsync.isLoading && !streakAsync.hasValue;

        final palette = AppColors.of(context);
        return Scaffold(
          backgroundColor: palette.background,
          appBar: CupertinoNavigationBar(
            middle: Text('${_greeting()}, ${profile.name}'),
            backgroundColor: palette.background.withValues(alpha: 0.8),
            border: null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: () => context.push('/ai-coach'),
                  child: const Icon(CupertinoIcons.chat_bubble_fill, size: 22),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: () => context.push('/settings'),
                  child: const Icon(CupertinoIcons.gear, size: 22),
                ),
              ],
            ),
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
                            burned: burned,
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Stats Row ---
                _StatsRow(
                  caloriesBurned: calories,
                  workoutMinutes: workout?.durationMinutes,
                ),
                const SizedBox(height: 20),

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

                // --- Apple Activity Rings (Move / Exercise / Stand) ---
                // ActivityRings, ActivityRow and FitnessWorkoutsCard each
                // self-gate on Platform.isIOS + healthConnectedProvider, so
                // they collapse cleanly to zero height on Android or when
                // Health is disconnected.
                if (Platform.isIOS) ...[
                  const ActivityRings(),
                  const SizedBox(height: 12),
                  const ActivityRow(),
                  const SizedBox(height: 12),
                  const FitnessWorkoutsCard(),
                  const SizedBox(height: 20),
                ],

                // --- Insights ---
                // Surfaces up to 3 local-analysis cards (strength progress,
                // streaks, deload reminders, etc.). Hides entirely while
                // loading or when no insights are produced so the dashboard
                // doesn't show an empty section.
                const _InsightsSection(),

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
                        onIncrement: () {
                          ref
                              .read(waterIntakeProvider.notifier)
                              .update((s) => s + 1);
                          _syncWaterToHealth(ref, 1);
                        },
                        onDecrement: () {
                          final current = ref.read(waterIntakeProvider);
                          if (current <= 0) return;
                          ref
                              .read(waterIntakeProvider.notifier)
                              .update((s) => s > 0 ? s - 1 : 0);
                          _syncWaterToHealth(ref, -1);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- Quick Log (saved meals — self-gates on availability) ---
                const SavedMealsQuickLog(),
                const SizedBox(height: 16),

                // --- Supplements Checklist ---
                const SupplementChecklistCard(),
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
                      child: _QuickActionButton(
                        label: '+ Log Meal',
                        onPressed: () => context.go('/nutrition'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionButton(
                        label: '+ Log Workout',
                        onPressed: () => context.go('/workouts'),
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

/// One glass of water in our UI represents 250 ml. Apple Health takes liters.
const _kGlassLiters = 0.25;

/// Debounced water sync. Rapid taps coalesce into one write 2s after the last
/// change, with the [glassDelta] passed reflecting the net change since the
/// last flush.
class _WaterSyncDebouncer {
  Timer? _timer;
  int _pendingGlasses = 0;

  void schedule(WidgetRef ref, int delta) {
    _pendingGlasses += delta;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () => _flush(ref));
  }

  void _flush(WidgetRef ref) {
    final glasses = _pendingGlasses;
    _pendingGlasses = 0;
    if (glasses <= 0) return; // Only write positive deltas — HealthKit doesn't
    // support negative water entries.
    ref
        .read(healthServiceProvider)
        .writeWater(glasses * _kGlassLiters); // fire-and-forget
  }
}

final _waterDebouncer = _WaterSyncDebouncer();

void _syncWaterToHealth(WidgetRef ref, int delta) {
  if (!ref.read(healthConnectedProvider)) return;
  if (!ref.read(healthPrefsProvider).syncWater) return;
  _waterDebouncer.schedule(ref, delta);
}

// ---------------------------------------------------------------------------
// Stats Row
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.caloriesBurned,
    required this.workoutMinutes,
  });

  final num caloriesBurned;
  final int? workoutMinutes;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.directions_walk,
            value: '—',
            label: 'Steps',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: NutrientIcons.caloriesIcon,
            value: caloriesBurned.toInt().toString(),
            label: 'kcal',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.timer,
            value: workoutMinutes != null ? '${workoutMinutes}m' : '—',
            label: 'Minutes',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.of(context).accent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Action Button
// ---------------------------------------------------------------------------

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 14),
      color: AppColors.of(context).accent,
      borderRadius: BorderRadius.circular(12),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Insights section
// ---------------------------------------------------------------------------

/// Renders up to 3 local-analysis insight cards. Self-collapses when there's
/// nothing to show so the dashboard doesn't carry an empty section. A "See
/// All" link appears only when the service produced 4+ insights (the list is
/// already capped at 5 inside [InsightService.generate]) — currently routes
/// to the AI Coach, which is the natural destination for follow-up Q&A.
class _InsightsSection extends ConsumerWidget {
  const _InsightsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardInsightsProvider);
    final insights = async.valueOrNull;
    if (insights == null || insights.isEmpty) {
      return const SizedBox.shrink();
    }
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final visible = insights.take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Insights',
            style: textTheme.titleMedium?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 10),
          // Horizontal scroll row — compact cards styled like the activity
          // row. Card width ~220 keeps two cards visible on most phones so
          // users notice there's more to swipe to.
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) =>
                  _InsightCard(insight: visible[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final Insight insight;

  /// Accent colour per insight type. The body palette already exposes
  /// success/warning/accent — we route them by type so positives feel light,
  /// warnings feel alert-y, and suggestions feel informational.
  Color _accentFor(BuildContext context) {
    final palette = AppColors.of(context);
    switch (insight.type) {
      case InsightType.positive:
        return palette.success;
      case InsightType.warning:
        return palette.warning;
      case InsightType.suggestion:
        return palette.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final accent = _accentFor(context);

    final card = Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(insight.icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  insight.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insight.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: palette.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (insight.route == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(insight.route!),
      child: card,
    );
  }
}
