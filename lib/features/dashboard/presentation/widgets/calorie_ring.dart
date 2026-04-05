import 'dart:math';
import 'package:flutter/material.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isOverBudget = _rawProgress >= 1.0;
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
                trackColor: colorScheme.surfaceContainerHighest,
                primaryColor: colorScheme.primary,
                accentColor: colorScheme.tertiary,
                errorColor: colorScheme.error,
                errorContainerColor: colorScheme.errorContainer,
                isOverBudget: isOverBudget,
                brightness: Theme.of(context).brightness,
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
                    ? colorScheme.error
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
    required this.primaryColor,
    required this.accentColor,
    required this.errorColor,
    required this.errorContainerColor,
    required this.isOverBudget,
    required this.brightness,
  });

  final double progress;
  final Color trackColor;
  final Color primaryColor;
  final Color accentColor;
  final Color errorColor;
  final Color errorContainerColor;
  final bool isOverBudget;
  final Brightness brightness;

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

      // Gradient colors
      final List<Color> gradientColors;
      if (isOverBudget) {
        gradientColors = [errorColor, errorContainerColor];
      } else {
        gradientColors = [primaryColor, accentColor];
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
      primaryColor != oldDelegate.primaryColor ||
      accentColor != oldDelegate.accentColor ||
      isOverBudget != oldDelegate.isOverBudget ||
      brightness != oldDelegate.brightness;
}
