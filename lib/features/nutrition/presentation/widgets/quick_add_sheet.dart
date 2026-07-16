import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../data/food_emojis.dart';
import '../../../../models/enums.dart';
import '../../../../providers/nutrition_providers.dart';
import '../../../../providers/saved_quick_add_providers.dart';
import '../../domain/saved_quick_add.dart';
import 'food_emoji_picker.dart';

/// Manual calorie/macro entry — used when the user knows what they ate but
/// doesn't want to search for it (e.g. home-cooked, restaurant without a
/// hardcoded builder, leftovers).
///
/// Calories are required; macros are optional (collapse by default). The
/// sheet also surfaces the user's saved Quick Add presets at the top so
/// repeat entries (e.g. "Morning coffee 5 kcal") are one tap to log.
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
  bool _saveForLater = false;
  bool _saving = false;
  // When the user tapped a saved preset we keep its id so re-saving with
  // edits updates the existing row instead of creating a duplicate.
  String? _editingPresetId;
  String? _emoji;

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

  void _prefillFromPreset(SavedQuickAdd p) {
    HapticFeedback.selectionClick();
    setState(() {
      _editingPresetId = p.id;
      _nameController.text = p.name;
      _caloriesController.text = p.calories.toInt().toString();
      _proteinController.text = p.protein > 0 ? p.protein.toInt().toString() : '';
      _carbsController.text = p.carbs > 0 ? p.carbs.toInt().toString() : '';
      _fatController.text = p.fat > 0 ? p.fat.toInt().toString() : '';
      _expandMacros = p.protein > 0 || p.carbs > 0 || p.fat > 0;
      _emoji = p.emoji;
    });
  }

  Future<void> _submit() async {
    final cal = double.tryParse(_caloriesController.text.trim());
    if (cal == null || cal <= 0) {
      showCupertinoToast(context, 'Enter a calorie amount.');
      return;
    }
    final rawName = _nameController.text.trim();
    if (_saveForLater && rawName.isEmpty) {
      showCupertinoToast(context, 'Add a name to save this for later.');
      return;
    }
    final name = rawName.isEmpty ? 'Quick add ${cal.toInt()} kcal' : rawName;
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
    // Persist the preset whenever the toggle is on OR when the user is
    // editing an existing preset (so we bump usage stats).
    if (_saveForLater || _editingPresetId != null) {
      await upsertQuickAdd(
        ref,
        id: _editingPresetId,
        name: name,
        calories: cal,
        protein: pro,
        carbs: carbs,
        fat: fat,
        emoji: _emoji,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
    showCupertinoToast(
      context,
      _saveForLater
          ? 'Saved & added to ${_mealType.label}'
          : 'Added $name to ${_mealType.label}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final savedAsync = ref.watch(savedQuickAddsProvider);
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
          child: SingleChildScrollView(
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
                // Saved presets section — only renders when there are any.
                ...savedAsync.maybeWhen(
                  data: (rows) => rows.isEmpty
                      ? const []
                      : [
                          const SizedBox(height: 14),
                          _SavedPresetsRow(
                            rows: rows.take(5).toList(),
                            onTap: _prefillFromPreset,
                            onDelete: (p) async {
                              HapticFeedback.mediumImpact();
                              await deleteQuickAdd(ref, p.id);
                              if (!mounted) return;
                              if (_editingPresetId == p.id) {
                                setState(() => _editingPresetId = null);
                              }
                              if (!context.mounted) return;
                              showCupertinoToast(
                                  context, 'Removed "${p.name}"');
                            },
                          ),
                        ],
                  orElse: () => const [],
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
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                // Food name (optional unless saving)
                CupertinoTextField(
                  controller: _nameController,
                  placeholder: _saveForLater
                      ? 'Name (required to save)'
                      : _placeholderName(),
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
                // Emoji picker — only surfaced when the user opts into
                // saving (or is editing an existing preset). Keeps the
                // one-shot quick-add flow as minimal as possible.
                if (_saveForLater || _editingPresetId != null) ...[
                  const SizedBox(height: 14),
                  FoodEmojiSelector(
                    emoji: _emoji,
                    onChanged: (e) => setState(() => _emoji = e),
                  ),
                ],
                const SizedBox(height: 14),
                // Save-for-later toggle
                _SaveToggle(
                  value: _saveForLater,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _saveForLater = v);
                  },
                ),
                const SizedBox(height: 14),
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
                      : Text(
                          _saveForLater ? 'Save & Add' : 'Add',
                          style: const TextStyle(
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
      ),
    );
  }

  /// Placeholder mirrors the calorie amount the user is typing so it doubles
  /// as a hint about what we'll auto-name the entry if they leave it blank.
  String _placeholderName() {
    final raw = _caloriesController.text.trim();
    final cal = double.tryParse(raw);
    if (cal == null || cal <= 0) return 'Food name (optional)';
    return 'Quick add ${cal.toInt()} kcal';
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

class _SavedPresetsRow extends StatelessWidget {
  const _SavedPresetsRow({
    required this.rows,
    required this.onTap,
    required this.onDelete,
  });

  final List<SavedQuickAdd> rows;
  final ValueChanged<SavedQuickAdd> onTap;
  final ValueChanged<SavedQuickAdd> onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(CupertinoIcons.clock,
                  size: 13, color: palette.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Recent Quick Adds',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: palette.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _PresetChip(
              row: rows[i],
              onTap: () => onTap(rows[i]),
              onDelete: () => onDelete(rows[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.row,
    required this.onTap,
    required this.onDelete,
  });

  final SavedQuickAdd row;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final hasMacros = row.protein > 0 || row.carbs > 0 || row.fat > 0;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              row.emoji ?? FoodEmojis.defaultEmoji,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasMacros
                        ? '${row.calories.toInt()} kcal · '
                            'P${row.protein.toInt()} '
                            'C${row.carbs.toInt()} '
                            'F${row.fat.toInt()}'
                        : '${row.calories.toInt()} kcal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Semantics(
              button: true,
              label: 'Remove entry',
              child: GestureDetector(
                onTap: onDelete,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  size: 16,
                  color: palette.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveToggle extends StatelessWidget {
  const _SaveToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Icon(
            value
                ? CupertinoIcons.checkmark_square_fill
                : CupertinoIcons.square,
            size: 20,
            color: value ? palette.accent : palette.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            'Save for later',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
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
