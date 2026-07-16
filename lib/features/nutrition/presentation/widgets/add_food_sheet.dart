import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../models/enums.dart';
import '../../../../providers/nutrition_providers.dart';
import '../../../../providers/saved_meal_providers.dart';
import '../../../../models/saved_meal_item.dart';
import '../../domain/food_search_result.dart';
import 'serving_size_picker.dart';

/// Bottom-sheet add-food flow. Replaces the old full-screen [FoodDetailScreen]
/// for cases where a quick log is what the user wants — coming from search,
/// barcode scan, restaurant builder pre-fill, or recent-foods one-tap re-add.
///
/// Call via `showCupertinoModalPopup` so it slides up over the current
/// screen. The sheet:
///   1. Shows the food name/brand/photo
///   2. Renders [ServingSizePicker] for flexible portions
///   3. Live nutrition preview that recomputes on every picker tick
///   4. Meal destination segmented control (Breakfast / Lunch / Dinner / Snack)
///   5. Add Food (primary) + Add & Save to Meal (secondary)
class AddFoodSheet extends ConsumerStatefulWidget {
  const AddFoodSheet({
    super.key,
    required this.food,
    this.initialMealType = MealType.lunch,
  });

  final FoodSearchResult food;
  final MealType initialMealType;

  @override
  ConsumerState<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends ConsumerState<AddFoodSheet> {
  late MealType _mealType;
  ServingSelection? _serving;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _mealType = widget.initialMealType;
  }

  double get _grams => _serving?.totalGrams ?? widget.food.defaultServingSize;

  Future<void> _addFood({bool alsoSaveAsMeal = false}) async {
    final food = widget.food;
    final g = _grams;
    if (g <= 0) {
      showCupertinoToast(context, 'Pick a serving first.');
      return;
    }
    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    final ok = await addFoodEntry(
      ref,
      mealType: _mealType,
      name: food.name,
      calories: food.caloriesFor(g),
      protein: food.proteinFor(g),
      carbs: food.carbsFor(g),
      fat: food.fatFor(g),
      servingSize: g,
      servingUnit: _serving?.label ?? food.servingUnit,
      fibre: food.fibreFor(g),
      sugar: food.sugarFor(g),
      sodiumMg: food.sodiumMgFor(g),
      vitaminDMcg: food.vitaminDMcgFor(g),
      ironMg: food.ironMgFor(g),
      calciumMg: food.calciumMgFor(g),
      vitaminCMg: food.vitaminCMgFor(g),
      magnesiumMg: food.magnesiumMgFor(g),
      potassiumMg: food.potassiumMgFor(g),
      zincMg: food.zincMgFor(g),
      vitaminB12Mcg: food.vitaminB12McgFor(g),
      folateMcg: food.folateMcgFor(g),
    );

    if (!mounted) return;
    if (!ok) {
      setState(() => _isSaving = false);
      showCupertinoToast(context, 'Failed to save. Try again.');
      return;
    }
    if (alsoSaveAsMeal) {
      // Save a single-item meal template alongside logging it. We bypass
      // SaveMealSheet here because the user already named/specified things
      // via the food itself — the food name doubles as the meal name.
      await _saveAsSingleItemMeal();
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
    showCupertinoToast(
      context,
      alsoSaveAsMeal
          ? 'Added & saved as a meal'
          : 'Added to ${_mealType.label}',
    );
  }

  Future<void> _saveAsSingleItemMeal() async {
    final food = widget.food;
    final g = _grams;
    final item = SavedMealItem()
      ..foodName = food.name
      ..fdcId = food.fdcId?.toString()
      ..barcode = food.barcode
      ..servingSize = g
      ..servingUnit = _serving?.label ?? food.servingUnit
      ..quantity = 1
      ..calories = food.caloriesFor(g)
      ..protein = food.proteinFor(g)
      ..carbs = food.carbsFor(g)
      ..fat = food.fatFor(g)
      ..fiber = food.fibreFor(g)
      ..sugar = food.sugarFor(g)
      ..sodium = food.sodiumMgFor(g)
      ..vitaminDMcg = food.vitaminDMcgFor(g)
      ..ironMg = food.ironMgFor(g)
      ..calciumMg = food.calciumMgFor(g)
      ..vitaminCMg = food.vitaminCMgFor(g)
      ..magnesiumMg = food.magnesiumMgFor(g)
      ..potassiumMg = food.potassiumMgFor(g)
      ..zincMg = food.zincMgFor(g)
      ..vitaminB12Mcg = food.vitaminB12McgFor(g)
      ..folateMcg = food.folateMcgFor(g);
    await saveMeal(
      ref,
      name: food.name,
      emoji: '🍽',
      items: [item],
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final food = widget.food;
    final g = _grams;

    final cal = food.caloriesFor(g);
    final pro = food.proteinFor(g);
    final carb = food.carbsFor(g);
    final fat = food.fatFor(g);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Grabber
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: palette.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header: photo + name ─────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (food.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              food.imageUrl!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox(width: 0),
                            ),
                          ),
                        if (food.imageUrl != null) const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                food.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: palette.text,
                                ),
                              ),
                              if (food.brand != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  food.brand!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.xmark, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Close',
                          color: palette.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ── Serving picker ──────────────────────────────
                    ServingSizePicker(
                      food: food,
                      onChanged: (s) => setState(() => _serving = s),
                    ),
                    const SizedBox(height: 16),
                    // ── Live nutrition preview ──────────────────────
                    LiveNutritionPreview(
                      calories: cal,
                      protein: pro,
                      carbs: carb,
                      fat: fat,
                    ),
                    const SizedBox(height: 16),
                    // ── Meal destination ───────────────────────────
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
                    _MealTypeSegmented(
                      selected: _mealType,
                      onChanged: (m) {
                        HapticFeedback.selectionClick();
                        setState(() => _mealType = m);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            // ── Actions ──────────────────────────────────────────
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(12),
                        onPressed:
                            _isSaving ? null : () => _addFood(),
                        child: _isSaving
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white)
                            : const Text(
                                'Add Food',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: CupertinoColors.white,
                                ),
                              ),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      onPressed: _isSaving
                          ? null
                          : () => _addFood(alsoSaveAsMeal: true),
                      child: Text(
                        'Add & Save to Meals',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: palette.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealTypeSegmented extends StatelessWidget {
  const _MealTypeSegmented({required this.selected, required this.onChanged});

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
