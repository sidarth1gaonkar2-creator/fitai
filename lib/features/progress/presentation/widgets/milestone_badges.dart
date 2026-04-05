import 'package:flutter/material.dart';
import '../../domain/milestone.dart';

class MilestoneBadges extends StatelessWidget {
  const MilestoneBadges({super.key, required this.milestones});

  final List<Milestone> milestones;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: milestones.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final m = milestones[index];
          final bgColor = m.isEarned
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest;
          final fgColor = m.isEarned
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

          return Container(
            width: 90,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(m.icon, color: fgColor, size: 24),
                const SizedBox(height: 4),
                Text(
                  m.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: fgColor,
                    fontWeight:
                        m.isEarned ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
