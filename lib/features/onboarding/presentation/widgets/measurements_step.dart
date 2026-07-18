import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../core/widgets/fm_segmented.dart';
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

  // Current unit — mutable so the user can switch live via the segmented
  // control. Synced both to local state (which drives the picker indexing
  // and headline formatting) and to [unitSystemProvider] so the rest of
  // the app picks up the choice after onboarding completes.
  bool _isImperial = true;

  // Picker values in the *current* display unit (lbs/in or kg/cm). When
  // the user toggles, we convert these once so the wheel can re-index in
  // 1-unit steps without producing irregular gaps or duplicates.
  late int _weight;
  late int _height;

  late FixedExtentScrollController _weightCtrl;
  late FixedExtentScrollController _heightCtrl;

  /// Controllers retired by [_setUnit] that we can't dispose immediately:
  /// the [AnimatedSwitcher] keeps the outgoing picker subtree mounted for
  /// the duration of the crossfade, and that outgoing subtree still holds
  /// a reference to the old controllers. We dispose everything together
  /// in [dispose] — at most a handful of controllers accumulate over a
  /// few unit toggles, each holding only a scroll offset.
  final List<FixedExtentScrollController> _retiredControllers = [];

  int get _minWeight => _isImperial ? _minWeightLbs : _minWeightKg;
  int get _maxWeight => _isImperial ? _maxWeightLbs : _maxWeightKg;
  int get _minHeight => _isImperial ? _minHeightIn : _minHeightCm;
  int get _maxHeight => _isImperial ? _maxHeightIn : _maxHeightCm;
  String get _weightUnit => _isImperial ? 'lbs' : 'kg';

  @override
  void initState() {
    super.initState();
    // Seed from the persisted preference, but fall back to imperial when
    // there's nothing saved yet (provider default also lives at imperial).
    _isImperial = ref.read(unitSystemProvider) == UnitSystem.imperial;

    final state = ref.read(onboardingControllerProvider);
    final savedKg = state.weight ?? 75;
    final savedCm = state.height ?? 175;

    _weight = _isImperial
        ? UnitConverter.kgToLbs(savedKg)
            .round()
            .clamp(_minWeightLbs, _maxWeightLbs)
        : savedKg.round().clamp(_minWeightKg, _maxWeightKg);

    _height = _isImperial
        ? (savedCm / 2.54).round().clamp(_minHeightIn, _maxHeightIn)
        : savedCm.round().clamp(_minHeightCm, _maxHeightCm);

    _weightCtrl =
        FixedExtentScrollController(initialItem: _weight - _minWeight);
    _heightCtrl =
        FixedExtentScrollController(initialItem: _height - _minHeight);
  }

  @override
  void dispose() {
    for (final c in _retiredControllers) {
      c.dispose();
    }
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _setUnit(bool toImperial) {
    if (toImperial == _isImperial) return;
    HapticFeedback.selectionClick();

    // Source the conversion from the LIVE picker position rather than
    // from `_weight`/`_height`. `onSelectedItemChanged` keeps those
    // fields in sync, but reading the controllers directly is one
    // fewer place a stale value can creep in when the segmented
    // control is tapped before the wheel has snapped after a scroll.
    // The `hasClients` guard handles the cold path where the
    // controller hasn't attached to its scrollable yet.
    final currentWeight = _weightCtrl.hasClients
        ? _minWeight + _weightCtrl.selectedItem
        : _weight;
    final currentHeight = _heightCtrl.hasClients
        ? _minHeight + _heightCtrl.selectedItem
        : _height;

    // Conversion formulas:
    //   kg ↔ lbs : 1 lb = 0.45359237 kg → divide/multiply by 2.20462
    //   cm ↔ in  : 1 in = 2.54 cm exactly
    // Clamp to the *new* unit's range so 401 lbs doesn't overflow when
    // an over-range metric value lands on the rounding boundary.
    final newWeight = toImperial
        ? UnitConverter.kgToLbs(currentWeight.toDouble())
            .round()
            .clamp(_minWeightLbs, _maxWeightLbs)
        : UnitConverter.lbsToKg(currentWeight.toDouble())
            .round()
            .clamp(_minWeightKg, _maxWeightKg);

    final newHeight = toImperial
        ? (currentHeight / 2.54).round().clamp(_minHeightIn, _maxHeightIn)
        : (currentHeight * 2.54).round().clamp(_minHeightCm, _maxHeightCm);

    // Retire the old controllers — we CAN'T dispose them yet because the
    // outgoing picker subtree (inside AnimatedSwitcher) still references
    // them while it fades out. They get disposed together in our
    // [dispose] when the step is unmounted.
    _retiredControllers.add(_weightCtrl);
    _retiredControllers.add(_heightCtrl);

    setState(() {
      _isImperial = toImperial;
      _weight = newWeight;
      _height = newHeight;
      // initialItem = (converted value in new unit) − (new unit's min).
      // Because `_isImperial` was flipped first, `_minWeight`/`_minHeight`
      // now resolve to the new unit's range, so the index lands on the
      // exact item that matches the header.
      // e.g. 83 kg → 83 − 35 = item[48];  72 in → 72 − 48 = item[24].
      _weightCtrl = FixedExtentScrollController(
        initialItem: _weight - _minWeight,
      );
      _heightCtrl = FixedExtentScrollController(
        initialItem: _height - _minHeight,
      );
    });

    // Safety net — `initialItem` is supposed to position the wheel when the
    // controller is first attached, but the AnimatedSwitcher mount timing
    // can leave the wheel one frame behind on some devices. After the new
    // picker has mounted and attached the controller, force the index to
    // the converted value so the wheel and header are guaranteed to match.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_weightCtrl.hasClients) {
        _weightCtrl.jumpToItem(_weight - _minWeight);
      }
      if (_heightCtrl.hasClients) {
        _heightCtrl.jumpToItem(_height - _minHeight);
      }
    });

    // Persist app-wide so the summary screen, dashboard, and settings all
    // pick up the choice. The provider is backed by SharedPreferences via
    // [UnitSystemNotifier.setUnit].
    ref.read(unitSystemProvider.notifier).setUnit(
          toImperial ? UnitSystem.imperial : UnitSystem.metric,
        );
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
    final palette = AppColors.of(context);
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
                      cursorColor: palette.accent,
                      style: FieldManual.readout(
                        fontSize: 16,
                        color: palette.text,
                      ),
                      placeholderStyle: FieldManual.body(
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: palette.border),
                      ),
                      onSubmitted: (_) => confirm(),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: FieldManual.body(
                          fontSize: 12,
                          color: palette.destructive,
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
      _settleWheel(_weightCtrl, _weight - _minWeight);
    }
  }

  /// Settle a wheel on [index] after tap-to-type — jumps instead of animating
  /// when the user has Reduce Motion on.
  void _settleWheel(FixedExtentScrollController ctrl, int index) {
    if (MediaQuery.disableAnimationsOf(context)) {
      ctrl.jumpToItem(index);
    } else {
      ctrl.animateToItem(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _editHeight() async {
    HapticFeedback.selectionClick();
    final palette = AppColors.of(context);
    if (_isImperial) {
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
                              cursorColor: palette.accent,
                              style: FieldManual.readout(
                                fontSize: 16,
                                color: palette.text,
                              ),
                              placeholderStyle: FieldManual.body(
                                fontSize: 13,
                                color: palette.textSecondary,
                              ),
                              decoration: BoxDecoration(
                                color: palette.surfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: palette.border),
                              ),
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
                              cursorColor: palette.accent,
                              style: FieldManual.readout(
                                fontSize: 16,
                                color: palette.text,
                              ),
                              placeholderStyle: FieldManual.body(
                                fontSize: 13,
                                color: palette.textSecondary,
                              ),
                              decoration: BoxDecoration(
                                color: palette.surfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: palette.border),
                              ),
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
                          style: FieldManual.body(
                            fontSize: 12,
                            color: palette.destructive,
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
        _settleWheel(_heightCtrl, _height - _minHeight);
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
                      cursorColor: palette.accent,
                      style: FieldManual.readout(
                        fontSize: 16,
                        color: palette.text,
                      ),
                      placeholderStyle: FieldManual.body(
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: palette.border),
                      ),
                      onSubmitted: (_) => confirm(),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: FieldManual.body(
                          fontSize: 12,
                          color: palette.destructive,
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
      _settleWheel(_heightCtrl, _height - _minHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return SafeArea(
      // Bottom inset so the Next button clears the home indicator, matching
      // the SafeArea-wrapped name/body/goal steps.
      child: Padding(
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
            style: FieldManual.prompt(color: palette.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a value to type it in, or scroll the wheel.',
            style: FieldManual.body(color: palette.textSecondary),
          ),
          const SizedBox(height: 16),
          // Unit toggle — Field Manual segmented control (same single-tap
          // surface as the sliding control it replaces); selecting either
          // side triggers the value conversion + provider sync in [_setUnit].
          Center(
            child: SizedBox(
              width: 260,
              child: FmSegmented<bool>(
                segments: const [(true, 'Imperial'), (false, 'Metric')],
                selected: _isImperial,
                onChanged: _setUnit,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            // AnimatedSwitcher crossfades between the imperial and metric
            // picker rows. The `ValueKey(_isImperial)` on the inner Row
            // is what makes this work: when the unit toggles, Flutter
            // treats the new Row as a *different* child, so it mounts a
            // fresh subtree (fresh CupertinoPicker → fresh
            // ScrollPosition that actually honours the new controller's
            // initialItem). Without the key change, the picker just
            // re-attaches the new controller while keeping its old
            // scroll offset — the header updates but the wheel doesn't,
            // which is the bug we're fixing here.
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Row(
                key: ValueKey(_isImperial),
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
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: palette.accent,
            borderRadius: BorderRadius.circular(4),
            onPressed: _submit,
            // "Next" stays sentence case — widget tests find this string.
            child: Text(
              'Next',
              style: FieldManual.title(color: palette.onAccent),
            ),
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(label.toUpperCase(), style: FieldManual.label()),
          ),
          // Tap-to-type — the big accent-coloured readout doubles as a
          // button. A dotted underline + vertical padding (≥44pt with the
          // 22pt readout) tells the user it's interactive and gives the
          // gesture room.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTapValue,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Text(
                displayValue,
                style: FieldManual.readout(
                  fontSize: 22,
                  color: palette.accent,
                ).copyWith(
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
                    // Wheel values are trained-against numbers → mono
                    // readout (Instrument Panel Rule).
                    style: FieldManual.readout(
                      fontSize: 17,
                      color: palette.text,
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
