// RENDER HARNESS — renders the Night Ops full skin vs the Field Manual default
// across dashboard / My Ranks / logging chrome, using the REAL reused widgets
// (CupertinoCard, FieldManual text styles, RankInsignia) under each skin.
//
// Run: flutter test --no-test-assets test/nightops_render_harness_test.dart
// (fonts are loaded from disk via FontLoader, so the test-asset bundle isn't
// needed — --no-test-assets is fine and matches the repo convention).
//
// Writes PNGs to the gitignored build/nightops-renders/ (safe on any checkout).
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
import 'package:fitai/features/ranks/domain/military_ranks.dart';
import 'package:fitai/features/ranks/presentation/widgets/rank_badge.dart';
import 'package:fitai/features/themes/domain/app_theme_data.dart';
import 'package:fitai/features/themes/domain/theme_registry.dart';
import 'package:fitai/features/themes/providers/theme_providers.dart';

final _outDir = '${Directory.current.path}/build/nightops-renders';

Future<void> _loadFont(String family, String path) async {
  final bytes = await File(path).readAsBytes();
  await (FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer))))
      .load();
}

Future<void> _capture(
  WidgetTester tester, {
  required AppThemeData theme,
  required String file,
}) async {
  // The whole-app skin the FM statics resolve (surfaces/geometry/type).
  FieldManual.skin = FmSkin.fromTheme(theme);
  const size = Size(390, 1200);
  await tester.binding.setSurfaceSize(size);
  final key = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [activeThemeProvider.overrideWithValue(theme)],
      child: MediaQuery(
        data: const MediaQueryData(size: size),
        child: Directionality(
          textDirection: TextDirection.ltr,
          // The app always runs dark (light mode retired); AppColors reads
          // brightness off CupertinoTheme, so the Palette channel needs a dark
          // CupertinoTheme here or it falls back to the light palette.
          child: CupertinoTheme(
            data: const CupertinoThemeData(brightness: Brightness.dark),
            child: RepaintBoundary(key: key, child: _Showcase(theme: theme)),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 32));
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2.0);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(file).writeAsBytes(png!.buffer.asUint8List());
    image.dispose();
  });
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

  tearDown(() {
    // Reset the global skin so ordering never leaks between captures.
    FieldManual.skin = const FmSkin.fieldManual();
  });

  testWidgets('Night Ops skin — dashboard/ranks/logging chrome', (t) async {
    await _capture(t, theme: themeById('night_ops'), file: '$_outDir/night_ops.png');
  });

  testWidgets('Field Manual default — same chrome for comparison', (t) async {
    await _capture(t, theme: defaultTheme, file: '$_outDir/field_manual.png');
  });
}

/// A single tall panel that stacks the signature chrome of the three key
/// screens, built from the real reused widgets so a skin's effect on surfaces,
/// geometry, type, accent, and insignia is visible at a glance.
class _Showcase extends StatelessWidget {
  const _Showcase({required this.theme});
  final AppThemeData theme;

  static const _rank = MilitaryRank.staffSergeant_e6;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return ColoredBox(
      color: FieldManual.ink,
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
                  _disc(p, size: 34, inset: 22),
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
                  _disc(p, size: 96, inset: 58),
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

  Widget _disc(Palette p, {required double size, required double inset}) {
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
          child: Container(color: p.accent),
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
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: FieldManual.hairline)),
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
