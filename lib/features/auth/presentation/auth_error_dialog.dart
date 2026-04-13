import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

void showAuthErrorDialog(BuildContext context, Object error) {
  String message = 'An unexpected error occurred. Please try again.';

  if (error is FirebaseAuthException) {
    message = switch (error.code) {
      'email-already-in-use' => 'An account with this email already exists.',
      'invalid-email' => 'Please enter a valid email address.',
      'wrong-password' || 'invalid-credential' =>
        'Incorrect email or password.',
      'user-not-found' => 'No account found with this email.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'weak-password' => 'Password must be at least 6 characters.',
      'network-request-failed' => 'Network error. Check your connection.',
      'google-sign-in-cancelled' => 'Google sign-in was cancelled.',
      _ => error.message ?? 'Authentication error. Please try again.',
    };
  }

  showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('Sign In Error'),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
