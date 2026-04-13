import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    super.key,
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          builder: (context, opacity, _) {
            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            );
          },
        );
      },
      child: Builder(
        builder: (context) {
          final palette = AppColors.of(context);
          return Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 56,
              color: palette.accent,
            ),
          );
        },
      ),
    );
  }
}
