import 'dart:io' show Platform;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/utils/logger.dart';

/// The single RevenueCat entitlement this app sells ("Airborne"). Grants the
/// higher AI Coach daily cap (enforced server-side via the rcWebhook →
/// entitlements/{uid} pipeline) and unlocks the standard coin themes
/// client-side. Must match the entitlement identifier configured in the
/// RevenueCat dashboard.
const kAirborneEntitlementId = 'airborne';

/// Thin lifecycle wrapper over the static [Purchases] SDK: one-time
/// [configure] during bootstrap, then identity hand-offs on auth transitions
/// via [setFirebaseUid]. Everything is best-effort — when the API key is
/// missing or any call fails, the app runs fully usable in the free tier
/// (degraded mode); failures are logged, never thrown.
class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  bool _configured = false;

  /// Whether [Purchases.configure] succeeded this launch. Every RevenueCat
  /// feature (entitlement provider, paywall, restore) gates on this so a
  /// missing key — or a non-iOS host, like tests on Windows — degrades to the
  /// free tier instead of crashing.
  bool get isConfigured => _configured;

  /// Configures the SDK with the Apple API key from assets/.env. iOS-only:
  /// this app ships no Android build, and calling the platform channel
  /// anywhere else would throw.
  ///
  /// [initialUid] binds the RevenueCat identity to the Firebase uid at
  /// configure time — bootstrap resolves the persisted auth state before
  /// runApp, so a signed-in launch never has an anonymous-purchases window.
  Future<void> configure({String? initialUid}) async {
    if (!Platform.isIOS) return;
    final key = dotenv.isInitialized ? dotenv.env['RC_APPLE_API_KEY'] : null;
    if (key == null || key.isEmpty) {
      AppLogger.error(
          'Airborne disabled by configuration (RC_APPLE_API_KEY missing)');
      return;
    }
    try {
      await Purchases.configure(
        PurchasesConfiguration(key)..appUserID = initialUid,
      );
      _configured = true;
    } catch (e, st) {
      AppLogger.error('RevenueCat configure failed', error: e, stack: st);
    }
  }

  /// Aligns the RevenueCat identity with the Firebase auth state. Rides the
  /// session coordinator (app.dart), so every transition — including passive
  /// sign-outs from token revocation — keeps purchases bound to the signed-in
  /// uid and never to an anonymous id while a user is signed in.
  Future<void> setFirebaseUid(String? uid) async {
    if (!_configured) return;
    try {
      if (uid != null) {
        await Purchases.logIn(uid);
      } else if (!await Purchases.isAnonymous) {
        // logOut throws when already anonymous, hence the guard.
        await Purchases.logOut();
      }
    } catch (e, st) {
      AppLogger.error('RevenueCat identity switch failed',
          error: e, stack: st);
    }
  }
}
