import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Icons, Theme;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../onboarding_controller.dart';
import 'onboarding_illustration.dart';

class NameStep extends ConsumerStatefulWidget {
  const NameStep({super.key});

  @override
  ConsumerState<NameStep> createState() => _NameStepState();
}

class _NameStepState extends ConsumerState<NameStep> {
  final _nameController = TextEditingController();
  String? _nameError;
  Timer? _debounce;
  bool _isTouched = false;

  @override
  void initState() {
    super.initState();
    final currentName = ref.read(onboardingControllerProvider).name;
    if (currentName.isNotEmpty) {
      _nameController.text = currentName;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    _isTouched = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _nameError = value.isEmpty ? null : validateName(value);
      });
    });
  }

  bool get _isValid =>
      _nameError == null && _nameController.text.trim().isNotEmpty;

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
          const Center(child: OnboardingIllustration(icon: Icons.waving_hand)),
          const SizedBox(height: 24),
          Text(
            "What's your name?",
            style: textTheme.headlineMedium?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: AppColors.of(context).text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll use this to personalise your experience.",
            style: textTheme.bodyLarge?.copyWith(
              fontFamily: 'LeagueSpartan',
              fontWeight: FontWeight.w400,
              color: AppColors.of(context).textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          CupertinoTextField(
            controller: _nameController,
            placeholder: 'Enter your name',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text('Name', style: TextStyle(color: CupertinoColors.systemGrey)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.of(context).surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (_isTouched && _nameError != null)
                    ? AppColors.of(context).destructive
                    : AppColors.of(context).border,
              ),
            ),
            style: TextStyle(color: AppColors.of(context).text),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: _onNameChanged,
            onSubmitted: (_) => _isValid ? _submit() : null,
          ),
          if (_isTouched && _nameError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                _nameError!,
                style: TextStyle(color: AppColors.of(context).destructive, fontSize: 12),
              ),
            ),
          const SizedBox(height: 32),
          _NextButton(isValid: _isValid, onPressed: _submit),
        ],
      ),
    ),
    );
  }

  void _submit() {
    final error = validateName(_nameController.text);
    if (error != null) {
      setState(() {
        _isTouched = true;
        _nameError = error;
      });
      return;
    }

    final controller = ref.read(onboardingControllerProvider.notifier);
    controller.setName(_nameController.text.trim());
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
