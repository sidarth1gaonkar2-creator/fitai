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
  // Always assigned NEW Set instances on update so child widgets see a new
  // reference and rebuild — an in-place mutation can be missed when child
  // widgets compare by identity (which is fine for radios but defeats the
  // checkbox tap-to-toggle UX).
  final Map<int, Set<int>> _selections = {};
  // Tracks which categories have the "Double Protein" toggle enabled. Keyed
  // by category index — only meaningful for categories with allowDouble:true.
  final Set<int> _doubled = <int>{};
  // Tracks categories with the "Half & Half" toggle on (Chipotle-style
  // half-and-half protein). When on, the picker collects TWO single
  // selections and each contributes 0.5× nutrition to the total.
  final Set<int> _halfHalf = <int>{};
  late MealType _mealType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _menu = restaurantById(widget.restaurantId);
    _builderKey = _menu?.mealTypes.first ?? '';
    _mealType = widget.initialMealType ?? MealType.lunch;
    _initSelections();
  }

  /// Starts every category EMPTY so the user must explicitly pick something
  /// — previously we pre-selected index 0 on required-single categories,
  /// which surprised users (the running total wasn't zero on entry and felt
  /// like the protein was "stuck at 2x" of whatever they actually wanted).
  ///
  /// The single exception is categories with exactly one item — a mandatory
  /// flour tortilla or "base" with no alternatives. Those auto-select so the
  /// UI doesn't show a single-item radio that the user must tap.
  void _initSelections() {
    _selections.clear();
    _doubled.clear();
    _halfHalf.clear();
    final categories = _menu?.builders[_builderKey] ?? const [];
    for (var i = 0; i < categories.length; i++) {
      final cat = categories[i];
      if (cat.mode == SelectionMode.single &&
          !cat.optional &&
          cat.items.length == 1) {
        _selections[i] = <int>{0};
      } else {
        _selections[i] = <int>{};
      }
    }
  }

  /// Switches the active builder (e.g. Bowl → Burrito) while preserving any
  /// already-picked items that exist by name in the new builder. The match
  /// is by category-name + item-name pair so renames are tolerated and the
  /// user keeps their rice/protein/toppings across the meal-type switch.
  void _switchBuilder(String newKey) {
    final oldKey = _builderKey;
    if (newKey == oldKey) return;

    final oldCats = _menu?.builders[oldKey] ?? const [];
    final selectedPairs = <(String, String)>{}; // (category name, item name)
    final doubledCats = <String>{};
    final halfHalfCats = <String>{};
    _selections.forEach((catIdx, items) {
      if (catIdx >= oldCats.length) return;
      final cat = oldCats[catIdx];
      for (final idx in items) {
        if (idx < cat.items.length) {
          selectedPairs.add((cat.name, cat.items[idx].name));
        }
      }
      if (_doubled.contains(catIdx)) doubledCats.add(cat.name);
      if (_halfHalf.contains(catIdx)) halfHalfCats.add(cat.name);
    });

    _builderKey = newKey;
    final newCats = _menu?.builders[newKey] ?? const [];
    _selections.clear();
    _doubled.clear();
    _halfHalf.clear();
    for (var i = 0; i < newCats.length; i++) {
      final cat = newCats[i];
      final keep = <int>{};
      for (var j = 0; j < cat.items.length; j++) {
        if (selectedPairs.contains((cat.name, cat.items[j].name))) {
          keep.add(j);
          // Single-mode categories can hold only one selection — except when
          // half-and-half is on for that category in the new builder, which
          // permits up to two protein picks.
          if (cat.mode == SelectionMode.single &&
              !(cat.allowHalfHalf && halfHalfCats.contains(cat.name)) &&
              keep.isNotEmpty) {
            break;
          }
        }
      }
      // If nothing carried over, fall back to auto-select for single-item
      // mandatory categories (e.g. a forced Tortilla on Burrito switch).
      if (keep.isEmpty &&
          cat.mode == SelectionMode.single &&
          !cat.optional &&
          cat.items.length == 1) {
        keep.add(0);
      }
      // Apply maxSelections cap defensively in case the old builder had a
      // looser limit than the new one.
      if (cat.maxSelections != null && keep.length > cat.maxSelections!) {
        final trimmed = keep.take(cat.maxSelections!).toSet();
        keep
          ..clear()
          ..addAll(trimmed);
      }
      _selections[i] = keep;
      if (doubledCats.contains(cat.name) && cat.allowDouble) _doubled.add(i);
      if (halfHalfCats.contains(cat.name) && cat.allowHalfHalf) {
        _halfHalf.add(i);
      }
    }
  }

  List<MenuCategory> get _categories =>
      _menu?.builders[_builderKey] ?? const [];

  /// Effective per-item multiplier for a category.
  ///   * Double on → 2× (both items in a half&half category, if double is
  ///     somehow also on, end up at 1× each because the doubling overrides
  ///     the halving — but in practice the UI prevents enabling both)
  ///   * Half & Half on → 0.5× per selected item (two halves = full meal)
  ///   * Neither → 1×
  double _qty(int catIdx) {
    if (_halfHalf.contains(catIdx)) return 0.5;
    if (_doubled.contains(catIdx)) return 2.0;
    return 1.0;
  }

  ({
    double cal,
    double pro,
    double carb,
    double fat,
    double? fibre,
    double? sodiumMg,
  }) get _totals {
    double cal = 0, pro = 0, carb = 0, fat = 0;
    double fibre = 0, sodium = 0;
    bool anyFibre = false, anySodium = false;
    for (final entry in _selections.entries) {
      final catIdx = entry.key;
      if (catIdx >= _categories.length) continue;
      final cat = _categories[catIdx];
      final qty = _qty(catIdx);
      for (final idx in entry.value) {
        if (idx >= cat.items.length) continue;
        final item = cat.items[idx];
        cal += item.calories * qty;
        pro += item.protein * qty;
        carb += item.carbs * qty;
        fat += item.fat * qty;
        if (item.fiber != null) {
          fibre += item.fiber! * qty;
          anyFibre = true;
        }
        if (item.sodium != null) {
          sodium += item.sodium! * qty;
          anySodium = true;
        }
      }
    }
    return (
      cal: cal,
      pro: pro,
      carb: carb,
      fat: fat,
      fibre: anyFibre ? fibre : null,
      sodiumMg: anySodium ? sodium : null,
    );
  }

  /// Builds a human name for the assembled meal — used as the FoodEntry name.
  /// Prefixes "Double" when the protein category is doubled, or "Half X + Half
  /// Y" when half-and-half mode is on for a multi-pick protein category.
  String _composedName() {
    final menu = _menu;
    if (menu == null) return _builderKey;
    final proteinCat = _categories.indexWhere(
        (c) => c.name.toLowerCase().contains('protein'));
    String? proteinPick;
    if (proteinCat >= 0 && (_selections[proteinCat]?.isNotEmpty ?? false)) {
      final picks = _selections[proteinCat]!;
      if (_halfHalf.contains(proteinCat) && picks.length == 2) {
        final names = picks
            .map((i) => _categories[proteinCat].items[i].name)
            .toList();
        proteinPick = 'Half ${names[0]} + Half ${names[1]}';
      } else {
        proteinPick = _categories[proteinCat].items[picks.first].name;
        if (_doubled.contains(proteinCat)) proteinPick = 'Double $proteinPick';
      }
    }
    if (proteinPick != null) {
      return '${menu.name} $proteinPick $_builderKey';
    }
    return '${menu.name} $_builderKey';
  }

  /// Collapses every selected component into a SavedMealItem list. The
  /// quantity field carries the effective multiplier (2× for double, 0.5× for
  /// half&half, 1× otherwise) so logging or re-using the saved meal preserves
  /// the user's portioning intent.
  List<SavedMealItem> _selectedAsSavedItems() {
    final items = <SavedMealItem>[];
    for (final entry in _selections.entries) {
      final catIdx = entry.key;
      if (catIdx >= _categories.length) continue;
      final cat = _categories[catIdx];
      final qty = _qty(catIdx);
      for (final idx in entry.value) {
        if (idx >= cat.items.length) continue;
        final m = cat.items[idx];
        final prefix = qty == 2
            ? 'Double '
            : qty == 0.5
                ? 'Half '
                : '';
        items.add(SavedMealItem()
          ..foodName = '$prefix${m.name}'
          ..servingSize = 1
          ..servingUnit = 'serving'
          ..quantity = qty
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
      fibre: t.fibre,
      sodiumMg: t.sodiumMg,
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
      // ALWAYS create a new Set instance — see field-level comment on
      // _selections. Mutating-in-place can leave checkbox UIs stale because
      // the reference doesn't change and child widgets that compare-by-
      // identity may skip rebuilds.
      final current = Set<int>.from(_selections[categoryIdx] ?? const <int>{});
      final isHalfHalf = _halfHalf.contains(categoryIdx);

      if (cat.mode == SelectionMode.single) {
        if (isHalfHalf) {
          // Half-and-half lets the user pick TWO items in a normally-single
          // category. Tapping a third deselects the OLDEST kept item so the
          // selection stays at ≤2. Tapping a currently-active item deselects.
          if (current.contains(itemIdx)) {
            current.remove(itemIdx);
            _selections[categoryIdx] = current;
          } else if (current.length < 2) {
            current.add(itemIdx);
            _selections[categoryIdx] = current;
          } else {
            // Drop the first-picked, add the new one (Set iteration order
            // is insertion order in Dart 2.7+).
            final next = current.skip(1).toSet()..add(itemIdx);
            _selections[categoryIdx] = next;
          }
        } else {
          // Tapping the active radio in an optional category deselects it.
          // Required-single can't be left empty by tapping the active row.
          if (current.contains(itemIdx) && cat.optional) {
            _selections[categoryIdx] = <int>{};
          } else {
            _selections[categoryIdx] = <int>{itemIdx};
          }
          // Switching protein clears the double flag — otherwise the user
          // can flip from one protein to another and miss that 2× is still
          // on a now-different item.
          if (cat.allowDouble && !current.contains(itemIdx)) {
            _doubled.remove(categoryIdx);
          }
        }
      } else {
        // multiple — toggle membership, with optional maxSelections cap.
        if (current.contains(itemIdx)) {
          current.remove(itemIdx);
        } else {
          final cap = cat.maxSelections;
          if (cap != null && current.length >= cap) {
            // At cap. The user must explicitly deselect something before
            // adding more — feedback handled via the disabled-row visual in
            // _ItemRow. Bail without changing state.
            return;
          }
          current.add(itemIdx);
        }
        _selections[categoryIdx] = current;
      }
    });
    HapticFeedback.selectionClick();
  }

  void _toggleDouble(int categoryIdx) {
    setState(() {
      if (_doubled.contains(categoryIdx)) {
        _doubled.remove(categoryIdx);
      } else {
        _doubled.add(categoryIdx);
        // Double and Half&Half are mutually exclusive on the same category.
        _halfHalf.remove(categoryIdx);
      }
    });
    HapticFeedback.lightImpact();
  }

  void _toggleHalfHalf(int categoryIdx) {
    setState(() {
      if (_halfHalf.contains(categoryIdx)) {
        _halfHalf.remove(categoryIdx);
        // Going back from half&half → single — trim selection to one item.
        final current = Set<int>.from(
            _selections[categoryIdx] ?? const <int>{});
        if (current.length > 1) {
          _selections[categoryIdx] = <int>{current.first};
        }
      } else {
        _halfHalf.add(categoryIdx);
        // Mutually exclusive with Double — clear the double flag.
        _doubled.remove(categoryIdx);
      }
    });
    HapticFeedback.lightImpact();
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
                  onChanged: (s) => setState(() => _switchBuilder(s)),
                ),
              ),
            // Build steps
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 200),
                itemCount: _categories.length,
                itemBuilder: (context, catIdx) {
                  final category = _categories[catIdx];
                  final selectedIdx =
                      _selections[catIdx] ?? const <int>{};
                  return _CategoryBlock(
                    category: category,
                    selectedIndexes: selectedIdx,
                    accent: menu.accentColor,
                    onToggle: (itemIdx) => _toggleItem(catIdx, itemIdx),
                    isDoubled: _doubled.contains(catIdx),
                    onToggleDouble: () => _toggleDouble(catIdx),
                    isHalfHalf: _halfHalf.contains(catIdx),
                    onToggleHalfHalf: () => _toggleHalfHalf(catIdx),
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
    required this.isDoubled,
    required this.onToggleDouble,
    required this.isHalfHalf,
    required this.onToggleHalfHalf,
  });

  final MenuCategory category;
  final Set<int> selectedIndexes;
  final Color accent;
  final ValueChanged<int> onToggle;

  /// Whether the "Double Protein" / "Double X" toggle is on. Only meaningful
  /// when [MenuCategory.allowDouble] is true.
  final bool isDoubled;
  final VoidCallback onToggleDouble;

  /// Whether the "Half & Half" toggle is on for this category. Only
  /// meaningful when [MenuCategory.allowHalfHalf] is true.
  final bool isHalfHalf;
  final VoidCallback onToggleHalfHalf;

  String get _hint {
    final cap = category.maxSelections;
    final count = selectedIndexes.length;
    String mode;
    if (isHalfHalf) {
      mode = '(pick two halves)';
    } else if (category.mode == SelectionMode.single) {
      mode = '(pick one)';
    } else if (cap != null) {
      // Running counter — drives the "Protein (2 of 3 max)" UX so the user
      // can see at a glance how many more they can stack.
      mode = '($count of $cap max)';
    } else {
      mode = '(pick any)';
    }
    return category.optional ? '$mode · optional' : mode;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final hasSelection = selectedIndexes.isNotEmpty;
    final cap = category.maxSelections;
    final isAtCap =
        cap != null && selectedIndexes.length >= cap;
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
                // At cap: unselected rows look (and behave) disabled until
                // the user removes an existing pick.
                final isDisabled =
                    isAtCap && !isSelected && category.mode == SelectionMode.multiple;
                return _ItemRow(
                  item: item,
                  isSelected: isSelected,
                  mode: category.mode,
                  accent: accent,
                  isDoubled: isDoubled && isSelected,
                  isHalfPortion: isHalfHalf && isSelected,
                  isDisabled: isDisabled,
                  onTap: isDisabled ? null : () => onToggle(i),
                  showDivider: showDivider,
                );
              }),
            ),
          ),
          if (category.allowHalfHalf) ...[
            const SizedBox(height: 8),
            _ModifierToggle(
              icon: CupertinoIcons.square_split_2x1,
              labelOn: 'Half & Half — pick two',
              labelOff: 'Half & Half',
              isOn: isHalfHalf,
              accent: accent,
              onToggle: onToggleHalfHalf,
            ),
          ],
          if (category.allowDouble && hasSelection && !isHalfHalf) ...[
            const SizedBox(height: 8),
            _ModifierToggle(
              icon: CupertinoIcons.plus_app,
              labelOn: 'Double Protein (2×) — on',
              labelOff: 'Double Protein (2×)',
              isOn: isDoubled,
              accent: accent,
              onToggle: onToggleDouble,
            ),
          ],
        ],
      ),
    );
  }
}

/// Reusable on/off pill used by both the Double Protein and Half & Half
/// toggles. The labels and icon vary per use site; behaviour is identical.
class _ModifierToggle extends StatelessWidget {
  const _ModifierToggle({
    required this.icon,
    required this.labelOn,
    required this.labelOff,
    required this.isOn,
    required this.accent,
    required this.onToggle,
  });

  final IconData icon;
  final String labelOn;
  final String labelOff;
  final bool isOn;
  final Color accent;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isOn
              ? accent.withValues(alpha: 0.12)
              : palette.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOn ? accent : palette.border,
            width: isOn ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isOn ? accent : palette.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isOn ? labelOn : labelOff,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isOn ? accent : palette.text,
                ),
              ),
            ),
            CupertinoSwitch(
              value: isOn,
              onChanged: (_) => onToggle(),
              activeTrackColor: accent,
            ),
          ],
        ),
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
    required this.isDoubled,
    required this.isHalfPortion,
    required this.isDisabled,
    required this.onTap,
    required this.showDivider,
  });

  final MenuItem item;
  final bool isSelected;
  final SelectionMode mode;
  final Color accent;
  final bool isDoubled;
  final bool isHalfPortion;
  final bool isDisabled;

  /// Null when the row is disabled (max-selections reached). The InkWell
  /// no-onTap state suppresses the ripple naturally.
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    // Selected rows show the SIGNED contribution to the running total
    // ("+180 cal"); unselected rows show the unsigned per-item kcal. The
    // effective value reflects the active multiplier — 2× when doubled,
    // 0.5× when half-portion — so the user can sanity-check at a glance.
    double effectiveCal = item.calories;
    if (isDoubled) effectiveCal *= 2;
    if (isHalfPortion) effectiveCal *= 0.5;
    final calLabel = isSelected
        ? '+${effectiveCal.toInt()} cal'
        : '${item.calories.toInt()} cal';

    final nameColor = isDisabled
        ? palette.textSecondary.withValues(alpha: 0.5)
        : palette.text;
    final calColor = isDisabled
        ? palette.textSecondary.withValues(alpha: 0.4)
        : (isSelected ? accent : palette.textSecondary);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: isSelected
                ? accent.withValues(alpha: 0.10)
                : Colors.transparent,
            child: Row(
              children: [
                _SelectorBadge(
                  mode: mode,
                  isSelected: isSelected,
                  accent: accent,
                  dimmed: isDisabled,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14,
                            color: nameColor,
                          ),
                        ),
                      ),
                      if (isDoubled) ...[
                        const SizedBox(width: 6),
                        _MultiplierBadge(text: '2×', accent: accent),
                      ],
                      if (isHalfPortion) ...[
                        const SizedBox(width: 6),
                        _MultiplierBadge(text: '½', accent: accent),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  calLabel,
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: calColor,
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

class _MultiplierBadge extends StatelessWidget {
  const _MultiplierBadge({required this.text, required this.accent});
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 10,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SelectorBadge extends StatelessWidget {
  const _SelectorBadge({
    required this.mode,
    required this.isSelected,
    required this.accent,
    this.dimmed = false,
  });

  final SelectionMode mode;
  final bool isSelected;
  final Color accent;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final borderColor = dimmed
        ? palette.textSecondary.withValues(alpha: 0.3)
        : (isSelected ? accent : palette.textSecondary);
    if (mode == SelectionMode.single) {
      // Radio
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
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
        border: Border.all(color: borderColor, width: 2),
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
