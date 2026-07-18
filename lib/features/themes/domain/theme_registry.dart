import 'package:flutter/painting.dart';

import 'app_theme_data.dart';

/// Static catalogue of all themes shipped with the app. Order here defines
/// the order shown in the store grid. The first entry MUST be the default
/// (free, always owned) so [defaultTheme] never returns null.
///
/// Since reskin batch #3 the Accent Swap Rule (DESIGN.md) holds for real:
/// every pack is an accent swap riding Field Manual chrome. Surfaces
/// (ink/field/field-raised), bone text, hairline borders, and the FM success
/// green are identical across packs — a pack contributes only its accent
/// family (accent, accentLight, accentPressed, lightAccent) and its identity
/// (id, name, price, isPremium). The packs' own surface colours — pure
/// blacks, tinted darks — are gone by design, not by accident.
///
/// accentPressed is derived per pack: each channel of the accent × 0.82
/// (≈18% darker), the same ratio that takes brass 0xFFC8A24B to
/// brass-pressed 0xFFA38443.

// ── Shared Field Manual chrome (every pack rides these) ─────────────────────
const Color _ink = Color(0xFF1A1C1A);
const Color _field = Color(0xFF21241F);
const Color _fieldRaised = Color(0xFF2A2E26);
const Color _bone = Color(0xFFE8E4D8);
const Color _mutedBone = Color(0xFFCDC8BA);
// Lifted olive: the FM olive raised to hold ≥4.5:1 on ink so inactive tab
// labels stay AA-legible (base olive #6B7257 is 3.4:1 — structure only, per
// the Olive Floor Rule).
const Color _liftedOlive = Color(0xFF8C9377);
const Color _hairline = Color(0x1FE8E4D8); // bone @12%
const Color _separator = Color(0x14E8E4D8); // bone @8%
const Color _fmSuccess = Color(0xFF3FBF4A);

const List<AppThemeData> themeRegistry = [
  // 1. Default — the Field Manual: brass on ink, the app's brand issue
  // (DESIGN.md). The id stays 'midnight_blue' so installs that persisted the
  // old default in UserThemeState keep resolving to the default theme.
  AppThemeData(
    id: 'midnight_blue',
    name: 'Field Manual',
    accent: Color(0xFFC8A24B), // brass
    accentLight: Color(0xFFE0C27E),
    success: _fmSuccess,
    surfaceTint: Color(0xFFC8A24B),
    darkBackground: _ink,
    darkSurface: _field,
    lightAccent: Color(0xFF8A6937), // brass-ink, AA on white
    price: 0,
    accentPressed: Color(0xFFA38443), // brass × 0.82 — the reference ratio
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: _fieldRaised,
    darkBorder: _hairline,
    darkSeparator: _separator,
  ),

  // 2. Slate — monochrome / minimalist. Free unlock on first launch.
  AppThemeData(
    id: 'slate',
    name: 'Slate',
    accent: Color(0xFF8E8E93),
    accentLight: Color(0xFFA0A0A5),
    success: _fmSuccess,
    surfaceTint: Color(0xFF8E8E93),
    darkBackground: _ink,
    darkSurface: _field,
    lightAccent: Color(0xFF636366), // WCAG AA-safe on white
    price: 0,
    accentPressed: Color(0xFF747479), // 0x8E8E93 × 0.82
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: _fieldRaised,
    darkBorder: _hairline,
    darkSeparator: _separator,
  ),

  // 3. Emerald — green energy.
  AppThemeData(
    id: 'emerald',
    name: 'Emerald',
    accent: Color(0xFF30D158),
    accentLight: Color(0xFFA8F0C1),
    success: _fmSuccess,
    surfaceTint: Color(0xFF30D158),
    darkBackground: _ink,
    darkSurface: _field,
    lightAccent: Color(0xFF248A3D), // darker green for AA contrast
    price: 500,
    accentPressed: Color(0xFF27AB48), // 0x30D158 × 0.82
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: _fieldRaised,
    darkBorder: _hairline,
    darkSeparator: _separator,
  ),

  // 4. Sunset — warm amber.
  AppThemeData(
    id: 'sunset',
    name: 'Sunset',
    accent: Color(0xFFFF9F0A),
    accentLight: Color(0xFFFFD60A),
    success: _fmSuccess,
    surfaceTint: Color(0xFFFF9F0A),
    darkBackground: _ink,
    darkSurface: _field,
    lightAccent: Color(0xFFC76E00),
    price: 500,
    accentPressed: Color(0xFFD18208), // 0xFF9F0A × 0.82
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: _fieldRaised,
    darkBorder: _hairline,
    darkSeparator: _separator,
  ),

  // 5. Crimson — red.
  AppThemeData(
    id: 'crimson',
    name: 'Crimson',
    accent: Color(0xFFFF453A),
    accentLight: Color(0xFFFF6B6B),
    success: _fmSuccess,
    surfaceTint: Color(0xFFFF453A),
    darkBackground: _ink,
    darkSurface: _field,
    lightAccent: Color(0xFFC2261B),
    price: 750,
    accentPressed: Color(0xFFD13930), // 0xFF453A × 0.82
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: _fieldRaised,
    darkBorder: _hairline,
    darkSeparator: _separator,
  ),

  // 6. Ocean — aqua / cyan.
  AppThemeData(
    id: 'ocean',
    name: 'Ocean',
    accent: Color(0xFF64D2FF),
    accentLight: Color(0xFF40C8E0),
    success: _fmSuccess,
    surfaceTint: Color(0xFF64D2FF),
    darkBackground: _ink,
    darkSurface: _field,
    lightAccent: Color(0xFF0080A8),
    price: 750,
    accentPressed: Color(0xFF52ACD1), // 0x64D2FF × 0.82
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: _fieldRaised,
    darkBorder: _hairline,
    darkSeparator: _separator,
  ),

  // 7. Lavender — purple.
  AppThemeData(
    id: 'lavender',
    name: 'Lavender',
    accent: Color(0xFFBF5AF2),
    accentLight: Color(0xFFDA9FFA),
    success: _fmSuccess,
    surfaceTint: Color(0xFFBF5AF2),
    darkBackground: _ink,
    darkSurface: _field,
    lightAccent: Color(0xFF8E2BC2),
    price: 1000,
    accentPressed: Color(0xFF9D4AC6), // 0xBF5AF2 × 0.82
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: _fieldRaised,
    darkBorder: _hairline,
    darkSeparator: _separator,
  ),

  // 8. Neon Pulse — premium, magenta + indigo.
  AppThemeData(
    id: 'neon_pulse',
    name: 'Neon Pulse',
    accent: Color(0xFFFF2D55),
    accentLight: Color(0xFF5E5CE6),
    success: _fmSuccess,
    surfaceTint: Color(0xFFFF2D55),
    darkBackground: _ink,
    darkSurface: _field,
    lightAccent: Color(0xFFD60036),
    price: 2000,
    isPremium: true,
    accentPressed: Color(0xFFD12546), // 0xFF2D55 × 0.82
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: _fieldRaised,
    darkBorder: _hairline,
    darkSeparator: _separator,
  ),

  // 9. Stealth — premium, monochrome gunmetal. The accent is a lifted cool
  // grey, not the near-black 0xFF48484A it shipped as: on FM chrome that old
  // tone was 1.7:1 on field (invisible as text/border/icon). Lifted to
  // 0xFF8A9098 — still a desaturated gunmetal, distinct from Slate's neutral
  // 0xFF8E8E93 by its cooler blue cast — which reads 4.88:1 on field and
  // 5.33:1 on ink, and clears the 0.18-luminance onAccent flip (ink on accent).
  AppThemeData(
    id: 'stealth',
    name: 'Stealth',
    accent: Color(0xFF8A9098),
    accentLight: Color(0xFFB0B4BA),
    success: _fmSuccess,
    surfaceTint: Color(0xFF8A9098),
    darkBackground: _ink,
    darkSurface: _field,
    lightAccent: Color(0xFF4B5058), // darker gunmetal, AA on white
    price: 2000,
    isPremium: true,
    accentPressed: Color(0xFF71767D), // 0x8A9098 × 0.82
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: _fieldRaised,
    darkBorder: _hairline,
    darkSeparator: _separator,
  ),
];

/// The default theme — guaranteed to be in [themeRegistry] (first entry).
/// Every user owns this theme implicitly. Mirrors the registry's Field
/// Manual entry exactly.
const AppThemeData defaultTheme = AppThemeData(
  id: 'midnight_blue',
  name: 'Field Manual',
  accent: Color(0xFFC8A24B),
  accentLight: Color(0xFFE0C27E),
  success: _fmSuccess,
  surfaceTint: Color(0xFFC8A24B),
  darkBackground: _ink,
  darkSurface: _field,
  lightAccent: Color(0xFF8A6937),
  price: 0,
  accentPressed: Color(0xFFA38443),
  darkText: _bone,
  darkTextSecondary: _mutedBone,
  darkTextTertiary: _liftedOlive,
  darkSurfaceElevated: _fieldRaised,
  darkBorder: _hairline,
  darkSeparator: _separator,
);

/// Resolves a theme by ID, falling back to [defaultTheme] when the ID isn't
/// in the registry (e.g. a removed theme that's still equipped on an old
/// install).
AppThemeData themeById(String id) {
  for (final t in themeRegistry) {
    if (t.id == id) return t;
  }
  return defaultTheme;
}
