import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../models/enums.dart';
import '../../../../providers/nutrition_providers.dart';

/// Manual calorie/macro entry — used when the user knows what they ate but
/// doesn't want to search for it (e.g. home-cooked, restaurant without a
/// hardcoded builder, leftovers).
///
/// Calories are required; macros are optional (collapse by default).
class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key, this.initialMealType = MealType.snack});

  final MealType initialMealType;

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  late MealType _mealType;
  bool _expandMacros = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _mealType = widget.initialMealType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cal = double.tryParse(_caloriesController.text.trim());
    if (cal == null || cal <= 0) {
      showCupertinoToast(context, 'Enter a calorie amount.');
      return;
    }
    final name = _nameController.text.trim().isEmpty
        ? 'Quick add'
        : _nameController.text.trim();
    final pro = double.tryParse(_proteinController.text.trim()) ?? 0;
    final carbs = double.tryParse(_carbsController.text.trim()) ?? 0;
    final fat = double.tryParse(_fatController.text.trim()) ?? 0;

    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    final ok = await addFoodEntry(
      ref,
      mealType: _mealType,
      name: name,
      calories: cal,
      protein: pro,
      carbs: carbs,
      fat: fat,
      servingSize: 1,
      servingUnit: 'serving',
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      showCupertinoToast(context, 'Failed to save. Try again.');
      return;
    }
    Navigator.of(context).pop(true);
    showCupertinoToast(context, 'Added $cal kcal to ${_mealType.label}');
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: palette.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Quick Add',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 16),
              // Calories — primary, large
              CupertinoTextField(
                controller: _caloriesController,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                placeholder: '0',
                decoration: BoxDecoration(
                  color: palette.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 18),
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  color: palette.text,
                ),
                placeholderStyle: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  color: palette.textSecondary.withValues(alpha: 0.5),
                ),
                suffix: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Text(
                    'kcal',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Food name (optional)
              CupertinoTextField(
                controller: _nameController,
                placeholder: 'Food name (optional)',
                decoration: BoxDecoration(
                  color: palette.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                style: TextStyle(color: palette.text, fontSize: 15),
                placeholderStyle:
                    TextStyle(color: palette.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 12),
              // Macros — expand
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _expandMacros = !_expandMacros),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _expandMacros
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      size: 14,
                      color: palette.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _expandMacros ? 'Hide macros' : 'Add macros (optional)',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: palette.accent,
                      ),
                    ),
                  ],
                ),
              ),
              if (_expandMacros) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _macroField(_proteinController, 'Protein')),
                    const SizedBox(width: 8),
                    Expanded(child: _macroField(_carbsController, 'Carbs')),
                    const SizedBox(width: 8),
                    Expanded(child: _macroField(_fatController, 'Fat')),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              // Meal type
              Text(
                'Meal',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              _MealTypeRow(
                selected: _mealType,
                onChanged: (m) {
                  HapticFeedback.selectionClick();
                  setState(() => _mealType = m);
                },
              ),
              const SizedBox(height: 16),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: palette.accent,
                borderRadius: BorderRadius.circular(12),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white)
                    : const Text(
                        'Add',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: CupertinoColors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _macroField(TextEditingController controller, String label) {
    return Builder(builder: (context) {
      final palette = AppColors.of(context);
      return CupertinoTextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        placeholder: label,
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        suffix: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(
            'g',
            style: TextStyle(
              fontSize: 12,
              color: palette.textSecondary,
            ),
          ),
        ),
        style: TextStyle(color: palette.text, fontSize: 14),
        placeholderStyle:
            TextStyle(color: palette.textSecondary, fontSize: 14),
      );
    });
  }
}

class _MealTypeRow extends StatelessWidget {
  const _MealTypeRow({required this.selected, required this.onChanged});

  final MealType selected;
  final ValueChanged<MealType> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: MealType.values
            .map((m) => Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(m),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected == m ? palette.accent : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        m.label,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: selected == m
                              ? Colors.white
                              : palette.text,
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
