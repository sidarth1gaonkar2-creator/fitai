import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class WaterTracker extends StatelessWidget {
  const WaterTracker({
    super.key,
    required this.glasses,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int glasses;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  static const _goal = 8;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          children: [
            const Icon(
              Icons.water_drop,
              size: 28,
              color: AppColors.lime,
            ),
            const SizedBox(height: 4),
            Text(
              '$glasses / $_goal',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'glasses',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            _GlassDotsRow(filled: glasses.clamp(0, _goal), total: _goal),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WaterIconButton(
                  icon: Icons.remove,
                  enabled: glasses > 0,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onDecrement();
                  },
                ),
                const SizedBox(width: 8),
                _WaterIconButton(
                  icon: Icons.add,
                  enabled: true,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onIncrement();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassDotsRow extends StatelessWidget {
  const _GlassDotsRow({required this.filled, required this.total});

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: List.generate(total, (index) {
        final isFilled = index < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.lime : Colors.transparent,
            border: isFilled
                ? null
                : Border.all(color: Colors.white, width: 1.5),
          ),
        );
      }),
    );
  }
}

class _WaterIconButton extends StatelessWidget {
  const _WaterIconButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.purple.withValues(alpha: 0.25),
        foregroundColor: AppColors.purple,
        disabledBackgroundColor: AppColors.purple.withValues(alpha: 0.1),
        disabledForegroundColor: AppColors.purple.withValues(alpha: 0.4),
        minimumSize: const Size(48, 48),
      ),
    );
  }
}
