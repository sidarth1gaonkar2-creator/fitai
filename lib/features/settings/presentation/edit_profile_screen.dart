import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import '../../../core/utils/tdee_calculator.dart';
import '../../../core/utils/validators.dart';
import '../../../models/enums.dart';
import '../../../models/user_profile.dart';
import '../../../providers/isar_provider.dart';
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
    _nameController = TextEditingController(text: profile?.name ?? '');
    _weightController =
        TextEditingController(text: profile?.weight.toString() ?? '');
    _heightController =
        TextEditingController(text: profile?.height.toString() ?? '');
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

    final weight = double.parse(_weightController.text);
    final height = double.parse(_heightController.text);
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile no longer exists.')),
        );
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

    await isar.writeTxn(() async {
      await isar.userProfiles.put(profile);
    });

    ref.invalidate(userProfileProvider);
    HapticFeedback.mediumImpact();

    if (mounted) {
      context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
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
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration:
                    const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => validatePositiveNumber(v, 'Weight'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heightController,
                decoration:
                    const InputDecoration(labelText: 'Height (cm)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
              ),
              const SizedBox(height: 16),
              Text('Activity Level', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              RadioGroup<ActivityLevel>(
                groupValue: _activityLevel ?? ActivityLevel.moderate,
                onChanged: (v) => setState(() => _activityLevel = v),
                child: Column(
                  children: ActivityLevel.values.map((level) {
                    return ListTile(
                      title: Text(level.label),
                      leading: Radio<ActivityLevel>(
                        value: level,
                      ),
                      onTap: () => setState(() => _activityLevel = level),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
