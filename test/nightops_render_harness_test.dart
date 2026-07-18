// RENDER HARNESS — Night Ops (full skin) vs Field Manual default across the
// dashboard / My Ranks / logging chrome, using the REAL reused widgets
// (SkinBackground, CupertinoCard, FieldManual text styles, RankInsignia) under
// each skin. Produces a SIDE-BY-SIDE PNG — the acceptance test: the two must
// read as different SKINS, not a recolor.
//
// Run: flutter test --no-test-assets test/nightops_render_harness_test.dart
// (fonts load from disk via FontLoader; --no-test-assets is fine.)
// Writes to gitignored build/nightops-renders/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitai/core/theme/app_colors.dart';
import 'package:fitai/core/theme/field_manual.dart';
import 'package:fitai/core/theme/fm_skin.dart';
import 'package:fitai/core/widgets/cupertino_helpers.dart';
import 'package:fitai/core/widgets/tactical_surface.dart';
import 'package:fitai/features/ranks/domain/military_ranks.dart';
import 'package:fitai/features/ranks/presentation/widgets/rank_badge.dart';
import 'package:fitai/features/themes/domain/app_theme_data.dart';
import 'package:fitai/features/themes/domain/theme_registry.dart';
import 'package:fitai/features/themes/providers/theme_providers.dart';

final _outDir = '${Directory.current.path}/build/nightops-renders';
const _screenSize = Size(390, 1180);

Future<void> _loadFont(String family, String path) async {
  final bytes = await File(path).readAsBytes();
  await (FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer))))
      .load();
}

Future<ui.Image> _render(
  WidgetTester tester, {
  required AppThemeData theme,
  required String file,
}) async {
  FieldManual.skin = FmSkin.fromTheme(theme);
  await tester.binding.setSurfaceSize(_screenSize);
  final key = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [activeThemeProvider.overrideWithValue(theme)],
      child: MediaQuery(
        data: const MediaQueryData(size: _screenSize),
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

Future<void> _sideBySide(
  ui.Image a,
  String la,
  ui.Image b,
  String lb,
  String file,
) async {
  final w = a.width, h = a.height;
  const gap = 44, headerH = 88, pad = 28;
  final totalW = pad + w + gap + w + pad;
  final totalH = headerH + h + pad;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec, Rect.fromLTWH(0, 0, totalW.toDouble(), totalH.toDouble()));
  c.drawRect(Rect.fromLTWH(0, 0, totalW.toDouble(), totalH.toDouble()),
      Paint()..color = const Color(0xFF161616));
  _label(c, la, Offset(pad + w / 2, headerH / 2), 26, const Color(0xFFFFB000));
  _label(c, lb, Offset(pad + w + gap + w / 2.0, headerH / 2), 26,
      const Color(0xFFC8A24B));
  c.drawImage(a, Offset(pad.toDouble(), headerH.toDouble()), Paint());
  c.drawImage(
      b, Offset((pad + w + gap).toDouble(), headerH.toDouble()), Paint());
  final img = await rec.endRecording().toImage(totalW, totalH);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  await File(file).writeAsBytes(png!.buffer.asUint8List());
  // ignore: avoid_print
  print('WROTE $file');
}

void main() {
  setUpAll(() async {
    await _loadFont('Oswald', 'assets/fonts/Oswald-Variable.ttf');
    await _loadFont('Inter', 'assets/fonts/Inter-Variable.ttf');
    await _loadFont('JetBrainsMono', 'assets/fonts/JetBrainsMono-Variable.ttf');
    await Directory(_outDir).create(recursive: true);
  });

  tearDown(() => FieldManual.skin = const FmSkin.fieldManual());

  testWidgets('Night Ops vs Field Manual — side-by-side acceptance', (t) async {
    final nightOps = await _render(t,
        theme: themeById('night_ops'), file: '$_outDir/night_ops.png');
    final fm = await _render(t,
        theme: defaultTheme, file: '$_outDir/field_manual.png');
    await t.runAsync(() => _sideBySide(
          nightOps,
          'NIGHT OPS',
          fm,
          'FIELD MANUAL',
          '$_outDir/night_ops_vs_fm.png',
        ));
  });
}

/// One tall panel stacking the signature chrome of the three key screens, built
/// from the real reused widgets so a skin's effect on the *material* (texture,
/// frames, geometry, type, accent, insignia) is visible at a glance.
class _Showcase extends StatelessWidget {
  const _Showcase({required this.theme});
  final AppThemeData theme;

  static const _rank = MilitaryRank.staffSergeant_e6;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    // SkinBackground paints the tactical texture on a full skin, or a solid
    // ink fill on accent-swap themes (byte-identical).
    return SkinBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── DASHBOARD ─────────────────────────────────────────────────
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
                              fontSize: 22, color: p.accent)),
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
                      Text('/ 2,300 KCAL',
                          style: FieldManual.label(fontSize: 11)),
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

            // ── MY RANKS ──────────────────────────────────────────────────
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

            // ── LOGGING ───────────────────────────────────────────────────
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
                      Text('135 LB × 5', style: FieldManual.readout(fontSize: 18)),
                      const SizedBox(width: 8),
                      Icon(CupertinoIcons.checkmark_alt_circle_fill,
                          color: p.accent, size: 20),
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
                  size: 22, color: active ? p.accent : p.textTertiary),
              const SizedBox(height: 3),
              Text(label,
                  style: FieldManual.label(
                      fontSize: 9,
                      color: active ? p.accent : p.textTertiary)),
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
