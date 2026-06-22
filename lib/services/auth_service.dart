import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../core/utils/logger.dart';

class AuthService {
  AuthService(this._auth, {this.deleteAccountEndpoint}) {
    // Keep Crashlytics' user identifier in lockstep with the current auth
    // state so crashes are attributed to the signed-in user (UID only — no
    // PII). This also covers session restoration on app launch.
    _auth.authStateChanges().listen((user) async {
      try {
        if (user != null) {
          await FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
          AppLogger.log('Auth: user signed in ${user.uid}');
        } else {
          await FirebaseCrashlytics.instance.setUserIdentifier('');
          AppLogger.log('Auth: user signed out');
        }
      } catch (e, st) {
        AppLogger.error(
          'Failed to sync Crashlytics user identifier',
          error: e,
          stack: st,
        );
      }
    });
  }

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Endpoint of the server-side `deleteAccount` Cloud Function, injected from
  /// `DELETE_ACCOUNT_URL` (assets/.env) by [authServiceProvider]. Null when the
  /// URL isn't configured, in which case [deleteAccount] fails with a
  /// user-safe message instead of hitting a bad URL. Mirrors how the AI proxy
  /// endpoint is wired.
  final Uri? deleteAccountEndpoint;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  /// Native Sign in with Apple → Firebase. Required for App Store Guideline 4.8
  /// (an equal third-party login option alongside Google).
  ///
  /// Replay-protection nonce flow: a cryptographically secure RAW nonce is
  /// SHA-256 hashed and sent to Apple (`nonce:`); the RAW nonce goes to Firebase
  /// via [OAuthProvider.credential] (`rawNonce:`), which re-hashes it and
  /// compares against the hash embedded in Apple's id token. Swapping raw/hashed
  /// is the classic cause of `MissingOrInvalidNonce`.
  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final AuthorizationCredentialAppleID appleCredential;
    try {
      appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      // Dismissing the Apple sheet is a normal no-op, not an error. Normalize to
      // a sentinel code the UI treats silently (mirrors Google's cancel code).
      if (e.code == AuthorizationErrorCode.canceled) {
        throw FirebaseAuthException(
          code: 'apple-sign-in-cancelled',
          message: 'Apple sign-in was cancelled.',
        );
      }
      rethrow;
    }

    final idToken = appleCredential.identityToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'apple-missing-id-token',
        message: 'Apple did not return an identity token. Please try again.',
      );
    }

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: idToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);

    // Apple returns the name ONLY on the first authorization. Capture it into
    // the Firebase displayName (same convention as signUpWithEmail) when present
    // and not already set, so onboarding/profile can use it. Best-effort — never
    // block sign-in on a name write.
    final given = appleCredential.givenName?.trim() ?? '';
    final family = appleCredential.familyName?.trim() ?? '';
    final fullName =
        [given, family].where((p) => p.isNotEmpty).join(' ').trim();
    final existing = userCredential.user?.displayName?.trim() ?? '';
    if (fullName.isNotEmpty && existing.isEmpty) {
      try {
        await userCredential.user?.updateDisplayName(fullName);
      } catch (e, st) {
        AppLogger.error('Apple sign-in: updateDisplayName failed',
            error: e, stack: st);
      }
    }

    return userCredential;
  }

  /// Cryptographically secure random nonce (URL-safe charset).
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Permanently deletes the signed-in user's account and ALL associated data
  /// via the server-side `deleteAccount` Cloud Function (Admin SDK). The
  /// function verifies the caller's Firebase ID token, tears down their
  /// Firestore documents and Storage objects, then deletes the auth user
  /// itself — work the client SDK can't do (admin-only deletes, and an auth
  /// delete that would otherwise require a recent re-login).
  ///
  /// This does NOT sign out or clear on-device data — the caller is
  /// responsible for clearing local Isar/SharedPreferences and signing out
  /// after this completes (see the Settings delete flow).
  ///
  /// Authenticated exactly like the AI proxy: a Bearer Firebase ID token.
  /// Throws [AuthServiceException] with a user-safe message on any failure;
  /// raw errors are logged via [AppLogger] and never surfaced to the UI.
  Future<void> deleteAccount() async {
    final endpoint = deleteAccountEndpoint;
    if (endpoint == null) {
      AppLogger.error(
        'deleteAccount called but DELETE_ACCOUNT_URL is not configured',
      );
      throw AuthServiceException(
        'Account deletion is unavailable right now. Please try again later.',
      );
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw AuthServiceException('You are not signed in.');
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);
    try {
      // Fetch the token BEFORE the server deletes the auth user.
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        throw AuthServiceException(
          "We couldn't verify your session. Please sign in again and retry.",
        );
      }

      final request = await client.postUrl(endpoint);
      request.headers
        ..set(HttpHeaders.contentTypeHeader, 'application/json')
        ..set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.add(utf8.encode('{}'));

      final response = await request.close().timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw AuthServiceException(
              'The request timed out. Please check your connection and '
              'try again.',
            ),
          );
      // Drain the body so the connection can be reused/closed cleanly; it also
      // feeds server-side error detail into our logs (never to the user).
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        AppLogger.error(
          'deleteAccount failed: HTTP ${response.statusCode} '
          '${_truncate(body, 500)}',
        );
        throw AuthServiceException(
          "We couldn't delete your account. Please try again.",
        );
      }
    } on AuthServiceException {
      rethrow;
    } on SocketException catch (e, st) {
      AppLogger.error('deleteAccount network error', error: e, stack: st);
      throw AuthServiceException(
        'No internet connection. Connect and try again.',
      );
    } on TimeoutException catch (e, st) {
      AppLogger.error('deleteAccount timed out', error: e, stack: st);
      throw AuthServiceException(
        'The request timed out. Please try again.',
      );
    } catch (e, st) {
      AppLogger.error(
        'deleteAccount unexpected error (${e.runtimeType})',
        error: e,
        stack: st,
      );
      throw AuthServiceException(
        "We couldn't delete your account. Please try again.",
      );
    } finally {
      client.close(force: true);
    }
  }

  static String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';
}

/// Thrown by [AuthService] operations that fail. [message] is always a
/// user-safe string suitable for display — raw underlying errors are logged
/// via [AppLogger], never carried here.
class AuthServiceException implements Exception {
  AuthServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}
