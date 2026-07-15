import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/field_manual.dart';
import '../../../tutorial/presentation/tutorial_anchor.dart';
import 'kcal_gauge.dart';
import 'saved_meals_quick_log.dart';

/// The nutrition instrument panel: kcal gauge, macro readouts, the log-meal
/// action, and quick rations (saved meals). Absorbs the old calorie ring,
/// stats row, macro row, quick-log strip, and "+ Log Meal" pill.
class RationsPanel extends StatelessWidget {
  const RationsPanel({
    super.key,
    required this.calories,
    required this.calorieTarget,
    required this.burned,
    required this.protein,
    required this.proteinTarget,
    required this.carbs,
    required this.carbsTarget,
    required this.fat,
    required this.fatTarget,
    this.loading = false,
  });

  final double calories;
  final double calorieTarget;
  final double burned;
  final double protein;
  final double proteinTarget;
  final double carbs;
  final double carbsTarget;
  final double fat;
  final double fatTarget;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FieldManual.field,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FieldManual.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('RATIONS', style: FieldManual.headline())),
              Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.go('/nutrition'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: FieldManual.brass.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '+ LOG MEAL',
                      style: FieldManual.label(
                        color: FieldManual.brass,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const _RationsSkeleton()
          else ...[
            Center(
              child: TutorialAnchor(
                id: 'calorie_ring',
                child: KcalGauge(
                  consumed: calories,
                  target: calorieTarget,
                  burned: burned,
                ),
              ),
            ),
            if (burned > 0) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'BURNED ${burned.round()} KCAL',
                  style: FieldManual.label(fontSize: 9),
                ),
              ),
            ],
            const SizedBox(height: 18),
            TutorialAnchor(
              id: 'macro_row',
              child: Row(
                children: [
                  Expanded(
                    child: _MacroReadout(
                      label: 'PROTEIN',
                      grams: protein,
                      target: proteinTarget,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _MacroReadout(
                      label: 'CARBS',
                      grams: carbs,
                      target: carbsTarget,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _MacroReadout(
                      label: 'FAT',
                      grams: fat,
                      target: fatTarget,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Quick rations — self-collapses when the user has no saved meals.
          const SavedMealsQuickLog(),
        ],
      ),
    );
  }
}

class _MacroReadout extends StatelessWidget {
  const _MacroReadout({
    required this.label,
    required this.grams,
    required this.target,
  });

  final String label;
  final double grams;
  final double target;

  @override
  Widget build(BuildContext context) {
    final fraction =
        target <= 0 ? 0.0 : (grams / target).clamp(0.0, 1.0).toDouble();
    return Semantics(
      label: '$label ${grams.round()} of ${target.round()} grams',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: FieldManual.label(fontSize: 9)),
          const SizedBox(height: 4),
          Text(
            '${grams.round()}/${target.round()}G',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FieldManual.readout(fontSize: 13),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: SizedBox(
              height: 2,
              child: Stack(
                children: [
                  Container(color: FieldManual.hairline),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(
                      color: FieldManual.bone.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RationsSkeleton extends StatelessWidget {
  const _RationsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double w, double h, {double r = 3}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: FieldManual.fieldRaised,
            borderRadius: BorderRadius.circular(r),
          ),
        );
    return Column(
      children: [
        block(180, 140, r: 70),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: block(double.infinity, 40)),
            const SizedBox(width: 14),
            Expanded(child: block(double.infinity, 40)),
            const SizedBox(width: 14),
            Expanded(child: block(double.infinity, 40)),
          ],
        ),
      ],
    );
  }
}
