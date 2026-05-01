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
import 'providers/auth_provider.dart';
import 'providers/firestore_provider.dart';
import 'providers/isar_provider.dart';
import 'providers/unit_system_provider.dart';
import 'services/notification_service.dart';
import 'services/pr_migration_service.dart';

void main() async {
  debugPrint('[startup] main() entered');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[startup] WidgetsFlutterBinding initialized');

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

  try {
    await dotenv.load(fileName: 'assets/.env');
    debugPrint('[startup] dotenv loaded');
  } catch (e, st) {
    debugPrint('[startup] dotenv load failed: $e\n$st');
  }

  // Firebase init
  try {
    await Firebase.initializeApp();
    debugPrint('[startup] Firebase initialized');
  } catch (e, st) {
    debugPrint('[startup] Firebase init FAILED: $e\n$st');
    runApp(_StartupErrorApp(phase: _StartupPhase.firebase, error: e, stack: st));
    return;
  }

  // Crashlytics — route Flutter and platform errors to Firebase. Disabled
  // in debug mode so dev-time exceptions don't pollute prod reports.
  FlutterError.onError =
      FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  debugPrint('[startup] Crashlytics configured (enabled=${!kDebugMode})');

  Isar? isar;
  Object? initError;
  StackTrace? initStack;
  debugPrint('[startup] before Isar init');
  try {
    isar = await IsarService.initialize();
    debugPrint('[startup] after Isar init (success)');
  } catch (e, st) {
    initError = e;
    initStack = st;
    debugPrint('[startup] Isar init FAILED: $e\n$st');
  }

  final prefs = await SharedPreferences.getInstance();

  // One-time PR migration
  if (isar != null) {
    final migrated = prefs.getBool('pr_migration_done') ?? false;
    if (!migrated) {
      try {
        await PRMigrationService.migrate(isar);
        await prefs.setBool('pr_migration_done', true);
        debugPrint('[startup] PR migration complete');
      } catch (e) {
        debugPrint('[startup] PR migration failed: $e');
      }
    }
  }

  // Initialize notification service
  try {
    await NotificationService.instance.init();
    debugPrint('[startup] NotificationService initialized');
  } catch (e) {
    debugPrint('[startup] NotificationService init failed: $e');
  }

  debugPrint('[startup] before runApp');
  if (isar == null) {
    runApp(_StartupErrorApp(
      phase: _StartupPhase.isar,
      error: initError,
      stack: initStack,
    ));
  } else {
    runApp(
      ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(isar),
          sharedPreferencesProvider.overrideWithValue(prefs),
          firebaseAuthProvider.overrideWithValue(FirebaseAuth.instance),
          firestoreProvider.overrideWithValue(FirebaseFirestore.instance),
          storageProvider.overrideWithValue(FirebaseStorage.instance),
        ],
        child: const FitAIApp(),
      ),
    );
  }
  debugPrint('[startup] after runApp');
}

enum _StartupPhase { firebase, isar }

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.phase, this.error, this.stack});
  final _StartupPhase phase;
  final Object? error;
  final StackTrace? stack;

  String get _subtitle {
    switch (phase) {
      case _StartupPhase.firebase:
        return 'Firebase could not be initialized. '
            'GoogleService-Info.plist may be missing from the iOS bundle.';
      case _StartupPhase.isar:
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
                    'FitAI failed to start',
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
