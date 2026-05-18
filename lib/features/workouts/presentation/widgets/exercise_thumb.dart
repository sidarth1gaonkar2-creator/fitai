import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/exercisedb_providers.dart';

/// Square ExerciseDB thumbnail with a colored-icon placeholder. Reused from
/// workout logging cards, workout history details, and anywhere else we
/// want to show "what does this lift look like" at a glance.
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
    final palette = AppColors.of(context);
    final asyncEx = ref.watch(exerciseDBProvider(exerciseName));
    final url = asyncEx.valueOrNull?.fullImageUrl;

    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.fitness_center,
        size: size * 0.5,
        color: palette.accent,
      ),
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
