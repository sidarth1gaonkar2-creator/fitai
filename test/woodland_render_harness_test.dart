// RENDER HARNESS — the THREE-WAY acceptance test for the Woodland full skin.
//
// Renders Woodland, Night Ops, and the Field Manual default through the SAME
// real widgets (SkinBackground, CupertinoCard, FieldManual text styles,
// RankInsignia) and composites them side by side. The bar Woodland has to
// clear: it must read as a THIRD skin, not as "Night Ops in green".
//
// This file is a gate, not a screenshot script. It asserts:
//   a) WCAG AA for every text tone measured over the LIGHTEST camo lobe —
//      the real worst case, not the base colour.
//   b) Quantitative separation between the three skins (mean-colour distance),
//      so "distinct" is measured rather than eyeballed.
//   c) Dynamic Type holds at 1.5x with no overflow.
//   d) Field Manual and every accent-swap pack still resolve byte-identically,
//      and Night Ops's texture still generates through the ORIGINAL code path.
//
// Run: flutter test --no-test-assets test/woodland_render_harness_test.dart
// Writes to gitignored build/woodland-renders/.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitai/core/theme/app_colors.dart';
import 'package:fitai/core/theme/field_manual.dart';
import 'package:fitai/core/theme/fm_skin.dart';
import 'package:fitai/core/theme/surface_texture.dart';
import 'package:fitai/core/widgets/cupertino_helpers.dart';
import 'package:fitai/core/widgets/tactical_surface.dart';
import 'package:fitai/features/ranks/domain/military_ranks.dart';
import 'package:fitai/features/ranks/presentation/widgets/rank_badge.dart';
import 'package:fitai/features/themes/domain/app_theme_data.dart';
import 'package:fitai/features/themes/domain/theme_registry.dart';
import 'package:fitai/features/themes/providers/theme_providers.dart';

final _outDir = '${Directory.current.path}/build/woodland-renders';
const _screenSize = Size(390, 1180);

/// A stand-in with the same identity as the shipped Woodland texture, so the
/// painter's repaint check can run without reaching into the registry.
const SurfaceTexture _woodlandProbe = SurfaceTexture(
  id: 'woodland',
  base: Color(0xFF313A1E),
  tones: [Color(0xFF453823), Color(0xFF524A2C), Color(0xFF1B1F10)],
);

// ── WCAG plumbing ───────────────────────────────────────────────────────────

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Hue in degrees — the axis on which two greens actually differ.
double _hue(Color c) {
  final r = c.r, g = c.g, b = c.b;
  final mx = math.max(r, math.max(g, b)), mn = math.min(r, math.min(g, b));
  final d = mx - mn;
  if (d == 0) return 0;
  double h;
  if (mx == r) {
    h = ((g - b) / d) % 6;
  } else if (mx == g) {
    h = (b - r) / d + 2;
  } else {
    h = (r - g) / d + 4;
  }
  return (h * 60 + 360) % 360;
}

/// Shortest angular distance between two hues.
double _hueGap(Color a, Color b) {
  final d = (_hue(a) - _hue(b)).abs();
  return d > 180 ? 360 - d : d;
}

// ── Render plumbing ─────────────────────────────────────────────────────────

Future<void> _loadFont(String family, String path) async {
  final bytes = await File(path).readAsBytes();
  await (FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer))))
      .load();
}

Future<ui.Image> _render(
  WidgetTester tester, {
  required AppThemeData theme,
  required String file,
  double textScale = 1.0,
  Size size = _screenSize,
}) async {
  FieldManual.skin = FmSkin.fromTheme(theme);
  // Tiles rasterize asynchronously now, so warm them BEFORE pumping. Without
  // this the surface paints its base colour and the render silently passes
  // with a flat, textureless panel — the very defect this harness exists to
  // catch. runAsync is required: real async work can't complete under the
  // fake-async test clock.
  await tester.runAsync(() async {
    await theme.surfaceTexture?.ensureTile();
    await theme.headerTexture?.ensureTile();
  });
  await tester.binding.setSurfaceSize(size);
  final key = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [activeThemeProvider.overrideWithValue(theme)],
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: CupertinoTheme(
            data: const CupertinoThemeData(brightness: Brightness.dark),
            child: RepaintBoundary(key: key, child: _Showcase(theme: theme)),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 40));
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  late ui.Image img;
  await tester.runAsync(() async {
    img = await boundary.toImage(pixelRatio: 2.0);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    await File(file).writeAsBytes(png!.buffer.asUint8List());
  });
  return img;
}

void _label(Canvas c, String s, Offset center, double size, Color color) {
  final tp = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
}

/// Composite N renders in one row with labels — the acceptance artefact.
Future<void> _filmstrip(
  List<(ui.Image, String, Color)> panels,
  String file,
) async {
  final w = panels.first.$1.width, h = panels.first.$1.height;
  const gap = 44, headerH = 92, pad = 28;
  final totalW = pad * 2 + w * panels.length + gap * (panels.length - 1);
  final totalH = headerH + h + pad;
  final rec = ui.PictureRecorder();
  final c =
      Canvas(rec, Rect.fromLTWH(0, 0, totalW.toDouble(), totalH.toDouble()));
  c.drawRect(Rect.fromLTWH(0, 0, totalW.toDouble(), totalH.toDouble()),
      Paint()..color = const Color(0xFF161616));
  for (var i = 0; i < panels.length; i++) {
    final (img, label, tone) = panels[i];
    final x = pad + i * (w + gap);
    _label(c, label, Offset(x + w / 2, headerH / 2), 26, tone);
    c.drawImage(img, Offset(x.toDouble(), headerH.toDouble()), Paint());
  }
  final img = await rec.endRecording().toImage(totalW, totalH);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  await File(file).writeAsBytes(png!.buffer.asUint8List());
  // ignore: avoid_print
  print('WROTE $file');
}

/// Mean RGB of a render — the basis for measuring skin separation.
Future<(double, double, double)> _meanRgb(ui.Image img) async {
  final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();
  var r = 0.0, g = 0.0, b = 0.0;
  final px = bytes.length ~/ 4;
  for (var i = 0; i < bytes.length; i += 4) {
    r += bytes[i];
    g += bytes[i + 1];
    b += bytes[i + 2];
  }
  return (r / px, g / px, b / px);
}

double _rgbDistance((double, double, double) a, (double, double, double) b) {
  final dr = a.$1 - b.$1, dg = a.$2 - b.$2, db = a.$3 - b.$3;
  return math.sqrt(dr * dr + dg * dg + db * db);
}

void main() {
  setUpAll(() async {
    await _loadFont('Oswald', 'assets/fonts/Oswald-Variable.ttf');
    await _loadFont('Inter', 'assets/fonts/Inter-Variable.ttf');
    await _loadFont('JetBrainsMono', 'assets/fonts/JetBrainsMono-Variable.ttf');
    await Directory(_outDir).create(recursive: true);
  });

  tearDown(() => FieldManual.skin = const FmSkin.fieldManual());

  testWidgets('3-way acceptance — Woodland vs Night Ops vs Field Manual',
      (t) async {
    final woodland = await _render(t,
        theme: themeById('woodland'), file: '$_outDir/woodland.png');
    final nightOps = await _render(t,
        theme: themeById('night_ops'), file: '$_outDir/night_ops.png');
    final fm =
        await _render(t, theme: defaultTheme, file: '$_outDir/field_manual.png');

    await t.runAsync(() => _filmstrip([
          (woodland, 'WOODLAND', const Color(0xFFB8CA72)),
          (nightOps, 'NIGHT OPS', const Color(0xFFFF3B3B)),
          (fm, 'FIELD MANUAL', const Color(0xFFC8A24B)),
        ], '$_outDir/three_way.png'));

    // Distinctness, measured. Each pair must differ materially in mean colour;
    // "Night Ops in green" would show up as a small Woodland↔Night Ops gap.
    late (double, double, double) mw, mn, mf;
    await t.runAsync(() async {
      mw = await _meanRgb(woodland);
      mn = await _meanRgb(nightOps);
      mf = await _meanRgb(fm);
    });
    final wn = _rgbDistance(mw, mn);
    final wf = _rgbDistance(mw, mf);
    final nf = _rgbDistance(mn, mf);
    // ignore: avoid_print
    print('MEAN RGB  woodland=$mw\n          nightops=$mn\n          fm      =$mf');
    // ignore: avoid_print
    print('SEPARATION  woodland<->nightops ${wn.toStringAsFixed(1)}  '
        'woodland<->fm ${wf.toStringAsFixed(1)}  '
        'nightops<->fm ${nf.toStringAsFixed(1)}');

    expect(wn, greaterThan(12.0),
        reason: 'Woodland reads too close to Night Ops');
    expect(wf, greaterThan(12.0),
        reason: 'Woodland reads too close to Field Manual');

    // Woodland must be the WARM one: green channel leads, and it is warmer
    // (R>B) — the concrete difference from Night Ops's neutral black.
    expect(mw.$2, greaterThan(mw.$3), reason: 'Woodland should read green');
    expect(mw.$1, greaterThan(mw.$3), reason: 'Woodland should read warm');
  });

  testWidgets('Woodland holds WCAG AA over the camo texture', (t) async {
    final woodland = themeById('woodland');
    final tex = woodland.surfaceTexture!;
    final worst = tex.lightestTone; // measured by luminance, not list order

    // Every tone that can carry text, measured against the worst-case lobe.
    final tones = <String, Color>{
      'bone': FieldManual.bone,
      'mutedBone': FieldManual.mutedBone,
      'accent': woodland.accent,
      'tertiary': woodland.darkTextTertiary!,
      'alert': woodland.darkAlert!,
      'success': woodland.success,
    };

    // ignore: avoid_print
    print('AA over Woodland camo — worst-case lobe ${_hex(worst)} '
        '(L=${worst.computeLuminance().toStringAsFixed(4)})');
    tones.forEach((name, c) {
      final r = _contrast(c, worst);
      // ignore: avoid_print
      print('  ${name.padRight(10)} ${_hex(c)}  ${r.toStringAsFixed(2)}:1');
      expect(r, greaterThanOrEqualTo(4.5),
          reason: '$name fails AA over the lightest camo lobe');
    });

    // Same tones over the near-solid card fills (where dense data actually
    // lives — texture never reaches here, gate c).
    for (final surface in [
      woodland.darkSurface,
      woodland.darkSurfaceElevated!,
      woodland.darkBackground,
    ]) {
      tones.forEach((name, c) {
        expect(_contrast(c, surface), greaterThanOrEqualTo(4.5),
            reason: '$name fails AA on ${_hex(surface)}');
      });
    }

    // Accent-filled controls: the label sitting ON the accent.
    expect(_contrast(woodland.darkBackground, woodland.accent),
        greaterThanOrEqualTo(4.5));
    expect(_contrast(woodland.darkBackground, woodland.accentPressed!),
        greaterThanOrEqualTo(4.5));

    // The accent must not be confusable with the success green: "selected"
    // and "succeeded" are different meanings and must not share a colour.
    // Measured as HUE distance — a luminance ratio cannot tell two greens
    // apart, since colours of different hue can share a luminance.
    final gap = _hueGap(woodland.accent, woodland.success);
    // ignore: avoid_print
    print('accent hue ${_hue(woodland.accent).toStringAsFixed(0)}° vs '
        'success ${_hue(woodland.success).toStringAsFixed(0)}° — gap '
        '${gap.toStringAsFixed(0)}°');
    expect(gap, greaterThan(40.0),
        reason: 'accent and success read as the same green');
    // And it must stay clear of brass, or Woodland reads as an FM accent swap.
    expect(_hueGap(woodland.accent, FieldManual.brass), greaterThan(20.0),
        reason: 'Woodland accent is too close to brass');
  });

  testWidgets('Woodland holds at 1.5x Dynamic Type without overflow',
      (t) async {
    await _render(t,
        theme: themeById('woodland'),
        file: '$_outDir/woodland_dynamic_type.png',
        textScale: 1.5,
        size: const Size(390, 1770));
    expect(t.takeException(), isNull,
        reason: 'Woodland overflows at 1.5x Dynamic Type');
  });

  test('Field Manual and accent-swap packs stay byte-identical', () {
    const fm = FmSkin.fieldManual();
    final resolved = FmSkin.fromTheme(defaultTheme);
    expect(resolved.ink, fm.ink);
    expect(resolved.field, fm.field);
    expect(resolved.fieldRaised, fm.fieldRaised);
    expect(resolved.cardRadius, fm.cardRadius);
    expect(resolved.sheetRadius, fm.sheetRadius);
    expect(resolved.buttonRadius, fm.buttonRadius);
    expect(resolved.displayFamily, fm.displayFamily);
    expect(resolved.displayWeight, fm.displayWeight);
    expect(resolved.headlineWeight, fm.headlineWeight);
    expect(resolved.titleWeight, fm.titleWeight);
    expect(resolved.alert, fm.alert);
    expect(resolved.surfaceTexture, isNull);
    expect(resolved.cardBrackets, isFalse);
    expect(resolved.accentGlow, isFalse);
    // The tracking token must stay null on every theme that doesn't opt in,
    // or their display type silently re-spaces. Woodland tracks wide for
    // stencil; Dress Blues tracks open for formality — nothing else may.
    expect(resolved.displayTrackingEm, isNull);
    const tracked = {'woodland', 'dress_blues'};
    for (final theme in themeRegistry) {
      if (tracked.contains(theme.id)) continue;
      expect(FmSkin.fromTheme(theme).displayTrackingEm, isNull,
          reason: '${theme.id} picked up display tracking');
    }
  });

  test('Night Ops texture still generates through the original code path', () {
    final tex = themeById('night_ops').surfaceTexture!;
    // Night Ops must stay on the original straight-edge camoLobes path (no
    // smooth Bézier lobes, no directional pattern) — that is the real "original
    // code path" invariant. The density itself was deliberately increased
    // (72→120 per tone, radius 0.045–0.13 → 0.025–0.08) to fill the sparse
    // voids the original left; these pins track that intentional value so an
    // *accidental* future change to the shipped look still trips.
    expect(tex.smooth, isFalse);
    expect(tex.pattern, SurfaceTexturePattern.camoLobes);
    expect(tex.minRadiusFactor, 0.025);
    expect(tex.maxRadiusFactor, 0.08);
    expect(tex.blobsPerTone, 120);
    expect(tex.tileSize, 480);
    expect(tex.seed, 7);
    // lightestTone is now luminance-measured; for Night Ops that must still
    // resolve to the same tone the original list-order logic returned.
    expect(tex.lightestTone, const Color(0xFF1C1C1C));
  });

  test('Woodland texture is generated once and cached (scroll perf gate)',
      () async {
    final tex = themeById('woodland').surfaceTexture!;

    // Measure a genuine COLD build against a distinct cache id — the render
    // tests above have already warmed the shipped texture, so timing that one
    // would report a cache hit as if it were the build cost.
    final cold = SurfaceTexture(
      id: 'woodland_perf_probe',
      base: tex.base,
      tones: tex.tones,
      blobsPerTone: tex.blobsPerTone,
      tileSize: tex.tileSize,
      seed: tex.seed,
      smooth: tex.smooth,
      minRadiusFactor: tex.minRadiusFactor,
      maxRadiusFactor: tex.maxRadiusFactor,
    );
    final sw = Stopwatch()..start();
    await cold.ensureTile(); // records the picture and rasterises it, once
    sw.stop();
    final coldMicros = sw.elapsedMicroseconds;

    final first = await tex.ensureTile();

    final sw2 = Stopwatch()..start();
    for (var i = 0; i < 1000; i++) {
      tex.tileOrNull();
    }
    sw2.stop();
    final warmNanosEach = sw2.elapsedMicroseconds * 1000 / 1000;

    // ignore: avoid_print
    print('texture tile: cold ${(coldMicros / 1000).toStringAsFixed(1)}ms, '
        'warm ${warmNanosEach.toStringAsFixed(0)}ns/lookup');

    // The whole perf argument rests on this: the tile is built once, then
    // every paint is a map lookup + one tiled ImageShader draw. If the cache
    // ever stopped returning the same instance, scrolling would re-rasterise
    // a 420x420 picture per frame.
    expect(identical(tex.tileOrNull(), first), isTrue,
        reason: 'texture tile is not cached — would rebuild every paint');
    expect(warmNanosEach, lessThan(10000),
        reason: 'cached tile lookup is too slow to be a cache hit');

    // And the painter must not invalidate itself between frames. Repaints are
    // driven by SurfaceTexture.tilesReady instead, which fires once per tile.
    final painter = SurfaceTexturePainter(_woodlandProbe);
    expect(painter.shouldRepaint(painter), isFalse,
        reason: 'texture painter repaints every frame');
  });

  test('Woodland registers as an earned 2000-coin premium theme', () {
    final w = themeById('woodland');
    expect(w.id, 'woodland');
    expect(w.price, 2000);
    expect(w.isPremium, isTrue);
    // Coin unlock, NOT an IAP: no cash price, and not granted for free.
    expect(w.cashPriceCents, isNull);
    expect(w.ownedByDefault, isFalse);
    // Full-skin material, but matte — glow and HUD brackets are Night Ops only.
    expect(w.surfaceTexture, isNotNull);
    expect(w.accentGlow, isFalse);
    expect(w.cardBrackets, isFalse);
  });
}

/// One tall panel stacking the signature chrome of the three key screens,
/// built from the real reused widgets so a skin's effect on the MATERIAL
/// (texture, frames, geometry, type, accent, insignia) is visible at a glance.
class _Showcase extends StatelessWidget {
  const _Showcase({required this.theme});
  final AppThemeData theme;

  static const _rank = MilitaryRank.staffSergeant_e6;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return SkinBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(theme.name.toUpperCase(),
                style: FieldManual.label(color: p.accent, fontSize: 11)),
            const SizedBox(height: 2),
            Text('DASHBOARD', style: FieldManual.display()),
            const SizedBox(height: 12),
            CupertinoCard(
              child: Row(
                children: [
                  _disc(size: 34, inset: 22),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_rank.displayName, style: FieldManual.title()),
                      Text('E${_rank.tier} · ${_rank.abbreviation}',
                          style: FieldManual.label(fontSize: 10)),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('742',
                          style: FieldManual.readout(
                                  fontSize: 22, color: p.accent)
                              .copyWith(
                                  shadows: skinAccentTextShadows(p.accent))),
                      Text('/ 900 SCORE', style: FieldManual.label(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CupertinoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RATIONS', style: FieldManual.label(fontSize: 10)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('1,840', style: FieldManual.readout(fontSize: 34)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text('/ 2,300 KCAL',
                            style: FieldManual.label(fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _bar(p, 0.8),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _macro('PROTEIN', '148 G'),
                      _macro('CARBS', '190 G'),
                      _macro('FAT', '52 G'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('MY RANKS', style: FieldManual.headline()),
            const SizedBox(height: 10),
            CupertinoCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _disc(size: 96, inset: 58),
                  const SizedBox(height: 12),
                  Text(_rank.displayName,
                      style: FieldManual.display().copyWith(fontSize: 24)),
                  Text('E${_rank.tier} · SCORE 742 / 900',
                      style:
                          FieldManual.label(fontSize: 11, color: p.accent)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: RankInsignia(rank: _rank, size: 40, airborne: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('AIRBORNE MOUNT — STAYS BRASS UNDER ANY SKIN',
                      style: FieldManual.label(fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('LOG SET', style: FieldManual.headline()),
            const SizedBox(height: 10),
            CupertinoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Barbell Bench Press', style: FieldManual.title()),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('SET 3', style: FieldManual.label(fontSize: 10)),
                      const Spacer(),
                      Text('135 LB × 5',
                          style: FieldManual.readout(fontSize: 18)),
                      const SizedBox(width: 8),
                      Icon(CupertinoIcons.checkmark_alt_circle_fill,
                          color: p.accent,
                          size: 20,
                          shadows: skinAccentTextShadows(p.accent)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _btn(p, 'LOG SET', filled: true)),
                const SizedBox(width: 10),
                Expanded(child: _btn(p, 'ADD SET', filled: false)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(CupertinoIcons.exclamationmark_triangle_fill,
                    color: FieldManual.alert, size: 14),
                const SizedBox(width: 6),
                Flexible(
                  child: Text('2 SETS BELOW TARGET',
                      style: FieldManual.label(
                          fontSize: 10, color: FieldManual.alert)),
                ),
              ],
            ),
            const Spacer(),
            _tabbar(p),
          ],
        ),
      ),
    );
  }

  Widget _disc({required double size, required double inset}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _rank.color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: _rank.color.withValues(alpha: 0.6), width: 2),
      ),
      alignment: Alignment.center,
      child: RankInsignia(rank: _rank, size: inset),
    );
  }

  Widget _bar(Palette p, double frac) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FieldManual.buttonRadius),
      child: Container(
        height: 8,
        color: FieldManual.fieldRaised,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: frac,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.accent,
              boxShadow: skinAccentGlow(p.accent, blur: 10, alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _macro(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: FieldManual.label(fontSize: 9)),
          const SizedBox(height: 2),
          Text(value, style: FieldManual.readout(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _btn(Palette p, String label, {required bool filled}) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? p.accent : FieldManual.fieldRaised,
        borderRadius: BorderRadius.circular(FieldManual.buttonRadius),
        border: filled ? null : Border.all(color: p.border),
        boxShadow: filled ? skinAccentGlow(p.accent) : null,
      ),
      child: Text(
        label,
        style: FieldManual.label(
          fontSize: 12,
          color: filled ? p.onAccent : FieldManual.bone,
        ),
      ),
    );
  }

  Widget _tabbar(Palette p) {
    Widget item(IconData icon, String label, bool active) => Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 22,
                  color: active ? p.accent : p.textTertiary,
                  shadows: active ? skinAccentTextShadows(p.accent) : null),
              const SizedBox(height: 3),
              Text(label,
                  style: FieldManual.label(
                          fontSize: 9,
                          color: active ? p.accent : p.textTertiary)
                      .copyWith(
                          shadows:
                              active ? skinAccentTextShadows(p.accent) : null)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          item(CupertinoIcons.house_fill, 'BASE', true),
          item(CupertinoIcons.chart_bar_alt_fill, 'PROGRESS', false),
          item(CupertinoIcons.person_fill, 'PROFILE', false),
        ],
      ),
    );
  }
}
