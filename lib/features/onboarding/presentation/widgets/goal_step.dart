import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            "We'll tailor your nutrition targets accordingly.",
            style: Theme.of(context).textTheme.bodyLarge,
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
          FilledButton(
            onPressed: _selectedGoal != null ? _submit : null,
            child: const Text('Next'),
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
