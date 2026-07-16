import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Material shim for the widgets that still come from the Material library
/// (Scaffold, Switch internals, TextField internals, charts, …). The app is
/// Cupertino-first; this exists so those stragglers render in Field Manual
/// dress instead of Material defaults. Component values follow DESIGN.md:
/// sharp 4px buttons, 8px field cards, hairline bone borders, no shadows.
class AppTheme {
  AppTheme._();

  // ─── Font families (Field Manual faces, bundled in pubspec) ──
  static const _display = 'Oswald';
  static const _body = 'Inter';
  static const _mono = 'JetBrainsMono';

  // ─── Field Manual constants (see lib/core/theme/field_manual.dart) ──
  static const _ink = Color(0xFF1A1C1A);
  static const _field = Color(0xFF21241F);
  static const _fieldRaised = Color(0xFF2A2E26);
  static const _bone = Color(0xFFE8E4D8);
  static const _mutedBone = Color(0xFFCDC8BA);
  static const _brass = Color(0xFFC8A24B);
  static const _brassPressed = Color(0xFFA38443);
  static const _brassInk = Color(0xFF8A6937);
  static const _hairline = Color(0x1FE8E4D8);

  // ─── Page transitions ───────────────────────────────────────
  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  );

  // ─────────────────────────────────────────────────────────────
  //  DARK THEME (the Field Manual — dark by doctrine)
  // ─────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _brass,
      onPrimary: _ink,
      primaryContainer: _brassPressed,
      onPrimaryContainer: _ink,
      secondary: AppColors.success,
      onSecondary: _ink,
      secondaryContainer: AppColors.success.withValues(alpha: 0.18),
      onSecondaryContainer: AppColors.success,
      // Lifted olive — tertiary occasionally carries small text (difficulty
      // chips), so it must hold 4.5:1 on field surfaces.
      tertiary: Color(0xFF8C9377),
      onTertiary: _bone,
      tertiaryContainer: _fieldRaised,
      onTertiaryContainer: _bone,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.error.withValues(alpha: 0.18),
      onErrorContainer: AppColors.error,
      surface: _ink,
      onSurface: _bone,
      surfaceContainerLowest: _ink,
      surfaceContainerLow: _field,
      surfaceContainer: _field,
      surfaceContainerHigh: _fieldRaised,
      surfaceContainerHighest: _fieldRaised,
      onSurfaceVariant: _mutedBone,
      outline: _hairline,
      outlineVariant: _hairline,
      inverseSurface: _bone,
      onInverseSurface: _ink,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _ink,
      pageTransitionsTheme: _pageTransitions,

      // ── Typography ──────────────────────────────────────────
      textTheme: _buildTextTheme(Brightness.dark),
      fontFamily: _body,

      // ── AppBar ──────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: _ink,
        foregroundColor: _bone,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _display,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: 0.4,
          color: _bone,
        ),
        iconTheme: IconThemeData(color: _bone),
      ),

      // ── Card ────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: _field,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _hairline),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Input / TextField ───────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _fieldRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: _hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: _hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: _brass, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: const TextStyle(fontFamily: _body, color: _mutedBone),
        labelStyle: const TextStyle(fontFamily: _body, color: _mutedBone),
      ),

      // ── Filled button (CTA) ────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _brass,
          foregroundColor: _ink,
          textStyle: const TextStyle(
            fontFamily: _display,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.4,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      // ── Outlined button ────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _bone,
          side: const BorderSide(color: _hairline),
          textStyle: const TextStyle(
            fontFamily: _display,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.4,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      // ── Text button ────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _brass,
          textStyle: const TextStyle(
            fontFamily: _body,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── Icon button ─────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: _bone),
      ),

      // ── Switch ──────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _ink;
          return _bone;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _brass;
          return _fieldRaised;
        }),
      ),

      // ── Tab bar ─────────────────────────────────────────────
      tabBarTheme: const TabBarThemeData(
        labelColor: _bone,
        unselectedLabelColor: _mutedBone,
        indicatorColor: _brass,
        labelStyle: TextStyle(
          fontFamily: _display,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.4,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: _display,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 0.4,
        ),
      ),

      // ── Dialog ──────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: _field,
        titleTextStyle: const TextStyle(
          fontFamily: _display,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: 0.4,
          color: _bone,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: _body,
          fontSize: 16,
          height: 1.45,
          color: _mutedBone,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _hairline),
        ),
      ),

      // ── Bottom sheet ────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _field,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),

      // ── Snack bar ──────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _fieldRaised,
        contentTextStyle: const TextStyle(fontFamily: _body, color: _bone),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _hairline),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Divider ─────────────────────────────────────────────
      dividerTheme: const DividerThemeData(color: _hairline, thickness: 1),

      // ── Chips (filter/choice) ───────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: _field,
        selectedColor: _brass.withValues(alpha: 0.18),
        side: const BorderSide(color: _hairline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        labelStyle: const TextStyle(
          fontFamily: _body,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _bone,
        ),
        iconTheme: const IconThemeData(color: _mutedBone, size: 16),
        checkmarkColor: _brass,
      ),

      // ── Expansion tile ──────────────────────────────────────
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: _bone,
        collapsedIconColor: _mutedBone,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  LIGHT THEME (non-FM surfaces only — FM screens are dark by
  //  doctrine; this keeps grouped-light stragglers coherent with a
  //  contrast-safe brass accent)
  // ─────────────────────────────────────────────────────────────
  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _brassInk,
      onPrimary: Colors.white,
      primaryContainer: _brassInk.withValues(alpha: 0.12),
      onPrimaryContainer: _brassInk,
      secondary: _brassInk,
      onSecondary: Colors.white,
      secondaryContainer: _brassInk.withValues(alpha: 0.15),
      onSecondaryContainer: _brassInk,
      tertiary: const Color(0xFF6B7257),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFF6B7257).withValues(alpha: 0.15),
      onTertiaryContainer: const Color(0xFF6B7257),
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

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _display,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: 0.4,
          color: AppColors.lightText,
        ),
        iconTheme: IconThemeData(color: AppColors.lightText),
      ),

      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: _brassInk, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        labelStyle: const TextStyle(fontFamily: _body),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _brassInk,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: _display,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.4,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _brassInk,
          side: const BorderSide(color: _brassInk),
          textStyle: const TextStyle(
            fontFamily: _display,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.4,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _brassInk,
          textStyle: const TextStyle(
            fontFamily: _body,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return const Color(0xFFBBBBBB);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _brassInk;
          return const Color(0xFFE0E0E0);
        }),
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: _brassInk,
        unselectedLabelColor: Color(0xFF6B6B6B),
        indicatorColor: _brassInk,
        labelStyle: TextStyle(
          fontFamily: _display,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.4,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: _display,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 0.4,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        titleTextStyle: const TextStyle(
          fontFamily: _display,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: 0.4,
          color: AppColors.lightText,
        ),
        contentTextStyle: TextStyle(
          fontFamily: _body,
          fontSize: 16,
          height: 1.45,
          color: AppColors.lightText.withValues(alpha: 0.8),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightText,
        contentTextStyle: const TextStyle(
          fontFamily: _body,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.08),
        thickness: 1,
      ),

      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: AppColors.lightText,
        collapsedIconColor: Color(0xFF6B6B6B),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  TEXT THEME — Field Manual roles mapped onto Material slots:
  //  display/headline/title → Oswald (the bark), body → Inter (the
  //  briefing), labels → JetBrains Mono (the instrument panel).
  // ─────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Brightness brightness) {
    final onSurface = brightness == Brightness.dark
        ? _bone
        : AppColors.lightText;
    final onSurfaceMuted = brightness == Brightness.dark
        ? _mutedBone
        : const Color(0xFF6B6B6B);

    return TextTheme(
      // Display / headlines — Oswald
      displayLarge: TextStyle(
        fontFamily: _display,
        fontWeight: FontWeight.w700,
        fontSize: 34,
        height: 1.05,
        letterSpacing: 0.3,
        color: onSurface,
      ),
      displayMedium: TextStyle(
        fontFamily: _display,
        fontWeight: FontWeight.w700,
        fontSize: 28,
        height: 1.05,
        letterSpacing: 0.3,
        color: onSurface,
      ),
      displaySmall: TextStyle(
        fontFamily: _display,
        fontWeight: FontWeight.w600,
        fontSize: 24,
        height: 1.1,
        letterSpacing: 0.35,
        color: onSurface,
      ),
      headlineLarge: TextStyle(
        fontFamily: _display,
        fontWeight: FontWeight.w700,
        fontSize: 28,
        height: 1.05,
        letterSpacing: 0.3,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: _display,
        fontWeight: FontWeight.w700,
        fontSize: 24,
        height: 1.1,
        letterSpacing: 0.35,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: _display,
        fontWeight: FontWeight.w600,
        fontSize: 20,
        height: 1.1,
        letterSpacing: 0.35,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: _display,
        fontWeight: FontWeight.w600,
        fontSize: 20,
        height: 1.2,
        letterSpacing: 0.4,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: _display,
        fontWeight: FontWeight.w600,
        fontSize: 16,
        height: 1.2,
        letterSpacing: 0.4,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: _display,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.2,
        letterSpacing: 0.4,
        color: onSurface,
      ),

      // Body — Inter, sentence case, never uppercase
      bodyLarge: TextStyle(
        fontFamily: _body,
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.45,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: _body,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.45,
        color: onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: _body,
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 1.45,
        color: onSurfaceMuted,
      ),

      // Labels — JetBrains Mono, the instrument panel
      labelLarge: TextStyle(
        fontFamily: _mono,
        fontWeight: FontWeight.w700,
        fontSize: 13,
        letterSpacing: 1.3,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: _mono,
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 1.1,
        color: onSurfaceMuted,
      ),
      labelSmall: TextStyle(
        fontFamily: _mono,
        fontWeight: FontWeight.w500,
        fontSize: 10,
        letterSpacing: 0.8,
        color: onSurfaceMuted,
      ),
    );
  }
}
