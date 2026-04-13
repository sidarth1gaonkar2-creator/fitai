import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../data/curated_meal_plans.dart';
import '../../../models/custom_meal_plan.dart';
import '../../../providers/custom_meal_plan_providers.dart';
import '../../../providers/nutrition_providers.dart';
import 'create_meal_plan_screen.dart';
import 'widgets/meal_plan_card.dart';

class MealPlansContent extends ConsumerWidget {
  const MealPlansContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customPlansAsync = ref.watch(allCustomMealPlansProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Create Plan button
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProviderScope(
                  parent: ProviderScope.containerOf(context),
                  child: const CreateMealPlanScreen(),
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.of(context).accent, AppColors.of(context).accent.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.add, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Create Plan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // My Plans section
        customPlansAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CupertinoActivityIndicator(),
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (plans) {
            if (plans.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'My Plans',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.of(context).text,
                    ),
                  ),
                ),
                ...plans.map((plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CustomPlanCard(plan: plan),
                    )),
                const SizedBox(height: 8),
              ],
            );
          },
        ),

        // Suggested Plans section
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Suggested Plans',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.of(context).text,
            ),
          ),
        ),
        ...curatedMealPlans.map((plan) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MealPlanCard(
                plan: plan,
                onPreview: () => context.go('/nutrition/meal-plan/${plan.id}'),
                onImport: () => _importCurated(context, ref, plan),
              ),
            )),
      ],
    );
  }

  Future<void> _importCurated(
    BuildContext context,
    WidgetRef ref,
    CuratedMealPlan plan,
  ) async {
    final success = await importMealPlan(ref, plan: plan);
    if (!context.mounted) return;

    showCupertinoToast(
      context,
      success
          ? 'Meal plan imported! ${plan.totalCalories} calories added'
          : 'Failed to import meal plan',
    );

    if (success) {
      ref.read(nutritionTabProvider.notifier).state = 1;
    }
  }
}

// ---------------------------------------------------------------------------
// Custom plan card
// ---------------------------------------------------------------------------

class _CustomPlanCard extends ConsumerWidget {
  const _CustomPlanCard({required this.plan});

  final CustomMealPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            plan.name,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: palette.text,
            ),
          ),
          if (plan.goal != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: palette.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                plan.goal!,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Stats
          Row(
            children: [
              _StatChip(
                icon: Icons.local_fire_department_outlined,
                label: '${plan.totalCalories.toInt()} kcal',
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.fitness_center_outlined,
                label: '${plan.totalProtein.toInt()}g P',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.grain,
                label: '${plan.totalCarbs.toInt()}g C',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.opacity,
                label: '${plan.totalFat.toInt()}g F',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _import(context, ref),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.text,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Import Today',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 44,
                child: IconButton(
                  onPressed: () => _delete(context, ref),
                  icon: const Icon(CupertinoIcons.trash, size: 18),
                  color: palette.destructive,
                  style: IconButton.styleFrom(
                    backgroundColor: palette.destructive.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final success = await importCustomMealPlan(ref, plan.id);
    if (!context.mounted) return;

    showCupertinoToast(
      context,
      success
          ? 'Meal plan imported! ${plan.totalCalories.toInt()} calories added'
          : 'Failed to import meal plan',
    );

    if (success) {
      ref.read(nutritionTabProvider.notifier).state = 1;
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Delete "${plan.name}"? This cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: false,
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await deleteCustomMealPlan(ref, plan.id);
    if (!context.mounted) return;

    showCupertinoToast(
      context,
      success ? 'Plan deleted' : 'Failed to delete plan',
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.of(context).accent),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: AppColors.of(context).accent,
          ),
        ),
      ],
    );
  }
}
