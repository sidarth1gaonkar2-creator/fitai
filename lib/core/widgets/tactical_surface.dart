import 'package:flutter/widgets.dart';

import '../theme/field_manual.dart';
import '../theme/surface_texture.dart';

/// Fills its area with the active skin's screen background. For accent-swap
/// themes that's a solid [FieldManual.ink] — byte-identical to the old
/// `Scaffold(backgroundColor: FieldManual.ink)`. For a full skin (Night Ops)
/// it paints the mottled dark [SurfaceTexture] instead: the tactical grain
/// that makes the skin read as a distinct material.
///
/// Wrap a screen's body in it (with a transparent Scaffold) to texture the
/// background. Dense-data cards sit on top on their own near-solid fills, so
/// texture never lands directly under numbers (gate c).
class SkinBackground extends StatelessWidget {
  const SkinBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final skin = FieldManual.skin;
    final texture = skin.surfaceTexture;
    if (texture == null) {
      return ColoredBox(color: FieldManual.ink, child: child);
    }
    return CustomPaint(
      painter: SurfaceTexturePainter(
        texture,
        // A skin may band a second material across the top of the ground.
        // Null/0 on every skin but Dress Blues, so the others are unchanged.
        header: skin.headerTexture,
        headerHeight: skin.headerBandHeight,
      ),
      child: child,
    );
  }
}

/// Wraps card content in the skin's card treatment. For a HUD skin
/// (`cardBrackets`) it overlays a hairline frame with corner brackets — the
/// viewport-readout look. Otherwise it's a pass-through, so non-HUD themes are
/// unchanged.
class HudFrame extends StatelessWidget {
  const HudFrame({
    super.key,
    required this.child,
    required this.color,
    this.radius,
  });

  final Widget child;

  /// Frame/bracket colour — pass the card border tone (bone-alpha), not the
  /// accent, so the frame stays structure and the One Voice rule holds.
  final Color color;

  /// Corner radius; defaults to the skin's card radius.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    if (!FieldManual.skin.cardBrackets) return child;
    return CustomPaint(
      foregroundPainter: _HudFramePainter(
        color: color,
        radius: radius ?? FieldManual.cardRadius,
      ),
      child: child,
    );
  }
}

class _HudFramePainter extends CustomPainter {
  const _HudFramePainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.5), Radius.circular(radius)),
      stroke,
    );

    // Corner brackets: short, slightly heavier L-ticks a hair inside each
    // corner — a viewport readout frame. Brighter than the hairline so they
    // register, still neutral (never the accent).
    final tick = (size.shortestSide * 0.06).clamp(8.0, 16.0);
    const inset = 3.0;
    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.square
      ..color = color.withValues(alpha: 1);
    final w = size.width, h = size.height;
    void corner(double x, double y, double sx, double sy) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y + sy * tick)
          ..lineTo(x, y)
          ..lineTo(x + sx * tick, y),
        bracket,
      );
    }

    corner(inset, inset, 1, 1); // top-left
    corner(w - inset, inset, -1, 1); // top-right
    corner(inset, h - inset, 1, -1); // bottom-left
    corner(w - inset, h - inset, -1, -1); // bottom-right
  }

  @override
  bool shouldRepaint(_HudFramePainter old) =>
      old.color != color || old.radius != radius;
}

/// The accent halo for a HUD skin — a controlled same-hue bloom to hang under
/// accent fills / active states on true black (the reticle glow). Empty (no
/// glow) unless the skin opts in, so every other theme is untouched.
///
/// A single `BoxShadow` with a small spread and a defined edge — a crisp halo,
/// not a blurry smear. **Cost/limit (perf gate):** it's opt-in per element and
/// only ever attached to primary/active/selected accent elements (buttons, the
/// score, the tab indicator) — never to list rows — so it never multiplies
/// across a scrolling list. Flutter rasterises `BoxShadow` on the GPU; a
/// handful of static glowing elements per screen is negligible and constant.
List<BoxShadow> skinAccentGlow(Color accent, {double blur = 11, double alpha = 0.6}) {
  if (!FieldManual.skin.accentGlow) return const [];
  return [
    BoxShadow(color: accent.withValues(alpha: alpha), blurRadius: blur, spreadRadius: 1),
  ];
}

/// The text/icon variant of [skinAccentGlow] — a same-hue glyph glow for accent
/// TEXT and ICONS (the score number, the active tab indicator, selected labels)
/// via the `shadows` slot on [TextStyle] / [Icon]. Empty unless the skin opts
/// in. Same limit: attach to single accent glyphs, never to list rows.
List<Shadow> skinAccentTextShadows(Color accent, {double blur = 8, double alpha = 0.7}) {
  if (!FieldManual.skin.accentGlow) return const [];
  return [Shadow(color: accent.withValues(alpha: alpha), blurRadius: blur)];
}
