import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CalorieRing extends StatefulWidget {
  const CalorieRing({
    super.key,
    required this.consumed,
    required this.target,
  });

  final double consumed;
  final double target;

  @override
  State<CalorieRing> createState() => _CalorieRingState();
}

class _CalorieRingState extends State<CalorieRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0;

  double get _rawProgress =>
      widget.target > 0 ? widget.consumed / widget.target : 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: _rawProgress.clamp(0.0, 1.5),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CalorieRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.consumed != widget.consumed ||
        oldWidget.target != widget.target) {
      _previousProgress = _progressAnimation.value;
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: _rawProgress.clamp(0.0, 1.5),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final palette = AppColors.of(context);
    final isOverBudget = _rawProgress >= 1.0;
    final isGoodProgress = _rawProgress >= 0.8;
    final remaining = widget.target - widget.consumed;

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Semantics(
          label: '${widget.consumed.toInt()} of ${widget.target.toInt()} '
              'calories consumed, '
              '${(_rawProgress * 100).toInt()}% of daily goal',
          child: SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _RingPainter(
                progress: _progressAnimation.value.clamp(0.0, 1.0),
                trackColor: palette.surface,
                isOverBudget: isOverBudget,
                isGoodProgress: isGoodProgress,
                brightness: Theme.of(context).brightness,
                accentColor: palette.accent,
                goodColor: palette.success,
                overColor: palette.destructive,
              ),
              child: child,
            ),
          ),
        );
      },
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.consumed.toInt().toString(),
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              '/ ${widget.target.toInt()} kcal',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isOverBudget
                  ? '+${(-remaining).toInt()} kcal over'
                  : '${remaining.toInt()} kcal left',
              style: textTheme.labelSmall?.copyWith(
                color: isOverBudget
                    ? AppColors.of(context).destructive
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.isOverBudget,
    required this.isGoodProgress,
    required this.brightness,
    required this.accentColor,
    required this.goodColor,
    required this.overColor,
  });

  final double progress;
  final Color trackColor;
  final bool isOverBudget;
  final bool isGoodProgress;
  final Brightness brightness;
  final Color accentColor;
  final Color goodColor;
  final Color overColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final sweepAngle = 2 * pi * progress.clamp(0.0, 0.999);

      // Gradient colors based on state
      final List<Color> gradientColors;
      if (isOverBudget) {
        gradientColors = [
          overColor,
          overColor.withValues(alpha: 0.6),
        ];
      } else if (isGoodProgress) {
        gradientColors = [
          goodColor,
          goodColor.withValues(alpha: 0.7),
        ];
      } else {
        gradientColors = [
          accentColor,
          accentColor.withValues(alpha: 0.6),
        ];
      }

      final gradient = SweepGradient(
        startAngle: 0,
        endAngle: sweepAngle,
        colors: gradientColors,
        transform: const GradientRotation(-pi / 2),
      );

      // Glow layer
      final glowOpacity = brightness == Brightness.dark ? 0.2 : 0.12;
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..color = gradientColors.first.withValues(alpha: glowOpacity);
      canvas.drawArc(rect, -pi / 2, sweepAngle, false, glowPaint);

      // Main arc with gradient
      final fillPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(rect);
      canvas.drawArc(rect, -pi / 2, sweepAngle, false, fillPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      trackColor != oldDelegate.trackColor ||
      isOverBudget != oldDelegate.isOverBudget ||
      isGoodProgress != oldDelegate.isGoodProgress ||
      brightness != oldDelegate.brightness ||
      accentColor != oldDelegate.accentColor ||
      goodColor != oldDelegate.goodColor ||
      overColor != oldDelegate.overColor;
}
