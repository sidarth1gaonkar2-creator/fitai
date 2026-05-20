import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// Three-state calorie ring:
///   * **On pace** — blue ring, large consumed number, "kcal left" caption.
///   * **Over budget** — red ring, large consumed number in red, "kcal over"
///     caption.
///   * **Health connected** — green ring once consumed >= 80%, otherwise
///     blue; centre shows "NET REMAINING" + a goal / eaten / burned
///     breakdown below the ring.
///
/// Tap to toggle between the consumed view and the net-remaining view when
/// Health data is present.
class CalorieRing extends StatefulWidget {
  const CalorieRing({
    super.key,
    required this.consumed,
    required this.target,
    this.burned = 0,
    this.compact = false,
  });

  final double consumed;
  final double target;
  final double burned;

  /// Compact mode shrinks the ring to fit a smaller card slot (e.g. the
  /// Nutrition screen summary) and hides the caption row below the ring so
  /// the parent layout doesn't need to reserve vertical space for it.
  final bool compact;

  @override
  State<CalorieRing> createState() => _CalorieRingState();
}

class _CalorieRingState extends State<CalorieRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _fill;
  double _previousFill = 0;
  bool _showNetView = false;

  double get _fraction =>
      widget.target > 0 ? widget.consumed / widget.target : 0;

  bool get _isOverBudget => widget.consumed > widget.target;
  bool get _isGoodProgress => _fraction >= 0.8;
  bool get _hasBurned => widget.burned > 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fill = Tween<double>(begin: 0, end: _fraction.clamp(0.0, 1.5))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    // Default to net view when Health is connected — that's the
    // information-dense state the spec calls for.
    _showNetView = _hasBurned;
  }

  @override
  void didUpdateWidget(covariant CalorieRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.consumed != widget.consumed ||
        oldWidget.target != widget.target ||
        oldWidget.burned != widget.burned) {
      _previousFill = _fill.value;
      _fill = Tween<double>(
        begin: _previousFill,
        end: _fraction.clamp(0.0, 1.5),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _ringColor(Palette palette) {
    if (_isOverBudget) return palette.destructive;
    if (_hasBurned && _isGoodProgress) return palette.success;
    return palette.accent;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final ringColor = _ringColor(palette);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: '${widget.consumed.toInt()} of ${widget.target.toInt()} '
              'calories consumed'
              '${_hasBurned ? ", ${widget.burned.toInt()} burned" : ""}',
          button: _hasBurned,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _hasBurned
                ? () {
                    HapticFeedback.selectionClick();
                    setState(() => _showNetView = !_showNetView);
                  }
                : null,
            child: AnimatedBuilder(
              animation: _fill,
              builder: (context, _) {
                final ringSize = widget.compact ? 120.0 : 220.0;
                return SizedBox(
                  width: ringSize,
                  height: ringSize,
                  child: CustomPaint(
                    painter: _RingPainter(
                      progress: _fill.value.clamp(0.0, 1.0),
                      trackColor: const Color(0xFF2C2C2E),
                      ringColor: ringColor,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _showNetView && _hasBurned
                            ? _NetCenter(
                                key: const ValueKey('net'),
                                consumed: widget.consumed,
                                burned: widget.burned,
                                target: widget.target,
                                palette: palette,
                              )
                            : _ConsumedCenter(
                                key: const ValueKey('consumed'),
                                consumed: widget.consumed,
                                target: widget.target,
                                isOver: _isOverBudget,
                                palette: palette,
                                compact: widget.compact,
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Caption under the ring — full mode only. Compact mode skips the
        // caption so the ring fits inside the smaller container slot used
        // on the Nutrition screen summary card.
        if (!widget.compact) ...[
          const SizedBox(height: 12),
          if (_showNetView && _hasBurned)
            _HealthBreakdown(
              target: widget.target,
              consumed: widget.consumed,
              burned: widget.burned,
              palette: palette,
            )
          else if (_isOverBudget)
            Text(
              '+${(widget.consumed - widget.target).toInt()} kcal over',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: palette.destructive,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            )
          else
            Text(
              'On track · ${(widget.target - widget.consumed).toInt()} kcal left',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: palette.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ],
    );
  }
}

class _ConsumedCenter extends StatelessWidget {
  const _ConsumedCenter({
    super.key,
    required this.consumed,
    required this.target,
    required this.isOver,
    required this.palette,
    this.compact = false,
  });

  final double consumed;
  final double target;
  final bool isOver;
  final Palette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          consumed.toInt().toString(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: compact ? 22 : 32,
            color: isOver ? palette.destructive : palette.text,
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1.05,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          compact
              ? '/ ${target.toInt()}'
              : 'of ${target.toInt()} kcal',
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            color: palette.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _NetCenter extends StatelessWidget {
  const _NetCenter({
    super.key,
    required this.consumed,
    required this.burned,
    required this.target,
    required this.palette,
  });

  final double consumed;
  final double burned;
  final double target;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final net = (target - consumed + burned).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'NET REMAINING',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.1,
            color: palette.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          net.toString(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 32,
            color: net < 0 ? palette.destructive : palette.text,
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

class _HealthBreakdown extends StatelessWidget {
  const _HealthBreakdown({
    required this.target,
    required this.consumed,
    required this.burned,
    required this.palette,
  });

  final double target;
  final double consumed;
  final double burned;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BreakdownRow(
          label: 'Goal',
          value: target.toInt().toString(),
          valueColor: palette.text,
          palette: palette,
        ),
        const SizedBox(height: 4),
        _BreakdownRow(
          label: 'Eaten',
          value: '− ${consumed.toInt()}',
          valueColor: palette.accent,
          palette: palette,
        ),
        const SizedBox(height: 4),
        _BreakdownRow(
          label: 'Burned',
          value: '+ ${burned.toInt()}',
          valueColor: palette.warning,
          palette: palette,
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.palette,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: palette.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 72,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.ringColor,
  });

  final double progress;
  final Color trackColor;
  final Color ringColor;

  static const _stroke = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - _stroke) / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    // Fill
    if (progress > 0) {
      final sweep = 2 * pi * progress.clamp(0.0, 0.9999);
      final fill = Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -pi / 2, sweep, false, fill);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      progress != old.progress ||
      trackColor != old.trackColor ||
      ringColor != old.ringColor;
}
