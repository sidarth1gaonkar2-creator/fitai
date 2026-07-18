import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/field_manual.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/validators.dart';
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
  final _emailFocus = FocusNode();
  Timer? _emailDebounce;

  bool _isLoading = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onEmailFocusChanged);
  }

  @override
  void dispose() {
    _emailDebounce?.cancel();
    _emailFocus.removeListener(_onEmailFocusChanged);
    _emailFocus.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onEmailFocusChanged() {
    // Validate on blur — but an untouched empty field stays quiet until
    // submit flags it.
    if (_emailFocus.hasFocus) return;
    _emailDebounce?.cancel();
    if (_emailController.text.trim().isEmpty) return;
    setState(() => _emailError = validateEmail(_emailController.text));
  }

  void _onEmailChanged(String value) {
    _emailDebounce?.cancel();
    // Clear the error the moment the input becomes valid.
    if (_emailError != null && validateEmail(value) == null) {
      setState(() => _emailError = null);
      return;
    }
    _emailDebounce = Timer(const Duration(milliseconds: 700), () {
      if (!mounted || value.trim().isEmpty) return;
      setState(() => _emailError = validateEmail(value));
    });
  }

  bool _validate() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    setState(() {
      _nameError = name.isEmpty ? 'Name is required.' : null;
      _emailError = validateEmail(email);
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
    } on FirebaseAuthException catch (e, st) {
      AppLogger.error('Email sign-up failed (${e.code})', error: e, stack: st);
      if (!mounted) return;
      switch (e.code) {
        case 'invalid-email':
          setState(
            () => _emailError = "That doesn't look like a real email address",
          );
        case 'email-already-in-use':
          setState(
            () => _emailError =
                "That email's already enlisted. Sign in instead.",
          );
        case 'weak-password':
          setState(
            () => _passwordError =
                'Password must be at least 6 characters.',
          );
        default:
          showAuthErrorDialog(context, e);
      }
    } catch (e, st) {
      AppLogger.error('Email sign-up failed', error: e, stack: st);
      if (mounted) showAuthErrorDialog(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Scaffold(
      backgroundColor: FieldManual.ink,
      appBar: CupertinoNavigationBar(
        middle: Text('CREATE ACCOUNT', style: FieldManual.title()),
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
              Text('GET STARTED', style: FieldManual.display()),
              const SizedBox(height: 8),
              Text(
                'Enlistment takes a minute. The rest you earn.',
                style: FieldManual.body(
                  fontSize: 16,
                  color: FieldManual.mutedBone,
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
                focusNode: _emailFocus,
                placeholder: 'Email',
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                onChanged: _onEmailChanged,
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

              // Create Account button — Field Manual primary: accent fill,
              // on-accent label, sharp 4px corners.
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: palette.accent,
                  // Keep the accent fill while loading (the only disabled
                  // state) so the ink spinner stays visible.
                  disabledColor: palette.accent,
                  borderRadius: BorderRadius.circular(4),
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? CupertinoActivityIndicator(color: palette.onAccent)
                      : Text(
                          'CREATE ACCOUNT',
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

class _AuthTextField extends StatefulWidget {
  const _AuthTextField({
    required this.controller,
    required this.placeholder,
    this.focusNode,
    this.keyboardType,
    this.obscureText = false,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.error,
  });

  final TextEditingController controller;
  final String placeholder;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autocorrect;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? error;

  @override
  State<_AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<_AuthTextField> {
  // Focus tracking is visual only — it drives the accent focus border on the
  // Field Manual input. When the caller passes a node (email), we listen to
  // it; otherwise we own a private one. Input behavior is unchanged.
  late FocusNode _focusNode;
  bool _ownsNode = false;

  @override
  void initState() {
    super.initState();
    _attach(widget.focusNode);
  }

  void _attach(FocusNode? node) {
    _ownsNode = node == null;
    _focusNode = node ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  void _detach() {
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsNode) _focusNode.dispose();
  }

  @override
  void didUpdateWidget(_AuthTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _detach();
      _attach(widget.focusNode);
    }
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  void _onFocusChanged() {
    // Repaint the focus border.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final borderColor = widget.error != null
        ? palette.destructive
        : _focusNode.hasFocus
            ? palette.accent
            : FieldManual.hairline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: widget.controller,
          focusNode: _focusNode,
          placeholder: widget.placeholder,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          autocorrect: widget.autocorrect,
          textCapitalization: widget.textCapitalization,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: FieldManual.fieldRaised,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor),
          ),
          style: FieldManual.body(),
          placeholderStyle: FieldManual.body(color: FieldManual.mutedBone),
          cursorColor: palette.accent,
        ),
        // Error is never color-alone — the message text carries it.
        if (widget.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              widget.error!,
              style: FieldManual.body(
                fontSize: 12,
                color: palette.destructive,
              ),
            ),
          ),
      ],
    );
  }
}
