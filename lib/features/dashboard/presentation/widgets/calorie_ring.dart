import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// Dual-arc calorie ring:
/// * Inner solid arc — calories consumed vs goal.
/// * Outer dashed arc — calories burned (from Apple Health). Hidden when
///   [burned] is 0.
///
/// The center text shows the NET remaining calories (`goal - consumed + burned`)
/// by default. Tap the ring to toggle to a breakdown view (Eaten / Burned).
class CalorieRing extends StatefulWidget {
  const CalorieRing({
    super.key,
    required this.consumed,
    required this.target,
    this.burned = 0,
  });

  final double consumed;
  final double target;
  final double burned;

  @override
  State<CalorieRing> createState() => _CalorieRingState();
}

class _CalorieRingState extends State<CalorieRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _consumedAnim;
  late Animation<double> _burnedAnim;
  double _previousConsumed = 0;
  double _previousBurned = 0;
  bool _showBreakdown = false;

  double get _rawConsumed =>
      widget.target > 0 ? widget.consumed / widget.target : 0.0;
  double get _rawBurned =>
      widget.target > 0 ? widget.burned / widget.target : 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _consumedAnim = Tween<double>(
      begin: 0,
      end: _rawConsumed.clamp(0.0, 1.5),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _burnedAnim = Tween<double>(
      begin: 0,
      end: _rawBurned.clamp(0.0, 1.5),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CalorieRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.consumed != widget.consumed ||
        oldWidget.target != widget.target ||
        oldWidget.burned != widget.burned) {
      _previousConsumed = _consumedAnim.value;
      _previousBurned = _burnedAnim.value;
      _consumedAnim = Tween<double>(
        begin: _previousConsumed,
        end: _rawConsumed.clamp(0.0, 1.5),
      ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _burnedAnim = Tween<double>(
        begin: _previousBurned,
        end: _rawBurned.clamp(0.0, 1.5),
      ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isOverBudget = _rawConsumed >= 1.0;
    final isGoodProgress = _rawConsumed >= 0.8;
    final net =
        (widget.target - widget.consumed + widget.burned).roundToDouble();
    final hasBurned = widget.burned > 0;

    return Semantics(
      label: '${widget.consumed.toInt()} of ${widget.target.toInt()} '
          'calories consumed, '
          '${widget.burned.toInt()} burned, '
          '${net.toInt()} net remaining',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: hasBurned
            ? () {
                HapticFeedback.selectionClick();
                setState(() => _showBreakdown = !_showBreakdown);
              }
            : null,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return SizedBox(
              width: 220,
              height: 220,
              child: CustomPaint(
                painter: _CalorieRingPainter(
                  consumedProgress: _consumedAnim.value.clamp(0.0, 1.0),
                  burnedProgress: _burnedAnim.value.clamp(0.0, 1.0),
                  trackColor: palette.surfaceElevated,
                  consumedColor: isOverBudget
                      ? palette.destructive
                      : isGoodProgress
                          ? palette.success
                          : palette.accent,
                  burnedColor: const Color(0xFFFF9F0A),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _showBreakdown && hasBurned
                        ? _Breakdown(
                            key: const ValueKey('breakdown'),
                            consumed: widget.consumed,
                            burned: widget.burned,
                            target: widget.target,
                          )
                        : _NetView(
                            key: const ValueKey('net'),
                            net: net,
                            target: widget.target,
                            consumed: widget.consumed,
                            burned: widget.burned,
                            isOverBudget: isOverBudget,
                            showBurnedSubline: hasBurned,
                            textTheme: textTheme,
                            colorScheme: colorScheme,
                            palette: palette,
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NetView extends StatelessWidget {
  const _NetView({
    super.key,
    required this.net,
    required this.target,
    required this.consumed,
    required this.burned,
    required this.isOverBudget,
    required this.showBurnedSubline,
    required this.textTheme,
    required this.colorScheme,
    required this.palette,
  });

  final double net;
  final double target;
  final double consumed;
  final double burned;
  final bool isOverBudget;
  final bool showBurnedSubline;
  final TextTheme textTheme;
  final ColorScheme colorScheme;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          net.toInt().toString(),
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isOverBudget && net < 0
                ? palette.destructive
                : colorScheme.onSurface,
          ),
        ),
        Text(
          showBurnedSubline ? 'Net Remaining' : '/ ${target.toInt()} kcal',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        if (showBurnedSubline)
          Text(
            'Eaten ${consumed.toInt()} · Burned ${burned.toInt()}',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else
          Text(
            isOverBudget
                ? '+${(consumed - target).toInt()} kcal over'
                : '${(target - consumed).toInt()} kcal left',
            style: textTheme.labelSmall?.copyWith(
              color: isOverBudget
                  ? palette.destructive
                  : colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({
    super.key,
    required this.consumed,
    required this.burned,
    required this.target,
  });

  final double consumed;
  final double burned;
  final double target;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final remaining = target - consumed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _BreakdownRow(
          label: 'Goal',
          value: target.toInt(),
          color: palette.textSecondary,
          textTheme: textTheme,
        ),
        const SizedBox(height: 2),
        _BreakdownRow(
          label: 'Eaten',
          value: consumed.toInt(),
          color: palette.accent,
          textTheme: textTheme,
          prefix: '−',
        ),
        const SizedBox(height: 2),
        _BreakdownRow(
          label: 'Burned',
          value: burned.toInt(),
          color: const Color(0xFFFF9F0A),
          textTheme: textTheme,
          prefix: '+',
        ),
        const SizedBox(height: 4),
        Container(
          width: 110,
          height: 1,
          color: palette.border,
        ),
        const SizedBox(height: 4),
        _BreakdownRow(
          label: 'Left',
          value: (remaining + burned).toInt(),
          color: palette.text,
          textTheme: textTheme,
          bold: true,
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.color,
    required this.textTheme,
    this.prefix = '',
    this.bold = false,
  });

  final String label;
  final int value;
  final Color color;
  final TextTheme textTheme;
  final String prefix;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            '$prefix$value',
            textAlign: TextAlign.right,
            style: textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CalorieRingPainter extends CustomPainter {
  _CalorieRingPainter({
    required this.consumedProgress,
    required this.burnedProgress,
    required this.trackColor,
    required this.consumedColor,
    required this.burnedColor,
  });

  final double consumedProgress;
  final double burnedProgress;
  final Color trackColor;
  final Color consumedColor;
  final Color burnedColor;

  static const _consumedStroke = 14.0;
  static const _burnedStroke = 6.0;
  static const _gap = 6.0;
  static const _dashWidth = 6.0;
  static const _dashGap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Inner consumed ring
    final consumedRadius =
        (min(size.width, size.height) - _consumedStroke) / 2 - 12;
    final consumedRect =
        Rect.fromCircle(center: center, radius: consumedRadius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _consumedStroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, consumedRadius, trackPaint);

    if (consumedProgress > 0) {
      final sweep = 2 * pi * consumedProgress.clamp(0.0, 0.999);
      final paint = Paint()
        ..color = consumedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _consumedStroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(consumedRect, -pi / 2, sweep, false, paint);
    }

    if (burnedProgress > 0) {
      final burnedRadius =
          consumedRadius + _consumedStroke / 2 + _gap + _burnedStroke / 2;
      final sweep = 2 * pi * burnedProgress.clamp(0.0, 0.999);
      final path = Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: burnedRadius),
          -pi / 2,
          sweep,
        );
      final dashed = Path();
      for (final metric in path.computeMetrics()) {
        var distance = 0.0;
        while (distance < metric.length) {
          final end = min(distance + _dashWidth, metric.length);
          dashed.addPath(metric.extractPath(distance, end), Offset.zero);
          distance += _dashWidth + _dashGap;
        }
      }
      final paint = Paint()
        ..color = burnedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _burnedStroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(dashed, paint);
    }
  }

  @override
  bool shouldRepaint(_CalorieRingPainter old) =>
      consumedProgress != old.consumedProgress ||
      burnedProgress != old.burnedProgress ||
      trackColor != old.trackColor ||
      consumedColor != old.consumedColor ||
      burnedColor != old.burnedColor;
}
