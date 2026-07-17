import 'package:flutter/cupertino.dart';

import '../../../../core/theme/field_manual.dart';
import '../../../../core/widgets/macro_readout.dart';
import '../../../dashboard/presentation/widgets/kcal_gauge.dart';

/// The nutrition instrument panel — Field Manual successor to the old
/// CalorieRing summary. The dashboard's KcalGauge language, at full size:
/// tick-marked kcal gauge on a field panel with mono macro readouts beneath.
/// Same constructor API as the pre-FM card; presentation only.
class NutritionSummaryCard extends StatelessWidget {
  const NutritionSummaryCard({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double calorieTarget;
  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;

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
          Center(
            child: KcalGauge(
              consumed: calories,
              target: calorieTarget,
              size: 190,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MacroReadout(
                  label: 'PROTEIN',
                  grams: protein,
                  target: proteinTarget,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: MacroReadout(
                  label: 'CARBS',
                  grams: carbs,
                  target: carbsTarget,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: MacroReadout(
                  label: 'FAT',
                  grams: fat,
                  target: fatTarget,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

