import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/logger.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../providers/unit_system_provider.dart';
import '../../domain/military_ranks.dart';
import '../../providers/rank_providers.dart';
import 'rank_badge.dart';

/// Canonical library exercise ids for the two headline lifts on the share card.
const _benchId = 'barbell_bench_press';
const _squatId = 'barbell_back_squat';

/// Output bitmap size — Instagram post ratio (4:5). High enough resolution to
/// stay crisp when shared or saved; encodes in well under a frame.
const double _cardW = 1080;
const double _cardH = 1350;

/// Reads the current rank + headline lifts and shares a branded rank card.
///
/// The card is drawn straight to a bitmap with a [ui.Canvas]/[ui.PictureRecorder]
/// rather than by capturing an off-screen widget with a RepaintBoundary. The
/// widget approach was unreliable — it depended on the off-screen subtree being
/// laid out, painted, and having its images decoded before `toImage` ran, and
/// any of those not being ready produced a blank capture or threw, surfacing as
/// "Couldn't create your rank card". Drawing directly has no such dependencies.
Future<void> shareCurrentRank(BuildContext context, WidgetRef ref) async {
  try {
    final calc = await ref.read(rankCalculatorProvider.future);
    final units = ref.read(unitSystemProvider);

    final rank = calc.overall;
    final hasData = calc.exerciseScores.isNotEmpty;
    final benchKg = calc.exerciseBestWeightKg[_benchId];
    final squatKg = calc.exerciseBestWeightKg[_squatId];
    final parts = <String>[
      if (benchKg != null) 'Bench: ${UnitConverter.formatWeight(benchKg, units)}',
      if (squatKg != null) 'Squat: ${UnitConverter.formatWeight(squatKg, units)}',
    ];
    final statsLine = parts.isEmpty ? null : parts.join('   ·   ');

    // iPad requires a source rect for the share popover or it throws. Computed
    // up front (before more awaits) and reused by both share paths below.
    final box =
        context.mounted ? context.findRenderObject() as RenderBox? : null;
    final origin = (box != null && box.hasSize)
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    // Try the image card. If ANY step of the image path fails, fall back to
    // sharing plain text so the button never dead-ends with an error.
    try {
      // Render at full resolution; retry once at half if the device can't
      // allocate the full-size GPU texture.
      Uint8List bytes;
      try {
        bytes = await _renderRankCard(
          rank: rank,
          hasData: hasData,
          statsLine: statsLine,
        );
      } catch (e, st) {
        AppLogger.error(
          'Rank card render failed at full resolution; retrying at half',
          error: e,
          stack: st,
        );
        bytes = await _renderRankCard(
          rank: rank,
          hasData: hasData,
          statsLine: statsLine,
          scale: 0.5,
        );
      }

      final dir = await getTemporaryDirectory();
      final file =
          await File('${dir.path}/drillfit_rank.png').writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'My DrillFit rank 🎖️',
        sharePositionOrigin: origin,
      );
    } catch (imgErr, imgSt) {
      // Image path failed — log the real cause and share text instead.
      AppLogger.error(
        'Rank card image share failed; sharing text instead',
        error: imgErr,
        stack: imgSt,
      );
      debugPrint('SHARE RANK ERROR: $imgErr');
      debugPrint('STACK: $imgSt');
      if (kDebugMode && context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Debug: rank card error'),
            content: Text(imgErr.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      await Share.share(
        _plainRankSummary(rank, statsLine),
        subject: 'My DrillFit rank',
        sharePositionOrigin: origin,
      );
    }
  } catch (e, st) {
    AppLogger.error('Share rank failed', error: e, stack: st);
    debugPrint('SHARE RANK ERROR: $e');
    debugPrint('STACK: $st');
    if (context.mounted) {
      showCupertinoToast(context, "Couldn't create your rank card. Try again.");
    }
  }
}

/// Plain-text rank summary used as a fallback when the image card can't be
/// rendered/shared — e.g. "I'm Corporal (E3) on DrillFit 🎖️\nBench: 205 lbs …".
String _plainRankSummary(MilitaryRank rank, String? statsLine) {
  final b = StringBuffer("I'm ${rank.displayName} (E${rank.tier}) on DrillFit 🎖️");
  if (statsLine != null) b.write('\n$statsLine');
  b.write('\ndrillfit.app');
  return b.toString();
}

/// Draws the branded rank card to PNG bytes. Pure drawing + raster — no widget
/// tree and no frame scheduling, so it can't fail on un-laid-out or un-painted
/// render objects. [hasData] is false when the user has no rankable PRs yet;
/// [statsLine] is the pre-formatted "Bench … · Squat …" line, or null when
/// neither headline lift has been logged.
Future<Uint8List> _renderRankCard({
  required MilitaryRank rank,
  required bool hasData,
  required String? statsLine,
  double scale = 1.0,
}) async {
  final color = rank.color;
  const cx = _cardW / 2;
  const margin = 40.0;
  const bandW = _cardW - 220; // centered content band (generous side padding)

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, _cardW * scale, _cardH * scale),
  );
  // Draw in logical (1080×1350) coordinates; [scale] shrinks the rasterized
  // bitmap so a device that can't allocate the full-size texture still gets a
  // card (see the half-res fallback in [shareCurrentRank]).
  if (scale != 1.0) canvas.scale(scale);

  // Backdrop, then the rounded card with a rank-tinted border.
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, _cardW, _cardH),
    Paint()..color = const Color(0xFF0E0E12),
  );
  final cardRect = RRect.fromLTRBR(
    margin,
    margin,
    _cardW - margin,
    _cardH - margin,
    const Radius.circular(56),
  );
  canvas.drawRRect(cardRect, Paint()..color = const Color(0xFF1C1C1E));
  canvas.drawRRect(
    cardRect,
    Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6,
  );

  var y = margin + 80;

  // Brand wordmark.
  y += _drawCenteredText(
    canvas,
    'DrillFit',
    cx: cx,
    top: y,
    bandW: bandW,
    style: const TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w700,
      fontSize: 62,
      color: Colors.white,
    ),
  );
  y += 56;

  // Rank insignia inside a tinted disc — same drawing logic as the in-app badge.
  const discR = 210.0;
  final discCenter = Offset(cx, y + discR);
  canvas.drawCircle(
    discCenter,
    discR,
    Paint()..color = color.withValues(alpha: 0.16),
  );
  canvas.drawCircle(
    discCenter,
    discR,
    Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5,
  );
  const insigniaH = 300.0;
  const insigniaW = insigniaH * 0.92;
  canvas.save();
  canvas.translate(cx - insigniaW / 2, discCenter.dy - insigniaH / 2);
  paintRankInsignia(canvas, Size(insigniaW, insigniaH), rank, color);
  canvas.restore();
  y += discR * 2 + 48;

  // Rank name (rank-colored).
  y += _drawCenteredText(
    canvas,
    rank.displayName,
    cx: cx,
    top: y,
    bandW: bandW,
    maxLines: 2,
    style: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w800,
      fontSize: 80,
      color: color,
    ),
  );
  y += 14;

  // "Overall: <Rank> (E#)".
  y += _drawCenteredText(
    canvas,
    'Overall: ${rank.displayName} (E${rank.tier})',
    cx: cx,
    top: y,
    bandW: bandW,
    maxLines: 2,
    style: TextStyle(
      fontFamily: 'LeagueSpartan',
      fontSize: 40,
      color: Colors.white.withValues(alpha: 0.7),
    ),
  );
  y += 40;

  // Headline-lift stats, or the empty-state prompt when there are no PRs.
  if (hasData && statsLine != null) {
    _drawStatsPill(canvas, statsLine, cx: cx, top: y);
  } else {
    _drawCenteredText(
      canvas,
      hasData
          ? 'Keep logging lifts to fill out your card'
          : 'Start training to earn your rank',
      cx: cx,
      top: y + 12,
      bandW: bandW,
      maxLines: 2,
      style: TextStyle(
        fontFamily: 'LeagueSpartan',
        fontSize: 38,
        color: Colors.white.withValues(alpha: 0.65),
      ),
    );
  }

  // Footer pinned near the bottom edge of the card.
  _drawCenteredText(
    canvas,
    'drillfit.app',
    cx: cx,
    top: _cardH - margin - 96,
    bandW: bandW,
    style: TextStyle(
      fontFamily: 'LeagueSpartan',
      fontSize: 34,
      letterSpacing: 2,
      color: color.withValues(alpha: 0.85),
    ),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (_cardW * scale).round(),
    (_cardH * scale).round(),
  );
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw StateError('Rank card capture produced no bytes');
    }
    return data.buffer.asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}

/// Draws [text] horizontally centered on [cx], starting at vertical [top],
/// laid out within a [bandW]-wide band. Returns the painted height so callers
/// can advance a top-down layout cursor.
double _drawCenteredText(
  Canvas canvas,
  String text, {
  required double cx,
  required double top,
  required double bandW,
  required TextStyle style,
  int maxLines = 1,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    maxLines: maxLines,
    ellipsis: '…',
  )..layout(minWidth: bandW, maxWidth: bandW);
  tp.paint(canvas, Offset(cx - bandW / 2, top));
  return tp.height;
}

/// Draws the stats line centered inside a subtle rounded pill at [top].
void _drawStatsPill(
  Canvas canvas,
  String text, {
  required double cx,
  required double top,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        fontFamily: 'LeagueSpartan',
        fontSize: 40,
        color: Colors.white,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: _cardW - 260);

  const padH = 36.0;
  const padV = 22.0;
  final pillW = tp.width + padH * 2;
  final pillH = tp.height + padV * 2;
  final pill = RRect.fromLTRBR(
    cx - pillW / 2,
    top,
    cx + pillW / 2,
    top + pillH,
    const Radius.circular(24),
  );
  canvas.drawRRect(
    pill,
    Paint()..color = Colors.white.withValues(alpha: 0.06),
  );
  tp.paint(canvas, Offset(cx - tp.width / 2, top + padV));
}
