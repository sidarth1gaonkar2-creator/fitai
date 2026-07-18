import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/field_manual.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../providers/auth_provider.dart';
import 'apple_sign_in_button.dart';
import 'auth_error_dialog.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isGoogleLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      // Router redirect handles navigation automatically
    } catch (e, st) {
      // Don't error-log the benign Google cancel — only genuine failures.
      if (e is! FirebaseAuthException ||
          e.code != 'google-sign-in-cancelled') {
        AppLogger.error('Google sign-in failed', error: e, stack: st);
      }
      if (mounted) showAuthErrorDialog(context, e);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FieldManual.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Logo — the DrillFit app icon PNG (mirror of the iOS
              // AppIcon-180). iOS uses a 22%-of-width corner radius for app
              // icons (~21px on a 96-wide rendering), so we clip with a
              // matching RRect to read as the system app icon.
              ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: Image.asset(
                  'assets/images/app-icon.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),

              // Wordmark — Oswald display, tracked caps (Field Manual).
              Text(
                'DRILLFIT',
                style: FieldManual.display().copyWith(
                  fontSize: 34,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),

              // Tagline — the positioning line, verbatim (PRODUCT.md). The
              // old "AI-powered fitness companion" was the exact register the
              // brand defines itself against.
              Text(
                'Most fitness apps just track. DrillFit makes you earn it.',
                textAlign: TextAlign.center,
                style: FieldManual.body(
                  fontSize: 16,
                  color: FieldManual.mutedBone,
                ),
              ),

              const Spacer(flex: 4),

              // Create Account button
              SizedBox(
                width: double.infinity,
                child: CupertinoPrimaryButton(
                  label: 'Create Account',
                  onPressed: () => context.push('/signup'),
                ),
              ),
              const SizedBox(height: 12),

              // Sign In button
              SizedBox(
                width: double.infinity,
                child: CupertinoSecondaryButton(
                  label: 'Sign In',
                  onPressed: () => context.push('/signin'),
                ),
              ),
              const SizedBox(height: 12),

              // Sign in with Apple (App Store 4.8) — an equal peer to Google:
              // same full width and placement weight, positioned directly above
              // it per Apple's Human Interface Guidelines.
              const AppleSignInButton(),
              const SizedBox(height: 12),

              // Google Sign-In button — provider brand treatment, NOT Field
              // Manual idiom (App Store / Google branding review). Neutral
              // white-on-dark chrome and platform font stay; only the corner
              // radius aligns at 4, which matches Google's own rectangular
              // button spec (4dp corners).
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _isGoogleLoading ? null : _signInWithGoogle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0x99FFFFFF)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isGoogleLoading)
                          const CupertinoActivityIndicator()
                        else ...[
                          const Text(
                            'G',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: CupertinoColors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
