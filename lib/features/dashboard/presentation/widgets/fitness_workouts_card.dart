import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/field_manual.dart';
import '../../../../providers/health_providers.dart';

/// Recent Apple Fitness / 3rd-party workouts pulled from HealthKit, rendered
/// as a Field Manual list panel. Collapses entirely when the user is not on
/// iOS, not connected, or has no workouts in the lookback window.
class FitnessWorkoutsCard extends ConsumerWidget {
  const FitnessWorkoutsCard({super.key});

  static const _maxRows = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isIOS) return const SizedBox.shrink();
    if (!ref.watch(healthConnectedProvider)) return const SizedBox.shrink();
    final async = ref.watch(recentFitnessWorkoutsProvider);

    return async.when(
      loading: () => Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.of(context).surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FieldManual.hairline),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (rows) {
        if (rows.isEmpty) return const SizedBox.shrink();
        final shown = rows.take(_maxRows).toList();

        return Container(
          decoration: BoxDecoration(
            color: AppColors.of(context).surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FieldManual.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'RECENT ACTIVITY',
                        style: FieldManual.label(fontSize: 9),
                      ),
                    ),
                    Text(
                      'APPLE HEALTH',
                      style: FieldManual.label(
                        color: FieldManual.olive,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
              for (int i = 0; i < shown.length; i++) ...[
                if (i > 0)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: FieldManual.hairline,
                  ),
                _WorkoutRow(row: shown[i]),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  const _WorkoutRow({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final activity = (row['activity'] as String? ?? '').toUpperCase();
    final start = row['start'] as DateTime;
    final durationMinutes = row['durationMinutes'] as int? ?? 0;
    final calories = (row['calories'] as double? ?? 0).round();
    final source = row['source'] as String? ?? '';
    final (icon, displayName) = _iconAndName(activity);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: FieldManual.olive),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(displayName, style: FieldManual.body(fontSize: 14)),
                Text(
                  '${timeago.format(start, locale: 'en_short')}'
                  '${source.isNotEmpty ? ' · $source' : ''}',
                  style: FieldManual.body(
                    color: FieldManual.mutedBone,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$durationMinutes MIN',
                style: FieldManual.readout(fontSize: 12),
              ),
              if (calories > 0)
                Text(
                  '$calories KCAL',
                  style: FieldManual.label(fontSize: 8),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Maps a HealthKit workout activity enum name (uppercase snake_case-ish)
  /// to a Cupertino-friendly icon + human display name.
  (IconData, String) _iconAndName(String activity) {
    if (activity.contains('RUN')) return (Icons.directions_run, 'Run');
    if (activity.contains('WALK')) return (Icons.directions_walk, 'Walk');
    if (activity.contains('CYCL') || activity.contains('BIK')) {
      return (Icons.directions_bike, 'Cycle');
    }
    if (activity.contains('STRENGTH') || activity.contains('FUNCTIONAL')) {
      return (Icons.fitness_center, 'Strength');
    }
    if (activity.contains('YOGA')) {
      return (Icons.self_improvement, 'Yoga');
    }
    if (activity.contains('SWIM')) {
      return (Icons.pool, 'Swim');
    }
    if (activity.contains('HIGH_INTENSITY') || activity.contains('HIIT')) {
      return (Icons.local_fire_department, 'HIIT');
    }
    if (activity.contains('CORE') || activity.contains('PILATES')) {
      return (Icons.accessibility_new, 'Core');
    }
    return (Icons.fitness_center, 'Workout');
  }
}
