import 'package:flutter/material.dart';

import '../../../../data/muscle_map.dart';

/// Composited anatomy diagram.
///
/// Built from pre-extracted assets in `assets/images/anatomy/masks/`:
///   * `base_front.png` / `base_back.png` — un-highlighted body silhouette
///   * one transparent-background PNG per muscle group with only the
///     highlight pixels surviving
///
/// At render time we draw the base body, then overlay every requested
/// primary mask at full opacity, then every secondary mask at 50% opacity.
/// Standard `BlendMode.srcOver` compositing — no fancy blending — because
/// the masks are already transparent everywhere except the highlight zone.
/// That kills the body-pixel ghosting the previous lighten-based overlay
/// produced for multi-muscle workouts.
///
/// Names are resolved through [MuscleMap.normalize] and a thin canonical-to-
/// filename mapping; if the supplied muscle has no PNG, the side simply
/// shows the base body so the widget never collapses.
///
/// Two display modes:
///   * Compact (`height: 120`) — single PNG side (whichever has more hits).
///   * Full   (`height: 280`) — front + back side by side when both have hits.
class MuscleHighlightWidget extends StatelessWidget {
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

  // PNG masks were exported at 669×1410 native; aspect ratio determines the
  // per-panel width given a fixed render height.
  static const double _nativeWidth = 669;
  static const double _nativeHeight = 1410;

  /// Legend swatch helpers — used to draw the colour key next to the figure.
  static Color targetColor(Color accent) => accent.withValues(alpha: 0.75);
  static Color secondaryColor(Color accent) => accent.withValues(alpha: 0.35);

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final dir = brightness == Brightness.light
        ? 'assets/images/anatomy/light/masks'
        : 'assets/images/anatomy/masks';

    final primaryFront = _AnatomySheets.frontSheetsFor(targetMuscles).toList();
    final primaryBack = _AnatomySheets.backSheetsFor(targetMuscles).toList();
    final secFrontAll = _AnatomySheets.frontSheetsFor(secondaryMuscles);
    final secBackAll = _AnatomySheets.backSheetsFor(secondaryMuscles);
    // Drop secondary sheets that are already drawn as primary so we don't
    // stack a half-opacity layer over an already-fully-painted highlight.
    final secondaryFront =
        secFrontAll.where((s) => !primaryFront.contains(s)).toList();
    final secondaryBack =
        secBackAll.where((s) => !primaryBack.contains(s)).toList();

    final hasFront = primaryFront.isNotEmpty || secondaryFront.isNotEmpty;
    final hasBack = primaryBack.isNotEmpty || secondaryBack.isNotEmpty;

    // Pick which body sides to render.
    final showFront = compact
        ? (hasFront && primaryFront.length >= primaryBack.length)
        : (hasFront || !hasBack);
    final showBack = compact
        ? (!showFront && hasBack)
        : (hasBack || (!hasFront && !showFront));

    // If nothing matched at all, still show a single empty front body so
    // the section never collapses to zero height (matches the old behaviour).
    if (!showFront && !showBack) {
      return _layout(
        height: height,
        children: [
          _BodyPanel(
            basePath: '$dir/base_front.png',
            primaryMasks: const [],
            secondaryMasks: const [],
            aspectRatio: _nativeWidth / _nativeHeight,
          ),
        ],
      );
    }

    final panels = <Widget>[];
    if (showFront) {
      panels.add(_BodyPanel(
        basePath: '$dir/base_front.png',
        primaryMasks: primaryFront.map((s) => '$dir/$s.png').toList(),
        secondaryMasks: secondaryFront.map((s) => '$dir/$s.png').toList(),
        aspectRatio: _nativeWidth / _nativeHeight,
      ));
    }
    if (showBack) {
      panels.add(_BodyPanel(
        basePath: '$dir/base_back.png',
        primaryMasks: primaryBack.map((s) => '$dir/$s.png').toList(),
        secondaryMasks: secondaryBack.map((s) => '$dir/$s.png').toList(),
        aspectRatio: _nativeWidth / _nativeHeight,
      ));
    }

    return _layout(height: height, children: panels);
  }

  Widget _layout({required double height, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: children.length == 1
            ? Center(child: children.first)
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: children,
              ),
      ),
    );
  }
}

/// One body side — base + primary masks (full opacity) + secondary masks
/// (50% opacity). Uses `Stack` of `Image.asset` widgets because the masks
/// are already transparent everywhere except the highlight zone, so plain
/// srcOver compositing produces the correct visual without any custom paint.
class _BodyPanel extends StatelessWidget {
  const _BodyPanel({
    required this.basePath,
    required this.primaryMasks,
    required this.secondaryMasks,
    required this.aspectRatio,
  });

  final String basePath;
  final List<String> primaryMasks;
  final List<String> secondaryMasks;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Un-highlighted body silhouette.
          Image.asset(
            basePath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          // 2. Secondary highlights — half opacity, drawn before primary so
          //    a stray pixel overlap reads as "secondary tinted under primary"
          //    rather than the other way around.
          for (final path in secondaryMasks)
            Opacity(
              opacity: 0.5,
              child: Image.asset(
                path,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          // 3. Primary highlights at full opacity.
          for (final path in primaryMasks)
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
