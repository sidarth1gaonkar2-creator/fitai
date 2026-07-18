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
    final icon = RankInsignia(rank: rank, size: size);

    final label = compact ? rank.abbreviation : rank.displayName;
    // 10px text floor regardless of insignia size — tiny abbreviations are
    // unreadable and fail AA.
    final fontSize = math.max(10.0, compact ? size * 0.46 : size * 0.52);
    // Rank colour is a material; text wears the lifted, AA-safe tone.
    final textColor = rank.textColor;

    // Field Manual type roles: abbreviations are mono designations
    // (Instrument Panel), full rank names wear the condensed display face.
    final style = compact
        ? TextStyle(
            fontFamily: 'JetBrainsMono',
            fontVariations: const [FontVariation('wght', 700)],
            fontWeight: FontWeight.w700,
            fontSize: fontSize,
            color: textColor,
            letterSpacing: 0.6,
          )
        : TextStyle(
            fontFamily: 'Oswald',
            fontVariations: const [FontVariation('wght', 600)],
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
            color: textColor,
            letterSpacing: 0.3,
          );

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
            style: style,
          ),
        ),
      ],
    );
  }
}

/// The command accent (DESIGN.md `brass`). An Airborne brand moment always
/// wears brass — the one accent the equipped theme pack never swaps.
const Color _brass = Color(0xFFC8A24B);

/// Just the rank insignia mark (no text). [size] is its height; the width is
/// slightly narrower. Optionally tint with [color] instead of the rank colour.
///
/// [airborne] renders the enriched, brass-mounted finish for a subscriber's
/// EARNED rank (same rank, elevated finish). It is dormant by default — every
/// existing call site renders the base insignia until Stage 2 gates it on the
/// Airborne entitlement.
class RankInsignia extends StatelessWidget {
  const RankInsignia({
    super.key,
    required this.rank,
    this.size = 24,
    this.color,
    this.airborne = false,
  });

  final MilitaryRank rank;
  final double size;
  final Color? color;
  final bool airborne;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 0.92,
      height: size,
      child: CustomPaint(
        painter: _RankInsigniaPainter(
            rank: rank, color: color ?? rank.color, airborne: airborne),
      ),
    );
  }
}

/// Insignia layout for one rank in the authentic US Army enlisted progression:
/// chevrons (top) → rockers (arcs below) → centre and flanking stars, with the
/// Specialist eagle-device and the blank Private sleeve as the two exceptions.
class _Insignia {
  const _Insignia({
    this.chevrons = 0,
    this.rockers = 0,
    this.centerStar = false,
    this.flankingStars = false,
    this.specialist = false,
    this.baseMark = false,
  });
  final int chevrons; // 0–3, pointing up, nested at the top
  final int rockers; // 0–3, arcs nested below the chevrons
  final bool centerStar; // Sergeant Major — star in the central void
  final bool flankingStars; // SMA — a star either side of the centre star
  final bool specialist; // SPC — the eagle "speck" device, no chevrons
  final bool baseMark; // Private — a single quiet field-stripe
}

_Insignia _insigniaFor(MilitaryRank rank) {
  switch (rank) {
    case MilitaryRank.private_e1:
      return const _Insignia(baseMark: true);
    case MilitaryRank.privateFc_e2:
      return const _Insignia(chevrons: 1);
    case MilitaryRank.corporal_e3:
      return const _Insignia(chevrons: 2);
    case MilitaryRank.specialist_e4:
      return const _Insignia(specialist: true);
    case MilitaryRank.sergeant_e5:
      return const _Insignia(chevrons: 3);
    case MilitaryRank.staffSergeant_e6:
      return const _Insignia(chevrons: 3, rockers: 1);
    case MilitaryRank.sergeantFc_e7:
      return const _Insignia(chevrons: 3, rockers: 2);
    case MilitaryRank.masterSergeant_e8:
      return const _Insignia(chevrons: 3, rockers: 3);
    case MilitaryRank.sergeantMajor_e9:
      return const _Insignia(chevrons: 3, rockers: 3, centerStar: true);
    case MilitaryRank.sgmArmy_e10:
      return const _Insignia(
          chevrons: 3, rockers: 3, centerStar: true, flankingStars: true);
  }
}

/// Paints a [MilitaryRank]'s insignia into [canvas], filling [size] and tinted
/// [color]. Chevrons nest at the top, rockers arc below them, and the senior
/// stars sit in the central void — the whole group is centred in [size] so the
/// one renderer reads crisply from the rank strip up to the celebration
/// overlay. Extracted as a free function so every surface (My Ranks ladder,
/// rank strip, celebration, share card, preview) draws one source of truth.
///
/// [airborne] wraps the earned insignia in the flat brass issued-mount — a
/// brass-tinted backing plate, a brass hairline frame, and corner rivets — the
/// enriched finish for an Airborne subscriber's own rank. The mount adds no
/// footprint (the marks inset to make room), stays flat (no glow/bevel), and
/// never recolours the tier marks: the rank you see is the rank you earned.
void paintRankInsignia(
  Canvas canvas,
  Size size,
  MilitaryRank rank,
  Color color, {
  bool airborne = false,
}) {
  if (!airborne) {
    _paintMarks(canvas, size, rank, color);
    return;
  }
  _paintAirborneMount(canvas, size);
  // Inset the marks so the frame reads without enlarging the insignia box. Ease
  // the inset at rank-strip sizes so the tier mark keeps its size (the frame
  // alone already signals "mounted") instead of the container out-shouting it.
  final short = math.min(size.width, size.height);
  final insetFrac = short < 34 ? 0.08 : 0.11;
  final dx = size.width * insetFrac;
  final dy = size.height * insetFrac;
  canvas.save();
  canvas.translate(dx, dy);
  _paintMarks(
      canvas, Size(size.width - dx * 2, size.height - dy * 2), rank, color);
  canvas.restore();
}

/// The flat brass "issued mount" behind an Airborne rank: a brass-tinted plate,
/// a brass hairline frame, and four corner rivets. Flat and tonal by doctrine
/// (Quiet Chrome) — no glow, no bevel — it reads as the rank struck onto issued
/// brass hardware and survives down to the rank-strip size.
void _paintAirborneMount(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final short = math.min(w, h);
  final inset = short * 0.04;
  final rect =
      Rect.fromLTWH(inset, inset, w - inset * 2, h - inset * 2);
  // Sharp regulation radius (near the system 4/8/12 scale), not a soft
  // consumer-badge roundness.
  final rrect = RRect.fromRectAndRadius(rect, Radius.circular(short * 0.10));
  // Brass-tinted backing plate — flat, low alpha so the tier colour stays legible.
  canvas.drawRRect(rrect, Paint()..color = _brass.withValues(alpha: 0.15));
  // Brass hairline frame.
  canvas.drawRRect(
      rrect,
      Paint()
        ..color = _brass
        ..style = PaintingStyle.stroke
        ..strokeWidth = (short * 0.042).clamp(1.0, short));
  // Corner rivets — the mounted-issue tell. Dropped below ~30px, where they'd
  // shrink to noise; the frame + plate carry the signal at rank-strip size.
  if (short >= 30) {
    final rr = short * 0.05;
    final ci = short * 0.19;
    final rivet = Paint()..color = _brass;
    for (final c in [
      Offset(ci, ci),
      Offset(w - ci, ci),
      Offset(ci, h - ci),
      Offset(w - ci, h - ci),
    ]) {
      canvas.drawCircle(c, rr, rivet);
    }
  }
}

void _paintMarks(
  Canvas canvas,
  Size size,
  MilitaryRank rank,
  Color color,
) {
  final cfg = _insigniaFor(rank);
  final w = size.width;
  final h = size.height;
  final cx = w / 2;

  final stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = (h * 0.082).clamp(1.3, h);
  final fill = Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  // Private — a single quiet field-stripe. The blank sleeve reads as "recruit"
  // without impersonating a chevron.
  if (cfg.baseMark) {
    final bar = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (h * 0.09).clamp(1.4, h);
    canvas.drawLine(
        Offset(cx - w * 0.22, h / 2), Offset(cx + w * 0.22, h / 2), bar);
    return;
  }

  // Specialist — the eagle "speck" device, no chevrons.
  if (cfg.specialist) {
    _drawSpecialist(canvas, stroke, fill, cx, h / 2, w, h);
    return;
  }

  final halfW = w * 0.42;
  final arm = h * 0.15;
  final step = h * 0.10;
  final hasCenter = cfg.centerStar || cfg.flankingStars;
  final voidHalf = (cfg.rockers > 0 || hasCenter) ? h * 0.085 : 0.0;

  // Positions relative to a provisional centre (0); the whole group is centred
  // in the box afterward so ranks with fewer rows don't float to one edge.
  final chevPeaks = <double>[
    for (var i = 0; i < cfg.chevrons; i++) -voidHalf - arm - i * step,
  ];
  final rockerEnds = <double>[
    for (var j = 0; j < cfg.rockers; j++) voidHalf + j * step,
  ];

  double minY = 0, maxY = 0;
  if (chevPeaks.isNotEmpty) minY = chevPeaks.last;
  if (rockerEnds.isNotEmpty) {
    maxY = rockerEnds.last + arm;
  } else if (chevPeaks.isNotEmpty) {
    maxY = chevPeaks.first + arm;
  }
  if (chevPeaks.isEmpty && rockerEnds.isEmpty) {
    minY = -voidHalf;
    maxY = voidHalf;
  }
  final cy = h / 2 - (minY + maxY) / 2;

  for (final e in rockerEnds) {
    _rocker(canvas, stroke, cx, cy + e, halfW, arm);
  }
  for (final pk in chevPeaks) {
    _chevron(canvas, stroke, cx, cy + pk, halfW, arm);
  }

  if (cfg.flankingStars) {
    _drawStar(canvas, fill, Offset(cx, cy), h * 0.088);
    _drawStar(canvas, fill, Offset(cx - halfW * 0.62, cy), h * 0.06);
    _drawStar(canvas, fill, Offset(cx + halfW * 0.62, cy), h * 0.06);
  } else if (cfg.centerStar) {
    _drawStar(canvas, fill, Offset(cx, cy), h * 0.092);
  }
}

/// A chevron pointing up: peak at (cx, peakY), arms dropping to ±[halfW].
void _chevron(
    Canvas canvas, Paint p, double cx, double peakY, double halfW, double arm) {
  final path = Path()
    ..moveTo(cx - halfW, peakY + arm)
    ..lineTo(cx, peakY)
    ..lineTo(cx + halfW, peakY + arm);
  canvas.drawPath(path, p);
}

/// A rocker: a shallow arc whose ends sit at [endY] and whose middle bulges
/// down — the mirror of a chevron, nested below the chevron stack.
void _rocker(
    Canvas canvas, Paint p, double cx, double endY, double halfW, double arm) {
  final path = Path()
    ..moveTo(cx - halfW, endY)
    ..quadraticBezierTo(cx, endY + arm * 1.7, cx + halfW, endY);
  canvas.drawPath(path, p);
}

/// The Specialist eagle-device: a shield with a concave, flared top and a
/// rounded base, a small spread-wing eagle set inside it.
void _drawSpecialist(Canvas canvas, Paint stroke, Paint fill, double cx,
    double cy, double w, double h) {
  final sw = w * 0.30;
  final st = cy - h * 0.30;
  final sb = cy + h * 0.32;
  final shield = Path()
    ..moveTo(cx - sw, st + h * 0.05)
    ..quadraticBezierTo(cx - sw, st, cx - sw * 0.46, st + h * 0.01)
    ..quadraticBezierTo(cx, st + h * 0.11, cx + sw * 0.46, st + h * 0.01)
    ..quadraticBezierTo(cx + sw, st, cx + sw, st + h * 0.05)
    ..lineTo(cx + sw * 0.86, sb - h * 0.12)
    ..quadraticBezierTo(cx, sb, cx - sw * 0.86, sb - h * 0.12)
    ..close();
  canvas.drawPath(shield, stroke);
  _drawEagle(canvas, fill, Offset(cx, cy - h * 0.01), w * 0.34);
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
      c.dx - hw * 0.4,
      c.dy - width * 0.20,
      c.dx,
      c.dy + width * 0.04,
    )
    ..quadraticBezierTo(c.dx + hw * 0.4, c.dy - width * 0.20, c.dx + hw, c.dy)
    ..quadraticBezierTo(
      c.dx + hw * 0.4,
      c.dy + width * 0.12,
      c.dx,
      c.dy + width * 0.20,
    )
    ..quadraticBezierTo(c.dx - hw * 0.4, c.dy + width * 0.12, c.dx - hw, c.dy)
    ..close();
  canvas.drawPath(wings, paint);
  // Head.
  canvas.drawCircle(Offset(c.dx, c.dy - width * 0.06), width * 0.08, paint);
}

class _RankInsigniaPainter extends CustomPainter {
  _RankInsigniaPainter({
    required this.rank,
    required this.color,
    this.airborne = false,
  });

  final MilitaryRank rank;
  final Color color;
  final bool airborne;

  @override
  void paint(Canvas canvas, Size size) =>
      paintRankInsignia(canvas, size, rank, color, airborne: airborne);

  @override
  bool shouldRepaint(_RankInsigniaPainter old) =>
      old.rank != rank || old.color != color || old.airborne != airborne;
}
