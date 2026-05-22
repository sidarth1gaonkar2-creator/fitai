import 'package:flutter/material.dart';

import '../../../../data/muscle_map.dart';

/// Renders a body silhouette with the target muscle group highlighted using
/// pre-rendered PNGs at `assets/images/anatomy/` (dark) and
/// `assets/images/anatomy/light/` (light). Each PNG contains the full body
/// silhouette plus its highlighted muscle baked in.
///
/// Names are resolved through [MuscleMap.normalize] and a thin canonical-to-
/// filename mapping; if the supplied muscle has no PNG, we fall back to the
/// front-chest sheet so the widget never collapses.
///
/// Two display modes:
///   * Compact (`height: 120`) — single PNG (best primary muscle wins).
///   * Full   (`height: 280`) — front + back side by side when both have hits.
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
  final bool compact;

  // Compensation for PNG misalignment (front body sits lower than back).
  // Front center_y ≈ 230 vs back center_y ≈ 198 in the 470px canvas — back
  // sits ~32px higher, so we split the diff: nudge front up, back down. These
  // can be set to 0 when PNGs are re-exported with matching body positions.
  static const double _frontShiftPx = -16.0; // shift front UP
  static const double _backShiftPx = 16.0; // shift back DOWN

  /// Legend swatch helpers — used to draw the colour key next to the figure.
  static Color targetColor(Color accent) => accent.withValues(alpha: 0.75);
  static Color secondaryColor(Color accent) => accent.withValues(alpha: 0.35);

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

  bool _isBackSheet(String sheet) => sheet.startsWith('back-');

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final dir = brightness == Brightness.light
        ? 'assets/images/anatomy/light'
        : 'assets/images/anatomy';

    final frontSheet = _AnatomySheets.frontFor(widget.targetMuscles);
    final backSheet = _AnatomySheets.backFor(widget.targetMuscles);

    // Side selection.
    final List<String> sheets;
    if (widget.compact) {
      sheets = [backSheet ?? frontSheet ?? 'front-chest'];
    } else if (frontSheet != null && backSheet != null) {
      sheets = [frontSheet, backSheet];
    } else if (backSheet != null) {
      sheets = [backSheet];
    } else {
      sheets = [frontSheet ?? 'front-chest'];
    }

    // Both PNG sets (dark + light) are exported at 223 × 470. Clamp the
    // rendered height so we never up-scale past native resolution — that's
    // what produced the grainy look on 3x retina screens.
    const nativeHeight = 470.0;
    final renderHeight =
        widget.height > nativeHeight ? nativeHeight : widget.height;

    // Two-panel layout: front+back side by side, evenly spaced, each shifted
    // vertically to compensate for the PNG center-of-mass mismatch. Single-
    // panel layout: just centre the figure (still compensated by side).
    final Widget content = sheets.length == 1
        ? Center(
            child: _AnatomyPanel(
              path: '$dir/${sheets.first}.png',
              height: renderHeight,
              isBack: _isBackSheet(sheets.first),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (final sheet in sheets)
                _AnatomyPanel(
                  path: '$dir/$sheet.png',
                  height: renderHeight,
                  isBack: _isBackSheet(sheet),
                ),
            ],
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: FadeTransition(
          opacity: _fade,
          child: content,
        ),
      ),
    );
  }
}

/// One anatomy figure, width-clamped to the PNG's 223 × 470 aspect ratio so
/// each panel renders at the same natural size regardless of how much
/// horizontal space its parent gives it. Applies a per-side vertical
/// `Transform.translate` to compensate for the PNG center-of-mass mismatch
/// (front sits ~32px lower than back in the 470px canvas). The shift scales
/// with rendered height so the alignment holds at any size. Remove the shift
/// when the PNGs are re-exported with matching body positions.
class _AnatomyPanel extends StatelessWidget {
  const _AnatomyPanel({
    required this.path,
    required this.height,
    required this.isBack,
  });

  final String path;
  final double height;
  final bool isBack;

  @override
  Widget build(BuildContext context) {
    // 223 / 470 ≈ 0.474 — derive width from height so both panels match.
    final width = height * (223 / 470);
    final shift = isBack
        ? MuscleHighlightWidget._backShiftPx
        : MuscleHighlightWidget._frontShiftPx;
    final scaledShift = shift * (height / 470.0);
    return Transform.translate(
      offset: Offset(0, scaledShift),
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Image.asset(
            path,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

/// Maps canonical muscle names (post [MuscleMap.normalize]) onto the two
/// anatomy PNG filenames. Front sheets cover the chest-shoulders-biceps-abs-
/// quads bucket; back sheets cover traps+lats / lower back / triceps / glutes
/// / calves.
abstract final class _AnatomySheets {
  static const Map<String, String> _front = {
    'pectorals': 'front-chest',
    'chest': 'front-chest',
    'deltoids': 'front-shoulders',
    'biceps': 'front-biceps',
    'forearms': 'front-biceps',
    'abs': 'front-abs',
    'abdominals': 'front-abs',
    'obliques': 'front-abs',
    'serratus': 'front-abs',
    'quadriceps': 'front-quads',
    'quads': 'front-quads',
    'hip flexors': 'front-quads',
    'adductors': 'front-quads',
  };

  static const Map<String, String> _back = {
    // upper back bundle — traps + lats share the same PNG
    'trapezius': 'back-upper',
    'traps': 'back-upper',
    'lats': 'back-upper',
    'latissimus dorsi': 'back-upper',
    'rhomboids': 'back-upper',
    'rear deltoids': 'back-upper',
    // lower back
    'lower back': 'back-lower',
    'erector spinae': 'back-lower',
    // arms (back view)
    'triceps': 'back-triceps',
    'triceps back': 'back-triceps',
    // glutes & legs
    'glutes': 'back-glutes',
    'gluteus maximus': 'back-glutes',
    'hamstrings': 'back-glutes',
    // calves
    'calves': 'back-calves',
    'gastrocnemius': 'back-calves',
    'tibialis': 'back-calves',
  };

  /// Picks the front-sheet filename for the first matching target, or null
  /// if no target maps to a front PNG.
  static String? frontFor(List<String> targets) {
    for (final raw in targets) {
      final key = MuscleMap.normalize(raw);
      final hit = _front[key];
      if (hit != null) return hit;
    }
    return null;
  }

  /// Picks the back-sheet filename for the first matching target, or null
  /// if no target maps to a back PNG.
  static String? backFor(List<String> targets) {
    for (final raw in targets) {
      final key = MuscleMap.normalize(raw);
      final hit = _back[key];
      if (hit != null) return hit;
    }
    return null;
  }
}
