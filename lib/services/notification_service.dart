import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../core/utils/logger.dart';
import '../data/motivator_messages.dart';
import 'notification_diagnostics.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Diagnostic state captured during [init], surfaced by [collectDiagnostics]
  /// so the hidden screen can show a UTC fallback at a glance.
  String? _resolvedTimezone;
  String? _tzInitError;

  /// Whether [init] ran far enough to finish `plugin.initialize()`.
  bool get isInitialized => _initialized;

  /// Dedicated id for the on-device "fire test in 60s" probe. Chosen to sit in
  /// the gap between morning motivation (860) and the challenge range (900+) so
  /// it can never collide with a real reminder.
  static const int diagnosticTestId = 870;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    // Without this, tz.local defaults to UTC and every zonedSchedule fires at
    // the wrong wall-clock time (the root of the "wrong time / never see them"
    // reports). Resolve the device zone explicitly.
    try {
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localZone));
      _resolvedTimezone = localZone;
      AppLogger.log('[notif] local timezone set to $localZone '
          '(tz.local=${tz.local.name})');
    } catch (e, st) {
      _tzInitError = '${e.runtimeType}: $e';
      AppLogger.error('[notif] timezone resolve failed; staying on UTC',
          error: e, stack: st);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    _initialized = true;
    AppLogger.log('[notif] plugin initialized (tz.local=${_safeTzName()})');
  }

  /// `tz.local.name` without ever throwing — if the database wasn't initialized
  /// the getter throws, and we never want diagnostics collection to crash.
  String _safeTzName() {
    try {
      return tz.local.name;
    } catch (e) {
      return 'UNRESOLVED(${e.runtimeType})';
    }
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Check-only: whether the OS currently allows notifications, WITHOUT
  /// prompting. Used to surface the "enable in Settings" state when the user
  /// has a notification enabled in-app but denied it at the OS level.
  Future<bool> hasPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final opts = await ios.checkPermissions();
      return opts?.isEnabled ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return (await android.areNotificationsEnabled()) ?? false;
    }
    return true;
  }

  /// Debug aid: dumps everything currently queued so on-device TestFlight logs
  /// show exactly what's scheduled (call after a reconcile).
  Future<void> dumpPending() async {
    final pending = await _plugin.pendingNotificationRequests();
    AppLogger.log('[notif] pending count = ${pending.length}');
    for (final p in pending) {
      AppLogger.log('[notif]   pending id=${p.id} title="${p.title}"');
    }
  }

  // ─── Workout Reminders (IDs 100-106) ──────────────────────────────────────

  Future<void> scheduleWorkoutReminder({
    required List<int> days,
    required int hour,
    required int minute,
  }) async {
    for (var i = 100; i <= 106; i++) {
      await _plugin.cancel(id: i);
    }

    for (final day in days) {
      final id = 100 + (day - 1);
      await _scheduleWeekly(
        id: id,
        day: day,
        hour: hour,
        minute: minute,
        title: 'Workout Reminder',
        body: "Time to hit the gym! Your body will thank you.",
        channelId: 'workout_reminders',
        channelName: 'Workout Reminders',
      );
    }
  }

  Future<void> cancelWorkoutReminders() async {
    for (var i = 100; i <= 106; i++) {
      await _plugin.cancel(id: i);
    }
  }

  // ─── Meal Reminders (IDs 200-202) ─────────────────────────────────────────

  Future<void> scheduleMealReminder({
    required int mealIndex,
    required int hour,
    required int minute,
  }) async {
    final id = 200 + mealIndex;
    final labels = ['Breakfast', 'Lunch', 'Dinner'];
    await _scheduleDaily(
      id: id,
      hour: hour,
      minute: minute,
      title: '${labels[mealIndex]} Reminder',
      body: "Don't forget to log your ${labels[mealIndex].toLowerCase()}!",
      channelId: 'meal_reminders',
      channelName: 'Meal Reminders',
    );
  }

  Future<void> cancelMealReminder(int mealIndex) async {
    await _plugin.cancel(id: 200 + mealIndex);
  }

  // ─── Water Reminders (IDs 300-314) ────────────────────────────────────────

  Future<void> scheduleWaterReminders() async {
    for (var i = 300; i <= 314; i++) {
      await _plugin.cancel(id: i);
    }

    for (var hour = 8; hour <= 22; hour++) {
      final id = 300 + (hour - 8);
      await _scheduleDaily(
        id: id,
        hour: hour,
        minute: 0,
        title: 'Water Reminder',
        body: 'Stay hydrated! Drink a glass of water.',
        channelId: 'water_reminders',
        channelName: 'Water Reminders',
      );
    }
  }

  Future<void> cancelWaterReminders() async {
    for (var i = 300; i <= 314; i++) {
      await _plugin.cancel(id: i);
    }
  }

  // ─── Streak Protection (ID 400) ───────────────────────────────────────────

  Future<void> scheduleStreakReminder() async {
    await _scheduleDaily(
      id: 400,
      hour: 20,
      minute: 0,
      title: 'Streak Alert',
      body: "You haven't logged anything today! Keep your streak alive.",
      channelId: 'streak_reminders',
      channelName: 'Streak Reminders',
    );
  }

  Future<void> cancelStreakReminder() async {
    await _plugin.cancel(id: 400);
  }

  // ─── PR Celebration (ID 450) ──────────────────────────────────────────────

  Future<void> showPRNotification(String exerciseName, double weight) async {
    await _plugin.show(
      id: 450,
      title: 'New Personal Record!',
      body: '$exerciseName: ${weight.toStringAsFixed(1)} kg',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'pr_celebration',
          'PR Celebrations',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // ─── Supplement Reminders (IDs 500+) ──────────────────────────────────────

  Future<void> scheduleSupplementReminder({
    required int supplementId,
    required String name,
    required int hour,
    required int minute,
  }) async {
    final id = 500 + supplementId;
    await _scheduleDaily(
      id: id,
      hour: hour,
      minute: minute,
      title: 'Supplement Reminder',
      body: "Time to take your $name!",
      channelId: 'supplement_reminders',
      channelName: 'Supplement Reminders',
    );
  }

  Future<void> cancelSupplementReminder(int supplementId) async {
    await _plugin.cancel(id: 500 + supplementId);
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      AppLogger.log('[notif] scheduled daily id=$id at '
          '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')} ($title)');
    } catch (e, st) {
      AppLogger.error('[notif] failed to schedule daily id=$id',
          error: e, stack: st);
    }
  }

  Future<void> _scheduleWeekly({
    required int id,
    required int day,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    while (scheduled.weekday != day) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      AppLogger.log('[notif] scheduled weekly id=$id day=$day at '
          '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')} ($title)');
    } catch (e, st) {
      AppLogger.error('[notif] failed to schedule weekly id=$id',
          error: e, stack: st);
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    AppLogger.log('[notif] cancelled ALL pending notifications');
  }

  // ───────────────────────────────────────────────────────────────────────
  // Smart streak protection (IDs 800-801)
  //
  // The plain [scheduleStreakReminder] above still ships untouched (it's
  // tied to existing user settings). [scheduleStreakReminderSmart] is the
  // newer variant that respects rest days and current streak length, and
  // is what new code should call.
  // ───────────────────────────────────────────────────────────────────────

  static const _streakSoftId = 800;
  static const _streakHardId = 801;

  Future<void> scheduleStreakReminderSmart({
    required int currentStreak,
    required DateTime? lastWorkoutDate,
    required Set<int> restDays,
  }) async {
    final now = DateTime.now();
    final todayWeekday = now.weekday - 1; // 0=Mon..6=Sun

    // Always start by clearing — we may end up scheduling nothing on rest
    // days or when there is no streak to protect.
    await _plugin.cancel(id: _streakSoftId);
    await _plugin.cancel(id: _streakHardId);

    if (restDays.contains(todayWeekday)) return;
    if (currentStreak <= 0) return;

    final daysSinceWorkout = lastWorkoutDate == null
        ? 999
        : now.difference(lastWorkoutDate).inDays;

    if (daysSinceWorkout >= 1) {
      // 6 PM gentle reminder if no workout yet today.
      await _scheduleDaily(
        id: _streakSoftId,
        hour: 18,
        minute: 0,
        title: 'Streak Alert',
        body:
            'Your $currentStreak-day streak is still going! Log a workout '
            'today to keep it alive.',
        channelId: 'streak_reminders',
        channelName: 'Streak Reminders',
      );
    }
    if (daysSinceWorkout >= 2) {
      // Immediate "about to break" toast.
      await _plugin.show(
        id: _streakHardId,
        title: 'Streak about to break',
        body:
            'Your $currentStreak-day streak will break tomorrow! Squeeze in a '
            'quick workout to save it.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'streak_reminders',
            'Streak Reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // Challenge reminders (IDs 900-999)
  // ───────────────────────────────────────────────────────────────────────

  static int _challengeIdFromKey(String challengeId) =>
      900 + challengeId.hashCode.abs() % 100;

  Future<void> scheduleChallengeReminder({
    required String challengeId,
    required String challengeTitle,
    required int daysRemaining,
    required bool requiresPhotoProof,
    required bool isAutoTracked,
  }) async {
    final id = _challengeIdFromKey(challengeId);
    final body = isAutoTracked
        ? 'Auto-tracked via Apple Health — $daysRemaining days left.'
        : requiresPhotoProof
            ? "Don't forget to log today with a photo. "
                '$daysRemaining days left.'
            : 'Keep going — $daysRemaining days remaining.';
    await _scheduleDaily(
      id: id,
      hour: 9,
      minute: 0,
      title: challengeTitle,
      body: body,
      channelId: 'challenge_reminders',
      channelName: 'Challenge Reminders',
    );
  }

  Future<void> cancelChallengeReminder(String challengeId) async {
    await _plugin.cancel(id: _challengeIdFromKey(challengeId));
  }

  Future<void> notifyChallengeGoalReached({
    required String challengeTitle,
  }) async {
    await _plugin.show(
      id: 950,
      title: 'Daily Goal Met!',
      body: 'You\'ve hit your "$challengeTitle" goal for today. Keep it up!',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'challenge_reminders',
          'Challenge Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> notifyChallengeComplete({
    required String challengeTitle,
  }) async {
    await _plugin.show(
      id: 951,
      title: 'Challenge Complete',
      body:
          'Amazing! You\'ve completed "$challengeTitle". Share your win with '
          'the community.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'challenge_reminders',
          'Challenge Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // Drill Sergeant / Toxic Motivator (IDs 850-853 daily, 860 morning)
  //
  // Opt-in personality. Picks aggressive messages from [MotivatorMessages]
  // based on days-since-last-workout, and skips entirely on configured rest
  // days. Intensity controls how many daily slots are scheduled.
  // ───────────────────────────────────────────────────────────────────────

  static const _drillSergeantIds = [850, 851, 852, 853];

  /// Public so the diagnostics screen can check whether the morning-motivation
  /// reminder actually landed in the OS pending queue (the failure under
  /// investigation in Build 77 is specific to this id).
  static const int morningMotivationId = 860;
  static const _morningMotivationId = morningMotivationId;

  /// Slot times per intensity level. Hours are 24h local time.
  ///   1 = Mild Roast      → 1 notification (6 PM)
  ///   2 = Medium Roast    → 2 notifications (12 PM + 6 PM)
  ///   3 = Full Savage     → 4 notifications (10 AM, 12 PM, 5 PM, 7 PM)
  static const _intensityHours = {
    1: <int>[18],
    2: <int>[12, 18],
    3: <int>[10, 12, 17, 19],
  };

  /// Schedules the Drill Sergeant's daily roasts. Always cancels any
  /// previously-scheduled ids before reinstalling — callers should invoke
  /// this on every app launch (and whenever streak / settings change) to
  /// keep the slots fresh.
  ///
  /// [restDays] uses 0-indexed weekdays (Mon = 0 … Sun = 6). On a rest day
  /// nothing is scheduled — even the Drill Sergeant respects recovery.
  Future<void> scheduleDrillSergeantReminders({
    required int currentStreak,
    required DateTime? lastWorkoutDate,
    required Set<int> restDays,
    required int intensity,
  }) async {
    for (final id in _drillSergeantIds) {
      await _plugin.cancel(id: id);
    }

    final now = DateTime.now();
    final todayWeekday = now.weekday - 1;
    if (restDays.contains(todayWeekday)) {
      AppLogger.log('[notif] drill sergeant: rest day — nothing scheduled');
      return;
    }

    final daysSince = lastWorkoutDate == null
        ? 999
        : now.difference(lastWorkoutDate).inDays;
    if (daysSince <= 0) {
      AppLogger.log(
          '[notif] drill sergeant: worked out today — nothing scheduled');
      return; // worked out today — nothing to nag about
    }

    final category = MotivatorMessages.missedCategoryFor(daysSince);
    final hours =
        _intensityHours[intensity.clamp(1, 3)] ?? _intensityHours[1]!;

    for (var i = 0; i < hours.length && i < _drillSergeantIds.length; i++) {
      // One fresh roast per slot — different message at noon vs 7 PM keeps
      // it from feeling like spam.
      await _scheduleDaily(
        id: _drillSergeantIds[i],
        hour: hours[i],
        minute: 0,
        title: 'Drill Sergeant',
        body: MotivatorMessages.random(
          category,
          streakCount: currentStreak,
        ),
        channelId: 'drill_sergeant',
        channelName: 'Drill Sergeant',
      );
    }
  }

  Future<void> cancelDrillSergeantReminders() async {
    for (final id in _drillSergeantIds) {
      await _plugin.cancel(id: id);
    }
    AppLogger.log('[notif] cancelled drill sergeant reminders');
  }

  /// Daily morning pep-talk delivered at the user's chosen [hour]/[minute].
  /// Picked from [MotivatorCategory.morningMotivation] so it stays in
  /// character even when the user did work out the day before.
  Future<void> scheduleMorningMotivation({
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(id: _morningMotivationId);
    await _scheduleDaily(
      id: _morningMotivationId,
      hour: hour,
      minute: minute,
      title: 'Wake up',
      body: MotivatorMessages.random(MotivatorCategory.morningMotivation),
      channelId: 'drill_sergeant',
      channelName: 'Drill Sergeant',
    );
  }

  Future<void> cancelMorningMotivation() async {
    await _plugin.cancel(id: _morningMotivationId);
    AppLogger.log('[notif] cancelled morning motivation');
  }

  /// Aggressive replacement for [showPRNotification] used when the user has
  /// the Drill Sergeant personality enabled. Same id (450) so the gentler
  /// version isn't queued alongside it.
  Future<void> showDrillSergeantPRNotification(
      String exerciseName, double weight) async {
    await _plugin.show(
      id: 450,
      title: 'NEW PR',
      body:
          '${MotivatorMessages.random(MotivatorCategory.prCelebration)}\n'
          '$exerciseName · ${weight.toStringAsFixed(1)} kg',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'drill_sergeant',
          'Drill Sergeant',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // On-device diagnostics (hidden Notification Diagnostics screen)
  //
  // We have NO console access on TestFlight, so these surface the entire
  // schedule pipeline on the device itself: the resolved timezone (to catch a
  // silent UTC fallback), the live OS permission, the real pending queue with
  // trigger dates, and a fire-test that returns any zonedSchedule exception
  // text instead of swallowing it.
  // ───────────────────────────────────────────────────────────────────────

  /// Snapshot every fact the diagnostics screen renders. Never throws — any
  /// failure is captured into [NotifDiagnostics.collectError].
  Future<NotifDiagnostics> collectDiagnostics() async {
    String tzLive;
    String? tzLiveError;
    try {
      tzLive = await FlutterTimezone.getLocalTimezone();
    } catch (e) {
      tzLive = '(unavailable)';
      tzLiveError = '${e.runtimeType}: $e';
    }

    bool? permEnabled;
    var permDetail = 'unknown';
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final opts = await ios.checkPermissions();
        permEnabled = opts?.isEnabled;
        if (opts != null) {
          permDetail = 'alert=${opts.isAlertEnabled} '
              'badge=${opts.isBadgeEnabled} sound=${opts.isSoundEnabled} '
              'provisional=${opts.isProvisionalEnabled} '
              'critical=${opts.isCriticalEnabled}';
        } else {
          permDetail = 'checkPermissions() returned null';
        }
      } else {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (android != null) {
          permEnabled = await android.areNotificationsEnabled();
          permDetail = 'android areNotificationsEnabled=$permEnabled';
        }
      }
    } catch (e) {
      permDetail = 'permission check failed: ${e.runtimeType}: $e';
    }

    final nativeAuth = await NotifNativeDiag.authorizationStatus();

    // Prefer the native queue (has trigger dates); fall back to the Dart API.
    var pendingFromNative = true;
    var pending = await NotifNativeDiag.pendingDetailed();
    if (pending == null) {
      pendingFromNative = false;
      try {
        final dart = await _plugin.pendingNotificationRequests();
        pending = dart
            .map((p) => PendingEntry(
                  id: p.id,
                  title: p.title,
                  body: p.body,
                  fromNative: false,
                ))
            .toList();
      } catch (e) {
        pending = <PendingEntry>[];
      }
    }
    pending.sort((a, b) {
      final at = a.nextTrigger, bt = b.nextTrigger;
      if (at == null && bt == null) return a.id.compareTo(b.id);
      if (at == null) return 1;
      if (bt == null) return -1;
      return at.compareTo(bt);
    });

    return NotifDiagnostics(
      collectedAt: DateTime.now(),
      pluginInitialized: _initialized,
      tzLocalName: _safeTzName(),
      tzResolvedAtInit: _resolvedTimezone,
      tzInitError: _tzInitError,
      tzLiveResolved: tzLive,
      tzLiveError: tzLiveError,
      permissionEnabled: permEnabled,
      permissionDetail: permDetail,
      nativeAuthStatus: nativeAuth,
      pending: pending,
      pendingFromNative: pendingFromNative,
      collectError: null,
    );
  }

  /// Schedules a one-shot probe 60 seconds out through the SAME
  /// [_plugin.zonedSchedule] path morning motivation uses (same channel, iOS
  /// details and Android schedule mode). Unlike the production helpers this one
  /// deliberately does NOT swallow the exception — it returns the text so the
  /// screen can show exactly why scheduling failed.
  Future<DiagTestResult> scheduleDiagnosticTest() async {
    final tzName = _safeTzName();
    tz.TZDateTime scheduled;
    try {
      scheduled =
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 60));
    } catch (e, st) {
      AppLogger.error('[notif] diag test: tz.local unusable', error: e,
          stack: st);
      return DiagTestResult(
        success: false,
        tzName: tzName,
        error: '${e.runtimeType}: $e',
        stack: st.toString(),
      );
    }

    try {
      await _plugin.zonedSchedule(
        id: diagnosticTestId,
        title: 'DrillFit test ping',
        body: 'Scheduling works. This was queued 60s ago from Diagnostics.',
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'drill_sergeant',
            'Drill Sergeant',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      AppLogger.log('[notif] diag test scheduled for '
          '${scheduled.toIso8601String()} (tz=$tzName)');
      return DiagTestResult(
        success: true,
        scheduledFor: DateTime.fromMillisecondsSinceEpoch(
            scheduled.millisecondsSinceEpoch),
        tzName: tzName,
      );
    } catch (e, st) {
      AppLogger.error('[notif] diag test FAILED to schedule',
          error: e, stack: st);
      return DiagTestResult(
        success: false,
        tzName: tzName,
        error: '${e.runtimeType}: $e',
        stack: st.toString(),
      );
    }
  }

  /// Cancels the diagnostic probe (used by the screen's "clear test" action).
  Future<void> cancelDiagnosticTest() async {
    await _plugin.cancel(id: diagnosticTestId);
  }
}
