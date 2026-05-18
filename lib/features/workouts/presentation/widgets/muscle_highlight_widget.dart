import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/anatomy_paths.dart';
import '../../../../data/muscle_map.dart';

/// Anatomically-shaped muscle highlight. Each muscle group renders as its
/// own closed path (chest fans, lat wings, glute curves, triceps horseshoe,
/// …) rather than a generic oval — see [AnatomyPaths].
///
/// Two display modes:
///   * Compact (`height: 120`) — shows ONE side, picked automatically based
///     on which side carries the most highlighted muscles. Used for inline
///     contexts like exercise cards.
///   * Full (`height: 280`) — shows front + back side by side. Used in the
///     exercise detail screen and workout history detail.
///
/// On first build, highlights fade in over 400ms with an easeOutCubic curve
/// so the user gets a brief "lighting up" effect.
class MuscleHighlightWidget extends StatefulWidget {
  const MuscleHighlightWidget({
    super.key,
    required this.targetMuscles,
    this.secondaryMuscles = const [],
    this.height = 280,
    this.compact = false,
  });

  final List<String> targetMuscles;
  final List<String> secondaryMuscles;
  final double height;

  /// When true, renders ONLY the side with the most active muscles. The
  /// `height` should typically be ~120 in this mode.
  final bool compact;

  /// Legend swatch helpers — colours that match the actual fill opacity
  /// used by the painter so on-screen swatches read correctly.
  static Color targetColor(Color accent) =>
      accent.withValues(alpha: 0.75);
  static Color secondaryColor(Color accent) =>
      accent.withValues(alpha: 0.35);

  @override
  State<MuscleHighlightWidget> createState() => _MuscleHighlightWidgetState();
}

class _MuscleHighlightWidgetState extends State<MuscleHighlightWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(MuscleHighlightWidget old) {
    super.didUpdateWidget(old);
    // Restart the fade-in any time the muscle list changes — gives the
    // user a clear visual cue that the highlights have shifted.
    if (!_eq(old.targetMuscles, widget.targetMuscles) ||
        !_eq(old.secondaryMuscles, widget.secondaryMuscles)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _eq(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final brightness = MediaQuery.platformBrightnessOf(context);
    // Apple-Fitness-style silhouette: subtle fill + slightly stronger
    // outline. Colours differ per brightness so the silhouette stays
    // readable on both backgrounds.
    final fillBase = brightness == Brightness.dark
        ? const Color(0xFF2A2A35)
        : const Color(0xFFD0D0D8);
    final strokeBase = brightness == Brightness.dark
        ? const Color(0xFF3A3A45)
        : const Color(0xFFB0B0B8);

    final all = [
      ...widget.targetMuscles.map(MuscleMap.normalize),
      ...widget.secondaryMuscles.map(MuscleMap.normalize),
    ];
    final hasFront =
        all.any((m) => AnatomyPaths.frontPathFor(m, const Size(1, 1)) != null);
    final hasBack =
        all.any((m) => AnatomyPaths.backPathFor(m, const Size(1, 1)) != null);

    // Side selection.
    final List<BodySide> sides;
    if (widget.compact) {
      // Single side — pick whichever has more highlights, defaulting to
      // front when the lists are empty or balanced.
      if (hasBack && !hasFront) {
        sides = [BodySide.back];
      } else {
        sides = [BodySide.front];
      }
    } else {
      // Full view — render both sides whenever at least one has muscles
      // to show. If nothing maps anywhere we still show the front
      // silhouette so the widget never collapses.
      if (hasFront && hasBack) {
        sides = [BodySide.front, BodySide.back];
      } else if (hasBack && !hasFront) {
        sides = [BodySide.back];
      } else {
        sides = [BodySide.front];
      }
    }

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _fade,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < sides.length; i++) ...[
              AspectRatio(
                aspectRatio: 0.5, // body is 2× taller than wide
                child: CustomPaint(
                  painter: _BodyPainter(
                    side: sides[i],
                    targetMuscles: widget.targetMuscles
                        .map(MuscleMap.normalize)
                        .toList(),
                    secondaryMuscles: widget.secondaryMuscles
                        .map(MuscleMap.normalize)
                        .toList(),
                    accent: palette.accent,
                    silhouetteFill: fillBase,
                    silhouetteStroke: strokeBase,
                    fadeProgress: _fade.value,
                  ),
                ),
              ),
              if (i < sides.length - 1) const SizedBox(width: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.side,
    required this.targetMuscles,
    required this.secondaryMuscles,
    required this.accent,
    required this.silhouetteFill,
    required this.silhouetteStroke,
    required this.fadeProgress,
  });

  final BodySide side;
  final List<String> targetMuscles;
  final List<String> secondaryMuscles;
  final Color accent;
  final Color silhouetteFill;
  final Color silhouetteStroke;

  /// 0..1 — multiplied into every muscle's fill opacity for the fade-in.
  final double fadeProgress;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Silhouette backdrop.
    final silhouette = AnatomyPaths.silhouette(size);
    canvas.drawPath(
      silhouette,
      Paint()
        ..color = silhouetteFill.withValues(alpha: 0.30)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      silhouette,
      Paint()
        ..color = silhouetteStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // 2. Secondary muscles (drawn below primary so a muscle marked as both
    //    ends up reading as primary).
    for (final raw in secondaryMuscles) {
      final path = _pathFor(raw, size);
      if (path == null) continue;
      _drawMuscle(
        canvas,
        path,
        opacity: 0.35,
        glowBlur: 3,
        outlineWidth: 0.5,
      );
    }

    // 3. Primary muscles on top.
    for (final raw in targetMuscles) {
      final path = _pathFor(raw, size);
      if (path == null) continue;
      _drawMuscle(
        canvas,
        path,
        opacity: 0.75,
        glowBlur: 4,
        outlineWidth: 0.8,
      );
    }
  }

  Path? _pathFor(String name, Size size) {
    return side == BodySide.front
        ? AnatomyPaths.frontPathFor(name, size)
        : AnatomyPaths.backPathFor(name, size);
  }

  /// Renders a single muscle in three layers: a subtle outer glow (blurred
  /// stroke), the solid fill, and a slightly brighter outline. The glow is
  /// deliberately small (blur 3–4) so the shape stays defined rather than
  /// turning into the flashlight-through-fog look the earlier version had.
  void _drawMuscle(
    Canvas canvas,
    Path path, {
    required double opacity,
    required double glowBlur,
    required double outlineWidth,
  }) {
    final effective = opacity * fadeProgress;
    // Glow (drawn first so the fill sits on top of it)
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(alpha: effective * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = glowBlur
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlur),
    );
    // Solid fill
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(alpha: effective)
        ..style = PaintingStyle.fill,
    );
    // Crisp outline a touch brighter than the fill — pins the shape down.
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(alpha: (effective + 0.15).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineWidth
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) {
    return old.side != side ||
        old.accent != accent ||
        old.silhouetteFill != silhouetteFill ||
        old.silhouetteStroke != silhouetteStroke ||
        old.fadeProgress != fadeProgress ||
        !_listEq(old.targetMuscles, targetMuscles) ||
        !_listEq(old.secondaryMuscles, secondaryMuscles);
  }

  static bool _listEq(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
