import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/field_manual.dart';
import '../../../core/utils/logger.dart';
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
    final palette = AppColors.of(context);

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
                color: palette.accent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.add,
                      size: 18, color: palette.onAccent),
                  const SizedBox(width: 8),
                  Text(
                    'CREATE PLAN',
                    style: FieldManual.label(
                      color: palette.onAccent,
                      fontSize: 12,
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
          error: (e, st) {
            AppLogger.error('Custom meal plans load failed',
                error: e, stack: st);
            final palette = AppColors.of(context);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(CupertinoIcons.exclamationmark_circle,
                      size: 16, color: palette.destructive),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Could not load your plans.',
                      style: FieldManual.body(
                        fontSize: 13,
                        color: FieldManual.mutedBone,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: () =>
                        ref.invalidate(allCustomMealPlansProvider),
                    child: Text(
                      'RETRY',
                      style: FieldManual.label(
                        color: palette.accent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          data: (plans) {
            if (plans.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'MY PLANS',
                    style: FieldManual.headline(),
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
            'SUGGESTED PLANS',
            style: FieldManual.headline(),
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
        color: FieldManual.field,
        border: Border.all(color: FieldManual.hairline),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            plan.name,
            style: FieldManual.title(),
          ),
          if (plan.goal != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: palette.accent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                plan.goal!.toUpperCase(),
                style: FieldManual.label(
                  color: palette.onAccent,
                  fontSize: 10,
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
                label: '${plan.totalCalories.toInt()} KCAL',
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.fitness_center_outlined,
                label: '${plan.totalProtein.toInt()}G P',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.grain,
                label: '${plan.totalCarbs.toInt()}G C',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.opacity,
                label: '${plan.totalFat.toInt()}G F',
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
                    foregroundColor: palette.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    'IMPORT TODAY',
                    style: FieldManual.label(
                      color: palette.onAccent,
                      fontSize: 11,
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
                  tooltip: 'Delete meal plan',
                  color: palette.destructive,
                  style: IconButton.styleFrom(
                    backgroundColor: palette.destructive.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
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
          style: FieldManual.readout(fontSize: 11),
        ),
      ],
    );
  }
}
