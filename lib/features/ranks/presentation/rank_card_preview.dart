import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../providers/unit_system_provider.dart';
import '../domain/military_ranks.dart';
import '../providers/rank_providers.dart';
import 'widgets/rank_badge.dart';

const _benchId = 'barbell_bench_press';
const _squatId = 'barbell_back_squat';
const _bg = Color(0xFF0E0E12);

/// Opens the rank-card preview with a fade transition. Replaces the old
/// straight-to-share-sheet flow — the user now sees the rendered card first.
void openRankCardPreview(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => const RankCardPreviewScreen(),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Full-screen preview of the user's rank card. Renders the card as a real
/// Flutter widget (so it always lays out correctly), then captures it from a
/// VISIBLE [RepaintBoundary] for sharing / saving — the previous off-screen
/// capture was what failed.
class RankCardPreviewScreen extends ConsumerStatefulWidget {
  const RankCardPreviewScreen({super.key});

  @override
  ConsumerState<RankCardPreviewScreen> createState() =>
      _RankCardPreviewScreenState();
}

class _RankCardPreviewScreenState extends ConsumerState<RankCardPreviewScreen> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  /// Captures the on-screen card boundary to PNG bytes at 3× for a crisp share.
  Future<Uint8List?> _capture() async {
    final boundary =
        _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<void> _share(MilitaryRank rank, String? statsLine) async {
    if (_busy) return;
    // Compute the iPad share origin synchronously (before any await).
    final box = context.findRenderObject() as RenderBox?;
    final origin = (box != null && box.hasSize)
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) {
        // Capture failed — fall back to plain text so the button still works.
        await Share.share(
          _plainSummary(rank, statsLine),
          subject: 'My DrillFit rank',
          sharePositionOrigin: origin,
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final file =
          await File('${dir.path}/drillfit_rank.png').writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'My DrillFit rank 🎖️',
        sharePositionOrigin: origin,
      );
    } catch (e, st) {
      AppLogger.error('Rank card share failed; sharing text instead',
          error: e, stack: st);
      try {
        await Share.share(_plainSummary(rank, statsLine),
            subject: 'My DrillFit rank');
      } catch (_) {
        if (mounted) {
          showCupertinoToast(context, "Couldn't share your rank card.");
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveToPhotos() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) throw StateError('Card capture produced no bytes');
      await Gal.putImageBytes(bytes, name: 'drillfit_rank');
      if (mounted) showCupertinoToast(context, 'Saved to Photos');
    } catch (e, st) {
      AppLogger.error('Save rank card to Photos failed', error: e, stack: st);
      if (mounted) {
        showCupertinoToast(context, "Couldn't save to Photos.");
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final async = ref.watch(rankCalculatorProvider);
    final units = ref.watch(unitSystemProvider);

    return ColoredBox(
      color: _bg,
      child: SafeArea(
        child: async.when(
          loading: () =>
              const Center(child: CupertinoActivityIndicator(color: Colors.white)),
          error: (_, _) => _MessageState(
            message: "Couldn't load your rank.",
            onClose: () => Navigator.of(context).maybePop(),
          ),
          data: (calc) {
            final rank = calc.overall;
            final hasData = calc.exerciseScores.isNotEmpty;
            final benchKg = calc.exerciseBestWeightKg[_benchId];
            final squatKg = calc.exerciseBestWeightKg[_squatId];
            final parts = <String>[
              if (benchKg != null)
                'Bench: ${UnitConverter.formatWeight(benchKg, units)}',
              if (squatKg != null)
                'Squat: ${UnitConverter.formatWeight(squatKg, units)}',
            ];
            final statsLine = parts.isEmpty ? null : parts.join('   ·   ');

            return Column(
              children: [
                // Close button row.
                Padding(
                  padding: const EdgeInsets.only(right: 6, top: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: CupertinoButton(
                      padding: const EdgeInsets.all(10),
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Icon(CupertinoIcons.xmark,
                          color: Colors.white,
                          size: 24,
                          semanticLabel: 'Close'),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // The wrapper is 1.12× the card width and 1.54× tall
                        // (card aspect 1.42 + 6% padding each side). Pick the
                        // largest card width that fits both axes so it never
                        // overflows on small screens.
                        final byWidth = (constraints.maxWidth - 16) / 1.12;
                        final byHeight = (constraints.maxHeight - 16) / 1.54;
                        final w = (byWidth < byHeight ? byWidth : byHeight)
                            .clamp(220.0, 360.0);
                        return RepaintBoundary(
                          key: _cardKey,
                          child: Container(
                            color: _bg,
                            padding: EdgeInsets.all(w * 0.06),
                            child: RankCardWidget(
                              rank: rank,
                              statsLine: statsLine,
                              hasData: hasData,
                              width: w,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _OutlinedButton(
                          label: 'Save to Photos',
                          palette: palette,
                          onPressed: _busy ? null : _saveToPhotos,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CupertinoButton(
                          color: palette.accent,
                          borderRadius: BorderRadius.circular(14),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          onPressed:
                              _busy ? null : () => _share(rank, statsLine),
                          child: _busy
                              ? const CupertinoActivityIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Share',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Plain-text rank summary used when the image can't be captured/shared.
String _plainSummary(MilitaryRank rank, String? statsLine) {
  final b = StringBuffer("I'm ${rank.displayName} (E${rank.tier}) on DrillFit 🎖️");
  if (statsLine != null) b.write('\n$statsLine');
  b.write('\ndrillfit.app');
  return b.toString();
}

// ─── The card widget ─────────────────────────────────────────────────────────

/// The shareable rank card, rendered as a real widget. Sizes scale off [width]
/// so it looks right on screen and stays crisp when captured at 3×.
class RankCardWidget extends StatelessWidget {
  const RankCardWidget({
    super.key,
    required this.rank,
    required this.statsLine,
    required this.hasData,
    this.width = 340,
  });

  final MilitaryRank rank;
  final String? statsLine;
  final bool hasData;
  final double width;

  @override
  Widget build(BuildContext context) {
    final color = rank.color;
    final discSize = width * 0.46;

    return Container(
      width: width,
      height: width * 1.42,
      padding: EdgeInsets.all(width * 0.07),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(width * 0.08),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Brand lockup.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(width * 0.022),
                child: Image.asset(
                  'assets/images/app-icon.png',
                  width: width * 0.1,
                  height: width * 0.1,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: width * 0.028),
              Text(
                'DrillFit',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: width * 0.062,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Insignia disc.
          Container(
            width: discSize,
            height: discSize,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
            ),
            alignment: Alignment.center,
            child: RankInsignia(rank: rank, size: discSize * 0.62),
          ),
          SizedBox(height: width * 0.05),
          // Rank name.
          Text(
            rank.displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: width * 0.11,
              height: 1.05,
              color: color,
            ),
          ),
          SizedBox(height: width * 0.015),
          Text(
            'Overall Strength Rank · E${rank.tier}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: width * 0.04,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          SizedBox(height: width * 0.04),
          // Stats / empty-state prompt.
          Text(
            hasData && statsLine != null
                ? statsLine!
                : (hasData
                    ? 'Keep logging lifts to fill out your card'
                    : 'Start training to earn your rank'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: width * 0.044,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          SizedBox(height: width * 0.04),
          Text(
            'drillfit.app',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: width * 0.036,
              letterSpacing: 1.5,
              color: color.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  const _OutlinedButton({
    required this.label,
    required this.palette,
    required this.onPressed,
  });

  final String label;
  final Palette palette;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Text(
            message,
            style: const TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 15,
              color: Colors.white70,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 6,
          child: CupertinoButton(
            padding: const EdgeInsets.all(10),
            onPressed: onClose,
            child: const Icon(CupertinoIcons.xmark,
                color: Colors.white, size: 24, semanticLabel: 'Close'),
          ),
        ),
      ],
    );
  }
}
