import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../core/utils/logger.dart';

class AuthService {
  AuthService(this._auth) {
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
}
