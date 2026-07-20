import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Dismissible, DismissDirection, Icons, Scaffold;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/field_manual.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../models/enums.dart';
import '../../../models/saved_meal_item.dart';
import '../../../providers/saved_meal_providers.dart';
import '../domain/food_search_result.dart';
import 'food_search_screen.dart';
import 'widgets/food_emoji_picker.dart';

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

    if (_isEdit && !_initialLoadDone) {
      return Scaffold(
        backgroundColor: FieldManual.scaffold,
        appBar: CupertinoNavigationBar(
          middle: Text('EDIT MEAL', style: FieldManual.title()),
          backgroundColor: FieldManual.ink.withValues(alpha: 0.82),
          border: const Border(
            bottom: BorderSide(color: FieldManual.hairline),
          ),
        ),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: ShimmerCard(height: 300),
        ),
      );
    }

    return Scaffold(
      backgroundColor: FieldManual.scaffold,
      appBar: CupertinoNavigationBar(
        middle: Text(
          _isEdit ? 'EDIT MEAL' : 'CREATE MEAL',
          style: FieldManual.title(),
        ),
        backgroundColor: FieldManual.ink.withValues(alpha: 0.82),
        border: const Border(
          bottom: BorderSide(color: FieldManual.hairline),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saving ? null : _save,
          child: _saving
              ? const CupertinoActivityIndicator()
              : Text(
                  'SAVE',
                  style: FieldManual.label(
                    color: palette.accent,
                    fontSize: 12,
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
                    style: FieldManual.body(fontSize: 16),
                    placeholderStyle: FieldManual.body(
                      fontSize: 16,
                      color: FieldManual.mutedBone,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: FieldManual.fieldRaised,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: FieldManual.hairline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FoodEmojiSelector(
                    emoji: _emoji,
                    onChanged: (e) => setState(() => _emoji = e),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ITEMS',
                          style: FieldManual.label(fontSize: 10),
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(4),
                        onPressed: _addItem,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add,
                                size: 16, color: palette.onAccent),
                            const SizedBox(width: 4),
                            Text(
                              'ADD ITEM',
                              style: FieldManual.label(
                                color: palette.onAccent,
                                fontSize: 11,
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
                        color: FieldManual.field,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FieldManual.hairline),
                      ),
                      child: Center(
                        child: Text(
                          'No items yet. Tap "Add Item" to search for foods.',
                          textAlign: TextAlign.center,
                          style: FieldManual.body(
                            fontSize: 14,
                            color: FieldManual.mutedBone,
                          ),
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
                              // 0.9 alpha over the dark surface keeps the
                              // bone icon ≥3:1 (same idiom as
                              // food_entry_tile's swipe background).
                              color: palette.destructive
                                  .withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete,
                                color: FieldManual.bone),
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
                color: FieldManual.field,
                border: Border(top: BorderSide(color: FieldManual.hairline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _Total(
                        label: 'KCAL', value: _totalCal.toInt().toString()),
                  ),
                  Expanded(
                    child:
                        _Total(label: 'P', value: '${_totalPro.toInt()}G'),
                  ),
                  Expanded(
                    child: _Total(
                        label: 'C', value: '${_totalCarb.toInt()}G'),
                  ),
                  Expanded(
                    child:
                        _Total(label: 'F', value: '${_totalFat.toInt()}G'),
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
    final total = item.calories * item.quantity;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FieldManual.field,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FieldManual.hairline),
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
                    style: FieldManual.title(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${item.servingSize.toStringAsFixed(0)} ${item.servingUnit}'
                    ' · ${item.quantity}× serving',
                    style: FieldManual.label(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${total.toInt()} KCAL',
              style: FieldManual.readout(fontSize: 13),
            ),
            const SizedBox(width: 6),
            const Icon(CupertinoIcons.chevron_right,
                size: 14, color: FieldManual.mutedBone),
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
    return Column(
      children: [
        Text(
          value,
          style: FieldManual.readout(fontSize: 16),
        ),
        Text(
          label,
          style: FieldManual.label(fontSize: 11),
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
        color: FieldManual.ink,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
                color: FieldManual.hairlineStrong,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: FieldManual.title(),
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
              borderRadius: BorderRadius.circular(4),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'DONE',
                style: FieldManual.label(
                  color: palette.onAccent,
                  fontSize: 12,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: FieldManual.label(fontSize: 10),
        ),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          style: FieldManual.readout(fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: FieldManual.fieldRaised,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: FieldManual.hairline),
          ),
        ),
      ],
    );
  }
}
