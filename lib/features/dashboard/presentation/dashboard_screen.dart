import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold, CircularProgressIndicator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/field_manual.dart';
import '../../../core/widgets/tactical_surface.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/error_card.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/nutrition_providers.dart';
import '../../../providers/health_providers.dart';
import '../../../providers/insight_providers.dart';
import '../../../providers/gym_streak_provider.dart';
import '../../../providers/saved_meal_providers.dart';
import '../../../providers/supplement_providers.dart';
import '../../../providers/training_schedule_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../services/insight_service.dart';
import '../../ranks/domain/drill_sergeant.dart';
import '../../ranks/domain/military_ranks.dart';
import '../../ranks/providers/rank_providers.dart';
import '../../workouts/domain/streak_rewards.dart';
import 'widgets/activity_row.dart';
import 'widgets/canteen_card.dart';
import 'widgets/dashboard_skeleton.dart';
import 'widgets/fitness_workouts_card.dart';
import 'widgets/orders_block.dart';
import 'widgets/rank_strip.dart';
import 'widgets/rations_panel.dart';
import 'widgets/recon_readouts.dart';
import '../../supplements/presentation/widgets/supplement_checklist_card.dart';
import '../../tutorial/presentation/tutorial_anchor.dart';
import '../../tutorial/providers/tutorial_providers.dart';

/// The Morning Briefing — DrillFit's Field Manual dashboard. Mission-first
/// order: today's orders lead, rank and promotion progress second, nutrition
/// instruments after, Apple Health recon last. Providers and data flow are
/// unchanged from the pre-FM dashboard; this screen is presentation +
/// hierarchy.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // First-launch tutorial trigger. We delay 800ms so the dashboard's
    // loading states settle before the spotlight measures the kcal gauge —
    // otherwise the spotlight wraps the skeleton instead of the real widget.
    // `shouldShowTutorialProvider` reads SharedPreferences synchronously, so
    // we can decide without an async hop.
    //
    // Guard against a Settings replay: if the controller is already active
    // (someone navigated us here via tutorial start()), don't kick off our
    // own start() — that would reset the user back to step 0.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final controller = ref.read(tutorialControllerProvider);
      if (controller.isActive) return;
      if (!ref.read(shouldShowTutorialProvider)) return;
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      if (controller.isActive) return;
      controller.start();
    });
  }

  Future<void> _refresh() async {
    ref
      ..invalidate(todayNutritionProvider)
      ..invalidate(todayWorkoutProvider)
      ..invalidate(streakProvider)
      ..invalidate(rankCalculatorProvider)
      ..invalidate(dashboardInsightsProvider)
      ..invalidate(frequentMealsProvider)
      ..invalidate(supplementChecklistProvider);
    if (Platform.isIOS) {
      ref
        ..invalidate(dailyHealthSummaryProvider)
        ..invalidate(todayActiveCaloriesProvider)
        ..invalidate(todayActiveMinutesProvider)
        ..invalidate(todayStandHoursProvider)
        ..invalidate(recentFitnessWorkoutsProvider);
    }
    // Hold the spinner on the core day data so the pull feels honest.
    try {
      await Future.wait([
        ref.read(todayNutritionProvider.future),
        ref.read(todayWorkoutProvider.future),
      ]);
    } catch (e, st) {
      AppLogger.error('Dashboard refresh failed', error: e, stack: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final nutritionAsync = ref.watch(todayNutritionProvider);
    final workoutAsync = ref.watch(todayWorkoutProvider);
    final streakAsync = ref.watch(streakProvider);
    // Schedule-aware gym streak: when a training schedule is configured, the
    // orders chip shows THIS (with its coin multiplier) instead of the
    // any-activity streak.
    final schedule = ref.watch(trainingScheduleProvider);
    final gymStreak = ref.watch(gymStreakProvider);
    final glasses = ref.watch(waterIntakeProvider);
    // Drill-sergeant greeting addresses the soldier by rank. Falls back to
    // Private while the rank is still computing.
    final overallRank =
        ref.watch(overallRankProvider).valueOrNull ?? MilitaryRank.private_e1;

    return profileAsync.when(
      loading: () => _shell(
        title: const Text('Dashboard'),
        body: const DashboardSkeleton(),
      ),
      error: (e, _) => _shell(
        title: const Text('Dashboard'),
        body: ErrorCard(
          message: 'Could not load your dashboard.',
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
      ),
      data: (profile) {
        if (profile == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/onboarding');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final targets = resolveDailyTargets(profile);
        final nutrition = nutritionAsync.valueOrNull;
        final workout = workoutAsync.valueOrNull;

        // Burned calories from Apple Health (0 unless connected + toggle on).
        final dashboardHealthOn = ref.watch(healthDashboardEnabledProvider);
        final burnedAsync = ref.watch(todayActiveCaloriesProvider);
        final burned =
            dashboardHealthOn ? (burnedAsync.valueOrNull ?? 0.0) : 0.0;

        final isNutritionLoading =
            nutritionAsync.isLoading && !nutritionAsync.hasValue;
        final isWorkoutLoading =
            workoutAsync.isLoading && !workoutAsync.hasValue;

        final now = DateTime.now();
        final isRestDay =
            schedule.isConfigured && !schedule.isScheduledGymDay(now);
        final streak = schedule.isConfigured
            ? gymStreak.currentStreak
            : (streakAsync.valueOrNull ?? 0);
        final multiplier = schedule.isConfigured && streak > 0
            ? streakMultiplier(streak)
            : null;

        return _shell(
          title: Text(
            drillGreeting(
              hour: now.hour,
              rank: overallRank,
              name: firstNameOf(profile.name),
              compact: true,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: FieldManual.body(fontSize: 15),
          ),
          body: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              CupertinoSliverRefreshControl(onRefresh: _refresh),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    OrdersBlock(
                      workout: workout,
                      isRestDay: isRestDay,
                      streak: streak,
                      multiplier: multiplier,
                      loading: isWorkoutLoading,
                    ),
                    const SizedBox(height: 12),
                    const RankStrip(),
                    const SizedBox(height: 12),
                    RationsPanel(
                      calories: (nutrition?.totalCalories ?? 0).toDouble(),
                      calorieTarget: targets.calories,
                      burned: burned,
                      protein: (nutrition?.totalProtein ?? 0).toDouble(),
                      proteinTarget: targets.protein,
                      carbs: (nutrition?.totalCarbs ?? 0).toDouble(),
                      carbsTarget: targets.carbs,
                      fat: (nutrition?.totalFat ?? 0).toDouble(),
                      fatTarget: targets.fat,
                      loading: isNutritionLoading,
                    ),
                    const SizedBox(height: 12),
                    CanteenCard(
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
                    const SizedBox(height: 12),
                    const SupplementChecklistCard(),
                    const _SergeantSaysSection(),
                    // Recon — Apple Health, last by design: rank and the day's
                    // mission outrank borrowed data. Each widget self-gates on
                    // platform/connection and collapses to zero height.
                    if (Platform.isIOS) ...[
                      const SizedBox(height: 20),
                      const ReconReadouts(),
                      const SizedBox(height: 12),
                      const ActivityRow(),
                      const SizedBox(height: 12),
                      const FitnessWorkoutsCard(),
                    ],
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Common Field Manual scaffold: ink surface, hairline-bordered blurred nav
  /// bar, chat + settings actions.
  Widget _shell({required Widget title, required Widget body}) {
    return Scaffold(
      backgroundColor: FieldManual.scaffold,
      appBar: CupertinoNavigationBar(
        middle: DefaultTextStyle.merge(
          style: FieldManual.body(fontSize: 15),
          child: title,
        ),
        backgroundColor: FieldManual.ink.withValues(alpha: 0.82),
        border: const Border(
          bottom: BorderSide(color: FieldManual.hairline),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.all(8),
              onPressed: () => context.push('/ai-coach'),
              child: const Icon(
                CupertinoIcons.chat_bubble_fill,
                size: 22,
                color: FieldManual.bone,
                semanticLabel: 'AI Coach',
              ),
            ),
            TutorialAnchor(
              id: 'settings_gear',
              child: CupertinoButton(
                padding: const EdgeInsets.all(8),
                onPressed: () => context.push('/settings'),
                child: const Icon(
                  CupertinoIcons.gear,
                  size: 22,
                  color: FieldManual.bone,
                  semanticLabel: 'Settings',
                ),
              ),
            ),
          ],
        ),
      ),
      body: SkinBackground(child: body),
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
// Sergeant Says — the insights strip, in the persona's voice
// ---------------------------------------------------------------------------

/// Renders up to 3 local-analysis insight cards under a "SERGEANT SAYS"
/// header. Self-collapses when there's nothing to show. Insight type speaks
/// through the icon color only — positive brass, warning alert, suggestion
/// olive — so the panel keeps one voice.
class _SergeantSaysSection extends ConsumerWidget {
  const _SergeantSaysSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardInsightsProvider);
    final insights = async.valueOrNull;
    if (insights == null || insights.isEmpty) {
      return const SizedBox.shrink();
    }
    final visible = insights.take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('SERGEANT SAYS', style: FieldManual.label(fontSize: 10)),
          const SizedBox(height: 10),
          // Horizontal scroll row; ~240dp cards keep two visible on most
          // phones so users notice there's more to swipe to.
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _InsightCard(insight: visible[i]),
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

  Color _iconColor(BuildContext context) => switch (insight.type) {
        // Positive wears the live accent (brass on the default issue).
        InsightType.positive => AppColors.of(context).accent,
        InsightType.warning => FieldManual.alert,
        InsightType.suggestion => FieldManual.olive,
      };

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FieldManual.field,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FieldManual.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(insight.icon, color: _iconColor(context), size: 18),
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
                  style: FieldManual.title(),
                ),
                const SizedBox(height: 3),
                Text(
                  insight.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: FieldManual.body(
                    color: FieldManual.mutedBone,
                    fontSize: 11,
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
