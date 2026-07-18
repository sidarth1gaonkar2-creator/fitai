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
  });

  /// Cache key — must be unique per distinct look.
  final String id;

  /// The darkest tone: fills the tile before the camo lobes.
  final Color base;

  /// Lighter camo tones, painted as organic lobes over [base]. Keep the
  /// lightest ≤ ~#1C1C1C so text over it holds AA.
  final List<Color> tones;

  final int blobsPerTone;
  final int tileSize;
  final int seed;

  /// The lightest tone any text could sit on — callers use this to prove the
  /// AA gate against the real worst case, not the base.
  Color get lightestTone => tones.isEmpty ? base : tones.last;

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
        final path = _blob(rnd, cx, cy, t * 0.045, t * 0.13);
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

  /// One irregular, camo-like lobe: a closed polygon whose vertices ride a
  /// jittered radius so it reads organic rather than geometric.
  Path _blob(math.Random rnd, double cx, double cy, double minR, double maxR) {
    final verts = 7 + rnd.nextInt(5);
    final baseR = minR + rnd.nextDouble() * (maxR - minR);
    final path = Path();
    for (var i = 0; i <= verts; i++) {
      final a = (i / verts) * 2 * math.pi;
      final r = baseR * (0.5 + rnd.nextDouble() * 0.95);
      final x = cx + math.cos(a) * r;
      final y = cy + math.sin(a) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
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
