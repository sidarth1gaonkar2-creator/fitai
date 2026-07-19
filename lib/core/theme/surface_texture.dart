import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

final Float64List _identity4 = Float64List.fromList(
  <double>[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
);

/// A tactical *surface texture* a full skin may paint behind large/background
/// surfaces — the mottled dark camo/NVG grain that makes a skin read as a
/// distinct material, not a recolour. Null on every accent-swap theme, so they
/// stay solid-fill and byte-identical.
///
/// Perf (hard gate b): the camo is generated ONCE into a seamless tile
/// `ui.Image` via [ui.Picture.toImageSync] and cached by [id]. Painting is then
/// a single tiled `ImageShader` draw with `shouldRepaint == false` — no
/// per-frame path work, nothing to drop frames on scroll.
///
/// Accessibility (hard gate a): every tone is near-black and capped by the
/// author; text over the *lightest* tone must still clear WCAG AA. Night Ops
/// caps at #1C1C1C → bone 13.6:1, amber 9.4:1. Texture is for background/header
/// surfaces only — never painted directly under dense numbers (gate c).
class SurfaceTexture {
  const SurfaceTexture({
    required this.id,
    required this.base,
    required this.tones,
    this.blobsPerTone = 46,
    this.tileSize = 480,
    this.seed = 7,
    this.smooth = false,
    this.minRadiusFactor = 0.045,
    this.maxRadiusFactor = 0.13,
  });

  /// Cache key — must be unique per distinct look.
  final String id;

  /// The base tone: fills the tile before the camo lobes. Usually the darkest,
  /// but a skin may paint darker lobes over a mid base — Woodland lays its
  /// near-black M81 overlay last, the way real four-colour woodland prints do.
  final Color base;

  /// Camo tones painted as organic lobes over [base], in paint order (later
  /// tones sit on top). Keep the *lightest* dark enough that secondary text
  /// still holds AA over it — see [lightestTone].
  final List<Color> tones;

  final int blobsPerTone;
  final int tileSize;
  final int seed;

  /// Round the lobes instead of drawing straight-edged polygons. Night Ops's
  /// fine tactical grain wants the hard polygon edge (the default, so its tile
  /// is unchanged); Woodland's large M81 shapes want the soft organic edge of
  /// printed fabric.
  final bool smooth;

  /// Lobe radius as a fraction of [tileSize]. The defaults are Night Ops's
  /// fine grain; a skin with large shapes (Woodland) raises both.
  final double minRadiusFactor;
  final double maxRadiusFactor;

  /// The lightest tone any text could sit on — callers use this to prove the
  /// AA gate against the real worst case.
  ///
  /// Measured by luminance across [base] *and* [tones] rather than assuming
  /// the last entry is lightest: a skin whose final lobe is its darkest (an
  /// M81 black overlay) would otherwise report a false worst case and let a
  /// failing tone through the gate.
  Color get lightestTone {
    var worst = base;
    var worstLum = base.computeLuminance();
    for (final tone in tones) {
      final l = tone.computeLuminance();
      if (l > worstLum) {
        worst = tone;
        worstLum = l;
      }
    }
    return worst;
  }

  static final Map<String, ui.Image> _cache = {};

  /// The cached seamless camo tile. Generated once (synchronously, so the
  /// first paint and headless render harness both get pixels), then reused.
  ui.Image tile() => _cache.putIfAbsent(id, _buildTile);

  ui.Image _buildTile() {
    final t = tileSize.toDouble();
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec, Rect.fromLTWH(0, 0, t, t));
    canvas.drawRect(Rect.fromLTWH(0, 0, t, t), Paint()..color = base);
    // Deterministic PRNG so the tile is identical every run (stable goldens).
    final rnd = math.Random(seed);
    for (final tone in tones) {
      final paint = Paint()
        ..color = tone
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      for (var i = 0; i < blobsPerTone; i++) {
        final cx = rnd.nextDouble() * t;
        final cy = rnd.nextDouble() * t;
        final path =
            _blob(rnd, cx, cy, t * minRadiusFactor, t * maxRadiusFactor);
        // Draw the lobe plus its eight wrapped copies so the tile is seamless.
        for (var dx = -1; dx <= 1; dx++) {
          for (var dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) {
              canvas.drawPath(path, paint);
            } else {
              canvas.save();
              canvas.translate(dx * t, dy * t);
              canvas.drawPath(path, paint);
              canvas.restore();
            }
          }
        }
      }
    }
    return rec.endRecording().toImageSync(tileSize, tileSize);
  }

  /// One irregular, camo-like lobe: a closed loop whose vertices ride a
  /// jittered radius so it reads organic rather than geometric.
  ///
  /// [smooth] picks the edge treatment. The straight-edge branch is the
  /// original and stays bit-for-bit identical (same PRNG draw order, same
  /// vertices) so Night Ops's cached tile is unchanged. The smooth branch
  /// reuses those same vertices as Bézier control points, rounding the lobe
  /// into the soft printed-fabric shape M81 woodland actually has.
  Path _blob(math.Random rnd, double cx, double cy, double minR, double maxR) {
    final verts = 7 + rnd.nextInt(5);
    final baseR = minR + rnd.nextDouble() * (maxR - minR);
    final pts = <Offset>[];
    for (var i = 0; i <= verts; i++) {
      final a = (i / verts) * 2 * math.pi;
      final r = baseR * (0.5 + rnd.nextDouble() * 0.95);
      pts.add(Offset(cx + math.cos(a) * r, cy + math.sin(a) * r));
    }

    final path = Path();
    if (!smooth) {
      for (var i = 0; i < pts.length; i++) {
        if (i == 0) {
          path.moveTo(pts[i].dx, pts[i].dy);
        } else {
          path.lineTo(pts[i].dx, pts[i].dy);
        }
      }
      path.close();
      return path;
    }

    // Quadratic through edge midpoints: each vertex becomes a control point,
    // so corners round off and the outline reads as a soft blotch.
    final n = verts; // pts[verts] duplicates pts[0]'s angle — use the first n
    Offset mid(int i) => Offset(
          (pts[i % n].dx + pts[(i + 1) % n].dx) / 2,
          (pts[i % n].dy + pts[(i + 1) % n].dy) / 2,
        );
    final start = mid(0);
    path.moveTo(start.dx, start.dy);
    for (var i = 1; i <= n; i++) {
      final ctrl = pts[i % n];
      final end = mid(i);
      path.quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
    }
    path.close();
    return path;
  }
}

/// Paints a [SurfaceTexture] filling the canvas: the base colour, then the
/// cached camo tile tiled with an [ui.ImageShader]. Static — repaints only
/// when the texture identity changes.
class SurfaceTexturePainter extends CustomPainter {
  const SurfaceTexturePainter(this.texture);

  final SurfaceTexture texture;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = texture.base);
    final shader = ui.ImageShader(
      texture.tile(),
      TileMode.repeated,
      TileMode.repeated,
      _identity4,
    );
    canvas.drawRect(rect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(SurfaceTexturePainter oldDelegate) =>
      oldDelegate.texture.id != texture.id;
}
