import 'package:flutter/material.dart';

/// A purchasable visual palette. Stored statically — the catalogue ships
/// with the app binary; ownership and the currently-equipped theme are
/// persisted to SharedPreferences via the theme providers.
class AppThemePack {
  const AppThemePack({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    this.textColor,
    this.brightness = Brightness.dark,
    this.priceCoin = 0,
    this.priceGem = 0,
    this.isPremium = false,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String description;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color? textColor;
  final Brightness brightness;

  /// Price in earnable coins. Ignored when [isPremium] is true.
  final int priceCoin;

  /// Price in gems (premium / IAP currency). 0 unless [isPremium] is true.
  final int priceGem;

  /// Requires gems instead of coins.
  final bool isPremium;

  /// The starter theme — automatically owned by every user, never purchasable.
  final bool isDefault;
}

/// The full catalogue of themes shipped with the app. The first entry must
/// have `isDefault: true` so `theme_providers` can guarantee at least one
/// owned theme exists for every user.
const List<AppThemePack> availableThemes = [
  AppThemePack(
    id: 'midnight_blue',
    name: 'Midnight Blue',
    description: 'Deep blue tones for night owls.',
    isDefault: true,
    primaryColor: Color(0xFF0A84FF),
    accentColor: Color(0xFF0A84FF),
    backgroundColor: Color(0xFF0A0E1A),
    surfaceColor: Color(0xFF1A1F2E),
  ),
  AppThemePack(
    id: 'forest_green',
    name: 'Forest Green',
    description: 'Nature-inspired calm.',
    priceCoin: 100,
    primaryColor: Color(0xFF34C759),
    accentColor: Color(0xFF34C759),
    backgroundColor: Color(0xFF0A1A0E),
    surfaceColor: Color(0xFF1A2E1F),
  ),
  AppThemePack(
    id: 'sunset_orange',
    name: 'Sunset Orange',
    description: 'Warm and energetic.',
    priceCoin: 100,
    primaryColor: Color(0xFFFF9F0A),
    accentColor: Color(0xFFFF9F0A),
    backgroundColor: Color(0xFF1A0E0A),
    surfaceColor: Color(0xFF2E1F1A),
  ),
  AppThemePack(
    id: 'royal_purple',
    name: 'Royal Purple',
    description: 'Classic and bold.',
    priceCoin: 150,
    primaryColor: Color(0xFF7B5CF6),
    accentColor: Color(0xFF7B5CF6),
    backgroundColor: Color(0xFF1A1A1A),
    surfaceColor: Color(0xFF242424),
  ),
  AppThemePack(
    id: 'arctic_white',
    name: 'Arctic White',
    description: 'Clean light mode.',
    priceCoin: 150,
    primaryColor: Color(0xFF007AFF),
    accentColor: Color(0xFF007AFF),
    backgroundColor: Color(0xFFF5F5F7),
    surfaceColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF000000),
    brightness: Brightness.light,
  ),
  AppThemePack(
    id: 'cherry_blossom',
    name: 'Cherry Blossom',
    description: 'Soft pink aesthetics.',
    priceCoin: 200,
    primaryColor: Color(0xFFFF6B8A),
    accentColor: Color(0xFFFF6B8A),
    backgroundColor: Color(0xFF1A0E14),
    surfaceColor: Color(0xFF2E1A22),
  ),
  AppThemePack(
    id: 'neon_cyberpunk',
    name: 'Neon Cyberpunk',
    description: 'Electric neon vibes.',
    priceCoin: 300,
    primaryColor: Color(0xFF00FF88),
    accentColor: Color(0xFF00FF88),
    backgroundColor: Color(0xFF0A0A0F),
    surfaceColor: Color(0xFF1A1A25),
  ),
  // Premium (gems) — placeholders for future StoreKit hook-up.
  AppThemePack(
    id: 'golden_hour',
    name: 'Golden Hour',
    description: 'Luxury gold accents.',
    priceGem: 50,
    isPremium: true,
    primaryColor: Color(0xFFFFD700),
    accentColor: Color(0xFFFFD700),
    backgroundColor: Color(0xFF1A150A),
    surfaceColor: Color(0xFF2E281A),
  ),
  AppThemePack(
    id: 'holographic',
    name: 'Holographic',
    description: 'Iridescent gradient magic.',
    priceGem: 100,
    isPremium: true,
    primaryColor: Color(0xFFE040FB),
    accentColor: Color(0xFF00BCD4),
    backgroundColor: Color(0xFF0A0A1A),
    surfaceColor: Color(0xFF1A1A2E),
  ),
];

AppThemePack themeById(String id) =>
    availableThemes.firstWhere((t) => t.id == id, orElse: () => defaultTheme);

AppThemePack get defaultTheme =>
    availableThemes.firstWhere((t) => t.isDefault, orElse: () => availableThemes.first);
