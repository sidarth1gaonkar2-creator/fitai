import 'package:flutter/material.dart';

/// Design-token colour palette derived from the Figma kit.
abstract final class AppColors {
  // ─── Dark mode ──────────────────────────────────────────────
  static const darkBackground = Color(0xFF1A1A1A);
  static const darkSurface = Color(0xFF242424);
  static const darkSurfaceBorder = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)
  static const darkSearchField = Color(0xFF2E2E2E);

  static const purple = Color(0xFF7B5CF6);
  static const purpleLight = Color(0xFFA78BFA);
  static const purpleDark = Color(0xFF3D2FA0);
  static const lime = Color(0xFFC8F135);

  static const darkText = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFA78BFA);

  // ─── Light mode ─────────────────────────────────────────────
  static const lightBackground = Color(0xFFF5F5F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightPrimary = Color(0xFF6D4FE0);
  static const lightCta = Color(0xFF8DB000);
  static const lightText = Color(0xFF1A1A1A);

  // ─── Shared accents ─────────────────────────────────────────
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF22C55E);

  // ─── Bottom nav ─────────────────────────────────────────────
  static const bottomNavBar = Color(0xFF7B5CF6);
}
