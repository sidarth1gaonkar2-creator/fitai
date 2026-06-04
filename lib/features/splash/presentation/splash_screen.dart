import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which startup phase failed, surfaced to the fatal-error screen.
enum StartupPhase { firebase, isar }

/// Result of background app initialization. Either [isReady] (carrying the
/// opened [Isar] + [SharedPreferences] + the resolved [isSignedIn] auth state)
/// or a failure with the offending [phase]. Produced by `main._bootstrap()` and
/// consumed by [SplashScreen].
class BootstrapResult {
  const BootstrapResult.ready(
    Isar this.isar,
    SharedPreferences this.prefs, {
    required this.isSignedIn,
  })  : phase = null,
        error = null,
        stack = null;

  const BootstrapResult.failed(StartupPhase this.phase, this.error, this.stack)
      : isar = null,
        prefs = null,
        isSignedIn = false;

  final Isar? isar;
  final SharedPreferences? prefs;
  final StartupPhase? phase;
  final Object? error;
  final StackTrace? stack;

  /// Whether Firebase reported a signed-in user during bootstrap. Used to pick
  /// the router's initial route so a signed-in user never sees the welcome
  /// screen, not even for a frame.
  final bool isSignedIn;

  bool get isReady => phase == null;
}

/// The dark background every launch starts on — matches the iOS
/// LaunchScreen.storyboard so there is no flash when Flutter takes over.
const splashBackground = Color(0xFF0E0E12);

/// DrillFit brand blue, used for the chevrons and dumbbell.
const _brandBlue = Color(0xFF0A84FF);

/// Per-chevron opacity, bottom (index 0) → top (index 4). Matches the app
/// icon's fade so the splash mark reads as the same logo.
const _chevronOpacities = <double>[1.0, 0.88, 0.76, 0.64, 0.52];

/// Minimal MaterialApp host that shows the animated [SplashScreen] while the
/// app initializes. Kept tiny and ProviderScope-free so it can render on the
/// very first frame — the real app (with ProviderScope) is swapped in by
/// [onReady] once initialization AND the intro animation have both finished.
class SplashApp extends StatelessWidget {
  const SplashApp({
    super.key,
    required this.bootstrap,
    required this.onReady,
  });

  final Future<BootstrapResult> bootstrap;
  final ValueChanged<BootstrapResult> onReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: splashBackground,
      ),
      home: SplashScreen(bootstrap: bootstrap, onReady: onReady),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.bootstrap,
    required this.onReady,
  });

  final Future<BootstrapResult> bootstrap;
  final ValueChanged<BootstrapResult> onReady;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Build-in (chevrons → dumbbell → text → tagline). Runs concurrently with
  // initialization; if init is slower it simply holds on the settled logo.
  late final AnimationController _intro;
  // Exit fade of the whole logo group, played once both are done so the
  // hand-off to the real app crossfades through the shared dark background.
  late final AnimationController _outro;
  // Pulsing wait-dot, only shown if bootstrap (incl. Firebase auth resolution)
  // outlasts the intro animation.
  late final AnimationController _dot;
  bool _showWaitDot = false;
  bool _bootstrapDone = false;

  @override
  void initState() {
    super.initState();
    _intro =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
    _outro =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _dot =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _run();
  }

  Future<void> _run() async {
    // Play the intro and wait for initialization — concurrently. We never
    // block the animation on init: the controller drives the UI thread while
    // the bootstrap future resolves off it. Critically we wait for BOTH the
    // intro AND bootstrap (which now includes the Firebase auth state) before
    // handing off, so the real app starts on the correct route with no flash.
    final intro = _intro.forward();
    // If the intro finishes while bootstrap is still pending, reveal a subtle
    // pulsing dot below the tagline so the held final frame doesn't read as a
    // freeze.
    unawaited(intro.then((_) {
      if (mounted && !_bootstrapDone) {
        setState(() => _showWaitDot = true);
        _dot.repeat(reverse: true);
      }
    }));

    final result = await widget.bootstrap;
    _bootstrapDone = true;
    if (mounted && _showWaitDot) {
      setState(() => _showWaitDot = false);
      _dot.stop();
    }

    await intro; // ensure the build-in finished before we exit
    if (!mounted) return;
    await _outro.forward();
    if (!mounted) return;
    widget.onReady(result);
  }

  @override
  void dispose() {
    _intro.dispose();
    _outro.dispose();
    _dot.dispose();
    super.dispose();
  }

  /// Eased progress of a sub-interval of [_intro], clamped to 0..1.
  double _seg(double v, double start, double end,
      [Curve curve = Curves.easeOut]) {
    if (end <= start) return v >= end ? 1 : 0;
    final t = ((v - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: splashBackground,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_intro, _outro, _dot]),
          builder: (context, _) {
            final v = _intro.value;

            // Whole icon scales 80% → 100% with a subtle overshoot.
            final groupScale = 0.8 + 0.2 * _seg(v, 0.0, 0.46, Curves.easeOutBack);

            // Chevrons stagger in bottom → top, 100ms apart, rising as they fade.
            final chevronOpacities = <double>[];
            final chevronSlides = <double>[];
            for (var i = 0; i < 5; i++) {
              final start = i * 0.075;
              final p = _seg(v, start, start + 0.23);
              chevronOpacities.add(_chevronOpacities[i] * p);
              chevronSlides.add((1 - p) * 6); // px, settles to 0
            }

            // Dumbbell last (≈200ms after the top chevron starts).
            final dumbbellOpacity = _seg(v, 0.44, 0.64);
            final textOpacity = _seg(v, 0.62, 0.82);
            final taglineOpacity = _seg(v, 0.80, 0.97);

            // Exit: fade the whole group out so the real app crossfades in.
            final groupOpacity = 1 - _outro.value;

            return Opacity(
              opacity: groupOpacity.clamp(0.0, 1.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: groupScale,
                    child: SizedBox(
                      width: 120,
                      height: 124,
                      child: CustomPaint(
                        painter: _SplashMarkPainter(
                          chevronOpacities: chevronOpacities,
                          chevronSlides: chevronSlides,
                          dumbbellOpacity: dumbbellOpacity,
                          color: _brandBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Opacity(
                    opacity: textOpacity,
                    child: const Text(
                      'DrillFit',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 28,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Opacity(
                    opacity: taglineOpacity,
                    child: const Text(
                      'Your Drill Sergeant',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                  // Pulsing wait-dot — only while bootstrap (incl. auth)
                  // outlasts the intro animation.
                  if (_showWaitDot) ...[
                    const SizedBox(height: 16),
                    Opacity(
                      opacity: 0.3 + 0.7 * _dot.value,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF8E8E93),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Draws the DrillFit mark: five stacked sergeant chevrons (each a thick ^
/// stroke) above a small dumbbell, all in brand blue. Every chevron's opacity
/// and vertical offset is supplied per-frame so they can animate independently.
class _SplashMarkPainter extends CustomPainter {
  _SplashMarkPainter({
    required this.chevronOpacities,
    required this.chevronSlides,
    required this.dumbbellOpacity,
    required this.color,
  });

  final List<double> chevronOpacities;
  final List<double> chevronSlides;
  final double dumbbellOpacity;
  final Color color;

  // Geometry (in the 120×124 canvas).
  static const double _cx = 60; // horizontal centre
  static const double _halfWidth = 38; // chevron arm half-span
  static const double _armDrop = 22; // vertical drop from peak to arm tips
  static const double _thickness = 12; // chevron stroke width
  static const double _step = 15; // vertical gap between chevron peaks
  static const double _bottomPeakY = 70; // peak Y of the bottom chevron

  @override
  void paint(Canvas canvas, Size size) {
    // Chevrons, bottom (i=0) → top (i=4).
    for (var i = 0; i < 5; i++) {
      final opacity = i < chevronOpacities.length ? chevronOpacities[i] : 0.0;
      if (opacity <= 0) continue;
      final slide = i < chevronSlides.length ? chevronSlides[i] : 0.0;
      final peakY = _bottomPeakY - i * _step + slide;

      final path = Path()
        ..moveTo(_cx - _halfWidth, peakY + _armDrop)
        ..lineTo(_cx, peakY)
        ..lineTo(_cx + _halfWidth, peakY + _armDrop);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = _thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, paint);
    }

    // Dumbbell below the chevrons — two plates + a connecting bar.
    if (dumbbellOpacity > 0) {
      final paint = Paint()
        ..color = color.withValues(alpha: dumbbellOpacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      const plateTop = 100.0;
      const plateHeight = 22.0;
      // Left plate.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(40, plateTop, 9, plateHeight),
          const Radius.circular(2.5),
        ),
        paint,
      );
      // Right plate.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(71, plateTop, 9, plateHeight),
          const Radius.circular(2.5),
        ),
        paint,
      );
      // Connecting bar.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(47, plateTop + plateHeight / 2 - 3, 26, 6),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SplashMarkPainter old) =>
      old.dumbbellOpacity != dumbbellOpacity ||
      old.chevronOpacities != chevronOpacities ||
      old.chevronSlides != chevronSlides;
}
