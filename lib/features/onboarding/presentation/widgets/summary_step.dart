import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
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
          const Center(
            child: OnboardingIllustration(icon: Icons.check_circle_outline),
          ),
          const SizedBox(height: 24),
          Text(
            "You're all set, ${state.name}!",
            style: textTheme.headlineMedium?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here is your personalised summary.',
            style: textTheme.bodyLarge?.copyWith(
              fontFamily: 'LeagueSpartan',
              fontWeight: FontWeight.w400,
              color: AppColors.purpleLight,
            ),
          ),
          const SizedBox(height: 32),

          // Profile card
          Container(
            decoration: BoxDecoration(
              color: AppColors.purpleDark,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Profile',
                  style: textTheme.titleSmall?.copyWith(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: AppColors.lime,
                  ),
                ),
                const SizedBox(height: 12),
                _SummaryRow(label: 'Name', value: state.name),
                _SummaryRow(label: 'Age', value: '${state.age}'),
                _SummaryRow(label: 'Sex', value: state.sex?.label ?? ''),
                _SummaryRow(label: 'Weight', value: '${state.weight} kg'),
                _SummaryRow(label: 'Height', value: '${state.height} cm'),
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
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.darkSurfaceBorder,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: _CalculationBreakdownCard(
                breakdown: breakdown,
                state: state,
              ),
            ),
          const SizedBox(height: 32),

          // Get Started button
          FilledButton(
            onPressed: state.isSaving
                ? null
                : () => ref
                    .read(onboardingControllerProvider.notifier)
                    .calculateAndSave(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lime,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: state.isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    'Get Started',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
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
    final textTheme = Theme.of(context).textTheme;
    final monoStyle = textTheme.bodyMedium?.copyWith(
      fontFeatures: [const FontFeature.tabularFigures()],
      color: Colors.white,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calorie Calculation',
          style: textTheme.titleSmall?.copyWith(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: AppColors.lime,
          ),
        ),
        const SizedBox(height: 12),

        // BMR calculation
        _CalcRow(
          label: 'Base metabolic rate',
          value: breakdown.baseValue.round().toString(),
          style: monoStyle,
        ),
        _CalcRow(
          label: 'Sex adjustment (${state.sex?.label})',
          value:
              '${breakdown.sexConstant >= 0 ? '+' : ''}${breakdown.sexConstant.round()}',
          style: monoStyle,
        ),
        const Divider(height: 16, color: AppColors.darkSurfaceBorder),
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
        const Divider(height: 16, color: AppColors.darkSurfaceBorder),
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
            value:
                '${breakdown.calorieAdjustment > 0 ? '+' : ''}${breakdown.calorieAdjustment}',
            style: monoStyle,
          ),
        const Divider(height: 16, color: AppColors.darkSurfaceBorder),

        // Final target
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Daily calorie target',
                style: textTheme.titleMedium?.copyWith(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              '${breakdown.goalAdjustedTarget.round()} kcal',
              style: textTheme.titleLarge?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: AppColors.lime,
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
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
