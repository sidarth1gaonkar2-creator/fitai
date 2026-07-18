import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/field_manual.dart';
import '../../../core/utils/imperial_height_formatter.dart';
import '../../../core/utils/tdee_calculator.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/logger.dart';
import '../../../models/enums.dart';
import '../../../models/user_profile.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/isar_provider.dart';
import '../../../providers/nutrition_providers.dart';
import '../../../providers/unit_system_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../onboarding/data/remote_profile_repository.dart';

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
    // Use the canonical heightToDisplay so the imperial format matches what
    // the parser expects on save ("6'1\""). cmToFtIn returns the same shape
    // but heightToDisplay also handles the inches-overflow edge case.
    _heightController = TextEditingController(
      text: heightCm > 0
          ? UnitConverter.heightToDisplay(heightCm.toDouble(), units)
          : '',
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

  /// Form-level validator for the height field. Handles both metric ("185")
  /// and imperial ("6'1\"" or "73") inputs and clamps to a reasonable human
  /// range. Pulled out as a method so it can read the current UnitSystem.
  String? _validateHeight(String? value) {
    if (value == null || value.trim().isEmpty) return 'Height is required';
    final units = ref.read(unitSystemProvider);
    final cm = UnitConverter.displayHeightToCm(value, units);
    if (cm == null) {
      return units == UnitSystem.imperial
          ? 'Enter height as 6\'1" or in total inches'
          : 'Enter height in centimeters';
    }
    // Sanity range: 3'0" (91 cm) to 8'0" (244 cm).
    if (cm < 91 || cm > 244) return 'Please enter a valid height';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sex == null || _goal == null || _activityLevel == null) return;

    setState(() => _isSaving = true);

    final units = ref.read(unitSystemProvider);
    final rawWeight = double.parse(_weightController.text);
    final weight = UnitConverter.displayWeightToKg(rawWeight, units);
    // Validation has already accepted the height; null here would be a
    // programming error, but guard with a sensible default rather than
    // crashing on an unexpected edge case.
    final height = UnitConverter.displayHeightToCm(
          _heightController.text,
          units,
        ) ??
        170.0;
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

    // Changing goal type means the user wants re-derived macros — clear any
    // custom Coach overrides so the goal-based split takes over again.
    final goalChanged = profile.goal != _goal;

    profile
      ..name = _nameController.text.trim()
      ..age = age
      ..sex = _sex!
      ..weight = weight
      ..height = height
      ..goal = _goal!
      ..activityLevel = _activityLevel!
      ..tdee = tdee;
    if (goalChanged) {
      profile
        ..calorieGoal = null
        ..proteinGoalG = null
        ..carbsGoalG = null
        ..fatGoalG = null;
    }

    try {
      await isar.writeTxn(() async {
        await isar.userProfiles.put(profile);
      });

      ref.invalidate(userProfileProvider);
      await _syncProfileToRemote(profile);
      HapticFeedback.mediumImpact();

      if (mounted) {
        context.go('/settings');
      }
    } catch (e, st) {
      AppLogger.error('Profile save failed', error: e, stack: st);
      if (mounted) {
        showCupertinoToast(context, 'Could not save profile. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Mirrors the profile (incl. custom goal overrides + clears) to the private
  /// Firestore doc so changes survive on new devices. Best-effort.
  Future<void> _syncProfileToRemote(UserProfile profile) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    try {
      await ref
          .read(remoteProfileRepositoryProvider)
          .save(uid, RemoteProfile.fromLocal(profile));
    } catch (e, st) {
      AppLogger.error('EditProfile: remote profile sync failed',
          error: e, stack: st);
    }
  }

  /// Clears the custom Coach goal overrides so targets revert to goal-derived.
  Future<void> _resetTargetsToRecommended() async {
    final isar = ref.read(isarProvider);
    final profile =
        await isar.userProfiles.where().anyId().build().findFirst();
    if (profile == null) return;
    profile
      ..calorieGoal = null
      ..proteinGoalG = null
      ..carbsGoalG = null
      ..fatGoalG = null;
    try {
      await isar.writeTxn(() async {
        await isar.userProfiles.put(profile);
      });
      ref.invalidate(userProfileProvider);
      await _syncProfileToRemote(profile);
      if (mounted) {
        showCupertinoToast(context, 'Targets reset to recommended.');
      }
    } catch (_) {
      if (mounted) showCupertinoToast(context, 'Could not reset targets.');
    }
  }

  /// The Instrument Panel Rule: numeric entry sets in mono.
  TextStyle _monoInputStyle(Palette palette) =>
      FieldManual.readout(fontSize: 16, color: palette.text);

  /// Neutralizes the M3 tint on [SegmentedButton] into the Field Manual
  /// idiom: field ground, hairline border, sharp 4px geometry, the selected
  /// segment filled with the live accent carrying on-accent mono type.
  ButtonStyle _segmentedStyle(Palette palette) => ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.accent
              : FieldManual.field,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.onAccent
              : FieldManual.mutedBone,
        ),
        textStyle: WidgetStatePropertyAll(FieldManual.label(fontSize: 12)),
        side: const WidgetStatePropertyAll(
          BorderSide(color: FieldManual.hairline),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
        overlayColor:
            WidgetStatePropertyAll(palette.accent.withValues(alpha: 0.12)),
      );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final units = ref.watch(unitSystemProvider);
    final weightLabel = 'Weight (${UnitConverter.weightUnit(units)})';
    final heightLabel =
        units == UnitSystem.imperial ? 'Height (ft\'in")' : 'Height (cm)';

    final palette = AppColors.of(context);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final overridesActive = profile != null &&
        (profile.calorieGoal != null ||
            profile.proteinGoalG != null ||
            profile.carbsGoalG != null ||
            profile.fatGoalG != null);
    final targets = profile != null ? resolveDailyTargets(profile) : null;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: CupertinoNavigationBar(
        // Field Manual nav: Oswald designation, hairline rule.
        middle: Text('EDIT PROFILE', style: FieldManual.title()),
        backgroundColor: palette.background.withValues(alpha: 0.82),
        border: Border(bottom: BorderSide(color: palette.border, width: 0.5)),
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
                // Numeric entry sets in mono — the Instrument Panel Rule.
                style: _monoInputStyle(palette),
                keyboardType: TextInputType.number,
                validator: validateAge,
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Sex'),
              const SizedBox(height: 8),
              SegmentedButton<Sex>(
                segments: Sex.values
                    .map((s) =>
                        ButtonSegment(value: s, label: Text(s.label)))
                    .toList(),
                selected: _sex != null ? {_sex!} : {},
                onSelectionChanged: (s) =>
                    setState(() => _sex = s.first),
                style: _segmentedStyle(palette),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(labelText: weightLabel),
                style: _monoInputStyle(palette),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => validatePositiveNumber(v, 'Weight'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heightController,
                decoration: InputDecoration(
                  labelText: heightLabel,
                  hintText: units == UnitSystem.imperial ? "6'1\"" : '185',
                ),
                style: _monoInputStyle(palette),
                keyboardType: units == UnitSystem.imperial
                    ? TextInputType.text
                    : const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: units == UnitSystem.imperial
                    ? [ImperialHeightFormatter()]
                    : [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                validator: _validateHeight,
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Goal'),
              const SizedBox(height: 8),
              SegmentedButton<Goal>(
                segments: Goal.values
                    .map((g) =>
                        ButtonSegment(value: g, label: Text(g.label)))
                    .toList(),
                selected: _goal != null ? {_goal!} : {},
                onSelectionChanged: (s) =>
                    setState(() => _goal = s.first),
                style: _segmentedStyle(palette),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Activity Level'),
              const SizedBox(height: 4),
              ...ActivityLevel.values.map((level) {
                final selected = _activityLevel == level;
                return Semantics(
                  button: true,
                  selected: selected,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _activityLevel = level),
                    child: Padding(
                      // ≥44pt row: 22pt glyph + 2×12 vertical padding.
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.circle,
                            color: selected
                                ? palette.accent
                                : palette.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(level.label)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (targets != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _FieldLabel('Daily targets'),
                          const SizedBox(width: 8),
                          if (overridesActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: palette.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Custom · set by Coach',
                                style: textTheme.labelSmall
                                    ?.copyWith(color: palette.accent),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // The most trained-against numbers in the app — mono, the
                      // Instrument Panel Rule.
                      Text(
                        '${targets.calories.toInt()} KCAL · '
                        '${targets.protein.toInt()}G P · '
                        '${targets.carbs.toInt()}G C · '
                        '${targets.fat.toInt()}G F',
                        style: FieldManual.readout(fontSize: 14),
                      ),
                      if (overridesActive) ...[
                        const SizedBox(height: 12),
                        // Secondary idiom: transparent + hairline border, bone
                        // label, ≥44pt (was a bare ~20pt accent-text tap zone
                        // that failed AA on the lower-contrast packs).
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _resetTargetsToRecommended,
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: palette.border),
                            ),
                            child: Text(
                              'RESET TO RECOMMENDED',
                              style: FieldManual.label(
                                fontSize: 12,
                                color: FieldManual.bone,
                              ),
                            ),
                          ),
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Derived from your goal. The AI Coach can propose '
                            'custom targets.',
                            style: textTheme.bodySmall
                                ?.copyWith(color: palette.textSecondary),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: palette.accent,
                disabledColor: palette.accent.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? CupertinoActivityIndicator(color: palette.onAccent)
                    : Text(
                        'SAVE CHANGES',
                        style: FieldManual.title(color: palette.onAccent),
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

/// Uppercase mono section label above a form control group. The uppercase is
/// visual; callers pass sentence case so semantics speak it naturally.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        label: text,
        child: ExcludeSemantics(
          child: Text(text.toUpperCase(), style: FieldManual.label()),
        ),
      );
}
