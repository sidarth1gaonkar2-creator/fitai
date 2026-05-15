import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Theme;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../providers/health_providers.dart';

/// Recent Apple Fitness / 3rd-party workouts pulled from HealthKit. Rendered
/// as a Cupertino card on the dashboard. The card collapses entirely (no
/// SizedBox.shrink takes space) when the user is not on iOS, not connected,
/// or has no workouts in the lookback window.
class FitnessWorkoutsCard extends ConsumerWidget {
  const FitnessWorkoutsCard({super.key});

  static const _maxRows = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isIOS) return const SizedBox.shrink();
    if (!ref.watch(healthConnectedProvider)) return const SizedBox.shrink();
    final async = ref.watch(recentFitnessWorkoutsProvider);

    return async.when(
      loading: () => const ShimmerCard(height: 120),
      error: (_, _) => const SizedBox.shrink(),
      data: (rows) {
        if (rows.isEmpty) return const SizedBox.shrink();
        final palette = AppColors.of(context);
        final textTheme = Theme.of(context).textTheme;
        final shown = rows.take(_maxRows).toList();

        return CupertinoCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Row(
                  children: [
                    Icon(Icons.favorite, size: 16, color: palette.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Activity',
                      style: textTheme.bodyMedium?.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Apple Health',
                      style: textTheme.labelSmall
                          ?.copyWith(color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
              for (int i = 0; i < shown.length; i++) ...[
                if (i > 0)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: palette.separator,
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
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: palette.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${timeago.format(start, locale: 'en_short')}'
                  '${source.isNotEmpty ? ' · $source' : ''}',
                  style: textTheme.bodySmall
                      ?.copyWith(color: palette.textSecondary),
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
                '${durationMinutes}m',
                style: textTheme.bodyMedium?.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (calories > 0)
                Text(
                  '$calories kcal',
                  style: textTheme.bodySmall
                      ?.copyWith(color: palette.textSecondary),
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
