import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/nutrient_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cupertino_helpers.dart' as helpers;
import '../../../models/enums.dart';
import '../../../providers/custom_meal_plan_providers.dart';
import '../domain/food_search_result.dart';
import 'food_search_screen.dart';

const _goalOptions = ['Lose Fat', 'Build Muscle', 'Maintain', 'Custom'];

class CreateMealPlanScreen extends ConsumerStatefulWidget {
  const CreateMealPlanScreen({super.key});

  @override
  ConsumerState<CreateMealPlanScreen> createState() =>
      _CreateMealPlanScreenState();
}

class _CreateMealPlanScreenState extends ConsumerState<CreateMealPlanScreen> {
  final _nameController = TextEditingController();
  String? _selectedGoal;
  final Map<MealType, List<FoodSearchResult>> _mealFoods = {
    for (final type in MealType.values) type: [],
  };
  bool _saving = false;

  double get _totalCalories => _allFoods.fold(0, (s, f) => s + f.caloriesPer100g * (f.defaultServingSize) / 100);
  double get _totalProtein => _allFoods.fold(0, (s, f) => s + f.proteinPer100g * (f.defaultServingSize) / 100);
  double get _totalCarbs => _allFoods.fold(0, (s, f) => s + f.carbsPer100g * (f.defaultServingSize) / 100);
  double get _totalFat => _allFoods.fold(0, (s, f) => s + f.fatPer100g * (f.defaultServingSize) / 100);
  Iterable<FoodSearchResult> get _allFoods =>
      _mealFoods.values.expand((list) => list);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addFood(MealType mealType) async {
    final result = await Navigator.of(context).push<FoodSearchResult>(
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: FoodSearchScreen(mealType: mealType, returnMode: true),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _mealFoods[mealType]!.add(result));
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      helpers.showCupertinoToast(context, 'Please enter a plan name');
      return;
    }
    if (_allFoods.isEmpty) {
      helpers.showCupertinoToast(context, 'Add at least one food');
      return;
    }

    setState(() => _saving = true);

    final meals = <MealType, List<PlanFood>>{};
    for (final entry in _mealFoods.entries) {
      if (entry.value.isEmpty) continue;
      meals[entry.key] = entry.value
          .map((f) => PlanFood(
                name: f.name,
                calories: f.caloriesFor(f.defaultServingSize),
                protein: f.proteinFor(f.defaultServingSize),
                carbs: f.carbsFor(f.defaultServingSize),
                fat: f.fatFor(f.defaultServingSize),
                servingSize: f.defaultServingSize,
                servingUnit: f.servingDescription,
                fibre: f.fibreFor(f.defaultServingSize),
                sugar: f.sugarFor(f.defaultServingSize),
                sodiumMg: f.sodiumMgFor(f.defaultServingSize),
                vitaminDMcg: f.vitaminDMcgFor(f.defaultServingSize),
                ironMg: f.ironMgFor(f.defaultServingSize),
                calciumMg: f.calciumMgFor(f.defaultServingSize),
                vitaminCMg: f.vitaminCMgFor(f.defaultServingSize),
                magnesiumMg: f.magnesiumMgFor(f.defaultServingSize),
                potassiumMg: f.potassiumMgFor(f.defaultServingSize),
                zincMg: f.zincMgFor(f.defaultServingSize),
                vitaminB12Mcg: f.vitaminB12McgFor(f.defaultServingSize),
                folateMcg: f.folateMcgFor(f.defaultServingSize),
              ))
          .toList();
    }

    final success = await saveCustomMealPlan(
      ref,
      name: name,
      goal: _selectedGoal,
      meals: meals,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      helpers.showCupertinoToast(context, 'Meal plan saved!');
      Navigator.of(context).pop();
    } else {
      helpers.showCupertinoToast(context, 'Failed to save meal plan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: CupertinoNavigationBar(
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel',
              style: TextStyle(color: palette.accent)),
        ),
        middle: Text(
          'Create Meal Plan',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: palette.text,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saving ? null : _save,
          child: _saving
              ? const CupertinoActivityIndicator(radius: 10)
              : Text('Save',
                  style: TextStyle(
                    color: palette.accent,
                    fontWeight: FontWeight.w600,
                  )),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Plan name
                CupertinoTextField(
                  controller: _nameController,
                  placeholder: 'Plan name',
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  style: TextStyle(color: palette.text, fontSize: 15),
                  placeholderStyle: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),

                // Goal chips
                Text(
                  'Goal',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _goalOptions.map((goal) {
                    final selected = _selectedGoal == goal;
                    return ChoiceChip(
                      label: Text(goal),
                      selected: selected,
                      onSelected: (v) =>
                          setState(() => _selectedGoal = v ? goal : null),
                      selectedColor: palette.accent,
                      backgroundColor: palette.surface,
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: selected ? Colors.white : palette.text,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: selected
                              ? palette.accent
                              : palette.border,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Meal sections
                ...MealType.values.map((type) => _MealSection(
                      mealType: type,
                      foods: _mealFoods[type]!,
                      onAddFood: () => _addFood(type),
                      onRemoveFood: (i) =>
                          setState(() => _mealFoods[type]!.removeAt(i)),
                    )),
              ],
            ),
          ),

          // Running totals bar
          _TotalsBar(
            calories: _totalCalories,
            protein: _totalProtein,
            carbs: _totalCarbs,
            fat: _totalFat,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meal section
// ---------------------------------------------------------------------------

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.mealType,
    required this.foods,
    required this.onAddFood,
    required this.onRemoveFood,
  });

  final MealType mealType;
  final List<FoodSearchResult> foods;
  final VoidCallback onAddFood;
  final void Function(int index) onRemoveFood;

  double get _sectionCals =>
      foods.fold(0.0, (s, f) => s + f.caloriesPer100g * (f.defaultServingSize) / 100);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: helpers.CupertinoExpansionTile(
        initiallyExpanded: true,
        title: Text(mealType.label),
        subtitle: Text(
          '${_sectionCals.toInt()} kcal · ${foods.length} item${foods.length == 1 ? '' : 's'}',
        ),
        children: [
          ...List.generate(foods.length, (i) {
            final food = foods[i];
            final cals = food.caloriesPer100g * food.defaultServingSize / 100;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.of(context).text,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${cals.toInt()} kcal',
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onRemoveFood(i),
                    child: Icon(
                      CupertinoIcons.minus_circle_fill,
                      color: AppColors.of(context).destructive,
                      size: 20,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onAddFood,
            child: Builder(
              builder: (context) {
                final accentColor = AppColors.of(context).accent;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.add, size: 16, color: accentColor),
                      const SizedBox(width: 6),
                      Text(
                        'Add Food',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Totals bar
// ---------------------------------------------------------------------------

class _TotalsBar extends StatelessWidget {
  const _TotalsBar({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final palette = AppColors.of(context);
    return Container(
      padding:
          EdgeInsets.fromLTRB(16, 12, 16, padding.bottom > 0 ? padding.bottom : 12),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TotalItem(
            label: 'Calories',
            value: '${calories.toInt()}',
            color: NutrientIcons.caloriesColor,
          ),
          _TotalItem(
            label: 'Protein',
            value: '${protein.toInt()}g',
            color: NutrientIcons.proteinColor,
          ),
          _TotalItem(
            label: 'Carbs',
            value: '${carbs.toInt()}g',
            color: NutrientIcons.carbsColor,
          ),
          _TotalItem(
            label: 'Fat',
            value: '${fat.toInt()}g',
            color: NutrientIcons.fatColor,
          ),
        ],
      ),
    );
  }
}

class _TotalItem extends StatelessWidget {
  const _TotalItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: AppColors.of(context).textSecondary,
          ),
        ),
      ],
    );
  }
}
