import 'package:flutter/cupertino.dart';
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
import 'widgets/quick_add_sheet.dart';
import 'widgets/recent_foods_sheet.dart';
import 'meal_plans_screen.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(nutritionTabProvider);
    final nutritionAsync = ref.watch(todayNutritionProvider);
    final mealsAsync = ref.watch(todayMealsProvider);
    final targetsAsync = ref.watch(dailyTargetsProvider);
    final microsAsync = ref.watch(todayMicronutrientsProvider);
    final completedDayAsync = ref.watch(todayCompletedDayProvider);

    if (mealsAsync.isLoading && !mealsAsync.hasValue) {
      return Scaffold(
        appBar: CupertinoNavigationBar(
        middle: const Text('Nutrition'),
        backgroundColor: AppColors.of(context).background.withValues(alpha: 0.8),
        border: null,
      ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _TabToggle(
                selectedIndex: selectedTab,
                onTabChanged: (i) => ref.read(nutritionTabProvider.notifier).state = i,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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
              ),
            ],
          ),
        ),
      );
    }

    if (mealsAsync.hasError && !mealsAsync.hasValue) {
      return Scaffold(
        appBar: CupertinoNavigationBar(
        middle: const Text('Nutrition'),
        backgroundColor: AppColors.of(context).background.withValues(alpha: 0.8),
        border: null,
      ),
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
      appBar: CupertinoNavigationBar(
        middle: const Text('Nutrition'),
        backgroundColor: AppColors.of(context).background.withValues(alpha: 0.8),
        border: null,
        trailing: CupertinoButton(
          padding: const EdgeInsets.all(8),
          onPressed: () => context.push('/nutrition/saved-meals'),
          child: Icon(
            Icons.bookmark_outline,
            size: 22,
            color: AppColors.of(context).accent,
            semanticLabel: 'Saved meals',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            _TabToggle(
              selectedIndex: selectedTab,
              onTabChanged: (i) => ref.read(nutritionTabProvider.notifier).state = i,
            ),
            const SizedBox(height: 16),
            if (selectedTab == 0) ...[
              const MealPlansContent(),
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
              const SizedBox(height: 12),
              // ── Quick search bar (taps into unified search) ──
              if (!isLocked) ...[
                _SearchTrigger(
                  onTap: () => context.go(
                      '/nutrition/search/${MealType.lunch.name}'),
                ),
                const SizedBox(height: 10),
                _QuickActionChips(isLocked: isLocked),
                const SizedBox(height: 12),
              ],
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
                    onRestoreEntry: (mealType, entry) => addFoodEntry(
                      ref,
                      mealType: mealType,
                      name: entry.name,
                      calories: entry.calories,
                      protein: entry.protein,
                      carbs: entry.carbs,
                      fat: entry.fat,
                      servingSize: entry.servingSize ?? 1,
                      servingUnit: entry.servingUnit ?? 'serving',
                      fibre: entry.fibre,
                      sugar: entry.sugar,
                      sodiumMg: entry.sodiumMg,
                      vitaminDMcg: entry.vitaminDMcg,
                      ironMg: entry.ironMg,
                      calciumMg: entry.calciumMg,
                      vitaminCMg: entry.vitaminCMg,
                      magnesiumMg: entry.magnesiumMg,
                      potassiumMg: entry.potassiumMg,
                      zincMg: entry.zincMg,
                      vitaminB12Mcg: entry.vitaminB12Mcg,
                      folateMcg: entry.folateMcg,
                    ),
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
      bottomNavigationBar: selectedTab == 1
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
    final palette = AppColors.of(context);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(22),
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
          decoration: BoxDecoration(
            color: isActive ? AppColors.of(context).accent : Colors.transparent,
            borderRadius: BorderRadius.circular(19),
            border: isActive
                ? null
                : Border.all(
                    color: AppColors.of(context).border,
                    width: 1,
                  ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isActive ? Colors.white : AppColors.of(context).text,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Search trigger + quick action chips ──────────────────────────

class _SearchTrigger extends StatelessWidget {
  const _SearchTrigger({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.search, size: 18, color: palette.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Search foods, restaurants, or scan barcode...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: palette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionChips extends ConsumerWidget {
  const _QuickActionChips({required this.isLocked});
  final bool isLocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _Chip(
            icon: CupertinoIcons.search,
            label: 'Search',
            onTap: () =>
                context.go('/nutrition/search/${MealType.lunch.name}'),
          ),
          _Chip(
            icon: CupertinoIcons.qrcode_viewfinder,
            label: 'Scan',
            onTap: () =>
                context.go('/nutrition/scan/${MealType.lunch.name}'),
          ),
          _Chip(
            emoji: '🍔',
            label: 'Restaurants',
            onTap: () => context.push('/nutrition/restaurants'),
          ),
          _Chip(
            icon: Icons.bookmark_outline,
            label: 'Saved',
            onTap: () => context.push('/nutrition/saved-meals'),
          ),
          _Chip(
            icon: CupertinoIcons.clock,
            label: 'Recent',
            onTap: () => showCupertinoModalPopup(
              context: context,
              builder: (_) => const RecentFoodsSheet(),
            ),
          ),
          _Chip(
            icon: CupertinoIcons.pencil,
            label: 'Quick Add',
            onTap: () => showCupertinoModalPopup(
              context: context,
              builder: (_) => const QuickAddSheet(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    this.icon,
    this.emoji,
    required this.label,
    required this.onTap,
  });

  final IconData? icon;
  final String? emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: palette.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null)
                Text(emoji!, style: const TextStyle(fontSize: 16))
              else if (icon != null)
                Icon(icon, size: 16, color: palette.text),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: palette.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
