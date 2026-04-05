import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../models/enums.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/nutrition_providers.dart';
import 'widgets/complete_day_button.dart';
import 'widgets/daily_summary_header.dart';
import 'widgets/meal_section.dart';
import 'widgets/micronutrient_section.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionAsync = ref.watch(todayNutritionProvider);
    final mealsAsync = ref.watch(todayMealsProvider);
    final targetsAsync = ref.watch(dailyTargetsProvider);
    final microsAsync = ref.watch(todayMicronutrientsProvider);
    final completedDayAsync = ref.watch(todayCompletedDayProvider);

    if (mealsAsync.isLoading && !mealsAsync.hasValue) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nutrition')),
        body: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              SizedBox(height: 8),
              ShimmerCard(height: 152),
              SizedBox(height: 8),
              ShimmerCard(height: 60),
              SizedBox(height: 8),
              ShimmerCard(height: 110),
              SizedBox(height: 8),
              ShimmerCard(height: 110),
              SizedBox(height: 8),
              ShimmerCard(height: 110),
              SizedBox(height: 8),
              ShimmerCard(height: 110),
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
            const SizedBox(height: 8),
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
            // Micronutrient section (collapsible)
            if (micros.values.any((v) => v > 0))
              MicronutrientSection(consumed: micros),
            if (micros.values.any((v) => v > 0))
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
            // Bottom padding so FAB doesn't obscure content
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: const CompleteDayButton(),
        ),
      ),
    );
  }
}
