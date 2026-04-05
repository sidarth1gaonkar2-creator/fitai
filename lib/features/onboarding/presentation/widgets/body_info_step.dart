import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Center(child: OnboardingIllustration(icon: Icons.person)),
          const SizedBox(height: 24),
          Text(
            'Tell us about yourself',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us calculate your daily calorie needs.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _ageController,
            decoration: InputDecoration(
              labelText: 'Age',
              hintText: 'Enter your age',
              errorText: _ageTouched ? _ageError : null,
            ),
            keyboardType: TextInputType.number,
            onChanged: _onAgeChanged,
          ),
          const SizedBox(height: 24),
          Text(
            'Sex',
            style: Theme.of(context).textTheme.titleMedium,
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
