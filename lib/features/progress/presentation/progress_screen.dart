import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../providers/progress_providers.dart';
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
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _selectedTab == 0
          ? _WorkoutLogTab(key: const ValueKey('workout_log'))
          : _ChartsTab(key: const ValueKey('charts')),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 56),
      child: Container(
        color: AppColors.purple,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: title + profile avatar
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Progress',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Profile avatar placeholder
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.purpleDark,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.lime.withValues(alpha: 0.6),
                            width: 1.5),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: AppColors.lime,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              // Tab toggle inside the AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ProgressTabToggle(
                  selectedIndex: _selectedTab,
                  onTabChanged: (i) => setState(() => _selectedTab = i),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
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
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(50),
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
              fontSize: 13,
              color: isActive ? Colors.black : Colors.white,
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
              color: AppColors.lime,
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
                    color: AppColors.lime,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const WeightEntryDialog(),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log Weight'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lime,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          weightAsync.when(
            data: (entries) => WeightChart(entries: entries),
            loading: () => const ShimmerBox(
                width: double.infinity, height: 220, borderRadius: 12),
            error: (_, _) =>
                const ErrorCard(message: 'Could not load weight data.'),
          ),
          const SizedBox(height: 24),
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

          // --- Strength Progress ---
          Text(
            'Strength Progress',
            style: textTheme.titleMedium?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: AppColors.lime,
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
              color: AppColors.lime,
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
