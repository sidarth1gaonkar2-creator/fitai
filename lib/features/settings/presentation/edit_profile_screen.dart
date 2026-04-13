import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/tdee_calculator.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../models/enums.dart';
import '../../../models/user_profile.dart';
import '../../../providers/isar_provider.dart';
import '../../../providers/unit_system_provider.dart';
import '../../../providers/user_profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _ageController;
  Sex? _sex;
  Goal? _goal;
  ActivityLevel? _activityLevel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).valueOrNull;
    final units = ref.read(unitSystemProvider);
    _nameController = TextEditingController(text: profile?.name ?? '');
    final weightKg = profile?.weight ?? 0;
    final heightCm = profile?.height ?? 0;
    _weightController = TextEditingController(
      text: units == UnitSystem.imperial
          ? UnitConverter.kgToLbs(weightKg).toStringAsFixed(1)
          : weightKg.toString(),
    );
    _heightController = TextEditingController(
      text: units == UnitSystem.imperial
          ? UnitConverter.cmToFtIn(heightCm)
          : heightCm.toString(),
    );
    _ageController =
        TextEditingController(text: profile?.age.toString() ?? '');
    _sex = profile?.sex;
    _goal = profile?.goal;
    _activityLevel = profile?.activityLevel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sex == null || _goal == null || _activityLevel == null) return;

    setState(() => _isSaving = true);

    final units = ref.read(unitSystemProvider);
    final rawWeight = double.parse(_weightController.text);
    final weight = UnitConverter.displayWeightToKg(rawWeight, units);
    final height = units == UnitSystem.imperial
        ? UnitConverter.ftInToCm(_heightController.text)
        : double.parse(_heightController.text);
    final age = int.parse(_ageController.text);

    final bmr = calculateBMR(
      weightKg: weight,
      heightCm: height,
      age: age,
      sex: _sex!,
    );
    final tdee = calculateTDEE(bmr: bmr, activityLevel: _activityLevel!);

    final isar = ref.read(isarProvider);
    final profile =
        await isar.userProfiles.where().anyId().build().findFirst();

    if (profile == null) {
      if (mounted) {
        showCupertinoToast(context, 'Profile no longer exists.');
        context.go('/onboarding');
      }
      return;
    }

    profile
      ..name = _nameController.text.trim()
      ..age = age
      ..sex = _sex!
      ..weight = weight
      ..height = height
      ..goal = _goal!
      ..activityLevel = _activityLevel!
      ..tdee = tdee;

    try {
      await isar.writeTxn(() async {
        await isar.userProfiles.put(profile);
      });

      ref.invalidate(userProfileProvider);
      HapticFeedback.mediumImpact();

      if (mounted) {
        context.go('/settings');
      }
    } catch (_) {
      if (mounted) {
        showCupertinoToast(context, 'Could not save profile. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final units = ref.watch(unitSystemProvider);
    final weightLabel = 'Weight (${UnitConverter.weightUnit(units)})';
    final heightLabel =
        units == UnitSystem.imperial ? 'Height (ft\'in")' : 'Height (cm)';

    final palette = AppColors.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: CupertinoNavigationBar(
        middle: const Text('Edit Profile'),
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => validateRequired(v, 'Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: validateAge,
              ),
              const SizedBox(height: 16),
              Text('Sex', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<Sex>(
                segments: Sex.values
                    .map((s) =>
                        ButtonSegment(value: s, label: Text(s.label)))
                    .toList(),
                selected: _sex != null ? {_sex!} : {},
                onSelectionChanged: (s) =>
                    setState(() => _sex = s.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: palette.accent,
                  selectedForegroundColor: palette.text,
                  foregroundColor: palette.text.withValues(alpha: 0.7),
                  backgroundColor: palette.surface,
                  side: BorderSide(color: palette.border),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(labelText: weightLabel),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => validatePositiveNumber(v, 'Weight'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heightController,
                decoration: InputDecoration(labelText: heightLabel),
                keyboardType: units == UnitSystem.imperial
                    ? TextInputType.text
                    : const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => validatePositiveNumber(v, 'Height'),
              ),
              const SizedBox(height: 16),
              Text('Goal', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<Goal>(
                segments: Goal.values
                    .map((g) =>
                        ButtonSegment(value: g, label: Text(g.label)))
                    .toList(),
                selected: _goal != null ? {_goal!} : {},
                onSelectionChanged: (s) =>
                    setState(() => _goal = s.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: palette.accent,
                  selectedForegroundColor: palette.text,
                  foregroundColor: palette.text.withValues(alpha: 0.7),
                  backgroundColor: palette.surface,
                  side: BorderSide(color: palette.border),
                ),
              ),
              const SizedBox(height: 16),
              Text('Activity Level', style: textTheme.labelLarge),
              const SizedBox(height: 4),
              ...ActivityLevel.values.map((level) {
                final selected = _activityLevel == level;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _activityLevel = level),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.circle,
                          color: selected
                              ? palette.accent
                              : palette.text.withValues(alpha: 0.4),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(level.label)),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: palette.accent,
                disabledColor: palette.accent.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const CupertinoActivityIndicator(color: Colors.black)
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
