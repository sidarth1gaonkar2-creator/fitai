import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../providers/unit_system_provider.dart';
import '../onboarding_controller.dart';
import 'onboarding_illustration.dart';

class MeasurementsStep extends ConsumerStatefulWidget {
  const MeasurementsStep({super.key});

  @override
  ConsumerState<MeasurementsStep> createState() => _MeasurementsStepState();
}

class _MeasurementsStepState extends ConsumerState<MeasurementsStep> {
  static const _minWeight = 30;
  static const _maxWeight = 200;
  static const _minHeight = 120;
  static const _maxHeight = 220;

  int _weightKg = 75;
  int _heightCm = 175;

  late final FixedExtentScrollController _weightCtrl;
  late final FixedExtentScrollController _heightCtrl;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingControllerProvider);
    if (state.weight != null) _weightKg = state.weight!.round().clamp(_minWeight, _maxWeight);
    if (state.height != null) _heightCm = state.height!.round().clamp(_minHeight, _maxHeight);
    _weightCtrl = FixedExtentScrollController(initialItem: _weightKg - _minWeight);
    _heightCtrl = FixedExtentScrollController(initialItem: _heightCm - _minHeight);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final controller = ref.read(onboardingControllerProvider.notifier);
    controller.setWeight(_weightKg.toDouble());
    controller.setHeight(_heightCm.toDouble());
    controller.nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final units = ref.watch(unitSystemProvider);
    final isImperial = units == UnitSystem.imperial;

    final weightDisplay = isImperial
        ? UnitConverter.kgToLbs(_weightKg.toDouble()).round()
        : _weightKg;
    final weightUnit = isImperial ? 'lbs' : 'kg';

    final heightDisplay = isImperial
        ? UnitConverter.cmToFtIn(_heightCm.toDouble())
        : '$_heightCm cm';

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
              color: AppColors.of(context).text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Used for accurate calorie and macro calculations.',
            style: textTheme.bodyLarge?.copyWith(
              fontFamily: 'LeagueSpartan',
              fontWeight: FontWeight.w400,
              color: AppColors.of(context).textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _WheelPicker(
                    label: 'Weight',
                    unit: weightUnit,
                    displayValue: '$weightDisplay $weightUnit',
                    controller: _weightCtrl,
                    value: _weightKg,
                    min: _minWeight,
                    max: _maxWeight,
                    onChanged: (v) => setState(() => _weightKg = v),
                    formatItem: isImperial
                        ? (rawKg) =>
                            '${UnitConverter.kgToLbs(rawKg.toDouble()).round()}'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WheelPicker(
                    label: 'Height',
                    unit: isImperial ? 'ft' : 'cm',
                    displayValue: heightDisplay,
                    controller: _heightCtrl,
                    value: _heightCm,
                    min: _minHeight,
                    max: _maxHeight,
                    onChanged: (v) => setState(() => _heightCm = v),
                    formatItem: isImperial
                        ? (rawCm) =>
                            UnitConverter.cmToFtIn(rawCm.toDouble())
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: AppColors.of(context).accent,
            borderRadius: BorderRadius.circular(12),
            onPressed: _submit,
            child: const Text(
              'Next',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelPicker extends StatelessWidget {
  const _WheelPicker({
    required this.label,
    required this.unit,
    this.displayValue,
    required this.controller,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.formatItem,
  });

  final String label;
  final String unit;
  final String? displayValue;
  final FixedExtentScrollController controller;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String Function(int)? formatItem;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: palette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            displayValue ?? '$value $unit',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: palette.accent,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          // The picker needs a generous tap target — the previous
          // configuration (itemExtent 34 + magnification 1.1 + squeeze 1.2)
          // compressed each row into a ~22-pt strip that effectively dead-
          // zoned vertical drags. Larger itemExtent + diameterRatio + no
          // squeeze gives the wheel room to grab gestures cleanly. We also
          // wrap with `behavior: opaque` so any transparent inner gaps
          // still consume the touch and route it to the picker.
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: CupertinoPicker.builder(
                scrollController: controller,
                itemExtent: 44,
                diameterRatio: 1.6,
                useMagnifier: true,
                magnification: 1.05,
                selectionOverlay: Container(
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.12),
                    border: Border(
                      top: BorderSide(color: palette.accent),
                      bottom: BorderSide(color: palette.accent),
                    ),
                  ),
                ),
                onSelectedItemChanged: (index) => onChanged(min + index),
                childCount: max - min + 1,
                itemBuilder: (context, i) => Center(
                  child: Text(
                    formatItem?.call(min + i) ?? '${min + i}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: palette.text,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
