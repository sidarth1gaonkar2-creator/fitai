import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            "We'll use this to personalise your experience.",
            style: Theme.of(context).textTheme.bodyLarge,
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
          FilledButton(
            onPressed: _isValid ? _submit : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    // Validate synchronously before advancing
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
