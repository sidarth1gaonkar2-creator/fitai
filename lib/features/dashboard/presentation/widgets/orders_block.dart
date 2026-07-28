import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/widgets/animated_count.dart';
import '../../../../models/workout.dart';
import '../../../ranks/domain/drill_sergeant.dart';

/// The dashboard's lead block: today's orders. Three states — train (nothing
/// logged on a training/unscheduled day), mission complete (workout logged),
/// and stand down (configured rest day). Carries the day streak as a mono
/// chip; hosts the page's single brass action.
class OrdersBlock extends StatelessWidget {
  const OrdersBlock({
    super.key,
    required this.workout,
    required this.isRestDay,
    required this.streak,
    this.multiplier,
    this.loading = false,
  });

  final Workout? workout;

  /// True when a training schedule is configured and today isn't on it.
  final bool isRestDay;

  /// Current streak (gym streak when a schedule is configured, otherwise the
  /// any-activity streak).
  final int streak;

  /// Coin multiplier for the gym streak; null hides it.
  final double? multiplier;

  final bool loading;

  /// Stable praise line for the day — random-per-rebuild copy reads as a
  /// glitch on a dashboard you revisit all day.
  static String praiseOfTheDay(DateTime now) =>
      kWorkoutPraiseLines[now.difference(DateTime(now.year)).inDays %
          kWorkoutPraiseLines.length];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FieldManual.hairlineStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "TODAY'S ORDERS",
                  style: FieldManual.label(fontSize: 10),
                ),
              ),
              if (streak > 0) _StreakChip(streak: streak, multiplier: multiplier),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const _OrdersSkeleton()
          else if (workout != null)
            _Complete(workout: workout!)
          else if (isRestDay)
            const _StandDown()
          else
            const _Train(),
        ],
      ),
    );
  }
}

class _Train extends StatelessWidget {
  const _Train();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('REPORT TO THE BAR', style: FieldManual.headline()),
        const SizedBox(height: 6),
        Text(
          'Nothing logged yet. The bar is waiting.',
          style: FieldManual.body(color: FieldManual.mutedBone, fontSize: 14),
        ),
        const SizedBox(height: 14),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 13),
          // The live accent — brass on the default issue, the equipped
          // pack's accent otherwise (DESIGN.md Accent Swap Rule).
          color: AppColors.of(context).accent,
          borderRadius: BorderRadius.circular(4),
          onPressed: () => context.go('/workouts'),
          child: Text(
            'LOG WORKOUT',
            style: FieldManual.title(color: FieldManual.ink),
          ),
        ),
      ],
    );
  }
}

class _StandDown extends StatelessWidget {
  const _StandDown();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('STAND DOWN', style: FieldManual.headline()),
        const SizedBox(height: 6),
        Text(
          'Scheduled recovery day. Stand down, soldier — recovery is training.',
          style: FieldManual.body(color: FieldManual.mutedBone, fontSize: 14),
        ),
        const SizedBox(height: 14),
        Semantics(
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.go('/workouts'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: FieldManual.hairlineStrong),
              ),
              child: Text(
                'LOG ANYWAY',
                style: FieldManual.title(color: FieldManual.mutedBone),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Complete extends StatelessWidget {
  const _Complete({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              CupertinoIcons.checkmark_seal_fill,
              size: 18,
              color: AppColors.of(context).accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('MISSION COMPLETE', style: FieldManual.headline()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          OrdersBlock.praiseOfTheDay(DateTime.now()),
          style: FieldManual.body(color: FieldManual.mutedBone, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                workout.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FieldManual.body(fontSize: 15),
              ),
            ),
            if (workout.durationMinutes != null) ...[
              const SizedBox(width: 10),
              Text(
                '${workout.durationMinutes} MIN',
                style: FieldManual.readout(fontSize: 13),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak, this.multiplier});

  final int streak;
  final double? multiplier;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.of(context).accent;
    return Semantics(
      label: multiplier != null
          ? '$streak day gym streak, ${multiplier!.toStringAsFixed(1)} times coin multiplier'
          : '$streak day streak',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: accent.withValues(alpha: 0.4),
          ),
        ),
        child: AnimatedCount(
          value: streak.toDouble(),
          builder: (context, animated) => Text(
            multiplier != null
                ? 'DAY ${animated.round()} · ×${multiplier!.toStringAsFixed(1)}'
                : 'DAY ${animated.round()}',
            style: FieldManual.label(color: accent, fontSize: 10),
          ),
        ),
      ),
    );
  }
}

class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: FieldManual.fieldRaised,
            borderRadius: BorderRadius.circular(3),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        block(180, 20),
        const SizedBox(height: 10),
        block(240, 13),
        const SizedBox(height: 14),
        block(double.infinity, 46),
      ],
    );
  }
}
