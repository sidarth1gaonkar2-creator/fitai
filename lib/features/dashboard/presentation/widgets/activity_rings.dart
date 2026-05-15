import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/health_providers.dart';

/// Apple-style three-ring activity widget. Compact 80×80 dp on the dashboard.
/// Outer = Move (active kcal), middle = Exercise (active min), inner = Stand
/// (stand hours). If the user has no stand-hours permission / data, the
/// stand ring is hidden and we render only the two outer rings.
class ActivityRings extends ConsumerWidget {
  const ActivityRings({super.key});

  static const _moveColor = Color(0xFFFA114F);
  static const _exerciseColor = Color(0xFF92E82A);
  static const _standColor = Color(0xFF00C2FF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isIOS) return const SizedBox.shrink();
    if (!ref.watch(healthConnectedProvider)) return const SizedBox.shrink();
    if (!ref.watch(healthDashboardEnabledProvider)) {
      return const SizedBox.shrink();
    }

    final moveAsync = ref.watch(todayActiveCaloriesProvider);
    final exerciseAsync = ref.watch(todayActiveMinutesProvider);
    final standAsync = ref.watch(todayStandHoursProvider);
    final goals = ref.watch(activityGoalsProvider);

    final move = moveAsync.valueOrNull ?? 0.0;
    final exercise = exerciseAsync.valueOrNull ?? 0;
    final stand = standAsync.valueOrNull ?? 0;
    // (showStand is constant; standAsync's value is consumed by `stand`.)

    final movePct =
        goals.moveCalories <= 0 ? 0.0 : move / goals.moveCalories;
    final exercisePct =
        goals.exerciseMinutes <= 0 ? 0.0 : exercise / goals.exerciseMinutes;
    final standPct =
        goals.standHours <= 0 ? 0.0 : stand / goals.standHours;


    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          _RingsPainterHost(
            move: movePct,
            exercise: exercisePct,
            // APPLE_STAND_HOUR exists in the package so we always render the
            // stand ring; if the user has no Apple Watch it just sits at 0.
            stand: standPct,
            moveColor: _moveColor,
            exerciseColor: _exerciseColor,
            standColor: _standColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Activity',
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                _GoalLine(
                  color: _moveColor,
                  label: 'Move',
                  current: move.round(),
                  goal: goals.moveCalories,
                  unit: 'kcal',
                ),
                _GoalLine(
                  color: _exerciseColor,
                  label: 'Exercise',
                  current: exercise,
                  goal: goals.exerciseMinutes,
                  unit: 'min',
                ),
                _GoalLine(
                  color: _standColor,
                  label: 'Stand',
                  current: stand,
                  goal: goals.standHours,
                  unit: 'hr',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalLine extends StatelessWidget {
  const _GoalLine({
    required this.color,
    required this.label,
    required this.current,
    required this.goal,
    required this.unit,
  });

  final Color color;
  final String label;
  final int current;
  final int goal;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: palette.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            '$current / $goal $unit',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingsPainterHost extends StatefulWidget {
  const _RingsPainterHost({
    required this.move,
    required this.exercise,
    required this.stand,
    required this.moveColor,
    required this.exerciseColor,
    required this.standColor,
  });

  final double move;
  final double exercise;
  final double? stand;
  final Color moveColor;
  final Color exerciseColor;
  final Color standColor;

  @override
  State<_RingsPainterHost> createState() => _RingsPainterHostState();
}

class _RingsPainterHostState extends State<_RingsPainterHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  @override
  void didUpdateWidget(covariant _RingsPainterHost old) {
    super.didUpdateWidget(old);
    if (old.move != widget.move ||
        old.exercise != widget.exercise ||
        old.stand != widget.stand) {
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
    return SizedBox(
      width: 80,
      height: 80,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_controller.value);
          return CustomPaint(
            painter: _ActivityRingsPainter(
              move: widget.move * t,
              exercise: widget.exercise * t,
              stand: widget.stand == null ? null : widget.stand! * t,
              moveColor: widget.moveColor,
              exerciseColor: widget.exerciseColor,
              standColor: widget.standColor,
            ),
          );
        },
      ),
    );
  }
}

class _ActivityRingsPainter extends CustomPainter {
  _ActivityRingsPainter({
    required this.move,
    required this.exercise,
    required this.stand,
    required this.moveColor,
    required this.exerciseColor,
    required this.standColor,
  });

  final double move;
  final double exercise;
  final double? stand;
  final Color moveColor;
  final Color exerciseColor;
  final Color standColor;

  static const _stroke = 7.0;
  static const _gap = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius =
        (math.min(size.width, size.height) - _stroke) / 2;
    // Move (outer)
    _drawRing(canvas, center, outerRadius, move, moveColor);
    // Exercise (middle)
    final middleRadius = outerRadius - _stroke - _gap;
    if (middleRadius > _stroke) {
      _drawRing(canvas, center, middleRadius, exercise, exerciseColor);
    }
    // Stand (inner) — only if data present
    if (stand != null) {
      final innerRadius = middleRadius - _stroke - _gap;
      if (innerRadius > _stroke) {
        _drawRing(canvas, center, innerRadius, stand!, standColor);
      }
    }
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    double progress,
    Color color,
  ) {
    final track = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    if (progress <= 0) return;
    final clamped = progress.clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * clamped,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ActivityRingsPainter old) {
    return old.move != move ||
        old.exercise != exercise ||
        old.stand != stand ||
        old.moveColor != moveColor ||
        old.exerciseColor != exerciseColor ||
        old.standColor != standColor;
  }
}
