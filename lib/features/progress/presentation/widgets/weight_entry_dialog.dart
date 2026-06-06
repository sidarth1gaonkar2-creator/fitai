import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
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
class WeightEntryDialog extends ConsumerStatefulWidget {
  const WeightEntryDialog({super.key});

  @override
  ConsumerState<WeightEntryDialog> createState() => _WeightEntryDialogState();
}

class _WeightEntryDialogState extends ConsumerState<WeightEntryDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final units = ref.read(unitSystemProvider);
    final unitLabel = UnitConverter.weightUnit(units);

    final raw = double.tryParse(_controller.text.trim());
    if (raw == null) {
      showCupertinoToast(context, 'Enter a valid number.');
      return;
    }
    // Sane bounds so a typo (0, negative, or a fat-fingered 1500) can't be
    // saved. Range depends on the unit the user is typing in.
    final (minV, maxV) =
        units == UnitSystem.imperial ? (50.0, 500.0) : (25.0, 225.0);
    if (raw < minV || raw > maxV) {
      showCupertinoToast(
        context,
        'Enter a weight between ${minV.toStringAsFixed(0)}–'
        '${maxV.toStringAsFixed(0)} $unitLabel.',
      );
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

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: palette.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Log Weight',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                placeholder: 'Weight ($unitLabel)',
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontSize: 16,
                  color: palette.text,
                ),
                placeholderStyle: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontSize: 16,
                  color: palette.textSecondary,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                suffix: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    unitLabel,
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: CupertinoColors.white,
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
