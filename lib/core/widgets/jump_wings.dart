import 'package:flutter/widgets.dart';

import '../theme/field_manual.dart';

/// The Airborne insignia: parachute canopy flanked by swept wings, drawn in
/// the same stroke language as the rank chevrons (round-capped strokes at the
/// chevron weight, no fills). Used wherever Airborne is named — the paywall,
/// the Settings row, upsell affordances.
class JumpWings extends StatelessWidget {
  const JumpWings({
    super.key,
    this.width = 72,
    this.color = FieldManual.brass,
    this.glow = false,
  });

  /// Rendered width; height follows the 96:44 design ratio.
  final double width;
  final Color color;

  /// Adds a soft same-hue bloom behind the strokes. Ceremony use only
  /// (the Quiet Chrome / Loud Ceremony Rule).
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Airborne insignia',
      child: CustomPaint(
        size: Size(width, width * 44 / 96),
        painter: _JumpWingsPainter(color: color, glow: glow),
      ),
    );
  }
}

class _JumpWingsPainter extends CustomPainter {
  const _JumpWingsPainter({required this.color, required this.glow});

  final Color color;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    // Design space: 96 × 44; stroke weight tracks the rank chevrons'.
    final s = size.width / 96;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      // Floor keeps the insignia legible at glyph sizes (e.g. 22pt wide).
      ..strokeWidth = (3.2 * s).clamp(1.2, double.infinity)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    final path = Path()
      // Canopy dome.
      ..moveTo(36 * s, 16 * s)
      ..quadraticBezierTo(48 * s, 0, 60 * s, 16 * s)
      // Risers converging toward the harness point.
      ..moveTo(37 * s, 17 * s)
      ..lineTo(47 * s, 32 * s)
      ..moveTo(59 * s, 17 * s)
      ..lineTo(49 * s, 32 * s)
      // Left wing, three feather tiers sweeping up to the tip.
      ..moveTo(42 * s, 34 * s)
      ..quadraticBezierTo(26 * s, 33 * s, 8 * s, 16 * s)
      ..moveTo(42 * s, 38 * s)
      ..quadraticBezierTo(28 * s, 38 * s, 14 * s, 26 * s)
      ..moveTo(42 * s, 42 * s)
      ..quadraticBezierTo(30 * s, 43 * s, 20 * s, 34 * s)
      // Right wing, mirrored.
      ..moveTo(54 * s, 34 * s)
      ..quadraticBezierTo(70 * s, 33 * s, 88 * s, 16 * s)
      ..moveTo(54 * s, 38 * s)
      ..quadraticBezierTo(68 * s, 38 * s, 82 * s, 26 * s)
      ..moveTo(54 * s, 42 * s)
      ..quadraticBezierTo(66 * s, 43 * s, 76 * s, 34 * s);

    if (glow) {
      final bloom = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.strokeWidth * 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = color.withValues(alpha: 0.45);
      canvas.drawPath(path, bloom);
    }
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_JumpWingsPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.glow != glow;
}
