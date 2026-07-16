import 'dart:math';

import 'package:flutter/cupertino.dart';

/// Full-screen PR celebration — a Field Manual ceremony (DESIGN.md): ink
/// scrim, brass-family confetti, Oswald bark, mono designations. Loud and
/// earned; honors Reduce Motion with a static card and no particle storm.
/// Uses a custom painter with animated particles — no external package needed.
class PRConfettiOverlay extends StatefulWidget {
  const PRConfettiOverlay({
    super.key,
    required this.exerciseNames,
    required this.onDismiss,
  });

  final List<String> exerciseNames;
  final VoidCallback onDismiss;

  @override
  State<PRConfettiOverlay> createState() => _PRConfettiOverlayState();
}

class _PRConfettiOverlayState extends State<PRConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiParticle> _particles;
  final _random = Random();
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _particles = List.generate(80, (_) => _ConfettiParticle(_random));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: the ceremony holds as a still card (no confetti, no
    // scale-in) and dismisses on tap only — no 3-second race.
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _controller.stop();
      _controller.value = 0.5; // fully-visible plateau of the fade curve
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Stack(
        children: [
          // Confetti particles (off under Reduce Motion).
          if (!_reduceMotion)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  size: MediaQuery.sizeOf(context),
                  painter: _ConfettiPainter(
                    progress: _controller.value,
                    particles: _particles,
                  ),
                );
              },
            ),
          // PR card
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final opacity = _controller.value < 0.1
                    ? _controller.value / 0.1
                    : _controller.value > 0.8
                        ? (1.0 - _controller.value) / 0.2
                        : 1.0;
                final scale = _reduceMotion
                    ? 1.0
                    : _controller.value < 0.15
                        ? 0.5 + (_controller.value / 0.15) * 0.5
                        : 1.0;
                return Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF21241F) // field
                      .withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFC8A24B), // brass — earned light
                    width: 2,
                  ),
                  // Ceremony glow: brief theatrical brass bloom.
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC8A24B).withValues(alpha: 0.30),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.bolt_fill,
                      size: 44,
                      color: Color(0xFFC8A24B),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'NEW PERSONAL RECORD',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontVariations: [FontVariation('wght', 700)],
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        height: 1.05,
                        color: Color(0xFFC8A24B), // brass
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...widget.exerciseNames.map((name) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            name.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontVariations: [FontVariation('wght', 700)],
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 1,
                              color: Color(0xFFE8E4D8), // bone
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap to continue',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFFCDC8BA), // muted bone
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiParticle {
  _ConfettiParticle(Random r)
      : x = r.nextDouble(),
        speed = 0.3 + r.nextDouble() * 0.7,
        drift = (r.nextDouble() - 0.5) * 0.3,
        size = 4 + r.nextDouble() * 6,
        rotation = r.nextDouble() * 6.28,
        rotationSpeed = (r.nextDouble() - 0.5) * 4,
        color = _colors[r.nextInt(_colors.length)];

  final double x;
  final double speed;
  final double drift;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final Color color;

  // Field Manual ceremony palette: brass family + bone, one alert flash.
  static const _colors = [
    Color(0xFFC8A24B), // brass
    Color(0xFFE0C27E), // light brass
    Color(0xFFA38443), // brass pressed
    Color(0xFFE8E4D8), // bone
    Color(0xFFCDC8BA), // muted bone
    Color(0xFFC24A38), // alert — the occasional stamp
  ];
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.particles});

  final double progress;
  final List<_ConfettiParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = -20 + progress * p.speed * (size.height + 40);
      final x = p.x * size.width + sin(progress * 6 + p.drift * 10) * 30;
      final opacity = progress > 0.7 ? (1.0 - progress) / 0.3 : 1.0;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * p.rotationSpeed * 6.28);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
