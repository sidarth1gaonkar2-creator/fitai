import 'package:flutter/widgets.dart';

import '../theme/field_manual.dart';

/// The DrillFit brand mark — the home-screen app-icon tile drawn in code:
/// three brass chevrons on an ink→field radial ground, rounded to the iOS
/// app-icon corner. The geometry mirrors `tool/app_icon/generate.mjs` (the
/// app-icon generator) so the in-app mark and the shipped launcher icon stay
/// identical. Field Manual doctrine: no glow (quiet chrome), no dumbbell, no
/// text — the DRILLFIT wordmark is a separate widget alongside it.
///
/// Replaces the old `assets/images/app-icon.png` blue raster wherever the mark
/// appears in-app (welcome screen, shareable rank card).
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 96,
    this.color = FieldManual.brass,
  });

  /// Rendered edge length; the mark is always square.
  final double size;

  /// The chevron color — brass by default. Per the Accent Swap Rule the
  /// ground stays ink regardless of the equipped theme pack.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'DrillFit',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _BrandMarkPainter(color: color),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter({required this.color});

  final Color color;

  // Icon design space and mark geometry (tool/app_icon/generate.mjs).
  static const double _canvas = 1024;
  static const double _stroke = 4.8; // logo units
  static const double _markWidthFrac = 0.58;
  static const double _chevW = 28;
  static const double _rise = 9;
  static const double _pitch = 10;
  static const double _apexX = 20;
  static const double _topApexY = 11;
  static const double _opticalNudgeY = -10;

  @override
  void paint(Canvas canvas, Size size) {
    // Work in the 1024 icon design space, scaled to the widget's edge.
    canvas.save();
    canvas.scale(size.width / _canvas);

    const rect = Rect.fromLTWH(0, 0, _canvas, _canvas);
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(_canvas * 0.2237), // iOS app-icon corner
    );

    // Ink→field radial lift (SVG cx 50% / cy 42% / r 72%) — matches the icon.
    final ground = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.16), // cy 42% → (0.42 − 0.5) × 2
        radius: 0.72,
        colors: [FieldManual.field, FieldManual.ink],
      ).createShader(rect);
    canvas.drawRRect(rrect, ground);
    canvas.clipRRect(rrect);

    // Transform into the chevron mark's own space (generate.mjs maths).
    const capR = _stroke / 2;
    const inkW = _chevW + _stroke; // round caps extend by capR each side
    const inkTop = _topApexY - capR;
    const inkBottom = _topApexY + _rise + 2 * _pitch + capR;
    const s = (_canvas * _markWidthFrac) / inkW;
    const tx = _canvas / 2 - _apexX * s;
    const ty = _canvas / 2 - ((inkTop + inkBottom) / 2) * s + _opticalNudgeY;

    canvas.save();
    canvas.translate(tx, ty);
    canvas.scale(s);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    // Three upward chevrons, apexes stacked at one pitch apart.
    for (final baseline in const [
      _topApexY + _rise,
      _topApexY + _rise + _pitch,
      _topApexY + _rise + 2 * _pitch,
    ]) {
      final path = Path()
        ..moveTo(_apexX - _chevW / 2, baseline)
        ..lineTo(_apexX, baseline - _rise)
        ..lineTo(_apexX + _chevW / 2, baseline);
      canvas.drawPath(path, stroke);
    }

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BrandMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
