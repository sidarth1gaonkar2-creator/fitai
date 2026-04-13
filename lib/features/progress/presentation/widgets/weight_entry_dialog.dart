import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../providers/progress_providers.dart';
import '../../../../providers/unit_system_provider.dart';
import '../../../../providers/user_profile_provider.dart';

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
      text: displayValue.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final rawValue = double.tryParse(_controller.text);
    if (rawValue == null || rawValue <= 0) return;
    final units = ref.read(unitSystemProvider);
    final kg = UnitConverter.displayWeightToKg(rawValue, units);

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
    final units = ref.watch(unitSystemProvider);
    final unitLabel = UnitConverter.weightUnit(units);

    return CupertinoAlertDialog(
      title: const Text('Log Weight'),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CupertinoTextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          placeholder: 'Weight ($unitLabel)',
          suffix: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(unitLabel),
          ),
          onSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const CupertinoActivityIndicator()
              : Text(
                  'Save',
                  style: TextStyle(color: AppColors.of(context).accent),
                ),
        ),
      ],
    );
  }
}
