import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';

/// Enumeration-safe confirmation shown for BOTH success and user-not-found —
/// enumeration protection is enabled, so the app must never reveal whether an
/// account exists. Only invalid-format and network errors surface distinctly.
const _resetSentMessage =
    'If an account exists for that email, a reset link is on the way.';

/// Opens the forgot-password sheet. [initialEmail] pre-fills the field
/// (typically whatever is already typed in the sign-in email field).
Future<void> showForgotPasswordSheet(
  BuildContext context, {
  String initialEmail = '',
}) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => ForgotPasswordSheet(initialEmail: initialEmail),
  );
}

class ForgotPasswordSheet extends ConsumerStatefulWidget {
  const ForgotPasswordSheet({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<ForgotPasswordSheet> {
  late final TextEditingController _emailController =
      TextEditingController(text: widget.initialEmail.trim());
  final FocusNode _emailFocus = FocusNode();
  Timer? _debounce;

  bool _isSending = false;
  bool _sent = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _emailFocus.removeListener(_onFocusChanged);
    _emailFocus.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    // Validate on blur — but an untouched empty field stays quiet until Send.
    if (_emailFocus.hasFocus) return;
    _debounce?.cancel();
    if (_emailController.text.trim().isEmpty) return;
    setState(() => _emailError = validateEmail(_emailController.text));
  }

  void _onEmailChanged(String value) {
    _debounce?.cancel();
    // Clear the error the moment the input becomes valid.
    if (_emailError != null && validateEmail(value) == null) {
      setState(() => _emailError = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (!mounted || value.trim().isEmpty) return;
      setState(() => _emailError = validateEmail(value));
    });
  }

  Future<void> _send() async {
    _debounce?.cancel();
    final email = _emailController.text.trim();
    final formatError = validateEmail(email);
    if (formatError != null) {
      setState(() => _emailError = formatError);
      return;
    }

    setState(() {
      _isSending = true;
      _emailError = null;
    });
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      if (mounted) setState(() => _sent = true);
    } on FirebaseAuthException catch (e, st) {
      AppLogger.error(
        'Password reset email failed (${e.code})',
        error: e,
        stack: st,
      );
      if (!mounted) return;
      switch (e.code) {
        case 'invalid-email':
          setState(
            () => _emailError = "That doesn't look like a real email address",
          );
        case 'network-request-failed':
          setState(
            () => _emailError = 'No connection. Check your internet and retry.',
          );
        default:
          // user-not-found (and anything else) must be indistinguishable
          // from success.
          setState(() => _sent = true);
      }
    } catch (e, st) {
      AppLogger.error('Password reset email failed', error: e, stack: st);
      if (mounted) setState(() => _sent = true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        decoration: const BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: _sent ? _buildConfirmation(context) : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Reset your password',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Confirm your email and we'll send a reset link. "
          "You'll be back in the fight in no time.",
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            fontWeight: FontWeight.w400,
            fontSize: 15,
            color: AppColors.purpleLight,
          ),
        ),
        const SizedBox(height: 20),
        CupertinoTextField(
          controller: _emailController,
          focusNode: _emailFocus,
          placeholder: 'Email',
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofocus: true,
          onChanged: _onEmailChanged,
          onSubmitted: (_) => _send(),
          textInputAction: TextInputAction.send,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _emailError != null
                  ? AppColors.error
                  : const Color(0x14FFFFFF),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        if (_emailError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _emailError!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        const SizedBox(height: 20),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: AppColors.lime,
          borderRadius: BorderRadius.circular(12),
          onPressed: _isSending ? null : _send,
          child: _isSending
              ? const CupertinoActivityIndicator(color: Colors.black)
              : const Text(
                  'Send Reset Link',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 10),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.purpleLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmation(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          CupertinoIcons.envelope_circle_fill,
          size: 48,
          color: AppColors.lime,
        ),
        const SizedBox(height: 12),
        const Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          _resetSentMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            fontWeight: FontWeight.w400,
            fontSize: 15,
            color: AppColors.purpleLight,
          ),
        ),
        const SizedBox(height: 20),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: AppColors.lime,
          borderRadius: BorderRadius.circular(12),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Roger That',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
