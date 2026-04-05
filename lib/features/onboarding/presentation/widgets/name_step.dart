import 'dart:async';

import 'package:flutter/material.dart';
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

    return Padding(
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll use this to personalise your experience.",
            style: textTheme.bodyLarge?.copyWith(
              fontFamily: 'LeagueSpartan',
              fontWeight: FontWeight.w400,
              color: AppColors.purpleLight,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'Enter your name',
              errorText: _isTouched ? _nameError : null,
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: _onNameChanged,
            onSubmitted: (_) => _isValid ? _submit() : null,
          ),
          const Spacer(),
          _NextButton(isValid: _isValid, onPressed: _submit),
        ],
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
