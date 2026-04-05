import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/tdee_calculator.dart';
import '../../../../models/enums.dart';
import '../../domain/onboarding_state.dart';
import '../onboarding_controller.dart';
import 'onboarding_illustration.dart';

class SummaryStep extends ConsumerWidget {
  const SummaryStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
          const Center(child: OnboardingIllustration(icon: Icons.check_circle_outline)),
          const SizedBox(height: 24),
          Text(
            "You're all set, ${state.name}!",
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Here is your personalised summary.',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),

          // Profile card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Profile',
                      style: textTheme.titleSmall
                          ?.copyWith(color: colorScheme.primary)),
                  const SizedBox(height: 12),
                  _SummaryRow(label: 'Name', value: state.name),
                  _SummaryRow(label: 'Age', value: '${state.age}'),
                  _SummaryRow(label: 'Sex', value: state.sex?.label ?? ''),
                  _SummaryRow(
                      label: 'Weight', value: '${state.weight} kg'),
                  _SummaryRow(
                      label: 'Height', value: '${state.height} cm'),
                  _SummaryRow(label: 'Goal', value: state.goal?.label ?? ''),
                  _SummaryRow(
                      label: 'Activity',
                      value: state.activityLevel?.label ?? ''),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // TDEE breakdown card
          if (breakdown != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _CalculationBreakdownCard(
                  breakdown: breakdown,
                  state: state,
                ),
              ),
            ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: state.isSaving
                ? null
                : () => ref
                    .read(onboardingControllerProvider.notifier)
                    .calculateAndSave(),
            child: state.isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Get Started'),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final monoStyle = textTheme.bodyMedium
        ?.copyWith(fontFeatures: [const FontFeature.tabularFigures()]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Calorie Calculation',
            style: textTheme.titleSmall
                ?.copyWith(color: colorScheme.primary)),
        const SizedBox(height: 12),

        // BMR calculation
        _CalcRow(
          label: 'Base metabolic rate',
          value: breakdown.baseValue.round().toString(),
          style: monoStyle,
        ),
        _CalcRow(
          label: 'Sex adjustment (${state.sex?.label})',
          value: '${breakdown.sexConstant >= 0 ? '+' : ''}${breakdown.sexConstant.round()}',
          style: monoStyle,
        ),
        const Divider(height: 16),
        _CalcRow(
          label: 'BMR',
          value: '${breakdown.bmr.round()} kcal',
          style: monoStyle?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // TDEE
        _CalcRow(
          label: 'Activity multiplier (${state.activityLevel?.shortLabel})',
          value: '× ${breakdown.activityMultiplier.toStringAsFixed(2)}',
          style: monoStyle,
        ),
        const Divider(height: 16),
        _CalcRow(
          label: 'TDEE',
          value: '${breakdown.tdee.round()} kcal',
          style: monoStyle?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // Goal adjustment
        if (breakdown.calorieAdjustment != 0)
          _CalcRow(
            label: 'Goal adjustment (${state.goal?.label})',
            value: '${breakdown.calorieAdjustment > 0 ? '+' : ''}${breakdown.calorieAdjustment}',
            style: monoStyle,
          ),
        const Divider(height: 16),

        // Final target
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text('Daily calorie target',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Text(
              '${breakdown.goalAdjustedTarget.round()} kcal',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
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
    this.style,
  });

  final String label;
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
