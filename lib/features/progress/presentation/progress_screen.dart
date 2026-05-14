import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../providers/health_providers.dart';
import '../../../providers/progress_providers.dart';
import 'widgets/activity_trends.dart';
import 'widgets/milestone_badges.dart';
import 'widgets/nutrition_trends.dart';
import 'widgets/strength_chart.dart';
import 'widgets/weight_chart.dart';
import 'widgets/weight_entry_dialog.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _selectedTab = 0; // 0 = Workout Log, 1 = Charts

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: CupertinoNavigationBar(
        middle: const Text('Progress'),
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _ProgressTabToggle(
              selectedIndex: _selectedTab,
              onTabChanged: (i) => setState(() => _selectedTab = i),
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _WorkoutLogTab(key: const ValueKey('workout_log'))
                : _ChartsTab(key: const ValueKey('charts')),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Toggle ──────────────────────────────────────────────────────────────

class _ProgressTabToggle extends StatelessWidget {
  const _ProgressTabToggle({
    required this.selectedIndex,
    required this.onTabChanged,
  });

  final int selectedIndex;
  final void Function(int) onTabChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _TabPill(
            label: 'Workout Log',
            isActive: selectedIndex == 0,
            onTap: () => onTabChanged(0),
          ),
          _TabPill(
            label: 'Charts',
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
      child: Semantics(
        label: label,
        button: true,
        selected: isActive,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color:
                  isActive ? AppColors.of(context).accent : Colors.transparent,
              borderRadius: BorderRadius.circular(21),
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
                color: isActive ? Colors.black : AppColors.of(context).text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Workout Log Tab ─────────────────────────────────────────────────────────

class _WorkoutLogTab extends ConsumerWidget {
  const _WorkoutLogTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final milestonesAsync = ref.watch(milestonesProvider);
    final weightAsync = ref.watch(weightEntriesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // --- Milestones ---
          Text(
            'Milestones',
            style: textTheme.titleMedium?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).accent,
            ),
          ),
          const SizedBox(height: 12),
          milestonesAsync.when(
            data: (milestones) => MilestoneBadges(milestones: milestones),
            loading: () => const ShimmerBox(
                width: double.infinity, height: 80, borderRadius: 12),
            error: (_, _) =>
                const ErrorCard(message: 'Could not load milestones.'),
          ),
          const SizedBox(height: 24),

          // --- Body Weight ---
          Row(
            children: [
              Expanded(
                child: Text(
                  'Body Weight',
                  style: textTheme.titleMedium?.copyWith(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: AppColors.of(context).accent,
                  ),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                color: AppColors.of(context).accent,
                borderRadius: BorderRadius.circular(10),
                onPressed: () => showCupertinoDialog(
                  context: context,
                  builder: (_) => const WeightEntryDialog(),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.add, color: Colors.black, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Log Weight',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          weightAsync.when(
            data: (entries) {
              final healthEntries = Platform.isIOS
                  ? ref.watch(healthWeightHistoryProvider).valueOrNull ??
                      const <({DateTime date, double weightKg})>[]
                  : const <({DateTime date, double weightKg})>[];
              return WeightChart(
                entries: entries,
                healthEntries: healthEntries,
              );
            },
            loading: () => const ShimmerBox(
                width: double.infinity, height: 220, borderRadius: 12),
            error: (_, _) =>
                const ErrorCard(message: 'Could not load weight data.'),
          ),
          const SizedBox(height: 24),

          // --- Activity Trends (Apple Health, iOS only when connected) ---
          if (Platform.isIOS && ref.watch(healthConnectedProvider)) ...[
            Text(
              'Activity Trends',
              style: textTheme.titleMedium?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: AppColors.of(context).accent,
              ),
            ),
            const SizedBox(height: 12),
            const ActivityTrends(),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

// ─── Charts Tab ──────────────────────────────────────────────────────────────

class _ChartsTab extends StatelessWidget {
  const _ChartsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // --- Personal Records ---
          _PRHallCard(),
          const SizedBox(height: 28),

          // --- Strength Progress ---
          Text(
            'Strength Progress',
            style: textTheme.titleMedium?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).accent,
            ),
          ),
          const SizedBox(height: 12),
          const StrengthChart(),
          const SizedBox(height: 28),

          // --- Nutrition Trends ---
          Text(
            'Nutrition Trends',
            style: textTheme.titleMedium?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).accent,
            ),
          ),
          const SizedBox(height: 12),
          const NutritionTrends(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── PR Hall Navigation Card ────────────────────────────────────────────────

class _PRHallCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/progress/pr-hall');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: palette.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.emoji_events,
                color: palette.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Records',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: palette.text,
                    ),
                  ),
                  Text(
                    'View your all-time bests',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 13,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: palette.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
