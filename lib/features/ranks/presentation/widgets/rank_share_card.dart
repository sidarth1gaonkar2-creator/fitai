import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

/// Reads the current rank + headline lifts, renders a [RankShareCard]
/// off-screen, captures it to a PNG, and opens the system share sheet.
Future<void> shareCurrentRank(BuildContext context, WidgetRef ref) async {
  try {
    final calc = await ref.read(rankCalculatorProvider.future);
    final units = ref.read(unitSystemProvider);
    final benchKg = calc.exerciseBestWeightKg[_benchId];
    final squatKg = calc.exerciseBestWeightKg[_squatId];

    final card = RankShareCard(
      rank: calc.overall,
      benchText:
          benchKg == null ? null : UnitConverter.formatWeight(benchKg, units),
      squatText:
          squatKg == null ? null : UnitConverter.formatWeight(squatKg, units),
    );

    if (!context.mounted) return;
    // Make sure the logo is decoded before we capture, or it renders blank.
    await precacheImage(const AssetImage('assets/images/app-icon.png'), context);
    if (!context.mounted) return;
    await _captureAndShare(context, card);
  } catch (e, st) {
    AppLogger.error('Share rank failed', error: e, stack: st);
    if (context.mounted) {
      showCupertinoToast(context, "Couldn't create your rank card.");
    }
  }
}

Future<void> _captureAndShare(BuildContext context, Widget card) async {
  final boundaryKey = GlobalKey();
  final overlay = Overlay.of(context, rootOverlay: true);

  // Render the card off-screen (still laid out + painted, so toImage works).
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -4000,
      top: 0,
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(key: boundaryKey, child: card),
      ),
    ),
  );
  overlay.insert(entry);

  try {
    // Give it a frame (plus a hair) to lay out and paint.
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    // Dispose the native image even if PNG encoding throws — a ~2-4 MB bitmap
    // at pixelRatio 3 would otherwise leak on every failed capture.
    final byteData = await image
        .toByteData(format: ui.ImageByteFormat.png)
        .whenComplete(image.dispose);
    if (byteData == null) {
      throw StateError('Rank card capture produced no bytes');
    }

    final dir = await getTemporaryDirectory();
    final file = await File('${dir.path}/drillfit_rank.png')
        .writeAsBytes(byteData.buffer.asUint8List());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: 'My DrillFit rank 🎖️',
    );
  } finally {
    entry.remove();
  }
}

/// The branded, shareable rank image. Fixed width so it captures at a
/// predictable resolution; always dark so the shared PNG looks consistent
/// regardless of the user's theme.
class RankShareCard extends StatelessWidget {
  const RankShareCard({
    super.key,
    required this.rank,
    this.benchText,
    this.squatText,
  });

  final MilitaryRank rank;
  final String? benchText;
  final String? squatText;

  String? get _statsLine {
    final parts = <String>[
      if (benchText != null) 'Bench: $benchText',
      if (squatText != null) 'Squat: $squatText',
    ];
    return parts.isEmpty ? null : parts.join('   ·   ');
  }

  @override
  Widget build(BuildContext context) {
    final color = rank.color;
    final stats = _statsLine;

    return Container(
      width: 360,
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/app-icon.png', width: 26, height: 26),
              const SizedBox(width: 8),
              const Text(
                'DrillFit',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
            ),
            alignment: Alignment.center,
            child: RankInsignia(rank: rank, size: 86),
          ),
          const SizedBox(height: 16),
          Text(
            rank.displayName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 26,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Overall: ${rank.displayName} (E${rank.tier})',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          if (stats != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                stats,
                style: const TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'drillfit.app',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 12,
              letterSpacing: 1,
              color: color.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
