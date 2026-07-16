import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Theme;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../models/workout.dart';

class WorkoutListTile extends StatelessWidget {
  const WorkoutListTile({
    super.key,
    required this.workout,
    required this.onTap,
  });

  final Workout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = AppColors.of(context);
    final date = workout.date;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[date.month - 1]} ${date.day}, ${date.year}';

    return CupertinoCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          // Squared field-raised emblem — quiet chrome, not an accent blob.
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: palette.border),
            ),
            child: Icon(
              Icons.fitness_center,
              color: palette.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.title,
                  style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  // Meta line in mono — date + duration are readouts.
                  [
                    dateStr.toUpperCase(),
                    if (workout.durationMinutes != null)
                      '${workout.durationMinutes} MIN',
                  ].join(' · '),
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontVariations: const [FontVariation('wght', 500)],
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chevron_right,
            color: palette.textSecondary,
            size: 18,
          ),
        ],
      ),
    );
  }
}
