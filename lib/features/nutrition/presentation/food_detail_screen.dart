import 'dart:developer' as dev;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../models/enums.dart';
import '../../../providers/nutrition_providers.dart';
import '../domain/food_search_result.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  const FoodDetailScreen({
    super.key,
    required this.mealType,
    required this.food,
  });

  final MealType mealType;
  final FoodSearchResult food;

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  late final TextEditingController _servingController;
  double _servingSize = 100;
  bool _isSaving = false;
  late FoodSearchResult _food;
  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();
    _food = widget.food;
    _servingSize = widget.food.defaultServingSize;
    _servingController =
        TextEditingController(text: _servingSize.toInt().toString());
    _fetchDetailIfNeeded();
  }

  Future<void> _fetchDetailIfNeeded() async {
    // If this is a USDA food without micronutrients, fetch the full detail
    if (_food.source == FoodSource.usda &&
        _food.fdcId != null &&
        !_food.hasMicronutrients) {
      setState(() => _loadingDetail = true);
      try {
        final service = ref.read(usdaServiceProvider);
        final detail = await service.getFoodDetail(_food.fdcId!);
        if (detail != null && mounted) {
          dev.log(
            '[FoodDetail] Enriched "${_food.name}" with micros: '
            'iron=${detail.ironMgPer100g} calcium=${detail.calciumMgPer100g} '
            'vitC=${detail.vitaminCMgPer100g} vitD=${detail.vitaminDMcgPer100g}',
            name: 'FitAI.Nutrition',
          );
          setState(() => _food = detail);
        }
      } catch (e) {
        dev.log('[FoodDetail] Failed to fetch detail: $e',
            name: 'FitAI.Nutrition');
      } finally {
        if (mounted) setState(() => _loadingDetail = false);
      }
    }
  }

  @override
  void dispose() {
    _servingController.dispose();
    super.dispose();
  }

  Future<void> _addFood() async {
    setState(() => _isSaving = true);

    final food = _food;
    final g = _servingSize;
    final success = await addFoodEntry(
      ref,
      mealType: widget.mealType,
      name: food.name,
      calories: food.caloriesFor(g),
      protein: food.proteinFor(g),
      carbs: food.carbsFor(g),
      fat: food.fatFor(g),
      servingSize: g,
      servingUnit: food.servingUnit,
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

    if (success) {
      context.go('/nutrition');
    } else {
      setState(() => _isSaving = false);
      showCupertinoToast(context, 'Failed to save. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final food = _food;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final cal = food.caloriesFor(_servingSize);
    final pro = food.proteinFor(_servingSize);
    final carb = food.carbsFor(_servingSize);
    final fat = food.fatFor(_servingSize);

    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: const Text('Add Food'),
        backgroundColor: AppColors.of(context).background.withValues(alpha: 0.8),
        border: null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Food image + name
            if (food.imageUrl != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    food.imageUrl!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            if (food.imageUrl != null) const SizedBox(height: 16),
            Text(
              food.name,
              style: textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (food.brand != null) ...[
              const SizedBox(height: 4),
              Text(
                food.brand!,
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),

            // Serving size input
            Text('Serving size',
                style: textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _servingController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                suffixText: 'g',
              ),
              onChanged: (value) {
                final parsed = double.tryParse(value);
                if (parsed != null && parsed > 0) {
                  setState(() => _servingSize = parsed);
                }
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                _QuickButton(
                    label: '50g',
                    onTap: () => _setServing(50)),
                _QuickButton(
                    label: '100g',
                    onTap: () => _setServing(100)),
                _QuickButton(
                    label: '150g',
                    onTap: () => _setServing(150)),
                _QuickButton(
                    label: '200g',
                    onTap: () => _setServing(200)),
              ],
            ),
            const SizedBox(height: 24),

            // Nutrition preview
            Card.filled(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _NutritionRow(
                      label: 'Calories',
                      value: '${cal.toInt()} kcal',
                      isBold: true,
                    ),
                    const Divider(height: 16),
                    _NutritionRow(
                      label: 'Protein',
                      value: '${pro.toStringAsFixed(1)} g',
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    _NutritionRow(
                      label: 'Carbs',
                      value: '${carb.toStringAsFixed(1)} g',
                      color: colorScheme.tertiary,
                    ),
                    const SizedBox(height: 8),
                    _NutritionRow(
                      label: 'Fat',
                      value: '${fat.toStringAsFixed(1)} g',
                      color: colorScheme.secondary,
                    ),
                  ],
                ),
              ),
            ),


            // Micronutrient preview
            if (_loadingDetail) ...[
              const SizedBox(height: 16),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Loading micronutrients…',
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ] else if (food.hasMicronutrients) ...[
              const SizedBox(height: 12),
              Card.filled(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Micronutrients',
                        style: textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Divider(height: 16),
                      if (food.ironMgFor(_servingSize) != null)
                        _NutritionRow(
                            label: 'Iron',
                            value:
                                '${food.ironMgFor(_servingSize)!.toStringAsFixed(1)} mg'),
                      if (food.calciumMgFor(_servingSize) != null)
                        _NutritionRow(
                            label: 'Calcium',
                            value:
                                '${food.calciumMgFor(_servingSize)!.toStringAsFixed(0)} mg'),
                      if (food.vitaminCMgFor(_servingSize) != null)
                        _NutritionRow(
                            label: 'Vitamin C',
                            value:
                                '${food.vitaminCMgFor(_servingSize)!.toStringAsFixed(1)} mg'),
                      if (food.vitaminDMcgFor(_servingSize) != null)
                        _NutritionRow(
                            label: 'Vitamin D',
                            value:
                                '${food.vitaminDMcgFor(_servingSize)!.toStringAsFixed(1)} mcg'),
                      if (food.magnesiumMgFor(_servingSize) != null)
                        _NutritionRow(
                            label: 'Magnesium',
                            value:
                                '${food.magnesiumMgFor(_servingSize)!.toStringAsFixed(0)} mg'),
                      if (food.potassiumMgFor(_servingSize) != null)
                        _NutritionRow(
                            label: 'Potassium',
                            value:
                                '${food.potassiumMgFor(_servingSize)!.toStringAsFixed(0)} mg'),
                      if (food.zincMgFor(_servingSize) != null)
                        _NutritionRow(
                            label: 'Zinc',
                            value:
                                '${food.zincMgFor(_servingSize)!.toStringAsFixed(1)} mg'),
                      if (food.vitaminB12McgFor(_servingSize) != null)
                        _NutritionRow(
                            label: 'Vitamin B12',
                            value:
                                '${food.vitaminB12McgFor(_servingSize)!.toStringAsFixed(1)} mcg'),
                      if (food.folateMcgFor(_servingSize) != null)
                        _NutritionRow(
                            label: 'Folate',
                            value:
                                '${food.folateMcgFor(_servingSize)!.toStringAsFixed(0)} mcg'),
                      if (food.sodiumMgFor(_servingSize) != null)
                        _NutritionRow(
                            label: 'Sodium',
                            value:
                                '${food.sodiumMgFor(_servingSize)!.toStringAsFixed(0)} mg'),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Add button
            FilledButton.icon(
              onPressed: _isSaving ? null : _addFood,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text('Add to ${widget.mealType.label}'),
            ),
          ],
        ),
      ),
    );
  }

  void _setServing(double grams) {
    setState(() => _servingSize = grams);
    _servingController.text = grams.toInt().toString();
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.tonal(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: Size.zero,
        ),
        child: Text(label),
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  const _NutritionRow({
    required this.label,
    required this.value,
    this.color,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        if (color != null) ...[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: isBold
                ? textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)
                : textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: isBold
              ? textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)
              : textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
