import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
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
  final _ageFocusNode = FocusNode();
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
    // Focus only drives the accent border — presentation state.
    _ageFocusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _debounce?.cancel();
    _ageFocusNode.removeListener(_onFocusChanged);
    _ageFocusNode.dispose();
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
    final palette = AppColors.of(context);
    final showError = _ageTouched && _ageError != null;

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
            style: FieldManual.prompt(color: palette.text),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us calculate your daily calorie needs.',
            style: FieldManual.body(color: palette.textSecondary),
          ),
          const SizedBox(height: 32),
          CupertinoTextField(
            controller: _ageController,
            focusNode: _ageFocusNode,
            placeholder: 'Enter your age',
            prefix: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text('AGE', style: FieldManual.label()),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: showError
                    ? palette.destructive
                    : _ageFocusNode.hasFocus
                        ? palette.accent
                        : palette.border,
              ),
            ),
            cursorColor: palette.accent,
            // Trained-against number → mono readout (Instrument Panel Rule).
            style: FieldManual.readout(fontSize: 16, color: palette.text),
            placeholderStyle:
                FieldManual.body(color: palette.textSecondary),
            keyboardType: TextInputType.number,
            onChanged: _onAgeChanged,
          ),
          if (showError)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                _ageError!,
                style: FieldManual.body(
                  fontSize: 12,
                  color: palette.destructive,
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text('SEX', style: FieldManual.label()),
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
    // "Next" stays sentence case — widget tests find this exact string.
    if (isValid) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: palette.accent,
          borderRadius: BorderRadius.circular(4),
          onPressed: onPressed,
          child: Text(
            'Next',
            style: FieldManual.title(color: palette.onAccent),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 14),
          borderRadius: BorderRadius.circular(4),
          onPressed: null,
          child: Text(
            'Next',
            style: FieldManual.title(
              color: palette.text.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
