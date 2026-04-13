import 'dart:math';

import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_colors.dart';

/// Full-screen confetti celebration overlay shown when a new PR is set.
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
          // Confetti particles
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
          // PR text overlay
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final opacity = _controller.value < 0.1
                    ? _controller.value / 0.1
                    : _controller.value > 0.8
                        ? (1.0 - _controller.value) / 0.2
                        : 1.0;
                final scale = _controller.value < 0.15
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
                  color: AppColors.darkSurface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.warning, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🏆',
                      style: TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'NEW PERSONAL RECORD!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AppColors.warning,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.exerciseNames.map((name) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'LeagueSpartan',
                              fontSize: 16,
                              color: CupertinoColors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to continue',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 13,
                        color:
                            CupertinoColors.white.withValues(alpha: 0.5),
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

  static const _colors = [
    AppColors.warning,
    AppColors.purple,
    AppColors.success,
    Color(0xFFFF453A),
    Color(0xFFFF9F0A),
    Color(0xFF64D2FF),
    CupertinoColors.white,
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
