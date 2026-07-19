import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/field_manual.dart';
import 'core/theme/fm_skin.dart';
import 'core/utils/logger.dart';
import 'features/themes/providers/theme_providers.dart';
import 'features/tutorial/presentation/tutorial_overlay.dart';
import 'providers/auth_provider.dart';
import 'providers/gym_streak_provider.dart';
import 'providers/isar_provider.dart';
import 'providers/notification_reconciler.dart';
import 'routing/app_router.dart';
import 'services/revenuecat_service.dart';

class DrillFitApp extends ConsumerWidget {
  const DrillFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // SESSION COORDINATOR (uid-scoping batch, audit §4): the single choke
    // point every sign-in AND sign-out converges through — including passive
    // ones (token expiry/revocation), which previously cleared nothing. On
    // each account transition it swaps the active per-account Isar instance
    // FIRST (publish-new-before-close-old, serialized inside the session
    // manager), THEN runs the per-user reconcilers so they read the incoming
    // account's data, not the outgoing one's.
    ref.listen(currentUserIdProvider, (prev, next) {
      if (next == prev) return;
      final session = ref.read(isarSessionManagerProvider);
      final reconciler = ref.read(notificationReconcilerProvider);
      // RevenueCat identity rides the same transition (never a per-call-site
      // concern): bind purchases to the incoming uid, or back to an anonymous
      // id on sign-out — so purchases can never land under an anonymous
      // RevenueCat id while a Firebase user is signed in. Independent of the
      // Isar swap below; runs concurrently and never throws (logs internally).
      unawaited(RevenueCatService.instance.setFirebaseUid(next));
      unawaited(
        session.switchToUid(next).then((_) async {
          if (next != null) {
            // reconcile() re-runs syncSchedules() for the incoming user
            // internally (permission-gated) — no separate call needed.
            await reconciler.reconcile();
            // Catch up the gym streak after time away: BREAK-DETECTION ONLY —
            // this resets a streak broken by a missed scheduled gym day while
            // the app was closed. It must NOT award coins; awards happen only
            // on workout finish.
            await ref.read(gymStreakProvider.notifier).reconcile();
          } else {
            await reconciler.cancelPersonal();
          }
        }).catchError((Object e, StackTrace st) {
          AppLogger.error('Session coordinator: account transition failed',
              error: e, stack: st);
        }),
      );
    });

    // Watch the equipped theme so the entire app rebuilds when the user
    // equips a new pack — that's what propagates the new accent / surface
    // colours through `AppColors.of(context)` everywhere downstream.
    final activeTheme = ref.watch(activeThemeProvider);
    // Full skins (Night Ops, …) may restyle surfaces, geometry, and type
    // beyond the accent. Resolve the equipped theme into the app-wide
    // FieldManual skin BEFORE building, so every FM-routed surface and type
    // token re-skins on equip; the whole tree rebuilds below. Accent-swap
    // packs resolve to the FM defaults, so they stay byte-identical.
    final skin = FmSkin.fromTheme(activeTheme);
    FieldManual.skin = skin;
    // Start rasterizing this skin's tiles now rather than on first paint.
    // Tile rasterization is asynchronous (see SurfaceTexture.ensureTile), so
    // kicking it off at equip time means it is normally ready before the first
    // frame that needs it; if it isn't, the surface paints its base colour for
    // a frame and repaints via SurfaceTexture.tilesReady. Accent-swap packs
    // have no textures, so this is a no-op for them.
    skin.surfaceTexture?.ensureTile();
    skin.headerTexture?.ensureTile();
    // Light mode retired (batch #3): the Field Manual is dark by doctrine.
    // AppColors keeps its light mappings for theme packs / a possible future
    // "Daylight Ops" pack, so the resolve(theme:, brightness:) shape stays.
    const brightness = Brightness.dark;
    // Derive the palette directly from the active theme, since this widget
    // sits above the ProviderScope's CupertinoApp and can't go through
    // `AppColors.of(context)` for itself.
    final palette = AppColors.resolve(theme: activeTheme, brightness: brightness);
    // Bone on every pack — packs are accent swaps on Field Manual chrome —
    // via the palette's text token.
    final textColor = palette.text;

    return CupertinoApp.router(
      title: 'DrillFit',
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
        // Ink on the accent, not bone — this is the on-accent contrasting tone
        // Cupertino paints atop primaryColor fills.
        primaryContrastingColor: palette.onAccent,
        scaffoldBackgroundColor: palette.background,
        barBackgroundColor: palette.background.withValues(alpha: 0.8),
        // Field Manual faces (DESIGN.md): Inter carries reading text, Oswald
        // carries nav titles (the bark). Colours track the equipped palette.
        textTheme: CupertinoTextThemeData(
          primaryColor: palette.accent,
          textStyle: TextStyle(
            fontFamily: skin.bodyFamily,
            color: textColor,
            fontSize: 15,
            height: 1.45,
          ),
          navTitleTextStyle: TextStyle(
            fontFamily: skin.displayFamily,
            fontVariations: [FontVariation('wght', skin.headlineWeight)],
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: 0.4,
            color: textColor,
          ),
          navLargeTitleTextStyle: TextStyle(
            fontFamily: skin.displayFamily,
            fontVariations: [FontVariation('wght', skin.displayWeight)],
            fontWeight: FontWeight.w700,
            fontSize: 30,
            height: 1.05,
            letterSpacing: 0.3,
            color: textColor,
          ),
          navActionTextStyle: TextStyle(
            fontFamily: skin.bodyFamily,
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
        // Always the dark Material theme — the Field Manual is dark by
        // doctrine.
        return Theme(
          data: AppTheme.dark,
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
