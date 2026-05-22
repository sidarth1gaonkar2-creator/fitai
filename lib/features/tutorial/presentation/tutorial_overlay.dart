import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/tutorial_controller.dart';
import '../providers/tutorial_providers.dart';

/// Top-level overlay host. Drop this once at the root of the widget tree
/// (typically inside the app's `builder`); it self-gates on the tutorial
/// being active so the rest of the time it costs nothing.
///
/// Responsibilities:
///   * Watch the tutorial controller and react to step transitions.
///   * Measure the current step's target widget after the next frame (so a
///     route change has time to lay out the new tree).
///   * Render the dim + spotlight + tooltip stack.
class TutorialOverlayHost extends ConsumerStatefulWidget {
  const TutorialOverlayHost({super.key});

  @override
  ConsumerState<TutorialOverlayHost> createState() =>
      _TutorialOverlayHostState();
}

class _TutorialOverlayHostState extends ConsumerState<TutorialOverlayHost> {
  Rect? _spotlightRect;
  int _lastMeasuredIndex = -1;
  bool _lastActive = false;
  int _retryCount = 0;
  bool _measureScheduled = false;

  static const _maxRetries = 20; // ~333ms at 60fps — covers route transitions.

  void _scheduleMeasure({bool reset = false}) {
    if (reset) {
      _retryCount = 0;
      _spotlightRect = null;
    }
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (mounted) _measure();
    });
  }

  void _measure() {
    final controller = ref.read(tutorialControllerProvider);
    final step = controller.currentStep;
    if (step == null || !controller.isActive) return;
    final ctx = step.targetKey.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      // Target not yet attached (likely mid-route-transition) — retry shortly.
      if (_retryCount++ < _maxRetries) {
        _scheduleMeasure();
      }
      return;
    }
    final position = box.localToGlobal(Offset.zero);
    final rect = Rect.fromLTWH(
      position.dx,
      position.dy,
      box.size.width,
      box.size.height,
    );
    if (rect != _spotlightRect) {
      setState(() => _spotlightRect = rect);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(tutorialControllerProvider);

    // Detect transitions and reset the measurement state. The ChangeNotifier
    // shares the same instance across rebuilds, so we can't diff via prev/next
    // in ref.listen — track our own copies of the relevant fields.
    final stepChanged = controller.currentIndex != _lastMeasuredIndex;
    final activeChanged = controller.isActive != _lastActive;
    if (stepChanged || activeChanged) {
      _lastMeasuredIndex = controller.currentIndex;
      _lastActive = controller.isActive;
      if (controller.isActive) {
        _scheduleMeasure(reset: true);
      }
    }

    if (!controller.isActive) return const SizedBox.shrink();
    final step = controller.currentStep;
    if (step == null) return const SizedBox.shrink();

    if (_spotlightRect == null) {
      // While we're still waiting for the target to lay out, render nothing.
      // Better a blank frame than a full-screen dim with no cutout.
      _scheduleMeasure();
      return const SizedBox.shrink();
    }

    return TutorialOverlay(
      spotlightRect: _spotlightRect!.inflate(8),
      title: step.title,
      description: step.description,
      buttonText: controller.currentIndex == controller.totalSteps - 1
          ? 'Get Started!'
          : 'Next',
      onNext: () {
        HapticFeedback.selectionClick();
        controller.next();
      },
      onSkip: () {
        HapticFeedback.lightImpact();
        controller.skip();
      },
      currentStep: controller.currentIndex + 1,
      totalSteps: controller.totalSteps,
      shape: step.shape,
    );
  }
}

/// The visual layer: dim background with a cutout at [spotlightRect], a
/// pulsing glow, and an auto-positioned tooltip card. Doesn't talk to the
/// controller — caller wires [onNext]/[onSkip] from outside so this widget
/// stays unit-testable.
class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({
    super.key,
    required this.spotlightRect,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onNext,
    required this.onSkip,
    required this.currentStep,
    required this.totalSteps,
    required this.shape,
  });

  final Rect spotlightRect;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final int currentStep;
  final int totalSteps;
  final SpotlightShape shape;

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _fade;
  late final AnimationController _spotlightMove;

  Rect _animatedRect = Rect.zero;
  Rect _moveFrom = Rect.zero;
  Rect _moveTo = Rect.zero;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _spotlightMove = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(_onMoveTick);
    _animatedRect = widget.spotlightRect;
    _moveFrom = widget.spotlightRect;
    _moveTo = widget.spotlightRect;
  }

  void _onMoveTick() {
    final t = Curves.easeInOutCubic.transform(_spotlightMove.value);
    setState(() {
      _animatedRect = Rect.lerp(_moveFrom, _moveTo, t)!;
    });
  }

  @override
  void didUpdateWidget(TutorialOverlay old) {
    super.didUpdateWidget(old);
    if (old.spotlightRect != widget.spotlightRect) {
      _moveFrom = _animatedRect;
      _moveTo = widget.spotlightRect;
      _spotlightMove
        ..stop()
        ..reset()
        ..forward();
    }
    // Quick fade-in on tooltip when the step title changes.
    if (old.title != widget.title) {
      _fade.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _fade.dispose();
    _spotlightMove.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final accent = AppColors.dark.accent;
    final rect = _animatedRect;

    // Tooltip placement: if the spotlight sits above the vertical centre,
    // show the tooltip below it; otherwise show it above. Falls back to
    // pinning to the safe edge when there isn't enough room either way.
    final showBelow = rect.center.dy < size.height * 0.55;
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Dim + cutout
        Positioned.fill(
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulse, _fade]),
            builder: (context, _) {
              return Opacity(
                opacity: _fade.value.clamp(0.0, 1.0),
                child: CustomPaint(
                  painter: SpotlightPainter(
                    spotlightRect: rect,
                    shape: widget.shape,
                    pulse: _pulse.value,
                    accent: accent,
                  ),
                ),
              );
            },
          ),
        ),

        // Skip button — top-right
        Positioned(
          top: topPad + 12,
          right: 12,
          child: SafeArea(
            child: TextButton(
              onPressed: widget.onSkip,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.75),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),

        // Tooltip card — positioned above or below the spotlight.
        _TooltipPositioner(
          spotlightRect: rect,
          showBelow: showBelow,
          screenSize: size,
          safeTop: topPad,
          safeBottom: bottomPad,
          child: FadeTransition(
            opacity: _fade,
            child: _SlideUp(
              animation: _fade,
              child: _TutorialTooltip(
                title: widget.title,
                description: widget.description,
                buttonText: widget.buttonText,
                onNext: widget.onNext,
                currentStep: widget.currentStep,
                totalSteps: widget.totalSteps,
                accent: accent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Picks a vertical position for the tooltip card relative to the spotlight.
/// Anchors the card 16px away from the cutout, and falls back to pinning to
/// the safe edge when the natural position would clip off-screen.
class _TooltipPositioner extends StatelessWidget {
  const _TooltipPositioner({
    required this.spotlightRect,
    required this.showBelow,
    required this.screenSize,
    required this.safeTop,
    required this.safeBottom,
    required this.child,
  });

  final Rect spotlightRect;
  final bool showBelow;
  final Size screenSize;
  final double safeTop;
  final double safeBottom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const tooltipMaxWidth = 320.0;
    final left = math.max(
      16.0,
      math.min(
        screenSize.width - tooltipMaxWidth - 16.0,
        spotlightRect.center.dx - tooltipMaxWidth / 2,
      ),
    );

    if (showBelow) {
      final top = math.min(
        screenSize.height - safeBottom - 240,
        spotlightRect.bottom + 16,
      );
      return Positioned(
        left: left,
        top: top,
        width: tooltipMaxWidth,
        child: child,
      );
    }
    final bottom = math.min(
      screenSize.height - safeTop - 240,
      screenSize.height - spotlightRect.top + 16,
    );
    return Positioned(
      left: left,
      bottom: bottom,
      width: tooltipMaxWidth,
      child: child,
    );
  }
}

class _SlideUp extends StatelessWidget {
  const _SlideUp({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, c) {
        final dy = (1 - animation.value) * 8.0;
        return Transform.translate(offset: Offset(0, dy), child: c);
      },
      child: child,
    );
  }
}

class _TutorialTooltip extends StatelessWidget {
  const _TutorialTooltip({
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onNext,
    required this.currentStep,
    required this.totalSteps,
    required this.accent,
  });

  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onNext;
  final int currentStep;
  final int totalSteps;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _StepDots(
                  current: currentStep,
                  total: totalSteps,
                  accent: accent,
                ),
                const Spacer(),
                _TooltipButton(
                  label: buttonText,
                  onPressed: onNext,
                  accent: accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({
    required this.current,
    required this.total,
    required this.accent,
  });

  final int current;
  final int total;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    // Cap the rendered dots for very long tutorials. 13+ still fits in the
    // 320px-wide tooltip; if we ever exceed ~16 we'll switch to a "3 / N"
    // counter to keep the row from wrapping.
    const maxDots = 16;
    final shown = math.min(total, maxDots);
    return Row(
      children: List.generate(shown, (i) {
        final isCurrent = i == current - 1;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 5),
          width: isCurrent ? 8 : 6,
          height: isCurrent ? 8 : 6,
          decoration: BoxDecoration(
            color: isCurrent
                ? accent
                : Colors.white.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _TooltipButton extends StatelessWidget {
  const _TooltipButton({
    required this.label,
    required this.onPressed,
    required this.accent,
  });

  final String label;
  final VoidCallback onPressed;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a full-screen scrim with a [shape]-shaped cutout at [spotlightRect],
/// then draws a pulsing accent-coloured glow around the cutout. The cutout is
/// produced by [Path.combine] with [PathOperation.difference] so the rest of
/// the UI shows through unmodified — no blur, no tint.
class SpotlightPainter extends CustomPainter {
  SpotlightPainter({
    required this.spotlightRect,
    required this.shape,
    required this.pulse,
    required this.accent,
  });

  final Rect spotlightRect;
  final SpotlightShape shape;
  final double pulse;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path();
    if (shape == SpotlightShape.circle) {
      final radius = spotlightRect.longestSide / 2;
      cutoutPath.addOval(
        Rect.fromCircle(center: spotlightRect.center, radius: radius),
      );
    } else {
      cutoutPath.addRRect(
        RRect.fromRectAndRadius(spotlightRect, const Radius.circular(14)),
      );
    }

    final combined =
        Path.combine(PathOperation.difference, overlayPath, cutoutPath);

    canvas.drawPath(
      combined,
      Paint()..color = Colors.black.withValues(alpha: 0.75),
    );

    // Pulsing glow ring around the cutout. Stroke width and blur grow
    // sinusoidally with [pulse] to suggest a heartbeat without being noisy.
    final glow = Paint()
      ..color = accent.withValues(alpha: 0.45 + 0.25 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 + 1.5 * pulse
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 3 * pulse);
    if (shape == SpotlightShape.circle) {
      canvas.drawCircle(
        spotlightRect.center,
        spotlightRect.longestSide / 2,
        glow,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(spotlightRect, const Radius.circular(14)),
        glow,
      );
    }
  }

  @override
  bool shouldRepaint(SpotlightPainter old) =>
      old.spotlightRect != spotlightRect ||
      old.shape != shape ||
      old.pulse != pulse ||
      old.accent != accent;
}
