import 'package:flutter/painting.dart';

/// One purchasable visual palette. Pure data — built into the binary via the
/// static registry in `theme_registry.dart`, never persisted. The user's
/// equipped + owned themes are stored separately in the `UserThemeState`
/// Isar collection.
///
/// Field map vs the existing [Palette]:
///   accent          → Palette.accent (dark mode)
///   lightAccent     → Palette.accent (light mode)  — split so each theme can
///                     pick a contrast-safe accent for white backgrounds
///   accentLight     → secondary/hover tint, used by progress bars and chips
///   success         → Palette.success (semantic green, often theme-tinted)
///   surfaceTint     → mixed into surface colours in dark mode for the theme
///                     to "show through" on cards
///   darkBackground  → Palette.background (dark mode)
///   darkSurface     → Palette.surface (dark mode)
///
/// The optional chrome tokens below let a theme restyle the fixed parts of
/// the dark palette (text, borders, elevated surfaces). They exist so the
/// default Field Manual theme can carry bone text and hairline bone borders
/// while every legacy pack keeps its original iOS values via the fallbacks
/// in `Palette._dark` — packs stay accent swaps, per DESIGN.md.
class AppThemeData {
  const AppThemeData({
    required this.id,
    required this.name,
    required this.accent,
    required this.accentLight,
    required this.success,
    required this.surfaceTint,
    required this.darkBackground,
    required this.darkSurface,
    required this.lightAccent,
    required this.price,
    this.isPremium = false,
    this.accentPressed,
    this.darkText,
    this.darkTextSecondary,
    this.darkTextTertiary,
    this.darkSurfaceElevated,
    this.darkBorder,
    this.darkSeparator,
    this.cardRadius,
    this.sheetRadius,
    this.buttonRadius,
    this.borderWidth,
    this.displayFontFamily,
    this.bodyFontFamily,
    this.monoFontFamily,
    this.displayWeight,
    this.headlineWeight,
    this.titleWeight,
    this.cashPriceCents,
    this.ownedByDefault = false,
  });

  final String id;
  final String name;

  // ── Colour tokens ────────────────────────────────────────────────────────
  final Color accent;
  final Color accentLight;
  final Color success;
  final Color surfaceTint;
  final Color darkBackground;
  final Color darkSurface;
  final Color lightAccent;

  // ── Optional chrome tokens (null → Palette's classic iOS fallbacks) ─────
  /// Pressed/held state of accent-filled controls.
  final Color? accentPressed;

  /// Primary text and icons on dark surfaces.
  final Color? darkText;

  /// Secondary text that must still be read.
  final Color? darkTextSecondary;

  /// Tertiary/inactive structure — inactive tabs, disabled meta.
  final Color? darkTextTertiary;

  /// The rare second surface step: active inputs, pressed cards.
  final Color? darkSurfaceElevated;

  /// Card/panel borders.
  final Color? darkBorder;

  /// Row separators (weaker than [darkBorder]).
  final Color? darkSeparator;

  // ── Optional full-skin tokens (null → Field Manual defaults) ──────────────
  // Accent-swap packs leave every one of these null and resolve to the FM
  // values in [FmSkin.fromTheme], so they stay byte-identical. A "full skin"
  // (Night Ops) sets them to restyle geometry and type beyond the accent —
  // per DESIGN.md this is a new tier above the Accent Swap Rule, not a change
  // to it. Colours already flow through the surface/accent tokens above.

  /// Card/panel corner radius (FM default 8).
  final double? cardRadius;

  /// Sheet/dialog corner radius (FM default 12).
  final double? sheetRadius;

  /// Button/input corner radius (FM default 4).
  final double? buttonRadius;

  /// Hairline border/frame width (FM default 1).
  final double? borderWidth;

  /// Display face family for the bark — display/headline/title (FM 'Oswald').
  /// Body (Inter) and mono (JetBrainsMono) stay stable unless a skin also
  /// overrides them — legibility first.
  final String? displayFontFamily;

  /// Reading face family — body/prompt (FM 'Inter').
  final String? bodyFontFamily;

  /// Instrument-panel face family — label/readout/finePrint (FM 'JetBrainsMono').
  final String? monoFontFamily;

  /// Variable-font wght for `display()` (FM 700), `headline()` (FM 600),
  /// `title()` (FM 600). A skin may push the display face heavier/lighter.
  final double? displayWeight;
  final double? headlineWeight;
  final double? titleWeight;

  // ── Commerce ─────────────────────────────────────────────────────────────
  /// Price in coins — the app's single currency, earned in-app (workouts,
  /// streaks, PRs, etc.). 0 = free / always owned / sold outside the coin
  /// economy (see [cashPriceCents]).
  final int price;
  final bool isPremium;

  /// Real-money price in US cents for a *cash* theme pack (a full skin sold
  /// for money, not coins). Non-null marks a future StoreKit product. Kept
  /// out of the coin economy: such themes carry `price: 0` so they never
  /// register as standard coin themes and are never Airborne-unlocked.
  /// The IAP/StoreKit wiring is deferred — see [ownedByDefault].
  final int? cashPriceCents;

  /// Granted to every user without purchase — the implicit default, free
  /// grants, and cash products in **preview** while their IAP is unwired.
  /// Lets a cash skin be equipped/tested on device before StoreKit exists.
  final bool ownedByDefault;
}
