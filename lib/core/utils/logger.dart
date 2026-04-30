import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Lightweight facade over `debugPrint` + Firebase Crashlytics. In debug mode
/// everything is a console log; in release mode, errors/fatals are forwarded
/// to Crashlytics and breadcrumb logs show up in the next crash's timeline.
class AppLogger {
  AppLogger._();

  /// Record a non-fatal error. The app keeps running; Crashlytics shows it
  /// under *non-fatals* attributed to the current session.
  static void error(String message, {Object? error, StackTrace? stack}) {
    debugPrint('[ERROR] $message${error != null ? ' | $error' : ''}');
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        error ?? message,
        stack,
        reason: message,
        fatal: false,
      );
    }
  }

  /// Record a breadcrumb. These appear in the timeline of the next crash
  /// report, so sprinkle them at major user-journey steps for context.
  static void log(String message) {
    debugPrint('[LOG] $message');
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.log(message);
    }
  }

  /// Record a fatal error and upload on next launch. Use for situations the
  /// app cannot reasonably recover from (corrupt local DB, startup failure).
  static void fatal(String message, {Object? error, StackTrace? stack}) {
    debugPrint('[FATAL] $message${error != null ? ' | $error' : ''}');
    FirebaseCrashlytics.instance.recordError(
      error ?? message,
      stack,
      reason: message,
      fatal: true,
    );
  }
}
