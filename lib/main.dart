import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/database/isar_service.dart';
import 'core/utils/logger.dart';
import 'core/utils/notif_diag_log.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/firestore_provider.dart';
import 'providers/isar_provider.dart';
import 'providers/unit_system_provider.dart';
import 'services/notification_service.dart';
import 'services/pr_migration_service.dart';
import 'services/weight_migration_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kReleaseMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Something went wrong. Please restart the app.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    };
  }

  // Kick off heavy initialization immediately, but render the animated splash
  // on the very first frame so it animates WHILE Firebase, Isar, migrations
  // and notifications spin up in the background. When both the intro animation
  // and bootstrapping finish, [_onBootstrapComplete] swaps in the real app.
  final bootstrap = _bootstrap();
  runApp(SplashApp(bootstrap: bootstrap, onReady: _onBootstrapComplete));
}

/// Initializes every backend service the app needs. Never throws — failures of
/// the two hard requirements (Firebase, Isar) are returned as a failed
/// [BootstrapResult] so the splash can hand off to a fatal-error screen;
/// best-effort steps (dotenv, migrations, notifications) only log.
Future<BootstrapResult> _bootstrap() async {
  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (e, st) {
    AppLogger.error('dotenv load failed', error: e, stack: st);
  }

  // Firebase — hard requirement.
  try {
    await Firebase.initializeApp();
  } catch (e, st) {
    AppLogger.error('Firebase init FAILED', error: e, stack: st);
    return BootstrapResult.failed(StartupPhase.firebase, e, st);
  }

  // Crashlytics — route Flutter and platform errors to Firebase. Disabled in
  // debug mode so dev-time exceptions don't pollute prod reports.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);

  // A release build that shipped without the AI proxy configured would silently
  // disable the AI Coach — a misbuilt .env must be loud. Record a non-fatal so
  // it surfaces in Crashlytics instead of failing quietly in the field.
  if (kReleaseMode) {
    final proxy = dotenv.isInitialized ? dotenv.env['AI_PROXY_URL'] : null;
    if (proxy == null || proxy.isEmpty) {
      AppLogger.error('AI Coach disabled by configuration (AI_PROXY_URL empty)');
      await FirebaseCrashlytics.instance.recordError(
        StateError('AI Coach disabled by configuration'),
        StackTrace.current,
        reason: 'AI_PROXY_URL missing/empty in a release build',
        fatal: false,
      );
    }
  }

  // Resolve the persisted Firebase auth state NOW, before the real app mounts,
  // so the router can start on the correct route (a signed-in user goes
  // straight to /dashboard, never flashing the welcome screen). Bounded by a
  // timeout so a hung auth backend can't stall startup; we fall back to the
  // synchronously-cached currentUser if the stream is slow.
  var isSignedIn = false;
  try {
    final user = await FirebaseAuth.instance
        .authStateChanges()
        .first
        .timeout(const Duration(seconds: 8));
    isSignedIn = user != null;
  } catch (e, st) {
    AppLogger.error('Auth state resolve failed/timed out', error: e, stack: st);
    isSignedIn = FirebaseAuth.instance.currentUser != null;
  }

  // Isar — hard requirement.
  Isar? isar;
  Object? initError;
  StackTrace? initStack;
  try {
    isar = await IsarService.initialize();
  } catch (e, st) {
    initError = e;
    initStack = st;
    AppLogger.error('Isar init FAILED', error: e, stack: st);
  }

  final prefs = await SharedPreferences.getInstance();

  // Wire the persistent [notif] ring buffer NOW, before NotificationService
  // .init() runs below — so the timezone-resolution and any cold-launch
  // schedule errors are captured and survive a restart (readable on-device
  // via the hidden Notification Diagnostics screen).
  NotifDiagLog.attach(prefs);

  // One-time data migrations (best-effort).
  if (isar != null) {
    final migrated = prefs.getBool('pr_migration_done') ?? false;
    if (!migrated) {
      try {
        await PRMigrationService.migrate(isar);
        await prefs.setBool('pr_migration_done', true);
      } catch (e, st) {
        AppLogger.error('PR migration failed', error: e, stack: st);
      }
    }

    // One-time imperial-corruption weight fix (lbs values stored as kg).
    final weightFixDone = prefs.getBool('weight_migration_done') ?? false;
    if (!weightFixDone) {
      try {
        await WeightMigrationService.migrate(isar);
        await prefs.setBool('weight_migration_done', true);
      } catch (e, st) {
        AppLogger.error('Weight migration failed', error: e, stack: st);
      }
    }
  }

  // Notifications (best-effort).
  try {
    await NotificationService.instance.init();
  } catch (e, st) {
    AppLogger.error('NotificationService init failed', error: e, stack: st);
  }

  if (isar == null) {
    return BootstrapResult.failed(StartupPhase.isar, initError, initStack);
  }
  return BootstrapResult.ready(isar, prefs, isSignedIn: isSignedIn);
}

/// Called by the splash once initialization AND the intro animation are both
/// done. Swaps the splash out for either the real app (fading in from the
/// shared dark background for a seamless crossfade) or the fatal-error screen.
void _onBootstrapComplete(BootstrapResult result) {
  if (!result.isReady) {
    runApp(_StartupErrorApp(
      phase: result.phase!,
      error: result.error,
      stack: result.stack,
    ));
    return;
  }
  runApp(
    _StartupFadeIn(
      child: ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(result.isar!),
          sharedPreferencesProvider.overrideWithValue(result.prefs!),
          firebaseAuthProvider.overrideWithValue(FirebaseAuth.instance),
          firestoreProvider.overrideWithValue(FirebaseFirestore.instance),
          storageProvider.overrideWithValue(FirebaseStorage.instance),
          bootSignedInProvider.overrideWithValue(result.isSignedIn),
        ],
        child: const DrillFitApp(),
      ),
    ),
  );
}

/// One-shot fade-in over the splash background, so the real app crossfades in
/// where the splash's logo faded out. Created once (it's the root passed to
/// runApp), so it animates exactly once at hand-off.
class _StartupFadeIn extends StatefulWidget {
  const _StartupFadeIn({required this.child});
  final Widget child;

  @override
  State<_StartupFadeIn> createState() => _StartupFadeInState();
}

class _StartupFadeInState extends State<_StartupFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: splashBackground,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Opacity(
          opacity: Curves.easeOut.transform(_controller.value),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.phase, this.error, this.stack});
  final StartupPhase phase;
  final Object? error;
  final StackTrace? stack;

  String get _subtitle {
    switch (phase) {
      case StartupPhase.firebase:
        return 'Firebase could not be initialized. '
            'GoogleService-Info.plist may be missing from the iOS bundle.';
      case StartupPhase.isar:
        return 'Local database (Isar) could not be opened.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0E0E12),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DrillFit failed to start',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _subtitle,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    Text(
                      '$error',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (stack != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        '$stack',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ] else ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Please reinstall the app or contact support if this persists.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
