import 'package:flutter/material.dart';

import '../../../../data/muscle_map.dart';

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

  // Native dimensions of every anatomy PNG.
  static const double _nativeWidth = 669;
  static const double _nativeHeight = 1410;

  /// Legend swatch helpers — used to draw the colour key next to the figure.
  static Color targetColor(Color accent) => accent.withValues(alpha: 0.75);
  static Color secondaryColor(Color accent) => accent.withValues(alpha: 0.35);

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final origDir = brightness == Brightness.light
        ? 'assets/images/anatomy/light'
        : 'assets/images/anatomy';
    final maskDir = '$origDir/masks';

    // Resolve sheet-name sets per side. `Set` dedupes when one muscle name
    // and a synonym both map to the same PNG.
    final primaryFront =
        _AnatomySheets.frontSheetsFor(targetMuscles).toList();
    final primaryBack = _AnatomySheets.backSheetsFor(targetMuscles).toList();
    final secFrontAll = _AnatomySheets.frontSheetsFor(secondaryMuscles);
    final secBackAll = _AnatomySheets.backSheetsFor(secondaryMuscles);
    // A muscle counted primary by one exercise shouldn't render again as a
    // half-opacity secondary just because another exercise listed it that
    // way — drop duplicates here.
    final secondaryFront =
        secFrontAll.where((s) => !primaryFront.contains(s)).toList();
    final secondaryBack =
        secBackAll.where((s) => !primaryBack.contains(s)).toList();

    final hasFront = primaryFront.isNotEmpty || secondaryFront.isNotEmpty;
    final hasBack = primaryBack.isNotEmpty || secondaryBack.isNotEmpty;

    // Pick which sides to render. Compact mode picks the heavier side.
    final showBoth = !compact && hasFront && hasBack;
    final showFront = compact
        ? (hasFront && primaryFront.length >= primaryBack.length)
        : hasFront;
    final showBack = compact ? !showFront && hasBack : hasBack;

    // Nothing matched at all — render a single neutral front body so the
    // section never collapses to zero height.
    if (!showFront && !showBack) {
      return _maybeWithOverlay(_layout(
        height: height,
        children: [
          _BodyPanel(
            baseOriginalPath: '$origDir/front-chest.png',
            primaryMaskPaths: const [],
            secondaryMaskPaths: const [],
            aspectRatio: _nativeWidth / _nativeHeight,
          ),
        ],
      ));
    }

    final panels = <Widget>[];
    if (showFront) {
      panels.add(_buildPanel(
        origDir: origDir,
        maskDir: maskDir,
        primary: primaryFront,
        secondary: secondaryFront,
      ));
    }
    if (showBack || (showBoth && hasBack)) {
      panels.add(_buildPanel(
        origDir: origDir,
        maskDir: maskDir,
        primary: primaryBack,
        secondary: secondaryBack,
      ));
    }

    return _maybeWithOverlay(_layout(height: height, children: panels));
  }

  /// Wraps [child] in a Stack with a "what muscles am I drawing" label
  /// pile when [debugOverlay] is true; otherwise returns [child] as-is.
  Widget _maybeWithOverlay(Widget child) {
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Composes one side. The first primary sheet (if any) becomes the
  /// ORIGINAL base layer — its highlight is already baked in, so we don't
  /// add a mask for it. The remaining primaries layer as masks at full
  /// opacity, secondaries at half.
  ///
  /// Fallbacks for the base layer when no primary hits this side:
  ///   * Use the first SECONDARY's original (its highlight will read at
  ///     full opacity, which is "wrong" but acceptable — better than no
  ///     silhouette at all).
  ///   * Last resort: front-chest, just to show *something*.
  Widget _buildPanel({
    required String origDir,
    required String maskDir,
    required List<String> primary,
    required List<String> secondary,
  }) {
    // Pick the base sheet — primary first, then secondary, then a hardcoded
    // fallback that exists in both light and dark folders.
    final String baseSheet;
    final List<String> remainingPrimaryAsMasks;
    final List<String> secondaryAsMasks;
    if (primary.isNotEmpty) {
      baseSheet = primary.first;
      remainingPrimaryAsMasks = primary.skip(1).toList();
      secondaryAsMasks = secondary;
    } else if (secondary.isNotEmpty) {
      // No primary on this side — borrow a secondary's original for the
      // silhouette. Its highlight will appear at full opacity (not 50%)
      // because there's no separate "base body" PNG anymore. Acceptable
      // trade-off: most workouts have at least one primary per active side,
      // so this branch rarely fires.
      baseSheet = secondary.first;
      remainingPrimaryAsMasks = const [];
      secondaryAsMasks = secondary.skip(1).toList();
    } else {
      // Shouldn't reach here — `build` short-circuits when a side has
      // nothing — but be defensive in case the call site ever asks us
      // to render an empty side.
      baseSheet = 'front-chest';
      remainingPrimaryAsMasks = const [];
      secondaryAsMasks = const [];
    }

    return _BodyPanel(
      baseOriginalPath: '$origDir/$baseSheet.png',
      primaryMaskPaths:
          remainingPrimaryAsMasks.map((s) => '$maskDir/$s.png').toList(),
      secondaryMaskPaths:
          secondaryAsMasks.map((s) => '$maskDir/$s.png').toList(),
      aspectRatio: _nativeWidth / _nativeHeight,
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
  });

  final String baseOriginalPath;
  final List<String> primaryMaskPaths;
  final List<String> secondaryMaskPaths;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          // 1. Original PNG — silhouette + first highlight baked in.
          Image.asset(
            baseOriginalPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          // 2. Secondary masks at half opacity — drawn before remaining
          //    primaries so a stray pixel overlap reads as "secondary
          //    tinted under primary" rather than the other way around.
          for (final path in secondaryMaskPaths)
            Opacity(
              opacity: 0.5,
              child: Image.asset(
                path,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          // 3. Remaining primary masks at full opacity.
          for (final path in primaryMaskPaths)
            Image.asset(
              path,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
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

  /// Every unique front-sheet filename stem matched by any name in [targets].
  static Set<String> frontSheetsFor(List<String> targets) {
    final out = <String>{};
    for (final raw in targets) {
      final key = MuscleMap.normalize(raw);
      final hit = _front[key];
      if (hit != null) out.add(hit);
    }
    return out;
  }

  /// Every unique back-sheet filename stem matched by any name in [targets].
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
