import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

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
    } catch (e) {
      debugPrint('[NotificationService] Failed to schedule daily ($id): $e');
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
    } catch (e) {
      debugPrint('[NotificationService] Failed to schedule weekly ($id): $e');
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
