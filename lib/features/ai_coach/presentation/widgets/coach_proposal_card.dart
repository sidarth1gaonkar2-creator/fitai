import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../models/ai_message.dart';
import '../../../../models/saved_workout_template.dart';
import '../../../../providers/ai_coach_providers.dart';
import '../../../../providers/nutrition_providers.dart';
import '../../../../providers/unit_system_provider.dart';

/// Renders the inline confirmation card for a tool proposal attached to an
/// assistant [message]. Dispatches on `proposalKind` + `proposalStatus`. The AI
/// never writes anything; only the Apply tap here does.
class CoachProposalCard extends ConsumerWidget {
  const CoachProposalCard({super.key, required this.message});

  final AIMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = message.proposalKind;
    final raw = message.proposalJson;
    if (kind == null || raw == null) return const SizedBox.shrink();

    Map<String, dynamic> input;
    try {
      input = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return const SizedBox.shrink();
    }

    if (message.proposalStatus == 'error') {
      return _CardShell(
        accent: AppColors.of(context).text,
        child: Text(
          "I drew that one up wrong — the numbers were out of range. Ask me "
          'again and I\'ll fix it.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return switch (kind) {
      'nutrition' => _NutritionCard(message: message, input: input),
      'workout' => _WorkoutCard(message: message, input: input),
      _ => const SizedBox.shrink(),
    };
  }
}

// ---------------------------------------------------------------------------
// Shared shell + action row
// ---------------------------------------------------------------------------

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, required this.accent});

  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}

/// Apply / Dismiss, or the resolved status row.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.status,
    required this.onApply,
    required this.onDismiss,
    this.appliedLabel = 'Applied',
    this.trailing,
  });

  final String status;
  final VoidCallback onApply;
  final VoidCallback onDismiss;
  final String appliedLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    if (status == 'applied') {
      return Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: palette.accent),
          const SizedBox(width: 6),
          Text('$appliedLabel ✓',
              style: textTheme.labelLarge?.copyWith(color: palette.accent)),
          const Spacer(),
          ?trailing,
        ],
      );
    }
    if (status == 'dismissed') {
      return Text('Dismissed',
          style: textTheme.labelMedium?.copyWith(color: palette.textSecondary));
    }
    // proposed
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onDismiss,
            child: const Text('Dismiss'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: onApply,
            child: const Text('Apply'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Nutrition goal card — current vs proposed
// ---------------------------------------------------------------------------

class _NutritionCard extends ConsumerWidget {
  const _NutritionCard({required this.message, required this.input});

  final AIMessage message;
  final Map<String, dynamic> input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final current = ref.watch(dailyTargetsProvider).valueOrNull;

    final propCals = (input['calories'] as num?)?.toDouble() ?? 0;
    final propP = (input['proteinG'] as num?)?.toDouble() ?? 0;
    final propC = (input['carbsG'] as num?)?.toDouble() ?? 0;
    final propF = (input['fatG'] as num?)?.toDouble() ?? 0;
    final rationale = input['rationale'] as String? ?? '';

    Widget row(String label, double? from, double to, String unit) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Text(label, style: textTheme.labelMedium),
            ),
            Text(
              from != null ? '${from.toInt()}' : '—',
              style: textTheme.bodyMedium
                  ?.copyWith(color: palette.textSecondary),
            ),
            Icon(Icons.arrow_right_alt,
                size: 18, color: palette.textSecondary),
            Text(
              '${to.toInt()} $unit',
              style: textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600, color: palette.text),
            ),
          ],
        ),
      );
    }

    return _CardShell(
      accent: palette.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu, size: 18, color: palette.accent),
              const SizedBox(width: 6),
              Text('New nutrition goals',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          row('Calories', current?.calories, propCals, 'kcal'),
          row('Protein', current?.protein, propP, 'g'),
          row('Carbs', current?.carbs, propC, 'g'),
          row('Fat', current?.fat, propF, 'g'),
          if (rationale.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(rationale,
                style: textTheme.bodySmall
                    ?.copyWith(color: palette.textSecondary)),
          ],
          const SizedBox(height: 12),
          _ActionRow(
            status: message.proposalStatus,
            appliedLabel: 'Goals updated',
            onApply: () => ref
                .read(aiChatControllerProvider.notifier)
                .applyNutritionProposal(message),
            onDismiss: () => ref
                .read(aiChatControllerProvider.notifier)
                .dismissProposal(message),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Workout preview card
// ---------------------------------------------------------------------------

class _WorkoutCard extends ConsumerWidget {
  const _WorkoutCard({required this.message, required this.input});

  final AIMessage message;
  final Map<String, dynamic> input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final units = ref.watch(unitSystemProvider);

    final name = input['name'] as String? ?? 'Workout';
    final focus = input['focus'] as String? ?? '';
    final rationale = input['rationale'] as String? ?? '';
    final exercises =
        (input['exercises'] as List?)?.whereType<Map>().toList() ?? const [];

    String weightLabel(Object? kg) {
      if (kg is! num) return 'bodyweight';
      return UnitConverter.formatWeight(kg.toDouble(), units);
    }

    return _CardShell(
      accent: palette.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, size: 18, color: palette.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(name,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (focus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(focus,
                  style: textTheme.labelMedium
                      ?.copyWith(color: palette.textSecondary)),
            ),
          const SizedBox(height: 8),
          ...exercises.map((e) {
            final exName = e['exerciseName'] as String? ?? 'Exercise';
            final sets = (e['sets'] as num?)?.toInt() ?? 0;
            final reps = (e['reps'] as num?)?.toInt() ?? 0;
            final w = e['suggestedWeightKg'];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(exName, style: textTheme.bodyMedium),
                  ),
                  Text(
                    '$sets×$reps · ${weightLabel(w)}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: palette.textSecondary),
                  ),
                ],
              ),
            );
          }),
          if (rationale.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(rationale,
                style: textTheme.bodySmall
                    ?.copyWith(color: palette.textSecondary)),
          ],
          const SizedBox(height: 12),
          _ActionRow(
            status: message.proposalStatus,
            appliedLabel: 'Saved to templates',
            onApply: () => ref
                .read(aiChatControllerProvider.notifier)
                .applyWorkoutProposal(message),
            onDismiss: () => ref
                .read(aiChatControllerProvider.notifier)
                .dismissProposal(message),
            trailing: TextButton(
              onPressed: () => _startNow(context),
              child: const Text('Start now'),
            ),
          ),
        ],
      ),
    );
  }

  void _startNow(BuildContext context) {
    final template = SavedWorkoutTemplate()
      ..uid = ''
      ..name = input['name'] as String? ?? 'Coach Workout'
      ..focus = input['focus'] as String? ?? ''
      ..exercisesJson = jsonEncode(input['exercises'] ?? const [])
      ..source = 'coach';
    context.push('/workouts/new', extra: template);
  }
}
