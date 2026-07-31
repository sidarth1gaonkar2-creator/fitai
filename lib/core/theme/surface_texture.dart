import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
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
/// Exists only so tile completion can be broadcast: `notifyListeners` is
/// protected, callable only from inside a [ChangeNotifier] subclass.
class _TileReadyNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// How a [SurfaceTexture] lays its tones down.
///
/// [camoLobes] is the original and the default, so Night Ops and Woodland are
/// untouched. The two directional patterns exist for Dress Blues, whose
/// references are woven cloth and brushed hardware — neither of which can be
/// expressed as blobs at any parameter setting.
enum SurfaceTexturePattern {
  /// Organic blotches — field camo. Night Ops (fine, hard-edged grain) and
  /// Woodland (large, soft-edged M81 shapes).
  camoLobes,

  /// Fine diagonal ribs — the weave of wool serge. Depth without pattern:
  /// at arm's length it reads as a richer surface, not as stripes.
  twillWeave,

  /// Fine horizontal streaks — anisotropic polished metal. Reserved for
  /// header bands, where it reads as the brass-and-braid hardware register.
  brushedMetal,
}

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
    this.pattern = SurfaceTexturePattern.camoLobes,
    this.ribPitch = 5,
    this.ribWidthFactor = 0.55,
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

  /// How the tones are laid down. Defaults to [SurfaceTexturePattern.camoLobes],
  /// the original path, so existing skins generate an identical tile.
  final SurfaceTexturePattern pattern;

  /// Spacing in logical pixels between ribs/streaks for the directional
  /// patterns. [tileSize] must be a whole multiple of it or the pattern seams
  /// at the tile edge — asserted in the harness.
  final int ribPitch;

  /// Rib stroke width as a fraction of [ribPitch], for
  /// [SurfaceTexturePattern.twillWeave] only. Brushed metal keeps its own
  /// hardcoded 0.6 so the Dress Blues header band is untouched by this.
  ///
  /// Ribs run at 45°, so the perpendicular gap between neighbours is
  /// `ribPitch / sqrt(2)` — a factor of ~0.707 is the point at which ribs meet
  /// edge to edge. Below it the [base] shows through between ribs and dilutes
  /// the weave; at or above it the surface is rib-to-rib and the pattern is
  /// carried entirely by tone contrast between neighbours, which is what makes
  /// a weave legible rather than a flat field.
  final double ribWidthFactor;

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

  /// Completed tiles only — an entry here has finished rasterizing.
  static final Map<String, ui.Image> _cache = {};

  /// Rasterizations already under way, so concurrent painters of the same
  /// skin don't each start their own.
  static final Map<String, Future<ui.Image>> _inFlight = {};

  /// Fires whenever a tile finishes rasterizing. [SurfaceTexturePainter]
  /// listens, so a surface that painted base-only repaints with its material
  /// the moment the tile lands.
  static final _TileReadyNotifier _tilesReady = _TileReadyNotifier();
  static Listenable get tilesReady => _tilesReady;

  /// Test-only: whether [id]'s tile has already been rasterized and cached.
  @visibleForTesting
  static bool debugIsCached(String id) => _cache.containsKey(id);

  /// Test-only: forget every cached tile, so a test can observe a cold start.
  @visibleForTesting
  static void debugClearCache() {
    _cache.clear();
    _inFlight.clear();
  }

  /// The tile if it is ready, otherwise null — and, if nothing is under way
  /// yet, kicks off rasterization.
  ///
  /// **Never rasterizes inline.** `Picture.toImageSync` returns a handle that
  /// is still rasterizing whenever a GPU context exists, so sampling it in the
  /// same paint pass yields an empty texture — which is exactly how the three
  /// full skins came to render as flat colour on device while looking correct
  /// in the headless harness (no GPU context there, so the engine falls back
  /// to a synchronous CPU raster). Painting must therefore tolerate a null.
  ui.Image? tileOrNull() {
    final ready = _cache[id];
    if (ready != null) return ready;
    ensureTile();
    return null;
  }

  /// Rasterize the tile if needed and complete when it is genuinely ready.
  /// `toImage` (async) is the GPU-safe counterpart to `toImageSync`: its future
  /// completes only once rasterization has actually finished.
  Future<ui.Image> ensureTile() {
    final ready = _cache[id];
    if (ready != null) return Future<ui.Image>.value(ready);
    return _inFlight.putIfAbsent(id, () async {
      final image = await _recordTile().toImage(tileSize, tileSize);
      _cache[id] = image;
      _inFlight.remove(id);
      _tilesReady.notify();
      return image;
    });
  }

  ui.Picture _recordTile() {
    final t = tileSize.toDouble();
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec, Rect.fromLTWH(0, 0, t, t));
    canvas.drawRect(Rect.fromLTWH(0, 0, t, t), Paint()..color = base);
    // Deterministic PRNG so the tile is identical every run (stable goldens).
    final rnd = math.Random(seed);
    switch (pattern) {
      case SurfaceTexturePattern.camoLobes:
        _paintCamo(canvas, t, rnd);
      case SurfaceTexturePattern.twillWeave:
        _paintTwill(canvas, t, rnd);
      case SurfaceTexturePattern.brushedMetal:
        _paintBrushedMetal(canvas, t, rnd);
    }
    return rec.endRecording();
  }

  /// Diagonal ribs at 45°. The family `x + y = k·pitch` is periodic in both
  /// axes with period [ribPitch], so the tile wraps seamlessly whenever
  /// `tileSize % ribPitch == 0`.
  ///
  /// Two things make the weave legible rather than a flat field, and both are
  /// deliberate:
  ///
  /// **Adjacent ribs always differ.** Ribs alternate between a darker and a
  /// lighter bank of [tones] (first half / second half). Picking each rib's
  /// tone at random — the original behaviour — left neighbouring ribs the same
  /// colour about half the time with a two-tone list, which erases the very
  /// boundary the eye resolves as cloth. Which member of a bank a rib takes is
  /// still seeded-random, so the weave keeps a slight irregularity instead of
  /// reading as a mechanical stripe.
  ///
  /// **Rib colour is periodic over the tile.** The rib leaving the right edge
  /// and the one entering the next tile's left edge are the SAME rib on
  /// screen, so they must be the same colour. Drawing a fresh random tone per
  /// rib broke that — the tile did not actually wrap in tone. It went unnoticed
  /// only because the shipped tones sat within ~4 RGB levels of each other; the
  /// moment the palette spreads far enough to see, the seam would have become
  /// a visible break in the diagonal every [tileSize] pixels.
  void _paintTwill(Canvas canvas, double t, math.Random rnd) {
    if (tones.isEmpty) return;
    final pitch = ribPitch.toDouble();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = pitch * ribWidthFactor
      ..isAntiAlias = true;

    final ribsPerTile = (t / pitch).round();
    final half = tones.length ~/ 2;
    final ribColors = List<Color>.generate(ribsPerTile, (i) {
      if (tones.length < 2) return tones.first;
      final lightBank = i.isOdd;
      final lo = lightBank ? half : 0;
      final hi = lightBank ? tones.length : half;
      return tones[lo + rnd.nextInt(hi - lo)];
    });

    // Sweep k across two tile widths so ribs entering from the left edge are
    // drawn as well as those leaving the right. Index the colour wrapped, so
    // rib k and rib k+t — the same rib once tiled — resolve identically.
    var i = 0;
    for (var k = -t; k <= t * 2; k += pitch, i++) {
      paint.color = ribColors[i % ribsPerTile];
      canvas.drawLine(Offset(k, 0), Offset(k - t, t), paint);
    }
  }

  /// Fine horizontal grain — anisotropic, like a brushed finish. Each row is
  /// ONE full-width stroke in a single tone; the variation is row-to-row, not
  /// along the row.
  ///
  /// An earlier version broke each row into random-length segments with a
  /// different tone per segment. That reads as scan-line corruption, not
  /// polished metal: real brushing varies across the grain, not along it.
  /// Full-width strokes also wrap horizontally for free.
  void _paintBrushedMetal(Canvas canvas, double t, math.Random rnd) {
    if (tones.isEmpty) return;
    final pitch = ribPitch.toDouble();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = pitch * 0.6
      ..isAntiAlias = true;
    for (var y = 0.0; y <= t; y += pitch) {
      paint.color = tones[rnd.nextInt(tones.length)];
      canvas.drawLine(Offset(0, y), Offset(t, y), paint);
    }
  }

  void _paintCamo(Canvas canvas, double t, math.Random rnd) {
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
///
/// A skin may supply a second [header] texture, painted as a band across the
/// top and faded out over its lower third so it melts into the ground rather
/// than ending on a hard line. Dress Blues uses this to lay brushed-metal
/// hardware over its twill ground. Null on every other skin, which therefore
/// paints exactly as before.
class SurfaceTexturePainter extends CustomPainter {
  /// Repaints on [SurfaceTexture.tilesReady], so a surface that painted
  /// base-only picks up its material as soon as the tile finishes. That is
  /// the correct channel for this — [shouldRepaint] compares configuration,
  /// which hasn't changed when a tile lands.
  SurfaceTexturePainter(
    this.texture, {
    this.header,
    this.headerHeight = 0,
  }) : super(repaint: SurfaceTexture.tilesReady);

  final SurfaceTexture texture;
  final SurfaceTexture? header;
  final double headerHeight;

  void _fill(Canvas canvas, Rect rect, SurfaceTexture tex) {
    canvas.drawRect(rect, Paint()..color = tex.base);
    // Null until rasterization completes. Painting the base alone for a frame
    // is the graceful degradation; sampling an unrasterized handle instead —
    // which is what toImageSync gave us — degrades permanently.
    final tile = tex.tileOrNull();
    if (tile == null) return;
    final shader = ui.ImageShader(
      tile,
      TileMode.repeated,
      TileMode.repeated,
      _identity4,
    );
    canvas.drawRect(rect, Paint()..shader = shader);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _fill(canvas, Offset.zero & size, texture);

    final band = header;
    if (band == null || headerHeight <= 0) return;
    final h = math.min(headerHeight, size.height);
    final rect = Rect.fromLTWH(0, 0, size.width, h);
    // Fade the band's lower third to nothing, so the two materials meet as a
    // gradient rather than a seam: isolate a layer, paint the band into it,
    // then punch its alpha out with a vertical gradient via dstIn.
    canvas.saveLayer(rect, Paint());
    _fill(canvas, rect, band);
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(0, h),
          const [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
          const [0.62, 1.0],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(SurfaceTexturePainter oldDelegate) =>
      oldDelegate.texture.id != texture.id ||
      oldDelegate.header?.id != header?.id ||
      oldDelegate.headerHeight != headerHeight;
}
