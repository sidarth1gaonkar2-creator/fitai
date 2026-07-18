import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
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
          color: FieldManual.ink,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
                      color: FieldManual.mutedBone.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'QUICK ADD',
                  textAlign: TextAlign.center,
                  style: FieldManual.title(),
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
                _FmFocusRing(
                  builder: (context, focused) => CupertinoTextField(
                    controller: _caloriesController,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    placeholder: '0',
                    decoration: BoxDecoration(
                      color: FieldManual.fieldRaised,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color:
                            focused ? palette.accent : FieldManual.hairline,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 18),
                    style: FieldManual.readout(fontSize: 28),
                    placeholderStyle: FieldManual.readout(
                      fontSize: 28,
                      color: FieldManual.mutedBone.withValues(alpha: 0.5),
                    ),
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child:
                          Text('KCAL', style: FieldManual.label(fontSize: 11)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 12),
                // Food name (optional unless saving)
                _FmFocusRing(
                  builder: (context, focused) => CupertinoTextField(
                    controller: _nameController,
                    placeholder: _saveForLater
                        ? 'Name (required to save)'
                        : _placeholderName(),
                    decoration: BoxDecoration(
                      color: FieldManual.fieldRaised,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color:
                            focused ? palette.accent : FieldManual.hairline,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    style: FieldManual.body(fontSize: 15),
                    placeholderStyle: FieldManual.body(
                      fontSize: 15,
                      color: FieldManual.mutedBone,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Macros — expand
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _expandMacros = !_expandMacros),
                  // ≥44pt tap target for the expander row.
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
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
                          _expandMacros
                              ? 'Hide macros'
                              : 'Add macros (optional)',
                          style: FieldManual.body(
                            fontSize: 13,
                            color: palette.accent,
                          ),
                        ),
                      ],
                    ),
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
                Text('MEAL', style: FieldManual.label(fontSize: 11)),
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
                  borderRadius: BorderRadius.circular(4),
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? CupertinoActivityIndicator(
                          color: palette.onAccent)
                      : Text(
                          _saveForLater ? 'SAVE & ADD' : 'ADD',
                          style: FieldManual.title(color: palette.onAccent),
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
      return _FmFocusRing(
        builder: (context, focused) => CupertinoTextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          placeholder: label,
          decoration: BoxDecoration(
            color: FieldManual.fieldRaised,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: focused ? palette.accent : FieldManual.hairline,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffix: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('G', style: FieldManual.label(fontSize: 11)),
          ),
          style: FieldManual.readout(fontSize: 14),
          placeholderStyle: FieldManual.body(
            fontSize: 14,
            color: FieldManual.mutedBone,
          ),
        ),
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
    final ts = MediaQuery.textScalerOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              const Icon(CupertinoIcons.clock,
                  size: 13, color: FieldManual.mutedBone),
              const SizedBox(width: 4),
              Text(
                'RECENT QUICK ADDS',
                style: FieldManual.label(fontSize: 11),
              ),
            ],
          ),
        ),
        SizedBox(
          height: ts.scale(64),
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
    final hasMacros = row.protein > 0 || row.carbs > 0 || row.fat > 0;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: FieldManual.field,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FieldManual.hairline),
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
                    // Preset names are user content — never uppercase.
                    style: FieldManual.title().copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasMacros
                        ? '${row.calories.toInt()} KCAL · '
                            'P${row.protein.toInt()} '
                            'C${row.carbs.toInt()} '
                            'F${row.fat.toInt()}'
                        : '${row.calories.toInt()} KCAL',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FieldManual.readout(
                      fontSize: 10,
                      color: FieldManual.mutedBone,
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
                // ≥44pt tap target; the icon stays visually small.
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 16,
                    color: FieldManual.mutedBone.withValues(alpha: 0.6),
                  ),
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
    // Spoken as a checkbox; the visual row is excluded to avoid
    // double-reading.
    return Semantics(
      checked: value,
      label: 'Save for later',
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!value),
          child: Row(
            children: [
              Icon(
                value
                    ? CupertinoIcons.checkmark_square_fill
                    : CupertinoIcons.square,
                size: 20,
                color: value ? palette.accent : FieldManual.mutedBone,
              ),
              const SizedBox(width: 8),
              Text(
                'Save for later',
                style: FieldManual.body(fontSize: 14),
              ),
            ],
          ),
        ),
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
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: FieldManual.field,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: FieldManual.hairline),
      ),
      child: Row(
        children: MealType.values
            .map((m) => Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected == m,
                    child: GestureDetector(
                      onTap: () => onChanged(m),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: duration,
                        constraints: const BoxConstraints(minHeight: 44),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected == m ? palette.accent : null,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          m.label.toUpperCase(),
                          style: FieldManual.label(
                            fontSize: 11,
                            color: selected == m
                                ? palette.onAccent
                                : FieldManual.mutedBone,
                          ),
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

/// Tracks whether a descendant text field holds focus so the builder can
/// paint the Field Manual accent focus border. Presentation only — the
/// wrapper node is unfocusable and skipped in traversal, so keyboard and
/// tap behavior are untouched.
class _FmFocusRing extends StatefulWidget {
  const _FmFocusRing({required this.builder});

  final Widget Function(BuildContext context, bool focused) builder;

  @override
  State<_FmFocusRing> createState() => _FmFocusRingState();
}

class _FmFocusRingState extends State<_FmFocusRing> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: widget.builder(context, _focused),
    );
  }
}
