import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/enums.dart';
import '../onboarding_controller.dart';
import 'onboarding_illustration.dart';
import 'selectable_card.dart';

class ActivityStep extends ConsumerStatefulWidget {
  const ActivityStep({super.key});

  @override
  ConsumerState<ActivityStep> createState() => _ActivityStepState();
}

class _ActivityStepState extends ConsumerState<ActivityStep> {
  ActivityLevel? _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = ref.read(onboardingControllerProvider).activityLevel;
  }

  IconData _iconFor(ActivityLevel level) => switch (level) {
        ActivityLevel.sedentary => Icons.weekend,
        ActivityLevel.light => Icons.directions_walk,
        ActivityLevel.moderate => Icons.directions_bike,
        ActivityLevel.active => Icons.directions_run,
        ActivityLevel.veryActive => Icons.speed,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Center(child: OnboardingIllustration(icon: Icons.directions_run)),
          const SizedBox(height: 24),
          Text(
            'How active are you?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Be honest — this affects your daily calorie target.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: ActivityLevel.values.map((level) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SelectableCard(
                    title: level.shortLabel,
                    subtitle: level.description,
                    icon: _iconFor(level),
                    isSelected: _selectedLevel == level,
                    onTap: () => setState(() => _selectedLevel = level),
                  ),
                );
              }).toList(),
            ),
          ),
          FilledButton(
            onPressed: _selectedLevel != null ? _submit : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final controller = ref.read(onboardingControllerProvider.notifier);
    controller.setActivityLevel(_selectedLevel!);
    controller.nextStep();
  }
}
