import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/logger.dart';
import '../core/utils/scoped_prefs.dart';
import '../data/retention_messages.dart';
import '../features/ranks/domain/military_ranks.dart';
import '../features/ranks/providers/rank_providers.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';
import 'dashboard_providers.dart';
import 'drill_sergeant_providers.dart';
import 'notification_providers.dart';
import 'retention_planner.dart';
import 'unit_system_provider.dart';
import 'workout_providers.dart';

/// THE single reconciler for all local notifications, run on app launch
/// (post-auth) and on sign-in. It makes the scheduled state match the user's
/// prefs, requests OS permission when needed, and never fails silently — the
/// root cause of "no notifications ever fire" was that nothing reconciled or
/// requested permission on launch.
class NotificationReconciler {
  NotificationReconciler(this._ref);

  final Ref _ref;

  /// If anything is enabled and permission is granted → (re)schedule the
  /// missing pieces; if enabled but the OS denied permission → log loudly (the
  /// UI surfaces a Settings prompt); if nothing is enabled → leave as is.
  Future<void> reconcile() async {
    try {
      final ns = NotificationService.instance;
      final settings = _ref.read(notificationSettingsProvider);
      final drill = _ref.read(drillSergeantProvider);

      final anyEnabled = settings.workoutEnabled ||
          settings.breakfastEnabled ||
          settings.lunchEnabled ||
          settings.dinnerEnabled ||
          settings.waterEnabled ||
          settings.streakEnabled ||
          drill.enabled;

      if (!anyEnabled) {
        AppLogger.log('[notif] reconcile: nothing enabled');
        await ns.cancelRetention();
        return;
      }

      final granted = await ns.requestPermission();
      if (!granted) {
        AppLogger.log('[notif] reconcile: ENABLED but permission DENIED — '
            'nothing will fire until the user enables it in iOS Settings');
        await ns.cancelRetention();
        return;
      }

      AppLogger.log('[notif] reconcile: permission granted — syncing schedules');
      await _ref.read(notificationSettingsProvider.notifier).syncSchedules();
      await reconcileDrill();
      await reconcileRetention();
      await ns.dumpPending();
    } catch (e, st) {
      AppLogger.error('[notif] reconcile failed', error: e, stack: st);
    }
  }

  /// (Re)applies the Drill Sergeant + morning-motivation schedule from current
  /// prefs. Shared by [reconcile] and the settings toggle handlers (DRY).
  Future<void> reconcileDrill() async {
    try {
      final ns = NotificationService.instance;
      final drill = _ref.read(drillSergeantProvider);
      if (!drill.enabled) {
        await ns.cancelDrillSergeantReminders();
        await ns.cancelMorningMotivation();
        return;
      }
      final streak = _ref.read(streakProvider).valueOrNull ?? 0;
      final workouts = _ref.read(allWorkoutsProvider).valueOrNull ?? const [];
      final lastWorkoutDate = workouts.isNotEmpty ? workouts.first.date : null;
      await ns.scheduleDrillSergeantReminders(
        currentStreak: streak,
        lastWorkoutDate: lastWorkoutDate,
        // Rest-day awareness isn't wired to a user-facing pref yet. When it is
        // (PR4b), convert the 1-based model rest-days to this scheduler's 0-based
        // form via restDaysToNotificationWeekdays (notification_providers.dart) —
        // the only sanctioned crossing of the two conventions.
        restDays: const <int>{},
        intensity: drill.intensity,
      );
      if (drill.morningEnabled) {
        await ns.scheduleMorningMotivation(
          hour: drill.morningHour,
          minute: drill.morningMinute,
        );
      } else {
        await ns.cancelMorningMotivation();
      }
    } catch (e, st) {
      AppLogger.error('[notif] reconcileDrill failed', error: e, stack: st);
    }
  }

  /// (Re)plans the retention campaign (feature/retention-notifications).
  /// Gated under the Drill Sergeant switch + intensity (Decision 1). Runs on
  /// every reconcile (launch/sign-in) and whenever the drill prefs change.
  /// Each run cancels the whole retention band first, then re-schedules today's
  /// eligible campaigns (capped/clamped by [RetentionPlanner]) plus the future
  /// Recall notifications, anchored to THIS app-open (darkness baseline).
  Future<void> reconcileRetention() async {
    try {
      final ns = NotificationService.instance;
      final drill = _ref.read(drillSergeantProvider);

      // Always start clean — retention is fully re-planned each run.
      await ns.cancelRetention();

      // Gate: no Drill Sergeant → no retention. Reset the recall hard-stop so a
      // later re-enable starts fresh.
      if (!drill.enabled) {
        await _resetRecallState();
        return;
      }

      final now = DateTime.now();

      // This reconcile == an app-open: reset the recall counter AND exhausted
      // flag and re-baseline darkness to now (the tested RetentionRecall
      // .onAppOpen() semantics, persisted).
      await _recordAppOpenResetRecall(now);

      final settings = _ref.read(notificationSettingsProvider);
      final streak = _ref.read(streakProvider).valueOrNull ?? 0;
      final workouts = _ref.read(allWorkoutsProvider).valueOrNull ?? const [];
      final lastWorkoutDate = workouts.isNotEmpty ? workouts.first.date : null;
      // Match reconcileDrill's day math: daysSince <= 0 means "today".
      final daysSince = lastWorkoutDate == null
          ? 999
          : now.difference(lastWorkoutDate).inDays;
      final workedOutToday = daysSince <= 0;

      final snapshot = RetentionSnapshot(
        drillEnabled: true,
        intensity: drill.intensity,
        now: now,
        streak: streak,
        workedOutToday: workedOutToday,
        trainingWeekdays: settings.workoutDays.toSet(),
        restWeekdays: settings.restDays,
        drillSlotHours: _drillHoursToday(
          intensity: drill.intensity,
          workedOutToday: workedOutToday,
        ),
        rank: _rankProximity(),
      );

      for (final n in RetentionPlanner.planToday(snapshot)) {
        await ns.scheduleRetentionToday(n);
      }

      // Recall (D1/D2) — future-dated, anchored to this app-open. If the user
      // stays dark they fire at +3d/+7d; the next app-open cancels + re-baselines.
      final c3 = RetentionPlanner.recallCopy(
          RetentionCampaign.recallDay3, drill.intensity);
      final c7 = RetentionPlanner.recallCopy(
          RetentionCampaign.recallDay7, drill.intensity);
      await ns.scheduleRetentionAt(
        id: kRetRecallDay3Id,
        whenLocal: RetentionPlanner.recallDay3Fire(now),
        title: c3.title,
        body: c3.body,
        route: kRouteDashboard,
      );
      await ns.scheduleRetentionAt(
        id: kRetRecallDay7Id,
        whenLocal: RetentionPlanner.recallDay7Fire(now),
        title: c7.title,
        body: c7.body,
        route: kRouteDashboard,
      );
    } catch (e, st) {
      AppLogger.error('[notif] reconcileRetention failed', error: e, stack: st);
    }
  }

  /// Hours the Drill Sergeant will occupy today, so a retention slot never
  /// stacks in the same hour (de-dupe). Mirrors NotificationService's
  /// intensity→hours map; empty when the sergeant schedules nothing today.
  List<int> _drillHoursToday({
    required int intensity,
    required bool workedOutToday,
  }) {
    if (workedOutToday) return const []; // sergeant stays quiet after a workout
    switch (intensity.clamp(1, 3)) {
      case 2:
        return const [12, 18];
      case 3:
        return const [10, 12, 17, 19];
      default:
        return const [18];
    }
  }

  /// Rank proximity from the strength-based overall points (continuous 0–9;
  /// floor = current rank index, fractional part = progress to next). Null
  /// until the first rank calculation lands — Rank Push simply waits a cycle.
  RankProximity? _rankProximity() {
    final calc = _ref.read(rankCalculatorProvider).valueOrNull;
    if (calc == null) return null;
    final points = calc.overallPoints;
    final floor = points.floor();
    final maxIndex = MilitaryRank.values.length - 1;
    if (floor >= maxIndex) {
      return const RankProximity(
          nextRankName: '', fractionToNext: 0, atMax: true);
    }
    return RankProximity(
      nextRankName: rankFromIndex(floor + 1).displayName,
      fractionToNext: points - floor,
      atMax: false,
    );
  }

  // ── Recall hard-stop persistence (uid-scoped) ────────────────────────────
  static const _kRecallUnanswered = 'retention_recall_unanswered';
  static const _kRecallExhausted = 'retention_recall_exhausted';
  static const _kRecallLastOpen = 'retention_last_app_open';

  /// Persists RetentionRecall.onAppOpen() — resets the counter AND exhausted
  /// flag — and records the darkness baseline (this open).
  Future<void> _recordAppOpenResetRecall(DateTime now) async {
    final uid = _ref.read(currentUserIdProvider);
    if (uid == null) return;
    final prefs = _ref.read(sharedPreferencesProvider);
    final reset = RetentionRecall.onAppOpen();
    await prefs.setInt(scopedKey(_kRecallUnanswered, uid), reset.unanswered);
    await prefs.setBool(scopedKey(_kRecallExhausted, uid), reset.exhausted);
    await prefs.setInt(
        scopedKey(_kRecallLastOpen, uid), now.millisecondsSinceEpoch);
  }

  Future<void> _resetRecallState() async {
    final uid = _ref.read(currentUserIdProvider);
    if (uid == null) return;
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.remove(scopedKey(_kRecallUnanswered, uid));
    await prefs.remove(scopedKey(_kRecallExhausted, uid));
    await prefs.remove(scopedKey(_kRecallLastOpen, uid));
  }

  /// Scheduled notifications are personal — cancel them all on sign-out so the
  /// next account on the device doesn't inherit them.
  Future<void> cancelPersonal() async {
    try {
      await NotificationService.instance.cancelAll();
    } catch (e, st) {
      AppLogger.error('[notif] cancelPersonal failed', error: e, stack: st);
    }
  }
}

final notificationReconcilerProvider = Provider<NotificationReconciler>((ref) {
  return NotificationReconciler(ref);
});
