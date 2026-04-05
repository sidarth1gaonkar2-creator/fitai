import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ─── Font families ──────────────────────────────────────────
  static const _heading = 'Poppins';
  static const _body = 'LeagueSpartan';

  // ─── Page transitions ───────────────────────────────────────
  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  );

  // ─────────────────────────────────────────────────────────────
  //  DARK THEME
  // ─────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.purple,
      onPrimary: Colors.white,
      primaryContainer: AppColors.purpleDark,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.lime,
      onSecondary: Colors.black,
      secondaryContainer: AppColors.lime.withValues(alpha: 0.18),
      onSecondaryContainer: AppColors.lime,
      tertiary: AppColors.purpleLight,
      onTertiary: Colors.black,
      tertiaryContainer: AppColors.purpleDark,
      onTertiaryContainer: AppColors.purpleLight,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.error.withValues(alpha: 0.18),
      onErrorContainer: AppColors.error,
      surface: AppColors.darkBackground,
      onSurface: AppColors.darkText,
      surfaceContainerLowest: const Color(0xFF141414),
      surfaceContainerLow: const Color(0xFF1E1E1E),
      surfaceContainer: AppColors.darkSurface,
      surfaceContainerHigh: const Color(0xFF2A2A2A),
      surfaceContainerHighest: const Color(0xFF333333),
      onSurfaceVariant: const Color(0xFFB0B0B0),
      outline: AppColors.darkSurfaceBorder,
      outlineVariant: AppColors.darkSurfaceBorder,
      inverseSurface: Colors.white,
      onInverseSurface: AppColors.darkBackground,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      pageTransitionsTheme: _pageTransitions,

      // ── Typography ──────────────────────────────────────────
      textTheme: _buildTextTheme(Brightness.dark),
      fontFamily: _body,

      // ── AppBar ──────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ── Card ────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkSurfaceBorder),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Input / TextField ───────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSearchField,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(
          fontFamily: _body,
          color: Colors.white.withValues(alpha: 0.4),
        ),
        labelStyle: const TextStyle(fontFamily: _body),
      ),

      // ── Filled button (CTA) ────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.lime,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(
            fontFamily: _heading,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      // ── Outlined button ────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white),
          textStyle: const TextStyle(
            fontFamily: _heading,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      // ── Text button ────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.purple,
          textStyle: const TextStyle(
            fontFamily: _body,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── Icon button ─────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
        ),
      ),

      // ── Switch ──────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.lime;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lime.withValues(alpha: 0.4);
          }
          return Colors.white.withValues(alpha: 0.12);
        }),
      ),

      // ── Tab bar ─────────────────────────────────────────────
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xFFB0B0B0),
        indicatorColor: AppColors.lime,
        labelStyle: TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),

      // ── Dialog ──────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.purple,
        titleTextStyle: const TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
        contentTextStyle: TextStyle(
          fontFamily: _body,
          fontSize: 16,
          color: Colors.white.withValues(alpha: 0.9),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ── Bottom sheet ────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // ── Snack bar ──────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurface,
        contentTextStyle: const TextStyle(
          fontFamily: _body,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Divider ─────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.darkSurfaceBorder,
        thickness: 1,
      ),

      // ── Expansion tile ──────────────────────────────────────
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: Colors.white,
        collapsedIconColor: Color(0xFFB0B0B0),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  LIGHT THEME
  // ─────────────────────────────────────────────────────────────
  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.lightPrimary.withValues(alpha: 0.12),
      onPrimaryContainer: AppColors.lightPrimary,
      secondary: AppColors.lightCta,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.lightCta.withValues(alpha: 0.15),
      onSecondaryContainer: AppColors.lightCta,
      tertiary: AppColors.purpleLight,
      onTertiary: Colors.black,
      tertiaryContainer: AppColors.purpleLight.withValues(alpha: 0.15),
      onTertiaryContainer: AppColors.purpleLight,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.error.withValues(alpha: 0.12),
      onErrorContainer: AppColors.error,
      surface: AppColors.lightBackground,
      onSurface: AppColors.lightText,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF9F9F9),
      surfaceContainer: AppColors.lightSurface,
      surfaceContainerHigh: const Color(0xFFEEEEEE),
      surfaceContainerHighest: const Color(0xFFE0E0E0),
      onSurfaceVariant: const Color(0xFF6B6B6B),
      outline: const Color(0xFFD0D0D0),
      outlineVariant: const Color(0xFFE0E0E0),
      inverseSurface: AppColors.lightText,
      onInverseSurface: Colors.white,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      pageTransitionsTheme: _pageTransitions,
      textTheme: _buildTextTheme(Brightness.light),
      fontFamily: _body,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.lightPrimary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: const TextStyle(fontFamily: _body),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.lightCta,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: _heading,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          side: BorderSide(color: AppColors.lightPrimary),
          textStyle: const TextStyle(
            fontFamily: _heading,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          textStyle: const TextStyle(
            fontFamily: _body,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightCta;
          }
          return const Color(0xFFBBBBBB);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightCta.withValues(alpha: 0.4);
          }
          return const Color(0xFFE0E0E0);
        }),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.lightPrimary,
        unselectedLabelColor: const Color(0xFF6B6B6B),
        indicatorColor: AppColors.lightCta,
        labelStyle: const TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        titleTextStyle: const TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: AppColors.lightText,
        ),
        contentTextStyle: TextStyle(
          fontFamily: _body,
          fontSize: 16,
          color: AppColors.lightText.withValues(alpha: 0.8),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightText,
        contentTextStyle: const TextStyle(
          fontFamily: _body,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.08),
        thickness: 1,
      ),

      expansionTileTheme: ExpansionTileThemeData(
        iconColor: AppColors.lightText,
        collapsedIconColor: const Color(0xFF6B6B6B),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  TEXT THEME (shared structure, brightness-aware colours)
  // ─────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Brightness brightness) {
    final onSurface = brightness == Brightness.dark
        ? AppColors.darkText
        : AppColors.lightText;

    return TextTheme(
      // Headlines — Poppins
      displayLarge: TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.bold,
          fontSize: 34,
          color: onSurface),
      displayMedium: TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.bold,
          fontSize: 28,
          color: onSurface),
      displaySmall: TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.w600,
          fontSize: 24,
          color: onSurface),
      headlineLarge: TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.bold,
          fontSize: 28,
          color: onSurface),
      headlineMedium: TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: onSurface),
      headlineSmall: TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: onSurface),
      titleLarge: TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: onSurface),
      titleMedium: TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: onSurface),
      titleSmall: TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: onSurface),

      // Body / labels — League Spartan
      bodyLarge: TextStyle(
          fontFamily: _body,
          fontWeight: FontWeight.normal,
          fontSize: 16,
          color: onSurface),
      bodyMedium: TextStyle(
          fontFamily: _body,
          fontWeight: FontWeight.normal,
          fontSize: 14,
          color: onSurface),
      bodySmall: TextStyle(
          fontFamily: _body,
          fontWeight: FontWeight.normal,
          fontSize: 12,
          color: onSurface),
      labelLarge: TextStyle(
          fontFamily: _body,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: onSurface),
      labelMedium: TextStyle(
          fontFamily: _body,
          fontWeight: FontWeight.w500,
          fontSize: 12,
          color: onSurface),
      labelSmall: TextStyle(
          fontFamily: _body,
          fontWeight: FontWeight.w500,
          fontSize: 10,
          color: onSurface),
    );
  }
}
