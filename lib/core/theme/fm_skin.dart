import 'package:flutter/painting.dart';

import '../../features/themes/domain/app_theme_data.dart';

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
        titleWeight = 600;

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
    );
  }
}
