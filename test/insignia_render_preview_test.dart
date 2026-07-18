// RENDER HARNESS — renders base vs Airborne insignia for review.
// Run: flutter test --no-test-assets test/zzz_insignia_render_harness_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai/features/ranks/domain/military_ranks.dart';
import 'package:fitai/features/ranks/presentation/widgets/rank_badge.dart';

const _ink = Color(0xFF1A1C1A);
const _field = Color(0xFF21241F);
const _bone = Color(0xFFE8E4D8);
const _mutedBone = Color(0xFFCDC8BA);
const _hairline = Color(0x29E8E4D8);
// Repo-relative, gitignored build output — safe on any checkout / CI.
final _outDir = '${Directory.current.path}/build/insignia-renders';

TextPainter _tp(String s, double size, Color color, FontWeight w) => TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: size,
              color: color,
              fontWeight: w,
              letterSpacing: 0.5)),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

void _label(ui.Canvas c, String s, Offset center,
    {double size = 12, Color color = _mutedBone, FontWeight w = FontWeight.w700}) {
  final tp = _tp(s, size, color, w);
  tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
}

void _insignia(ui.Canvas c, MilitaryRank rank, Offset center, double px,
    {required bool airborne}) {
  final box =
      Rect.fromCenter(center: center, width: px * 0.92, height: px);
  c.save();
  c.translate(box.left, box.top);
  paintRankInsignia(c, Size(box.width, box.height), rank, rank.color,
      airborne: airborne);
  c.restore();
}

void main() {
  setUpAll(() async {
    final bytes =
        await File('assets/fonts/JetBrainsMono-Variable.ttf').readAsBytes();
    await (FontLoader('JetBrainsMono')
          ..addFont(Future.value(ByteData.view(bytes.buffer))))
        .load();
    await Directory(_outDir).create(recursive: true);
  });

  test('Airborne mount — base vs airborne, SSG + SMA, My-Ranks + strip-22',
      () async {
    const samples = [MilitaryRank.staffSergeant_e6, MilitaryRank.sgmArmy_e10];
    const sampleLabels = ['SSG', 'SMA'];
    // (header, px, airborne, cellWidth)
    final cols = <(String, double, bool, double)>[
      ('BASE · MY-RANKS', 104, false, 190),
      ('AIRBORNE · MY-RANKS', 104, true, 190),
      ('BASE @22', 22, false, 116),
      ('AIRBORNE @22', 22, true, 116),
    ];

    const leftGutter = 70.0;
    const rowH = 178.0;
    const headerH = 42.0;
    const titleH = 72.0;

    final totalCols = cols.fold<double>(0, (a, c) => a + c.$4);
    final w = (leftGutter + totalCols + 24).toInt();
    final h = (titleH + headerH + samples.length * rowH + 24).toInt();

    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
    c.drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        Paint()..color = _ink);

    _label(c, 'AIRBORNE INSIGNIA — BRASS ISSUED-MOUNT', Offset(w / 2, 28),
        size: 17, color: _bone);
    _label(
        c,
        'earned rank, elevated finish · flat brass frame + plate + rivets · same rank, never purchased',
        Offset(w / 2, 50),
        size: 10.5,
        color: _mutedBone,
        w: FontWeight.w500);

    // column headers
    var x = leftGutter;
    for (final col in cols) {
      _label(c, col.$1, Offset(x + col.$4 / 2, titleH + headerH / 2),
          size: 11, color: _mutedBone);
      x += col.$4;
    }

    var y = titleH + headerH;
    for (var s = 0; s < samples.length; s++) {
      final rank = samples[s];
      _label(c, sampleLabels[s], Offset(leftGutter / 2, y + rowH / 2),
          size: 14, color: rank.color);
      var cxx = leftGutter;
      for (final col in cols) {
        final center = Offset(cxx + col.$4 / 2, y + rowH / 2);
        final big = col.$2 >= 60;
        final panelW = big ? 168.0 : 92.0;
        final panelH = big ? 148.0 : 92.0;
        final panel = RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: panelW, height: panelH),
            const Radius.circular(10));
        c.drawRRect(panel, Paint()..color = _field);
        c.drawRRect(
            panel,
            Paint()
              ..color = _hairline
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
        _insignia(c, rank, center, col.$2, airborne: col.$3);
        cxx += col.$4;
      }
      y += rowH;
    }

    final img = await rec.endRecording().toImage(w, h);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$_outDir/airborne_mount_base_vs_airborne.png');
    await f.writeAsBytes(png!.buffer.asUint8List());
    // ignore: avoid_print
    print('WROTE ${f.path}');
  });
}
