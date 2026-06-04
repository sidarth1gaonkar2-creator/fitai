import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/drill_sergeant.dart';
import '../../domain/military_ranks.dart';
import 'rank_badge.dart';

/// Full-screen promotion celebration shown when the user's overall rank goes
/// up. The new rank's insignia bounces in (in the rank's colour), "PROMOTED!",
/// the new rank name, a drill-sergeant line, and chevron particles floating up.
/// Fires [HapticFeedback.heavyImpact] on appear. Self-contained — no packages.
class RankCelebrationOverlay extends StatefulWidget {
  const RankCelebrationOverlay({
    super.key,
    required this.rank,
    required this.onDismiss,
  });

  final MilitaryRank rank;
  final VoidCallback onDismiss;

  @override
  State<RankCelebrationOverlay> createState() => _RankCelebrationOverlayState();
}

class _RankCelebrationOverlayState extends State<RankCelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _intro; // one-shot: insignia bounce + fade-in
  late final AnimationController _particles; // looping chevron rise
  late final List<_Chevron> _chevrons;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _particles = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    final rng = Random();
    _chevrons = List.generate(30, (_) => _Chevron(rng));
  }

  @override
  void dispose() {
    _intro.dispose();
    _particles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rank = widget.rank;
    final color = rank.color;

    return Material(
      color: Colors.black.withValues(alpha: 0.88),
      child: Stack(
        children: [
          // Floating chevron particles in the rank colour.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particles,
              builder: (_, _) => CustomPaint(
                painter: _ChevronParticlePainter(
                  progress: _particles.value,
                  chevrons: _chevrons,
                  color: color,
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: AnimatedBuilder(
                animation: _intro,
                builder: (context, _) {
                  final t = _intro.value;
                  final insigniaScale = Curves.elasticOut.transform(
                    t.clamp(0.0, 1.0),
                  );
                  final contentOpacity = ((t - 0.35) / 0.4).clamp(0.0, 1.0);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: insigniaScale,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.withValues(alpha: 0.6),
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: RankInsignia(rank: rank, size: 96),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Opacity(
                        opacity: contentOpacity,
                        child: Column(
                          children: [
                            Text(
                              'PROMOTED!',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w800,
                                fontSize: 30,
                                letterSpacing: 2,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You are now a ${rank.displayName.toUpperCase()}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${rank.abbreviation} · E${rank.tier}',
                              style: TextStyle(
                                fontFamily: 'LeagueSpartan',
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 44),
                              child: Text(
                                promotionCelebrationLine(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'LeagueSpartan',
                                  fontSize: 15,
                                  height: 1.35,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            CupertinoButtonLike(
                              color: color,
                              onPressed: widget.onDismiss,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small filled "Dismiss" button. Kept as a Material widget so the overlay
/// doesn't need a Cupertino import just for one button.
class CupertinoButtonLike extends StatelessWidget {
  const CupertinoButtonLike({
    super.key,
    required this.color,
    required this.onPressed,
  });

  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 44, vertical: 13),
          child: Text(
            'Dismiss',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// One floating chevron particle — randomised start column, phase and speed.
class _Chevron {
  _Chevron(Random r)
      : x = r.nextDouble(),
        phase = r.nextDouble(),
        speed = 0.6 + r.nextDouble() * 0.8,
        size = 7 + r.nextDouble() * 11,
        drift = (r.nextDouble() - 0.5) * 0.12;

  final double x; // base column, 0..1
  final double phase; // cycle offset, 0..1
  final double speed;
  final double size;
  final double drift;
}

class _ChevronParticlePainter extends CustomPainter {
  _ChevronParticlePainter({
    required this.progress,
    required this.chevrons,
    required this.color,
  });

  final double progress;
  final List<_Chevron> chevrons;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in chevrons) {
      final p = (progress * c.speed + c.phase) % 1.0; // 0..1 rise cycle
      final y = (1.1 - p * 1.2) * size.height; // bottom → top
      final x = (c.x + sin(p * 2 * pi + c.phase * 2 * pi) * c.drift) * size.width;
      final opacity = (sin(p * pi)).clamp(0.0, 1.0) * 0.7; // fade in then out
      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.4, c.size * 0.2)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final w = c.size;
      final h = c.size * 0.6;
      final path = Path()
        ..moveTo(x - w / 2, y + h / 2)
        ..lineTo(x, y - h / 2)
        ..lineTo(x + w / 2, y + h / 2);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ChevronParticlePainter old) =>
      old.progress != progress || old.color != color;
}
