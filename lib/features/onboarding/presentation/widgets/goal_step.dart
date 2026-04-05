import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/enums.dart';
import '../onboarding_controller.dart';
import 'onboarding_illustration.dart';
import 'selectable_card.dart';

class GoalStep extends ConsumerStatefulWidget {
  const GoalStep({super.key});

  @override
  ConsumerState<GoalStep> createState() => _GoalStepState();
}

class _GoalStepState extends ConsumerState<GoalStep> {
  Goal? _selectedGoal;

  @override
  void initState() {
    super.initState();
    _selectedGoal = ref.read(onboardingControllerProvider).goal;
  }

  IconData _iconFor(Goal goal) => switch (goal) {
        Goal.loseFat => Icons.local_fire_department,
        Goal.buildMuscle => Icons.fitness_center,
        Goal.maintain => Icons.balance,
      };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Center(child: OnboardingIllustration(icon: Icons.flag_rounded)),
          const SizedBox(height: 24),
          Text(
            "What's your goal?",
            style: textTheme.headlineMedium?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll tailor your nutrition targets accordingly.",
            style: textTheme.bodyLarge?.copyWith(
              fontFamily: 'LeagueSpartan',
              fontWeight: FontWeight.w400,
              color: AppColors.purpleLight,
            ),
          ),
          const SizedBox(height: 32),
          ...Goal.values.map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SelectableCard(
                title: goal.label,
                icon: _iconFor(goal),
                isSelected: _selectedGoal == goal,
                onTap: () => setState(() => _selectedGoal = goal),
              ),
            ),
          ),
          const Spacer(),
          _NextButton(
            isValid: _selectedGoal != null,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  void _submit() {
    final controller = ref.read(onboardingControllerProvider.notifier);
    controller.setGoal(_selectedGoal!);
    controller.nextStep();
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.isValid, required this.onPressed});

  final bool isValid;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isValid) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.lime,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Next',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return OutlinedButton(
      onPressed: null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
      ),
      child: const Text(
        'Next',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
