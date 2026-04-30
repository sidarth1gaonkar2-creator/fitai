import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
