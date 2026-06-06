import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/military_ranks.dart';

/// Reusable insignia + label for a [MilitaryRank]. The chevrons are drawn
/// programmatically (same upward-chevron style as the DrillFit app icon),
/// tinted with the rank's colour, with star / eagle / specialist-disk marks
/// added for the senior ranks.
///
///   * [compact] — icon + abbreviation (e.g. "SGT") in a tight row.
///   * default   — icon + full rank name (e.g. "Sergeant").
///   * [size]    — the insignia's height in logical pixels (text scales with it).
class RankBadge extends StatelessWidget {
  const RankBadge({
    super.key,
    required this.rank,
    this.compact = false,
    this.size = 24,
  });

  final MilitaryRank rank;
  final bool compact;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = rank.color;
    final icon = RankInsignia(rank: rank, size: size);

    final label = compact ? rank.abbreviation : rank.displayName;
    final fontSize = compact ? size * 0.46 : size * 0.52;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: compact ? size * 0.2 : size * 0.32),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              color: color,
              letterSpacing: compact ? 0.3 : 0,
            ),
          ),
        ),
      ],
    );
  }
}

/// Just the rank insignia mark (no text). [size] is its height; the width is
/// slightly narrower. Optionally tint with [color] instead of the rank colour.
class RankInsignia extends StatelessWidget {
  const RankInsignia({
    super.key,
    required this.rank,
    this.size = 24,
    this.color,
  });

  final MilitaryRank rank;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 0.92,
      height: size,
      child: CustomPaint(
        painter: _RankInsigniaPainter(rank: rank, color: color ?? rank.color),
      ),
    );
  }
}

/// Insignia layout for one rank — chevron count plus the senior-rank marks.
class _Insignia {
  const _Insignia(
    this.chevrons, {
    this.circle = false,
    this.star = false,
    this.eagle = false,
    this.bold = false,
  });
  final int chevrons;
  final bool circle; // Specialist disk
  final bool star; // Sergeant Major
  final bool eagle; // SMA
  final bool bold; // Sergeant — slightly heavier chevrons
}

_Insignia _insigniaFor(MilitaryRank rank) {
  switch (rank) {
    case MilitaryRank.private_e1:
      return const _Insignia(1);
    case MilitaryRank.privateFc_e2:
      return const _Insignia(2);
    case MilitaryRank.corporal_e3:
      return const _Insignia(3);
    case MilitaryRank.specialist_e4:
      return const _Insignia(3, circle: true);
    case MilitaryRank.sergeant_e5:
      return const _Insignia(3, bold: true);
    case MilitaryRank.staffSergeant_e6:
      return const _Insignia(4);
    case MilitaryRank.sergeantFc_e7:
      return const _Insignia(5);
    case MilitaryRank.masterSergeant_e8:
      return const _Insignia(6);
    case MilitaryRank.sergeantMajor_e9:
      return const _Insignia(3, star: true);
    case MilitaryRank.sgmArmy_e10:
      return const _Insignia(3, star: true, eagle: true);
  }
}

/// Paints a [MilitaryRank]'s insignia — chevrons plus any senior-rank star /
/// eagle / specialist-disk marks — into [canvas], filling [size] and tinted
/// [color]. Extracted as a free function so the [RankInsignia] widget (used both
/// in-app and inside the captured rank card) draws from one source of truth.
void paintRankInsignia(
    Canvas canvas, Size size, MilitaryRank rank, Color color) {
  final cfg = _insigniaFor(rank);
  final w = size.width;
  final h = size.height;
  final cx = w / 2;

  final stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final fill = Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  // Reserve a top band for the senior-rank emblems; the chevrons fill the
  // rest below them.
  var top = 0.0;
  if (cfg.eagle) top += h * 0.20;
  if (cfg.star) top += h * 0.16;
  if (cfg.circle) top += h * 0.18;

  final bandTop = top;
  final bandBottom = h * 0.98;
  final bandH = math.max(0.0, bandBottom - bandTop);
  final n = cfg.chevrons;

  if (n > 0 && bandH > 0) {
    final step = bandH / (n + 0.4);
    final armDrop = step * 1.3;
    final halfW = w * 0.34;
    final sw = (step * 0.5 * (cfg.bold ? 1.25 : 1.0)).clamp(1.2, h * 0.18);
    stroke.strokeWidth = sw;

    for (var i = 0; i < n; i++) {
      // i == 0 is the bottom (widest-feeling) chevron.
      final peakY = bandBottom - armDrop - i * step;
      final path = Path()
        ..moveTo(cx - halfW, peakY + armDrop)
        ..lineTo(cx, peakY)
        ..lineTo(cx + halfW, peakY + armDrop);
      canvas.drawPath(path, stroke);
    }
  }

  // Emblems, drawn top-to-bottom within the reserved band.
  var ey = 0.0;
  if (cfg.eagle) {
    _drawEagle(canvas, fill, Offset(cx, ey + h * 0.10), w * 0.46);
    ey += h * 0.20;
  }
  if (cfg.star) {
    _drawStar(canvas, fill, Offset(cx, ey + h * 0.08), h * 0.085);
    ey += h * 0.16;
  }
  if (cfg.circle) {
    canvas.drawCircle(Offset(cx, ey + h * 0.09), h * 0.06, fill);
  }
}

/// A filled 5-pointed star centred at [c] with circum-radius [r].
void _drawStar(Canvas canvas, Paint paint, Offset c, double r) {
  final path = Path();
  const points = 5;
  final inner = r * 0.42;
  for (var i = 0; i < points * 2; i++) {
    final radius = i.isEven ? r : inner;
    final angle = -math.pi / 2 + i * math.pi / points;
    final x = c.dx + radius * math.cos(angle);
    final y = c.dy + radius * math.sin(angle);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  path.close();
  canvas.drawPath(path, paint);
}

/// A small stylised spread-wing eagle emblem centred at [c], [width] wide.
void _drawEagle(Canvas canvas, Paint paint, Offset c, double width) {
  final hw = width / 2;
  final wings = Path()
    ..moveTo(c.dx - hw, c.dy)
    ..quadraticBezierTo(
        c.dx - hw * 0.4, c.dy - width * 0.20, c.dx, c.dy + width * 0.04)
    ..quadraticBezierTo(c.dx + hw * 0.4, c.dy - width * 0.20, c.dx + hw, c.dy)
    ..quadraticBezierTo(
        c.dx + hw * 0.4, c.dy + width * 0.12, c.dx, c.dy + width * 0.20)
    ..quadraticBezierTo(c.dx - hw * 0.4, c.dy + width * 0.12, c.dx - hw, c.dy)
    ..close();
  canvas.drawPath(wings, paint);
  // Head.
  canvas.drawCircle(Offset(c.dx, c.dy - width * 0.06), width * 0.08, paint);
}

class _RankInsigniaPainter extends CustomPainter {
  _RankInsigniaPainter({required this.rank, required this.color});

  final MilitaryRank rank;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      paintRankInsignia(canvas, size, rank, color);

  @override
  bool shouldRepaint(_RankInsigniaPainter old) =>
      old.rank != rank || old.color != color;
}
