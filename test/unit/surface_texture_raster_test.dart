// Regression tests for "flagship skin textures render as solid fill on device".
//
// Root cause was Picture.toImageSync being called lazily from inside
// CustomPainter.paint(). That API returns a handle that is still rasterizing
// whenever a GPU context exists, so the ImageShader built from it in the same
// paint pass sampled an empty texture — and the handle was then cached
// forever. The headless harness never caught it because with no GPU context
// the engine falls back to a synchronous CPU raster, which completes in time.
//
// These assertions are renderer-independent: they check the SHAPE of the code
// path, not pixels produced under one particular backend, so a debug/headless
// run cannot false-pass them the way the original harness did.
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitai/core/theme/surface_texture.dart';
import 'package:fitai/features/themes/domain/theme_registry.dart';

const _probe = SurfaceTexture(
  id: 'raster_regression_probe',
  base: Color(0xFF101010),
  tones: [Color(0xFF303030), Color(0xFF505050)],
  tileSize: 64,
  blobsPerTone: 6,
);

void main() {
  setUp(SurfaceTexture.debugClearCache);
  tearDown(SurfaceTexture.debugClearCache);

  test('paint() NEVER rasterizes a tile inline', () {
    expect(SurfaceTexture.debugIsCached(_probe.id), isFalse);

    // Drive a paint pass on a cold texture, the way the framework does.
    final recorder = ui.PictureRecorder();
    SurfaceTexturePainter(_probe).paint(Canvas(recorder), const Size(390, 800));
    recorder.endRecording();

    // The exact inversion of the bug: painting must not have produced a tile.
    // If this fails, someone has put synchronous rasterization back on the
    // paint path and the skins will go flat on device again.
    expect(SurfaceTexture.debugIsCached(_probe.id), isFalse,
        reason: 'paint() rasterized inline — the device bug is back');
  });

  test('painting a cold texture still lays down the base colour', () async {
    // Graceful degradation: one frame of flat base, never a blank hole.
    final recorder = ui.PictureRecorder();
    SurfaceTexturePainter(_probe).paint(Canvas(recorder), const Size(8, 8));
    final img = await recorder.endRecording().toImage(8, 8);
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    final px = data!.buffer.asUint8List();
    expect(px[0], 0x10, reason: 'base colour missing while tile is pending');
    expect(px[3], 0xFF, reason: 'surface should be opaque, not transparent');
  });

  test('ensureTile completes with a tile carrying real, varied pixels', () async {
    final image = await _probe.ensureTile();
    expect(image.width, _probe.tileSize);

    // Assert by CONTENT, not by a non-null handle: an unrasterized image would
    // read back uniform. A real tile has its base plus its tones present.
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final px = data!.buffer.asUint8List();
    final distinct = <int>{};
    for (var i = 0; i < px.length; i += 4) {
      distinct.add((px[i] << 16) | (px[i + 1] << 8) | px[i + 2]);
    }
    expect(distinct.length, greaterThan(1),
        reason: 'tile rasterized to a uniform fill — nothing was drawn');
    expect(SurfaceTexture.debugIsCached(_probe.id), isTrue);
  });

  test('concurrent callers share one rasterization', () async {
    final results = await Future.wait([
      _probe.ensureTile(),
      _probe.ensureTile(),
      _probe.ensureTile(),
    ]);
    expect(identical(results[0], results[1]), isTrue);
    expect(identical(results[1], results[2]), isTrue);
  });

  test('every shipped full-skin texture rasterizes to real content', () async {
    // All three skins share this path; verify the actual shipped configs, not
    // just a probe. Covers both directional patterns and the camo lobes.
    for (final id in ['night_ops', 'woodland', 'dress_blues']) {
      final theme = themeById(id);
      for (final tex in [theme.surfaceTexture, theme.headerTexture]) {
        if (tex == null) continue;
        final image = await tex.ensureTile();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final px = data!.buffer.asUint8List();
        final distinct = <int>{};
        for (var i = 0; i < px.length; i += 4) {
          distinct.add((px[i] << 16) | (px[i + 1] << 8) | px[i + 2]);
        }
        expect(distinct.length, greaterThan(1),
            reason: '$id / ${tex.id} rasterized to a uniform fill');
      }
    }
  });

  test('accent-swap packs never touch the texture path', () {
    // The fix must stay additive: FM and the eight packs carry no texture, so
    // SkinBackground takes its ColoredBox branch and none of this runs.
    for (final theme in themeRegistry) {
      if (const {'night_ops', 'woodland', 'dress_blues'}.contains(theme.id)) {
        continue;
      }
      expect(theme.surfaceTexture, isNull, reason: '${theme.id} gained a texture');
      expect(theme.headerTexture, isNull, reason: '${theme.id} gained a header');
    }
  });
}
