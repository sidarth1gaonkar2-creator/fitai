import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/nutrient_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/field_manual.dart';
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
          setState(() => _food = detail);
        }
      } catch (_) {
        // Network failure leaves _food with only search-endpoint nutrients
        // — better than blocking the user from saving the entry.
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
    final palette = AppColors.of(context);
    final accent = palette.accent;

    final cal = food.caloriesFor(_servingSize);
    final pro = food.proteinFor(_servingSize);
    final carb = food.carbsFor(_servingSize);
    final fat = food.fatFor(_servingSize);

    return Scaffold(
      backgroundColor: FieldManual.ink,
      appBar: CupertinoNavigationBar(
        middle: Text('ADD FOOD', style: FieldManual.title()),
        backgroundColor: FieldManual.ink.withValues(alpha: 0.82),
        border: const Border(
          bottom: BorderSide(color: FieldManual.hairline),
        ),
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
                  borderRadius: BorderRadius.circular(8),
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
              // Food names are user content — never uppercase.
              style: FieldManual.title().copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            if (food.brand != null) ...[
              const SizedBox(height: 4),
              Text(
                food.brand!,
                style: FieldManual.body(
                  fontSize: 14,
                  color: FieldManual.mutedBone,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),

            // Serving size input
            Text('SERVING SIZE', style: FieldManual.label(fontSize: 10)),
            const SizedBox(height: 8),
            TextField(
              controller: _servingController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: FieldManual.readout(fontSize: 18),
              cursorColor: accent,
              decoration: InputDecoration(
                filled: true,
                fillColor: FieldManual.fieldRaised,
                suffixText: 'G',
                suffixStyle: FieldManual.label(fontSize: 10),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide:
                      const BorderSide(color: FieldManual.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: accent),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
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
                    label: '50G',
                    onTap: () => _setServing(50)),
                _QuickButton(
                    label: '100G',
                    onTap: () => _setServing(100)),
                _QuickButton(
                    label: '150G',
                    onTap: () => _setServing(150)),
                _QuickButton(
                    label: '200G',
                    onTap: () => _setServing(200)),
              ],
            ),
            const SizedBox(height: 24),

            // Nutrition preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FieldManual.field,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FieldManual.hairline),
              ),
              child: Column(
                children: [
                  _NutritionRow(
                    label: 'Calories',
                    value: '${cal.toInt()} KCAL',
                    isBold: true,
                  ),
                  const Divider(height: 16, color: FieldManual.hairline),
                  // Small NutrientIcons dots stay — they aid scanning; the
                  // values themselves are bone mono readouts.
                  _NutritionRow(
                    label: 'Protein',
                    value: '${pro.toStringAsFixed(1)} G',
                    color: NutrientIcons.proteinColor,
                  ),
                  const SizedBox(height: 8),
                  _NutritionRow(
                    label: 'Carbs',
                    value: '${carb.toStringAsFixed(1)} G',
                    color: NutrientIcons.carbsColor,
                  ),
                  const SizedBox(height: 8),
                  _NutritionRow(
                    label: 'Fat',
                    value: '${fat.toStringAsFixed(1)} G',
                    color: NutrientIcons.fatColor,
                  ),
                ],
              ),
            ),


            // Micronutrient preview
            if (_loadingDetail) ...[
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: FieldManual.mutedBone,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading micronutrients…',
                      style: FieldManual.body(
                        fontSize: 13,
                        color: FieldManual.mutedBone,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (food.hasMicronutrients) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FieldManual.field,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FieldManual.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MICRONUTRIENTS', style: FieldManual.title()),
                    const Divider(height: 16, color: FieldManual.hairline),
                    if (food.ironMgFor(_servingSize) != null)
                      _NutritionRow(
                          label: 'Iron',
                          value:
                              '${food.ironMgFor(_servingSize)!.toStringAsFixed(1)} MG'),
                    if (food.calciumMgFor(_servingSize) != null)
                      _NutritionRow(
                          label: 'Calcium',
                          value:
                              '${food.calciumMgFor(_servingSize)!.toStringAsFixed(0)} MG'),
                    if (food.vitaminCMgFor(_servingSize) != null)
                      _NutritionRow(
                          label: 'Vitamin C',
                          value:
                              '${food.vitaminCMgFor(_servingSize)!.toStringAsFixed(1)} MG'),
                    if (food.vitaminDMcgFor(_servingSize) != null)
                      _NutritionRow(
                          label: 'Vitamin D',
                          value:
                              '${food.vitaminDMcgFor(_servingSize)!.toStringAsFixed(1)} MCG'),
                    if (food.magnesiumMgFor(_servingSize) != null)
                      _NutritionRow(
                          label: 'Magnesium',
                          value:
                              '${food.magnesiumMgFor(_servingSize)!.toStringAsFixed(0)} MG'),
                    if (food.potassiumMgFor(_servingSize) != null)
                      _NutritionRow(
                          label: 'Potassium',
                          value:
                              '${food.potassiumMgFor(_servingSize)!.toStringAsFixed(0)} MG'),
                    if (food.zincMgFor(_servingSize) != null)
                      _NutritionRow(
                          label: 'Zinc',
                          value:
                              '${food.zincMgFor(_servingSize)!.toStringAsFixed(1)} MG'),
                    if (food.vitaminB12McgFor(_servingSize) != null)
                      _NutritionRow(
                          label: 'Vitamin B12',
                          value:
                              '${food.vitaminB12McgFor(_servingSize)!.toStringAsFixed(1)} MCG'),
                    if (food.folateMcgFor(_servingSize) != null)
                      _NutritionRow(
                          label: 'Folate',
                          value:
                              '${food.folateMcgFor(_servingSize)!.toStringAsFixed(0)} MCG'),
                    if (food.sodiumMgFor(_servingSize) != null)
                      _NutritionRow(
                          label: 'Sodium',
                          value:
                              '${food.sodiumMgFor(_servingSize)!.toStringAsFixed(0)} MG'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Add button — disabled while fetching USDA detail so the
            // micronutrient fields are populated before the entry is saved.
            FilledButton.icon(
              onPressed: (_isSaving || _loadingDetail) ? null : _addFood,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: palette.onAccent,
                disabledBackgroundColor: FieldManual.fieldRaised,
                disabledForegroundColor: FieldManual.mutedBone,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                textStyle: FieldManual.title(),
              ),
              icon: (_isSaving || _loadingDetail)
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: FieldManual.mutedBone,
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(_loadingDetail
                  ? 'Loading nutrients…'
                  : 'ADD TO ${widget.mealType.label.toUpperCase()}'),
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
          backgroundColor: FieldManual.fieldRaised,
          foregroundColor: FieldManual.bone,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: FieldManual.hairline),
          ),
          textStyle: FieldManual.readout(fontSize: 13),
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
                ? FieldManual.title().copyWith(fontSize: 15)
                : FieldManual.body(fontSize: 14),
          ),
        ),
        Text(
          value,
          style: FieldManual.readout(fontSize: isBold ? 16 : 13),
        ),
      ],
    );
  }
}
