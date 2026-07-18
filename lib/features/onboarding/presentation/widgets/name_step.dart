import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
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
  final _focusNode = FocusNode();
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
    // Focus only drives the accent border — presentation state.
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
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
    final palette = AppColors.of(context);
    final showError = _isTouched && _nameError != null;

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
            style: FieldManual.prompt(color: palette.text),
          ),
          const SizedBox(height: 8),
          Text(
            "So the sergeant knows who he's talking to.",
            style: FieldManual.body(color: palette.textSecondary),
          ),
          const SizedBox(height: 32),
          CupertinoTextField(
            controller: _nameController,
            focusNode: _focusNode,
            placeholder: 'Enter your name',
            prefix: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text('NAME', style: FieldManual.label()),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: showError
                    ? palette.destructive
                    : _focusNode.hasFocus
                        ? palette.accent
                        : palette.border,
              ),
            ),
            cursorColor: palette.accent,
            style: FieldManual.body(color: palette.text),
            placeholderStyle:
                FieldManual.body(color: palette.textSecondary),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: _onNameChanged,
            onSubmitted: (_) => _isValid ? _submit() : null,
          ),
          if (showError)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                _nameError!,
                style: FieldManual.body(
                  fontSize: 12,
                  color: palette.destructive,
                ),
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
