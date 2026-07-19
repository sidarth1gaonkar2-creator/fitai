import 'package:flutter/painting.dart';

import '../../features/themes/domain/app_theme_data.dart';
import 'surface_texture.dart';

/// The resolved, app-wide "skin" behind [FieldManual] — the surface, geometry,
/// and type tokens that a *full skin* (e.g. Night Ops) may override beyond the
/// accent. A theme that overrides nothing resolves to [FmSkin.fieldManual],
/// the shipping Field Manual defaults, so every accent-swap pack renders
/// byte-identically to before full skins existed.
///
/// **Why a global, not an InheritedWidget:** the equipped theme is global (one
/// per app) and `DrillFitApp` rebuilds the entire tree when it changes. It
/// writes this skin via `FieldManual.skin = FmSkin.fromTheme(...)` on every
/// theme change, so [FieldManual]'s statics resolve the live skin with zero
/// per-widget plumbing — the injection point that keeps this a capability
/// addition, not a mass edit of ~1300 static call sites.
class FmSkin {
  const FmSkin({
    required this.ink,
    required this.field,
    required this.fieldRaised,
    required this.cardRadius,
    required this.sheetRadius,
    required this.buttonRadius,
    required this.borderWidth,
    required this.displayFamily,
    required this.bodyFamily,
    required this.monoFamily,
    required this.displayWeight,
    required this.headlineWeight,
    required this.titleWeight,
    required this.alert,
    this.displayTrackingEm,
    this.surfaceTexture,
    this.headerTexture,
    this.headerBandHeight = 0,
    this.cardBrackets = false,
    this.accentGlow = false,
  });

  // ── Surfaces ──────────────────────────────────────────────────────────────
  final Color ink;
  final Color field;
  final Color fieldRaised;

  // ── Geometry ──────────────────────────────────────────────────────────────
  final double cardRadius;
  final double sheetRadius;
  final double buttonRadius;
  final double borderWidth;

  // ── Type: families ────────────────────────────────────────────────────────
  final String displayFamily; // display / headline / title (the bark)
  final String bodyFamily; // body / prompt (reading text)
  final String monoFamily; // label / readout / finePrint (instrument panel)

  // ── Type: display-face weights (variable-font wght axis) ──────────────────
  final double displayWeight;
  final double headlineWeight;
  final double titleWeight;

  /// Display-face letter-spacing as a fraction of font size. Null → keep FM's
  /// absolute per-style values untouched (every non-Woodland theme).
  final double? displayTrackingEm;

  /// Destructive/alert tone. Default FM brick red; a skin whose ACCENT is red
  /// (Night Ops infrared) routes this off red — to amber — so alerts never
  /// collide with the accent.
  final Color alert;

  // ── Material: the "full skin" tier ────────────────────────────────────────
  /// Mottled dark texture painted behind background/header surfaces. Null on
  /// accent-swap themes → solid fills, byte-identical.
  final SurfaceTexture? surfaceTexture;

  /// Optional second material banded across the top of the ground, faded into
  /// [surfaceTexture]. Null on every skin but Dress Blues.
  final SurfaceTexture? headerTexture;

  /// Height in logical pixels of the [headerTexture] band.
  final double headerBandHeight;

  /// HUD viewport treatment on cards: hairline frame + corner brackets.
  final bool cardBrackets;

  /// Lets the accent bloom on true black (HUD signal). Off by default; on for
  /// Night Ops, where DESIGN.md's quiet-chrome rule is relaxed for a HUD.
  final bool accentGlow;

  bool get hasTexture => surfaceTexture != null;

  /// The Field Manual defaults — the shipping look. Every value matches the
  /// constants [FieldManual] carried before full skins, so a theme that
  /// overrides nothing is pixel-for-pixel unchanged.
  const FmSkin.fieldManual()
      : ink = const Color(0xFF1A1C1A),
        field = const Color(0xFF21241F),
        fieldRaised = const Color(0xFF2A2E26),
        cardRadius = 8,
        sheetRadius = 12,
        buttonRadius = 4,
        borderWidth = 1,
        displayFamily = 'Oswald',
        bodyFamily = 'Inter',
        monoFamily = 'JetBrainsMono',
        displayWeight = 700,
        headlineWeight = 600,
        titleWeight = 600,
        alert = const Color(0xFFC24A38),
        displayTrackingEm = null,
        surfaceTexture = null,
        headerTexture = null,
        headerBandHeight = 0,
        cardBrackets = false,
        accentGlow = false;

  /// Resolve a theme's optional full-skin overrides against the FM defaults.
  /// Surfaces reuse the theme's existing colour tokens (`darkBackground`,
  /// `darkSurface`, `darkSurfaceElevated`) — every shipped theme sets these to
  /// the FM constants today, so this stays byte-identical for them, and a full
  /// skin (Night Ops) changes them by setting those same colour fields.
  factory FmSkin.fromTheme(AppThemeData t) {
    const fm = FmSkin.fieldManual();
    return FmSkin(
      ink: t.darkBackground,
      field: t.darkSurface,
      fieldRaised: t.darkSurfaceElevated ?? fm.fieldRaised,
      cardRadius: t.cardRadius ?? fm.cardRadius,
      sheetRadius: t.sheetRadius ?? fm.sheetRadius,
      buttonRadius: t.buttonRadius ?? fm.buttonRadius,
      borderWidth: t.borderWidth ?? fm.borderWidth,
      displayFamily: t.displayFontFamily ?? fm.displayFamily,
      bodyFamily: t.bodyFontFamily ?? fm.bodyFamily,
      monoFamily: t.monoFontFamily ?? fm.monoFamily,
      displayWeight: t.displayWeight ?? fm.displayWeight,
      headlineWeight: t.headlineWeight ?? fm.headlineWeight,
      titleWeight: t.titleWeight ?? fm.titleWeight,
      alert: t.darkAlert ?? fm.alert,
      displayTrackingEm: t.displayTrackingEm,
      surfaceTexture: t.surfaceTexture,
      headerTexture: t.headerTexture,
      headerBandHeight: t.headerBandHeight,
      cardBrackets: t.cardBrackets,
      accentGlow: t.accentGlow,
    );
  }
}
