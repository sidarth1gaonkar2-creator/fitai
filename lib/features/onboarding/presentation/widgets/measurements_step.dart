import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // Imperial ranges (whole pounds / total inches).
  static const _minWeightLbs = 80;
  static const _maxWeightLbs = 400;
  static const _minHeightIn = 48; // 4'0"
  static const _maxHeightIn = 84; // 7'0"

  // Metric ranges (whole kg / cm).
  static const _minWeightKg = 35;
  static const _maxWeightKg = 180;
  static const _minHeightCm = 120;
  static const _maxHeightCm = 220;

  // The unit system isn't user-toggleable during onboarding (Settings →
  // Units lives behind the auth wall), so we latch it once at initState
  // and key everything off this flag. That lets us scroll the wheel in
  // the *displayed* unit — every integer pound or kilo shows up exactly
  // once, instead of producing the irregular 170/172/174… gaps you get
  // when the underlying step is 1 kg and we just convert to lbs at paint
  // time.
  late final bool _isImperial;

  late final int _minWeight;
  late final int _maxWeight;
  late final int _minHeight;
  late final int _maxHeight;
  late final String _weightUnit;

  // Picker state: integer values already in the display unit.
  late int _weight;
  late int _height;

  late final FixedExtentScrollController _weightCtrl;
  late final FixedExtentScrollController _heightCtrl;

  @override
  void initState() {
    super.initState();
    final units = ref.read(unitSystemProvider);
    _isImperial = units == UnitSystem.imperial;

    if (_isImperial) {
      _minWeight = _minWeightLbs;
      _maxWeight = _maxWeightLbs;
      _minHeight = _minHeightIn;
      _maxHeight = _maxHeightIn;
      _weightUnit = 'lbs';
    } else {
      _minWeight = _minWeightKg;
      _maxWeight = _maxWeightKg;
      _minHeight = _minHeightCm;
      _maxHeight = _maxHeightCm;
      _weightUnit = 'kg';
    }

    final state = ref.read(onboardingControllerProvider);

    final savedKg = state.weight ?? 75;
    _weight = (_isImperial
            ? UnitConverter.kgToLbs(savedKg).round()
            : savedKg.round())
        .clamp(_minWeight, _maxWeight);

    final savedCm = state.height ?? 175;
    _height = (_isImperial
            ? (savedCm / 2.54).round()
            : savedCm.round())
        .clamp(_minHeight, _maxHeight);

    _weightCtrl =
        FixedExtentScrollController(initialItem: _weight - _minWeight);
    _heightCtrl =
        FixedExtentScrollController(initialItem: _height - _minHeight);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  String _formatHeight(int value) {
    if (_isImperial) {
      final feet = value ~/ 12;
      final inches = value % 12;
      return "$feet'$inches\"";
    }
    return '$value cm';
  }

  void _submit() {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final kg = _isImperial
        ? UnitConverter.lbsToKg(_weight.toDouble())
        : _weight.toDouble();
    final cm = _isImperial ? _height * 2.54 : _height.toDouble();
    controller.setWeight(kg);
    controller.setHeight(cm);
    controller.nextStep();
  }

  Future<void> _editWeight() async {
    HapticFeedback.selectionClick();
    final ctrl = TextEditingController(text: '$_weight');
    final result = await showCupertinoDialog<int>(
      context: context,
      builder: (dialogContext) {
        String? error;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void confirm() {
              final parsed = int.tryParse(ctrl.text.trim());
              if (parsed == null) {
                setDialogState(() => error = 'Enter a whole number.');
                return;
              }
              if (parsed < _minWeight || parsed > _maxWeight) {
                setDialogState(() => error =
                    'Must be between $_minWeight and $_maxWeight $_weightUnit.');
                return;
              }
              Navigator.of(dialogContext).pop(parsed);
            }

            return CupertinoAlertDialog(
              title: const Text('Enter weight'),
              content: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    CupertinoTextField(
                      controller: ctrl,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      placeholder: '$_minWeight - $_maxWeight $_weightUnit',
                      textAlign: TextAlign.center,
                      onSubmitted: (_) => confirm(),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: confirm,
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
    ctrl.dispose();
    if (result != null && mounted) {
      setState(() => _weight = result);
      _weightCtrl.animateToItem(
        _weight - _minWeight,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _editHeight() async {
    HapticFeedback.selectionClick();
    if (_isImperial) {
      // Two fields: feet + inches. Inches is bounded to 0–11; the OK
      // handler also validates the combined total falls within the
      // picker's full range so the wheel can scroll to it cleanly.
      final ftCtrl = TextEditingController(text: '${_height ~/ 12}');
      final inCtrl = TextEditingController(text: '${_height % 12}');
      final result = await showCupertinoDialog<int>(
        context: context,
        builder: (dialogContext) {
          String? error;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              void confirm() {
                final f = int.tryParse(ftCtrl.text.trim());
                final iText = inCtrl.text.trim();
                final i = iText.isEmpty ? 0 : int.tryParse(iText);
                if (f == null || i == null) {
                  setDialogState(
                      () => error = 'Enter whole feet and inches.');
                  return;
                }
                if (i < 0 || i >= 12) {
                  setDialogState(() => error = 'Inches must be 0 – 11.');
                  return;
                }
                final total = f * 12 + i;
                if (total < _minHeight || total > _maxHeight) {
                  setDialogState(() => error =
                      'Must be between ${_formatHeight(_minHeight)} and ${_formatHeight(_maxHeight)}.');
                  return;
                }
                Navigator.of(dialogContext).pop(total);
              }

              return CupertinoAlertDialog(
                title: const Text('Enter height'),
                content: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoTextField(
                              controller: ftCtrl,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              placeholder: 'ft',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text("'"),
                          const SizedBox(width: 6),
                          Expanded(
                            child: CupertinoTextField(
                              controller: inCtrl,
                              keyboardType: TextInputType.number,
                              placeholder: 'in',
                              textAlign: TextAlign.center,
                              onSubmitted: (_) => confirm(),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Text('"'),
                        ],
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          error!,
                          style: const TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: confirm,
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        },
      );
      ftCtrl.dispose();
      inCtrl.dispose();
      if (result != null && mounted) {
        setState(() => _height = result);
        _heightCtrl.animateToItem(
          _height - _minHeight,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }

    // Metric — a single cm field.
    final ctrl = TextEditingController(text: '$_height');
    final result = await showCupertinoDialog<int>(
      context: context,
      builder: (dialogContext) {
        String? error;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void confirm() {
              final parsed = int.tryParse(ctrl.text.trim());
              if (parsed == null) {
                setDialogState(() => error = 'Enter a whole number.');
                return;
              }
              if (parsed < _minHeight || parsed > _maxHeight) {
                setDialogState(() => error =
                    'Must be between $_minHeight and $_maxHeight cm.');
                return;
              }
              Navigator.of(dialogContext).pop(parsed);
            }

            return CupertinoAlertDialog(
              title: const Text('Enter height'),
              content: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    CupertinoTextField(
                      controller: ctrl,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      placeholder: '$_minHeight - $_maxHeight cm',
                      textAlign: TextAlign.center,
                      onSubmitted: (_) => confirm(),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: confirm,
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
    ctrl.dispose();
    if (result != null && mounted) {
      setState(() => _height = result);
      _heightCtrl.animateToItem(
        _height - _minHeight,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Center(
            child: OnboardingIllustration(icon: Icons.straighten),
          ),
          const SizedBox(height: 24),
          Text(
            'Your measurements',
            style: textTheme.headlineMedium?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a value to type it in, or scroll the wheel.',
            style: textTheme.bodyLarge?.copyWith(
              fontFamily: 'LeagueSpartan',
              fontWeight: FontWeight.w400,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _WheelPicker(
                    label: 'Weight',
                    displayValue: '$_weight $_weightUnit',
                    onTapValue: _editWeight,
                    controller: _weightCtrl,
                    min: _minWeight,
                    max: _maxWeight,
                    onChanged: (v) => setState(() => _weight = v),
                    formatItem: (v) => '$v',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WheelPicker(
                    label: 'Height',
                    displayValue: _formatHeight(_height),
                    onTapValue: _editHeight,
                    controller: _heightCtrl,
                    min: _minHeight,
                    max: _maxHeight,
                    onChanged: (v) => setState(() => _height = v),
                    formatItem: _formatHeight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: palette.accent,
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
    required this.displayValue,
    required this.onTapValue,
    required this.controller,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.formatItem,
  });

  final String label;
  final String displayValue;
  final VoidCallback onTapValue;
  final FixedExtentScrollController controller;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String Function(int) formatItem;

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
          // Tap-to-type — the big accent-coloured headline doubles as a
          // button. A dotted underline + ~16-px vertical padding tells the
          // user it's interactive and gives the gesture room.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTapValue,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: Text(
                displayValue,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: palette.accent,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                  decorationColor: palette.accent.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
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
                    formatItem(min + i),
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
