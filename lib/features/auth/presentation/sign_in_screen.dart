import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/field_manual.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../providers/auth_provider.dart';
import 'apple_sign_in_button.dart';
import 'auth_error_dialog.dart';
import 'forgot_password_sheet.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // Focus tracking is visual only — it drives the accent focus border on the
  // Field Manual inputs. Keyboard behavior is unchanged.
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onFocusChanged);
    _passwordFocus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    // Repaint the focused field's border.
    setState(() {});
  }

  @override
  void dispose() {
    _emailFocus.removeListener(_onFocusChanged);
    _passwordFocus.removeListener(_onFocusChanged);
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showCupertinoToast(context, 'Please fill in all fields.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithEmail(email, password);
      // Router redirect handles navigation
    } catch (e, st) {
      AppLogger.error('Email sign-in failed', error: e, stack: st);
      if (mounted) showAuthErrorDialog(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _forgotPassword() {
    showForgotPasswordSheet(context, initialEmail: _emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Scaffold(
      backgroundColor: FieldManual.scaffold,
      appBar: CupertinoNavigationBar(
        middle: Text('SIGN IN', style: FieldManual.title()),
        backgroundColor: FieldManual.ink.withValues(alpha: 0.82),
        border: const Border(
          bottom: BorderSide(color: FieldManual.hairline),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Heading
              Text('WELCOME BACK', style: FieldManual.display()),
              const SizedBox(height: 8),
              Text(
                'Fall back in. Your ranks are holding.',
                style: FieldManual.body(
                  fontSize: 16,
                  color: FieldManual.mutedBone,
                ),
              ),
              const SizedBox(height: 32),

              // Email field
              CupertinoTextField(
                controller: _emailController,
                focusNode: _emailFocus,
                placeholder: 'Email',
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: FieldManual.fieldRaised,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _emailFocus.hasFocus
                        ? palette.accent
                        : FieldManual.hairline,
                  ),
                ),
                style: FieldManual.body(),
                placeholderStyle: FieldManual.body(
                  color: FieldManual.mutedBone,
                ),
                cursorColor: palette.accent,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),

              // Password field
              CupertinoTextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                placeholder: 'Password',
                obscureText: true,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: FieldManual.fieldRaised,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _passwordFocus.hasFocus
                        ? palette.accent
                        : FieldManual.hairline,
                  ),
                ),
                style: FieldManual.body(),
                placeholderStyle: FieldManual.body(
                  color: FieldManual.mutedBone,
                ),
                cursorColor: palette.accent,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signIn(),
              ),
              const SizedBox(height: 8),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  onPressed: _forgotPassword,
                  child: Text(
                    'Forgot Password?',
                    style: FieldManual.body(
                      fontSize: 13,
                      color: palette.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sign In button — Field Manual primary: accent fill, on-accent
              // label, sharp 4px corners.
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: palette.accent,
                  // Keep the accent fill while loading (the only disabled
                  // state) so the ink spinner stays visible.
                  disabledColor: palette.accent,
                  borderRadius: BorderRadius.circular(4),
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? CupertinoActivityIndicator(color: palette.onAccent)
                      : Text(
                          'SIGN IN',
                          style: FieldManual.title().copyWith(
                            fontSize: 15,
                            letterSpacing: 0.6,
                            color: palette.onAccent,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Sign in with Apple (App Store 4.8) — additional access point.
              const AuthOrDivider(),
              const SizedBox(height: 20),
              const AppleSignInButton(),
            ],
          ),
        ),
      ),
    );
  }
}
