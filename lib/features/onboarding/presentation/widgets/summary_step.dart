import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/utils/tdee_calculator.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../models/enums.dart';
import '../../../../providers/unit_system_provider.dart';
import '../../domain/onboarding_state.dart';
import '../onboarding_controller.dart';
import 'onboarding_illustration.dart';

class SummaryStep extends ConsumerWidget {
  const SummaryStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final units = ref.watch(unitSystemProvider);
    final palette = AppColors.of(context);

    final breakdown = (state.weight != null &&
            state.height != null &&
            state.age != null &&
            state.sex != null &&
            state.activityLevel != null &&
            state.goal != null)
        ? calculateTDEEBreakdown(
            weightKg: state.weight!,
            heightCm: state.height!,
            age: state.age!,
            sex: state.sex!,
            activityLevel: state.activityLevel!,
            goal: state.goal!,
          )
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Center(
            child: OnboardingIllustration(icon: Icons.check_circle_outline),
          ),
          const SizedBox(height: 24),
          // Sentence case: the headline carries the recruit's name — user
          // content is never uppercased. The sergeant praises completed work,
          // and doesn't gush — no exclamation.
          Text(
            'Intake complete, ${state.name}.',
            style: FieldManual.prompt(color: palette.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Your numbers. The sergeant has them too.',
            style: FieldManual.body(color: palette.textSecondary),
          ),
          const SizedBox(height: 32),

          // Profile card
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.border),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR PROFILE', style: FieldManual.label()),
                const SizedBox(height: 12),
                _SummaryRow(label: 'Name', value: state.name),
                _SummaryRow(label: 'Age', value: '${state.age}', mono: true),
                _SummaryRow(label: 'Sex', value: state.sex?.label ?? ''),
                _SummaryRow(
                  label: 'Weight',
                  value: state.weight == null
                      ? '—'
                      : UnitConverter.formatWeight(state.weight!, units),
                  mono: true,
                ),
                _SummaryRow(
                  label: 'Height',
                  value: state.height == null
                      ? '—'
                      : UnitConverter.formatHeight(state.height!, units),
                  mono: true,
                ),
                _SummaryRow(label: 'Goal', value: state.goal?.label ?? ''),
                _SummaryRow(
                  label: 'Activity',
                  value: state.activityLevel?.label ?? '',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // TDEE breakdown card
          if (breakdown != null)
            Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.border),
              ),
              padding: const EdgeInsets.all(20),
              child: _CalculationBreakdownCard(
                breakdown: breakdown,
                state: state,
              ),
            ),
          const SizedBox(height: 32),

          // Get Started button — sentence case kept to match the pinned
          // "Next" labels earlier in the flow.
          FilledButton(
            onPressed: state.isSaving
                ? null
                : () => ref
                    .read(onboardingControllerProvider.notifier)
                    .calculateAndSave(),
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.onAccent,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: state.isSaving
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.onAccent,
                    ),
                  )
                : Text(
                    'Get Started',
                    style: FieldManual.title(color: palette.onAccent),
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CalculationBreakdownCard extends StatelessWidget {
  const _CalculationBreakdownCard({
    required this.breakdown,
    required this.state,
  });

  final TDEEBreakdown breakdown;
  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final labelStyle =
        FieldManual.body(fontSize: 13, color: palette.textSecondary);
    // Every figure the recruit trains against is a mono readout
    // (Instrument Panel Rule).
    final valueStyle = FieldManual.readout(fontSize: 13, color: palette.text);
    final emphasisLabelStyle =
        FieldManual.body(fontSize: 13, color: palette.text).copyWith(
      fontVariations: const [FontVariation('wght', 600)],
      fontWeight: FontWeight.w600,
    );
    final emphasisValueStyle =
        FieldManual.readout(fontSize: 14, color: palette.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CALORIE CALCULATION', style: FieldManual.label()),
        const SizedBox(height: 12),

        // BMR calculation
        _CalcRow(
          label: 'Base metabolic rate',
          value: breakdown.baseValue.round().toString(),
          labelStyle: labelStyle,
          valueStyle: valueStyle,
        ),
        _CalcRow(
          label: 'Sex adjustment (${state.sex?.label})',
          value:
              '${breakdown.sexConstant >= 0 ? '+' : ''}${breakdown.sexConstant.round()}',
          labelStyle: labelStyle,
          valueStyle: valueStyle,
        ),
        Divider(height: 16, color: palette.border),
        _CalcRow(
          label: 'BMR',
          value: '${breakdown.bmr.round()} kcal',
          labelStyle: emphasisLabelStyle,
          valueStyle: emphasisValueStyle,
        ),
        const SizedBox(height: 12),

        // TDEE
        _CalcRow(
          label: 'Activity multiplier (${state.activityLevel?.shortLabel})',
          value: '× ${breakdown.activityMultiplier.toStringAsFixed(2)}',
          labelStyle: labelStyle,
          valueStyle: valueStyle,
        ),
        Divider(height: 16, color: palette.border),
        _CalcRow(
          label: 'TDEE',
          value: '${breakdown.tdee.round()} kcal',
          labelStyle: emphasisLabelStyle,
          valueStyle: emphasisValueStyle,
        ),
        const SizedBox(height: 12),

        // Goal adjustment
        if (breakdown.calorieAdjustment != 0)
          _CalcRow(
            label: 'Goal adjustment (${state.goal?.label})',
            value:
                '${breakdown.calorieAdjustment > 0 ? '+' : ''}${breakdown.calorieAdjustment}',
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
        Divider(height: 16, color: palette.border),

        // Final target
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Daily calorie target',
                style: FieldManual.title(color: palette.text),
              ),
            ),
            Text(
              '${breakdown.goalAdjustedTarget.round()} kcal',
              style: FieldManual.readout(
                fontSize: 20,
                color: palette.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CalcRow extends StatelessWidget {
  const _CalcRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: labelStyle)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.mono = false,
  });

  final String label;
  final String value;

  /// True for numeric values (age, weight, height) — they render in the
  /// mono readout face per the Instrument Panel Rule.
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: FieldManual.body(
              fontSize: 14,
              color: palette.textSecondary,
            ),
          ),
          Text(
            value,
            style: mono
                ? FieldManual.readout(fontSize: 14, color: palette.text)
                : FieldManual.body(fontSize: 14, color: palette.text)
                    .copyWith(
                    fontVariations: const [FontVariation('wght', 600)],
                    fontWeight: FontWeight.w600,
                  ),
          ),
        ],
      ),
    );
  }
}
