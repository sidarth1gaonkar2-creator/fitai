import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../providers/progress_providers.dart';
import '../../../../providers/unit_system_provider.dart';
import '../../../../providers/user_profile_provider.dart';

/// Bottom-sheet weight logger.
///
/// Presented via `showCupertinoModalPopup` so it sits ABOVE the keyboard — the
/// old centered `CupertinoAlertDialog` was covered by the keyboard on smaller
/// devices, which made the field/Save button unreachable. The sheet also
/// dismisses on tap-outside, pre-fills the last logged weight in the user's
/// preferred unit, uses a numeric keyboard, and validates the entry is in a
/// sane range before saving.
///
/// Field Manual input ergonomics (DESIGN.md §Inputs): raised-field fill,
/// hairline border, mono numeric entry, focus shifts the border to the live
/// accent, and validation errors show an alert border + a plain-language
/// message — never color alone.
class WeightEntryDialog extends ConsumerStatefulWidget {
  const WeightEntryDialog({super.key});

  @override
  ConsumerState<WeightEntryDialog> createState() => _WeightEntryDialogState();
}

class _WeightEntryDialogState extends ConsumerState<WeightEntryDialog> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).valueOrNull;
    final units = ref.read(unitSystemProvider);
    final weightKg = profile?.weight ?? 0;
    final displayValue = units == UnitSystem.imperial
        ? UnitConverter.kgToLbs(weightKg)
        : weightKg;
    _controller = TextEditingController(
      text: displayValue > 0 ? displayValue.toStringAsFixed(1) : '',
    );
    // Repaint the input border when focus moves to/from the field.
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final units = ref.read(unitSystemProvider);
    final unitLabel = UnitConverter.weightUnit(units);

    final raw = double.tryParse(_controller.text.trim());
    if (raw == null) {
      setState(() => _error = 'Enter a valid number.');
      return;
    }
    // Sane bounds so a typo (0, negative, or a fat-fingered 1500) can't be
    // saved. Range depends on the unit the user is typing in.
    final (minV, maxV) =
        units == UnitSystem.imperial ? (50.0, 500.0) : (25.0, 225.0);
    if (raw < minV || raw > maxV) {
      setState(() {
        _error = 'Enter a weight between ${minV.toStringAsFixed(0)}–'
            '${maxV.toStringAsFixed(0)} $unitLabel.';
      });
      return;
    }

    final kg = UnitConverter.displayWeightToKg(raw, units);
    setState(() => _isSaving = true);
    final success = await saveWeightEntry(ref, kg);

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() => _isSaving = false);
      showCupertinoToast(context, 'Failed to save.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final units = ref.watch(unitSystemProvider);
    final unitLabel = UnitConverter.weightUnit(units);

    // Focus shifts the border to the live accent; an error outranks focus
    // (alert red + plain message — never color alone).
    final borderColor = _error != null
        ? FieldManual.alert
        : _focusNode.hasFocus
            ? palette.accent
            : FieldManual.hairline;

    return Container(
      decoration: BoxDecoration(
        color: FieldManual.field,
        // Sheets are the 12px surface (DESIGN.md §Cards/Containers).
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      // Lift the content above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: FieldManual.mutedBone.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'LOG WEIGHT',
                textAlign: TextAlign.center,
                style: FieldManual.title(),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                placeholder: 'Weight ($unitLabel)',
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                // Trained-against number — mono entry, arm's-length size.
                style: FieldManual.readout(fontSize: 18),
                placeholderStyle: FieldManual.body(
                  fontSize: 15,
                  color: FieldManual.mutedBone,
                ),
                decoration: BoxDecoration(
                  color: FieldManual.fieldRaised,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: borderColor),
                ),
                suffix: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    unitLabel.toUpperCase(),
                    style: FieldManual.label(fontSize: 11),
                  ),
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _save(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: FieldManual.body(
                      fontSize: 13,
                      // Reading text needs ≥4.5:1 on field — the muted alert
                      // tone stays on the border only.
                      color: palette.destructive,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CupertinoSecondaryButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      label: 'Save',
                      button: true,
                      child: ExcludeSemantics(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          color: palette.accent,
                          borderRadius: BorderRadius.circular(4),
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? CupertinoActivityIndicator(
                                  color: palette.onAccent,
                                )
                              : Text(
                                  'SAVE',
                                  style: TextStyle(
                                    fontFamily: 'Oswald',
                                    fontVariations: const [
                                      FontVariation('wght', 600),
                                    ],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    letterSpacing: 0.6,
                                    color: palette.onAccent,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
