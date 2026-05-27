import 'package:flutter/material.dart';

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
class _BodyPanel extends StatelessWidget {
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
  /// When true, wraps every `Image.asset` in a 1px coloured border so a
  /// TestFlight tester can count layers visually and confirm they're
  /// positioned identically. Base=red, secondary mask=yellow, primary
  /// mask=cyan — same colour vocabulary the diagnostic dialog uses.
  final bool debugBorders;

  Widget _maybeBorder(Widget child, Color color) {
    if (!debugBorders) return child;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: color, width: 1)),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          // 1. Original PNG — silhouette + first highlight baked in.
          _maybeBorder(
            Image.asset(
              baseOriginalPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            Colors.red,
          ),
          // 2. Secondary masks at half opacity — drawn before remaining
          //    primaries so a stray pixel overlap reads as "secondary
          //    tinted under primary" rather than the other way around.
          for (final path in secondaryMaskPaths)
            _maybeBorder(
              Opacity(
                opacity: 0.5,
                child: Image.asset(
                  path,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              Colors.yellow,
            ),
          // 3. Remaining primary masks at full opacity.
          for (final path in primaryMaskPaths)
            _maybeBorder(
              Image.asset(
                path,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
              Colors.cyan,
            ),
        ],
      ),
    );
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
