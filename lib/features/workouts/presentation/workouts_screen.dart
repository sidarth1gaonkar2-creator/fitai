import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../providers/workout_providers.dart';
import 'template_picker_sheet.dart';
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'Templates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _HistoryTab(),
          const _TemplatesTab(),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          if (_tabController.index != 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => context.go('/workouts/new'),
            icon: const Icon(Icons.add),
            label: const Text('Start Workout'),
          );
        },
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

    return Column(
      children: [
        // Calendar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: workoutDatesAsync.when(
            data: (dates) => WorkoutCalendar(
              workoutDates: dates,
              selectedDate: selectedDate,
              onDateSelected: (date) =>
                  ref.read(_selectedDateProvider.notifier).state = date,
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: ShimmerCard(height: 280),
            ),
            error: (_, _) => ErrorCard(
              message: 'Could not load calendar.',
              onRetry: () => ref.invalidate(workoutDatesProvider),
            ),
          ),
        ),
        // Workout list
        Expanded(
          child: filteredAsync.when(
            data: (workouts) {
              if (workouts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fitness_center_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedDate != null
                            ? 'No workouts on this day.'
                            : 'No workouts yet.\nTap + to start your first workout!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  return WorkoutListTile(
                    workout: workout,
                    onTap: () => context.go('/workouts/${workout.id}'),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ShimmerList(itemCount: 3),
            ),
            error: (_, _) => ErrorCard(
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
