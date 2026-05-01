import 'package:flutter/cupertino.dart';

/// iOS-native black & white palette with blue as the only accent.
///
/// Use [AppColors.dark] / [AppColors.light] for the two palette sets, or
/// [AppColors.of] to pick the correct one based on the current theme
/// brightness.
///
/// Legacy top-level fields (`purple`, `lime`, `darkBackground`, …) are kept
/// as compile-time aliases pointing at the dark palette so the rest of the
/// app picks up the new colour scheme without any other edits.
abstract final class AppColors {
  // ─── Palette sets ────────────────────────────────────────────
  static const Palette dark = Palette(
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    surfaceElevated: Color(0xFF2C2C2E),
    border: Color(0x1FFFFFFF),
    separator: Color(0x14FFFFFF),
    text: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8E8E93),
    accent: Color(0xFF0A84FF),
    success: Color(0xFF32D74B),
    destructive: Color(0xFFFF453A),
    warning: Color(0xFFFF9F0A),
  );

  static const Palette light = Palette(
    background: Color(0xFFF2F2F7),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF2F2F7),
    border: Color(0x1A000000),
    separator: Color(0x0F000000),
    text: Color(0xFF000000),
    textSecondary: Color(0xFF8E8E93),
    accent: Color(0xFF007AFF),
    success: Color(0xFF34C759),
    destructive: Color(0xFFFF3B30),
    warning: Color(0xFFFF9500),
  );

  /// Returns the palette appropriate for the current brightness.
  static Palette of(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness ??
        MediaQuery.platformBrightnessOf(context);
    return brightness == Brightness.light ? light : dark;
  }

  // ───────────────────────────────────────────────────────────────
  //  Legacy aliases — bound to the dark palette
  //  (the app is dark-first; light mode resolves through `of`).
  // ───────────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkSurfaceBorder = Color(0x1FFFFFFF);
  static const Color darkSearchField = Color(0xFF2C2C2E);

  /// Was purple — now the iOS dark mode system blue accent.
  static const Color purple = Color(0xFF0A84FF);
  static const Color purpleLight = Color(0xFF64B5FF);
  static const Color purpleDark = Color(0xFF0050A0);

  /// Was lime — now white text in dark mode.
  static const Color lime = Color(0xFFFFFFFF);

  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E8E93);

  // ─── Light mode legacy aliases ──────────────────────────────
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF007AFF);
  static const Color lightCta = Color(0xFF007AFF);
  static const Color lightText = Color(0xFF000000);

  // ─── Shared accents ─────────────────────────────────────────
  static const Color error = Color(0xFFFF453A);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color success = Color(0xFF32D74B);

  // ─── Bottom nav ─────────────────────────────────────────────
  static const Color bottomNavBar = Color(0xFF000000);
}

/// Bundle of theme-aware colours. One instance per brightness, exposed via
/// [AppColors.dark], [AppColors.light], and [AppColors.of].
class Palette {
  const Palette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.separator,
    required this.text,
    required this.textSecondary,
    required this.accent,
    required this.success,
    required this.destructive,
    required this.warning,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color separator;
  final Color text;
  final Color textSecondary;
  final Color accent;
  final Color success;
  final Color destructive;
  final Color warning;
}
