import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../../data/muscle_map.dart';

/// Side flag used by [PanelResolution] and the path helpers.
enum MuscleSide { front, back }

/// Full description of how one anatomy panel (front or back) will be
/// composited, including the resolved PNG paths. Returned by
/// [MuscleHighlightWidget.resolvePanel] so the diagnostic dialog can
/// dump the same data the renderer uses without duplicating logic.
class PanelResolution {
  const PanelResolution({
    required this.side,
    required this.baseSheet,
    required this.baseFromMuscle,
    required this.baseImagePath,
    required this.primaryMaskSheets,
    required this.primaryMaskPaths,
    required this.primaryMaskFromMuscles,
    required this.secondaryMaskSheets,
    required this.secondaryMaskPaths,
    required this.secondaryMaskFromMuscles,
    required this.isEmpty,
  });

  final MuscleSide side;
  /// PNG stem chosen as the base (full silhouette + baked-in highlight).
  /// Null when the side is empty.
  final String? baseSheet;
  /// Original muscle name (one of the input strings) that produced the
  /// base sheet. Empty when the base came from a fallback.
  final String? baseFromMuscle;
  /// Absolute asset path that will be passed to `Image.asset` for the
  /// base layer. Empty string when the side is empty.
  final String baseImagePath;
  final List<String> primaryMaskSheets;
  final List<String> primaryMaskPaths;
  final List<String> primaryMaskFromMuscles;
  final List<String> secondaryMaskSheets;
  final List<String> secondaryMaskPaths;
  final List<String> secondaryMaskFromMuscles;
  /// True when no muscles on the input list hit this side — the
  /// renderer short-circuits with a neutral placeholder in that case.
  final bool isEmpty;

  /// Image.asset count the renderer will produce: 1 for the base +
  /// each primary/secondary mask. 0 when the side is empty.
  int get imageCount => isEmpty
      ? 1
      : 1 + primaryMaskPaths.length + secondaryMaskPaths.length;
}

/// Composited anatomy diagram.
///
/// For each body side we render:
///   1. ONE original full-body PNG (silhouette + first highlight baked in)
///      as the base layer — these PNGs already look clean, so using one of
///      them as the canvas avoids the synthetic-base artifacts we saw when
///      compositing a min-brightness "base body" from all the sheets.
///   2. The remaining primary muscle MASKS on top at full opacity. Masks
///      are transparent everywhere except the highlight zone, so stacking
///      them adds the extra highlights without re-drawing the body.
///   3. Every secondary muscle's MASK on top at 50% opacity.
///
/// Mask PNGs come from `…/anatomy/masks/`; originals come from the parent
/// `…/anatomy/` folder. Light mode swaps the root dir; the masks layout
/// mirrors it under `…/anatomy/light/`.
///
/// Two display modes:
///   * Compact (`height: 120`) — single panel (whichever side has more hits).
///   * Full   (`height: 280`) — front + back side by side when both have hits.
class MuscleHighlightWidget extends StatelessWidget {
  const MuscleHighlightWidget({
    super.key,
    required this.targetMuscles,
    this.secondaryMuscles = const [],
    this.height = 280,
    this.compact = false,
    this.debugOverlay = false,
  });

  final List<String> targetMuscles;
  final List<String> secondaryMuscles;
  final double height;
  final bool compact;

  /// When true, paints the muscle-name strings (with their resolved PNG
  /// sheet stem in parens) on top of the figure so a TestFlight tester
  /// can verify what the widget *thinks* it's drawing without needing a
  /// debugger. No `kDebugMode` guard — intentionally visible in
  /// release builds while the diagram bug is under investigation.
  final bool debugOverlay;

  /// Returns the front-sheet PNG stem (e.g. `front-chest`) that the
  /// given muscle name resolves to, or null if unmapped. Exposed so the
  /// in-app diagnostic dialog can show the full per-muscle mapping
  /// without duplicating the lookup table.
  static String? frontSheetFor(String muscle) =>
      _AnatomySheets._front[MuscleMap.normalize(muscle)];

  /// Returns the back-sheet PNG stem, or null if unmapped.
  static String? backSheetFor(String muscle) =>
      _AnatomySheets._back[MuscleMap.normalize(muscle)];

  /// Asset directory the widget reads from for the given [brightness].
  /// Useful for the diagnostic to print exactly what would be loaded in
  /// either theme without needing a BuildContext.
  static String originalDir(Brightness brightness) =>
      brightness == Brightness.light
          ? 'assets/images/anatomy/light'
          : 'assets/images/anatomy';

  /// Mask directory for the given [brightness].
  static String maskDir(Brightness brightness) =>
      '${originalDir(brightness)}/masks';

  /// Replicates the in-widget panel resolution (base + overlay masks)
  /// for one side ([side]). Output is exactly what the renderer will
  /// hand to [Image.asset] so the diagnostic dialog and the rendered
  /// figure can never drift apart.
  static PanelResolution resolvePanel({
    required MuscleSide side,
    required List<String> targetMuscles,
    required List<String> secondaryMuscles,
    required Brightness brightness,
  }) {
    final orig = originalDir(brightness);
    final masks = maskDir(brightness);
    String? sheet(String m) =>
        side == MuscleSide.front ? frontSheetFor(m) : backSheetFor(m);

    // Preserve insertion order so the first-listed target wins the base
    // slot — matches the runtime resolver.
    final primarySheets = <String>{};
    final primaryByMuscle = <String, String>{};
    for (final m in targetMuscles) {
      final s = sheet(m);
      if (s != null && primarySheets.add(s)) primaryByMuscle[s] = m;
    }
    final secondarySheetsRaw = <String>{};
    final secondaryByMuscle = <String, String>{};
    for (final m in secondaryMuscles) {
      final s = sheet(m);
      if (s != null && secondarySheetsRaw.add(s)) secondaryByMuscle[s] = m;
    }
    // Same dedup the renderer applies — a sheet promoted to primary
    // by one exercise can't reappear as a half-opacity secondary.
    final secondarySheets =
        secondarySheetsRaw.where((s) => !primarySheets.contains(s)).toList();

    if (primarySheets.isEmpty && secondarySheets.isEmpty) {
      return PanelResolution(
        side: side,
        baseSheet: null,
        baseFromMuscle: null,
        baseImagePath: '',
        primaryMaskSheets: const [],
        primaryMaskPaths: const [],
        primaryMaskFromMuscles: const [],
        secondaryMaskSheets: const [],
        secondaryMaskPaths: const [],
        secondaryMaskFromMuscles: const [],
        isEmpty: true,
      );
    }

    final String baseSheet;
    final String? baseFromMuscle;
    final List<String> primaryOverlaySheets;
    final List<String> secondaryOverlaySheets;
    if (primarySheets.isNotEmpty) {
      baseSheet = primarySheets.first;
      baseFromMuscle = primaryByMuscle[baseSheet];
      primaryOverlaySheets = primarySheets.skip(1).toList();
      secondaryOverlaySheets = secondarySheets;
    } else {
      // Fallback path: side has only secondaries → borrow the first
      // for the base silhouette.
      baseSheet = secondarySheets.first;
      baseFromMuscle = secondaryByMuscle[baseSheet];
      primaryOverlaySheets = const [];
      secondaryOverlaySheets = secondarySheets.skip(1).toList();
    }

    return PanelResolution(
      side: side,
      baseSheet: baseSheet,
      baseFromMuscle: baseFromMuscle,
      baseImagePath: '$orig/$baseSheet.png',
      primaryMaskSheets: primaryOverlaySheets,
      primaryMaskPaths:
          primaryOverlaySheets.map((s) => '$masks/$s.png').toList(),
      primaryMaskFromMuscles:
          primaryOverlaySheets.map((s) => primaryByMuscle[s] ?? '').toList(),
      secondaryMaskSheets: secondaryOverlaySheets,
      secondaryMaskPaths:
          secondaryOverlaySheets.map((s) => '$masks/$s.png').toList(),
      secondaryMaskFromMuscles: secondaryOverlaySheets
          .map((s) => secondaryByMuscle[s] ?? '')
          .toList(),
      isEmpty: false,
    );
  }

  // Native dimensions of every anatomy PNG.
  static const double _nativeWidth = 669;
  static const double _nativeHeight = 1410;

  /// Legend swatch helpers — used to draw the colour key next to the figure.
  static Color targetColor(Color accent) => accent.withValues(alpha: 0.75);
  static Color secondaryColor(Color accent) => accent.withValues(alpha: 0.35);

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final origDir = originalDir(brightness);

    // Use the public resolver so the diagnostic dialog and the renderer
    // always see the exact same allocation.
    final frontRes = resolvePanel(
      side: MuscleSide.front,
      targetMuscles: targetMuscles,
      secondaryMuscles: secondaryMuscles,
      brightness: brightness,
    );
    final backRes = resolvePanel(
      side: MuscleSide.back,
      targetMuscles: targetMuscles,
      secondaryMuscles: secondaryMuscles,
      brightness: brightness,
    );

    final hasFront = !frontRes.isEmpty;
    final hasBack = !backRes.isEmpty;

    // Pick which sides to render. Compact mode picks the heavier side.
    final showBoth = !compact && hasFront && hasBack;
    final showFront = compact
        ? (hasFront &&
            frontRes.primaryMaskSheets.length + (frontRes.baseSheet == null ? 0 : 1) >=
                backRes.primaryMaskSheets.length + (backRes.baseSheet == null ? 0 : 1))
        : hasFront;
    final showBack = compact ? !showFront && hasBack : hasBack;

    // Nothing matched at all — render a single neutral front body so the
    // section never collapses to zero height.
    if (!showFront && !showBack) {
      return _maybeWithOverlay(
        _layout(
          height: height,
          children: [
            _BodyPanel(
              baseOriginalPath: '$origDir/front-chest.png',
              primaryMaskPaths: const [],
              secondaryMaskPaths: const [],
              aspectRatio: _nativeWidth / _nativeHeight,
              debugBorders: debugOverlay,
            ),
          ],
        ),
        frontImageCount: 1,
        backImageCount: 0,
      );
    }

    final panels = <Widget>[];
    if (showFront) panels.add(_panelFromResolution(frontRes));
    if (showBack || (showBoth && hasBack)) {
      panels.add(_panelFromResolution(backRes));
    }

    return _maybeWithOverlay(
      _layout(height: height, children: panels),
      frontImageCount: showFront ? frontRes.imageCount : 0,
      backImageCount:
          (showBack || (showBoth && hasBack)) ? backRes.imageCount : 0,
    );
  }

  Widget _panelFromResolution(PanelResolution res) => _BodyPanel(
        baseOriginalPath: res.baseImagePath,
        primaryMaskPaths: res.primaryMaskPaths,
        secondaryMaskPaths: res.secondaryMaskPaths,
        aspectRatio: _nativeWidth / _nativeHeight,
        debugBorders: debugOverlay,
      );

  /// Wraps [child] in a Stack with a "what muscles am I drawing" label
  /// pile when [debugOverlay] is true; otherwise returns [child] as-is.
  /// [frontImageCount] / [backImageCount] = number of `Image.asset`
  /// widgets in the front / back panel's stack — surfaces the same data
  /// the diagnostic dialog reports so a tester can verify the figure
  /// rendered the expected number of layers.
  Widget _maybeWithOverlay(
    Widget child, {
    required int frontImageCount,
    required int backImageCount,
  }) {
    if (!debugOverlay) return child;
    return Stack(
      children: [
        child,
        Positioned(
          left: 4,
          right: 4,
          top: 4,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TARGETS: ${targetMuscles.isEmpty ? "(none)" : targetMuscles.join(", ")}',
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 10,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (secondaryMuscles.isNotEmpty)
                    Text(
                      'SECONDARY: ${secondaryMuscles.join(", ")}',
                      style: const TextStyle(
                        color: Color(0xFFB0BEC5),
                        fontSize: 10,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  Text(
                    'LAYERS  front: $frontImageCount  back: $backImageCount   '
                    'fit: BoxFit.contain  align: center',
                    style: const TextStyle(
                      color: Color(0xFF80DEEA),
                      fontSize: 10,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _layout({required double height, required List<Widget> children}) {
    // Symmetric 16px horizontal padding on the card, two equal-flex columns
    // separated by a 10px gutter. Each column centers its panel within its
    // own half so the front/back bodies sit mirrored across the centerline.
    //
    // The PNGs themselves are pre-recentered (every body's bbox is at the
    // exact same canvas position), so we don't need any per-panel
    // Transform.translate compensation here.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: children.length == 1
            ? Center(child: children.first)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Center(child: children[0])),
                  const SizedBox(width: 10),
                  Expanded(child: Center(child: children[1])),
                ],
              ),
      ),
    );
  }
}

/// One body side. Renders the base original PNG, then any additional
/// primary masks at full opacity, then secondary masks at 50% opacity.
/// All composited with normal `srcOver` since masks are transparent
/// outside their highlight zone.
/// One body side. Renders the base original PNG, then any additional
/// primary masks at full opacity, then secondary masks at 50% opacity.
///
/// CustomPainter implementation: the previous `Stack<Image.asset>` approach
/// composited base + masks by stacking widgets, each of which independently
/// resolved `BoxFit.contain` against the available box. In practice some
/// platforms (notably iOS release builds) produced sub-pixel rounding
/// differences between layers — the front-shoulders mask would land a few
/// pixels off the front-chest base, and the highlight would fall outside
/// the body silhouette. The bug was invisible in dev/hot-reload because
/// the rounding happened to align.
///
/// Painting on a single shared `Rect` removes that class of bug entirely:
/// every layer uses the exact same destination rectangle. `drawImageRect`
/// also gives us a true painter cache (`shouldRepaint` returns false when
/// the layer list hasn't changed) instead of N widget rebuilds.
class _BodyPanel extends StatefulWidget {
  const _BodyPanel({
    required this.baseOriginalPath,
    required this.primaryMaskPaths,
    required this.secondaryMaskPaths,
    required this.aspectRatio,
    this.debugBorders = false,
  });

  final String baseOriginalPath;
  final List<String> primaryMaskPaths;
  final List<String> secondaryMaskPaths;
  final double aspectRatio;
  /// When true, the painter draws a 1px coloured outline around each
  /// layer's destination rectangle so a TestFlight tester can see, at a
  /// glance, that every image is being painted into the exact same Rect.
  /// Colour vocabulary mirrors the diagnostic dialog:
  /// red=BASE, yellow=secondary mask (50%), cyan=primary mask (100%).
  final bool debugBorders;

  @override
  State<_BodyPanel> createState() => _BodyPanelState();
}

class _BodyPanelState extends State<_BodyPanel> {
  // All decoded layers, in paint order (base first, then secondary
  // masks, then primary masks). Indexed identically to [_LayerSpec].
  List<_DecodedLayer>? _layers;
  Object? _error;
  // Bumped each time we kick off a load. Stale loads (cancelled because
  // the widget rebuilt with new paths) compare on this token and skip
  // their setState — protects against last-write-wins races.
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void didUpdateWidget(covariant _BodyPanel old) {
    super.didUpdateWidget(old);
    if (old.baseOriginalPath != widget.baseOriginalPath ||
        !_listEq(old.primaryMaskPaths, widget.primaryMaskPaths) ||
        !_listEq(old.secondaryMaskPaths, widget.secondaryMaskPaths)) {
      _loadAll();
    }
  }

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _loadAll() async {
    final token = ++_loadToken;
    final specs = <_LayerSpec>[
      _LayerSpec(widget.baseOriginalPath, 1.0, _LayerRole.base),
      for (final p in widget.secondaryMaskPaths)
        _LayerSpec(p, 0.5, _LayerRole.secondaryMask),
      for (final p in widget.primaryMaskPaths)
        _LayerSpec(p, 1.0, _LayerRole.primaryMask),
    ];
    try {
      final decoded = await Future.wait(specs.map((s) => _decode(s)));
      // The load may finish after the widget has been disposed (or after
      // a newer _loadAll was kicked off with different paths). In either
      // case the freshly-decoded ui.Images would leak native memory if
      // we just returned — explicitly dispose them.
      if (!mounted || token != _loadToken) {
        for (final l in decoded) {
          l.image.dispose();
        }
        return;
      }
      // Dispose the PREVIOUS layer set we're about to replace.
      final old = _layers;
      if (old != null) {
        for (final l in old) {
          l.image.dispose();
        }
      }
      setState(() {
        _layers = decoded;
        _error = null;
      });
    } catch (e) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _layers = null;
        _error = e;
      });
    }
  }

  static Future<_DecodedLayer> _decode(_LayerSpec spec) async {
    final data = await rootBundle.load(spec.path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return _DecodedLayer(image: frame.image, opacity: spec.opacity, role: spec.role);
  }

  @override
  void dispose() {
    // Decoded ui.Image instances hold native memory — dispose them so
    // rapid template switching doesn't leak.
    final layers = _layers;
    if (layers != null) {
      for (final l in layers) {
        l.image.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layers = _layers;
    if (_error != null || layers == null) {
      // Reserve space while loading so the surrounding layout doesn't
      // jump when the figure pops in.
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: const SizedBox.shrink(),
      );
    }
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: CustomPaint(
        painter: _BodyPainter(layers: layers, debugBorders: widget.debugBorders),
      ),
    );
  }
}

enum _LayerRole { base, primaryMask, secondaryMask }

class _LayerSpec {
  const _LayerSpec(this.path, this.opacity, this.role);
  final String path;
  final double opacity;
  final _LayerRole role;
}

class _DecodedLayer {
  const _DecodedLayer({required this.image, required this.opacity, required this.role});
  final ui.Image image;
  final double opacity;
  final _LayerRole role;
}

class _BodyPainter extends CustomPainter {
  const _BodyPainter({required this.layers, required this.debugBorders});

  final List<_DecodedLayer> layers;
  final bool debugBorders;

  @override
  void paint(Canvas canvas, Size size) {
    if (layers.isEmpty) return;
    // Every layer ships at the same 669×1410 canvas, so picking the
    // first layer's dimensions as the "native" size is safe. The dst
    // rect is computed once and reused for every layer — the whole
    // point of this painter is to guarantee pixel-identical placement.
    final base = layers.first.image;
    final nativeAspect = base.width / base.height;
    final boxAspect = size.width / size.height;
    final double dstW, dstH;
    if (boxAspect > nativeAspect) {
      // Box is wider than the image — letterbox left/right.
      dstH = size.height;
      dstW = dstH * nativeAspect;
    } else {
      // Box is taller — letterbox top/bottom.
      dstW = size.width;
      dstH = dstW / nativeAspect;
    }
    final dx = (size.width - dstW) / 2;
    final dy = (size.height - dstH) / 2;
    final dst = Rect.fromLTWH(dx, dy, dstW, dstH);

    for (final layer in layers) {
      final src = Rect.fromLTWH(
        0,
        0,
        layer.image.width.toDouble(),
        layer.image.height.toDouble(),
      );
      final paint = Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true
        ..colorFilter = layer.opacity < 1.0
            ? ColorFilter.mode(
                Colors.white.withValues(alpha: layer.opacity),
                BlendMode.modulate,
              )
            : null;
      canvas.drawImageRect(layer.image, src, dst, paint);
    }

    if (debugBorders) {
      // Outline EACH layer's dst rect at a slight inset so the per-layer
      // colours don't perfectly overlap and become indistinguishable.
      for (var i = 0; i < layers.length; i++) {
        final color = switch (layers[i].role) {
          _LayerRole.base => Colors.red,
          _LayerRole.secondaryMask => Colors.yellow,
          _LayerRole.primaryMask => Colors.cyan,
        };
        final inset = i.toDouble() * 1.0;
        canvas.drawRect(
          dst.deflate(inset),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) {
    if (debugBorders != old.debugBorders) return true;
    if (layers.length != old.layers.length) return true;
    for (var i = 0; i < layers.length; i++) {
      if (!identical(layers[i].image, old.layers[i].image) ||
          layers[i].opacity != old.layers[i].opacity ||
          layers[i].role != old.layers[i].role) {
        return true;
      }
    }
    return false;
  }
}

/// Maps canonical muscle names (post [MuscleMap.normalize]) onto the
/// anatomy PNG filename stems. Front sheets cover chest/shoulders/biceps/
/// abs/quads; back sheets cover traps+lats / lower back / triceps /
/// glutes+hams / calves.
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
}
