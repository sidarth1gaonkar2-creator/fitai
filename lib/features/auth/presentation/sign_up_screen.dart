import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Scaffold;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../../../providers/auth_provider.dart';
import 'apple_sign_in_button.dart';
import 'auth_error_dialog.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    setState(() {
      _nameError = name.isEmpty ? 'Name is required.' : null;
      _emailError = email.isEmpty
          ? 'Email is required.'
          : !email.contains('@')
              ? 'Enter a valid email address.'
              : null;
      _passwordError = password.isEmpty
          ? 'Password is required.'
          : password.length < 6
              ? 'Password must be at least 6 characters.'
              : null;
      _confirmError = confirm != password ? 'Passwords do not match.' : null;
    });

    return _nameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmError == null;
  }

  Future<void> _signUp() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signUpWithEmail(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
          );
      // Router redirect handles navigation (→ /onboarding since no profile)
    } catch (e, st) {
      AppLogger.error('Email sign-up failed', error: e, stack: st);
      if (mounted) showAuthErrorDialog(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: const CupertinoNavigationBar(
        middle: Text('Create Account'),
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
                'Get started',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your account to begin your fitness journey.',
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: AppColors.purpleLight,
                ),
              ),
              const SizedBox(height: 32),

              // Name field
              _AuthTextField(
                controller: _nameController,
                placeholder: 'Name',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                error: _nameError,
              ),
              const SizedBox(height: 14),

              // Email field
              _AuthTextField(
                controller: _emailController,
                placeholder: 'Email',
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                error: _emailError,
              ),
              const SizedBox(height: 14),

              // Password field
              _AuthTextField(
                controller: _passwordController,
                placeholder: 'Password',
                obscureText: true,
                textInputAction: TextInputAction.next,
                error: _passwordError,
              ),
              const SizedBox(height: 14),

              // Confirm password field
              _AuthTextField(
                controller: _confirmPasswordController,
                placeholder: 'Confirm Password',
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signUp(),
                error: _confirmError,
              ),
              const SizedBox(height: 32),

              // Create Account button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? const CupertinoActivityIndicator(color: Colors.black)
                      : const Text(
                          'Create Account',
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

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.obscureText = false,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.onSubmitted,
    this.error,
  });

  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autocorrect;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autocorrect: autocorrect,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: error != null ? AppColors.error : const Color(0x14FFFFFF),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              error!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
