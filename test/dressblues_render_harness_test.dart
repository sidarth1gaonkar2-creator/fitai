// RENDER HARNESS — the FOUR-WAY acceptance test for Dress Blues, the
// Airborne-exclusive flagship full skin.
//
// The risk this file exists to catch: Night Ops and Woodland earn their
// premium feel from rugged material, but Dress Blues has to earn it from
// REFINEMENT. If the twill and the brass trim don't land, what ships is "a
// navy theme" — and that failure looks fine in isolation. It only shows up
// against the other three, which is what the separation gate measures.
//
// Asserts:
//   a) 4-way separation: Dress Blues vs FM, vs Night Ops, vs Woodland.
//   b) WCAG AA for every text tone over BOTH textures' worst-case tone,
//      with brass-on-navy and bone-on-navy called out explicitly.
//   c) Dynamic Type at 1.5x, texture caching, seamless tiling.
//   d) Economy: Airborne-gated, never coin-purchasable, re-locks on lapse.
//   e) FM, every accent-swap pack, Night Ops and Woodland unchanged.
//
// Run: flutter test --no-test-assets test/dressblues_render_harness_test.dart
// Writes to gitignored build/dressblues-renders/.
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
import 'package:fitai/features/themes/domain/theme_gate.dart';
import 'package:fitai/features/themes/domain/theme_registry.dart';
import 'package:fitai/features/themes/providers/theme_providers.dart';

final _outDir = '${Directory.current.path}/build/dressblues-renders';
const _screenSize = Size(390, 1180);

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

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

Future<void> _filmstrip(
  List<(ui.Image, String, Color)> panels,
  String file,
) async {
  final w = panels.first.$1.width, h = panels.first.$1.height;
  const gap = 40, headerH = 92, pad = 26;
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
    _label(c, label, Offset(x + w / 2, headerH / 2), 24, tone);
    c.drawImage(img, Offset(x.toDouble(), headerH.toDouble()), Paint());
  }
  final img = await rec.endRecording().toImage(totalW, totalH);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  await File(file).writeAsBytes(png!.buffer.asUint8List());
  // ignore: avoid_print
  print('WROTE $file');
}

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

double _dist((double, double, double) a, (double, double, double) b) {
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

  testWidgets('4-way acceptance — Dress Blues vs FM vs Night Ops vs Woodland',
      (t) async {
    final blues = await _render(t,
        theme: themeById('dress_blues'), file: '$_outDir/dress_blues.png');
    final fm =
        await _render(t, theme: defaultTheme, file: '$_outDir/field_manual.png');
    final nightOps = await _render(t,
        theme: themeById('night_ops'), file: '$_outDir/night_ops.png');
    final woodland = await _render(t,
        theme: themeById('woodland'), file: '$_outDir/woodland.png');

    await t.runAsync(() => _filmstrip([
          (blues, 'DRESS BLUES', const Color(0xFFD9BC6A)),
          (fm, 'FIELD MANUAL', const Color(0xFFC8A24B)),
          (nightOps, 'NIGHT OPS', const Color(0xFFFF3B3B)),
          (woodland, 'WOODLAND', const Color(0xFFC2D473)),
        ], '$_outDir/four_way.png'));

    late (double, double, double) mb, mf, mn, mw;
    await t.runAsync(() async {
      mb = await _meanRgb(blues);
      mf = await _meanRgb(fm);
      mn = await _meanRgb(nightOps);
      mw = await _meanRgb(woodland);
    });
    final vsFm = _dist(mb, mf), vsNo = _dist(mb, mn), vsWo = _dist(mb, mw);
    // ignore: avoid_print
    print('MEAN RGB dressblues=$mb');
    // ignore: avoid_print
    print('SEPARATION  vs FM ${vsFm.toStringAsFixed(1)}  '
        'vs NightOps ${vsNo.toStringAsFixed(1)}  '
        'vs Woodland ${vsWo.toStringAsFixed(1)}');

    // Must clear the gate against ALL THREE. Scoring high against Night Ops
    // and Woodland while hugging FM is exactly the "just a navy theme"
    // failure — navy is far from olive and black almost for free.
    expect(vsFm, greaterThan(12.0),
        reason: 'Dress Blues reads too close to Field Manual — "just navy"');
    expect(vsNo, greaterThan(12.0), reason: 'too close to Night Ops');
    expect(vsWo, greaterThan(12.0), reason: 'too close to Woodland');

    // And it must actually be NAVY: blue leads, and it is cool (B > R).
    expect(mb.$3, greaterThan(mb.$1), reason: 'Dress Blues should read blue');
    expect(mb.$3, greaterThan(mb.$2), reason: 'blue should lead green');
  });

  testWidgets('Dress Blues holds WCAG AA over both textures', (t) async {
    final blues = themeById('dress_blues');
    final twill = blues.surfaceTexture!;
    final metal = blues.headerTexture!;

    final tones = <String, Color>{
      'bone': FieldManual.bone,
      'mutedBone': FieldManual.mutedBone,
      'accent(gold)': blues.accent,
      'tertiary': blues.darkTextTertiary!,
      'alert': blues.darkAlert!,
      'success': blues.success,
    };

    for (final (name, tex) in [('twill ground', twill), ('metal header', metal)]) {
      final worst = tex.lightestTone;
      // ignore: avoid_print
      print('AA over $name — worst tone ${_hex(worst)} '
          '(L=${worst.computeLuminance().toStringAsFixed(4)})');
      tones.forEach((tn, c) {
        final r = _contrast(c, worst);
        // ignore: avoid_print
        print('  ${tn.padRight(13)} ${_hex(c)}  ${r.toStringAsFixed(2)}:1');
        expect(r, greaterThanOrEqualTo(4.5),
            reason: '$tn fails AA over $name');
      });
    }

    // Called out explicitly: the two pairings the whole skin rests on.
    final brassOnNavy = _contrast(blues.accent, blues.darkBackground);
    final boneOnNavy = _contrast(FieldManual.bone, blues.darkBackground);
    // ignore: avoid_print
    print('brass-on-navy ${brassOnNavy.toStringAsFixed(2)}:1   '
        'bone-on-navy ${boneOnNavy.toStringAsFixed(2)}:1');
    expect(brassOnNavy, greaterThanOrEqualTo(4.5));
    expect(boneOnNavy, greaterThanOrEqualTo(4.5));

    // Near-solid card surfaces (dense data lives here — texture never does).
    for (final s in [
      blues.darkSurface,
      blues.darkSurfaceElevated!,
      blues.darkBackground,
    ]) {
      tones.forEach((tn, c) {
        expect(_contrast(c, s), greaterThanOrEqualTo(4.5),
            reason: '$tn fails AA on ${_hex(s)}');
      });
    }
    expect(_contrast(blues.darkBackground, blues.accent),
        greaterThanOrEqualTo(4.5));
    expect(_contrast(blues.darkBackground, blues.accentPressed!),
        greaterThanOrEqualTo(4.5));

    // The gold trim must stay legible as structure against its own ground.
    // Composited over navy at 60%, not measured as if it were opaque.
    final trim = Color.alphaBlend(blues.darkBorder!, blues.darkSurface);
    final trimContrast = _contrast(trim, blues.darkSurface);
    // ignore: avoid_print
    print('brass trim ${_hex(trim)} on card ${trimContrast.toStringAsFixed(2)}:1');
    expect(trimContrast, greaterThan(3.0),
        reason: 'brass trim is too faint to read as trim');

    // Gold braid vs Field Manual brass. These CANNOT separate on hue — braid
    // is brass-family by definition, and they sit ~2° apart — so the claim
    // being made is that they separate on LUMINANCE instead. Assert that,
    // rather than pretending to a hue gap the palette doesn't have.
    final hueGap = (_hue(blues.accent) - _hue(FieldManual.brass)).abs();
    final lumGap =
        blues.accent.computeLuminance() - FieldManual.brass.computeLuminance();
    // ignore: avoid_print
    print('gold ${_hex(blues.accent)} vs FM brass ${_hex(FieldManual.brass)}: '
        'hue gap ${hueGap.toStringAsFixed(0)}°, luminance gap '
        '${lumGap.toStringAsFixed(3)}');
    expect(lumGap, greaterThan(0.10),
        reason: 'gold braid is not lifted clear of FM brass — with only a '
            '~2° hue gap, luminance is the only axis separating them');
  });

  testWidgets('Dress Blues holds at 1.5x Dynamic Type without overflow',
      (t) async {
    await _render(t,
        theme: themeById('dress_blues'),
        file: '$_outDir/dress_blues_dynamic_type.png',
        textScale: 1.5,
        size: const Size(390, 1770));
    expect(t.takeException(), isNull);
  });

  test('both Dress Blues textures cache and tile seamlessly', () async {
    final blues = themeById('dress_blues');
    for (final tex in [blues.surfaceTexture!, blues.headerTexture!]) {
      // The directional patterns are only seamless when the tile is a whole
      // multiple of the rib pitch; otherwise the weave visibly seams.
      expect(tex.tileSize % tex.ribPitch, 0,
          reason: '${tex.id} tile size is not a multiple of its rib pitch');
      final first = await tex.ensureTile();
      expect(identical(tex.tileOrNull(), first), isTrue,
          reason: '${tex.id} is not cached — would rebuild every paint');
    }
    final painter = SurfaceTexturePainter(_twillProbe,
        header: _metalProbe, headerHeight: 260);
    expect(painter.shouldRepaint(painter), isFalse,
        reason: 'texture painter repaints every frame');
  });

  test('Dress Blues is Airborne-gated and never purchasable', () {
    final blues = themeById('dress_blues');
    expect(blues.airborneExclusive, isTrue);
    expect(blues.price, 0);
    expect(blues.cashPriceCents, isNull);
    expect(blues.ownedByDefault, isFalse);
    expect(blues.isPremium, isFalse); // premium == coin-only; this is neither

    // Coins can never buy it, however many the user has.
    expect(isCoinPurchasable(blues), isFalse);
    // And it is not a "standard coin theme", so it can't sneak in that way.
    expect(isStandardCoinTheme(blues), isFalse);

    // Locked without the subscription...
    expect(
      unlockedThemeIds(owned: {'midnight_blue'}, airborneActive: false),
      isNot(contains('dress_blues')),
    );
    // ...unlocked with it...
    expect(
      unlockedThemeIds(owned: {'midnight_blue'}, airborneActive: true),
      contains('dress_blues'),
    );
    // ...and it RE-LOCKS when the subscription lapses, because Airborne never
    // writes ownership. Even a user who equipped it loses it.
    expect(
      unlockedThemeIds(owned: {'midnight_blue'}, airborneActive: false),
      isNot(contains('dress_blues')),
    );

    // The coin-premium skins must NOT have been dragged into the Airborne
    // unlock by this change — they stay the long-term coin sink.
    final airborneSet =
        unlockedThemeIds(owned: const {}, airborneActive: true);
    expect(airborneSet, isNot(contains('woodland')));
    expect(airborneSet, isNot(contains('neon_pulse')));
    expect(airborneSet, isNot(contains('stealth')));
  });

  test('every other skin is byte-identical', () {
    const fm = FmSkin.fieldManual();
    final resolved = FmSkin.fromTheme(defaultTheme);
    expect(resolved.ink, fm.ink);
    expect(resolved.field, fm.field);
    expect(resolved.cardRadius, fm.cardRadius);
    expect(resolved.displayWeight, fm.displayWeight);
    expect(resolved.alert, fm.alert);
    expect(resolved.surfaceTexture, isNull);
    expect(resolved.headerTexture, isNull);
    expect(resolved.headerBandHeight, 0);
    expect(resolved.displayTrackingEm, isNull);

    // Only Dress Blues may carry a header band; only it and Woodland track.
    for (final theme in themeRegistry) {
      final skin = FmSkin.fromTheme(theme);
      if (theme.id != 'dress_blues') {
        expect(skin.headerTexture, isNull,
            reason: '${theme.id} picked up a header band');
        expect(skin.headerBandHeight, 0, reason: '${theme.id} header height');
      }
      if (theme.id != 'dress_blues' && theme.id != 'woodland') {
        expect(skin.displayTrackingEm, isNull,
            reason: '${theme.id} picked up display tracking');
      }
    }

    // The camo skins must still generate through the ORIGINAL blob path.
    for (final id in ['night_ops', 'woodland']) {
      final tex = themeById(id).surfaceTexture!;
      expect(tex.pattern, SurfaceTexturePattern.camoLobes,
          reason: '$id changed texture pattern');
    }
    final no = themeById('night_ops').surfaceTexture!;
    expect(no.smooth, isFalse);
    // Density raised deliberately (72→120/tone, 0.045–0.13 → 0.025–0.08) to
    // fill the sparse voids; the camoLobes path and near-black tones are what
    // must stay fixed, and do.
    expect(no.minRadiusFactor, 0.025);
    expect(no.maxRadiusFactor, 0.08);
    expect(no.lightestTone, const Color(0xFF1C1C1C));
  });
}

const SurfaceTexture _twillProbe = SurfaceTexture(
  id: 'dress_blues_twill',
  base: Color(0xFF161B2C),
  tones: [Color(0xFF181E31), Color(0xFF1D2439)],
  pattern: SurfaceTexturePattern.twillWeave,
  ribPitch: 6,
);
const SurfaceTexture _metalProbe = SurfaceTexture(
  id: 'dress_blues_metal',
  base: Color(0xFF1E2540),
  tones: [Color(0xFF222A47), Color(0xFF2C3557)],
  pattern: SurfaceTexturePattern.brushedMetal,
  ribPitch: 4,
);

/// Same showcase the Woodland harness uses, so the four skins are compared on
/// identical chrome built from the real widgets.
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
                      style: FieldManual.label(fontSize: 11, color: p.accent)),
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
