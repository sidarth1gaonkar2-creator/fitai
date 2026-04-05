import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../onboarding_controller.dart';
import 'onboarding_illustration.dart';

class MeasurementsStep extends ConsumerStatefulWidget {
  const MeasurementsStep({super.key});

  @override
  ConsumerState<MeasurementsStep> createState() => _MeasurementsStepState();
}

class _MeasurementsStepState extends ConsumerState<MeasurementsStep> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String? _weightError;
  String? _heightError;
  Timer? _weightDebounce;
  Timer? _heightDebounce;
  bool _weightTouched = false;
  bool _heightTouched = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingControllerProvider);
    if (state.weight != null) _weightController.text = state.weight.toString();
    if (state.height != null) _heightController.text = state.height.toString();
  }

  @override
  void dispose() {
    _weightDebounce?.cancel();
    _heightDebounce?.cancel();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _onWeightChanged(String value) {
    _weightTouched = true;
    _weightDebounce?.cancel();
    _weightDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _weightError = value.isEmpty ? null : validateWeight(value);
      });
    });
  }

  void _onHeightChanged(String value) {
    _heightTouched = true;
    _heightDebounce?.cancel();
    _heightDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _heightError = value.isEmpty ? null : validateHeight(value);
      });
    });
  }

  bool get _isValid =>
      _weightError == null &&
      _heightError == null &&
      _weightController.text.isNotEmpty &&
      _heightController.text.isNotEmpty;

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
            child: OnboardingIllustration(icon: Icons.monitor_weight_outlined),
          ),
          const SizedBox(height: 24),
          Text(
            'Your measurements',
            style: textTheme.headlineMedium?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Used for accurate calorie and macro calculations.',
            style: textTheme.bodyLarge?.copyWith(
              fontFamily: 'LeagueSpartan',
              fontWeight: FontWeight.w400,
              color: AppColors.purpleLight,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _weightController,
            decoration: InputDecoration(
              labelText: 'Weight (kg)',
              hintText: 'e.g. 75',
              suffixText: 'kg',
              errorText: _weightTouched ? _weightError : null,
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: _onWeightChanged,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _heightController,
            decoration: InputDecoration(
              labelText: 'Height (cm)',
              hintText: 'e.g. 175',
              suffixText: 'cm',
              errorText: _heightTouched ? _heightError : null,
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: _onHeightChanged,
          ),
          const Spacer(),
          _NextButton(isValid: _isValid, onPressed: _submit),
        ],
      ),
    );
  }

  void _submit() {
    final wError = validateWeight(_weightController.text);
    final hError = validateHeight(_heightController.text);
    if (wError != null || hError != null) {
      setState(() {
        _weightTouched = true;
        _heightTouched = true;
        _weightError = wError;
        _heightError = hError;
      });
      return;
    }

    final controller = ref.read(onboardingControllerProvider.notifier);
    controller.setWeight(double.parse(_weightController.text));
    controller.setHeight(double.parse(_heightController.text));
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
