import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../data/muscle_map.dart';

/// Renders a body silhouette with the target muscle group highlighted using
/// pre-rendered PNGs at `assets/images/anatomy/` (dark) and
/// `assets/images/anatomy/light/` (light). Each PNG contains the full body
/// silhouette plus its highlighted muscle baked in.
///
/// Multi-muscle workouts get *every* primary/secondary zone highlighted — the
/// underlying PNGs are composited via [BlendMode.lighten], which keeps the
/// silhouette stable (same dark body pixels across every sheet) while letting
/// each sheet's bright highlight zone bleed through.
///
/// Names are resolved through [MuscleMap.normalize] and a thin canonical-to-
/// filename mapping; if the supplied muscle has no PNG, we fall back to the
/// front-chest sheet so the widget never collapses.
///
/// Two display modes:
///   * Compact (`height: 120`) — single PNG side (best primary muscle wins).
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

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final dir = brightness == Brightness.light
        ? 'assets/images/anatomy/light'
        : 'assets/images/anatomy';

    // Collect every front/back sheet matched by the input muscle lists. A
    // single muscle name may map to a sheet that the widget already shows
    // for another muscle — the `Set` dedupes those naturally.
    final primaryFront =
        _AnatomySheets.frontSheetsFor(widget.targetMuscles).toList();
    final primaryBack =
        _AnatomySheets.backSheetsFor(widget.targetMuscles).toList();
    final secFrontAll =
        _AnatomySheets.frontSheetsFor(widget.secondaryMuscles);
    final secBackAll = _AnatomySheets.backSheetsFor(widget.secondaryMuscles);
    // A muscle counted as primary by one exercise should never render twice
    // (once at full opacity, once at half) just because another exercise
    // listed it as secondary. Drop the duplicates here.
    final secondaryFront =
        secFrontAll.where((s) => !primaryFront.contains(s)).toList();
    final secondaryBack =
        secBackAll.where((s) => !primaryBack.contains(s)).toList();

    final hasFront = primaryFront.isNotEmpty || secondaryFront.isNotEmpty;
    final hasBack = primaryBack.isNotEmpty || secondaryBack.isNotEmpty;

    // Build a list of panels to render, each carrying its primary + secondary
    // sheet filenames and a flag for the alignment shift direction.
    final panels = <_PanelSpec>[];
    if (widget.compact) {
      // Compact: one side only. Prefer the side with more primary hits so
      // the spotlight on a typical leg/glute lift lands on the back.
      final preferBack = primaryBack.length >= primaryFront.length;
      if (preferBack && hasBack) {
        panels.add(_PanelSpec(
            primary: primaryBack, secondary: secondaryBack, isBack: true));
      } else if (hasFront) {
        panels.add(_PanelSpec(
            primary: primaryFront, secondary: secondaryFront, isBack: false));
      } else if (hasBack) {
        panels.add(_PanelSpec(
            primary: primaryBack, secondary: secondaryBack, isBack: true));
      } else {
        // Nothing matched — keep the widget from collapsing to zero height.
        panels.add(const _PanelSpec(
            primary: ['front-chest'], secondary: [], isBack: false));
      }
    } else if (hasFront && hasBack) {
      panels.add(_PanelSpec(
          primary: primaryFront, secondary: secondaryFront, isBack: false));
      panels.add(_PanelSpec(
          primary: primaryBack, secondary: secondaryBack, isBack: true));
    } else if (hasFront) {
      panels.add(_PanelSpec(
          primary: primaryFront, secondary: secondaryFront, isBack: false));
    } else if (hasBack) {
      panels.add(_PanelSpec(
          primary: primaryBack, secondary: secondaryBack, isBack: true));
    } else {
      panels.add(const _PanelSpec(
          primary: ['front-chest'], secondary: [], isBack: false));
    }

    // Both PNG sets (dark + light) are exported at 223 × 470. Clamp the
    // rendered height so we never up-scale past native resolution — that's
    // what produced the grainy look on 3x retina screens.
    const nativeHeight = 470.0;
    final renderHeight =
        widget.height > nativeHeight ? nativeHeight : widget.height;

    final Widget content = panels.length == 1
        ? Center(
            child: _OverlayPanel(
              dir: dir,
              primarySheets: panels.first.primary,
              secondarySheets: panels.first.secondary,
              height: renderHeight,
              isBack: panels.first.isBack,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (final p in panels)
                _OverlayPanel(
                  dir: dir,
                  primarySheets: p.primary,
                  secondarySheets: p.secondary,
                  height: renderHeight,
                  isBack: p.isBack,
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

/// Bundle of sheets that go into one panel (one body side). Pulled out so
/// the build method's panel-selection logic isn't nested inside the layout.
class _PanelSpec {
  const _PanelSpec({
    required this.primary,
    required this.secondary,
    required this.isBack,
  });
  final List<String> primary;
  final List<String> secondary;
  final bool isBack;
}

/// One body-side panel that composites N sheets together. Loads each sheet
/// as a [ui.Image] in `initState`, then paints them via [_SheetCompositePainter]
/// with [BlendMode.lighten] so every highlight zone survives the overlay.
///
/// The silhouette body in each PNG is identical across sheets, so the dark
/// body pixels are stable under `lighten` (max of equal values is itself).
/// Highlight pixels are brighter than the body, so the brightest one wins —
/// which is exactly the union-of-zones we want.
class _OverlayPanel extends StatefulWidget {
  const _OverlayPanel({
    required this.dir,
    required this.primarySheets,
    required this.secondarySheets,
    required this.height,
    required this.isBack,
  });

  final String dir;
  final List<String> primarySheets;
  final List<String> secondarySheets;
  final double height;
  final bool isBack;

  @override
  State<_OverlayPanel> createState() => _OverlayPanelState();
}

class _OverlayPanelState extends State<_OverlayPanel> {
  final Map<String, ui.Image> _images = {};
  // Tracks the in-flight load tag so a re-render with new sheets can ignore
  // stale completions.
  int _loadTag = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void didUpdateWidget(_OverlayPanel old) {
    super.didUpdateWidget(old);
    final sheetsChanged = !_eq(old.primarySheets, widget.primarySheets) ||
        !_eq(old.secondarySheets, widget.secondarySheets) ||
        old.dir != widget.dir;
    if (sheetsChanged) {
      _images.clear();
      _loadAll();
    }
  }

  bool _eq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _loadAll() async {
    _loadTag++;
    final tag = _loadTag;
    final all = <String>{...widget.primarySheets, ...widget.secondarySheets};
    for (final sheet in all) {
      final path = '${widget.dir}/$sheet.png';
      try {
        final img = await _loadAssetImage(path);
        if (!mounted || tag != _loadTag) return;
        setState(() => _images[sheet] = img);
      } catch (_) {
        // Asset missing or decode failed — skip this sheet silently so the
        // rest of the composite still renders.
      }
    }
  }

  Future<ui.Image> _loadAssetImage(String path) async {
    final completer = Completer<ui.Image>();
    final provider = AssetImage(path);
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        completer.complete(info.image);
      },
      onError: (e, st) {
        stream.removeListener(listener);
        completer.completeError(e, st);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.height * (223 / 470);
    final shift = widget.isBack
        ? MuscleHighlightWidget._backShiftPx
        : MuscleHighlightWidget._frontShiftPx;
    final scaledShift = shift * (widget.height / 470.0);

    final primaryImgs = widget.primarySheets
        .map((s) => _images[s])
        .whereType<ui.Image>()
        .toList();
    final secondaryImgs = widget.secondarySheets
        .map((s) => _images[s])
        .whereType<ui.Image>()
        .toList();

    return Transform.translate(
      offset: Offset(0, scaledShift),
      child: SizedBox(
        width: width,
        height: widget.height,
        child: primaryImgs.isEmpty && secondaryImgs.isEmpty
            ? const SizedBox.shrink() // images still loading
            : CustomPaint(
                painter: _SheetCompositePainter(
                  primaryImages: primaryImgs,
                  secondaryImages: secondaryImgs,
                ),
              ),
      ),
    );
  }
}

/// Composites N anatomy sheets into one image by drawing each with
/// [BlendMode.lighten]. Secondary sheets render first with a 0.5 alpha
/// pre-multiplication so their highlights appear at roughly half intensity
/// per the design spec.
class _SheetCompositePainter extends CustomPainter {
  _SheetCompositePainter({
    required this.primaryImages,
    required this.secondaryImages,
  });

  final List<ui.Image> primaryImages;
  final List<ui.Image> secondaryImages;

  void _drawImage(
    Canvas canvas,
    Size size,
    ui.Image img, {
    required Paint paint,
  }) {
    final imgW = img.width.toDouble();
    final imgH = img.height.toDouble();
    // Contain-fit: scale so the image fits inside the panel without crop.
    final scale = math.min(size.width / imgW, size.height / imgH);
    final dstW = imgW * scale;
    final dstH = imgH * scale;
    final dx = (size.width - dstW) / 2;
    final dy = (size.height - dstH) / 2;
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, imgW, imgH),
      Rect.fromLTWH(dx, dy, dstW, dstH),
      paint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 0.5 alpha matrix — pre-multiplies each pixel's alpha so the secondary
    // highlight composites at half intensity onto the canvas. Identity on
    // RGB so the silhouette colour itself isn't shifted.
    const halfAlpha = ColorFilter.matrix(<double>[
      1, 0, 0, 0, 0, //
      0, 1, 0, 0, 0, //
      0, 0, 1, 0, 0, //
      0, 0, 0, 0.5, 0, //
    ]);

    final secondaryPaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..blendMode = BlendMode.lighten
      ..colorFilter = halfAlpha;
    for (final img in secondaryImages) {
      _drawImage(canvas, size, img, paint: secondaryPaint);
    }

    final primaryPaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..blendMode = BlendMode.lighten;
    for (final img in primaryImages) {
      _drawImage(canvas, size, img, paint: primaryPaint);
    }
  }

  @override
  bool shouldRepaint(_SheetCompositePainter old) {
    if (old.primaryImages.length != primaryImages.length ||
        old.secondaryImages.length != secondaryImages.length) {
      return true;
    }
    for (var i = 0; i < primaryImages.length; i++) {
      if (!identical(old.primaryImages[i], primaryImages[i])) return true;
    }
    for (var i = 0; i < secondaryImages.length; i++) {
      if (!identical(old.secondaryImages[i], secondaryImages[i])) return true;
    }
    return false;
  }
}

/// Maps canonical muscle names (post [MuscleMap.normalize]) onto the
/// anatomy PNG filenames. Front sheets cover the chest-shoulders-biceps-abs-
/// quads bucket; back sheets cover traps+lats / lower back / triceps / glutes
/// / calves.
abstract final class _AnatomySheets {
  static const Map<String, String> _front = {
    'pectorals': 'front-chest',
    'chest': 'front-chest',
    'deltoids': 'front-shoulders',
    'shoulders': 'front-shoulders',
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
    'upper back': 'back-upper',
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

  /// Every unique front-sheet filename matched by any name in [targets].
  /// Order is stable: iteration order of insertion into the result set.
  static Set<String> frontSheetsFor(List<String> targets) {
    final out = <String>{};
    for (final raw in targets) {
      final key = MuscleMap.normalize(raw);
      final hit = _front[key];
      if (hit != null) out.add(hit);
    }
    return out;
  }

  /// Every unique back-sheet filename matched by any name in [targets].
  static Set<String> backSheetsFor(List<String> targets) {
    final out = <String>{};
    for (final raw in targets) {
      final key = MuscleMap.normalize(raw);
      final hit = _back[key];
      if (hit != null) out.add(hit);
    }
    return out;
  }
}
