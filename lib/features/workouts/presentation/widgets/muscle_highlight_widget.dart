import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/muscle_map.dart';

/// Apple-Fitness-inspired muscle highlight. Renders a minimal body
/// silhouette behind a set of glowing ovals — primary muscles at full
/// accent strength, secondary muscles dimmed and softer.
///
/// Sizing:
///   * Compact (default `height: 160`): single front-or-back silhouette.
///   * Full (`height: 360+`): front + back side by side when the muscles
///     span both. The widget auto-picks which sides to render based on
///     whether any of the supplied muscles map there.
class MuscleHighlightWidget extends StatelessWidget {
  const MuscleHighlightWidget({
    super.key,
    required this.targetMuscles,
    this.secondaryMuscles = const [],
    this.height = 160,
    this.maxWidth = 220,
  });

  final List<String> targetMuscles;
  final List<String> secondaryMuscles;
  final double height;

  /// Caps the combined width when both panels are visible so the widget
  /// doesn't stretch to fill an entire scroll view.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final brightness = MediaQuery.platformBrightnessOf(context);
    final silhouetteColor = brightness == Brightness.dark
        ? const Color(0xFFBFBFBF) // light grey on dark
        : const Color(0xFF333333); // dark grey on light

    final all = [...targetMuscles, ...secondaryMuscles];
    final showFront = MuscleMap.hasMusclesOnSide(all, BodySide.front);
    final showBack = MuscleMap.hasMusclesOnSide(all, BodySide.back);
    // Always show at least one side so the widget never collapses.
    final useFrontOnly = showFront && !showBack;
    final useBothSides = showFront && showBack;
    final useBackOnly = !showFront && showBack;
    final fallbackToFront = !showFront && !showBack;

    final panels = <Widget>[];
    if (useFrontOnly || useBothSides || fallbackToFront) {
      panels.add(_panel(
        side: BodySide.front,
        accent: palette.accent,
        silhouette: silhouetteColor,
      ));
    }
    if (useBackOnly || useBothSides) {
      panels.add(_panel(
        side: BodySide.back,
        accent: palette.accent,
        silhouette: silhouetteColor,
      ));
    }

    return SizedBox(
      height: height,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < panels.length; i++) ...[
              Expanded(child: panels[i]),
              if (i < panels.length - 1) const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _panel({
    required BodySide side,
    required Color accent,
    required Color silhouette,
  }) {
    return CustomPaint(
      painter: _BodyPainter(
        side: side,
        targetMuscles: targetMuscles,
        secondaryMuscles: secondaryMuscles,
        accent: accent,
        silhouette: silhouette,
      ),
      size: Size.infinite,
    );
  }

  /// Reused by callers that want to render a legend swatch matching the
  /// actual highlight intensity used inside the widget.
  static Color targetColor(Color accent) =>
      accent.withValues(alpha: 0.85);
  static Color secondaryColor(Color accent) =>
      accent.withValues(alpha: 0.35);
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.side,
    required this.targetMuscles,
    required this.secondaryMuscles,
    required this.accent,
    required this.silhouette,
  });

  final BodySide side;
  final List<String> targetMuscles;
  final List<String> secondaryMuscles;
  final Color accent;
  final Color silhouette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Backdrop silhouette first — glows blend on top.
    _drawSilhouette(canvas, w, h);

    // Secondary muscles first (drawn UNDER primary so a "both" highlight
    // reads as primary).
    final secondary = _resolveZones(secondaryMuscles);
    for (final z in secondary) {
      _drawGlow(canvas, w, h, z,
          color: accent.withValues(alpha: 0.35),
          blurRadius: 10,
          stretchFactor: 0.85);
    }

    final primary = _resolveZones(targetMuscles);
    for (final z in primary) {
      _drawGlow(canvas, w, h, z,
          color: accent.withValues(alpha: 0.80),
          blurRadius: 14,
          stretchFactor: 1.0);
    }
  }

  /// Looks up zones for the current [side] only. Returns each zone twice
  /// when [MuscleZone.mirrored] so paired muscles render on both arms/legs.
  List<MuscleZone> _resolveZones(List<String> names) {
    final out = <MuscleZone>[];
    final source = side == BodySide.front
        ? MuscleMap.frontZones
        : MuscleMap.backZones;
    for (final raw in names) {
      final key = MuscleMap.normalize(raw);
      final z = source[key];
      if (z == null) continue;
      out.add(z);
      if (z.mirrored) {
        out.add(MuscleZone(1.0 - z.cx, z.cy, z.rx, z.ry));
      }
    }
    return out;
  }

  void _drawGlow(
    Canvas canvas,
    double w,
    double h,
    MuscleZone z, {
    required Color color,
    required double blurRadius,
    required double stretchFactor,
  }) {
    final rect = Rect.fromCenter(
      center: Offset(z.cx * w, z.cy * h),
      width: z.rx * 2 * w * stretchFactor,
      height: z.ry * 2 * h * stretchFactor,
    );
    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);
    canvas.drawOval(rect, paint);
    // Crisper core on top of the glow so the highlight has a recognisable
    // shape rather than just being a fuzzy cloud.
    final core = Paint()
      ..color = color.withValues(alpha: (color.a * 0.6).clamp(0.0, 1.0));
    final coreRect = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.65,
      height: rect.height * 0.65,
    );
    canvas.drawOval(coreRect, core);
  }

  // ───────────────────────────────────────────────────────────────────
  // Silhouette — same outline for front and back. Apple Fitness style:
  // a single soft path, no internal muscle delineation. Coordinates are
  // expressed relative to the widget bounds via `w` and `h`.
  // ───────────────────────────────────────────────────────────────────
  void _drawSilhouette(Canvas canvas, double w, double h) {
    final fill = Paint()
      ..color = silhouette.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = silhouette.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;

    final path = _bodyPath(w, h);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  /// Builds a soft, generic body silhouette. Reused for front and back —
  /// they're indistinguishable from a single outline view.
  Path _bodyPath(double w, double h) {
    // Anchor coords as fractions (0..1) of the canvas — same convention as
    // MuscleZone — then multiply.
    Offset p(double x, double y) => Offset(x * w, y * h);

    final path = Path();

    // Head (circle approximated as oval, slightly taller than wide).
    final headTop = 0.04;
    final headBottom = 0.13;
    final headLeft = 0.42;
    final headRight = 0.58;
    path.addOval(Rect.fromLTRB(
      headLeft * w,
      headTop * h,
      headRight * w,
      headBottom * h,
    ));

    // Neck → torso → arms → legs as one continuous outline. Built by
    // walking down the LEFT side first then back UP the right side.
    path.moveTo(p(0.46, headBottom + 0.01).dx, p(0.46, headBottom + 0.01).dy);
    // Left trapezius/shoulder
    path.quadraticBezierTo(
      p(0.34, 0.16).dx, p(0.34, 0.16).dy,
      p(0.20, 0.20).dx, p(0.20, 0.20).dy,
    );
    // Left arm — outer edge
    path.quadraticBezierTo(
      p(0.12, 0.30).dx, p(0.12, 0.30).dy,
      p(0.10, 0.45).dx, p(0.10, 0.45).dy,
    );
    // Wrist
    path.quadraticBezierTo(
      p(0.09, 0.48).dx, p(0.09, 0.48).dy,
      p(0.13, 0.50).dx, p(0.13, 0.50).dy,
    );
    // Inner arm back up to torso waist
    path.quadraticBezierTo(
      p(0.20, 0.40).dx, p(0.20, 0.40).dy,
      p(0.28, 0.30).dx, p(0.28, 0.30).dy,
    );
    // Down the left side of the torso to the waist
    path.quadraticBezierTo(
      p(0.30, 0.40).dx, p(0.30, 0.40).dy,
      p(0.32, 0.50).dx, p(0.32, 0.50).dy,
    );
    // Outer thigh
    path.quadraticBezierTo(
      p(0.30, 0.62).dx, p(0.30, 0.62).dy,
      p(0.34, 0.78).dx, p(0.34, 0.78).dy,
    );
    // Outer calf
    path.quadraticBezierTo(
      p(0.34, 0.86).dx, p(0.34, 0.86).dy,
      p(0.36, 0.95).dx, p(0.36, 0.95).dy,
    );
    // Foot
    path.lineTo(p(0.46, 0.96).dx, p(0.46, 0.96).dy);
    // Up inner left leg
    path.quadraticBezierTo(
      p(0.46, 0.78).dx, p(0.46, 0.78).dy,
      p(0.48, 0.58).dx, p(0.48, 0.58).dy,
    );
    // Crotch
    path.lineTo(p(0.52, 0.58).dx, p(0.52, 0.58).dy);
    // Down inner right leg
    path.quadraticBezierTo(
      p(0.54, 0.78).dx, p(0.54, 0.78).dy,
      p(0.54, 0.96).dx, p(0.54, 0.96).dy,
    );
    path.lineTo(p(0.64, 0.95).dx, p(0.64, 0.95).dy);
    // Outer right calf + thigh
    path.quadraticBezierTo(
      p(0.66, 0.86).dx, p(0.66, 0.86).dy,
      p(0.66, 0.78).dx, p(0.66, 0.78).dy,
    );
    path.quadraticBezierTo(
      p(0.70, 0.62).dx, p(0.70, 0.62).dy,
      p(0.68, 0.50).dx, p(0.68, 0.50).dy,
    );
    // Right side of torso up to underarm
    path.quadraticBezierTo(
      p(0.70, 0.40).dx, p(0.70, 0.40).dy,
      p(0.72, 0.30).dx, p(0.72, 0.30).dy,
    );
    // Right inner arm back down to wrist
    path.quadraticBezierTo(
      p(0.80, 0.40).dx, p(0.80, 0.40).dy,
      p(0.87, 0.50).dx, p(0.87, 0.50).dy,
    );
    path.quadraticBezierTo(
      p(0.91, 0.48).dx, p(0.91, 0.48).dy,
      p(0.90, 0.45).dx, p(0.90, 0.45).dy,
    );
    // Up outer right arm to shoulder
    path.quadraticBezierTo(
      p(0.88, 0.30).dx, p(0.88, 0.30).dy,
      p(0.80, 0.20).dx, p(0.80, 0.20).dy,
    );
    // Right trapezius back to neck
    path.quadraticBezierTo(
      p(0.66, 0.16).dx, p(0.66, 0.16).dy,
      p(0.54, headBottom + 0.01).dx, p(0.54, headBottom + 0.01).dy,
    );
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) {
    return old.side != side ||
        old.accent != accent ||
        old.silhouette != silhouette ||
        !_listEq(old.targetMuscles, targetMuscles) ||
        !_listEq(old.secondaryMuscles, secondaryMuscles);
  }

  static bool _listEq(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
