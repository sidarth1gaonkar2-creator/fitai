import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Icons, Theme;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../models/enums.dart';
import '../onboarding_controller.dart';
import 'onboarding_illustration.dart';
import 'selectable_card.dart';

class BodyInfoStep extends ConsumerStatefulWidget {
  const BodyInfoStep({super.key});

  @override
  ConsumerState<BodyInfoStep> createState() => _BodyInfoStepState();
}

class _BodyInfoStepState extends ConsumerState<BodyInfoStep> {
  final _ageController = TextEditingController();
  Sex? _selectedSex;
  String? _ageError;
  Timer? _debounce;
  bool _ageTouched = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingControllerProvider);
    if (state.age != null) _ageController.text = state.age.toString();
    _selectedSex = state.sex;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ageController.dispose();
    super.dispose();
  }

  void _onAgeChanged(String value) {
    _ageTouched = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _ageError = value.isEmpty ? null : validateAge(value);
      });
    });
  }

  bool get _isValid =>
      _ageError == null &&
      _ageController.text.isNotEmpty &&
      _selectedSex != null;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Center(child: OnboardingIllustration(icon: Icons.person)),
          const SizedBox(height: 24),
          Text(
            'Tell us about yourself',
            style: textTheme.headlineMedium?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: AppColors.of(context).text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us calculate your daily calorie needs.',
            style: textTheme.bodyLarge?.copyWith(
              fontFamily: 'LeagueSpartan',
              fontWeight: FontWeight.w400,
              color: AppColors.of(context).textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          CupertinoTextField(
            controller: _ageController,
            placeholder: 'Enter your age',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text('Age', style: TextStyle(color: CupertinoColors.systemGrey)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.of(context).surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (_ageTouched && _ageError != null)
                    ? AppColors.of(context).destructive
                    : AppColors.of(context).border,
              ),
            ),
            style: TextStyle(color: AppColors.of(context).text),
            keyboardType: TextInputType.number,
            onChanged: _onAgeChanged,
          ),
          if (_ageTouched && _ageError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                _ageError!,
                style: TextStyle(color: AppColors.of(context).destructive, fontSize: 12),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Sex',
            style: textTheme.titleMedium?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).text,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SelectableCard(
                  title: 'Male',
                  icon: Icons.male,
                  isSelected: _selectedSex == Sex.male,
                  onTap: () => setState(() => _selectedSex = Sex.male),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableCard(
                  title: 'Female',
                  icon: Icons.female,
                  isSelected: _selectedSex == Sex.female,
                  onTap: () => setState(() => _selectedSex = Sex.female),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _NextButton(isValid: _isValid, onPressed: _submit),
        ],
      ),
    ),
    );
  }

  void _submit() {
    final error = validateAge(_ageController.text);
    if (error != null) {
      setState(() => _ageError = error);
      return;
    }

    final controller = ref.read(onboardingControllerProvider.notifier);
    controller.setAge(int.parse(_ageController.text));
    controller.setSex(_selectedSex!);
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
      return SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: palette.accent,
          borderRadius: BorderRadius.circular(12),
          onPressed: onPressed,
          child: const Text(
            'Next',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14),
        borderRadius: BorderRadius.circular(12),
        onPressed: null,
        child: Text(
          'Next',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: palette.text.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
