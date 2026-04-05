import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/enums.dart';

/// Display-only muscle group body diagram showing front and back silhouettes
/// side by side with highlighted primary (error/red) and secondary (tertiary/orange)
/// muscle regions.
class MuscleGroupDiagram extends StatelessWidget {
  const MuscleGroupDiagram({
    super.key,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    this.height = 200,
  });

  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final allPrimary = primaryMuscles.map((m) => m.label).join(', ');
    final allSecondary = secondaryMuscles.map((m) => m.label).join(', ');
    final semanticsLabel = [
      if (primaryMuscles.isNotEmpty) 'Primary muscles: $allPrimary',
      if (secondaryMuscles.isNotEmpty) 'Secondary muscles: $allSecondary',
      if (primaryMuscles.isEmpty && secondaryMuscles.isEmpty)
        'No muscle groups highlighted',
    ].join('. ');

    return Semantics(
      label: semanticsLabel,
      child: Column(
        children: [
          // Labels row
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    'Front',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Back',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: height,
            child: CustomPaint(
              size: Size.infinite,
              painter: _BodyDiagramPainter(
                primaryMuscles: primaryMuscles,
                secondaryMuscles: secondaryMuscles,
                bodyColor: colorScheme.surfaceContainerHighest,
                outlineColor: colorScheme.outline,
                primaryColor: colorScheme.error,
                secondaryColor: colorScheme.tertiary,
              ),
            ),
          ),
          // Legend
          if (primaryMuscles.isNotEmpty || secondaryMuscles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (primaryMuscles.isNotEmpty) ...[
                    _LegendDot(color: colorScheme.error),
                    const SizedBox(width: 4),
                    Text(
                      'Primary',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (primaryMuscles.isNotEmpty && secondaryMuscles.isNotEmpty)
                    const SizedBox(width: 16),
                  if (secondaryMuscles.isNotEmpty) ...[
                    _LegendDot(color: colorScheme.tertiary),
                    const SizedBox(width: 4),
                    Text(
                      'Secondary',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _BodyDiagramPainter extends CustomPainter {
  _BodyDiagramPainter({
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.bodyColor,
    required this.outlineColor,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final Color bodyColor;
  final Color outlineColor;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final halfW = size.width / 2;

    // Front silhouette on left half
    _drawFrontBody(canvas, Size(halfW, size.height), Offset.zero);

    // Back silhouette on right half
    _drawBackBody(canvas, Size(halfW, size.height), Offset(halfW, 0));
  }

  // ---------------------------------------------------------------------------
  // FRONT BODY
  // ---------------------------------------------------------------------------

  void _drawFrontBody(Canvas canvas, Size size, Offset origin) {
    final w = size.width;
    final h = size.height;

    // Normalised silhouette path for front body
    // Scale coordinates from 0-1 to canvas size
    double x(double nx) => origin.dx + nx * w;
    double y(double ny) => origin.dy + ny * h;

    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // --- Draw simplified front body silhouette ---
    final path = Path();
    // Head
    path.addOval(Rect.fromCenter(
      center: Offset(x(0.5), y(0.07)),
      width: w * 0.2,
      height: h * 0.12,
    ));
    // Torso
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x(0.35), y(0.14), w * 0.3, h * 0.36),
      const Radius.circular(6),
    ));
    // Left arm
    _drawRoundedRect(
        canvas, bodyPaint, x(0.22), y(0.14), w * 0.12, h * 0.32, 4);
    _drawRoundedRectOutline(
        canvas, outlinePaint, x(0.22), y(0.14), w * 0.12, h * 0.32, 4);
    // Right arm
    _drawRoundedRect(
        canvas, bodyPaint, x(0.66), y(0.14), w * 0.12, h * 0.32, 4);
    _drawRoundedRectOutline(
        canvas, outlinePaint, x(0.66), y(0.14), w * 0.12, h * 0.32, 4);
    // Left leg
    _drawRoundedRect(
        canvas, bodyPaint, x(0.35), y(0.52), w * 0.13, h * 0.44, 5);
    _drawRoundedRectOutline(
        canvas, outlinePaint, x(0.35), y(0.52), w * 0.13, h * 0.44, 5);
    // Right leg
    _drawRoundedRect(
        canvas, bodyPaint, x(0.52), y(0.52), w * 0.13, h * 0.44, 5);
    _drawRoundedRectOutline(
        canvas, outlinePaint, x(0.52), y(0.52), w * 0.13, h * 0.44, 5);

    canvas.drawPath(path, bodyPaint);
    canvas.drawPath(path, outlinePaint);

    // --- Neck connector ---
    _drawRoundedRect(canvas, bodyPaint, x(0.44), y(0.12), w * 0.12, h * 0.04, 2);
    _drawRoundedRectOutline(
        canvas, outlinePaint, x(0.44), y(0.12), w * 0.12, h * 0.04, 2);

    // --- Draw highlighted muscle regions (front) ---
    for (final muscle in MuscleGroup.values) {
      final isPrimary = primaryMuscles.contains(muscle);
      final isSecondary = secondaryMuscles.contains(muscle);
      if (!isPrimary && !isSecondary) continue;

      final color = isPrimary ? primaryColor : secondaryColor;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.75)
        ..style = PaintingStyle.fill;

      switch (muscle) {
        case MuscleGroup.chest:
          // Upper chest — two pec regions
          _drawRoundedRect(
              canvas, paint, x(0.38), y(0.16), w * 0.1, h * 0.11, 4);
          _drawRoundedRect(
              canvas, paint, x(0.52), y(0.16), w * 0.1, h * 0.11, 4);
          break;
        case MuscleGroup.shoulders:
          // Front deltoids — tops of arms
          _drawOval(canvas, paint, x(0.26), y(0.14), w * 0.08, h * 0.07);
          _drawOval(canvas, paint, x(0.66), y(0.14), w * 0.08, h * 0.07);
          break;
        case MuscleGroup.biceps:
          // Mid upper arm front
          _drawRoundedRect(
              canvas, paint, x(0.23), y(0.22), w * 0.1, h * 0.11, 4);
          _drawRoundedRect(
              canvas, paint, x(0.67), y(0.22), w * 0.1, h * 0.11, 4);
          break;
        case MuscleGroup.forearms:
          _drawRoundedRect(
              canvas, paint, x(0.23), y(0.35), w * 0.1, h * 0.11, 4);
          _drawRoundedRect(
              canvas, paint, x(0.67), y(0.35), w * 0.1, h * 0.11, 4);
          break;
        case MuscleGroup.abs:
          // Six-pack grid
          for (int row = 0; row < 3; row++) {
            _drawRoundedRect(canvas, paint, x(0.38), y(0.29 + row * 0.07),
                w * 0.09, h * 0.05, 3);
            _drawRoundedRect(canvas, paint, x(0.53), y(0.29 + row * 0.07),
                w * 0.09, h * 0.05, 3);
          }
          break;
        case MuscleGroup.obliques:
          _drawRoundedRect(
              canvas, paint, x(0.35), y(0.28), w * 0.05, h * 0.18, 4);
          _drawRoundedRect(
              canvas, paint, x(0.60), y(0.28), w * 0.05, h * 0.18, 4);
          break;
        case MuscleGroup.quads:
          // Front of upper leg
          _drawRoundedRect(
              canvas, paint, x(0.36), y(0.53), w * 0.12, h * 0.22, 5);
          _drawRoundedRect(
              canvas, paint, x(0.52), y(0.53), w * 0.12, h * 0.22, 5);
          break;
        case MuscleGroup.calves:
          // Lower legs
          _drawRoundedRect(
              canvas, paint, x(0.37), y(0.78), w * 0.10, h * 0.16, 5);
          _drawRoundedRect(
              canvas, paint, x(0.53), y(0.78), w * 0.10, h * 0.16, 5);
          break;
        case MuscleGroup.cardio:
          // Heart icon region in chest
          _drawRoundedRect(
              canvas, paint, x(0.40), y(0.19), w * 0.20, h * 0.10, 4);
          break;
        default:
          break;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // BACK BODY
  // ---------------------------------------------------------------------------

  void _drawBackBody(Canvas canvas, Size size, Offset origin) {
    final w = size.width;
    final h = size.height;

    double x(double nx) => origin.dx + nx * w;
    double y(double ny) => origin.dy + ny * h;

    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Head
    final headPath = Path();
    headPath.addOval(Rect.fromCenter(
      center: Offset(x(0.5), y(0.07)),
      width: w * 0.2,
      height: h * 0.12,
    ));
    canvas.drawPath(headPath, bodyPaint);
    canvas.drawPath(headPath, outlinePaint);

    // Torso
    _drawRoundedRect(canvas, bodyPaint, x(0.35), y(0.14), w * 0.30, h * 0.36, 6);
    _drawRoundedRectOutline(
        canvas, outlinePaint, x(0.35), y(0.14), w * 0.30, h * 0.36, 6);

    // Arms
    _drawRoundedRect(canvas, bodyPaint, x(0.22), y(0.14), w * 0.12, h * 0.32, 4);
    _drawRoundedRectOutline(
        canvas, outlinePaint, x(0.22), y(0.14), w * 0.12, h * 0.32, 4);
    _drawRoundedRect(canvas, bodyPaint, x(0.66), y(0.14), w * 0.12, h * 0.32, 4);
    _drawRoundedRectOutline(
        canvas, outlinePaint, x(0.66), y(0.14), w * 0.12, h * 0.32, 4);

    // Legs
    _drawRoundedRect(canvas, bodyPaint, x(0.35), y(0.52), w * 0.13, h * 0.44, 5);
    _drawRoundedRectOutline(
        canvas, outlinePaint, x(0.35), y(0.52), w * 0.13, h * 0.44, 5);
    _drawRoundedRect(canvas, bodyPaint, x(0.52), y(0.52), w * 0.13, h * 0.44, 5);
    _drawRoundedRectOutline(
        canvas, outlinePaint, x(0.52), y(0.52), w * 0.13, h * 0.44, 5);

    // Neck
    _drawRoundedRect(canvas, bodyPaint, x(0.44), y(0.12), w * 0.12, h * 0.04, 2);
    _drawRoundedRectOutline(
        canvas, outlinePaint, x(0.44), y(0.12), w * 0.12, h * 0.04, 2);

    // --- Highlighted muscle regions (back) ---
    for (final muscle in MuscleGroup.values) {
      final isPrimary = primaryMuscles.contains(muscle);
      final isSecondary = secondaryMuscles.contains(muscle);
      if (!isPrimary && !isSecondary) continue;

      final color = isPrimary ? primaryColor : secondaryColor;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.75)
        ..style = PaintingStyle.fill;

      switch (muscle) {
        case MuscleGroup.upperBack:
          // Trapezius / rhomboids
          _drawRoundedRect(
              canvas, paint, x(0.38), y(0.15), w * 0.24, h * 0.13, 4);
          break;
        case MuscleGroup.lats:
          // Latissimus — widens toward waist
          _drawRoundedRect(
              canvas, paint, x(0.36), y(0.26), w * 0.10, h * 0.18, 4);
          _drawRoundedRect(
              canvas, paint, x(0.54), y(0.26), w * 0.10, h * 0.18, 4);
          break;
        case MuscleGroup.shoulders:
          // Rear deltoids
          _drawOval(canvas, paint, x(0.26), y(0.14), w * 0.08, h * 0.07);
          _drawOval(canvas, paint, x(0.66), y(0.14), w * 0.08, h * 0.07);
          break;
        case MuscleGroup.triceps:
          // Back of upper arm
          _drawRoundedRect(
              canvas, paint, x(0.23), y(0.22), w * 0.10, h * 0.11, 4);
          _drawRoundedRect(
              canvas, paint, x(0.67), y(0.22), w * 0.10, h * 0.11, 4);
          break;
        case MuscleGroup.forearms:
          _drawRoundedRect(
              canvas, paint, x(0.23), y(0.35), w * 0.10, h * 0.11, 4);
          _drawRoundedRect(
              canvas, paint, x(0.67), y(0.35), w * 0.10, h * 0.11, 4);
          break;
        case MuscleGroup.glutes:
          _drawRoundedRect(
              canvas, paint, x(0.37), y(0.50), w * 0.12, h * 0.10, 4);
          _drawRoundedRect(
              canvas, paint, x(0.51), y(0.50), w * 0.12, h * 0.10, 4);
          break;
        case MuscleGroup.hamstrings:
          _drawRoundedRect(
              canvas, paint, x(0.36), y(0.54), w * 0.12, h * 0.20, 5);
          _drawRoundedRect(
              canvas, paint, x(0.52), y(0.54), w * 0.12, h * 0.20, 5);
          break;
        case MuscleGroup.calves:
          _drawRoundedRect(
              canvas, paint, x(0.37), y(0.78), w * 0.10, h * 0.16, 5);
          _drawRoundedRect(
              canvas, paint, x(0.53), y(0.78), w * 0.10, h * 0.16, 5);
          break;
        case MuscleGroup.cardio:
          _drawRoundedRect(
              canvas, paint, x(0.40), y(0.19), w * 0.20, h * 0.10, 4);
          break;
        default:
          break;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _drawRoundedRect(Canvas canvas, Paint paint, double x, double y,
      double w, double h, double r) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
      paint,
    );
  }

  void _drawRoundedRectOutline(Canvas canvas, Paint paint, double x, double y,
      double w, double h, double r) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
      paint,
    );
  }

  void _drawOval(Canvas canvas, Paint paint, double cx, double cy, double w,
      double h) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BodyDiagramPainter oldDelegate) {
    return !listEquals(oldDelegate.primaryMuscles, primaryMuscles) ||
        !listEquals(oldDelegate.secondaryMuscles, secondaryMuscles) ||
        oldDelegate.bodyColor != bodyColor ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
