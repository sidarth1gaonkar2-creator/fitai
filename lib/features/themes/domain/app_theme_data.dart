import 'package:flutter/painting.dart';

/// Currency types a theme can be priced in. Coins are earned in-app (workouts,
/// streaks, PRs, etc.); gems are reserved for premium themes that will hook
/// into StoreKit once IAP is wired up.
enum ThemeCurrency { coins, gems }

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
    required this.currency,
    this.isPremium = false,
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

  // ── Commerce ─────────────────────────────────────────────────────────────
  final int price;
  final ThemeCurrency currency;
  final bool isPremium;
}
