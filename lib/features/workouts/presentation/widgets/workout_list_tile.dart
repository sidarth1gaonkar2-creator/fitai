import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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
    final date = workout.date;
    final dateStr = '${date.day}/${date.month}/${date.year}';

    return Card.outlined(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.purpleDark,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.fitness_center,
            color: Colors.white,
            size: 22,
          ),
        ),
        title: Text(
          workout.title,
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            dateStr,
            if (workout.durationMinutes != null)
              '${workout.durationMinutes} min',
          ].join(' · '),
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.purpleLight,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.lime,
        ),
        onTap: onTap,
      ),
    );
  }
}
