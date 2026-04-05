import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../models/enums.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/nutrition_providers.dart';
import 'widgets/complete_day_button.dart';
import 'widgets/daily_summary_header.dart';
import 'widgets/meal_section.dart';
import 'widgets/micronutrient_section.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  int _selectedTab = 1; // 0 = Meal Plans, 1 = Food Log

  @override
  Widget build(BuildContext context) {
    final nutritionAsync = ref.watch(todayNutritionProvider);
    final mealsAsync = ref.watch(todayMealsProvider);
    final targetsAsync = ref.watch(dailyTargetsProvider);
    final microsAsync = ref.watch(todayMicronutrientsProvider);
    final completedDayAsync = ref.watch(todayCompletedDayProvider);

    if (mealsAsync.isLoading && !mealsAsync.hasValue) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nutrition')),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _TabToggle(
                selectedIndex: _selectedTab,
                onTabChanged: (i) => setState(() => _selectedTab = i),
              ),
              const SizedBox(height: 16),
              const ShimmerCard(height: 152),
              const SizedBox(height: 8),
              const ShimmerCard(height: 60),
              const SizedBox(height: 8),
              const ShimmerCard(height: 110),
              const SizedBox(height: 8),
              const ShimmerCard(height: 110),
              const SizedBox(height: 8),
              const ShimmerCard(height: 110),
              const SizedBox(height: 8),
              const ShimmerCard(height: 110),
            ],
          ),
        ),
      );
    }

    if (mealsAsync.hasError && !mealsAsync.hasValue) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nutrition')),
        body: ErrorCard(
          message: 'Could not load nutrition data.',
          onRetry: () => ref.invalidate(todayMealsProvider),
        ),
      );
    }

    final calories = nutritionAsync.valueOrNull?.totalCalories ?? 0;
    final protein = nutritionAsync.valueOrNull?.totalProtein ?? 0;
    final carbs = nutritionAsync.valueOrNull?.totalCarbs ?? 0;
    final fat = nutritionAsync.valueOrNull?.totalFat ?? 0;

    final targets = targetsAsync.valueOrNull;
    final micros = microsAsync.valueOrNull ?? {};
    final isLocked = completedDayAsync.valueOrNull != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            _TabToggle(
              selectedIndex: _selectedTab,
              onTabChanged: (i) => setState(() => _selectedTab = i),
            ),
            const SizedBox(height: 16),
            if (_selectedTab == 0) ...[
              const _MealPlansPlaceholder(),
              const SizedBox(height: 80),
            ] else ...[
              // Summary card with calorie ring + macro bars
              NutritionSummaryCard(
                calories: calories.toDouble(),
                protein: protein.toDouble(),
                carbs: carbs.toDouble(),
                fat: fat.toDouble(),
                calorieTarget: targets?.calories ?? 2000,
                proteinTarget: targets?.protein ?? 150,
                carbsTarget: targets?.carbs ?? 250,
                fatTarget: targets?.fat ?? 70,
              ),
              const SizedBox(height: 8),
              // Micronutrient section (always visible)
              MicronutrientSection(consumed: micros),
              const SizedBox(height: 8),
              // Meal sections
              ...MealType.values.map((type) {
                final entries = mealsAsync.valueOrNull?[type] ?? [];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MealSection(
                    mealType: type,
                    entries: entries,
                    onAddFood: () =>
                        context.go('/nutrition/search/${type.name}'),
                    onDeleteEntry: (id) => deleteFoodEntry(ref, id),
                    isLocked: isLocked,
                  ),
                );
              }),
              // Bottom padding so button doesn't obscure content
              const SizedBox(height: 80),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _selectedTab == 1
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: const CompleteDayButton(),
              ),
            )
          : null,
    );
  }
}

// ─── Tab Toggle ──────────────────────────────────────────────────────────────

class _TabToggle extends StatelessWidget {
  const _TabToggle({
    required this.selectedIndex,
    required this.onTabChanged,
  });

  final int selectedIndex;
  final void Function(int) onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.darkSurfaceBorder),
        borderRadius: BorderRadius.circular(50),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _TabPill(
            label: 'Meal Plans',
            isActive: selectedIndex == 0,
            onTap: () => onTabChanged(0),
          ),
          _TabPill(
            label: 'Food Log',
            isActive: selectedIndex == 1,
            onTap: () => onTabChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? AppColors.lime : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isActive ? Colors.black : AppColors.purple,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Meal Plans Placeholder ──────────────────────────────────────────────────

class _MealPlansPlaceholder extends StatelessWidget {
  const _MealPlansPlaceholder();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 320,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.purpleDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu_outlined,
              color: AppColors.lime,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Meal Plans',
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.lime,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
