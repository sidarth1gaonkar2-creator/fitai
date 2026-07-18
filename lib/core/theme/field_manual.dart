import 'package:flutter/widgets.dart';

import 'fm_skin.dart';

/// Field Manual design tokens — the app's target visual spec (DESIGN.md).
///
/// First adopted by the Airborne paywall; new and reworked screens build on
/// these. The Field Manual is dark by doctrine: these colors do not follow
/// system brightness or the equipped theme pack. Per DESIGN.md's Accent Swap
/// Rule, theme packs swap the accent on app chrome only — Airborne brand
/// moments always wear brass.
abstract final class FieldManual {
  // ── Active skin ───────────────────────────────────────────────────────────
  // Full skins (Night Ops, …) restyle surfaces, geometry, and type beyond the
  // accent. `DrillFitApp` writes this from the equipped theme, and the whole
  // tree rebuilds on change — so these statics resolve the live skin with no
  // per-widget wiring. Defaults to the Field Manual look, so every accent-swap
  // pack (which overrides nothing) renders byte-identically.
  static FmSkin skin = const FmSkin.fieldManual();

  // ── Surfaces (skin-driven) ────────────────────────────────────────────────

  /// Screen background.
  static Color get ink => skin.ink;

  /// Cards, panels, sheets — one tonal step above ink.
  static Color get field => skin.field;

  /// The rare second step: active inputs, pressed cards, selected surfaces.
  static Color get fieldRaised => skin.fieldRaised;

  // ── Geometry (skin-driven) ────────────────────────────────────────────────

  /// Card/panel corner radius (FM 8). Chokepoint surfaces (CupertinoCard) read
  /// this; ad-hoc `BorderRadius.circular(...)` literals are not yet tokenised.
  static double get cardRadius => skin.cardRadius;

  /// Sheet/dialog corner radius (FM 12).
  static double get sheetRadius => skin.sheetRadius;

  /// Button/input corner radius (FM 4).
  static double get buttonRadius => skin.buttonRadius;

  /// Hairline border/frame width (FM 1).
  static double get borderWidth => skin.borderWidth;

  // ── Text & accents ────────────────────────────────────────────────────────

  /// Primary text and icons.
  static const bone = Color(0xFFE8E4D8);

  /// Secondary text that must still be read (≥4.5:1 on ink).
  static const mutedBone = Color(0xFFCDC8BA);

  /// The command accent: primary actions, selection, emphasis.
  static const brass = Color(0xFFC8A24B);

  /// Pressed/held state of brass surfaces.
  static const brassPressed = Color(0xFFA38443);

  /// Secondary structure only — large labels, dividers-with-presence. Never
  /// reading text (fails 4.5:1 on ink at body sizes — the Olive Floor Rule).
  static const olive = Color(0xFF6B7257);

  /// Destructive actions and consequences. Not an accent.
  static const alert = Color(0xFFC24A38);

  /// Brass for light surfaces: dark enough to hold 4.5:1 on white. FM
  /// surfaces are always dark, but Airborne accents also appear on themed
  /// app chrome, which can be light.
  static const brassInk = Color(0xFF8A6937);

  // ── Borders (bone at low alpha, never gray hexes) ─────────────────────────

  static const hairline = Color(0x1FE8E4D8); // 12%
  static const hairlineStrong = Color(0x29E8E4D8); // 16%

  /// The Airborne accent readable against [background]: brass on dark
  /// surfaces, [brassInk] on light ones.
  static Color brassOn(Color background) =>
      background.computeLuminance() < 0.5 ? brass : brassInk;

  // ── Type ──────────────────────────────────────────────────────────────────
  // The three FM faces ship as variable fonts (pubspec.yaml); weight is
  // selected via FontVariation because Flutter does not map FontWeight onto a
  // variable font's wght axis. fontWeight is still set for synthesis fallback
  // and semantics. All sizes ride the ambient TextScaler (Dynamic Type).

  static List<FontVariation> _wght(double w) => [FontVariation('wght', w)];

  /// Screen titles, ceremony headlines, rank names. Uppercase commands only.
  static TextStyle display({Color color = bone}) => TextStyle(
        fontFamily: skin.displayFamily,
        fontVariations: _wght(skin.displayWeight),
        fontWeight: FontWeight.w700,
        fontSize: 28,
        height: 1.05,
        letterSpacing: 0.3,
        color: color,
      );

  /// Section headers and card group titles. Uppercase.
  static TextStyle headline({Color color = bone}) => TextStyle(
        fontFamily: skin.displayFamily,
        fontVariations: _wght(skin.headlineWeight),
        fontWeight: FontWeight.w600,
        fontSize: 21,
        height: 1.1,
        letterSpacing: 0.35,
        color: color,
      );

  /// Card headings, exercise names, list row leads. Uppercase.
  static TextStyle title({Color color = bone}) => TextStyle(
        fontFamily: skin.displayFamily,
        fontVariations: _wght(skin.titleWeight),
        fontWeight: FontWeight.w600,
        fontSize: 16,
        height: 1.2,
        letterSpacing: 0.4,
        color: color,
      );

  /// Reading text: descriptions, coach chat, settings. Sentence case, never
  /// uppercase — the sergeant shouts headlines, not paragraphs.
  static TextStyle body({Color color = bone, double fontSize = 15}) =>
      TextStyle(
        fontFamily: skin.bodyFamily,
        fontVariations: _wght(400),
        fontWeight: FontWeight.w400,
        fontSize: fontSize,
        height: 1.45,
        color: color,
      );

  /// Sentence-case screen heading in the reading face — for onboarding
  /// questions and prompts ("What's your name?") that must NOT wear the
  /// uppercase-command Oswald [display]/[headline] faces. Inter at heading
  /// weight and size.
  static TextStyle prompt({Color color = bone}) => TextStyle(
        fontFamily: skin.bodyFamily,
        fontVariations: _wght(600),
        fontWeight: FontWeight.w600,
        fontSize: 22,
        height: 1.2,
        color: color,
      );

  /// Mono designation labels: eyebrows, stamps, chips. Uppercase, tracked.
  static TextStyle label({Color color = mutedBone, double fontSize = 11}) =>
      TextStyle(
        fontFamily: skin.monoFamily,
        fontVariations: _wght(700),
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
        height: 1.3,
        letterSpacing: fontSize * 0.12,
        color: color,
      );

  /// Instrument-panel values: weights, reps, streaks, targets, prices.
  /// Tabular by face; sized to read at arm's length.
  static TextStyle readout({Color color = bone, double fontSize = 18}) =>
      TextStyle(
        fontFamily: skin.monoFamily,
        fontVariations: _wght(700),
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
        height: 1.2,
        letterSpacing: 0.5,
        color: color,
      );

  /// Fine print that must stay legible: terms, disclosures. Mono, quiet,
  /// but mutedBone — never olive (the Olive Floor Rule).
  static TextStyle finePrint({Color color = mutedBone}) => TextStyle(
        fontFamily: skin.monoFamily,
        fontVariations: _wght(500),
        fontWeight: FontWeight.w500,
        fontSize: 11,
        height: 1.5,
        letterSpacing: 0.2,
        color: color,
      );
}
