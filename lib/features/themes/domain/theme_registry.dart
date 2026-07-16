import 'package:flutter/painting.dart';

import 'app_theme_data.dart';

/// Static catalogue of all themes shipped with the app. Order here defines
/// the order shown in the store grid. The first entry MUST be the default
/// (free, always owned) so [defaultTheme] never returns null.
const List<AppThemeData> themeRegistry = [
  // 1. Default — the Field Manual: brass on ink, the app's brand issue
  // (DESIGN.md). The id stays 'midnight_blue' so installs that persisted the
  // old default in UserThemeState keep resolving to the default theme.
  AppThemeData(
    id: 'midnight_blue',
    name: 'Field Manual',
    accent: Color(0xFFC8A24B), // brass
    accentLight: Color(0xFFE0C27E),
    success: Color(0xFF3FBF4A),
    surfaceTint: Color(0xFFC8A24B),
    darkBackground: Color(0xFF1A1C1A), // ink
    darkSurface: Color(0xFF21241F), // field
    lightAccent: Color(0xFF8A6937), // brass-ink, AA on white
    price: 0,
    accentPressed: Color(0xFFA38443), // brass-pressed
    darkText: Color(0xFFE8E4D8), // bone
    darkTextSecondary: Color(0xFFCDC8BA), // muted bone
    // Lifted olive: the FM olive raised to hold ≥4.5:1 on ink so inactive
    // tab labels stay AA-legible (base olive #6B7257 is 3.4:1 — structure
    // only, per the Olive Floor Rule).
    darkTextTertiary: Color(0xFF8C9377),
    darkSurfaceElevated: Color(0xFF2A2E26), // field-raised
    darkBorder: Color(0x1FE8E4D8), // bone @12%
    darkSeparator: Color(0x14E8E4D8), // bone @8%
  ),

  // 2. Slate — monochrome / minimalist. Free unlock on first launch.
  AppThemeData(
    id: 'slate',
    name: 'Slate',
    accent: Color(0xFF8E8E93),
    accentLight: Color(0xFFA0A0A5),
    success: Color(0xFF34C759),
    surfaceTint: Color(0xFF8E8E93),
    darkBackground: Color(0xFF000000),
    darkSurface: Color(0xFF1C1C1E),
    lightAccent: Color(0xFF636366), // WCAG AA-safe on white
    price: 0,
  ),

  // 3. Emerald — green energy.
  AppThemeData(
    id: 'emerald',
    name: 'Emerald',
    accent: Color(0xFF30D158),
    accentLight: Color(0xFFA8F0C1),
    success: Color(0xFF30D158),
    surfaceTint: Color(0xFF30D158),
    darkBackground: Color(0xFF000000),
    darkSurface: Color(0xFF0D1F12),
    lightAccent: Color(0xFF248A3D), // darker green for AA contrast
    price: 500,
  ),

  // 4. Sunset — warm amber.
  AppThemeData(
    id: 'sunset',
    name: 'Sunset',
    accent: Color(0xFFFF9F0A),
    accentLight: Color(0xFFFFD60A),
    success: Color(0xFF32D74B),
    surfaceTint: Color(0xFFFF9F0A),
    darkBackground: Color(0xFF000000),
    darkSurface: Color(0xFF1F1508),
    lightAccent: Color(0xFFC76E00),
    price: 500,
  ),

  // 5. Crimson — red.
  AppThemeData(
    id: 'crimson',
    name: 'Crimson',
    accent: Color(0xFFFF453A),
    accentLight: Color(0xFFFF6B6B),
    success: Color(0xFF32D74B),
    surfaceTint: Color(0xFFFF453A),
    darkBackground: Color(0xFF000000),
    darkSurface: Color(0xFF1F0C0A),
    lightAccent: Color(0xFFC2261B),
    price: 750,
  ),

  // 6. Ocean — aqua / cyan.
  AppThemeData(
    id: 'ocean',
    name: 'Ocean',
    accent: Color(0xFF64D2FF),
    accentLight: Color(0xFF40C8E0),
    success: Color(0xFF32D74B),
    surfaceTint: Color(0xFF64D2FF),
    darkBackground: Color(0xFF000000),
    darkSurface: Color(0xFF0A1520),
    lightAccent: Color(0xFF0080A8),
    price: 750,
  ),

  // 7. Lavender — purple.
  AppThemeData(
    id: 'lavender',
    name: 'Lavender',
    accent: Color(0xFFBF5AF2),
    accentLight: Color(0xFFDA9FFA),
    success: Color(0xFF32D74B),
    surfaceTint: Color(0xFFBF5AF2),
    darkBackground: Color(0xFF000000),
    darkSurface: Color(0xFF150A22),
    lightAccent: Color(0xFF8E2BC2),
    price: 1000,
  ),

  // 8. Neon Pulse — premium, magenta + indigo.
  AppThemeData(
    id: 'neon_pulse',
    name: 'Neon Pulse',
    accent: Color(0xFFFF2D55),
    accentLight: Color(0xFF5E5CE6),
    success: Color(0xFF32D74B),
    surfaceTint: Color(0xFFFF2D55),
    darkBackground: Color(0xFF0F0F14),
    darkSurface: Color(0xFF12101A),
    lightAccent: Color(0xFFD60036),
    price: 2000,
    isPremium: true,
  ),

  // 9. Stealth — premium, monochrome dark.
  AppThemeData(
    id: 'stealth',
    name: 'Stealth',
    accent: Color(0xFF48484A),
    accentLight: Color(0xFF636366),
    success: Color(0xFF32D74B),
    surfaceTint: Color(0xFF48484A),
    darkBackground: Color(0xFF000000),
    darkSurface: Color(0xFF0A0A0A),
    lightAccent: Color(0xFF1C1C1E),
    price: 2000,
    isPremium: true,
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
  success: Color(0xFF3FBF4A),
  surfaceTint: Color(0xFFC8A24B),
  darkBackground: Color(0xFF1A1C1A),
  darkSurface: Color(0xFF21241F),
  lightAccent: Color(0xFF8A6937),
  price: 0,
  accentPressed: Color(0xFFA38443),
  darkText: Color(0xFFE8E4D8),
  darkTextSecondary: Color(0xFFCDC8BA),
  darkTextTertiary: Color(0xFF8C9377), // lifted olive, ≥4.5:1 on ink
  darkSurfaceElevated: Color(0xFF2A2E26),
  darkBorder: Color(0x1FE8E4D8),
  darkSeparator: Color(0x14E8E4D8),
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
