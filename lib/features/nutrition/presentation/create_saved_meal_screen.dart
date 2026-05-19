import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Dismissible, DismissDirection, Icons, Scaffold, Theme;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../models/enums.dart';
import '../../../models/saved_meal_item.dart';
import '../../../providers/saved_meal_providers.dart';
import '../domain/food_search_result.dart';
import 'food_search_screen.dart';

/// Build-a-saved-meal-from-scratch screen. When [savedMealId] is non-null
/// the screen pre-loads that meal and switches to edit mode.
class CreateSavedMealScreen extends ConsumerStatefulWidget {
  const CreateSavedMealScreen({super.key, this.savedMealId});

  /// `null` → create mode. Non-null → edit existing meal.
  final int? savedMealId;

  @override
  ConsumerState<CreateSavedMealScreen> createState() =>
      _CreateSavedMealScreenState();
}

class _CreateSavedMealScreenState
    extends ConsumerState<CreateSavedMealScreen> {
  static const List<String> _quickEmoji = [
    '🥗', '🍳', '🥑', '🍗', '🥩', '🍜', '🥤', '🍎'
  ];

  final TextEditingController _nameController = TextEditingController();
  String? _emoji;
  final List<SavedMealItem> _items = [];
  bool _saving = false;
  bool _initialLoadDone = false;

  bool get _isEdit => widget.savedMealId != null;

  @override
  void initState() {
    super.initState();
    if (!_isEdit) _initialLoadDone = true;
  }

  Future<void> _loadForEdit() async {
    if (_initialLoadDone || !_isEdit) return;
    final id = widget.savedMealId!;
    try {
      final all = await ref.read(savedMealsProvider.future);
      final meal = all.where((m) => m.id == id).firstOrNull;
      if (meal == null) {
        // Stale ID; show empty form.
        if (mounted) setState(() => _initialLoadDone = true);
        return;
      }
      final items = await ref.read(savedMealItemsProvider(id).future);
      if (!mounted) return;
      setState(() {
        _nameController.text = meal.name;
        _emoji = meal.emoji;
        _items
          ..clear()
          ..addAll(items.map(_cloneItem));
        _initialLoadDone = true;
      });
    } catch (_) {
      if (mounted) setState(() => _initialLoadDone = true);
    }
  }

  /// Clone so edits to the staging list don't mutate the cached Isar object.
  SavedMealItem _cloneItem(SavedMealItem src) {
    return SavedMealItem()
      ..foodName = src.foodName
      ..fdcId = src.fdcId
      ..barcode = src.barcode
      ..servingSize = src.servingSize
      ..servingUnit = src.servingUnit
      ..quantity = src.quantity
      ..calories = src.calories
      ..protein = src.protein
      ..carbs = src.carbs
      ..fat = src.fat
      ..fiber = src.fiber
      ..sugar = src.sugar
      ..sodium = src.sodium
      ..vitaminDMcg = src.vitaminDMcg
      ..ironMg = src.ironMg
      ..calciumMg = src.calciumMg
      ..vitaminCMg = src.vitaminCMg
      ..magnesiumMg = src.magnesiumMg
      ..potassiumMg = src.potassiumMg
      ..zincMg = src.zincMg
      ..vitaminB12Mcg = src.vitaminB12Mcg
      ..folateMcg = src.folateMcg;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  double get _totalCal =>
      _items.fold(0, (s, i) => s + i.calories * i.quantity);
  double get _totalPro =>
      _items.fold(0, (s, i) => s + i.protein * i.quantity);
  double get _totalCarb =>
      _items.fold(0, (s, i) => s + i.carbs * i.quantity);
  double get _totalFat =>
      _items.fold(0, (s, i) => s + i.fat * i.quantity);

  Future<void> _addItem() async {
    HapticFeedback.selectionClick();
    // Push the existing food search screen in returnMode — when the user
    // taps a result it pops with a FoodSearchResult.
    final result = await Navigator.of(context).push<FoodSearchResult>(
      CupertinoPageRoute(
        builder: (_) => const FoodSearchScreen(
          mealType: MealType.snack, // Meal type unused in returnMode.
          returnMode: true,
        ),
      ),
    );
    if (!mounted || result == null) return;
    final servingGrams = result.defaultServingSize > 0
        ? result.defaultServingSize
        : 100.0;
    setState(() {
      _items.add(savedMealItemFromSearchResult(result, servingGrams));
    });
  }

  Future<void> _editItemServing(int index) async {
    final item = _items[index];
    final servingController = TextEditingController(
      text: item.servingSize.toStringAsFixed(0),
    );
    final qtyController = TextEditingController(
      text: item.quantity.toStringAsFixed(item.quantity == item.quantity.toInt() ? 0 : 1),
    );
    final saved = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (sheetCtx) => _EditItemSheet(
        name: item.foodName,
        servingUnit: item.servingUnit,
        servingController: servingController,
        qtyController: qtyController,
      ),
    );
    servingController.dispose();
    qtyController.dispose();
    if (!mounted) return;
    if (saved != true) return;

    final newServing =
        double.tryParse(servingController.text) ?? item.servingSize;
    final newQty = double.tryParse(qtyController.text) ?? item.quantity;
    if (newServing <= 0 || newQty <= 0) return;

    // Scale stored nutrition values to the new serving size — the original
    // per-serving numbers were captured against the *old* serving.
    final scale = newServing / item.servingSize;
    setState(() {
      item.calories *= scale;
      item.protein *= scale;
      item.carbs *= scale;
      item.fat *= scale;
      item.fiber = item.fiber == null ? null : item.fiber! * scale;
      item.sugar = item.sugar == null ? null : item.sugar! * scale;
      item.sodium = item.sodium == null ? null : item.sodium! * scale;
      item.servingSize = newServing;
      item.quantity = newQty;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showCupertinoToast(context, 'Give your meal a name first');
      return;
    }
    if (_items.isEmpty) {
      showCupertinoToast(context, 'Add at least one food item');
      return;
    }
    setState(() => _saving = true);
    bool ok = false;
    try {
      if (_isEdit) {
        ok = await updateSavedMeal(
          ref,
          mealId: widget.savedMealId!,
          name: name,
          emoji: _emoji,
          items: _items,
        );
      } else {
        await saveMeal(ref, name: name, emoji: _emoji, items: _items);
        ok = true;
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    if (ok) {
      showCupertinoToast(
        context,
        _isEdit ? 'Changes saved' : 'Meal saved',
      );
      Navigator.of(context).pop();
    } else {
      showCupertinoToast(context, 'Could not save meal');
    }
  }

  @override
  Widget build(BuildContext context) {
    // First-build hook for edit mode — uses a post-frame callback so we
    // don't `ref.read` during build phase.
    if (_isEdit && !_initialLoadDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadForEdit());
    }

    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    if (_isEdit && !_initialLoadDone) {
      return Scaffold(
        backgroundColor: palette.background,
        appBar: CupertinoNavigationBar(
          middle: const Text('Edit Meal'),
          backgroundColor: palette.background.withValues(alpha: 0.8),
          border: null,
        ),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: ShimmerCard(height: 300),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: CupertinoNavigationBar(
        middle: Text(_isEdit ? 'Edit Meal' : 'Create Meal'),
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saving ? null : _save,
          child: _saving
              ? const CupertinoActivityIndicator()
              : Text(
                  _isEdit ? 'Save' : 'Save',
                  style: TextStyle(
                    color: palette.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  CupertinoTextField(
                    controller: _nameController,
                    placeholder: 'Meal name',
                    style: TextStyle(color: palette.text, fontSize: 16),
                    placeholderStyle:
                        TextStyle(color: palette.textSecondary),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: palette.border),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickEmoji.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final candidate = _quickEmoji[i];
                        final selected = candidate == _emoji;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() =>
                                _emoji = selected ? null : candidate);
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? palette.accent.withValues(alpha: 0.2)
                                  : palette.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? palette.accent
                                    : palette.border,
                              ),
                            ),
                            child: Text(
                              candidate,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Items',
                          style: textTheme.labelLarge?.copyWith(
                            color: palette.accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(10),
                        onPressed: _addItem,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add,
                                size: 16, color: CupertinoColors.white),
                            SizedBox(width: 4),
                            Text(
                              'Add Item',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette.border),
                      ),
                      child: Center(
                        child: Text(
                          'No items yet. Tap "Add Item" to search for foods.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: palette.textSecondary),
                        ),
                      ),
                    )
                  else
                    for (int i = 0; i < _items.length; i++)
                      Padding(
                        key: ValueKey(
                            'item-$i-${_items[i].foodName.hashCode}'),
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Dismissible(
                          key: ValueKey(
                              'dismiss-$i-${_items[i].foodName.hashCode}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: palette.destructive,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete,
                                color: CupertinoColors.white),
                          ),
                          onDismissed: (_) =>
                              setState(() => _items.removeAt(i)),
                          child: _ItemRow(
                            item: _items[i],
                            onTap: () => _editItemServing(i),
                          ),
                        ),
                      ),
                ],
              ),
            ),
            // Totals footer
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 12 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border(top: BorderSide(color: palette.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _Total(
                        label: 'kcal', value: _totalCal.toInt().toString()),
                  ),
                  Expanded(
                    child:
                        _Total(label: 'P', value: '${_totalPro.toInt()}g'),
                  ),
                  Expanded(
                    child: _Total(
                        label: 'C', value: '${_totalCarb.toInt()}g'),
                  ),
                  Expanded(
                    child:
                        _Total(label: 'F', value: '${_totalFat.toInt()}g'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onTap});

  final SavedMealItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final total = item.calories * item.quantity;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.foodName,
                    style: textTheme.bodyMedium?.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${item.servingSize.toStringAsFixed(0)} ${item.servingUnit}'
                    ' · ${item.quantity}× serving',
                    style: textTheme.bodySmall
                        ?.copyWith(color: palette.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${total.toInt()} kcal',
              style: textTheme.bodyMedium?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(CupertinoIcons.chevron_right,
                size: 14, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: palette.text,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _EditItemSheet extends StatelessWidget {
  const _EditItemSheet({
    required this.name,
    required this.servingUnit,
    required this.servingController,
    required this.qtyController,
  });

  final String name;
  final String servingUnit;
  final TextEditingController servingController;
  final TextEditingController qtyController;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: palette.text,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'Serving size ($servingUnit)',
            controller: servingController,
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: 'Quantity (servings)',
            controller: qtyController,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: palette.accent,
              borderRadius: BorderRadius.circular(12),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: palette.text, fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: palette.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}
