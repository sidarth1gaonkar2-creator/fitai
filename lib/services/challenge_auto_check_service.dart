import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../core/utils/logger.dart';
import '../features/community/data/challenge_repository.dart';
import '../features/community/domain/challenge.dart';
import '../models/workout.dart';
import 'health_service.dart';
import 'notification_service.dart';

/// Walks the user's active challenges and, for each one whose [trackingMode]
/// is automatable, reads today's value from HealthKit / Isar and calls
/// `ChallengeRepository.checkIn` if the daily goal has been met.
///
/// Designed to be cheap and idempotent — `checkIn` already short-circuits
/// when a participant has already checked in for the current day, so it's
/// safe to call this on every app launch and every navigation into the
/// Challenges screen.
class ChallengeAutoCheckService {
  ChallengeAutoCheckService({
    required HealthService healthService,
    required ChallengeRepository challengeRepository,
    required NotificationService notificationService,
    required Isar isar,
  })  : _health = healthService,
        _repo = challengeRepository,
        _notifications = notificationService,
        _isar = isar;

  final HealthService _health;
  final ChallengeRepository _repo;
  final NotificationService _notifications;
  final Isar _isar;

  /// Iterates the user's joined challenges and auto-checks any whose
  /// per-day goal has been hit. Errors on individual challenges are logged
  /// and swallowed so one broken row can't stop the loop.
  Future<void> checkActiveChallenges(String userId) async {
    List<Challenge> challenges;
    try {
      challenges = await _repo.getMyChallenges(userId);
    } catch (e, st) {
      AppLogger.error('Auto-check: getMyChallenges failed',
          error: e, stack: st);
      return;
    }

    for (final challenge in challenges) {
      if (!challenge.isActive) continue;
      if (!challenge.isAutoTracked) continue;
      final goal = challenge.dailyGoalValue;
      if (goal == null || goal <= 0) continue;

      try {
        final value = await _todayValue(challenge.trackingMode);
        if (value < goal) continue;
        final participant =
            await _repo.getParticipant(challenge.challengeId, userId);
        if (participant == null) continue;
        if (_alreadyCheckedInToday(participant.lastCheckInDate)) continue;

        await _repo.checkIn(challenge: challenge, userId: userId);
        await _notifications.notifyChallengeGoalReached(
          challengeTitle: challenge.title,
        );
        debugPrint(
          '[ChallengeAutoCheck] checked in "${challenge.title}" '
          '(value=$value / goal=$goal)',
        );
      } catch (e, st) {
        AppLogger.error(
          'Auto-check failed for "${challenge.title}"',
          error: e,
          stack: st,
        );
      }
    }
  }

  Future<double> _todayValue(ChallengeTrackingMode mode) async {
    switch (mode) {
      case ChallengeTrackingMode.autoSteps:
        return (await _health.getTodaySteps()).toDouble();
      case ChallengeTrackingMode.autoCalories:
        return _health.getTodayCaloriesBurned();
      case ChallengeTrackingMode.autoWorkouts:
        return (await _todayWorkoutCount()) >= 1 ? 1 : 0;
      case ChallengeTrackingMode.autoWater:
        // Local water tracker (StateProvider<int> on dashboard) is session-
        // scoped and not persisted; we don't have a persisted water value
        // yet. Return 0 and let the caller wire this up when the water
        // tracker is migrated to Isar / a daily total.
        return 0;
      case ChallengeTrackingMode.manual:
        return 0;
    }
  }

  Future<int> _todayWorkoutCount() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _isar.workouts
        .filter()
        .dateBetween(start, end, includeUpper: false)
        .count();
  }

  bool _alreadyCheckedInToday(DateTime? last) {
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }
}
