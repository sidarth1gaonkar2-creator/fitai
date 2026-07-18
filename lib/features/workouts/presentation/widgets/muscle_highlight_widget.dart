import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../../data/muscle_map.dart';
import '../../../ranks/domain/military_ranks.dart';

enum _MuscleSide { front, back }

/// Internal description of one anatomy panel's resolved layer paths.
class _PanelResolution {
  const _PanelResolution({
    required this.baseImagePath,
    required this.primaryMaskPaths,
    required this.secondaryMaskPaths,
    required this.isEmpty,
  });

  final String baseImagePath;
  final List<String> primaryMaskPaths;
  final List<String> secondaryMaskPaths;
  final bool isEmpty;

  int get primaryCount => isEmpty ? 0 : 1 + primaryMaskPaths.length;
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
  }) : heatMapRanks = null;

  /// Rank heat-map mode: renders the SAME front+back PNG anatomy as the workout
  /// diagrams, but tints each muscle group's mask by its military rank instead
  /// of a uniform accent. Keys are [RankGroup] names (`chest`, `back`, `legs`,
  /// `shoulders`, `arms`, `core`); a missing group renders as "unranked".
  const MuscleHighlightWidget.rankHeatMap({
    super.key,
    required Map<String, MilitaryRank> muscleGroupRanks,
    this.height = 280,
  })  : targetMuscles = const [],
        secondaryMuscles = const [],
        compact = false,
        heatMapRanks = muscleGroupRanks;

  final List<String> targetMuscles;
  final List<String> secondaryMuscles;
  final double height;
  final bool compact;

  /// Non-null only in [MuscleHighlightWidget.rankHeatMap] mode.
  final Map<String, MilitaryRank>? heatMapRanks;

  /// Front-panel anatomy sheets paired with the [RankGroup] name they belong
  /// to. The base body is the first sheet; every sheet's mask is then tinted.
  static const List<(String, String)> _frontHeatZones = [
    ('front-chest', 'chest'),
    ('front-shoulders', 'shoulders'),
    ('front-biceps', 'arms'),
    ('front-abs', 'core'),
    ('front-quads', 'legs'),
  ];

  /// Back-panel anatomy sheets paired with their [RankGroup] name.
  static const List<(String, String)> _backHeatZones = [
    ('back-upper', 'back'),
    ('back-lower', 'back'),
    ('back-triceps', 'arms'),
    ('back-glutes', 'legs'),
    ('back-calves', 'legs'),
  ];

  static _PanelResolution _resolvePanel({
    required _MuscleSide side,
    required List<String> targetMuscles,
    required List<String> secondaryMuscles,
    required String origDir,
    required String maskDir,
  }) {
    String? sheet(String m) {
      final key = MuscleMap.normalize(m);
      return side == _MuscleSide.front
          ? _AnatomySheets._front[key]
          : _AnatomySheets._back[key];
    }

    // Preserve insertion order so the first-listed target wins the base
    // slot — the rendering depends on this stable ordering.
    final primarySheets = <String>{};
    for (final m in targetMuscles) {
      final s = sheet(m);
      if (s != null) primarySheets.add(s);
    }
    final secondarySheetsRaw = <String>{};
    for (final m in secondaryMuscles) {
      final s = sheet(m);
      if (s != null) secondarySheetsRaw.add(s);
    }
    // A muscle promoted to primary by one exercise can't reappear as a
    // half-opacity secondary because of another exercise listing it.
    final secondarySheets =
        secondarySheetsRaw.where((s) => !primarySheets.contains(s)).toList();

    if (primarySheets.isEmpty && secondarySheets.isEmpty) {
      return const _PanelResolution(
        baseImagePath: '',
        primaryMaskPaths: [],
        secondaryMaskPaths: [],
        isEmpty: true,
      );
    }

    final String baseSheet;
    final List<String> primaryOverlaySheets;
    final List<String> secondaryOverlaySheets;
    if (primarySheets.isNotEmpty) {
      baseSheet = primarySheets.first;
      primaryOverlaySheets = primarySheets.skip(1).toList();
      secondaryOverlaySheets = secondarySheets;
    } else {
      // Fallback path: side has only secondaries → borrow the first
      // for the base silhouette.
      baseSheet = secondarySheets.first;
      primaryOverlaySheets = const [];
      secondaryOverlaySheets = secondarySheets.skip(1).toList();
    }

    return _PanelResolution(
      baseImagePath: '$origDir/$baseSheet.png',
      primaryMaskPaths:
          primaryOverlaySheets.map((s) => '$maskDir/$s.png').toList(),
      secondaryMaskPaths:
          secondaryOverlaySheets.map((s) => '$maskDir/$s.png').toList(),
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
    // The Field Manual is dark by doctrine (batch #3) — always the dark
    // anatomy art, regardless of the device's system brightness. The light
    // sprites stay on disk for a future "Daylight Ops" theme pack.
    const origDir = 'assets/images/anatomy';
    const maskDir = '$origDir/masks';

    if (heatMapRanks != null) {
      return _buildHeatMap(origDir, maskDir);
    }

    final frontRes = _resolvePanel(
      side: _MuscleSide.front,
      targetMuscles: targetMuscles,
      secondaryMuscles: secondaryMuscles,
      origDir: origDir,
      maskDir: maskDir,
    );
    final backRes = _resolvePanel(
      side: _MuscleSide.back,
      targetMuscles: targetMuscles,
      secondaryMuscles: secondaryMuscles,
      origDir: origDir,
      maskDir: maskDir,
    );

    final hasFront = !frontRes.isEmpty;
    final hasBack = !backRes.isEmpty;

    // Pick which sides to render. Compact mode picks the heavier side.
    final showBoth = !compact && hasFront && hasBack;
    final showFront = compact
        ? (hasFront && frontRes.primaryCount >= backRes.primaryCount)
        : hasFront;
    final showBack = compact ? !showFront && hasBack : hasBack;

    // Nothing matched at all — render a single neutral front body so the
    // section never collapses to zero height.
    if (!showFront && !showBack) {
      return _layout(
        height: height,
        children: [
          _BodyPanel(
            baseOriginalPath: '$origDir/front-chest.png',
            primaryMaskPaths: const [],
            secondaryMaskPaths: const [],
            aspectRatio: _nativeWidth / _nativeHeight,
          ),
        ],
      );
    }

    final panels = <Widget>[];
    if (showFront) panels.add(_panelFromResolution(frontRes));
    if (showBack || (showBoth && hasBack)) {
      panels.add(_panelFromResolution(backRes));
    }

    return _layout(height: height, children: panels);
  }

  Widget _panelFromResolution(_PanelResolution res) => _BodyPanel(
        baseOriginalPath: res.baseImagePath,
        primaryMaskPaths: res.primaryMaskPaths,
        secondaryMaskPaths: res.secondaryMaskPaths,
        aspectRatio: _nativeWidth / _nativeHeight,
      );

  /// Builds the front + back rank heat-map panels: one neutral body PNG as the
  /// base, then every group's mask tinted by its rank via a srcIn colour
  /// filter. Always shows both sides (a full-body heat map), unlike the
  /// compact workout mode.
  Widget _buildHeatMap(String origDir, String maskDir) {
    final ranks = heatMapRanks!;

    List<_LayerSpec> specsFor(List<(String, String)> zones) {
      final baseStem = zones.first.$1;
      return [
        // Base body silhouette (untinted). Its one baked-in highlight is
        // overpainted below by that zone's tinted mask.
        _LayerSpec('$origDir/$baseStem.png', 1.0),
        for (final (stem, group) in zones)
          _LayerSpec('$maskDir/$stem.png', 1.0,
              tint: heatColorForRank(ranks[group])),
      ];
    }

    return _layout(
      height: height,
      children: [
        _BodyPanel.layers(
          specs: specsFor(_frontHeatZones),
          aspectRatio: _nativeWidth / _nativeHeight,
        ),
        _BodyPanel.layers(
          specs: specsFor(_backHeatZones),
          aspectRatio: _nativeWidth / _nativeHeight,
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

/// One body side. Decodes the base original + every mask through
/// `rootBundle` once, then paints them into a single shared `Rect` via
/// `CustomPainter`. Single-rect painting avoids the sub-pixel rounding
/// drift we saw when each layer was an independent `Image.asset` —
/// some iOS release builds rounded the mask rect a pixel away from the
/// base rect and the highlight fell outside the body silhouette.
class _BodyPanel extends StatefulWidget {
  const _BodyPanel({
    required this.baseOriginalPath,
    required this.primaryMaskPaths,
    required this.secondaryMaskPaths,
    required this.aspectRatio,
  }) : layerSpecs = null;

  /// Heat-map path: caller supplies fully-resolved (path + opacity + tint)
  /// layers directly instead of the base/primary/secondary triplet.
  const _BodyPanel.layers({
    required List<_LayerSpec> specs,
    required this.aspectRatio,
  })  : baseOriginalPath = '',
        primaryMaskPaths = const [],
        secondaryMaskPaths = const [],
        layerSpecs = specs;

  final String baseOriginalPath;
  final List<String> primaryMaskPaths;
  final List<String> secondaryMaskPaths;
  final List<_LayerSpec>? layerSpecs;
  final double aspectRatio;

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
        !_listEq(old.secondaryMaskPaths, widget.secondaryMaskPaths) ||
        !_specsEq(old.layerSpecs, widget.layerSpecs)) {
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

  static bool _specsEq(List<_LayerSpec>? a, List<_LayerSpec>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].path != b[i].path ||
          a[i].opacity != b[i].opacity ||
          a[i].tint != b[i].tint) {
        return false;
      }
    }
    return true;
  }

  Future<void> _loadAll() async {
    final token = ++_loadToken;
    final specs = widget.layerSpecs ??
        <_LayerSpec>[
          _LayerSpec(widget.baseOriginalPath, 1.0),
          for (final p in widget.secondaryMaskPaths) _LayerSpec(p, 0.5),
          for (final p in widget.primaryMaskPaths) _LayerSpec(p, 1.0),
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
    return _DecodedLayer(
        image: frame.image, opacity: spec.opacity, tint: spec.tint);
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
      child: CustomPaint(painter: _BodyPainter(layers: layers)),
    );
  }
}

class _LayerSpec {
  const _LayerSpec(this.path, this.opacity, {this.tint});
  final String path;
  final double opacity;

  /// When set, the layer is recoloured to this solid colour (keeping the PNG's
  /// alpha) via a srcIn filter — used to paint each mask in its rank colour.
  final Color? tint;
}

class _DecodedLayer {
  const _DecodedLayer({required this.image, required this.opacity, this.tint});
  final ui.Image image;
  final double opacity;
  final Color? tint;
}

class _BodyPainter extends CustomPainter {
  const _BodyPainter({required this.layers});

  final List<_DecodedLayer> layers;

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
        ..colorFilter = layer.tint != null
            // Heat map: replace the mask's RGB with the rank colour, keeping
            // its alpha, so the zone fills solid in that colour.
            ? ColorFilter.mode(layer.tint!, BlendMode.srcIn)
            : (layer.opacity < 1.0
                ? ColorFilter.mode(
                    Colors.white.withValues(alpha: layer.opacity),
                    BlendMode.modulate,
                  )
                : null);
      canvas.drawImageRect(layer.image, src, dst, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) {
    if (layers.length != old.layers.length) return true;
    for (var i = 0; i < layers.length; i++) {
      if (!identical(layers[i].image, old.layers[i].image) ||
          layers[i].opacity != old.layers[i].opacity ||
          layers[i].tint != old.layers[i].tint) {
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
