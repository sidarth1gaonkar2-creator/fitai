import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/exercisedb_providers.dart';

/// Square ExerciseDB thumbnail with a colored-gradient placeholder. Reused
/// from workout logging cards, workout history details, and anywhere else
/// we want to show "what does this lift look like" at a glance.
///
/// The placeholder is rendered both during the API in-flight period and as
/// the permanent error/miss state — that way users with poor connectivity
/// or local-only exercise names never see a broken-image icon.
///
/// Tapping the thumbnail routes to `/exercise?name=...` for the full
/// exercise detail screen.
class ExerciseThumb extends ConsumerWidget {
  const ExerciseThumb({
    super.key,
    required this.exerciseName,
    this.size = 40,
    this.onTap,
  });

  final String exerciseName;
  final double size;

  /// Optional override — defaults to routing to the exercise detail screen.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEx = ref.watch(exerciseDBProvider(exerciseName));
    final url = asyncEx.valueOrNull?.fullImageUrl;
    final bodyParts = asyncEx.valueOrNull?.bodyParts ?? const <String>[];

    final placeholder = _ExercisePlaceholder(
      exerciseName: exerciseName,
      bodyPart: bodyParts.isEmpty ? null : bodyParts.first,
      size: size,
    );

    Widget child = SizedBox(
      width: size,
      height: size,
      child: url == null
          ? placeholder
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, _) => placeholder,
              errorWidget: (_, _, _) => placeholder,
            ),
    );
    child = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.2),
      child: child,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ??
          () => context.push(
                '/exercise?name=${Uri.encodeComponent(exerciseName)}',
              ),
      child: child,
    );
  }
}

/// Reusable placeholder shown while the ExerciseDB image is in flight, or
/// permanently when no image is available. Gradient colour is derived from
/// the exercise name hash so different exercises get different tints — a
/// row of placeholders still reads as a row of distinct items.
class _ExercisePlaceholder extends StatelessWidget {
  const _ExercisePlaceholder({
    required this.exerciseName,
    required this.bodyPart,
    required this.size,
  });

  final String exerciseName;
  final String? bodyPart;
  final double size;

  /// Body-part → icon mapping. Falls back to a dumbbell.
  IconData get _icon {
    final part = (bodyPart ?? exerciseName).toLowerCase();
    if (part.contains('chest')) return Icons.fitness_center;
    if (part.contains('back') || part.contains('lat')) return Icons.airline_seat_flat_angled;
    if (part.contains('arm') || part.contains('bicep') || part.contains('tricep')) {
      return Icons.front_hand;
    }
    if (part.contains('leg') ||
        part.contains('quad') ||
        part.contains('hamstring') ||
        part.contains('glute') ||
        part.contains('calf') ||
        part.contains('squat')) {
      return Icons.directions_run;
    }
    if (part.contains('shoulder') || part.contains('delt')) return Icons.accessibility_new;
    if (part.contains('core') || part.contains('abs') || part.contains('oblique')) {
      return Icons.self_improvement;
    }
    if (part.contains('cardio') ||
        part.contains('run') ||
        part.contains('cycle') ||
        part.contains('row') ||
        part.contains('swim')) {
      return Icons.directions_run;
    }
    return Icons.fitness_center;
  }

  /// Pair of accent colours for the gradient. Hue derived from the exercise
  /// name hash so the colour stays stable across re-renders.
  List<Color> _gradient(BuildContext context) {
    final palette = AppColors.of(context);
    final hash = exerciseName.hashCode.abs();
    // Five hand-picked palettes that feel modern + work in both light and
    // dark mode. Selected by hash for determinism.
    const palettes = <(int, int)>[
      (0xFF0A84FF, 0xFF5E5CE6),
      (0xFF30D158, 0xFF0A84FF),
      (0xFFFF9F0A, 0xFFFF453A),
      (0xFFBF5AF2, 0xFF0A84FF),
      (0xFF64D2FF, 0xFF0A84FF),
    ];
    final pick = palettes[hash % palettes.length];
    return [Color(pick.$1), Color(pick.$2), palette.accent];
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final colours = _gradient(context);
    final showLabel = size >= 56 && bodyPart != null;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colours[0].withValues(alpha: 0.85),
            colours[1].withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _icon,
            size: size * 0.45,
            color: palette.text == const Color(0xFFFFFFFF)
                ? Colors.white
                : Colors.white,
          ),
          if (showLabel) ...[
            const SizedBox(height: 2),
            Text(
              bodyPart!.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: size * 0.10,
                color: Colors.white.withValues(alpha: 0.95),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
