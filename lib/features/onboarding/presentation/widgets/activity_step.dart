import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
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
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Center(
            child: OnboardingIllustration(icon: Icons.directions_run),
          ),
          const SizedBox(height: 24),
          Text(
            'How active are you?',
            style: textTheme.headlineMedium?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: AppColors.of(context).text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be honest — this affects your daily calorie target.',
            style: textTheme.bodyLarge?.copyWith(
              fontFamily: 'LeagueSpartan',
              fontWeight: FontWeight.w400,
              color: AppColors.of(context).textSecondary,
            ),
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
          _NextButton(
            isValid: _selectedLevel != null,
            onPressed: _submit,
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

class _NextButton extends StatelessWidget {
  const _NextButton({required this.isValid, required this.onPressed});

  final bool isValid;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    if (isValid) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: Colors.white,
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
        foregroundColor: palette.text,
        side: BorderSide(color: palette.border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        disabledForegroundColor: palette.text.withValues(alpha: 0.4),
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
