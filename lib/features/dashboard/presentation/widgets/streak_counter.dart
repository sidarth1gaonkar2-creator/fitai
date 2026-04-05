import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StreakCounter extends StatelessWidget {
  const StreakCounter({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: '$streak day streak',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.purpleDark,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            const Icon(
              Icons.local_fire_department,
              size: 32,
              color: AppColors.lime,
            ),
            const SizedBox(height: 4),
            Text(
              streak.toString(),
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              'day streak',
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
