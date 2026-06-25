import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../../../providers/auth_provider.dart';
import 'auth_error_dialog.dart';

/// Official "Sign in with Apple" button + native-flow wiring (App Store 4.8).
///
/// Self-contained loading state and error handling so welcome / sign-in /
/// sign-up can each drop it in as an equal peer to the other auth options. Uses
/// the package's official [SignInWithAppleButton] (don't hand-roll Apple's
/// button). A fresh Apple user lands signed-in with no profile doc, so the
/// shared onboarding gate routes them to /onboarding exactly like Google/email.
class AppleSignInButton extends ConsumerStatefulWidget {
  const AppleSignInButton({super.key});

  @override
  ConsumerState<AppleSignInButton> createState() => _AppleSignInButtonState();
}

class _AppleSignInButtonState extends ConsumerState<AppleSignInButton> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).signInWithApple();
      // Router redirect handles navigation (→ /onboarding for a fresh user).
    } on FirebaseAuthException catch (e, st) {
      // User dismissed the Apple sheet → silent no-op, never an error dialog.
      if (e.code == 'apple-sign-in-cancelled') return;
      AppLogger.error('Apple sign-in failed', error: e, stack: st);
      if (mounted) showAuthErrorDialog(context, e);
    } catch (e, st) {
      AppLogger.error('Apple sign-in failed', error: e, stack: st);
      if (mounted) showAuthErrorDialog(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SignInWithAppleButton(
        // Null onPressed disables the official button while a request is in
        // flight (don't overlay a spinner — keep Apple's button pristine).
        onPressed: _loading ? null : _signIn,
        style: SignInWithAppleButtonStyle.white,
        height: 48,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

/// "───  or  ───" divider separating email auth from the Apple button on the
/// sign-in / sign-up screens.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0x22FFFFFF))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 13,
              color: AppColors.purpleLight,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: const Color(0x22FFFFFF))),
      ],
    );
  }
}
