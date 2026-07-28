import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/field_manual.dart';
import '../../../../core/widgets/animated_count.dart';
import '../../../../core/widgets/meter_bar.dart';
import '../../../../providers/health_providers.dart';

/// Field Manual replacement for the Apple-style activity rings: Move /
/// Exercise / Stand as instrument readouts with thin progress rules. Gates
/// exactly like the old ActivityRings — collapses when Health is
/// disconnected or the dashboard toggle is off.
class ReconReadouts extends ConsumerWidget {
  const ReconReadouts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(healthConnectedProvider)) return const SizedBox.shrink();
    if (!ref.watch(healthDashboardEnabledProvider)) {
      return const SizedBox.shrink();
    }

    final move = ref.watch(todayActiveCaloriesProvider).valueOrNull ?? 0.0;
    final exercise = ref.watch(todayActiveMinutesProvider).valueOrNull ?? 0;
    final stand = ref.watch(todayStandHoursProvider).valueOrNull ?? 0;
    final goals = ref.watch(effectiveActivityGoalsProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FieldManual.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Readout(
              label: 'MOVE',
              current: move,
              goalLabel: '${goals.moveCalories}',
              unit: 'KCAL',
              fraction: _frac(move, goals.moveCalories),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _Readout(
              label: 'EXERCISE',
              current: exercise.toDouble(),
              goalLabel: '${goals.exerciseMinutes}',
              unit: 'MIN',
              fraction: _frac(exercise.toDouble(), goals.exerciseMinutes),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _Readout(
              label: 'STAND',
              current: stand.toDouble(),
              goalLabel: '${goals.standHours}',
              unit: 'HR',
              fraction: _frac(stand.toDouble(), goals.standHours),
            ),
          ),
        ],
      ),
    );
  }

  static double _frac(double value, int goal) =>
      goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0).toDouble();
}

class _Readout extends StatelessWidget {
  const _Readout({
    required this.label,
    required this.current,
    required this.goalLabel,
    required this.unit,
    required this.fraction,
  });

  final String label;
  final double current;
  final String goalLabel;
  final String unit;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // The spoken reading carries the settled value, not the count-up.
      label: '$label ${current.round()}/$goalLabel $unit',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: FieldManual.label(fontSize: 9)),
          const SizedBox(height: 4),
          AnimatedCount(
            value: current,
            builder: (context, animated) => Text(
              '${animated.round()}/$goalLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FieldManual.readout(fontSize: 13),
            ),
          ),
          Text(unit, style: FieldManual.label(fontSize: 8)),
          const SizedBox(height: 6),
          MeterBar(
            fraction: fraction,
            fill: FieldManual.bone.withValues(alpha: 0.85),
          ),
        ],
      ),
    );
  }
}
