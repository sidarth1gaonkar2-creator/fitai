import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/workout_templates.dart';
import '../../../models/enums.dart';
import '../../../models/saved_workout_template.dart';
import '../../ai_coach/data/coach_actions.dart';
import 'template_preview_screen.dart';

/// Embeddable (or modal) template browser with category filter chips.
/// When [isEmbedded] is true the drag handle and close button are hidden
/// (designed for use inside a tab rather than a bottom sheet).
class TemplatePickerContent extends ConsumerStatefulWidget {
  const TemplatePickerContent({
    super.key,
    this.isEmbedded = false,
  });

  final bool isEmbedded;

  @override
  ConsumerState<TemplatePickerContent> createState() =>
      _TemplatePickerContentState();
}

class _TemplatePickerContentState extends ConsumerState<TemplatePickerContent> {
  WorkoutTemplateCategory? _selectedCategory;

  List<WorkoutTemplate> get _filtered => _selectedCategory == null
      ? workoutTemplates
      : workoutTemplates
          .where((t) => t.category == _selectedCategory)
          .toList();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final coachTemplates =
        ref.watch(savedWorkoutTemplatesProvider).valueOrNull ??
            const <SavedWorkoutTemplate>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.isEmbedded) ...[
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Workout Templates',
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
        ],

        // Category filter chips
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedCategory == null,
                onSelected: (_) =>
                    setState(() => _selectedCategory = null),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
              ...WorkoutTemplateCategory.values.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat.label),
                    selected: _selectedCategory == cat,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Template list — Coach templates on top (newest first), built-ins
        // below. The Coach section is hidden when the user has none.
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              if (coachTemplates.isNotEmpty) ...[
                const _SectionLabel(label: 'From your Coach'),
                ...coachTemplates.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CoachTemplateCard(
                      template: t,
                      onStart: () {
                        HapticFeedback.lightImpact();
                        context.push('/workouts/new', extra: t);
                      },
                      onDelete: () => deleteCoachWorkoutTemplate(ref, t.id),
                    ),
                  ),
                ),
                const _SectionLabel(label: 'Templates'),
              ],
              ..._filtered.map(
                (template) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TemplateCard(
                    template: template,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TemplatePreviewScreen(template: template),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shows [TemplatePickerContent] as a full-height modal bottom sheet.
Future<void> showTemplatePickerSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const SizedBox(
      height: double.infinity,
      child: TemplatePickerContent(isEmbedded: false),
    ),
  );
}

// ---------------------------------------------------------------------------
// Template card
// ---------------------------------------------------------------------------

class TemplateCard extends StatelessWidget {
  const TemplateCard({
    super.key,
    required this.template,
    required this.onTap,
  });

  final WorkoutTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (diffLabel, diffColor) = switch (template.difficulty) {
      ExerciseDifficulty.beginner => ('Beginner', colorScheme.primary),
      ExerciseDifficulty.intermediate => ('Intermediate', colorScheme.tertiary),
      ExerciseDifficulty.advanced => ('Advanced', colorScheme.error),
    };

    return Card.filled(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: diffColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      diffLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: diffColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                template.description,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.fitness_center,
                    label: '${template.exercises.length} exercises',
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.timer_outlined,
                    label: '~${template.estimatedMinutes} min',
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.category_outlined,
                    label: template.category.label,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Coach templates ("From your Coach")
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _CoachTemplateCard extends StatelessWidget {
  const _CoachTemplateCard({
    required this.template,
    required this.onStart,
    required this.onDelete,
  });

  final SavedWorkoutTemplate template;
  final VoidCallback onStart;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    int exerciseCount;
    try {
      exerciseCount = (jsonDecode(template.exercisesJson) as List).length;
    } catch (_) {
      exerciseCount = 0;
    }

    return Card.filled(
      child: InkWell(
        onTap: onStart,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Coach',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.delete_outline,
                        size: 20, color: colorScheme.onSurfaceVariant),
                    onPressed: onDelete,
                  ),
                ],
              ),
              if (template.focus.isNotEmpty)
                Text(
                  template.focus,
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.fitness_center,
                      size: 13, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 3),
                  Text(
                    '$exerciseCount exercises · tap to start',
                    style: textTheme.labelSmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
