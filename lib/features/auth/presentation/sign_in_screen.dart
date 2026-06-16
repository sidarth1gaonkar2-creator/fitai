import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Scaffold;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../providers/auth_provider.dart';
import 'apple_sign_in_button.dart';
import 'auth_error_dialog.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
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
    } catch (e) {
      if (mounted) showAuthErrorDialog(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showCupertinoToast(context, 'Enter your email first.');
      return;
    }
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      if (mounted) {
        showCupertinoToast(context, 'Password reset email sent.');
      }
    } catch (e) {
      if (mounted) showAuthErrorDialog(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: const CupertinoNavigationBar(
        middle: Text('Sign In'),
        backgroundColor: Color(0xCC1A1A1A),
        border: null,
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
              const Text(
                'Welcome back',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue tracking your progress.',
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: AppColors.purpleLight,
                ),
              ),
              const SizedBox(height: 32),

              // Email field
              CupertinoTextField(
                controller: _emailController,
                placeholder: 'Email',
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x14FFFFFF)),
                ),
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),

              // Password field
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'Password',
                obscureText: true,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x14FFFFFF)),
                ),
                style: const TextStyle(color: Colors.white),
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
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppColors.purple,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sign In button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const CupertinoActivityIndicator(color: Colors.black)
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.black,
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
