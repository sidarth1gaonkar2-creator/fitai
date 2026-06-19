import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/ranks/domain/exercise_standards.dart';
import '../../../models/enums.dart';
import '../../../providers/custom_exercise_provider.dart';
import '../../../providers/workout_providers.dart';
import 'widgets/exercise_picker_card.dart';

/// Muscle group filter groups used in the filter bar.
/// Each entry maps a display label to a list of [MuscleGroup] values.
const _filterGroups = <(String, IconData, List<MuscleGroup>?)>[
  ('All', Icons.apps_outlined, null),
  ('Chest', Icons.fitness_center, [MuscleGroup.chest]),
  (
    'Back',
    Icons.expand,
    [MuscleGroup.upperBack, MuscleGroup.lats]
  ),
  (
    'Shoulders',
    Icons.sports_gymnastics,
    [MuscleGroup.shoulders]
  ),
  (
    'Legs',
    Icons.directions_run,
    [
      MuscleGroup.quads,
      MuscleGroup.hamstrings,
      MuscleGroup.glutes,
      MuscleGroup.calves,
    ]
  ),
  (
    'Arms',
    Icons.sports_handball,
    [MuscleGroup.biceps, MuscleGroup.triceps, MuscleGroup.forearms]
  ),
  ('Core', Icons.grid_view, [MuscleGroup.abs, MuscleGroup.obliques]),
  ('Cardio', Icons.favorite_outline, [MuscleGroup.cardio]),
];

/// Shows a draggable bottom sheet for picking an exercise from the library.
/// Returns the selected exercise name via [Navigator.pop].
class ExercisePickerSheet extends ConsumerStatefulWidget {
  const ExercisePickerSheet({super.key});

  @override
  ConsumerState<ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  final _searchController = TextEditingController();
  int _selectedGroupIndex = 0;

  @override
  void initState() {
    super.initState();
    // Reset filter when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exerciseFilterProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(exerciseFilterProvider.notifier).setQuery(value);
  }

  /// Asks which of the six rank groups a new custom exercise belongs to, so it
  /// can count toward the user's ranks. Returns null if dismissed.
  Future<RankGroup?> _promptForRankGroup(String name) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return showModalBottomSheet<RankGroup>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Text(
                'Which muscle group is "$name"?',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'So it counts toward your ranks.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            const Divider(height: 1),
            for (final group in RankGroup.values)
              ListTile(
                title: Text(group.label),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(sheetContext, group);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _onGroupSelected(int index) {
    setState(() => _selectedGroupIndex = index);
    final group = _filterGroups[index];
    final muscles = group.$3;
    // For multi-muscle groups we pass the first representative muscle;
    // filteredExercisesProvider supports single MuscleGroup filter so we
    // pick the first from the group (matches any of them via filterExercises).
    if (muscles == null || muscles.isEmpty) {
      ref.read(exerciseFilterProvider.notifier).setMuscleGroup(null);
    } else {
      // Set each muscle group — provider takes one at a time so we rely
      // on the filterExercises function which checks both primary and secondary.
      // We set the first muscle and the filter function matches any in the list
      // since we filter per-muscle. For multi-muscle groups the provider only
      // supports one at a time; show all muscles by toggling to null and
      // relying on query filtering by name, OR we enhance the filter.
      // The existing filterExercises checks containment so passing one of
      // the group muscles will already surface most exercises. For "Legs"
      // we pass null and handle in the local filter below.
      if (muscles.length == 1) {
        ref.read(exerciseFilterProvider.notifier).setMuscleGroup(muscles.first);
      } else {
        // Multi-muscle group — pass null to provider and filter locally via tag
        ref.read(exerciseFilterProvider.notifier).setMuscleGroup(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Watch the provider-filtered list (by query + single muscle)
    final providerFiltered = ref.watch(filteredExercisesProvider);
    final query = ref.watch(exerciseFilterProvider).query;
    final selectedGroup = _filterGroups[_selectedGroupIndex];
    final groupMuscles = selectedGroup.$3;

    // For multi-muscle groups, further filter locally
    final exercises = (groupMuscles != null && groupMuscles.length > 1)
        ? providerFiltered
            .where((e) =>
                e.primaryMuscles.any(groupMuscles.contains) ||
                e.secondaryMuscles.any(groupMuscles.contains))
            .toList()
        : providerFiltered;

    final showCustom = query.isNotEmpty &&
        !exercises
            .any((e) => e.name.toLowerCase() == query.toLowerCase().trim());

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add Exercise',
                      style: textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SearchBar(
                controller: _searchController,
                hintText: 'Search exercises...',
                leading: const Icon(Icons.search),
                onChanged: _onSearchChanged,
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  colorScheme.surfaceContainerHighest,
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),

            // Muscle group filter chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filterGroups.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final group = _filterGroups[i];
                  final isSelected = _selectedGroupIndex == i;
                  return FilterChip(
                    avatar: Icon(group.$2, size: 16),
                    label: Text(group.$1),
                    selected: isSelected,
                    onSelected: (_) => _onGroupSelected(i),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            const Divider(height: 1),

            // Exercise list
            Expanded(
              child: exercises.isEmpty && !showCustom
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 40,
                              color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text(
                            'No exercises found.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: exercises.length + (showCustom ? 1 : 0),
                      itemBuilder: (context, index) {
                        // "Add custom" tile at top
                        if (showCustom && index == 0) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 2),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.add_circle_outline,
                                color: colorScheme.onTertiaryContainer,
                              ),
                            ),
                            title: Text(
                              'Add "${_searchController.text.trim()}"',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'Custom exercise',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              final name = _searchController.text.trim();
                              if (name.isEmpty) return;
                              // Capture the navigator before any async gap so
                              // we never touch BuildContext after an await.
                              final navigator = Navigator.of(context);
                              final registry =
                                  ref.read(customExerciseRegistryProvider);
                              // Re-categorising an existing custom isn't needed
                              // — reuse its stored group. A brand-new custom
                              // must pick a group so it can be ranked; bail if
                              // the user dismisses the picker (don't create an
                              // uncategorised exercise).
                              if (!registry.isKnown(name)) {
                                final group = await _promptForRankGroup(name);
                                if (group == null) return;
                                await registry.setGroup(name, group);
                              }
                              navigator.pop(name);
                            },
                          );
                        }

                        final exerciseIndex =
                            showCustom ? index - 1 : index;
                        final exercise = exercises[exerciseIndex];
                        return ExercisePickerCard(
                          exercise: exercise,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context, exercise.name);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Helper to show the [ExercisePickerSheet] and return the selected name.
Future<String?> showExercisePickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const ExercisePickerSheet(),
  );
}
