import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../data/restaurant_menus.dart';
import '../../../models/enums.dart';
import '../../../models/saved_meal_item.dart';
import '../../../providers/nutrition_providers.dart';
import '../../../providers/saved_meal_providers.dart';

class MealBuilderScreen extends ConsumerStatefulWidget {
  const MealBuilderScreen({
    super.key,
    required this.restaurantId,
    this.initialMealType,
  });

  final String restaurantId;
  final MealType? initialMealType;

  @override
  ConsumerState<MealBuilderScreen> createState() =>
      _MealBuilderScreenState();
}

class _MealBuilderScreenState extends ConsumerState<MealBuilderScreen> {
  late RestaurantMenu? _menu;
  late String _builderKey;
  // Per-category selection state. Keyed by category index in the current
  // builder's category list. Stores the indexes of selected items.
  final Map<int, Set<int>> _selections = {};
  late MealType _mealType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _menu = restaurantById(widget.restaurantId);
    _builderKey = _menu?.mealTypes.first ?? '';
    _mealType = widget.initialMealType ?? MealType.lunch;
    _resetSelections();
  }

  void _resetSelections() {
    _selections.clear();
    final categories = _menu?.builders[_builderKey] ?? const [];
    for (var i = 0; i < categories.length; i++) {
      // For required single-pick categories, pre-select the first item so
      // the running total isn't 0/0/0/0 on load.
      if (categories[i].mode == SelectionMode.single &&
          !categories[i].optional &&
          categories[i].items.isNotEmpty) {
        _selections[i] = {0};
      } else {
        _selections[i] = <int>{};
      }
    }
  }

  List<MenuCategory> get _categories =>
      _menu?.builders[_builderKey] ?? const [];

  ({double cal, double pro, double carb, double fat}) get _totals {
    double cal = 0, pro = 0, carb = 0, fat = 0;
    for (final entry in _selections.entries) {
      final cat = _categories[entry.key];
      for (final idx in entry.value) {
        final item = cat.items[idx];
        cal += item.calories;
        pro += item.protein;
        carb += item.carbs;
        fat += item.fat;
      }
    }
    return (cal: cal, pro: pro, carb: carb, fat: fat);
  }

  /// Builds a human name for the assembled meal — used as the FoodEntry name.
  String _composedName() {
    final menu = _menu;
    if (menu == null) return _builderKey;
    final proteinCat = _categories.indexWhere(
        (c) => c.name.toLowerCase().contains('protein'));
    String? proteinPick;
    if (proteinCat >= 0 && (_selections[proteinCat]?.isNotEmpty ?? false)) {
      proteinPick = _categories[proteinCat]
          .items[_selections[proteinCat]!.first]
          .name;
    }
    if (proteinPick != null) {
      return '${menu.name} $proteinPick $_builderKey';
    }
    return '${menu.name} $_builderKey';
  }

  /// Collapses every selected component into a single SavedMealItem set —
  /// reusable both for "Add to Log" (we pass these to addFoodEntry as one
  /// composed entry) and for "Save as Meal" (each component becomes its own
  /// SavedMealItem so the saved meal is editable).
  List<SavedMealItem> _selectedAsSavedItems() {
    final items = <SavedMealItem>[];
    for (final entry in _selections.entries) {
      final cat = _categories[entry.key];
      for (final idx in entry.value) {
        final m = cat.items[idx];
        items.add(SavedMealItem()
          ..foodName = m.name
          ..servingSize = 1
          ..servingUnit = 'serving'
          ..quantity = 1
          ..calories = m.calories
          ..protein = m.protein
          ..carbs = m.carbs
          ..fat = m.fat
          ..fiber = m.fiber
          ..sodium = m.sodium);
      }
    }
    return items;
  }

  Future<void> _addToLog() async {
    final t = _totals;
    if (t.cal <= 0) {
      showCupertinoToast(context, 'Pick at least one item.');
      return;
    }
    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();
    final name = _composedName();
    final ok = await addFoodEntry(
      ref,
      mealType: _mealType,
      name: name,
      calories: t.cal,
      protein: t.pro,
      carbs: t.carb,
      fat: t.fat,
      servingSize: 1,
      servingUnit: 'meal',
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _isSaving = false);
      showCupertinoToast(context, 'Failed to save. Try again.');
      return;
    }
    showCupertinoToast(context, 'Added $name');
    context.go('/nutrition');
  }

  Future<void> _saveAsMeal() async {
    final items = _selectedAsSavedItems();
    if (items.isEmpty) {
      showCupertinoToast(context, 'Pick at least one item first.');
      return;
    }
    HapticFeedback.lightImpact();
    final result = await showCupertinoModalPopup<String>(
      context: context,
      builder: (_) => _NameSavedMealSheet(initialName: _composedName()),
    );
    if (result == null || result.isEmpty || !mounted) return;
    final id = await saveMeal(
      ref,
      name: result,
      emoji: _menu?.emoji,
      items: items,
    );
    if (!mounted) return;
    if (id > 0) {
      showCupertinoToast(context, 'Saved "$result" 🔖');
    }
  }

  void _toggleItem(int categoryIdx, int itemIdx) {
    final cat = _categories[categoryIdx];
    setState(() {
      final current = _selections[categoryIdx] ?? <int>{};
      if (cat.mode == SelectionMode.single) {
        // Allow tapping the active one to deselect (only when optional).
        if (current.contains(itemIdx) && cat.optional) {
          _selections[categoryIdx] = <int>{};
        } else {
          _selections[categoryIdx] = <int>{itemIdx};
        }
      } else {
        // multiple — toggle membership.
        if (current.contains(itemIdx)) {
          current.remove(itemIdx);
        } else {
          current.add(itemIdx);
        }
        _selections[categoryIdx] = current;
      }
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final menu = _menu;
    if (menu == null) {
      return Scaffold(
        appBar: CupertinoNavigationBar(
          middle: const Text('Not found'),
          backgroundColor: palette.background.withValues(alpha: 0.8),
          border: null,
        ),
        body: Center(
          child: Text(
            "We don't have a menu for ${widget.restaurantId} yet.",
            style: TextStyle(color: palette.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final totals = _totals;

    return Scaffold(
      appBar: CupertinoNavigationBar(
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(menu.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(menu.name),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Meal type segmented control (Burrito / Bowl / etc.)
            if (menu.mealTypes.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _MealTypeSelector(
                  options: menu.mealTypes,
                  selected: _builderKey,
                  accent: menu.accentColor,
                  onChanged: (s) {
                    setState(() {
                      _builderKey = s;
                      _resetSelections();
                    });
                  },
                ),
              ),
            // Build steps
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 200),
                itemCount: _categories.length,
                itemBuilder: (context, catIdx) {
                  final category = _categories[catIdx];
                  return _CategoryBlock(
                    category: category,
                    selectedIndexes: _selections[catIdx] ?? const <int>{},
                    accent: menu.accentColor,
                    onToggle: (itemIdx) => _toggleItem(catIdx, itemIdx),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _RunningTotalBar(
        cal: totals.cal,
        pro: totals.pro,
        carb: totals.carb,
        fat: totals.fat,
        mealType: _mealType,
        onMealTypeChanged: (m) => setState(() => _mealType = m),
        isSaving: _isSaving,
        onAddToLog: _addToLog,
        onSaveAsMeal: _saveAsMeal,
        accent: menu.accentColor,
      ),
    );
  }
}

// ─── Meal type selector ───────────────────────────────────────────

class _MealTypeSelector extends StatelessWidget {
  const _MealTypeSelector({
    required this.options,
    required this.selected,
    required this.accent,
    required this.onChanged,
  });

  final List<String> options;
  final String selected;
  final Color accent;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isActive = options[i] == selected;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(options[i]);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? accent : palette.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                options[i],
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isActive ? Colors.white : palette.text,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Category block ───────────────────────────────────────────────

class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({
    required this.category,
    required this.selectedIndexes,
    required this.accent,
    required this.onToggle,
  });

  final MenuCategory category;
  final Set<int> selectedIndexes;
  final Color accent;
  final ValueChanged<int> onToggle;

  String get _hint {
    final mode = category.mode == SelectionMode.single ? 'Pick one' : 'Pick any';
    return category.optional ? '$mode · optional' : mode;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: palette.text,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _hint,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              children: List.generate(category.items.length, (i) {
                final item = category.items[i];
                final isSelected = selectedIndexes.contains(i);
                final showDivider = i < category.items.length - 1;
                return _ItemRow(
                  item: item,
                  isSelected: isSelected,
                  mode: category.mode,
                  accent: accent,
                  onTap: () => onToggle(i),
                  showDivider: showDivider,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.isSelected,
    required this.mode,
    required this.accent,
    required this.onTap,
    required this.showDivider,
  });

  final MenuItem item;
  final bool isSelected;
  final SelectionMode mode;
  final Color accent;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: isSelected
                ? accent.withValues(alpha: 0.08)
                : Colors.transparent,
            child: Row(
              children: [
                _SelectorBadge(
                  mode: mode,
                  isSelected: isSelected,
                  accent: accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: palette.text,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.calories.toInt()} cal',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 50, color: palette.separator),
      ],
    );
  }
}

class _SelectorBadge extends StatelessWidget {
  const _SelectorBadge({
    required this.mode,
    required this.isSelected,
    required this.accent,
  });

  final SelectionMode mode;
  final bool isSelected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    if (mode == SelectionMode.single) {
      // Radio
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? accent : palette.textSecondary,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: isSelected
            ? Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      );
    }
    // Checkbox
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isSelected ? accent : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? accent : palette.textSecondary,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: isSelected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}

// ─── Bottom running total + actions ───────────────────────────────

class _RunningTotalBar extends StatelessWidget {
  const _RunningTotalBar({
    required this.cal,
    required this.pro,
    required this.carb,
    required this.fat,
    required this.mealType,
    required this.onMealTypeChanged,
    required this.isSaving,
    required this.onAddToLog,
    required this.onSaveAsMeal,
    required this.accent,
  });

  final double cal;
  final double pro;
  final double carb;
  final double fat;
  final MealType mealType;
  final ValueChanged<MealType> onMealTypeChanged;
  final bool isSaving;
  final VoidCallback onAddToLog;
  final VoidCallback onSaveAsMeal;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Totals row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        cal.toStringAsFixed(0),
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'cal',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _macro('P', pro, palette.accent),
                      const SizedBox(width: 10),
                      _macro('C', carb, palette.warning),
                      const SizedBox(width: 10),
                      _macro('F', fat, palette.success),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Meal type picker
              _CompactMealTypePicker(
                selected: mealType,
                accent: accent,
                onChanged: onMealTypeChanged,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: accent,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: isSaving ? null : onAddToLog,
                      child: isSaving
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white)
                          : const Text(
                              'Add to Log',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: CupertinoColors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: palette.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: isSaving ? null : onSaveAsMeal,
                      child: Text(
                        'Save Meal',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: palette.text,
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

  Widget _macro(String label, double value, Color color) {
    return Builder(builder: (context) {
      final palette = AppColors.of(context);
      return Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '${value.toStringAsFixed(0)}$label',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: palette.text,
            ),
          ),
        ],
      );
    });
  }
}

class _CompactMealTypePicker extends StatelessWidget {
  const _CompactMealTypePicker({
    required this.selected,
    required this.accent,
    required this.onChanged,
  });

  final MealType selected;
  final Color accent;
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
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(m);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: selected == m ? accent : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        m.label,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
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

class _NameSavedMealSheet extends StatefulWidget {
  const _NameSavedMealSheet({required this.initialName});
  final String initialName;

  @override
  State<_NameSavedMealSheet> createState() => _NameSavedMealSheetState();
}

class _NameSavedMealSheetState extends State<_NameSavedMealSheet> {
  late final TextEditingController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
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
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: palette.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Save this meal',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _ctl,
                autofocus: true,
                placeholder: 'Meal name',
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: palette.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () =>
                          Navigator.of(context).pop(_ctl.text.trim()),
                      child: const Text(
                        'Save',
                        style: TextStyle(color: CupertinoColors.white),
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
