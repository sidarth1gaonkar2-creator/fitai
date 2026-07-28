import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../core/motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';

/// Field Manual replacement for the Apple-style calorie ring: a tick-marked
/// instrument gauge (240° arc) with mono numerals. Tapping flips between
/// consumed and net-remaining views when burned data is present — same
/// behavior the old ring had.
class KcalGauge extends StatefulWidget {
  const KcalGauge({
    super.key,
    required this.consumed,
    required this.target,
    this.burned = 0,
    this.size = 224,
  });

  final double consumed;
  final double target;
  final double burned;
  final double size;

  @override
  State<KcalGauge> createState() => _KcalGaugeState();
}

class _KcalGaugeState extends State<KcalGauge> {
  bool _showNet = false;

  bool get _canFlip => widget.burned > 0;

  @override
  Widget build(BuildContext context) {
    final target = widget.target <= 0 ? 1.0 : widget.target;

    final gauge = SizedBox(
      width: widget.size,
      // The 240° arc leaves the bottom open; height is less than a full circle.
      height: widget.size * 0.78,
      // One animated value drives the arc AND the numeral, so the sweep and
      // the count-up can never drift apart. Retargets from the current
      // position on value change; sweeps from zero only on first build.
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: widget.consumed),
        duration: Motion.meterDurationOf(context),
        curve: Motion.meterCurve,
        builder: (context, consumed, _) {
          final fraction = (consumed / target).clamp(0.0, 1.0).toDouble();
          final String bigNumber;
          final String subLabel;
          if (_showNet && _canFlip) {
            final remaining = (target - consumed + widget.burned).round();
            bigNumber = '$remaining';
            subLabel = 'KCAL REMAINING';
          } else {
            bigNumber = '${consumed.round()}';
            subLabel = consumed > target
                ? 'OVER BY ${(consumed - target).round()}'
                : 'OF ${target.round()} KCAL';
          }
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GaugePainter(
                    fraction: fraction,
                    // The live accent sweep — brass on the default issue.
                    accent: AppColors.of(context).accent,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: widget.size * 0.08),
                // Clamp (not disable) Dynamic Type inside the fixed-size tick
                // ring so AX text sizes can't collide with the arc. The
                // Semantics label below carries the full-size reading.
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        bigNumber,
                        style: FieldManual.readout(fontSize: 34),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subLabel,
                        style: FieldManual.label(fontSize: 10),
                      ),
                      if (_canFlip) ...[
                        const SizedBox(height: 4),
                        Icon(
                          CupertinoIcons.arrow_2_squarepath,
                          size: 12,
                          color: FieldManual.olive,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return Semantics(
      label: _showNet && _canFlip
          ? '${(target - widget.consumed + widget.burned).round()} '
              'calories remaining today'
          : '${widget.consumed.round()} of ${target.round()} calories eaten',
      button: _canFlip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _canFlip
            ? () {
                HapticFeedback.selectionClick();
                setState(() => _showNet = !_showNet);
              }
            : null,
        child: gauge,
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.fraction, required this.accent});

  final double fraction;
  final Color accent;

  // 240° arc, opening at the bottom: 150° → 390°.
  static final _start = _rad(150);
  static final _sweep = _rad(240);

  static double _rad(double deg) => deg * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.62);
    final radius = math.min(size.width, size.height * 1.28) / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = FieldManual.hairlineStrong;
    canvas.drawArc(rect, _start, _sweep, false, track);

    // Tick marks: minor every 5%, major every 25%. Bone at low alpha —
    // instrument etching, not decoration.
    final minorTick = Paint()
      ..strokeWidth = 1.2
      ..color = FieldManual.bone.withValues(alpha: 0.35);
    final majorTick = Paint()
      ..strokeWidth = 1.6
      ..color = FieldManual.bone.withValues(alpha: 0.65);
    for (var i = 0; i <= 20; i++) {
      final isMajor = i % 5 == 0;
      final angle = _start + _sweep * (i / 20);
      final outer = radius + 8;
      final inner = outer + (isMajor ? 9 : 5);
      final from = center + Offset(math.cos(angle), math.sin(angle)) * outer;
      final to = center + Offset(math.cos(angle), math.sin(angle)) * inner;
      canvas.drawLine(from, to, isMajor ? majorTick : minorTick);
    }

    // Progress arc — the accent needle-sweep (brass on the default issue).
    if (fraction > 0) {
      final progress = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = accent;
      canvas.drawArc(rect, _start, _sweep * fraction, false, progress);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.accent != accent;
}
