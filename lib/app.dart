import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/themes/providers/theme_providers.dart';
import 'features/tutorial/presentation/tutorial_overlay.dart';
import 'providers/settings_providers.dart';
import 'routing/app_router.dart';

class FitAIApp extends ConsumerWidget {
  const FitAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Watch the equipped theme so the entire app rebuilds when the user
    // equips a new pack — that's what propagates the new accent / surface
    // colours through `AppColors.of(context)` everywhere downstream.
    final activeTheme = ref.watch(activeThemeProvider);
    final isLight = themeMode == ThemeMode.light;
    final brightness = isLight ? Brightness.light : Brightness.dark;
    // Derive the palette directly from the active theme, since this widget
    // sits above the ProviderScope's CupertinoApp and can't go through
    // `AppColors.of(context)` for itself.
    final palette = AppColors.resolve(theme: activeTheme, brightness: brightness);
    final textColor =
        isLight ? CupertinoColors.black : CupertinoColors.white;

    return CupertinoApp.router(
      title: 'AtlasFit',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
      ],
      theme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: palette.accent,
        primaryContrastingColor: palette.text,
        scaffoldBackgroundColor: palette.background,
        barBackgroundColor: palette.background.withValues(alpha: 0.8),
        textTheme: CupertinoTextThemeData(
          primaryColor: palette.accent,
          textStyle: TextStyle(
            fontFamily: 'Poppins',
            color: textColor,
            fontSize: 15,
          ),
          navTitleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: textColor,
          ),
          navLargeTitleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 32,
            color: textColor,
          ),
          navActionTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: palette.accent,
          ),
        ),
      ),
      // Wrap with a Theme + transparent Material so remaining Material
      // widgets (Card, ListTile, Switch, TextField internals, etc.) inherit
      // the correct dark ThemeData and continue to render correctly during
      // and after the Cupertino migration.
      builder: (context, child) {
        // Material widgets that remain in the tree need a ThemeData ancestor.
        // We always feed them the dark Material theme since the app's surfaces
        // are still dark-grouped even in light mode (white cards over the
        // light grouped background).
        return Theme(
          data: isLight ? AppTheme.light : AppTheme.dark,
          child: Material(
            type: MaterialType.transparency,
            // Tutorial overlay floats above all routes — including modals and
            // sheets pushed via the router — because it's a sibling of the
            // entire navigation tree. Self-gates on `tutorialActiveProvider`.
            child: Stack(
              children: [
                child ?? const SizedBox.shrink(),
                const Positioned.fill(child: TutorialOverlayHost()),
              ],
            ),
          ),
        );
      },
    );
  }
}
