---
name: Notifications System
description: Local notifications for workout reminders, meals, water, streak protection, supplements, and PR celebrations
type: project
---

## Service (lib/services/notification_service.dart)

NotificationService singleton using flutter_local_notifications + timezone.

### Notification Channels & IDs
- **100-106:** Workout reminders (weekly by day of week)
- **200-202:** Meal reminders (breakfast, lunch, dinner)
- **300-314:** Water reminders (hourly 8am–10pm)
- **400:** Streak protection reminder (8pm)
- **450:** PR celebration notification
- **500+:** Supplement reminders

### Methods
- scheduleWorkoutReminder(days, hour, minute)
- scheduleMealReminder(mealIndex, hour, minute)
- scheduleWaterReminders()
- scheduleStreakReminder()
- showPRNotification(exerciseName, weight)
- scheduleSupplementReminder()
- requestPermission()

## Providers (lib/providers/notification_providers.dart)

**NotificationSettings** class — All notification flags and schedule times
**NotificationSettingsNotifier** (StateNotifier) — Persists to SharedPreferences

- `notificationSettingsProvider` — Current settings state
- `notificationPermissionProvider` — Permission status
- `_syncSchedules()` — Auto-schedules/cancels based on current settings

### SharedPreferences Keys
- notif_workout_enabled, notif_workout_days, notif_workout_hour/minute
- notif_breakfast/lunch/dinner_enabled + times
- notif_water_enabled, notif_streak_enabled
- notif_pr_enabled (default true), notif_supplement_enabled

## Screen
- **NotificationSettingsScreen** — Comprehensive notification management UI with toggles and time pickers for each category

## Packages
- flutter_local_notifications: ^21.0.0
- timezone: ^0.11.0
- shared_preferences: ^2.3.4
