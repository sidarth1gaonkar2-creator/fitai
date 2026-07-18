import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar, Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/utils/logger.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../../../providers/firestore_provider.dart';
import '../../../../providers/user_profile_provider.dart';
import '../../data/user_repository.dart';
import '../../domain/firestore_user.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  File? _imageFile;
  bool _isPublic = true;
  bool _isSaving = false;
  String _usernameStatus = ''; // '', 'checking', 'available', 'taken', 'short', 'invalid', 'error'
  String _usernameErrorDetail = '';
  Timer? _debounce;

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _debounce?.cancel();

    if (value.isEmpty) {
      setState(() => _usernameStatus = '');
      return;
    }

    final valid = RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value);
    if (!valid) {
      setState(() => _usernameStatus = 'invalid');
      return;
    }

    if (value.length < 3) {
      setState(() => _usernameStatus = 'short');
      return;
    }

    setState(() => _usernameStatus = 'checking');

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        debugPrint(
            '[ProfileSetup] auth state before check: uid=${currentUser?.uid} '
            'emailVerified=${currentUser?.emailVerified} '
            'isAnonymous=${currentUser?.isAnonymous}');

        if (currentUser == null) {
          // Auth hasn't resolved yet — wait for the first real event.
          debugPrint('[ProfileSetup] currentUser is null, awaiting authStateChanges');
          final resolved = await FirebaseAuth.instance
              .authStateChanges()
              .firstWhere((u) => u != null)
              .timeout(const Duration(seconds: 5));
          debugPrint('[ProfileSetup] auth resolved: uid=${resolved?.uid}');
        }

        // Force the ID token to be fetched so Firestore's internal auth token
        // provider has it before the request goes out. Fixes a race where the
        // Firestore client sends the first request before the auth token
        // propagates from firebase_auth → cloud_firestore.
        await FirebaseAuth.instance.currentUser
            ?.getIdToken()
            .timeout(const Duration(seconds: 5));

        final taken = await ref
            .read(userRepositoryProvider)
            .isUsernameTaken(value)
            .timeout(const Duration(seconds: 5));
        if (!mounted || _usernameController.text != value) return;
        setState(() {
          _usernameStatus = taken ? 'taken' : 'available';
          _usernameErrorDetail = '';
        });
      } on FirebaseException catch (e) {
        debugPrint(
            '[ProfileSetup] isUsernameTaken FirebaseException code=${e.code} message=${e.message}');
        if (!mounted || _usernameController.text != value) return;
        setState(() {
          _usernameStatus = 'error';
          _usernameErrorDetail = _describeFirebaseError(e.code);
        });
      } on TimeoutException catch (e) {
        debugPrint('[ProfileSetup] isUsernameTaken timed out: $e');
        if (!mounted || _usernameController.text != value) return;
        setState(() {
          _usernameStatus = 'error';
          _usernameErrorDetail = 'timed out — check your connection';
        });
      } catch (e) {
        debugPrint('[ProfileSetup] isUsernameTaken failed: $e');
        if (!mounted || _usernameController.text != value) return;
        setState(() {
          _usernameStatus = 'error';
          _usernameErrorDetail = 'unexpected error';
        });
      }
    });
  }

  String _describeFirebaseError(String code) {
    switch (code) {
      case 'permission-denied':
        return 'permission denied — Firestore rules are blocking this request';
      case 'unavailable':
        return 'Firestore unreachable — check your connection';
      case 'unauthenticated':
        return 'not signed in — please sign in again';
      default:
        return 'Firestore error ($code)';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (xFile == null) return;
    setState(() => _imageFile = File(xFile.path));
  }

  bool get _canContinue =>
      !_isSaving &&
      _usernameStatus == 'available' &&
      _usernameController.text.length >= 3;

  Future<void> _onContinue() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      // Avatar upload is best-effort and MUST NOT block account creation. The
      // public bucket rules can reject an upload (e.g. they expired in May 2026,
      // which silently broke every avatar upload → "Failed to create profile").
      // If the upload throws, log it and continue with a null picture URL — the
      // user can add a photo later from Edit Profile. createUser then writes the
      // users/{uid} doc with profilePictureUrl == null, which the rules allow.
      String? profilePictureUrl;
      if (_imageFile != null) {
        try {
          profilePictureUrl = await ref
              .read(storageServiceProvider)
              .uploadProfilePicture(userId, _imageFile!);
        } catch (e, st) {
          AppLogger.error(
            'ProfileSetup: avatar upload failed — continuing without photo',
            error: e,
            stack: st,
          );
        }
      }

      // Use the Isar user profile display name if available.
      final localProfile = await ref.read(userProfileProvider.future);
      final displayName = localProfile?.name ?? _usernameController.text;

      final user = FirestoreUser(
        userId: userId,
        username: _usernameController.text.toLowerCase(),
        displayName: displayName,
        bio: _bioController.text.trim(),
        profilePictureUrl: profilePictureUrl,
        isPublic: _isPublic,
      );

      await ref.read(userRepositoryProvider).createUser(user);

      // Refresh the Firestore user provider so downstream widgets see
      // the newly created document.
      ref.invalidate(firestoreUserProvider);

      if (!mounted) return;
      context.go('/dashboard');
    } on FirebaseException catch (e, st) {
      // Surface the real cause instead of swallowing it: log the code+stack to
      // Crashlytics (the previous catch-all discarded it, leaving the App Store
      // rejection undiagnosable) and decode the code for the user, mirroring the
      // username-availability path above.
      AppLogger.error(
        'ProfileSetup: createUser failed (code=${e.code})',
        error: e,
        stack: st,
      );
      if (!mounted) return;
      _showError(
        'Failed to create profile: ${_describeFirebaseError(e.code)}. '
        'Please try again.',
      );
    } catch (e, st) {
      AppLogger.error(
        'ProfileSetup: createUser failed',
        error: e,
        stack: st,
      );
      if (!mounted) return;
      _showError('Failed to create profile. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'SET UP PROFILE',
          style: FieldManual.title(color: colors.text),
        ),
        backgroundColor: colors.background.withValues(alpha: 0.82),
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // --- Profile picture (icon-only control, so it is labeled) ---
              Semantics(
                label: 'Add profile photo',
                button: true,
                child: ExcludeSemantics(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 80,
                          backgroundColor: colors.surfaceElevated,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : null,
                          child: _imageFile == null
                              ? Icon(
                                  Icons.person,
                                  size: 64,
                                  color: colors.textSecondary,
                                )
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: colors.onAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- Username ---
              _FMTextField(
                controller: _usernameController,
                placeholder: 'Username',
                maxLength: 20,
                autocorrect: false,
                onChanged: _onUsernameChanged,
                errored: _usernameStatus == 'taken' ||
                    _usernameStatus == 'invalid' ||
                    _usernameStatus == 'error',
              ),
              const SizedBox(height: 8),
              _buildUsernameStatus(colors),
              const SizedBox(height: 20),

              // --- Bio ---
              _FMTextField(
                controller: _bioController,
                placeholder: 'Bio (optional)',
                maxLength: 150,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // --- Public toggle ---
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Public Account',
                      style: FieldManual.body(fontSize: 15, color: colors.text)
                          .copyWith(
                        fontVariations: const [FontVariation('wght', 600)],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoSwitch(
                      value: _isPublic,
                      activeTrackColor: colors.accent,
                      onChanged: (v) => setState(() => _isPublic = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- Continue button ---
              // Spoken label stays sentence case; uppercase is visual only.
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  label: 'Continue',
                  button: true,
                  child: ExcludeSemantics(
                    child: CupertinoButton(
                      color: colors.accent,
                      disabledColor: colors.accent.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                      onPressed: _canContinue ? _onContinue : null,
                      child: _isSaving
                          ? CupertinoActivityIndicator(
                              color: colors.onAccent,
                            )
                          : Text(
                              'CONTINUE',
                              style: TextStyle(
                                fontFamily: 'Oswald',
                                fontVariations: const [
                                  FontVariation('wght', 600),
                                ],
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                letterSpacing: 0.6,
                                color: colors.onAccent,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameStatus(Palette colors) {
    String text;
    Color color;

    // Never colour alone: every state carries a plain-language message.
    switch (_usernameStatus) {
      case 'checking':
        text = 'Checking...';
        color = colors.textSecondary;
      case 'available':
        text = 'Available';
        color = colors.success;
      case 'taken':
        text = 'Taken';
        color = colors.destructive;
      case 'short':
        text = 'Too short';
        color = colors.textSecondary;
      case 'invalid':
        text = 'Letters, numbers, and underscores only';
        color = colors.destructive;
      case 'error':
        text = _usernameErrorDetail.isNotEmpty
            ? 'Could not check username: $_usernameErrorDetail'
            : 'Could not check username. Check your connection and try again.';
        color = colors.destructive;
      default:
        return const SizedBox(height: 18);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: FieldManual.body(fontSize: 13, color: color),
      ),
    );
  }
}

/// Field Manual text input: field-raised fill, hairline border that shifts to
/// the live accent on focus and to alert red when [errored], no glow
/// (DESIGN.md §Inputs). Purely visual — behaviour is the inner
/// [CupertinoTextField]'s.
class _FMTextField extends StatefulWidget {
  const _FMTextField({
    required this.controller,
    required this.placeholder,
    this.maxLength,
    this.maxLines = 1,
    this.autocorrect = true,
    this.onChanged,
    this.errored = false,
  });

  final TextEditingController controller;
  final String placeholder;
  final int? maxLength;
  final int maxLines;
  final bool autocorrect;
  final ValueChanged<String>? onChanged;
  final bool errored;

  @override
  State<_FMTextField> createState() => _FMTextFieldState();
}

class _FMTextFieldState extends State<_FMTextField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final focused = _focusNode.hasFocus;
    final borderColor = widget.errored
        ? palette.destructive
        : focused
            ? palette.accent
            : palette.border;
    return CupertinoTextField(
      controller: widget.controller,
      focusNode: _focusNode,
      placeholder: widget.placeholder,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      autocorrect: widget.autocorrect,
      onChanged: widget.onChanged,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      cursorColor: palette.accent,
      style: FieldManual.body(fontSize: 15, color: palette.text),
      placeholderStyle: FieldManual.body(
        fontSize: 15,
        color: palette.textSecondary,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
    );
  }
}
