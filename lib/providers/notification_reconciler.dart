import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/logger.dart';
import '../services/notification_service.dart';
import 'dashboard_providers.dart';
import 'drill_sergeant_providers.dart';
import 'notification_providers.dart';
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
        return;
      }

      final granted = await ns.requestPermission();
      if (!granted) {
        AppLogger.log('[notif] reconcile: ENABLED but permission DENIED — '
            'nothing will fire until the user enables it in iOS Settings');
        return;
      }

      AppLogger.log('[notif] reconcile: permission granted — syncing schedules');
      await _ref.read(notificationSettingsProvider.notifier).syncSchedules();
      await reconcileDrill();
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
        // Rest-day awareness isn't wired to a user-facing pref yet.
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
