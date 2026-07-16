import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../providers/workout_providers.dart';
import '../../tutorial/presentation/tutorial_anchor.dart';
import 'template_picker_sheet.dart';
import 'widgets/training_days_card.dart';
import 'widgets/workout_calendar.dart';
import 'widgets/workout_list_tile.dart';

/// Tracks which date is selected in the calendar. Null = show all.
final _selectedDateProvider = StateProvider<DateTime?>((ref) => null);

class WorkoutsScreen extends ConsumerStatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  ConsumerState<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends ConsumerState<WorkoutsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: CupertinoNavigationBar(
        middle: const Text('Workouts'),
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
        trailing: CupertinoButton(
          padding: const EdgeInsets.all(8),
          onPressed: () => context.push('/settings'),
          child: const Icon(CupertinoIcons.gear,
              size: 22, semanticLabel: 'Settings'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _PillTabBar(controller: _tabController),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _HistoryTab(),
                const _TemplatesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: palette.accent,
              borderRadius: BorderRadius.circular(28),
              onPressed: () => context.go('/workouts/new'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.add, color: Colors.black, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Start Workout',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Pill tab bar
// ---------------------------------------------------------------------------

class _PillTabBar extends StatefulWidget {
  const _PillTabBar({required this.controller});

  final TabController controller;

  @override
  State<_PillTabBar> createState() => _PillTabBarState();
}

class _PillTabBarState extends State<_PillTabBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ['History', 'Templates'];

    final palette = AppColors.of(context);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isActive = widget.controller.index == index;
          // The "Templates" tab (index 1) hosts the workout_templates tutorial
          // spotlight. Wrap the GestureDetector — not the outer Expanded —
          // so Expanded keeps its Row as a direct parent.
          final inner = Semantics(
            label: tabs[index],
            button: true,
            selected: isActive,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.controller.animateTo(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isActive ? palette.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(21),
                  border: isActive
                      ? null
                      : Border.all(
                          color: palette.border,
                          width: 1,
                        ),
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isActive ? Colors.white : palette.text,
                    ),
                  ),
                ),
              ),
            ),
          );
          return Expanded(
            child: index == 1
                ? TutorialAnchor(id: 'workout_templates', child: inner)
                : inner,
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// History tab
// ---------------------------------------------------------------------------

class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutDatesAsync = ref.watch(workoutDatesProvider);
    final selectedDate = ref.watch(_selectedDateProvider);
    final allWorkoutsAsync = ref.watch(allWorkoutsProvider);
    final filteredAsync = selectedDate != null
        ? ref.watch(workoutsByDateProvider(selectedDate))
        : allWorkoutsAsync;

    return CustomScrollView(
      slivers: [
        // Training days — set/adjust your gym schedule where it lives mentally
        // (drives the gym streak + multiplier). Same picker as Notifications.
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TrainingDaysCard(),
          ),
        ),
        // Calendar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: workoutDatesAsync.when(
              data: (dates) => WorkoutCalendar(
                workoutDates: dates,
                selectedDate: selectedDate,
                onDateSelected: (date) =>
                    ref.read(_selectedDateProvider.notifier).state = date,
              ),
              loading: () => const ShimmerCard(height: 280),
              error: (_, _) => ErrorCard(
                message: 'Could not load calendar.',
                onRetry: () => ref.invalidate(workoutDatesProvider),
              ),
            ),
          ),
        ),
        // Section label
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              selectedDate != null ? 'Workouts on this day' : 'All Workouts',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.of(context).text,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        // Workout list
        filteredAsync.when(
          data: (workouts) {
            if (workouts.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fitness_center_outlined,
                        size: 48,
                        color: AppColors.of(context).textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedDate != null
                            ? 'No workouts on this day.'
                            : "No workouts logged? That's unacceptable, soldier.\nTap + and get moving!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 14,
                          color: AppColors.of(context).textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList.builder(
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  return WorkoutListTile(
                    workout: workout,
                    onTap: () => context.go('/workouts/${workout.id}'),
                  );
                },
              ),
            );
          },
          loading: () => const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: ShimmerList(itemCount: 3)),
          ),
          error: (_, _) => SliverToBoxAdapter(
            child: ErrorCard(
              message: 'Could not load workouts.',
              onRetry: () {
                if (selectedDate != null) {
                  ref.invalidate(workoutsByDateProvider(selectedDate));
                } else {
                  ref.invalidate(allWorkoutsProvider);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Templates tab — inline (not a sheet)
// ---------------------------------------------------------------------------

class _TemplatesTab extends StatelessWidget {
  const _TemplatesTab();

  @override
  Widget build(BuildContext context) {
    return const TemplatePickerContent(isEmbedded: true);
  }
}
