import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/themes/domain/app_theme_data.dart';
import '../../features/themes/domain/theme_registry.dart';
import '../../features/themes/providers/theme_providers.dart';

/// iOS-native palette tokens, themed by the user's currently-equipped pack.
///
/// `AppColors.of(context)` resolves the active [AppThemeData] from the
/// nearest [ProviderScope] and maps its fields onto a [Palette] for the
/// current brightness. Widgets remain unaware of themes — they read tokens
/// (accent, surface, background, …) and the right values appear.
///
/// To force a full-app rebuild when the theme changes, the root [DrillFitApp]
/// watches `activeThemeProvider`; that propagates through `CupertinoApp` so
/// all descendants get a fresh build with the new palette.
abstract final class AppColors {
  /// Returns a palette appropriate to the current brightness AND the active
  /// theme. When the [ProviderScope] is unavailable (e.g. early in startup
  /// before `runApp`), falls back to the default theme.
  static Palette of(BuildContext context) {
    final brightness =
        CupertinoTheme.of(context).brightness ??
        MediaQuery.platformBrightnessOf(context);
    final theme = _readActiveTheme(context);
    return brightness == Brightness.light
        ? Palette._light(theme)
        : Palette._dark(theme);
  }

  /// Direct factory for the (theme × brightness) → Palette mapping, used by
  /// the app root where the CupertinoTheme isn't established yet so
  /// [of] would fall back to the platform brightness.
  static Palette resolve({
    required AppThemeData theme,
    required Brightness brightness,
  }) {
    return brightness == Brightness.light
        ? Palette._light(theme)
        : Palette._dark(theme);
  }

  static AppThemeData _readActiveTheme(BuildContext context) {
    try {
      return ProviderScope.containerOf(
        context,
        listen: false,
      ).read(activeThemeProvider);
    } catch (_) {
      // ProviderScope not in the tree — only happens in unit/widget tests
      // that pump a Cupertino app without Riverpod. Default is fine.
      return defaultTheme;
    }
  }

  // ───────────────────────────────────────────────────────────────
  //  Legacy aliases — kept as compile-time constants pointing at the
  //  default-theme dark palette (the Field Manual since reskin batch
  //  #2). These are referenced from places that need a colour at
  //  compile time (e.g. const widgets). Anything that *can* take a
  //  Palette should call `AppColors.of(context)` instead so it picks
  //  up the equipped theme.
  // ───────────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF1A1C1A); // ink
  static const Color darkSurface = Color(0xFF21241F); // field
  static const Color darkSurfaceBorder = Color(0x1FE8E4D8); // bone hairline
  static const Color darkSearchField = Color(0xFF2A2E26); // field-raised

  /// Was purple, then system blue — now Field Manual brass.
  static const Color purple = Color(0xFFC8A24B);
  static const Color purpleLight = Color(0xFFE0C27E);
  static const Color purpleDark = Color(0xFFA38443);

  /// Was lime — now bone (primary text on dark).
  static const Color lime = Color(0xFFE8E4D8);

  static const Color darkText = Color(0xFFE8E4D8); // bone
  static const Color darkTextSecondary = Color(0xFFCDC8BA); // muted bone

  // ─── Light mode legacy aliases ──────────────────────────────
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF8A6937); // brass-ink
  static const Color lightCta = Color(0xFF8A6937);
  static const Color lightText = Color(0xFF000000);

  // ─── Shared accents ─────────────────────────────────────────
  static const Color error = Color(0xFFFF453A);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color success = Color(0xFF3FBF4A);

  // ─── Bottom nav ─────────────────────────────────────────────
  static const Color bottomNavBar = Color(0xFF1A1C1A); // ink

  // ─── Accent tints ────────────────────────────────────────────
  static const Color accentPressed = Color(0xFFA38443); // brass-pressed
  static const Color accentTint = Color(0x2EC8A24B);

  // ─── Activity rings (Apple Fitness inspired) ────────────────
  static const Color ringMove = Color(0xFFFA114F);
  static const Color ringExercise = Color(0xFF92E82A);
  static const Color ringStand = Color(0xFF00C2FF);

  // ─── Macro nutrients ─────────────────────────────────────────
  static const Color macroProtein = Color(0xFFE55B5B);
  static const Color macroCarbs = Color(0xFFF0A830);
  static const Color macroFat = Color(0xFF6FBF73);

  // ─── Brightness-only fallbacks ──────────────────────────────
  //  Some code paths still want a compile-time-constant Palette (e.g. as
  //  a hard fallback inside the tutorial overlay). These mirror the
  //  original midnight-blue palette so consumers don't accidentally
  //  resolve a black-on-black palette.
  static const Palette dark = Palette._defaultDark();
  static const Palette light = Palette._defaultLight();
}

/// Bundle of theme-aware colour tokens. One instance per (brightness × theme).
/// Construct via [AppColors.of] — the internal factory constructors below
/// are how we map an [AppThemeData] onto these tokens.
class Palette {
  const Palette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.separator,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentPressed,
    required this.accentLight,
    required this.success,
    required this.destructive,
    required this.warning,
  });

  // Dark mode mapping. Background and surface come from the theme directly.
  // Chrome tokens (text, borders, elevated surface) come from the theme when
  // it defines them — the Field Manual default does — and otherwise fall back
  // to the classic iOS values so legacy packs render exactly as before.
  // Destructive/warning stay fixed to iOS system reds/oranges so semantic
  // alerts don't fade into accent-colour soup.
  //
  // Not `const` — the initializers read from a runtime [AppThemeData].
  Palette._dark(AppThemeData theme)
    : background = theme.darkBackground,
      surface = theme.darkSurface,
      surfaceElevated = theme.darkSurfaceElevated ?? const Color(0xFF2C2C2E),
      border = theme.darkBorder ?? const Color(0x1FFFFFFF),
      separator = theme.darkSeparator ?? const Color(0x14FFFFFF),
      text = theme.darkText ?? const Color(0xFFFFFFFF),
      textSecondary = theme.darkTextSecondary ?? const Color(0xFF8E8E93),
      textTertiary = theme.darkTextTertiary ?? const Color(0xFF8E8E93),
      accent = theme.accent,
      accentPressed = theme.accentPressed ?? theme.accent,
      accentLight = theme.accentLight,
      success = theme.success,
      destructive = const Color(0xFFFF453A),
      warning = const Color(0xFFFF9F0A);

  // Light mode mapping. Background/surface stay fixed (Apple grouped-light
  // tokens — themes don't override these because most themes are dark-mode
  // optimised). Only the accent shifts to the theme's contrast-safe variant.
  Palette._light(AppThemeData theme)
    : background = const Color(0xFFF2F2F7),
      surface = const Color(0xFFFFFFFF),
      surfaceElevated = const Color(0xFFF2F2F7),
      border = const Color(0x1A000000),
      separator = const Color(0x0F000000),
      text = const Color(0xFF000000),
      textSecondary = const Color(0xFF8E8E93),
      textTertiary = const Color(0xFF3C3C43),
      accent = theme.lightAccent,
      accentPressed = theme.lightAccent,
      accentLight = theme.accentLight,
      success = theme.success,
      destructive = const Color(0xFFFF3B30),
      warning = const Color(0xFFFF9500);

  // Compile-time-constant fallbacks. Mirror the default Field Manual palette
  // so any const-context use of `AppColors.dark`/`.light` still resolves to
  // a sensible colour.
  const Palette._defaultDark()
    : background = const Color(0xFF1A1C1A),
      surface = const Color(0xFF21241F),
      surfaceElevated = const Color(0xFF2A2E26),
      border = const Color(0x1FE8E4D8),
      separator = const Color(0x14E8E4D8),
      text = const Color(0xFFE8E4D8),
      textSecondary = const Color(0xFFCDC8BA),
      textTertiary = const Color(0xFF8C9377), // lifted olive, ≥4.5:1 on ink
      accent = const Color(0xFFC8A24B),
      accentPressed = const Color(0xFFA38443),
      accentLight = const Color(0xFFE0C27E),
      success = const Color(0xFF3FBF4A),
      destructive = const Color(0xFFFF453A),
      warning = const Color(0xFFFF9F0A);

  const Palette._defaultLight()
    : background = const Color(0xFFF2F2F7),
      surface = const Color(0xFFFFFFFF),
      surfaceElevated = const Color(0xFFF2F2F7),
      border = const Color(0x1A000000),
      separator = const Color(0x0F000000),
      text = const Color(0xFF000000),
      textSecondary = const Color(0xFF8E8E93),
      textTertiary = const Color(0xFF3C3C43),
      accent = const Color(0xFF8A6937),
      accentPressed = const Color(0xFF8A6937),
      accentLight = const Color(0xFFE0C27E),
      success = const Color(0xFF34C759),
      destructive = const Color(0xFFFF3B30),
      warning = const Color(0xFFFF9500);

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color separator;
  final Color text;
  final Color textSecondary;

  /// Tertiary/inactive structure — inactive tab items, disabled meta. On the
  /// Field Manual default this is olive, which never carries reading text
  /// (the Olive Floor Rule).
  final Color textTertiary;
  final Color accent;

  /// Readable tone for text/icons sitting ON the accent fill: ink for bright
  /// accents (brass and most packs), bone for the dark ones (e.g. Stealth).
  /// Hardcoding ink on accent breaks dark packs — always use this.
  Color get onAccent => accent.computeLuminance() >= 0.18
      ? const Color(0xFF1A1C1A)
      : const Color(0xFFE8E4D8);

  /// Pressed/held state of accent-filled controls.
  final Color accentPressed;
  final Color accentLight;
  final Color success;
  final Color destructive;
  final Color warning;
}
